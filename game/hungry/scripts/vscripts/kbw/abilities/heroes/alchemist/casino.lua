LinkLuaModifier('m_alchemist_casino_thinker', "kbw/abilities/heroes/alchemist/casino", 0)

alchemist_casino = class{}

function alchemist_casino:GetIntrinsicModifierName()
	return 'm_alchemist_casino_thinker'
end

function alchemist_casino:Spawn()
	if IsServer() then
		local hCaster = self:GetCaster()
		self:SetLevel(1)

		Timer(function()
			if not exist(self) or not exist(hCaster) then
				return
			end

			if hCaster:HasScepter() then
				if not self.bActive then
					self.bActive = true
					self:SetHidden(false)
				end
			else
				if self.bActive then
					self.bActive = false
					self:SetHidden(true)
				end
			end

			return 0.1
		end)
	end
end

function alchemist_casino:GetGoldCost(nLevel)
	local nCost

	if IsServer() then
		nCost = self.nCost
	else
		nCost = GenTable:Get('CasinoCost')
	end

	return nCost or self:GetSpecialValueFor('min_bet')
end

function alchemist_casino:OnSpellStart()
	local hCaster = self:GetCaster()
	if not hCaster.ModifyGold then
		return
	end

	local nPlayer = hCaster:GetPlayerOwnerID()
	local nBet = self:GetGoldCost(self:GetLevel()-1)
	local nMin = self:GetSpecialValueFor('mult_min')
	local nMax = self:GetSpecialValueFor('mult_max')

	local nGold = math.floor(RandomFloat(nMin, nMax) * nBet + 0.5)
	PlayerResource:SetGold(nPlayer, PlayerResource:GetUnreliableGold(nPlayer) + nGold, false)

	SendOverheadEventMessage(hCaster:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, hCaster, nGold, nil)
end

m_alchemist_casino_thinker = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_alchemist_casino_thinker:OnCreated(t)
	if IsServer() then
		self.hParent = self:GetParent()
		self.hAbility = self:GetAbility()
		self.nPlayer = self.hParent:GetPlayerOwnerID()
		self.nMinCost = self.hAbility:GetSpecialValueFor('min_bet')
		self.nBetMultiplier = self.hAbility:GetSpecialValueFor('bet_size_pct') / 100
		self.nBetMultiplier2 = self.hAbility:GetSpecialValueFor('small_bet_pct') / 100
		self:OnIntervalThink()
		self:StartIntervalThink(1/30)
	end
end

function m_alchemist_casino_thinker:OnIntervalThink()
	local nCost = self.hAbility:GetAutoCastState() and self.nBetMultiplier2 or self.nBetMultiplier
	nCost = math.max(self.nMinCost, nCost * PlayerResource:GetGold(self.nPlayer))

	GenTable:Set(self.nPlayer, 'CasinoCost', nCost, true)
	self.hAbility.nCost = nCost
end