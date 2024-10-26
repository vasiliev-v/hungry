m_test_invuln = class({})

function m_test_invuln:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function m_test_invuln:GetModifierIncomingDamage_Percentage()
	return -100000
end

function m_test_invuln:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

m_test_nocd = class({})

function m_test_nocd:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
	}
end

function m_test_nocd:GetModifierPercentageCooldown()
	return 100
end

function m_test_nocd:GetModifierPercentageManacost()
	return 100
end

function m_test_nocd:GetModifierPercentageCasttime()
	return 100
end

function m_test_nocd:GetModifierCastRangeBonusStacking()
	return 99999
end

function m_test_nocd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

m_test_lox = class({})

function m_test_lox:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
end

function m_test_lox:GetModifierTotalDamageOutgoing_Percentage()
	return -9999
end

function m_test_lox:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end