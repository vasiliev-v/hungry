m_special_bonus_unique_night_stalker_crippling_fear_disarm = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_special_bonus_unique_night_stalker_crippling_fear_disarm:OnCreated()
	ReadAbilityData(self, {
		'duration'
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_special_bonus_unique_night_stalker_crippling_fear_disarm:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_special_bonus_unique_night_stalker_crippling_fear_disarm:OnParentAbilityFullyCast(t)
	if t.ability:GetName() == 'night_stalker_crippling_fear' then
		local hCaster = t.ability:GetCaster()
		local aEnemies = FindUnitsInRadius(
			hCaster:GetTeam(),
			hCaster:GetOrigin(),
			hCaster,
			t.ability:GetSpecialValueFor('radius'),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, hEnemy in ipairs(aEnemies) do
			AddModifier('modifier_disarmed', {
				hTarget = hEnemy,
				hCaster = hCaster,
				hAbility = t.ability,
				duration = self.duration,
			})
		end
	end
end