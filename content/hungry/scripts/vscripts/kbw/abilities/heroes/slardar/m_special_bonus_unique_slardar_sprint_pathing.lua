m_special_bonus_unique_slardar_sprint_pathing = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_special_bonus_unique_slardar_sprint_pathing:CheckState()
	if self:GetParent():HasModifier('modifier_slardar_sprint_river') then
		return {
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		}
	end
end