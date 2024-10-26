m_kbw_cast_attack_range = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_cast_attack_range:OnCreated()
	ReadAbilityData(self, {
		'value',
	})
end

function m_kbw_cast_attack_range:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
end

function m_kbw_cast_attack_range:GetModifierCastRangeBonusStacking()
	return self.value
end
function m_kbw_cast_attack_range:GetModifierAttackRangeBonus()
	return self.value
end