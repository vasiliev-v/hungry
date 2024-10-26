require 'lib/timer'
require 'lib/basis/game_mode'
self.tListenerFunctions = {}
self.tTeams = {}

------------------------------------------------------------------

self.tListenerFunctions.game_rules_state_change = function()
	local nState = GameRules:State_Get()

	if nState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		self:GameSetup()
	elseif nState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		self:GamePick()
	elseif nState == DOTA_GAMERULES_STATE_PRE_GAME then
		self:GamePregame()
	elseif nState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:GameStart()
	end
end



function self:GamePick()
end

function self:GameSetup()

end

function self:GamePregame()

	Events:Trigger('GamePregame')
end

function self:GameStart()
	-- reklama:Init()

	Events:Trigger('GameStart')
end

local tLimitSpecialUnits = {
	npc_dota_earth_spirit_stone = 1,
}

local tIgnoreLimitUnits = {
	npc_dota_techies_land_mine = 1,
	npc_dota_muerta_revenant = 1,
}

self.tListenerFunctions.npc_spawned = function( tEvent )
	local hUnit = EntIndexToHScript( tEvent.entindex )
	if not exist(hUnit) then
		return
	end

	local bIsGameUnit = UnitFilter(
		hUnit,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		DOTA_TEAM_NEUTRALS
	) == UF_SUCCESS
	or hUnit:HasMovementCapability()

	if bIsGameUnit then
		hUnit:AddNewModifier( hUnit, nil, "m_kbw_unit", {} )
	end

	if hUnit:IsHero() then
		Timer(1/30, function()
			if exist(hUnit) then

				if hUnit:HasModifier('modifier_arc_warden_tempest_double') then
					for nAbility = 0, hUnit:GetAbilityCount() - 1 do
						local hAbility = hUnit:GetAbilityByIndex( nAbility )
						if hAbility then
							local aModifiers = GetAbilityValueModifiers(hAbility)
							for _, hMod in ipairs(aModifiers) do
								hMod:Destroy()
							end

							hAbility.bChecked = nil
						end
					end

					local hOwner = PlayerResource:GetSelectedHeroEntity(hUnit:GetPlayerOwnerID())
					if hOwner then
						for _, hMod in ipairs(hOwner:FindAllModifiers()) do
							if type(hMod.AllowIllusionDuplicate) == 'function' and hMod:AllowIllusionDuplicate() then
								hUnit:AddNewModifier(hUnit, hMod:GetAbility(), hMod:GetName(), {})
							end
						end
					end
				end

				if not exist(hUnit.hThinkerTimer) then
					hUnit.hThinkerTimer = Timer(function()
						if exist(hUnit) then
							self:CheckAbilities(hUnit)
							self:CheckConditionalModifiers(hUnit)
							return 0.3
						end
					end)
				end

				-- illusion neutral slot fix
				if hUnit:IsIllusion() then
					local hOriginal = FindIllusionOriginal(hUnit)
					if hOriginal then
						local hItem = hOriginal:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
						if hItem then
							local sItem = hItem:GetName()
							local hTargetItem
							IterateInventory(hUnit, 'ANY', function(nSlot, hItem)
								if hItem and hItem:GetName() == sItem and (IsStash(nSlot) or not hOriginal:GetItemInSlot(nSlot)) then
									hTargetItem = hItem
									return true
								end
							end)
							if hTargetItem then
								hUnit:RemoveItem(hTargetItem)
								hUnit:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_NEUTRAL_SLOT)
								local hTargetItem = AddItem(hUnit, sItem, {
									nSlot = DOTA_ITEM_SLOT_1,
									bRedirect = false,
									bDrop = false,
								})
								if hTargetItem then
									hTargetItem:SetCurrentCharges(hItem:GetCurrentCharges())
									hTargetItem:SetSecondaryCharges(hItem:GetSecondaryCharges())
									if hItem:GetToggleState() ~= hTargetItem:GetToggleState() then
										hTargetItem:ToggleAbility()
									end
								end
								hUnit:SwapItems(DOTA_ITEM_SLOT_1, DOTA_ITEM_NEUTRAL_SLOT)
							end
						end
					end
				end
			end
		end)

		if not hUnit:HasModifier('m_kbw_hero') then
			hUnit:AddNewModifier( hUnit, nil, 'm_kbw_hero', {} )
		end
	end

	if not hUnit.bSpawned then
		self:FirstSpawn( hUnit )
	end

	-- unit limit
	self.tSummonedUnits = self.tSummonedUnits or {}
	Timer(1/30, function()
		if not exist(hUnit) then
			return
		end

		local sUnit = hUnit:GetUnitName()
		if not hUnit:IsRealHero() and not hUnit:IsCourier()
		and not tIgnoreLimitUnits[sUnit] and (bIsGameUnit or tLimitSpecialUnits[sUnit]) then
			local nPlayer = hUnit:GetPlayerOwnerID()
			if PlayerResource:IsValidPlayerID(nPlayer) then
				local qUnits = self.tSummonedUnits[nPlayer]
				if not qUnits then
					qUnits = {}
					self.tSummonedUnits[nPlayer] = qUnits
				end

				for i = #qUnits, 1, -1 do
					if not exist(qUnits[i]) or not qUnits[i]:IsAlive() then
						table.remove(qUnits, i)
					end
				end

				table.insert(qUnits, hUnit)
				if #qUnits > UNIT_LIMIT then
					local hDeleteUnit = table.remove(qUnits, 1)
					if exist(hDeleteUnit) then
						hDeleteUnit:ForceKill(false)
					end
				end
			end
		end
	end)

	-- illusions lags force fix
	if hUnit:IsIllusion() then
		Timer(1, function()
			if exist(hUnit) then
				if hUnit:IsAlive() or hUnit:IsReincarnating() then
					return 1
				else
					Timer(10, function()
						if exist(hUnit) then
							hUnit:Destroy()
						end
					end)
				end
			end
		end)
	end

	Events:Trigger('KBW_Spawn', hUnit)
end

function self:FirstSpawn( hUnit )
	
end

function self:InitPlayer( nPlayer, hHero )

end

self.tListenerFunctions.entity_killed = function( eventInfo )
	
end

self.tListenerFunctions.dota_player_gained_level = function( tEvent )
	-- DebugPrint('[BAREBONES] OnPlayerLevelUp')
   -- DebugPrintTable(keys)
    
    --PrintTable(keys)
    
    local player = PlayerResource:GetPlayer(tEvent.player_id) --EntIndexToHScript(keys.player)
    local level = tEvent.level
    local hero = player:GetAssignedHero()  
    
    --времменый фикс вольво пока они сука не вернут всё как было
    if level > 20 and level < 126 then
        hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
    end
    --
end

self.tListenerFunctions.dota_player_learned_ability = function(t)
	local hCaster = PlayerResource:GetSelectedHeroEntity(t.PlayerID)
	if exist(hCaster) then
		local hAbility = hCaster:FindAbilityByName(t.abilityname)
		if exist(hAbility) then
			if hAbility:GetLevel() == 1 then
				local tKV = hAbility:GetAbilityKeyValues()
				if type(tKV.OnLearn) == 'table' then

					if type(tKV.OnLearn.SwitchAbilities) == 'table' then
						local hOld = hCaster:FindAbilityByName(tKV.OnLearn.SwitchAbilities.old)
						if hOld then
							local nLevel = hOld:GetLevel()
							local nIndex = hOld:GetAbilityIndex()
							hCaster:RemoveAbilityByHandle(hOld)

							local hNew = hCaster:AddAbility(tKV.OnLearn.SwitchAbilities.new)
							if hNew then
								hNew:SetLevel(nLevel)
							end
						end
					end

					if type(tKV.OnLearn.GiveItems) == 'table' then
						for _, sItem in pairs(tKV.OnLearn.GiveItems) do
							local hItem = AddItem(hCaster, sItem)
							if hItem then
								hItem:SetPurchaseTime(0)
							end
						end
					end
				end
			end
		end
	end
end

Events:Register('OnTakeDamage', function(t)
	if t.damage > 0 and exist(t.unit) and exist(t.attacker) and t.attacker:GetTeam() ~= DOTA_TEAM_NEUTRALS then
		t.unit.nLastTimeDamaged = GameRules:GetGameTime()
	end
end, {
	sName = 'Listeners',
})

------------------------------------------------------------------

self:StopListeningToGameEvents()

for sEvent, fCallback in pairs( self.tListenerFunctions ) do
	self:ListenToGameEventUnique( sEvent, function(...)
		ppcall(fCallback, ...)
	end)
end

