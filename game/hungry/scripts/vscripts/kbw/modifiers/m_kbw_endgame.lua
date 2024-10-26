m_kbw_endgame = class{}

function m_kbw_endgame:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function m_kbw_endgame:IsHidden()
    return true
end

function m_kbw_endgame:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function m_kbw_endgame:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    }
end

function m_kbw_endgame:GetOverrideAnimation()
    if self:GetStackCount() > 0 then
        return ACT_DOTA_VICTORY
    else
        return ACT_DOTA_DEFEAT
    end
end