m_kbw_break = ModifierClass{}

function m_kbw_break:OnCreated()
	if IsServer() then
		local parent = self:GetParent()
		self.partilce = ParticleManager:Create('particles/generic_gameplay/generic_break.vpcf', PATTACH_OVERHEAD_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.partilce, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
	end
end

function m_kbw_break:OnDestroy()
	if IsServer() then
		if self.partilce then
			ParticleManager:Fade(self.partilce, true)
		end
	end
end

function m_kbw_break:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end