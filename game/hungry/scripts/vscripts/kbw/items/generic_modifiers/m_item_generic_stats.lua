m_item_generic_stats = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_stats:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_stats:OnRefresh()
	ReadAbilityData(self, {
		'all',
		'str',
		'agi',
		'int',
	})
end

function m_item_generic_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_item_generic_stats:GetModifierBonusStats_Strength()
	return self.all + self.str
end
function m_item_generic_stats:GetModifierBonusStats_Agility()
	return self.all + self.agi
end
function m_item_generic_stats:GetModifierBonusStats_Intellect()
	return self.all + self.int
end