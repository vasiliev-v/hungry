creep_small_golem_split = class{}

function creep_small_golem_split:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function creep_small_golem_split:OnOwnerDied()
	local bInitial = not self.nSplits

	if bInitial then
		self.nSplits = self:GetSpecialValueFor('split_count')
	end

	if self.nSplits < 1 then
		return
	end

	local sAbility = self:GetName()
	local hCaster = self:GetCaster()
	local vPos = hCaster:GetOrigin()
	local nTeam = hCaster:GetTeam()
	local nSpeed = hCaster:GetMoveSpeedModifier(hCaster:GetBaseMoveSpeed(), true)
	local nDamage = hCaster:GetAverageTrueAttackDamage(nil)
	local nBaseArmor = hCaster:GetPhysicalArmorBaseValue()
	local nHealth = math.ceil(hCaster:GetMaxHealth() * self:GetSpecialValueFor('hp_mult') / 100)
	local nBountyMult = self:GetSpecialValueFor('reward_mult') / 100
	local nGold = math.ceil(hCaster:GetGoldBounty() * nBountyMult)
	local nExp = math.ceil(hCaster:GetDeathXP() * nBountyMult)
	local hOwner = hCaster:GetOwner()
	local nPlayer = hCaster:GetMainControllingPlayer()
	local hHero = PlayerResource:GetSelectedHeroEntity(nPlayer)
	local nLifeTime = self:GetSpecialValueFor('lifetime')

	if bInitial then
		local aOld = Find:UnitsInRadius({
			nFilterFlag_ = DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
			fCondition = function(hUnit)
				return hUnit:GetUnitName() == 'creep_small_golem' and hUnit:GetMainControllingPlayer() == nPlayer
			end
		})

		for _, hOld in ipairs(aOld) do
			local hSpell = hOld:FindAbilityByName(sAbility)
			if hSpell and hSpell.nSplits and hSpell.nSplits < self.nSplits then
				hOld:RemoveAbilityByHandle(hSpell)
				hOld:__Kill(self, hCaster)
			end
		end
	end

	local nBaseModel = hCaster:GetModelScale()
	if hCaster:GetUnitName() ~= 'creep_small_golem' then
		nBaseModel = nBaseModel + 0.2
	end
	local nModel = nBaseModel * self:GetSpecialValueFor('model_mult') / 100

	local nArmor
	local hMod = hCaster:FindModifierByName('modifier_armor_bonus')
	if hMod then
		nArmor = hMod:GetStackCount()
	end

	local hAggroTarget = FindUnitsInRadius(nTeam, vPos, nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)[1]

	for i = 1, self:GetSpecialValueFor('split_creeps') do
		local hCreep = CreateUnitByName('creep_small_golem', vPos + RandomVector(120), true, hHero, hOwner, nTeam)
		if hCreep then
			hCreep:SetBaseMoveSpeed(nSpeed)
			hCreep:SetModelScale(nModel)
			hCreep:SetBaseDamageMin(nDamage)
			hCreep:SetBaseDamageMax(nDamage)
			hCreep:SetBaseMaxHealth(nHealth)
			hCreep:SetMaxHealth(nHealth)
			hCreep:SetHealth(nHealth)
			hCreep:SetPhysicalArmorBaseValue(nBaseArmor)
			hCreep:SetMinimumGoldBounty(nGold)
			hCreep:SetMaximumGoldBounty(nGold)
			hCreep:SetDeathXP(nExp)

			if nPlayer >= 0 then
				hCreep:SetControllableByPlayer(nPlayer, false)
				hCreep:SetOwner(hHero)
			end

			hCreep:AddNewModifier(hCreep, self, 'modifier_kill', {
				duration = nLifeTime,
			})

			if nArmor then
				hCreep:AddNewModifier(hCreep,nil,"modifier_armor_bonus",{duration = -1}):SetStackCount(nArmor)
			end

			local hAbility = hCreep:FindAbilityByName(sAbility)
			if hAbility then
				hAbility.nSplits = self.nSplits - 1
			end

			Timer(1/30, function()
				if hCreep.hAi then
					if nPlayer >= 0 then
						hCreep.hAi:Destroy()
					elseif hAggroTarget then
						hCreep.hAi:Excite(hAggroTarget)
					end
				end
			end)

			hCreep.spawner = hCaster.spawner
		end
	end
end