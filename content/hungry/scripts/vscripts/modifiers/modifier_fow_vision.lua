modifier_fow_vision = class({})

function modifier_fow_vision:IsHidden()
	return true
end

function modifier_fow_vision:CheckState()
	local state =
	{
		[MODIFIER_STATE_INVISIBLE] = false,

	}
	return state
end

function modifier_fow_vision:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(FrameTime())
end

function modifier_fow_vision:OnIntervalThink()
	if not IsServer() then return end
	for i = 0, 12 do
		AddFOWViewer( i, self:GetParent():GetAbsOrigin(), 400, FrameTime(), false)
	end
end