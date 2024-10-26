m_kbw_antistun = ModifierClass{}

function m_kbw_antistun:IsHidden()
	return self:GetStackCount() ~= 0
end

function m_kbw_antistun:OnCreated(t)
	if toboolean(t.hide) and self.hide ~= false then
		self.hide = true
		self:SetStackCount(1)
	else
		self.hide = false
	end
end

function m_kbw_antistun:OnRefresh(t)
	self:OnCreated(t)
end

function m_kbw_antistun:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function m_kbw_antistun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = false,
	}
end