modifier_winter_mega = class({})

function modifier_winter_mega:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_winter_mega:IsHidden()
    return false
end

function modifier_winter_mega:IsPurgable()
    return false
end

function modifier_winter_mega:IsPermanent()
	return true
end

function modifier_winter_mega:GetTexture()
	return "custom/modifier_winter_mega"
end

function modifier_winter_mega:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
             MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
             MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			 MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end

function modifier_winter_mega:GetModifierIncomingDamage_Percentage()
	return -5
end

function modifier_winter_mega:GetModifierMagicalResistanceBonus()

	return 5
end

function modifier_winter_mega:GetModifierTotalDamageOutgoing_Percentage()
	return 5
end

function modifier_winter_mega:GetModifierStatusResistanceStacking()
	return 5
end

function modifier_winter_mega:GetModifierMoveSpeedBonus_Constant()
	return 15
end

