m_tusk_snowball_unmute = ModifierClass{
}

function m_tusk_snowball_unmute:CheckState()
	local state = {
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_STUNNED] = false,
		[MODIFIER_STATE_DISARMED] = false,

	}
	local talent = self:GetCaster():FindAbilityByName('special_bonus_unique_tusk_snowball_items')
	if talent and talent:GetLevel() > 0 then
		state[MODIFIER_STATE_MUTED] = false
	end
	return state
end

function m_tusk_snowball_unmute:GetPriority()
	return 99999
end

function m_tusk_snowball_unmute:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function m_tusk_snowball_unmute:GetModifierConstantHealthRegen()
	local talent = self:GetCaster():FindAbilityByName('special_bonus_unique_tusk_snowball_regen')
	if talent and talent:GetLevel() > 0 then
		return talent:GetSpecialValueFor('regen_pct') * self:GetParent():GetMaxHealth() / 100
	end
end