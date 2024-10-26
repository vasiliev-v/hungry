m_kbw_boss_flag = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_boss_flag:OnCreated(t)
	if IsServer() then
		if t.real_boss then
			self:SetStackCount(1)
		end
	end
end