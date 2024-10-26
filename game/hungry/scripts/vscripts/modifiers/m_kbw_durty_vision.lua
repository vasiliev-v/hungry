require('kbw/util_spell')
require('kbw/util_c')
m_kbw_durty_vision = ModifierClass{
	bHidden = true,
	bMultiple = true,
}

function m_kbw_durty_vision:IsPurgable()
	return self:GetStackCount() ~= 0
end

function m_kbw_durty_vision:IsPurgeException()
	return self:IsPurgable()
end

function m_kbw_durty_vision:OnCreated(t)
	if IsServer() then
		self.team = self:GetCaster():GetTeam()

		if toboolean(t.purgable) then
			self:SetStackCount(1)
		end

		self:StartIntervalThink(0.1)
	end
end

function m_kbw_durty_vision:OnIntervalThink()
	local parent = self:GetParent()
	local range = parent:GetCurrentVisionRange()
	local obstructed = not parent:HasFlyingVision()

	AddFOWViewer(self.team, parent:GetOrigin(), range, 0.15, obstructed)
end