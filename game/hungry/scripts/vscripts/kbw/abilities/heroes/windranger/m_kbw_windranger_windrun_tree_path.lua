m_kbw_windranger_windrun_tree_path = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_windranger_windrun_tree_path:CheckState()
	if self:GetParent():HasModifier('modifier_windrunner_windrun') then
		return {
			[MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true,
		}
	end
end