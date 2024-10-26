m_kbw_cdr_stackable = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_cdr_stackable:OnCreated()
	ReadAbilityData(self, {
		'value',
		'only_abilities',
	})
end

function m_kbw_cdr_stackable:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
end	

function m_kbw_cdr_stackable:GetModifierPercentageCooldown(t)
	if self.only_abilities ~= 0 and t.ability:IsItem() then
		return
	end
	return self.value
end