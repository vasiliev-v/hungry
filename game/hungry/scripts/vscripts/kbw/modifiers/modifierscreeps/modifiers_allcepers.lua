modifiers_allCepers = class({
	IsHidden =      function() return true end,
	IsPurgable =    function() return false end,
	IsBuff =        function() return true end,
})

function modifiers_allCepers:CheckState()
    return {
        [MODIFIER_STATE_CANNOT_MISS] = true,
    }
end