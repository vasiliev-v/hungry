--
CORPSE_MODEL = "models/development/invisiblebox.vmdl" --"models/items/pudge/pudge_skeleton_hook.vmdl"
--"particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_eztzhok_ambient_blade_rope_lv.vpcf"
--"models/props_nature/grass_clump_00f.vmdl"
--"models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl"
CORPSE_DURATION = 88

------------------------------------------------------------------------------
require( "hero_demo/demo_core" )
require('survival/survival')
require('player')
require('PseudoRandom')
require('runes')
require('libraries/notifications')
require("libraries/table")
------------------------------------------------------------------------------

LinkLuaModifier( "modifier_stun_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_hide_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_orn_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_test_lia", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_knockback_lia", "abilities/modifiers/modifier_knockback_lia.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_archmage_polymorph_lua", "heroes/Archmage/modifier_archmage_polymorph_lua.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_item_shield_of_death_armor", "items/modifier_item_shield_of_death_armor.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_demonologist_riual_of_summoning_status_effect", "heroes/Demonologist/modifier_demonologist_riual_of_summoning_status_effect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("part_mod", "modifiers/parts/part_mod", LUA_MODIFIER_MOTION_NONE )
------------------------------------------------------------------------------

if LiA == nil then
	_G.LiA = class({})
end
------------------------------------------------------------------------------

MAX_LEVEL = 100

XP_TABLE = {}
XP_TABLE[1] = 0
for i = 2, MAX_LEVEL do
    XP_TABLE[i] = XP_TABLE[i-1] + i * 50 
end

------------------------------------------------------------------------------

require('filtering')

function LiA:InitGameMode()
    if GameRules:IsCheatMode() then
        ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(HeroDemo, 'OnGameRulesStateChange'), self)
        ListenToGameEvent('npc_spawned', Dynamic_Wrap(HeroDemo, 'OnNPCSpawned'), self)
        ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(HeroDemo, 'OnItemPurchased'), self)
        ListenToGameEvent('npc_replaced', Dynamic_Wrap(HeroDemo, 'OnNPCReplaced'), self)
		HeroDemo:Init()
	end
    LiA = self

    self.vUserIds = {}
    self.tPlayers = {}
    self.nPlayers = 0

    MIN_RATING_PLAYER = 5
	MAX_AEGIS_COUNT = 4
    PRE_GAME_TIME = 30
    XP_OUTPOST_PER_MIN = 100
    GOLD_OUTPOST_PER_MIN = 100

    ZONA_START_TIME1 = 1800
	ZONA_START_TIME2 = 2100
	ZONA_START_TIME3 = 2400
	ZONA_START_TIME4 = 2700
    ZONA_START_TIME5 = 3000

    ITEM_LIFE_TIME = 60
    ITEM_LIFE_TIME_DROP = 30 -- drop.
    

    GameRules:SetSafeToLeave(true)
	GameRules:SetHeroSelectionTime(90)
    GameRules:SetSameHeroSelectionEnabled(false) -- pick all pl one hero
	GameRules:SetPreGameTime(PRE_GAME_TIME)
    GameRules:SetShowcaseTime(0)
    GameRules:SetPostGameTime(120)
    GameRules:SetStrategyTime(15)
	--
	GameRules:SetGoldTickTime(1)
	GameRules:SetGoldPerTick(1)
	--GameRules:SetHeroMinimapIconScale(1)
   -- GameRules:SetCreepMinimapIconScale(1)
	--GameRules:SetRuneMinimapIconScale(1)
    GameRules:SetFirstBloodActive(true)

    GameRules:SetAllowOutpostBonuses(false)
    

    GameRules:SetUseBaseGoldBountyOnHeroes(true)

    GameRules:SetStartingGold(600)

    GameRules:SetCustomGameEndDelay(10)

    GameRules:SetUseUniversalShopMode(true)
    
	local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetMaximumAttackSpeed(600)
	
    GameMode:SetCustomXPRequiredToReachNextLevel(XP_TABLE)
    GameMode:SetUseCustomHeroLevels(true)

    --GameMode:SetRecommendedItemsDisabled(true)
    --GameMode:SetNeutralStashTeamViewOnlyEnabled(true)
    --GameMode:SetNeutralItemHideUndiscoveredEnabled(true)
    --GameMode:SetHUDVisible(12, false)
    --GameMode:SetHUDVisible(1, false) 
    GameMode:SetTopBarTeamValuesVisible(false)
    --GameMode:SetHudCombatEventsDisabled(false)
    
    GameMode:SetBuybackEnabled(false)
    GameMode:SetTowerBackdoorProtectionEnabled(false)
    GameMode:SetStashPurchasingDisabled(false)
    GameMode:SetLoseGoldOnDeath(false)
    GameMode:SetFreeCourierModeEnabled(true)
    --GameMode:SetUseTurboCouriers(true)
    GameMode:SetPauseEnabled(false)

    GameRules:LockCustomGameSetupTeamAssignment(true)
    GameRules:SetCustomGameSetupRemainingTime(0)
    GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameMode:SetFogOfWarDisabled(false) -- false
    GameMode:SetSelectionGoldPenaltyEnabled(true)
    GameMode:SetItemAddedToInventoryFilter(Dynamic_Wrap(Survival, "ItemAddFilter"), self)
    -- GameMode:SetTPScrollSlotItemOverride("item_lia_healing_ward")
    GameMode:SetDraftingBanningTimeOverride(20)
    GameMode:SetDraftingHeroPickSelectTimeOverride(40)
    GameMode:SetCustomScanCooldown(9999999)
    
    if string.match(GetMapName(),"1x10") then
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_7, 1 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_8, 1 )
    elseif string.match(GetMapName(),"2x20") then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_7, 2 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_8, 2 )    
    elseif string.match(GetMapName(),"3x21") then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 3 )
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 3 )
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 3 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 3 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_3, 3 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_4, 3 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_5, 3 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_6, 3 )
    elseif string.match(GetMapName(),"5x20") then
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 5 )
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
	    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 5 )
        GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 5 )
    end
    
   
    self.m_TeamColors = {}
	self.m_TeamColors[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }	--		Teal
	self.m_TeamColors[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }		--		Yellow
	self.m_TeamColors[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }	--      Pink
	self.m_TeamColors[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }		--		Orange
	self.m_TeamColors[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }		--		Blue
	self.m_TeamColors[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }	--		Green
	self.m_TeamColors[DOTA_TEAM_CUSTOM_5] = { 129, 83, 54 }		--		Brown
	self.m_TeamColors[DOTA_TEAM_CUSTOM_6] = { 27, 192, 216 }	--		Cyan
	self.m_TeamColors[DOTA_TEAM_CUSTOM_7] = { 199, 228, 13 }	--		Olive
	self.m_TeamColors[DOTA_TEAM_CUSTOM_8] = { 140, 42, 244 }	--		Purple

	for team = 0, (DOTA_TEAM_COUNT-1) do
		color = self.m_TeamColors[ team ]
		if color then
			SetTeamCustomHealthbarColor( team, color[1], color[2], color[3] )
		end
	end

    PlayerResource:SetCustomPlayerColor(0, 255, 3, 3)
    PlayerResource:SetCustomPlayerColor(1, 0, 66, 255)
    PlayerResource:SetCustomPlayerColor(2, 28, 230, 185)
    PlayerResource:SetCustomPlayerColor(3, 84, 0, 129)
    PlayerResource:SetCustomPlayerColor(4, 255, 252, 1)
    PlayerResource:SetCustomPlayerColor(5, 254, 186, 14)
    PlayerResource:SetCustomPlayerColor(6, 32, 192, 0)
    PlayerResource:SetCustomPlayerColor(7, 229, 91, 176)
    PlayerResource:SetCustomPlayerColor(8 ,0, 255, 255) -- голубой
    PlayerResource:SetCustomPlayerColor(9 ,153, 0, 204) -- фиолетовый
    PlayerResource:SetCustomPlayerColor(10 ,225, 0, 255)  -- фиолетовый 
    PlayerResource:SetCustomPlayerColor(11 ,51, 204, 51)
    PlayerResource:SetCustomPlayerColor(12 ,0, 105, 0)
    PlayerResource:SetCustomPlayerColor(13 ,128, 0, 0)
    PlayerResource:SetCustomPlayerColor(14 ,176, 0, 0)
    PlayerResource:SetCustomPlayerColor(15 ,60,20, 74)
	PlayerResource:SetCustomPlayerColor(16 ,139, 69, 19)
    PlayerResource:SetCustomPlayerColor(17 ,0, 0, 255)
	PlayerResource:SetCustomPlayerColor(18 ,0, 0, 128)
    PlayerResource:SetCustomPlayerColor(19 ,0, 0, 0)
    PlayerResource:SetCustomPlayerColor(20, 255, 255, 0)
    PlayerResource:SetCustomPlayerColor(21 ,0, 102, 255) -- синий
    PlayerResource:SetCustomPlayerColor(22 ,255, 153, 51)
    --listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(LiA, 'OnGameStateChange'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(LiA, 'OnConnectFull'), self)
    ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(LiA, 'OnPlayerLearnedAbility'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(LiA, 'OnNPCSpawned'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(LiA, 'OnGameRulesStateChange'), self)


	GameMode:SetDamageFilter( Dynamic_Wrap( LiA, "FilterDamage" ), self )
    GameMode:SetModifyExperienceFilter( Dynamic_Wrap( LiA, "ExperienceFilter" ), self )

    CustomGameEventManager:RegisterListener("lia_random_hero", Dynamic_Wrap(LiA, "RandomHero"))


    CustomGameEventManager:RegisterListener("SelectPart", Dynamic_Wrap(wearables, 'SelectPart'))
    CustomGameEventManager:RegisterListener("BuyShopItem", Dynamic_Wrap(Shop, 'BuyShopItem'))
    CustomGameEventManager:RegisterListener("SetDefaultPart", Dynamic_Wrap(wearables, 'SetDefaultPart'))
    CustomGameEventManager:RegisterListener("SetDefaultPets", Dynamic_Wrap(SelectPets, 'SetDefaultPets'))
    CustomGameEventManager:RegisterListener("SetDefaultSkin", Dynamic_Wrap(wearables, 'SetDefaultSkin'))
    CustomGameEventManager:RegisterListener("UpdateTops", Dynamic_Wrap(top, 'UpdateTops'))
    CustomGameEventManager:RegisterListener("SelectPets", Dynamic_Wrap(SelectPets, 'SelectPets'))
    CustomGameEventManager:RegisterListener("OpenChestAnimation", Dynamic_Wrap(Shop, 'OpenChestAnimation'))
    CustomGameEventManager:RegisterListener("SelectVO", Dynamic_Wrap(Shop,'SelectVO'))
    CustomGameEventManager:RegisterListener("EventRewards", Dynamic_Wrap(Shop, 'EventRewards'))
    CustomGameEventManager:RegisterListener("EventBattlePass", Dynamic_Wrap(Shop, 'EventBattlePass'))
    Pets:Init()
end

 -- Debugging setup
 local spew = 1
 if TROLLNELVES2_DEBUG_SPEW then
   spew = 1
 end
 Convars:RegisterConvar('lia2_spew', tostring(spew), 'Set to 1 to start spewing lia debug info.  Set to 0 to disable.', 0)

function LiA:OnGameStateChange()  
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
    	print("LIA_MODE_SURVIVAL")
        self.GameMode = LIA_MODE_SURVIVAL
        Survival:InitSurvival()
    elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        Runes:StartRunesSpawn()
        Runes:StartOutPost()
    end
    if self.GameMode == LIA_MODE_SURVIVAL then
        Survival:OnGameStateChange()
    else 

    end 
end

function LiA:OnConnectFull(event)
    PrintTable("OnConnectFull",event)
	
	local playerID = event.PlayerID
    local player = PlayerResource:GetPlayer(playerID)
   
    self.vUserIds[event.userid] = player
    player.userid = event.userid
    table.insert(self.tPlayers,player)
    self.nPlayers = self.nPlayers + 1  
end

function LiA:ExperienceFilter( kv )
    --[[
    if kv.reason_const == 5 then
        kv.experience = XP_OUTPOST_PER_MIN * math.ceil((GameRules:GetDOTATime(false, false)+1)/60)
        local hero = PlayerResource:GetSelectedHeroEntity(kv.player_id_const)
        local valueGold = GOLD_OUTPOST_PER_MIN * math.ceil((GameRules:GetDOTATime(false, false)+1)/60)
        hero:ModifyGold(valueGold, false, DOTA_ModifyGold_Unspecified)
	    SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, hero, valueGold, nil )
    end
    ]]
    return true
end

function LiA:OnNPCSpawned( event )
    local spawnedUnit = EntIndexToHScript( event.entindex )

    if self.GameMode == LIA_MODE_SURVIVAL then
        Survival:OnNPCSpawned(event)
    end
end


function LiA:RandomHero(event)
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION then
        if not PlayerResource:HasRandomed(event.PlayerID) then
            --print("Random")
            PlayerResource:GetPlayer(event.PlayerID):MakeRandomHeroSelection()
            PlayerResource:SetHasRandomed(event.PlayerID)
            if PlayerResource:GetGold(event.PlayerID) == 330 then
                PlayerResource:ModifyGold(event.PlayerID, -150, false, DOTA_ModifyGold_Unspecified)
            else
                PlayerResource:ModifyGold(event.PlayerID, 50, false, DOTA_ModifyGold_Unspecified)
            end
        --[[elseif PlayerResource:CanRepick(event.PlayerID) and PlayerResource:GetGold(event.PlayerID) >= 50 then 
            print("RePick")
            PlayerResource:GetPlayer(event.PlayerID):MakeRandomHeroSelection()
            PlayerResource:SetCanRepick(event.PlayerID,false)
            --PlayerResource:ModifyGold(event.PlayerID, -250, false, DOTA_ModifyGold_Unspecified)]]
        end
    end
end

function LiA:OnGameRulesStateChange()
    DebugPrint("GameRulesStateChange ******************")
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_PRE_GAME then
        self:PreStart()
    end
    if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        DebugPrint("GameRulesStateChange GO TEAM******************")
        local countSort = 0 
		Timers:CreateTimer(0.4, function()
            local playersInTeams = {}
			for nPlayerID = 0, (DOTA_MAX_TEAM_PLAYERS-1) do
				if PlayerResource:IsValidPlayer( nPlayerID ) and nPlayerID>=0 then
					local player = PlayerResource:GetPlayer(nPlayerID)
					if player then
						local playerTeam = player:GetTeam()
						playersInTeams[playerTeam] = playersInTeams[playerTeam] or {}
						table.insert(playersInTeams[playerTeam], nPlayerID)
					end
				end
			end
			local fTeamNoFull
			local sTeamNoFull
			for key,value in pairs(playersInTeams) do
				if #value<GameRules:GetCustomGameTeamMaxPlayers(key) then
					if fTeamNoFull == nil then
						fTeamNoFull = key
					else
						sTeamNoFull = key
					end
				end
				if fTeamNoFull and sTeamNoFull then
					while (#playersInTeams[fTeamNoFull] < GameRules:GetCustomGameTeamMaxPlayers(fTeamNoFull)) and (#playersInTeams[sTeamNoFull] > 0) do
						local pID = table.random(playersInTeams[sTeamNoFull])
						local player = PlayerResource:GetPlayer(pID)
						player:SetTeam(fTeamNoFull)
						for i,x in pairs(playersInTeams[sTeamNoFull]) do
							if x == pID then
								playersInTeams[sTeamNoFull][i] = nil
							end
						end
					end
					fTeamNoFull = nil
					sTeamNoFull = nil
				end
			end 
            countSort = countSort + 1 
            if countSort <= 10 then
                return 1
            end
		end)
    end

    for i = 0, 12 do
		AddFOWViewer( i, Vector(0,0,0), 1800, 99999, false)
	end

    local outpostEntities = Entities:FindAllByClassname("npc_dota_watch_tower")
    for _, outpostEnt in pairs(outpostEntities) do
        outpostEnt:SetTeam(5)
        outpostEnt:SetSkin(0)
        outpostEnt:SetInvulnCount(0)
    end
end

function LiA:PreStart()
    local gameStartTimer = PRE_GAME_TIME
    Timers:CreateTimer(function()
        if gameStartTimer > 0 then
            Notifications:ClearBottomFromAll()
            Notifications:BottomToAll({
                text = "Game starts in " .. gameStartTimer,
                style = {color = '#E62020'},
                duration = 1
            })
            gameStartTimer = gameStartTimer - 1
            return 1
        else
                Notifications:ClearBottomFromAll()
                Notifications:BottomToAll(
                {
                    text = "Game started!",
                    style = {color = '#E62020'},
                    duration = 1
                })
                -- Unstun the elves
                for pID = 0, DOTA_MAX_TEAM_PLAYERS do
                    local playerHero = PlayerResource:GetSelectedHeroEntity(pID)
                    if playerHero then
                        playerHero:RemoveModifierByName("modifier_stunned")
                        playerHero:RemoveModifierByName("modifier_invulnerable")
                    end
                end
            end
    end)

    if IsServer() then
        
        GameRules.PlayersCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)  + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_1) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_2) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_3) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_4) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_5) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_6) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_7) + 
                                 PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_8)
        GameRules:SendCustomMessage("<font color='#00FFFF '> Number of players: " .. GameRules.PlayersCount .. "</font>" ,  0, 0)
        wearables:SetPart()
        --wearables:SetSkin()
        SelectPets:SetPets()
    end 
    

end

function LiA:OnPlayerLearnedAbility(keys)
    if not IsServer() then return end

	local parent = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	if not parent or parent:IsNull() then return end
    local talent = parent:FindAbilityByName(keys.abilityname)
	if not talent or talent:IsNull() then return end
    local tKv = talent:GetAbilityKeyValues()
    DebugPrint(keys.abilityname)
    if tKv.AddModifiers then
        DebugPrint("talent.AddModifiers")
        DebugPrint(keys.abilityname)
        OnLearn( talent, function()
            for sModifier, tData in pairs( tKv.AddModifiers ) do
                local aMods = parent:FindAllModifiersByName(sModifier)
                for _, hMod in ipairs(aMods) do
                    if hMod:GetAbility() == talent then
                        goto continue
                    end
                end

                local tCreateData = {
                    hTarget = parent,
                    hCaster = parent,
                    hAbility = talent,
                    bAddToDead = true,
                    nAttempts = 3000,
                }

                if tData.Path then
                    LinkLuaModifier(sModifier, tData.Path, 0)
                    tData.Path = nil
                end

                for sField, xValue in pairs( tData ) do
                    local nValue = tonumber(xValue)
                    if not nValue then
                        if xValue:sub(1,1) == '$' then
                            nValue = xValue:sub(2)
                        else
                            nValue = talent:GetSpecialValueFor(xValue)
                        end
                    end
                    tCreateData[ sField ] = nValue
                end

                AddModifier( sModifier, tCreateData )
                DebugPrint("AddModifier " .. sModifier)
                ::continue::
            end
        end )
    end

end