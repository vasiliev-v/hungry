local PATH = 'kbw/abilities/heroes/slardar/corrosive_haze'

slardar_corrosive_haze_kbw = class{}

---------------------------------------------------------
-- passive tracker

function slardar_corrosive_haze_kbw:GetIntrinsicModifierName()
	return 'm_slardar_corrosive_haze_kbw_passive_tracker'
end

---------------------------------------------------------
-- targeting

function slardar_corrosive_haze_kbw:GetAOERadius()
	return self:GetSpecialValueFor('aoe')
end

function slardar_corrosive_haze_kbw:GetBehavior()
	if self:GetAOERadius() > 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end
	return self.BaseClass.GetBehavior(self)
end

---------------------------------------------------------
-- active

function slardar_corrosive_haze_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local pos = self:GetCursorPosition()
	local aoe = self:GetAOERadius()

	if exist(target) then
		if target:TriggerSpellAbsorb(self) then
			return
		end

		pos = target:GetOrigin()
	end

	if aoe > 0 then
		local victims = FindUnitsInRadius(
			caster:GetTeam(),
			pos,
			nil,
			aoe,
			GetAbilityTargetTeam(self),
			GetAbilityTargetType(self),
			GetAbilityTargetFlags(self),
			FIND_ANY_ORDER,
			false
		)

		for _, victim in ipairs(victims) do
			self:AffectUnit({
				target = victim,
			})
		end
	else
		if not exist(target) then
			return
		end

		self:AffectUnit({
			target = target,
		})
	end
end

function slardar_corrosive_haze_kbw:AffectUnit(t)
	if type(t) ~= 'table' or not t.target then
		return
	end

	t.duration = t.duration or self:GetSpecialValueFor('duration')

	t.target:RemoveModifierByName('m_slardar_corrosive_haze_kbw_debuff')

	AddModifier('m_slardar_corrosive_haze_kbw_debuff', {
		hTarget = t.target,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = t.duration,
	})

	t.target:EmitSound('Hero_Slardar.Amplify_Damage')
end

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- active debuff

LinkLuaModifier('m_slardar_corrosive_haze_kbw_debuff', PATH, LUA_MODIFIER_MOTION_NONE)
m_slardar_corrosive_haze_kbw_debuff = ModifierClass{
	bPurgable = true,
}

function m_slardar_corrosive_haze_kbw_debuff:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function m_slardar_corrosive_haze_kbw_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_slardar_corrosive_haze_kbw_debuff:GetModifierProvidesFOWVision(t)
	if exist(t.target) and self:GetCaster():GetTeamNumber() == t.target:GetTeamNumber() then
		if not HasState(self:GetParent(), MODIFIER_STATE_TRUESIGHT_IMMUNE) then
			return 1
		end
	end
end

function m_slardar_corrosive_haze_kbw_debuff:GetModifierPhysicalArmorBonus()
	return -self.armor_reduction
end

---------------------------------------------------------
-- active debuff lifecycle

function m_slardar_corrosive_haze_kbw_debuff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()

		self.aura = CreateAura({
			sModifier = 'modifier_slardar_puddle',
			aLine = {},
			bLineDiscrete = true,
			nRadius = self.puddle_radius,
			hAbility = self:GetAbility(),
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
			fCondition = function(unit)
				return unit:HasAbility('slardar_sprint')
			end,
		})

		self.truesight = self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_truesight', {})

		self.particle = ParticleManager:Create('particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControlEnt(self.particle, 2, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)

		self:OnIntervalThink()
		self:StartIntervalThink(0.1)
	end
end

function m_slardar_corrosive_haze_kbw_debuff:OnRefresh()
	ReadAbilityData(self, {
		'armor_reduction',
		'puddle_radius',
		'puddle_duration',
	})
end

function m_slardar_corrosive_haze_kbw_debuff:OnDestroy()
	if IsServer() then
		Timer(self.puddle_duration, function()
			self.fReduceAura(self.aura)
		end)

		if exist(self.truesight) then
			self.truesight:Destroy()
		end

		ParticleManager:Fade(self.particle, true)
	end
end

---------------------------------------------------------
-- active debuff water trail

function m_slardar_corrosive_haze_kbw_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local pos = parent:GetOrigin()
	local aura = self.aura
	local length = #aura.aLine
	local last_point = aura.aLine[length]

	if last_point and (pos - last_point.pos):Length2D() < self.puddle_radius - 12 then
		return
	end

	if last_point then
		Timer(self.puddle_duration, function()
			self.fReduceAura(aura)
		end)
	end

	local new_point = aura:AddLinePoint(pos)

	new_point.particle = ParticleManager:Create('particles/units/heroes/hero_slardar/slardar_water_puddle_test.vpcf', PATTACH_WORLDORIGIN)
	ParticleManager:SetParticleControl(new_point.particle, 0, GetGroundPosition(pos, nil))
	ParticleManager:SetParticleControl(new_point.particle, 1, Vector(self.puddle_radius, 1, 1))
	ParticleManager:SetParticleFoWProperties(new_point.particle, 0, 0, self.puddle_radius)
end

function m_slardar_corrosive_haze_kbw_debuff.fReduceAura(aura)
	if not exist(aura) then
		return
	end

	local last_point = aura.aLine[1]

	if last_point then
		ParticleManager:Fade(last_point.particle, true)
		aura:RemoveLinePoint(last_point)
	end
end

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- passive tracker

LinkLuaModifier('m_slardar_corrosive_haze_kbw_passive_tracker', PATH, LUA_MODIFIER_MOTION_NONE)
m_slardar_corrosive_haze_kbw_passive_tracker = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_slardar_corrosive_haze_kbw_passive_tracker:OnCreated()
	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_slardar_corrosive_haze_kbw_passive_tracker:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_slardar_corrosive_haze_kbw_passive_tracker:OnParentDealDamage(t)
	if t.attacker:HasShard() and exist(t.inflictor) and t.inflictor:GetName() == 'slardar_slithereen_crush' then
		local ability = self:GetAbility()
		if ability then
			local original_damage = GetOriginalDamageWithArmor(t.damage, t.unit)

			-- apply corrosive haze
			ability:AffectUnit({
				target = t.unit,
				duration = t.inflictor:GetSpecialValueFor('shard_amp_duration'),
			})

			-- compensate armor damage difference
			local delta = GetDamageWithArmor(original_damage, t.unit) - t.damage
			if delta > 1 then
				ApplyDamage({
					victim = t.unit,
					attacker = t.attacker,
					ability = t.inflictor,
					damage = GetOriginalDamageWithArmor(delta, t.unit),
					damage_type = DAMAGE_TYPE_PHYSICAL,
				})
			end
		end
	end
end