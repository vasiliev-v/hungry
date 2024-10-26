m_winter_wyvern_arctic_burn_vision = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_winter_wyvern_arctic_burn_vision:CheckState()
	local hBuff = self:GetParent():FindModifierByName('modifier_winter_wyvern_arctic_burn_flight')
	if hBuff then
		local hAbility = hBuff:GetAbility()
		if hAbility and hAbility:GetSpecialValueFor('flying_vision') ~= 0 then
			return {
				[MODIFIER_STATE_FORCED_FLYING_VISION] = true,
			}
		end
	end
end