LinkLuaModifier('m_flash_racers', "kbw/items/levels/flash_racers", 0)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_flash_racers'
end

CreateLevels({
	'item_flash_racers',
	'item_flash_racers_2',
	'item_flash_racers_3',
}, base)

m_flash_racers = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_flash_racers:OnCreated()
	ReadAbilityData(self, {
		'speed',
		'hp_regen',
		'mp_regen',
	})
end

function m_flash_racers:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_flash_racers:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end
function m_flash_racers:GetModifierConstantHealthRegen()
	return self.hp_regen
end
function m_flash_racers:GetModifierConstantManaRegen()
	return self.mp_regen
end