m_special_bonus_unique_phantom_assassin_blur_spell_immunity = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_special_bonus_unique_phantom_assassin_blur_spell_immunity:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'duration',
		})

		self:RegisterSelfEvents()
	end
end

function m_special_bonus_unique_phantom_assassin_blur_spell_immunity:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_special_bonus_unique_phantom_assassin_blur_spell_immunity:OnParentAbilityExecuted(t)
	if t.ability and t.ability:GetName() == 'phantom_assassin_blur' then
		local parent = self:GetParent()
		parent:Purge(false, true, false, false, false)
		AddModifier('modifier_black_king_bar_immune', {
			hTarget = parent,
			hCaster = parent,
			hAbility = t.ability,
			duration = self.duration,
		})
	end
end