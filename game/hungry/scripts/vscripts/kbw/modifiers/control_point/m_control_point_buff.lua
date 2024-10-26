m_control_point_buff = ModifierClass{}

function m_control_point_buff:GetTexture()
	return 'control_point'
end

function m_control_point_buff:DestroyOnExpire()
	return false
end

function m_control_point_buff:IsHidden()
	return self:GetStackCount() < 0
end

function m_control_point_buff:OnCreated()
	self.nReceiveTime = 60

	if IsServer() then
		self.hParent = self:GetParent()
		
		if self.hParent:IsRealHero() then			
			if not _G.tControlPointTomeTimers then
				_G.tControlPointTomeTimers = {}
			end

			self:Delay(_G.tControlPointTomeTimers[self.hParent] or self.nReceiveTime)
		else
			self:SetStackCount(-1)
		end
	end
end

function m_control_point_buff:OnDestroy()
	if IsServer() then
		if self.hParent:IsRealHero() then
			_G.tControlPointTomeTimers[self.hParent] = self:GetRemainingTime()
		end
	end
end

function m_control_point_buff:Delay(nTime)
	self:StartIntervalThink(nTime)
	self:SetDuration(nTime, true)
end

function m_control_point_buff:OnIntervalThink()
	AddItem(self.hParent, 'item_kbw_tome_of_knowledge')

	self:Delay(self.nReceiveTime)
end