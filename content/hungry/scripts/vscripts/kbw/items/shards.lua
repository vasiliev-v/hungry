local tShards = {
	item_shard_strength = {
		nModifierProperty = MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		sModifierFunction = 'GetModifierBonusStats_Strength',
		sGenKey = 'Strength',
		sTexture = 'item_shard_strength',
	},
	item_shard_agility = {
		nModifierProperty = MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		sModifierFunction = 'GetModifierBonusStats_Agility',
		sGenKey = 'Agility',
		sTexture = 'item_shard_agility',
	},
	item_shard_intellect = {
		nModifierProperty = MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		sModifierFunction = 'GetModifierBonusStats_Intellect',
		sGenKey = 'Intellect',
		sTexture = 'item_shard_intellect',
	},
}

local sPath = "kbw/items/shards"
local GM = GetGameMode('GameModeKBW')

for sShardName, tData in pairs( tShards ) do
	local sModPassive = 'm_' .. sShardName
	local sModConsume = sModPassive .. '_consume'

	LinkLuaModifier( sModPassive, sPath, 0 )
	LinkLuaModifier( sModConsume, sPath, 0 )

	-------------------------------------------------------------

	local cShard = class{}
	_G[ sShardName ] = cShard

	function cShard:GetIntrinsicModifierName()
		return sModPassive
	end

	function cShard:GetGoldCost()
		local hCaster = self:GetCaster()
		if not hCaster or hCaster:IsIllusion() then
			return 0
		end

		local nPlayer = hCaster:GetPlayerOwnerID()
		if nPlayer < 0 then
			return 0
		end
	
		local nCost
	
		if IsServer() then
			local tPlayerData = GM.tPlayers[ nPlayer ]
			if tPlayerData then
				nCost = tPlayerData.tShardCosts[ tData.sGenKey ]
			end
		else
			nCost = GenTable:Get( 'ShardsCosts.' ..  tData.sGenKey .. '.' .. nPlayer )
		end

		return nCost or 0
	end

	function cShard:OnSpellStart()
		local hCaster = self:GetCaster()
		local nBonus = self:GetSpecialValueFor('stats_per_use')

		GenTable:SetAll( 'ShardsStats.' ..  tData.sGenKey, nBonus, true )

		AddModifier( sModConsume, {
			hTarget = hCaster,
			hCaster = hCaster,
			hAbility = self,
			bStacks = true,
			bAddToDead = true,
			bonus = nBonus,
		} )

		local nPlayer = hCaster:GetPlayerOwnerID()
		if nPlayer >= 0 then


			local tPlayerData = GM.tPlayers[ nPlayer ]
			if tPlayerData then
				local nNewCost = tPlayerData.tShardCosts[ tData.sGenKey ] or 0
				nNewCost = nNewCost + self:GetSpecialValueFor('add_cost_per_use')
				nNewCost = math.min(nNewCost, self:GetSpecialValueFor('max_cost'))

				tPlayerData.tShardCosts[ tData.sGenKey ] = nNewCost
				GenTable:SetAll( 'ShardsCosts.' ..  tData.sGenKey .. '.' .. nPlayer, nNewCost, true )
			end
		end

		hCaster:RemoveItem( self )
	end

	-------------------------------------------------------------

	local cModConsume = ModifierClass{
		bPermanent = true,
	}

	_G[ sModConsume ] = cModConsume

	function cModConsume:GetTexture()
		return tData.sTexture
	end

	function cModConsume:AllowIllusionDuplicate()
		return true
	end

	function cModConsume:DeclareFunctions()
		return { tData.nModifierProperty }
	end

	cModConsume[ tData.sModifierFunction ] = function( self )
		if IsServer() then
			return self.nBonus * self:GetStackCount()
		else
			return ( GenTable:Get( 'ShardsStats.' .. tData.sGenKey ) or 0 ) * self:GetStackCount()
		end
	end

	function cModConsume:OnCreated( t )
		if IsServer() then
			self.nBonus = t.bonus or 0

			local hParent = self:GetParent()
			if hParent:IsHero() then
				local hOriginal = FindIllusionOriginal( hParent )
				if hOriginal and hOriginal ~= hParent then
					local hMod = hOriginal:FindModifierByName( sModConsume )
					if hMod then
						self:SetStackCount( hMod:GetStackCount() )
						self.nBonus = hMod.nBonus
					end
				end
			end
		else
			self.nBonus = GenTable:Get( 'ShardsStats.' .. tData.sGenKey ) or 0
		end
	end

	-------------------------------------------------------------

	local cModPassive = ModifierClass{
		bHidden = true,
		bMultiple = true,
	}

	_G[ sModPassive ] = cModPassive

	function cModPassive:DeclareFunctions()
		return { tData.nModifierProperty }
	end

	cModPassive[ tData.sModifierFunction ] = function( self )
		return self.nBonus
	end

	function cModPassive:OnCreated()
		ReadAbilityData( self, {
			nBonus = 'bonus_stat',
		})
	end
end