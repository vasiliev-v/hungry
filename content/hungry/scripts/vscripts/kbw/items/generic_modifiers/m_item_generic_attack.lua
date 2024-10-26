m_item_generic_attack = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_attack:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_attack:OnRefresh()
	ReadAbilityData(self, {
		'attack',
		'damage',
	})
end

function m_item_generic_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function m_item_generic_attack:GetModifierAttackSpeedBonus_Constant()
	return self.attack
end
function m_item_generic_attack:GetModifierPreAttack_BonusDamage()
	return self.damage
end