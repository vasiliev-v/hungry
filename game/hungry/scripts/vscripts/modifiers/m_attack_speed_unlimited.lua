require('kbw/util_spell')
require('kbw/util_c')
m_attack_speed_unlimited = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_attack_speed_unlimited:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
	}
end

function m_attack_speed_unlimited:GetModifierAttackSpeed_Limit()
	return 1
end