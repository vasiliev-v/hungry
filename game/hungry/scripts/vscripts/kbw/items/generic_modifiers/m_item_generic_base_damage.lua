m_item_generic_base_damage = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_base_damage:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_base_damage:OnRefresh()
	ReadAbilityData(self, {
		'base_damage',
		'base_damage_amp',
	})
end

function m_item_generic_base_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_item_generic_base_damage:GetModifierBaseAttack_BonusDamage()
	return self.base_damage
end
function m_item_generic_base_damage:GetModifierBaseDamageOutgoing_Percentage()
	return self.base_damage_amp
end