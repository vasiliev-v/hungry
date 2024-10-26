lina_laguna_blade_kbw = class{}

function lina_laguna_blade_kbw:GetBehavior()
	if self:GetCaster():HasShard() then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end

	return self.BaseClass.GetBehavior( self )
end

function lina_laguna_blade_kbw:OnSpellStart()
	local nDelay = self:GetSpecialValueFor('damage_delay')
	local nDamage = self:GetSpecialValueFor('damage')
	local nDamageType = self:GetAbilityDamageType()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local vStart = hCaster:GetOrigin()
	local qUnits

	local sParticle = 'particles/units/heroes/hero_lina/lina_spell_laguna_blade.vpcf'
	local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN, 7 )
	ParticleManager:SetParticleControlEnt( nParticle, 0, hCaster, PATTACH_POINT_FOLLOW, 'attach_attack1', vStart, false )

	if hCaster:HasShard() then
		local vTarget = self:GetCursorPosition()
		local nWidth = self:GetSpecialValueFor('shard_width')
		local nRange = (GetModifiedAbilityValue( self, 'AbilityCastRange' ) or self:GetCastRange(vTarget, hTarget)) + hCaster:GetCastRangeBonus()

		if hTarget then
			vTarget = hTarget:GetOrigin()
		end

		_, vTarget = GetCastDirection{
			hCaster = hCaster,
			vTarget = vTarget,
			nRange = nRange,
			bAllowExtention = true,
			nMinHeight = -128,
		}

		qUnits = Find:UnitsInLine({
			vStart = vStart,
			vEnd = vTarget,
			nWidth = nWidth,
			bStartOffset = true,
			nTeam = hCaster:GetTeam(),
			nFilterTeam = self:GetAbilityTargetTeam(),
			nFilterType = self:GetAbilityTargetType(),
			nFilterFlag = self:GetAbilityTargetFlags(),
		})

		ParticleManager:SetParticleControl( nParticle, 1, vTarget )

		local sHitParticle = 'particles/units/heroes/hero_lina/lina_spell_laguna_blade_shard_units_hit.vpcf'
		for _, hUnit in ipairs( qUnits ) do
			local nParticle = ParticleManager:Create( sHitParticle, PATTACH_ABSORIGIN_FOLLOW, hUnit, 3 )
			ParticleManager:SetParticleControlEnt( nParticle, 0, hUnit, PATTACH_POINT_FOLLOW, 'attach_hitloc', hUnit:GetOrigin(), true )
		end

	elseif hTarget then
		ParticleManager:SetParticleControlEnt( nParticle, 1, hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false )
		qUnits = { hTarget }
	end

	Timer( nDelay, function()
		for _, hUnit in ipairs( qUnits ) do
			ApplyDamage({
				victim = hUnit,
				attacker = hCaster,
				ability = self,
				damage = nDamage,
				damage_type = nDamageType,
			})

			hUnit:EmitSound('Ability.LagunaBladeImpact')
		end
	end )

	hCaster:EmitSound('Ability.LagunaBlade')
end