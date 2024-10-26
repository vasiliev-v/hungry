require 'lib/lua/base'
require 'lib/timer'

if balance == nil then
	balance = {}
end

local GM = self
local sPath = self:Path("balance/modifiers")

LinkLuaModifier( "m_balance_gold_buff", sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "m_balance_gold_debuff", sPath, LUA_MODIFIER_MOTION_NONE )
-- LinkLuaModifier( "m_balance_xp_buff", sPath, LUA_MODIFIER_MOTION_NONE )
-- LinkLuaModifier( "m_balance_xp_debuff", sPath, LUA_MODIFIER_MOTION_NONE )

balance.nMaxXP = self.MAX_XP
balance.nMaxGold = 350000
balance.nMaxBuff = 200
balance.EXP_WEIGHT = 2
balance.EST_MAX_TIME = 42 * 60
balance.GROW_RATE_POWER = 1.9
balance.FLEX_SCALE = 0.015
balance.BALANCE_POWER = 2.0
balance.BOOST_POWER = 2.7
balance.MAX_HEALTH = 25000
balance.HEALTH_MIN_SCALE = 0.01
balance.HEALTH_MAX_SCALE = 0.5
-- balance.HEALTH_MAX_TIME = 27 * 60

balance.boosts = {}
balance.players = {}
balance.cached = {}

function balance:GetPlayerHealthBonus(pid)
	if self.healths then
		return self.healths[pid]
	end
	return 0
end

function balance:GetPlayerCost(nPlayer)
	return PlayerResource:GetNetWorth(nPlayer) + GetConsumedNetWorth(nPlayer)
end

function balance:GetPlayerExp(nPlayer)
	return PlayerResource:GetTotalEarnedXP(nPlayer)
end

function balance:GetPlayerWorth(nPlayer)
	return self:GetPlayerCost(nPlayer) + self:GetPlayerExp(nPlayer) * self.EXP_WEIGHT
end

function balance:GetTeamWorth(nTeam)
	local n = 0
	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:GetSelectedHeroEntity(i) and PlayerResource:GetTeam(i) == nTeam then
			n = n + self:GetPlayerWorth(i)
		end
	end
	return n
end

function balance:GetMaxPlayers()
	local t = {}
	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:GetSelectedHeroEntity(i) and GM:IsConnected(i) then
			local nTeam = PlayerResource:GetTeam(i)
			t[nTeam] = (t[nTeam] or 0) + 1
		end
	end
	return math.max(t[DOTA_TEAM_GOODGUYS] or 0, t[DOTA_TEAM_BADGUYS] or 0)
end

function balance:GetMaxPlayerWorth()
	return self.nMaxGold + self.nMaxXP * self.EXP_WEIGHT
end

function balance:GetMaxTeamWorth()
	return self:GetMaxPlayerWorth() * self:GetMaxPlayers()
end

function balance:GetPlayerScale(nTeam)
	return math.min(1, self:GetPlayerWorth(nTeam) / self:GetMaxPlayerWorth())
end

function balance:GetTeamScale(nTeam)
	return math.min(1, self:GetTeamWorth(nTeam) / self:GetMaxTeamWorth())
end

function balance:GetEstScale(nTime)
	return math.min(1, 600 / self:GetMaxPlayerWorth() + (nTime / self.EST_MAX_TIME)^self.GROW_RATE_POWER)
end

function balance:GetPlayerMultiplier(nPlayer)
	return self.players[nPlayer] or 1
end

function balance:GetTeamBoost(nTeam)
	return self.boosts[nTeam] or 1
end

function balance:GetPlayerIncomeModifier(nPlayer)
	local nMult = self:GetPlayerMultiplier(nPlayer) * self:GetTeamBoost(PlayerResource:GetTeam(nPlayer))
	return math.min(self.nMaxBuff, (nMult - 1) * 100)
end

function balance:GetPlayerIncomeMultiplier(nPlayer)
	return self.cached[nPlayer] or 1
end

function balance:Start()
	if exist( self.hThinker ) then
		self.hThinker:Destroy()
	end

	self.hThinker = Timer( function()
		self:Think()
		return 1
	end )
end

function balance:Think()
	local time = GameRules:GetDOTATime( false, false )
	local est = self:GetEstScale(time)
	local good = self:GetTeamScale(DOTA_TEAM_GOODGUYS)
	local bad = self:GetTeamScale(DOTA_TEAM_BADGUYS)

	local function get_team_boost(team, other)
		return math.max(1, (other + self.FLEX_SCALE) / (team + self.FLEX_SCALE))^self.BOOST_POWER
	end

	self.boosts = {
		[DOTA_TEAM_GOODGUYS] = get_team_boost(good, bad),
		[DOTA_TEAM_BADGUYS] = get_team_boost(bad, good),
	}

	self.players = {}
	self.cached = {}
	self.healths = {}

	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		local hero = PlayerResource:GetSelectedHeroEntity(pid)

		if exist(hero) and GM:IsConnected(pid) then
			local scale = self:GetPlayerScale(pid)
			self.players[pid] = ((est + self.FLEX_SCALE) / (scale + self.FLEX_SCALE))^self.BALANCE_POWER

			local pct = self:GetPlayerIncomeModifier(pid)
			self.cached[pid] = 1 + pct / 100
			pct = math.floor(pct + 0.5)

			-- health bonus
			local enemy_scale = PlayerResource:GetTeam(pid) == DOTA_TEAM_GOODGUYS and bad or good
			local lack = enemy_scale - scale - self.HEALTH_MIN_SCALE
			if lack > 0 then
				self.healths[pid] = math.min(1, lack / (self.HEALTH_MAX_SCALE - self.HEALTH_MIN_SCALE)) * self.MAX_HEALTH
			else
				self.healths[pid] = 0
			end

			local modname
			if pct > 0 then
				modname = 'm_balance_gold_buff'
			elseif pct < 0 then
				modname = 'm_balance_gold_debuff'
			end

			if not modname or not hero:HasModifier(modname) then
				hero:RemoveModifierByName('m_balance_gold_buff')
				hero:RemoveModifierByName('m_balance_gold_debuff')
			end

			if modname then
				local mod = hero:AddNewModifier(hero, nil, modname, {})
				if mod then
					mod:SetStackCount(math.abs(pct))
				end
			end
		end
	end
end
