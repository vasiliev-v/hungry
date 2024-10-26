require('kbw/util_spell')
require('kbw/util_c')
m_kbw_no_damage = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_no_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function m_kbw_no_damage:GetAbsoluteNoDamagePhysical()
	return 1
end
function m_kbw_no_damage:GetAbsoluteNoDamageMagical()
	return 1
end
function m_kbw_no_damage:GetAbsoluteNoDamagePure()
	return 1
end