local PATH = "kbw/abilities/heroes/storm_spirit/vortex"

LinkLuaModifier('m_storm_spirit_vortex_kbw', PATH, LUA_MODIFIER_MOTION_NONE)

storm_spirit_vortex_kbw = class{}

function storm_spirit_vortex_kbw:GetBehavior()
	local base = tonumber(tostring(self.BaseClass.GetBehavior(self)))
	if self:GetCaster():HasScepter() then
		return bit.bor(base, DOTA_ABILITY_BEHAVIOR_AUTOCAST)
	end
	return base
end

function storm_spirit_vortex_kbw:ShouldFollow()
	if IsServer() then
		return self:GetCaster():HasScepter() and self:GetAutoCastState()
	end
	return self:GetCaster():HasScepter()
end

function storm_spirit_vortex_kbw:CastFilterResultTarget(target)
	local caster = self:GetCaster()

	if target == caster then
		return -1
	end

	local target_team = GetAbilityTargetTeam(self)
	local target_type = GetAbilityTargetType(self)
	local target_flag = GetAbilityTargetFlags(self)
	if self:ShouldFollow() then
		target_team = bit.bor(target_team, DOTA_UNIT_TARGET_TEAM_FRIENDLY)
	end
	return UnitFilter(target, target_team, target_type, target_flag, caster:GetTeamNumber())
end

function storm_spirit_vortex_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor('duration')

	if not target then
		return
	end

	if target:GetTeam() ~= caster:GetTeam() and target:TriggerSpellAbsorb(self) then
		return
	end

	AddModifier('m_storm_spirit_vortex_kbw', {
		hTarget = target,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})

	caster:EmitSound('Hero_StormSpirit.ElectricVortexCast')
	target:EmitSound('Hero_StormSpirit.ElectricVortex')
end

m_storm_spirit_vortex_kbw = ModifierClass{}

function m_storm_spirit_vortex_kbw:IsStunDebuff()
	return true
end

function m_storm_spirit_vortex_kbw:IsPurgable()
	return false
end

function m_storm_spirit_vortex_kbw:IsPurgeException()
	return true
end

function m_storm_spirit_vortex_kbw:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()

		self.particle = ParticleManager:Create('particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf', PATTACH_CUSTOMORIGIN)
		ParticleManager:SetParticleControl(self.particle, 0, self.targetpos)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', parent:GetOrigin(), false)

		self:StartIntervalThink(FrameTime())
	end

end

function m_storm_spirit_vortex_kbw:OnRefresh()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	self.ally = (caster:GetTeamNumber() == parent:GetTeamNumber())

	ReadAbilityData(self, {
		'pull_speed',
		'scepter_consume_distance',
		'scepter_consume_duration',
		'scepter_min_lesh_range',
	})

	if IsServer() then
		local ability = self:GetAbility()
		self.scepter = ability and ability.ShouldFollow and ability:ShouldFollow()
		self.lasttime = GameRules:GetGameTime()
		self.endtime = self.lasttime + self:GetRemainingTime()
		self.targetpos = GetGroundPosition(caster:GetOrigin(), caster)
		self.oldpos = parent:GetOrigin()
	end
end

function m_storm_spirit_vortex_kbw:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()

		FindClearSpaceForUnit(parent, parent:GetOrigin(), false)

		ParticleManager:Fade(self.particle, true)
	end
end

function m_storm_spirit_vortex_kbw:OnIntervalThink()
	local parent = self:GetParent()
	local pos = parent:GetOrigin()
	local time = GameRules:GetGameTime()
	local dt = time - self.lasttime
	local delta = self.pull_speed * dt
	local lesh_offset = 0

	if self.scepter then
		local caster = self:GetCaster()
		local targetpos = GetGroundPosition(caster:GetOrigin(), caster)
		local olddistance = (self.targetpos - self.oldpos):Length2D()
		local newdistance = (targetpos - self.oldpos):Length2D()
		local extradelta = math.max(0, newdistance - olddistance)
		delta = delta + extradelta
		lesh_offset = self.scepter_min_lesh_range

		ParticleManager:SetParticleControl(self.particle, 0, targetpos)

		if not self.ally then
			self.endtime = self.endtime - extradelta * self.scepter_consume_duration / self.scepter_consume_distance
		end

		self.targetpos = targetpos
		self.oldpos = pos
	end

	local dir = self.targetpos - pos
	dir.z = 0
	local maxdelta = math.max(0, #dir - lesh_offset)
	dir = dir:Normalized()

	pos = pos + dir * math.min(delta, maxdelta)
	if not parent:IsCurrentlyVerticalMotionControlled() then
		pos = GetGroundPosition(pos, parent)
	end
	parent:SetAbsOrigin(pos)

	if time >= self.endtime then
		self:Destroy()
	end

	self.lasttime = time
end

function m_storm_spirit_vortex_kbw:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	if self.ally then
		state[MODIFIER_STATE_ROOTED] = true
		state[MODIFIER_STATE_UNTARGETABLE] = true
	else
		state[MODIFIER_STATE_STUNNED] = true
	end

	return state
end

function m_storm_spirit_vortex_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function m_storm_spirit_vortex_kbw:GetOverrideAnimation()
	if not self.ally then
		return ACT_DOTA_FLAIL
	end
end

function m_storm_spirit_vortex_kbw:GetModifierProvidesFOWVision()
	return 1
end