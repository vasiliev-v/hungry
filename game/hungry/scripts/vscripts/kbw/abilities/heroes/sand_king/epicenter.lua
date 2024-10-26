local sPath = "kbw/abilities/heroes/sand_king/epicenter"
LinkLuaModifier('m_sand_king_epicenter_kbw', sPath, 0)
LinkLuaModifier('m_sand_king_epicenter_kbw_debuff', sPath, 0)
LinkLuaModifier('m_sand_king_epicenter_kbw_shard_tracker', sPath, 0)

sand_king_epicenter_kbw = class{}

function sand_king_epicenter_kbw:GetIntrinsicModifierName()
	return 'm_sand_king_epicenter_kbw_shard_tracker'
end

function sand_king_epicenter_kbw:OnAbilityPhaseStart()
	local hCaster = self:GetCaster()
	
	self.nCastParticle = ParticleManager:Create('particles/units/heroes/hero_sandking/sandking_epicenter_tell.vpcf', PATTACH_CUSTOMORIGIN, hCaster)
	ParticleManager:SetParticleControlEnt(self.nCastParticle, 0, hCaster, PATTACH_POINT_FOLLOW, 'attach_tail', hCaster:GetOrigin(), false)

	hCaster:EmitSound('Ability.SandKing_Epicenter.spell')

	return true
end

function sand_king_epicenter_kbw:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound('Ability.SandKing_Epicenter.spell')
	self:StopParticle()
end

function sand_king_epicenter_kbw:StopParticle()
	if self.nCastParticle then
		ParticleManager:Fade(self.nCastParticle, true)
		self.nCastParticle = nil
	end
end

function sand_king_epicenter_kbw:OnSpellStart()
	self:StopParticle()	

	local hCaster = self:GetCaster()

	AddModifier('m_sand_king_epicenter_kbw', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor('pulses') * self:GetSpecialValueFor('interval'),
	})
end

function sand_king_epicenter_kbw:Affect(t)
	t = t or {}
	t.nRadius = t.nRadius or self:GetSpecialValueFor('radius')
	t.nDamage = t.nDamage or self:GetSpecialValueFor('damage')
	t.nDuration = t.nDuration or self:GetSpecialValueFor('slow_duration')
	local hCaster = self:GetCaster()
	local nDamageType = self:GetAbilityDamageType()
	local vPos = hCaster:GetOrigin()

	local qUnits = Find:UnitsInRadius({
		vCenter = vPos,
		nRadius = t.nRadius,
		nTeam = hCaster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
		nFilterFlag = 0,
	})

	for _, hUnit in ipairs(qUnits) do
		AddModifier('m_sand_king_epicenter_kbw_debuff', {
			hTarget = hUnit,
			hCaster = hCaster,
			hAbility = self,
			duration = t.nDuration,
		})

		ApplyDamage({
			victim = hUnit,
			attacker = hCaster,
			ability = self,
			damage = t.nDamage,
			damage_type = nDamageType,
		})
	end

	local nParticle = ParticleManager:Create('particles/units/heroes/hero_sandking/sandking_epicenter.vpcf', PATTACH_WORLDORIGIN, 3)
	ParticleManager:SetParticleControl(nParticle, 0, vPos)
	ParticleManager:SetParticleControl(nParticle, 1, Vector(t.nRadius, t.nRadius, t.nRadius))

	hCaster:EmitSound('Hero_Sandking.EpiPulse')
end

m_sand_king_epicenter_kbw = ModifierClass{
	bMultiple = true,
}

function m_sand_king_epicenter_kbw:DestroyOnExpire()
	return false
end

function m_sand_king_epicenter_kbw:OnCreated(t)
	if IsServer() then
		self.hParent = self:GetParent()

		ReadAbilityData(self, {
			'radius',
			'pulses',
			'damage',
			'interval',
			'slow_duration',
		})

		self:StartIntervalThink(self.interval)

		self.hParent:EmitSound('Ability.SandKing_Epicenter')
	end
end

function m_sand_king_epicenter_kbw:OnDestroy()
	if IsServer() then
		self.hParent:StopSound('Ability.SandKing_Epicenter')
	end
end

function m_sand_king_epicenter_kbw:OnIntervalThink()
	if IsServer() then
		local hAbility = self:GetAbility()
		if hAbility then
			hAbility:Affect({
				nRadius = self.radius,
				nDamage = self.damage,
				nDuration = self.slow_duration,
			})
		end

		if self.pulses < 2 then
			self:Destroy()
		else
			self.pulses = self.pulses - 1
		end
	end
end

m_sand_king_epicenter_kbw_debuff = ModifierClass{
	bPurgable = true,
}

function m_sand_king_epicenter_kbw_debuff:OnCreated(t)
	self:OnRefresh(t)
end

function m_sand_king_epicenter_kbw_debuff:OnRefresh(t)
	ReadAbilityData(self, {
		'slow',
		'slow_as',
	})
end

function m_sand_king_epicenter_kbw_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function m_sand_king_epicenter_kbw_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function m_sand_king_epicenter_kbw_debuff:GetModifierAttackSpeedBonus_Constant()
	return -self.slow_as
end

m_sand_king_epicenter_kbw_shard_tracker = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_sand_king_epicenter_kbw_shard_tracker:OnCreated()
	if IsServer() then
		if self:GetParent():IsIllusion() then
			return
		end

		ReadAbilityData(self, {'shard_distance'})

		self.hParent = self:GetParent()
		self.hAbility = self:GetAbility()
		self.vPos = self.hParent:GetOrigin()
		self.nDistance = 0
		self:StartIntervalThink(1/30)
	end
end

function m_sand_king_epicenter_kbw_shard_tracker:OnIntervalThink()
	if IsServer() then
		local vPos = self.hParent:GetOrigin()

		if self.hParent:HasShard() then
			local nDelta = (vPos - self.vPos):Length2D()
			self.nDistance = self.nDistance + nDelta
			if self.nDistance >= self.shard_distance then
				self.nDistance = self.nDistance % self.shard_distance

				if self.hAbility and self.hAbility.Affect then
					self.hAbility:Affect()
				end
			end
		end

		self.vPos = vPos
	end
end