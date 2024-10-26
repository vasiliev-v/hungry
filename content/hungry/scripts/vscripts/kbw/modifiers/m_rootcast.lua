m_rootcast = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_rootcast:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function m_rootcast:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
	}
end

function m_rootcast:GetModifierIgnoreCastAngle()
	return 1
end