m_kbw_effect_duration = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_effect_duration:OnCreated(t)
	if IsServer() then
		ReadAbilityData(self, {
			'value',
		})
	end
end

function m_kbw_effect_duration:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER,
	}
end

function m_kbw_effect_duration:GetModifierStatusResistanceCaster()
	return -self.value
end