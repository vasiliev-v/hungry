m_special_bonus_unique_slardar_sprint_mag_resist = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_special_bonus_unique_slardar_sprint_mag_resist:OnCreated()
	ReadAbilityData(self, {
		'resist',
	})
end

function m_special_bonus_unique_slardar_sprint_mag_resist:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function m_special_bonus_unique_slardar_sprint_mag_resist:GetModifierMagicalResistanceBonus()
	if self:GetParent():HasModifier('modifier_slardar_sprint_river') then
		return self.resist
	end
end