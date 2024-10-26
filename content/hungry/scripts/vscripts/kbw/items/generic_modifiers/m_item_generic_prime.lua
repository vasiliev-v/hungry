m_item_generic_prime = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_prime:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(FrameTime())
	end
end

function m_item_generic_prime:OnRefresh()
	ReadAbilityData(self, {
		'prime',
		'other',
	})
end

function m_item_generic_prime:OnIntervalThink()
	local parent = self:GetParent()
	if parent.GetPrimaryAttribute then
		self:SetStackCount(parent:GetPrimaryAttribute())
	end
end

function m_item_generic_prime:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_item_generic_prime:GetStatValue(attr)
	local stack = self:GetStackCount()
	if attr == stack then
		return self.prime
	elseif stack == DOTA_ATTRIBUTE_ALL then
		return self.other + self.prime / 3
	else
		return self.other
	end
end

function m_item_generic_prime:GetModifierBonusStats_Strength()
	return self:GetStatValue(DOTA_ATTRIBUTE_STRENGTH)
end
function m_item_generic_prime:GetModifierBonusStats_Agility()
	return self:GetStatValue(DOTA_ATTRIBUTE_AGILITY)
end
function m_item_generic_prime:GetModifierBonusStats_Intellect()
	return self:GetStatValue(DOTA_ATTRIBUTE_INTELLECT)
end