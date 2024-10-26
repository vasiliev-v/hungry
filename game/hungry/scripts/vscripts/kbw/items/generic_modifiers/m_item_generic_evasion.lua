m_item_generic_evasion = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_evasion:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_evasion:OnRefresh()
	ReadAbilityData(self, {
		'evasion',
	})
end

function m_item_generic_evasion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
end

function m_item_generic_evasion:GetModifierEvasion_Constant()
	return self.evasion
end