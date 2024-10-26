require('kbw/util_spell')
require('kbw/util_c')
m_kbw_freeze = ModifierClass{}

function m_kbw_freeze:IsPurgable()
	return false
end

function m_kbw_freeze:IsPurgeException()
	return true
end

function m_kbw_freeze:IsDebuff()
	return true
end

function m_kbw_freeze:IsStunDebuff()
	return true
end

function m_kbw_freeze:GetTexture()
	return 'winter_wyvern_cold_embrace'
end

function m_kbw_freeze:GetStatusEffectName()
	return 'particles/status_fx/status_effect_abaddon_frostmourne.vpcf'
end

function m_kbw_freeze:StatusEffectPriority()
	return 1000
end

function m_kbw_freeze:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end