LinkLuaModifier('m_shitcoin_ability', "kbw/abilities/shitcoin", 0)

shitcoin_ability = class{}

function shitcoin_ability:GetIntrinsicModifierName()
	return 'm_shitcoin_ability'
end

function shitcoin_ability:Spawn()
	if IsServer() and self.SetLevel then
		self:SetLevel(1)
	end
end

m_shitcoin_ability = class{}

function m_shitcoin_ability:IsPermanent()
	return true
end

function m_shitcoin_ability:IsPurgable()
	return false
end

function m_shitcoin_ability:IsPurgeException()
	return false
end

function m_shitcoin_ability:DestroyOnExpire()
	return false
end

function m_shitcoin_ability:CanParentBeAutoAttacked()
	return false
end

function m_shitcoin_ability:CheckState()
	local pregame = (self:GetStackCount() < 1 or nil)

	return {
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_INVULNERABLE] = pregame,
		[MODIFIER_STATE_NO_HEALTH_BAR] = pregame,
	}
end

function m_shitcoin_ability:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
	}
end

function m_shitcoin_ability:GetModifierAvoidDamage()
	return 1
end

function m_shitcoin_ability:OnCreated()
	if IsServer() then
		if GameRules:State_Get() < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			self.listener = ListenToGameEvent('game_rules_state_change', function()
				if exist(self) and GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
					self:OnCreated()
				end
			end, nil)
			return
		end

		local hParent = self:GetParent()
		local hAbility = self:GetAbility()
		self.nMaxStacks = hAbility:GetSpecialValueFor('hit_limit')
		self.nResetTime = hAbility:GetSpecialValueFor('reset_time')
		self.nGold = hAbility:GetSpecialValueFor('hit_gold')
		self.nGoldPerMinute = hAbility:GetSpecialValueFor('gold_per_minute')
		self.nExp = hAbility:GetSpecialValueFor('hit_exp')
		self.nXPM = hAbility:GetSpecialValueFor('exp_per_minute')
		
		hParent:SetBaseMaxHealth(self.nMaxStacks)
		hParent:SetMaxHealth(self.nMaxStacks)

		self:SetStacks(self.nMaxStacks)

		self:RegisterSelfEvents()
	end
end

function m_shitcoin_ability:OnDestroy()
	if IsServer() then
		if self.listener then
			StopListeningToGameEvent(self.listener)
		end
		self:UnregisterSelfEvents()
	end
end

function m_shitcoin_ability:SetStacks(nStacks)
	self:SetStackCount(nStacks)
	self:GetParent():SetHealth(nStacks > 0 and nStacks or self.nMaxStacks)
end

function m_shitcoin_ability:OnParentTakeAttackLanded(t)
	if not t.attacker or not t.attacker.ModifyGoldFiltered or t.attacker:IsIllusion() or not t.attacker:IsRealHero() then
		return
	end

	local hPlayer = PlayerResource:GetPlayer(t.attacker:GetPlayerOwnerID())
	if not hPlayer then
		return
	end

	local nStacks = self:GetStackCount()

	if nStacks > 0 then
		local nTime = GameRules:GetDOTATime(false, false) / 60
		local nGold = math.floor(self.nGold + nTime * self.nGoldPerMinute)
		local nExp = math.floor(self.nExp + nTime * self.nXPM)
		
		nGold = t.attacker:ModifyGoldFiltered(nGold, false, DOTA_ModifyGold_NeutralKill)
		SendOverheadEventMessage(hPlayer, OVERHEAD_ALERT_GOLD, t.target, nGold, nil)

		ModifyExperienceFiltered(t.attacker, nExp)

		if nStacks == self.nMaxStacks then
			self:SetDuration(self.nResetTime, true)
			self:StartIntervalThink(self.nResetTime)
		end

		self:SetStacks(nStacks-1)
	end
end

function m_shitcoin_ability:OnIntervalThink()
	self:SetDuration(-1, true)
	self:SetStacks(self.nMaxStacks)
	self:StartIntervalThink(-1)
end