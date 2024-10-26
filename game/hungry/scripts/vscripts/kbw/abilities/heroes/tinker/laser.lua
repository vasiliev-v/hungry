require 'lib/finder'

LinkLuaModifier( 'modifier_tinker_laser_kbw',  "kbw/abilities/heroes/tinker/laser", 0 )

tinker_laser_kbw = class{}

function tinker_laser_kbw:GetAOERadius()
	local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_tinker_laser_aoe')
	if hTalent and hTalent:GetLevel() > 0 then
		return hTalent:GetSpecialValueFor('radius')
	end
	return 0
end

function tinker_laser_kbw:GetTargetFlag()
    if self:GetCaster():HasScepter() then
        return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    end

    return 0
end

function tinker_laser_kbw:CastFilterResultTarget( hTarget )
    local nTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
    local nType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local nFlag = self:GetTargetFlag()

    return UnitFilter( hTarget, nTeam, nType, nFlag, self:GetCaster():GetTeamNumber() )
end

function tinker_laser_kbw:GetCastRange( vPos, hTarget )
    return self:GetSpecialValueFor('castrange')
end

function tinker_laser_kbw:OnSpellStart()
    self:ThrowUnit()
end

function tinker_laser_kbw:ThrowUnit( t )
    t = t or {}
    t.hCaster = t.hCaster or self:GetCaster()
    t.hTarget = t.hTarget or self:GetCursorTarget()
    t.hSource = t.hSource or t.hCaster
    t.tAffected = t.tAffected or {}

	local nTeam = t.hCaster:GetTeam()
	local nFilterTeam = self:GetAbilityTargetTeam()
	local nFilterFlag = self:GetTargetFlag()

    UnderlayAbilityValues( self, t, {
        nDamage = 'damage',
        nDuration = 'duration',
		nBkbMultiplier = 'bkb_damage_pct',
    })

    local sParticle = 'particles/units/heroes/hero_tinker/tinker_laser.vpcf'
    local sAttach = 'attach_attack2'

    if t.bChain then
        sParticle = 'particles/units/heroes/hero_tinker/tinker_laser_aghs.vpcf'
        sAttach = 'attach_hitloc'
    end

	local vTarget = t.hTarget:GetOrigin()
    local nParticle = ParticleManager:Create( ParticleManager:GetParticleReplacement( sParticle, t.hCaster ), PATTACH_CUSTOMORIGIN, 2 )
    ParticleManager:SetParticleControlEnt( nParticle, 1, t.hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', vTarget, false )
    ParticleManager:SetParticleControlEnt( nParticle, 9, t.hSource, PATTACH_POINT_FOLLOW, sAttach, t.hCaster:GetOrigin(), false )

    if not t.bChain then
        Timer( 1/30, function()
            t.hCaster:EmitSound('Hero_Tinker.Laser')
        end )
    end

    if t.hTarget:TriggerSpellAbsorb( self ) then
        return
    end

    t.hTarget:EmitSound('Hero_Tinker.LaserImpact')

	local nHealthRemove = 0
    local nDamage = t.nDamage
	local nDamageType = self:GetAbilityDamageType()

    if t.hCaster:HasScepter() then
		if not t.nBounce then
			t.nBounce = 1
			t.nBounceRange = self:GetSpecialValueFor('scepter_bounce')
		end

        nHealthRemove = self:GetSpecialValueFor('scepter_damage_pct') * t.hTarget:GetHealth() / 100
        if IsBoss( t.hTarget ) then
            nHealthRemove = nHealthRemove * ( 100 - self:GetSpecialValueFor('scepter_boss_deamp') ) / 100
        end
    end

	local function fDamage(hTarget, nDamage, nHealthRemove)
		if hTarget:IsMagicImmune() then
			nDamage = nDamage * t.nBkbMultiplier / 100
			nHealthRemove = nHealthRemove * t.nBkbMultiplier / 100
		end

		if nHealthRemove > 0 then
			ApplyDamage({
				victim = hTarget,
				attacker = t.hCaster,
				ability = self,
				damage = nHealthRemove,
				damage_type = DAMAGE_TYPE_PURE,
				damage_flags = DOTA_DAMAGE_FLAG_HPLOSS
							+ DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
							+ DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			})
		end

		ApplyDamage({
			victim = hTarget,
			attacker = t.hCaster,
			ability = self,
			damage = nDamage,
			damage_type = nDamageType,
		})
	end

	fDamage(t.hTarget, nDamage, nHealthRemove)

    if t.hTarget:IsAlive() then
        AddModifier( 'modifier_tinker_laser_kbw', {
            hTarget = t.hTarget,
            hCaster = t.hCaster,
            hAbility = self,
            duration = t.nDuration,
        })
    end

	local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_tinker_laser_aoe')

	if hTalent and hTalent:IsTrained() then
		local nMult = hTalent:GetSpecialValueFor('damage') / 100
		local nAoeDamage = nDamage * nMult
		local nAoeHealthRemove = nHealthRemove * nMult
		local sAoeParticle = 'particles/units/heroes/hero_tinker/tinker_laser_secondary.vpcf'

		local qEnemies = Find:UnitsInRadius({
            vCenter = t.hTarget,
            nRadius = hTalent:GetSpecialValueFor('radius'),
            nTeam = nTeam,
            nFilterTeam = nFilterTeam,
            nFilterType = self:GetAbilityTargetType(),
            nFilterFlag = nFilterFlag,
        })

		for _, hUnit in ipairs(qEnemies) do
			if hUnit ~= t.hTarget then
				fDamage(hUnit, nAoeDamage, nAoeHealthRemove)

				local nParticle = ParticleManager:Create(sAoeParticle, PATTACH_CUSTOMORIGIN, 2)
				ParticleManager:SetParticleControlEnt(nParticle, 1, hUnit, PATTACH_POINT_FOLLOW, 'attach_hitloc', hUnit:GetOrigin(), false)
				ParticleManager:SetParticleControlEnt(nParticle, 9, t.hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', vTarget, false)
			end
		end
	end

    if t.nBounce and t.nBounce > 0 then
        t.tAffected[ t.hTarget ] = true

        local nOrder = FIND_FARTHEST
        local fCondition = function( hUnit )
            return not t.tAffected[ hUnit ]
        end

        local hTarget = Find:UnitsInRadius({
            vCenter = t.hTarget,
            nRadius = t.nBounceRange,
            nTeam = nTeam,
            nFilterTeam = nFilterTeam,
            nFilterType = DOTA_UNIT_TARGET_HERO,
            nFilterFlag = nFilterFlag,
            nOrder = nOrder,
            fCondition = fCondition,
        })[ 1 ]
        or Find:UnitsInRadius({
            vCenter = t.hTarget,
            nRadius = t.nBounceRange,
            nTeam = nTeam,
            nFilterTeam = nFilterTeam,
            nFilterType = DOTA_UNIT_TARGET_BASIC,
            nFilterFlag = nFilterFlag,
            nOrder = nOrder,
            fCondition = fCondition,
        })[ 1 ]

        if hTarget then
            self:ThrowUnit({
                hTarget = hTarget,
                hCaster = t.hCaster,
                bChain = true,
                hSource = t.hTarget,
                nBounce = t.nBounce - 1,
                tAffected = t.tAffected,
            })
        end
    end
end

modifier_tinker_laser_kbw = class{}

function modifier_tinker_laser_kbw:OnCreated()
    ReadAbilityData( self, {
        nMissRate = 'miss_rate',
    })
end

function modifier_tinker_laser_kbw:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MISS_PERCENTAGE,
    }
end

function modifier_tinker_laser_kbw:GetModifierMiss_Percentage()
    return self.nMissRate
end