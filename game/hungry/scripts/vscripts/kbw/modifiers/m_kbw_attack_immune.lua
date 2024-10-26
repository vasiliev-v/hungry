m_kbw_attack_immune = ModifierClass{
	bHidden = false,
}

function m_kbw_attack_immune:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function m_kbw_attack_immune:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function m_kbw_attack_immune:GetAbsoluteNoDamagePhysical()
	return 1
end