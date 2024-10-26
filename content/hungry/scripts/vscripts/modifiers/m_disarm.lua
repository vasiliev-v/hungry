require('kbw/util_spell')
require('kbw/util_c')
m_disarm = ModifierClass{
}

function m_disarm:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end