m_kbw_status_resist = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_status_resist:OnCreated(t)
	self.spell = self:GetAbility()
	if IsServer() then
		self:SetStackCount(math.floor((t.status_resist or 0) + 0.5))
	end
end

function m_kbw_status_resist:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function m_kbw_status_resist:GetModifierStatusResistanceStacking()
	if self.spell then
		local resist = self.spell:GetSpecialValueFor('status_resist')
		print(resist)
		if resist > 0 then
			return resist
		end
	end
	return self:GetStackCount()
end