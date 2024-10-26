m_ursa_enrage_shard = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_ursa_enrage_shard:OnCreated(t)
	ReadAbilityData(self, {
		'base_damage',
		'spell_amp',
	})
end

function m_ursa_enrage_shard:OnRefresh(t)
	self:OnCreated(t)
end

function m_ursa_enrage_shard:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end

function m_ursa_enrage_shard:GetModifierBaseDamageOutgoing_Percentage()
	return self.base_damage
end
function m_ursa_enrage_shard:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end