modifier_water = class({})

function modifier_water:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_water:IsHidden()
    return false
end

function modifier_water:IsPurgable()
    return false
end

function modifier_water:IsPermanent()
	return true
end

function modifier_water:GetTexture()
	return "custom/modifier_water"
end

function modifier_water:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_water:GetModifierBonusStats_Strength()
	return 25
end

function modifier_water:GetModifierBonusStats_Agility()

	return 25
end

function modifier_water:GetModifierBonusStats_Intellect()
	return 40
end
