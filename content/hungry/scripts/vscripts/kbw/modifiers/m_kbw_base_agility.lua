m_kbw_base_agility = ModifierClass{
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_base_agility:OnCreated(t)
	if IsServer() then
		self:GetParent():ModifyAgility(t.value or 0)
		self:Destroy()
	end
end