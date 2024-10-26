m_kbw_min_health = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_min_health:OnCreated(t)
	if IsServer() then
		self.value = t.value
	end
end

function m_kbw_min_health:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MIN_HEALTH,
	}
end

function m_kbw_min_health:GetMinHealth()
	return self.value
end