LinkLuaModifier('m_warlock_upheaval_kbw', "kbw/abilities/heroes/warlock/upheaval", 0)
LinkLuaModifier('m_warlock_upheaval_kbw_effect', "kbw/abilities/heroes/warlock/upheaval", 0)

warlock_upheaval_kbw = class{}

function warlock_upheaval_kbw:GetAOERadius()
	return self:GetSpecialValueFor('aoe')
end

function warlock_upheaval_kbw:GetBehavior()
	if self:GetCaster():HasShard() then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end
	return self.BaseClass.GetBehavior(self)
end

function warlock_upheaval_kbw:GetChannelTime()
	if self:GetCaster():HasShard() then
		return 0
	end
	return self:GetSpecialValueFor('max_duration')
end

function warlock_upheaval_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	local vPos = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor('max_duration')

	self.nStartTime = GameRules:GetGameTime()

	local hMarker = CreateModifierThinker(
		hCaster,
		self,
		'm_warlock_upheaval_kbw',
		{},
		vPos,
		hCaster:GetTeam(),
		false
	)
	self.hMarker = hMarker
	
	Timer(duration + FrameTime(), function()
		if exist(hMarker) then
			hMarker:Kill(nil, nil)
		end
	end)
end

function warlock_upheaval_kbw:OnChannelFinish(bInterrupt)
	if exist(self.hMarker) then
		self.hMarker:Kill(nil, nil)
	end
end

m_warlock_upheaval_kbw = ModifierClass{}

function m_warlock_upheaval_kbw:OnCreated()
	ReadAbilityData(self, {
		'aoe',
		'duration',
	})

	if IsServer() then
		local hParent = self:GetParent()

		local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_warlock_upheaval_kbw_attack_speed')
		if hTalent and hTalent:IsTrained() then
			self.nTeamFilter = DOTA_UNIT_TARGET_TEAM_BOTH
		else
			self.nTeamFilter = DOTA_UNIT_TARGET_TEAM_ENEMY
		end

		hParent:EmitSound('Hero_Warlock.Upheaval')

		self.nParticle = ParticleManager:CreateParticle('particles/units/heroes/hero_warlock/warlock_upheaval.vpcf', PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.nParticle, 0, hParent:GetOrigin())
		ParticleManager:SetParticleControl(self.nParticle, 1, Vector(self.aoe, 0, 0))
		ParticleManager:SetParticleFoWProperties(self.nParticle, 0, 0, self.aoe)
	end
end

function m_warlock_upheaval_kbw:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)

		self:GetParent():StopSound('Hero_Warlock.Upheaval')
	end
end

function m_warlock_upheaval_kbw:IsAura()
	return true
end

function m_warlock_upheaval_kbw:GetModifierAura()
	return 'm_warlock_upheaval_kbw_effect'
end

function m_warlock_upheaval_kbw:GetAuraRadius()
	return self.aoe
end

function m_warlock_upheaval_kbw:GetAuraDuration()
	return self.duration
end

function m_warlock_upheaval_kbw:GetAuraSearchTeam()
	return self.nTeamFilter
end

function m_warlock_upheaval_kbw:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

m_warlock_upheaval_kbw_effect = ModifierClass{
	bPurgable = true,
}

function m_warlock_upheaval_kbw_effect:IsDebuff()
	return self.bDebuff
end

function m_warlock_upheaval_kbw_effect:OnCreated()
	ReadAbilityData(self, {
		'slow_per_second',
		'max_slow',
		'update_tick',
		'damage',
	})

	self.bDebuff = (self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber())

	if IsServer() then
		self.attack_speed = 0
		self.damage = self.damage * self.update_tick
		self.nStartTime = self:GetAbility().nStartTime

		if not self.bDebuff then
			local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_warlock_upheaval_kbw_attack_speed')
			if hTalent and hTalent:IsTrained() then
				self.attack_speed = hTalent:GetSpecialValueFor('value')
			end
		end

		if self.bDebuff then
			self.nParticle = ParticleManager:Create('particles/units/heroes/hero_warlock/warlock_upheaval_debuff.vpcf', self:GetParent())
		end

		-- self:OnIntervalThink()
		self:StartIntervalThink(0.2)
	end
end

function m_warlock_upheaval_kbw_effect:OnDestroy()
	if IsServer() then
		if self.nParticle then
			ParticleManager:Fade(self.nParticle, true)
		end
	end
end

function m_warlock_upheaval_kbw_effect:OnIntervalThink()
	if self:IsDebuff() then
		local nSlow = math.min(self.max_slow, (GameRules:GetGameTime() - self.nStartTime) * self.slow_per_second)
		self:SetStackCount(nSlow)

		ApplyDamage({
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = self.damage,
			damage_type = DAMAGE_TYPE_MAGICAL
		})
	else
		local nAttackSpeed = (GameRules:GetGameTime() - self.nStartTime) * self.attack_speed
		self:SetStackCount(nAttackSpeed)
	end

	self:StartIntervalThink(self.update_tick)
end

function m_warlock_upheaval_kbw_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function m_warlock_upheaval_kbw_effect:GetModifierMoveSpeedBonus_Percentage()
	if self:IsDebuff() then
		return -self:GetStackCount()
	end
end

function m_warlock_upheaval_kbw_effect:GetModifierAttackSpeedBonus_Constant()
	if not self:IsDebuff() then
		return self:GetStackCount()
	end
end