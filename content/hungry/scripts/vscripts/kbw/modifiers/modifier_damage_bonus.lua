modifier_damage_bonus = class{}

function modifier_damage_bonus:IsHidden()
	return true
end

function modifier_damage_bonus:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_damage_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_damage_bonus:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount()
end