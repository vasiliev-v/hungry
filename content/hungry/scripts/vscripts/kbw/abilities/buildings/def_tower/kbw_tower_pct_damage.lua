require 'lib/modifier_self_events'

LinkLuaModifier( 'm_kbw_tower_pct_damage', "kbw/abilities/buildings/def_tower/kbw_tower_pct_damage", 0 )

kbw_tower_pct_damage = class{}

function kbw_tower_pct_damage:GetIntrinsicModifierName()
    return 'm_kbw_tower_pct_damage'
end

m_kbw_tower_pct_damage = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_kbw_tower_pct_damage:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_CANNOT_MISS] = true,
    }
end

function m_kbw_tower_pct_damage:OnCreated()
    if IsServer() then
        ReadAbilityData( self, {
            nMultiplier = 'pct_damage',
        }, function( hAbility )
            self.hParent = self:GetParent()
            self.hAbility = hAbility
            self.nMultiplier = self.nMultiplier / 100
            self.nDamageType = hAbility:GetAbilityDamageType()

            self:RegisterSelfEvents()
        end )
    end
end

function m_kbw_tower_pct_damage:OnDestroy()
    if IsServer() then
        self:UnregisterSelfEvents()
    end
end

function m_kbw_tower_pct_damage:OnParentAttackLanded( tEvent )
    if exist( tEvent.target ) and tEvent.target.GetMaxHealth then
        ApplyDamage{
            victim = tEvent.target,
            attacker = self.hParent,
            ability = self.hAbility,
            damage = tEvent.target:GetMaxHealth() * self.nMultiplier,
            damage_type = self.nDamageType,
        }
    end
end