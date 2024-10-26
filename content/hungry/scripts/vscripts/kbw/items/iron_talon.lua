require 'lib/m_mult'
require 'lib/particle_manager'

local sPath = "kbw/items/iron_talon"
LinkLuaModifier( 'm_item_kbw_iron_talon_stats', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_iron_talon', sPath, 0 )

item_kbw_iron_talon = class{}

function item_kbw_iron_talon:CastFilterResultTarget( hTarget )
    return UnitFilter( hTarget,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_CREEP,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS,
        self:GetCaster():GetTeamNumber()
    )
end

function item_kbw_iron_talon:GetCooldown( nLevel )
    if self.bTree then
        local nCd = self:GetSpecialValueFor('tree_cooldown')
        self.bTree = nil
        return nCd
    end

    return self.BaseClass.GetCooldown( self, nLevel )
end

function item_kbw_iron_talon:OnAbilityPhaseStart()
    if not self:GetCursorTarget().AddAbility then
        self.bTree = true
    end

    return true
end

function item_kbw_iron_talon:OnSpellStart()
    local hTarget = self:GetCursorTarget()
    local hCaster = self:GetCaster()

    if hTarget.AddAbility then
        local nDamage = self:GetSpecialValueFor('active_damage_pct') * hTarget:GetHealth() / 100
        local vTarget = hTarget:GetOrigin()

        ApplyDamage({
            victim = hTarget,
            attacker = hCaster,
            ability = self,
            damage = nDamage,
            damage_type = DAMAGE_TYPE_PURE,
            damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
        })

        local sParticle = 'particles/items3_fx/iron_talon_active.vpcf'
        local nParticle = ParticleManager:Create( sParticle, hTarget )
        ParticleManager:SetParticleControl( nParticle, 0, vTarget )
        ParticleManager:SetParticleControlEnt( nParticle, 1, hTarget, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', vTarget, false )
        ParticleManager:Fade( nParticle, 3 )

        hTarget:EmitSound('DOTA_Item.IronTalon.Activate')
    else
        if hTarget.CutDown then
            hTarget:CutDown( hCaster:GetTeam() )
        else
            hTarget:Kill()
        end
    end
end

function item_kbw_iron_talon:GetIntrinsicModifierName()
    return 'm_mult'
end

function item_kbw_iron_talon:GetMultModifiers()
    return {
        m_item_kbw_iron_talon_stats = 0,
        m_item_kbw_iron_talon = 1,
    }
end

m_item_kbw_iron_talon_stats = ModifierClass{
    bMultiple = true,
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_iron_talon_stats:OnCreated()
    ReadAbilityData( self, {
        nAttackSpeed = 'attack_speed',
    })
end

function m_item_kbw_iron_talon_stats:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function m_item_kbw_iron_talon_stats:GetModifierAttackSpeedBonus_Constant()
    return self.nAttackSpeed
end

m_item_kbw_iron_talon = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_iron_talon:OnCreated()
    ReadAbilityData( self, {
        nCreepDamage = 'creep_damage',
    })
end

function m_item_kbw_iron_talon:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function m_item_kbw_iron_talon:GetModifierPreAttack_BonusDamage( t )
    if IsServer() and exist( t.target ) and t.target:IsCreep() then
        return self.nCreepDamage
    end
end