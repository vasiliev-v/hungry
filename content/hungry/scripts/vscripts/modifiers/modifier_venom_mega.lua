modifier_venom_mega = class({})

function modifier_venom_mega:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_venom_mega:IsHidden()
    return false
end

function modifier_venom_mega:IsPurgable()
    return false
end

function modifier_venom_mega:IsPermanent()
	return true
end

function modifier_venom_mega:GetTexture()
	return "custom/modifier_venom_mega"
end

function modifier_venom_mega:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
             MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
             MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			 MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end

function modifier_venom_mega:GetModifierIncomingDamage_Percentage()
	return -5
end

function modifier_venom_mega:GetModifierMagicalResistanceBonus()

	return 5
end

function modifier_venom_mega:GetModifierTotalDamageOutgoing_Percentage()
	return 5
end

function modifier_venom_mega:GetModifierStatusResistanceStacking()
	return 5
end

function modifier_venom_mega:GetModifierMoveSpeedBonus_Constant()
	return 15
end

