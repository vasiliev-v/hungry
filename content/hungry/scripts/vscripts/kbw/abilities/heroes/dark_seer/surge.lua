LinkLuaModifier('m_dark_seer_surge_kbw', "kbw/abilities/heroes/dark_seer/surge", 0)

dark_seer_surge_kbw = class{}

function dark_seer_surge_kbw:GetAoeTalent()
	local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_dark_seer_surge_aoe')
	if hTalent and hTalent:GetLevel() > 0 then
		return hTalent
	end
end

function dark_seer_surge_kbw:GetBehavior()
	if self:GetAoeTalent() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end
	return self.BaseClass.GetBehavior(self)
end

function dark_seer_surge_kbw:GetAOERadius()
	local hTalent = self:GetAoeTalent()
	if hTalent then
		return hTalent:GetSpecialValueFor('radius')
	end
	return 0
end

function dark_seer_surge_kbw:OnSpellStart()
	local hTalent = self:GetAoeTalent()
	local hTarget = self:GetCursorTarget()
	local nDuration = self:GetSpecialValueFor('duration')
	local nPathing = self:GetSpecialValueFor('pathing')

	if hTalent then
		local vTarget = self:GetCursorPosition()
		if exist(hTarget) then
			vTarget = hTarget:GetOrigin()
		end

		local qUnits = Find:UnitsInRadius({
			vCenter = vTarget,
			nRadius = hTalent:GetSpecialValueFor('radius'),
			nTeam = self:GetCaster():GetTeam(),
			nFilterTeam = self:GetAbilityTargetTeam(),
			nFilterType = self:GetAbilityTargetType(),
			nFilterFlag = self:GetAbilityTargetFlags(),
		})

		for _, hUnit in ipairs(qUnits) do
			self:Effect({
				hTarget = hUnit,
				nDuration = nDuration,
			})
		end
	else
		self:Effect({
			hTarget = hTarget,
			nDuration = nDuration,
		})
	end
end

function dark_seer_surge_kbw:Effect(t)
	if not t or not exist(t.hTarget) then
		return
	end

	t.nDuration = t.nDuration or self:GetSpecialValueFor('duration')
	t.nPathing = t.nPathing or self:GetSpecialValueFor('pathing')

	AddModifier('m_dark_seer_surge_kbw', {
		hTarget = t.hTarget,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = t.nDuration,
		pathing = t.nPathing,
	})

	t.hTarget:EmitSound('Hero_Dark_Seer.Surge')
end

m_dark_seer_surge_kbw = ModifierClass{
	bMultiple = true,
	bPurgable = true,
}

function m_dark_seer_surge_kbw:OnCreated(t)
	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf', hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)
	end

	self:OnRefresh(t)
end

function m_dark_seer_surge_kbw:OnRefresh(t)
	ReadAbilityData(self, {
		'speed',
	})
	
	if IsServer() then
		if t.pathing and t.pathing ~= 0 then
			self.bPathing = true
			self.hModPathing = self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), 'm_kbw_no_speed_limit', {})			
		end
	end
end

function m_dark_seer_surge_kbw:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)

		if exist(self.hModPathing) then
			self.hModPathing:Destroy()
		end
	end
end

function m_dark_seer_surge_kbw:CheckState()
	return {
		[MODIFIER_STATE_UNSLOWABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = self.bPathing,
	}
end

function m_dark_seer_surge_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}
end

function m_dark_seer_surge_kbw:GetModifierMoveSpeedBonus_Constant()
	return self.speed
end