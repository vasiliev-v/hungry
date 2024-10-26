m_kbw_attack_range_melee = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_attack_range_melee:OnCreated()
	ReadAbilityData(self, {
		'attack_range',
		'model_scale',
	})
end

function m_kbw_attack_range_melee:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end

function m_kbw_attack_range_melee:GetModifierAttackRangeBonus()
	return self.attack_range
end

function m_kbw_attack_range_melee:GetModifierModelScale()
	return self.model_scale
end