m_kbw_visible = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_visible:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function m_kbw_visible:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function m_kbw_visible:GetModifierProvidesFOWVision(t)
	if exist(t.target) and self:GetCaster():GetTeamNumber() == t.target:GetTeamNumber() then
		if not HasState(self:GetParent(), MODIFIER_STATE_TRUESIGHT_IMMUNE) then
			return 1
		end
	end
end

function m_kbw_visible:OnCreated(t)
	if IsServer() then
		self.truesight = self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_truesight', {})
	end
end

function m_kbw_visible:OnDestroy()
	if IsServer() then
		if exist(self.truesight) then
			self.truesight:Destroy()
		end
	end
end