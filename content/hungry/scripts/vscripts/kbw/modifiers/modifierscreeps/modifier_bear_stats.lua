modifier_bear_stats = class({
	IsHidden =      function() return true end,
	IsPurgable =    function() return false end,
	IsBuff =        function() return true end,
})

function modifier_bear_stats:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true,
    }
end

function modifier_bear_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT
	}
end

function modifier_bear_stats:GetModifierEvasion_Constant()
	return 25
end