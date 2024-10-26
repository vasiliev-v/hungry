modifier_winter = class({})

function modifier_winter:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_winter:IsHidden()
    return false
end

function modifier_winter:IsPurgable()
    return false
end

function modifier_winter:IsPermanent()
	return true
end

function modifier_winter:GetTexture()
	return "custom/modifier_winter"
end

function modifier_winter:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_winter:GetModifierBonusStats_Strength()
	return 25
end

function modifier_winter:GetModifierBonusStats_Agility()

	return 25
end

function modifier_winter:GetModifierBonusStats_Intellect()
	return 40
end
