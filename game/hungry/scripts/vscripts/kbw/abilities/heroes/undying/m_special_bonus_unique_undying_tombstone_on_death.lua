m_special_bonus_unique_undying_tombstone_on_death = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_special_bonus_unique_undying_tombstone_on_death:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'count',
		})

		self:RegisterSelfEvents()
	end
end

function m_special_bonus_unique_undying_tombstone_on_death:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_special_bonus_unique_undying_tombstone_on_death:OnParentDead(t)
	if not exist(t.unit) then
		return
	end

	local tomb = t.unit:FindAbilityByName('undying_tombstone')
	if tomb and tomb:IsTrained() then
		local pos = t.unit:GetOrigin()
		for i = 1, self.count do
			SpellCaster:Cast(tomb, pos)
		end
	end
end