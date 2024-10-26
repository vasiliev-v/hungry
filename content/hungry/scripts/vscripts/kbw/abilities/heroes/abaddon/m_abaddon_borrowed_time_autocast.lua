m_abaddon_borrowed_time_autocast = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_abaddon_borrowed_time_autocast:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
	}
end

function m_abaddon_borrowed_time_autocast:GetModifierTotal_ConstantBlock(t)
	local parent = self:GetParent()

	if t.damage < parent:GetHealth() - 1 then
		return
	end

	if not self:IsDeathPreventor() then
		return
	end

	if not IsKillable(parent, self) then
		return
	end

	local ability = parent:FindAbilityByName('abaddon_borrowed_time_2')
	if ability then
		SpellCaster:Cast(ability, nil, true)
		return t.damage
	end
end

function m_abaddon_borrowed_time_autocast:IsDeathPreventor()
	local parent = self:GetParent()
	local ability = parent:FindAbilityByName('abaddon_borrowed_time_2')

	if self:GetParent():PassivesDisabled() then
		return false
	end

	if not ability or not ability:IsTrained() or ability:GetCooldownTimeRemaining() > 0 then
		return false
	end

	return true
end

function m_abaddon_borrowed_time_autocast:IsSoftDeathPreventor()
	return self:IsDeathPreventor()
end