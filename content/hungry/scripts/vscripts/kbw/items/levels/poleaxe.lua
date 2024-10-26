LinkLuaModifier( 'm_item_kbw_poleaxe', "kbw/items/levels/poleaxe", 0 )

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_item_kbw_poleaxe'
end

CreateLevels({
    'item_kbw_poleaxe',
    'item_kbw_poleaxe_2',
    'item_kbw_poleaxe_3',
}, base )

m_item_kbw_poleaxe = ModifierClass{
	bHidden = true,
    bMultiple = true,
    bPermanent = true,
}

function m_item_kbw_poleaxe:OnCreated()
	ReadAbilityData( self, {
        nDamage = 'damage',
    })
end

function m_item_kbw_poleaxe:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function m_item_kbw_poleaxe:GetModifierPreAttack_BonusDamage()
	return self.nDamage
end