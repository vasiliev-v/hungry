m_storm_spirit_overload_cast_attacks = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_storm_spirit_overload_cast_attacks:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'bonus_range',
			'attacks',
		})

		self.records = {}

		self:RegisterSelfEvents()
	end
end

function m_storm_spirit_overload_cast_attacks:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_storm_spirit_overload_cast_attacks:OnParentAbilityExecuted(t)
	if not exist(t.ability) or t.ability:IsItem() then
		return
	end

	local parent = self:GetParent()

	local enemies = FindUnitsInRadius(
		parent:GetTeam(),
		parent:GetOrigin(),
		parent,
		parent:GetAttackRange() + self.bonus_range,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
		FIND_CLOSEST,
		false
	)

	self.launching = true
	for i = 1, self.attacks do
		local enemy = enemies[i]
		if not enemy then
			break
		end
		
		parent:PerformAttack(enemy, true, true, true, false, true, false, false)
	end
	self.launching = nil
end

function m_storm_spirit_overload_cast_attacks:OnParentAttackRecord(t)
	if self.launching then
		self.records[t.record] = true
	end
end

function m_storm_spirit_overload_cast_attacks:OnParentAttackRecordDestroy(t)
	self.records[t.record] = nil
end

function m_storm_spirit_overload_cast_attacks:OnParentAttackLanded(t)
	if self.records[t.record] then
		local parent = self:GetParent()
		local ability = parent:FindAbilityByName('storm_spirit_overload')
		if ability then
			local buff = parent:AddNewModifier(parent, ability, 'modifier_storm_spirit_electric_rave', {
				duration = FrameTime(),
			})
			if buff then
				buff:IncrementStackCount()
			end

			if parent:HasModifier('modifier_storm_spirit_overload') then
				Timer(FrameTime(), function()
					if exist(parent) and parent:IsAlive() then
						parent:AddNewModifier(parent, ability, 'modifier_storm_spirit_overload', {})
					end
				end)
			end
		end
	end
end