m_item_generic_regen = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_regen:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_regen:OnRefresh()
	ReadAbilityData(self, {
		'hp_regen',
		'mp_regen',
	})
end

function m_item_generic_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_item_generic_regen:GetModifierConstantHealthRegen()
	return self.hp_regen
end
function m_item_generic_regen:GetModifierConstantManaRegen()
	return self.mp_regen
end