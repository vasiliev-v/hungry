m_item_generic_base = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_base:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_base:OnRefresh()
	ReadAbilityData(self, {
		'hp',
		'mp',
	})
end

function m_item_generic_base:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
	}
end
function m_item_generic_base:GetModifierHealthBonus()
	return self.hp
end
function m_item_generic_base:GetModifierManaBonus()
	return self.mp
end