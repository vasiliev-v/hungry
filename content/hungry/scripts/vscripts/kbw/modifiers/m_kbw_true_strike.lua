m_kbw_true_strike = ModifierClass{
	bHidden = true,
	bMultiple = true,
}

function m_kbw_true_strike:CheckState()
	return {
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}
end