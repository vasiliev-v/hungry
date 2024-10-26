m_item_generic_speed = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_speed:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_speed:OnRefresh()
	ReadAbilityData(self, {
		'movespeed',
		'movespeed_pct',
	})
end

function m_item_generic_speed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_item_generic_speed:GetModifierMoveSpeedBonus_Constant()
	return self.movespeed
end
function m_item_generic_speed:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed_pct
end