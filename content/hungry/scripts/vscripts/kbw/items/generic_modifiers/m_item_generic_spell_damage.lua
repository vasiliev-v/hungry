m_item_generic_spell_damage = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_spell_damage:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_generic_spell_damage:OnRefresh()
	ReadAbilityData(self, {
		'spell_damage',
	})
end

function m_item_generic_spell_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

function m_item_generic_spell_damage:GetModifierSpellAmplify_Percentage(t)
	if t.damage_type ~= DAMAGE_TYPE_PURE then
		return self.spell_damage
	end
end