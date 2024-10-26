m_faceless_void_time_dilation_chronosphere = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_faceless_void_time_dilation_chronosphere:OnCreated(t)
	if IsServer() then	
		self.chrono_values = {
			radius = t.radius,
			duration = t.stun,
		}

		self:RegisterSelfEvents()
	end
end

function m_faceless_void_time_dilation_chronosphere:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_faceless_void_time_dilation_chronosphere:OnParentAbilityFullyCast(t)
	if not exist(t.ability) or t.ability:GetName() ~= 'faceless_void_time_dilation' then
		return
	end

	local caster = t.ability:GetCaster()
	local chrono = caster:FindAbilityByName('faceless_void_chronosphere')

	if chrono and chrono:IsTrained() then
		self.override_chrono = true
		SpellCaster:Cast(chrono, caster:GetOrigin())
		self.override_chrono = nil
	end
end

function m_faceless_void_time_dilation_chronosphere:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end

function m_faceless_void_time_dilation_chronosphere:GetModifierOverrideAbilitySpecial(t)
	if IsServer() and self.override_chrono and t.ability:GetName() == 'faceless_void_chronosphere' then
		return self.chrono_values[t.ability_special_value] and 1
	end
end

function m_faceless_void_time_dilation_chronosphere:GetModifierOverrideAbilitySpecialValue(t)
	if IsServer() and self.override_chrono and t.ability:GetName() == 'faceless_void_chronosphere' then
		local value = self.chrono_values[t.ability_special_value]

		-- Force unaffected by chronosphere radius talent
		if t.ability_special_value == 'radius' then
			local talent_radius = self:GetParent():FindAbilityByName('special_bonus_unique_faceless_void_2')
			if talent_radius and talent_radius:IsTrained() then
				value = value - talent_radius:GetSpecialValueFor('value')
			end
		end

		return value
	end
end