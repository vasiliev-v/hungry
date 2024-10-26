m_item_generic_armor = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_armor:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_armor:OnRefresh()
	ReadAbilityData(self, {
		'armor',
		'magic_resist',
	})
end

function m_item_generic_armor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function m_item_generic_armor:GetModifierPhysicalArmorBonus()
	return self.armor
end
function m_item_generic_armor:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end