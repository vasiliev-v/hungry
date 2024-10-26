modifier_aegis_buff = class({})

function modifier_aegis_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_aegis_buff:GetModifierMoveSpeed_Max( params )
    return 600
end

function modifier_aegis_buff:GetModifierMoveSpeed_Limit( params )
    return 600
end

function modifier_aegis_buff:GetModifierIgnoreMovespeedLimit()
    return 1
end

function modifier_aegis_buff:IsHidden()
    return false
end

function modifier_aegis_buff:GetModifierMoveSpeedBonus_Percentage()
    return 600
end
