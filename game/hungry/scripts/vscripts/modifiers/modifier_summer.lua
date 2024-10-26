modifier_summer = class({})

function modifier_summer:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_summer:IsHidden()
    return false
end

function modifier_summer:IsPurgable()
    return false
end

function modifier_summer:IsPermanent()
	return true
end

function modifier_summer:GetTexture()
	return "custom/modifier_summer"
end

function modifier_summer:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_summer:GetModifierBonusStats_Strength()
	return 25
end

function modifier_summer:GetModifierBonusStats_Agility()

	return 25
end

function modifier_summer:GetModifierBonusStats_Intellect()
	return 40
end
