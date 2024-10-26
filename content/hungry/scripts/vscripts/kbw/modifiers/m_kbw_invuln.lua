m_kbw_invuln = ModifierClass{
	bHidden = true,
}

function m_kbw_invuln:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end