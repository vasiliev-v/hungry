require('kbw/util_spell')
require('kbw/util_c')
m_kbw_boss_healthbar = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_boss_healthbar:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end