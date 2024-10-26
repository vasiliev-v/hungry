m_nyx_special = ModifierClass{
	bPermanent = true,
	-- bHidden = true,
}

function m_nyx_special:OnCreated()
	if IsServer() then
		self.hParent = self:GetParent()
		self:StartIntervalThink(1/30)
	end
end

function m_nyx_special:OnIntervalThink()
	if self.hParent:HasModifier('modifier_nyx_assassin_burrow') then
		if not self.bBurrow then
			self.bBurrow = true

			local hAbility = self.hParent:FindAbilityByName('nyx_assassin_burrow')
			if hAbility then
				local nValue = hAbility:GetLevelSpecialValueNoOverride('damage_reduction', hAbility:GetLevel()-1) / 100
				self.hDamageModifier = AddSpecialModifier( self.hParent, 'nDamageResist', nValue, OPERATION_ASYMPTOTE )
			end
		end
	else
		if self.bBurrow then
			self.bBurrow = false
			if exist(self.hDamageModifier) then
				self.hDamageModifier:Destroy()
				self.hDamageModifier = nil
			end
		end
	end
end

function m_nyx_special:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end

function m_nyx_special:GetModifierOverrideAbilitySpecial(t)
	if IsServer() and t.ability:GetName() == 'nyx_assassin_burrow' and t.ability_special_value == 'damage_reduction' then
		return 1
	end
end

function m_nyx_special:GetModifierOverrideAbilitySpecialValue(t)
	return 0
end