m_crit = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_crit:OnCreated(t)
	if IsServer() then
		self.nChance = t.nChance or 0
		self.nCrit = t.nCrit or 0
	end
end

function m_crit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
end

function m_crit:GetModifierPreAttack_CriticalStrike()
	if RandomFloat(0, 100) <= self.nChance then
		return self.nCrit
	end
end