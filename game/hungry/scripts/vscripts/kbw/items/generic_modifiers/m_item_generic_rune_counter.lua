m_item_generic_rune_counter = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_generic_rune_counter:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self:SetRuneCharges(self:GetParent()._rune_charges or 0)
	end
end

function m_item_generic_rune_counter:OnRefresh(t)
	ReadAbilityData(self, {
		'runes_max',
		'runes_hp_regen',
		'runes_mp_regen',
	})
end

function m_item_generic_rune_counter:SetRuneCharges(count)
	count = math.min(self.runes_max, count)

	local spell = self:GetAbility()
	if spell then
		spell:SetCurrentCharges(count)
	end
	
	self:SetStackCount(count)
end

function m_item_generic_rune_counter:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_item_generic_rune_counter:GetModifierConstantHealthRegen()
	return self.runes_hp_regen * self:GetStackCount()
end
function m_item_generic_rune_counter:GetModifierConstantManaRegen()
	return self.runes_mp_regen * self:GetStackCount()
end