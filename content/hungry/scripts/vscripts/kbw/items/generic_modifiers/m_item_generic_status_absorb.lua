m_item_generic_status_absorb = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_status_absorb:OnCreated(t)
	ReadAbilityData(self, {
		'status_absorb',
	})

	if IsServer() then
		-- Implemented in m_kbw_unit
		self.modifier = AddSpecialModifier(self:GetParent(), 'nStatusAbsorb', self.status_absorb)
	end
end

function m_item_generic_status_absorb:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

function m_item_generic_status_absorb:OnDestroy()
	if IsServer() then
		if exist(self.modifier) then
			self.modifier:Destroy()
		end
	end
end