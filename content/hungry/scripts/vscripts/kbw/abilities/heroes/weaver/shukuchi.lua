local sPath = "kbw/abilities/heroes/weaver/shukuchi"
LinkLuaModifier( 'm_weaver_shukuchi_kbw', sPath, 0 )

weaver_shukuchi_kbw = class{}

function weaver_shukuchi_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	local nDuration = self:GetSpecialValueFor('duration')

	AddModifier( 'm_weaver_shukuchi_kbw', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		bStacks = true,
		duration = nDuration,
	})

	hCaster:EmitSound("Hero_Weaver.Shukuchi")
end

m_weaver_shukuchi_kbw = ModifierClass{}

function m_weaver_shukuchi_kbw:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVISIBLE] = self:GetTimeSinceCreation() >= self.nFadeTime or nil,
	}
end

function m_weaver_shukuchi_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
	}
end

function m_weaver_shukuchi_kbw:GetModifierMoveSpeedBonus_Constant()
	return self.nSpeed * self:GetStackCount()
end

function m_weaver_shukuchi_kbw:GetModifierInvisibilityLevel()
	if IsServer() then
		return 1
	end

	if self.nFadeTime then
		return self:GetTimeSinceCreation() / self.nFadeTime
	end
	
	return 1
end

function m_weaver_shukuchi_kbw:GetTimeSinceCreation()
	return GameRules:GetGameTime() - ( self.nCreateTime or 0 )
end

function m_weaver_shukuchi_kbw:OnCreated( t )
	self.nCreateTime = GameRules:GetGameTime()

	ReadAbilityData( self, {
		nSpeed = 'speed',
		nDamage = 'damage',
		nRadius = 'radius',
		nFadeTime = 'fade_time',
	}, function( hAbility )
		self.hAbility = hAbility

		if IsServer() then
			self.nDamageType = self.hAbility:GetAbilityDamageType()
			self.nCharged = 1
			self.tAffected = {}
	
			self:RegisterSelfEvents()
			self:StartIntervalThink( 1/30 )

			local hParent = self:GetParent()
			if hParent:IsAttacking() and hParent:AttackReady() then
				hParent:Stop()
			end
	
			local sParticle = 'particles/units/heroes/hero_weaver/weaver_shukuchi.vpcf'
			self.nParticle = ParticleManager:Create( sParticle, self:GetParent() )
		end
	end )
end

function m_weaver_shukuchi_kbw:OnRefresh( t )
	if IsServer() then
		self.nCharged = self.nCharged + 1
	end
end

function m_weaver_shukuchi_kbw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()

		if self.nParticle then
			ParticleManager:Fade( self.nParticle, true )
		end
	end
end

function m_weaver_shukuchi_kbw:OnIntervalThink()
	local hParent = self:GetParent()
	
	local qUnits = Find:UnitsInRadius({
		vCenter = hParent,
		nRadius = self.nRadius,
		nTeam = hParent:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		nFilterFlag = 0,
	})

	for _, hUnit in ipairs( qUnits ) do
		local nAmp = self.nCharged - ( self.tAffected[ hUnit ] or 0 )
		if nAmp > 0 then
			nAmp = math.min( nAmp, self:GetStackCount() )
			self.tAffected[ hUnit ] = self.nCharged

			ApplyDamage({
				victim = hUnit,
				attacker = hParent,
				ability = self.hAbility,
				damage = self.nDamage * nAmp,
				damage_type = self.nDamageType,
			})

			local sParticle = 'particles/units/heroes/hero_weaver/weaver_shukuchi_damage.vpcf'
			local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN, hUnit, 3 )
			ParticleManager:SetParticleControlEnt( nParticle, 0, hUnit, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hUnit:GetOrigin(), false )
			ParticleManager:SetParticleControlEnt( nParticle, 1, hParent, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hParent:GetOrigin(), false )
		end
	end
end

function m_weaver_shukuchi_kbw:OnParentAttack( tEvent )
	if not self:GetParent().bTriggeredAttack then
		self:Destroy()
	end
end