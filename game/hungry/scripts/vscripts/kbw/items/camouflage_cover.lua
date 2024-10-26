local PATH = "kbw/items/camouflage_cover"
local base = {}

-----------------------------------------------
-- passives

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_base = 0,
		m_item_corrosion_applier = 0,
	}
end

-----------------------------------------------
-- indicator

function base:GetAOERadius()
	return self:GetSpecialValueFor('active_radius')
end

-----------------------------------------------
-- instances

for _, name in pairs({
	'item_kbw_blight_stone',
	'item_kbw_orb_of_venom',
	'item_kbw_orb_of_corrosion',
	'item_camouflage_cover',
}) do
	local item = class{}
	_G[name] = item
	for k, v in pairs(base) do
		item[k] = v
	end
end

-----------------------------------------------
-- active

function item_camouflage_cover:OnSpellStart()
	local target = self:GetCursorTarget()

	AddModifier('m_item_camouflage_cover_active', {
		hTarget = target,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = self:GetSpecialValueFor('active_duration'),
	})

	PlaySound('KBW.Item.Cover.Invis', target)
end

-----------------------------------------------
-- passive corrosion visuals by id

local CORROSION_PARTICLES = {
	-- venom / corrosion / cover
	[1] = {
		particle = 'particles/items/venom.vpcf',
		controls = {
			[1] = Vector(2, 0.4, 0),
			[3] = Vector(90 /360, 168 /255-1, 200 /255),
		}
	},
	-- blight / desolator
	[2] = {
		particle = 'particles/items/venom.vpcf',
		controls = {
			[1] = Vector(1, 0.5, 0),
			[3] = Vector(0 /360, 180 /255-1, 180 /255),
		}
	},
}

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-- passive corrosion applier

LinkLuaModifier('m_item_corrosion_applier', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_corrosion_applier = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_corrosion_applier:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self.empower = {
			damage = 0,
			slow = 0,
			corruption = 0,
		}
		self.records = {}
		self.temporal = false
		self.temporal_destroyed = false

		self:RegisterSelfEvents()
	end
end

function m_item_corrosion_applier:OnRefresh()
	ReadAbilityData(self, {
		'corrosion_duration',
		'corrosion_corruption',
		'corrosion_damage',
		'corrosion_slow',
		'corrosion_id',
		'corrosion_bkb',
	})
end

function m_item_corrosion_applier:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_corrosion_applier:Empower(t)
	t = t or {}
	t.damage = t.damage or 0
	t.slow = t.slow or 0
	t.corruption = t.corruption or 0
	self.empower = t
end

function m_item_corrosion_applier:MakeTemporal()
	self.temporal = true
end

function m_item_corrosion_applier:DestroyTemporal()
	if self.temporal then
		self.temporal_destroyed = true
	end
end

function m_item_corrosion_applier:IsActive()
	return not self.temporal_destroyed
end

function m_item_corrosion_applier:OnParentAttackRecord(t)
	if not exist(t.target) or not t.target:IsBaseNPC() then
		return
	end

	if self:IsActive() then
		self.records[t.record] = {
			id = self.corrosion_id,
			bkb = self.corrosion_bkb,
			corruption = self.corrosion_corruption + self.empower.corruption,
			damage = self.corrosion_damage + self.empower.damage,
			slow = self.corrosion_slow + self.empower.slow,
		}
	end
end

function m_item_corrosion_applier:OnParentAttackRecordDestroy(t)
	self.records[t.record] = nil

	if self.temporal_destroyed and table.size(self.records) == 0 then
		self:Destroy()
	end
end

function m_item_corrosion_applier:OnParentAttackLanded(t)
	if not exist(t.target) or not t.target:IsAlive() then
		return
	end

	local poison = self.records[t.record]
	if poison then
		self:Apply(t.target, poison)
	end
end

function m_item_corrosion_applier:Apply(target, poison)
	local mod
	local ability = self:GetAbility()

	poison = poison or {}
	poison.id = poison.id or self.corrosion_id
	poison.bkb = poison.bkb or self.corrosion_bkb
	poison.corruption = poison.corruption or self.corrosion_corruption
	poison.damage = poison.damage or self.corrosion_damage
	poison.slow = poison.slow or self.corrosion_slow

	if (poison.bkb or 0) == 0 and target:IsMagicImmune() then
		return
	end

	for _, mod_other in ipairs(target:FindAllModifiersByName('m_item_corrosion_debuff')) do
		if mod_other.id == poison.id then
			mod = mod_other
			break
		end
	end

	if not mod then
		mod = AddModifier('m_item_corrosion_debuff',{
			hTarget = target,
			hCaster = self:GetParent(),
			hAbility = ability,
			id = poison.id,
		})
	end

	if mod and mod.UpdateCorrosion then
		mod:UpdateCorrosion({
			ability = ability,
			duration = self.corrosion_duration,
			corruption = poison.corruption,
			damage = poison.damage,
			slow = poison.slow,
			bkb = poison.bkb,
		})
	end
end

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-- passive corrosion debuff

LinkLuaModifier('m_item_corrosion_debuff', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_corrosion_debuff = ModifierClass{
	bMultiple = true,
	bDebuff = true,
}

function m_item_corrosion_debuff:IsDebuff()
	return true
end

function m_item_corrosion_debuff:IsPurgable()
	return self.bkb == 0
end
function m_item_corrosion_debuff:IsPurgeException()
	return self:IsPurgable()
end

function m_item_corrosion_debuff:OnCreated(t)
	if IsServer() then
		self.ability = self:GetAbility()
		self.id = t.id
		self.bkb = 0
		self.corruption = 0
		self.damage = 0
		self.slow = 0
		self.tick = 1

		local pdata = CORROSION_PARTICLES[self.id]
		if pdata and pdata.particle then
			self.particle = ParticleManager:Create(pdata.particle, self:GetParent())
			if pdata.controls then
				for control, v in pairs(pdata.controls) do
					ParticleManager:SetParticleControl(self.particle, control, v)
				end
			end
		end

		self:StartIntervalThink(self.tick - FrameTime())
	end
end

function m_item_corrosion_debuff:UpdateCorrosion(t)
	local parent = self:GetParent()
	local caster = self:GetCaster()
	t = t or {}

	if t.duration then
		local duration = t.duration * (1 - self:GetParent():GetStatusResistance())
		if duration > self:GetRemainingTime() then
			self.ability = t.ability
			self:SetDuration(duration, true)
		end
	end

	self.bkb = math.max(self.bkb, t.bkb or 0)
	self.damage = math.max(self.damage, t.damage or 0)

	if (t.slow or 0) > self.slow then
		self.slow = t.slow
		if not self.mod_slow then
			self.mod_slow = AddModifier('m_speed_pct', {
				hTarget = parent,
				hCaster = caster,
				hAbility = self:GetAbility(),
			})
		end
		if self.mod_slow then
			self.mod_slow:SetStackCount(-self.slow)
		end
	end

	if (t.corruption or 0) > self.corruption then
		self.corruption = t.corruption
		self.mod_armor = ApplyArmorReduction(parent, self.corruption, self.mod_armor)
	end
end

function m_item_corrosion_debuff:OnDestroy()
	if IsServer() then
		if exist(self.mod_slow) then
			self.mod_slow:Destroy()
		end
		if exist(self.mod_armor) then
			self.mod_armor:Destroy()
		end
		if self.particle then
			ParticleManager:Fade(self.particle, true)
		end
	end
end

function m_item_corrosion_debuff:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()

		if exist(self.ability) and self.damage > 0 then
			local damage = ApplyDamage({
				victim = parent,
				attacker = self:GetCaster(),
				ability = self.ability,
				damage = self.damage * self.tick,
				damage_type = self.ability:GetAbilityDamageType(),
			})

			if damage > 0 then
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage, nil)
			end
		end
	end
end

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-- active buff

LinkLuaModifier('m_item_camouflage_cover_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_camouflage_cover_active = ModifierClass{
	bPurgable = true,
	bDebuff = false,
}

function m_item_camouflage_cover_active:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
	}
end

function m_item_camouflage_cover_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
	}
end


function m_item_camouflage_cover_active:GetModifierInvisibilityLevel()
	return 1
end

function m_item_camouflage_cover_active:OnCreated(t)
	ReadAbilityData(self, {
		'active_radius',
		'active_max_stack',
		'active_max_damage',
		'active_max_slow',
	})

	if IsServer() then
		self.time_start = self.time_start or GameRules:GetGameTime()
		self.charge = self.charge or 0
		self.parent = self:GetParent()
		self.center = self.parent:GetOrigin()

		self.applier = self.parent:AddNewModifier(self:GetCaster(), self:GetAbility(), 'm_item_corrosion_applier', {})
		if self.applier then
			self.applier:MakeTemporal()
			self:ApplyEmpower()
		end

		self.particle = 'particles/units/heroes/hero_monkey_king/monkey_king_furarmy_ring_bright.vpcf'
		self.particle = ParticleManager:CreateParticleForTeam(self.particle, PATTACH_WORLDORIGIN, nil, self.parent:GetTeam())
		ParticleManager:SetParticleControl(self.particle, 0, self.center)
		ParticleManager:SetParticleControl(self.particle, 1, Vector(self.active_radius, 0, 0))
		ParticleManager:SetParticleControl(self.particle, 62, Vector(0.3, 0, 0))

		self:StartIntervalThink(FrameTime())

		self:RegisterSelfEvents()

		PreventAttack(self.parent)
	end
end

function m_item_camouflage_cover_active:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

function m_item_camouflage_cover_active:OnDestroy()
	if IsServer() then
		if exist(self.applier) then
			self.applier:DestroyTemporal()
		end

		if self.particle then
			ParticleManager:Fade(self.particle, true)
		end

		self:UnregisterSelfEvents()
	end
end

function m_item_camouflage_cover_active:OnIntervalThink()
	if IsServer() then
		local distance = (self.parent:GetOrigin() - self.center):Length2D()
		if distance > self.active_radius then
			self:Destroy()
			return
		end

		local charge = math.min(self.active_max_stack, math.floor(GameRules:GetGameTime() - self.time_start))
		if charge ~= self.charge then
			self.charge = charge
			self:SetStackCount(charge)
			self:ApplyEmpower()
		end
	end
end

function m_item_camouflage_cover_active:ApplyEmpower()
	if exist(self.applier) then
		local k = self.charge / self.active_max_stack
		self.applier:Empower({
			damage = self.active_max_damage * k,
			slow = self.active_max_slow * k,
		})
	end
end

function m_item_camouflage_cover_active:OnParentAttack()
	self:Destroy()
end