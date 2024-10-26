modifier_venom = class({})

function modifier_venom:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_venom:IsHidden()
    return false
end

function modifier_venom:IsPurgable()
    return false
end

function modifier_venom:IsPermanent()
	return true
end

function modifier_venom:GetTexture()
	return "custom/modifier_venom"
end

function modifier_venom:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_venom:GetModifierBonusStats_Strength()
	return 25
end

function modifier_venom:GetModifierBonusStats_Agility()

	return 25
end

function modifier_venom:GetModifierBonusStats_Intellect()
	return 40
end
