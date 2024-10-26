m_item_generic_spell_cleave = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_spell_cleave:OnCreated(t)
	ReadAbilityData(self, {
		'spell_cleave',
	})

	if IsServer() then
		-- Implemented in m_kbw_unit
		self.modifier = AddSpecialModifier(self:GetParent(), 'nSpellCleave', self.spell_cleave)
	end
end

function m_item_generic_spell_cleave:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

function m_item_generic_spell_cleave:OnDestroy()
	if IsServer() then
		if exist(self.modifier) then
			self.modifier:Destroy()
		end
	end
end