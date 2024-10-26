local sPath = "kbw/items/levels/static_amulet"
local base = {}

local TARGET_TEAM = DOTA_UNIT_TARGET_TEAM_ENEMY
local TARGET_TYPE = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
local TARGET_FLAG = DOTA_UNIT_TARGET_FLAG_NONE

function base:Precache(hContext)
	PrecacheResource('particle', 'particles/items/static_amulet/debuff.vpcf', hContext)
	PrecacheResource('particle', 'particles/econ/events/ti10/maelstrom_ti10.vpcf', hContext)
end

-------------------------------------------
-- targeting

function base:CastFilterResultTarget(hTarget)
	local nFilter = UnitFilter(
		hTarget,
		TARGET_TEAM,
		TARGET_TYPE,
		TARGET_FLAG,
		self:GetCaster():GetTeamNumber()
	)

	if nFilter ~= UF_SUCCESS then
		return nFilter
	end

	if self:GetCurrentCharges() <= 0 then
		return UF_FAIL_CUSTOM
	end

	if hTarget:HasModifier('m_static_amulet_debuff') then
		return UF_FAIL_OTHER
	end

	return UF_SUCCESS
end

function base:GetCustomCastErrorTarget(hTarget)
	return '#dota_hud_error_no_charges'
end

-------------------------------------------
-- active

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	if not hTarget:TriggerSpellAbsorb(self) then
		AddModifier('m_static_amulet_debuff', {
			hTarget = hTarget,
			hCaster = self:GetCaster(),
			hAbility = self,
			duration = self:GetSpecialValueFor('active_duration') + 0.1,
		})
	end

	if hCaster.nRuneCharges and hCaster.nRuneCharges > 0 then
		hCaster.nRuneCharges = hCaster.nRuneCharges - 1
		self:SetCurrentChargesKBW(hCaster.nRuneCharges)
	end
end

-------------------------------------------
-- active strike

function base:Lightning(t)
	if not t or not exist(t.target) then
		return
	end

	local caster = self:GetCaster()
	local center = t.target:GetOrigin()
	local range = self:GetSpecialValueFor('active_damage_range')
	local targets = self:GetSpecialValueFor('active_damage_targets')

	t = table.copy(t or {})
	t.damage = t.damage or t.target:GetHealth() * self:GetSpecialValueFor('active_damage_pct') / 100

	local units = FindUnitsInRadius(
		caster:GetTeam(),
		center,
		t.target,
		range,
		TARGET_TEAM,
		TARGET_TYPE,
		TARGET_FLAG,
		FIND_CLOSEST,
		false
	)

	if units[1] ~= t.target then
		table.insert(units, 1, t.target)
	end

	for i = 1, targets + 1 do
		local target = units[i]
		if target then
			target:Purge(true, false, false, false, false)

			ApplyDamage({
				victim = target,
				attacker = caster,
				ability = self,
				damage = t.damage,
				damage_type = DAMAGE_TYPE_PURE,
				damage_flags = DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT
							+ DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
							+ DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
			})

			local particle = ParticleManager:Create('particles/econ/events/ti10/maelstrom_ti10.vpcf', PATTACH_CUSTOMORIGIN, t.target, 1)
			ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, 'attach_hitloc', target:GetOrigin(), false)
			if target == t.target then
				ParticleManager:SetParticleControl(particle, 0, center + Vector(0,0,1400))
			else
				ParticleManager:SetParticleControlEnt(particle, 0, t.target, PATTACH_POINT_FOLLOW, 'attach_hitloc', center, false)
			end

			target:EmitSound('Hero_Disruptor.ThunderStrike.Target')
		else
			break
		end
	end
end

-------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_static_amulet_stats = 0,
		m_static_amulet = self.nLevel,
	}
end

-------------------------------------------
-- charges

function base:SetCurrentChargesKBW(nCharges)
	if IsServer() then
		local hCaster = self:GetCaster()
		nCharges = math.min(self:GetSpecialValueFor('stack_max'), nCharges)
		hCaster.nRuneCharges = math.max(hCaster.nRuneCharges or 0, nCharges)

		IterateInventory(hCaster, 'INVENTORY', function(nSlot, hItem)
			if hItem and hItem:GetName():match('^item_static_amulet') then
				hItem:SetCurrentCharges(nCharges)
			end
		end)
	end
end

-------------------------------------------
-- levels

CreateLevels({
	'item_static_amulet',
	'item_static_amulet_2',
	'item_static_amulet_3',
}, base)

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- passive stackable

LinkLuaModifier('m_static_amulet_stats', sPath, LUA_MODIFIER_MOTION_NONE)
m_static_amulet_stats = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_static_amulet_stats:OnCreated()
	ReadAbilityData(self, {
		'int',
		'str',
		'agi',
		'hp_regen',
		'mp_regen',
	}, function(hAbility)
		if IsServer() then
			Timer(1/30, function()
				if exist(self) and exist(hAbility) then
					hAbility:SetCurrentChargesKBW(self:GetParent().nRuneCharges or 0)
				end
			end)
		end
	end)
end

function m_static_amulet_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_static_amulet_stats:GetModifierBonusStats_Strength()
	return self.str
end
function m_static_amulet_stats:GetModifierBonusStats_Agility()
	return self.agi
end
function m_static_amulet_stats:GetModifierBonusStats_Intellect()
	return self.int
end
function m_static_amulet_stats:GetModifierConstantHealthRegen()
	return self.hp_regen
end
function m_static_amulet_stats:GetModifierConstantManaRegen()
	return self.mp_regen
end

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- passive unique

LinkLuaModifier('m_static_amulet', sPath, LUA_MODIFIER_MOTION_NONE)
m_static_amulet = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_static_amulet:OnCreated()
	ReadAbilityData(self, {
		'stack_max',
		'stack_hp_regen',
		'stack_mp_regen',
	}, function(hAbility)
		if IsServer() and exist(hAbility) then
			local hParent = self:GetParent()

			-- rune charges
			self.hListener = Events:Register('CustomRunePickup', function(hRune, hUnit)
				if hUnit == hParent and exist(hAbility) then
					if not hRune.bCharged then
						hRune.bCharged = true
						if not hParent.nRuneCharges or hParent.nRuneCharges < self.stack_max then
							hParent.nRuneCharges = (hParent.nRuneCharges or 0) + 1
						end
					end
					hAbility:SetCurrentChargesKBW(hParent.nRuneCharges or 0)
				end
			end)
		end
	end)
end

function m_static_amulet:OnDestroy()
	if IsServer() then
		if exist(self.hListener) then
			self.hListener:Destroy()
		end
	end
end

function m_static_amulet:GetCurrentCharges()
	local hAbility = self:GetAbility()
	if hAbility then
		return hAbility:GetCurrentCharges()
	end
	return 0
end

-------------------------------------------
-- passive stats

function m_static_amulet:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_static_amulet:GetModifierConstantHealthRegen()
	return self:GetCurrentCharges() * self.stack_hp_regen
end
function m_static_amulet:GetModifierConstantManaRegen()
	return self:GetCurrentCharges() * self.stack_mp_regen
end

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- active debuff

LinkLuaModifier('m_static_amulet_debuff', sPath, LUA_MODIFIER_MOTION_NONE)
m_static_amulet_debuff = ModifierClass{
	bPurgable = true,
}

function m_static_amulet_debuff:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function m_static_amulet_debuff:OnCreated()
	ReadAbilityData(self, {
		'active_interval',
		'active_threshold_pct',
		'active_damage_pct',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self.spell_damage = 0
		self.next_lighning = -1

		self:RegisterSelfEvents()

		self.particle1 = ParticleManager:CreateParticle('particles/items/static_amulet/debuff.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControlEnt(self.particle1, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControlEnt(self.particle1, 1, hParent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)

		hParent:EmitSound('Hero_Disruptor.ThunderStrike.Target')
		self.sound_stop = PlaySound('KBW.Item.StaticAmulet', hParent, DOTA_TEAM_NEUTRALS, -1)
	end
end

function m_static_amulet_debuff:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		local ability = self:GetAbility()

		Timer(FrameTime(), function()
			if exist(ability) then
				ability:Lightning({
					target = parent,
				})
			end
		end)

		self:UnregisterSelfEvents()

		ParticleManager:Fade(self.particle1, true)

		self.sound_stop()
	end
end

function m_static_amulet_debuff:OnParentTakeDamage(t)
	if t.inflictor and not t.inflictor:GetName():match('item_static_amulet') then
		self.spell_damage = self.spell_damage + t.damage

		local parent = self:GetParent()
		local health = parent:GetHealth()
		local threshold = parent:GetMaxHealth() * self.active_threshold_pct / 100

		while self.spell_damage > threshold do
			self.spell_damage = self.spell_damage - threshold

			local was_health = health + self.spell_damage

			self:DelayLightning({
				damage = was_health * self.active_damage_pct / 100
			})
		end
	end
end

function m_static_amulet_debuff:DelayLightning(t)
	t = table.copy(t or {})
	t.target = self:GetParent()

	local time = GameRules:GetGameTime()
	local delay = math.max(0, self.next_lighning - time)
	local ability = self:GetAbility()

	self.next_lighning = time + delay + self.active_interval

	Timer(delay, function()
		if exist(ability) and (exist(self) or (exist(t.target) and not t.target:IsAlive())) then
			ability:Lightning(t)
		end
	end)
end