require('drop')
require('stats')
require('error_debug')
LinkLuaModifier("modifier_aegis", "modifiers/modifier_aegis.lua",LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_venom", "modifiers/modifier_venom.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_venom_mega", "modifiers/modifier_venom_mega.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_winter", "modifiers/modifier_winter.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_winter_mega", "modifiers/modifier_winter_mega.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_summer", "modifiers/modifier_summer.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_summer_mega", "modifiers/modifier_summer_mega.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_water", "modifiers/modifier_water.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_water_mega", "modifiers/modifier_water_mega.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hero_killer", "modifiers/modifier_hero_killer.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_birzha_map_center_vision", "modifiers/modifier_birzha_map_center_vision.lua", LUA_MODIFIER_MOTION_NONE )
local meepoFirst = true
function Survival:OnNPCSpawned(event)
    local spawnedUnit = EntIndexToHScript( event.entindex )

    if spawnedUnit:IsHero() then
        spawnedUnit.units = {}
        spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_item_boots_of_travel_2", {tp_channel_time = 6, tp_cooldown = 60})
        local courier = PlayerResource:GetPreferredCourierForPlayer(spawnedUnit:GetPlayerOwnerID())
        if not courier then
            if spawnedUnit:GetPlayerOwner() then
                local coura = spawnedUnit:GetPlayerOwner():SpawnCourierAtPosition(Vector(-919, 694, 277))
                if coura then
                    coura:SetControllableByPlayer(-1, true)
                    coura:SetOwner(spawnedUnit)
                    coura:SetControllableByPlayer(spawnedUnit:GetPlayerOwnerID(), true)
                end
            end
        end
        if not spawnedUnit:HasAbility("custom_ability_smoke") then
            spawnedUnit:AddAbility("custom_ability_smoke")
        end
        if not spawnedUnit:HasAbility("custom_ability_observer") then
            spawnedUnit:AddAbility("custom_ability_observer")
        end
        if not spawnedUnit:HasAbility("custom_ability_sentry") then
            spawnedUnit:AddAbility("custom_ability_sentry")
        end
        if not spawnedUnit:HasAbility("custom_ability_dust") then
            spawnedUnit:AddAbility("custom_ability_dust")
        end
        
        
        if not spawnedUnit:HasModifier('m_kbw_hero') then
			spawnedUnit:AddNewModifier( spawnedUnit, nil, 'm_kbw_hero', {} )
		end
        if not spawnedUnit:HasAbility('attribute_bonuses_str') then
			spawnedUnit:AddAbility('attribute_bonuses_str')
		end
        if not spawnedUnit:HasAbility('attribute_bonuses_agi') then
			spawnedUnit:AddAbility( 'attribute_bonuses_agi')
		end
        if not spawnedUnit:HasAbility('attribute_bonuses_int') then
			spawnedUnit:AddAbility( 'attribute_bonuses_int')
		end
        if not spawnedUnit:HasAbility('attribute_bonuses_ms') then
			spawnedUnit:AddAbility( 'attribute_bonuses_ms')
		end
       

        

        if GameRules:GetGameTime() < 2100 and spawnedUnit:IsRealHero() then
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_invulnerable", {Duration = 5})
            spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_invisible", {Duration = 10})
        --    spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_aegis_buff", {Duration = 10})
        end
    end
    if spawnedUnit:GetUnitName() == "npc_dota_courier" then
        spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_invulnerable", {})
        --spawnedUnit:SetRespawnPosition(Vector(-919, 694, 277))
       -- spawnedUnit:SetAbsOrigin(Vector(-919, 694, 277))
       -- FindClearSpaceForUnit( spawnedUnit , Vector(-919, 694, 277) , true )
        --spawnedUnit:GetPlayerOwner():SpawnCourierAtPosition(Vector(-919, 694, 277))
    end
    if spawnedUnit:GetUnitName() == "npc_dota_hero_meepo" then
        local mainMeepo = PlayerResource:GetSelectedHeroEntity(spawnedUnit:GetPlayerOwnerID())
        if meepoFirst then
            mainMeepo.units = {}
            meepoFirst = false
        end
        table.insert(mainMeepo.units, spawnedUnit)
        if mainMeepo then
            if mainMeepo:HasModifier("modifier_aegis") then
                if mainMeepo:GetModifierStackCount("modifier_aegis", mainMeepo) > 0 then
                    spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_aegis", {})
                    spawnedUnit:SetModifierStackCount("modifier_aegis", spawnedUnit, mainMeepo:GetModifierStackCount("modifier_aegis", mainMeepo))
                else
                    spawnedUnit:RemoveModifierByName("modifier_aegis")
                end
            else
                spawnedUnit:RemoveModifierByName("modifier_aegis")
            end
        end
    end
end

function Survival:OnPlayerPickHero(keys)


    local hero = EntIndexToHScript(keys.heroindex)
    local playerID = hero:GetPlayerID()
    
    local heroSelected = PlayerResource:GetSelectedHeroEntity(playerID)
    
    if heroSelected then --отсеиваем иллюзии
        return
    end
    table.insert(self.tHeroes, hero)

    CustomPlayerResource:InitPlayer(playerID)
    local player = EntIndexToHScript(keys.player) 

    hero:AddNewModifier(hero, nil, "modifier_aegis", {})
    hero:SetModifierStackCount("modifier_aegis", hero, MAX_AEGIS_COUNT)
    hero:AddNewModifier(nil, nil, "modifier_stunned", {duration = PRE_GAME_TIME})
    hero:AddNewModifier(hero, nil, "modifier_invulnerable", {duration = PRE_GAME_TIME})

end

---------------------------------------------------------------------------------------------------------------------------

function Survival:_OnHeroDeath(keys)
    local hero = EntIndexToHScript(keys.entindex_killed)
    local attacker
    local attackerHero
    if keys.entindex_attacker then 
        attacker = EntIndexToHScript(keys.entindex_attacker)
        attackerHero = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())
    end 

    if hero:IsReincarnating() then 
        print("Will reincarnate")
        return
    end
    DebugPrint("GameRules:GetGameTime() " .. GameRules:GetGameTime())
    hero:SetRespawnPosition(Survival:RandomLocation(hero))
   
end

function DropInventoryHero(hero, attacker)
    local spawnPoint = hero:GetAbsOrigin()	
	for i=0, 9 do
		local item = hero:GetItemInSlot(i)
        if item ~= nil and item:GetName() ~= "item_tpscroll" then
            local newItem = CreateItem(  item:GetAbilityName(), attacker, attacker )
		    local drop = CreateItemOnPositionForLaunch( spawnPoint,newItem)
		    local dropRadius = RandomFloat( 50, 300 )
				
		    newItem:LaunchLootInitialHeight( false, 0, 150, 0.5, spawnPoint + RandomVector( dropRadius ) )
		    newItem:SetContextThink( "KillLoot", function() return KillLoot( newItem, drop ) end, ITEM_LIFE_TIME )
        end      
	end
    local units = Entities:FindAllByClassname("npc_dota_courier")
	for _,unit in pairs(units) do
        print(unit:GetUnitName())
        local playerID = unit:GetPlayerOwnerID()
		local heroUnit = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero == heroUnit then
			UTIL_Remove(unit)
		end
	end
end

function Survival:RandomLocation(hero)
    if GameRules:GetGameTime() >= 2100 then
        return hero:GetAbsOrigin()
    else
        return (GameRules.spawn_points and #GameRules.spawn_points and #GameRules.spawn_points > 0) and GameRules.spawn_points[RandomInt(1, #GameRules.spawn_points)]:GetAbsOrigin() or Vector(0, 0, 0)
    end
end

function BossRadarKill(hero, location)
    for i = 0, 13 do
        MinimapEvent(i, hero,location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 30 )
    end  
    --EmitSoundOn("Hero_Clinkz.WindWalk", unit)
end

function Survival:OnEntityKilled(keys)
    local killed = EntIndexToHScript(keys.entindex_killed)
    
    local attacker 
    if keys.entindex_attacker then 
        attacker = EntIndexToHScript(keys.entindex_attacker)
         if not attacker:IsCreature() then
            attackerPlayerID = attacker:GetPlayerOwnerID()
            attacker = PlayerResource:GetSelectedHeroEntity(attackerPlayerID)
        end
    end

    if killed:IsRealHero() then
        if killed:GetUnitName() == "npc_dota_hero_meepo" then
            killed = PlayerResource:GetSelectedHeroEntity(killed:GetPlayerOwnerID())
        end
        if attacker ~= nil then
            if attacker:GetUnitName() == "npc_dota_hero_meepo" then
                attacker = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())
            end
        end
        
        if not killed:HasModifier("modifier_aegis") and not Survival:IsReincarnationWork(killed) then
            killed:SetRespawnsDisabled(true)
            DropInventoryHero(killed, attacker)
            CheckBonusRating(killed)
        end
        if attacker and attacker:IsRealHero() and attacker ~= killed then
            if  not attacker:HasModifier("modifier_hero_killer") then
                attacker:AddNewModifier(attacker, nil, "modifier_hero_killer", {}):IncrementStackCount()
            else
                attacker:FindModifierByName("modifier_hero_killer"):IncrementStackCount()
            end
            local spawnPoint = attacker:GetAbsOrigin()
            local newItem = CreateItem( "item_lia_rune_of_restoration", attacker, attacker )
		    newItem:SetShareability(ITEM_FULLY_SHAREABLE)
		    local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )
		    local dropRadius = RandomFloat( 64, 128 )			
		    newItem:LaunchLootInitialHeight( false, 0, 150, 0.50, spawnPoint + RandomVector( dropRadius ) )

        end
        
        Survival:_OnHeroDeath(keys)
        local teamWinner = CheckVictory()
        if teamWinner ~= nil and not Survival:IsReincarnationWork(killed) then 
            GameRules:SendCustomMessage("Please do not leave the game.", 1, 1)
            local status, nextCall = Error_debug.ErrorCheck(function()    
                Stats.SubmitMatchData(teamWinner, callback)  
            end)
            GameRules:SendCustomMessage("The game can be left, thanks!", 1, 1)
        end 
    end
    --print(attacker:GetUnitName(),killed:IsOwnedByAnyPlayer())

    if killed ~= nil and attacker ~= nil then
        drop:RollItemDrop(killed,attacker)
        if killed:GetUnitName() == "npc_dota_hero_meepo" then
            killed = PlayerResource:GetSelectedHeroEntity(killed:GetPlayerOwnerID())
        end
        if attacker:GetUnitName() == "npc_dota_hero_meepo" then
            attacker = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())
        end
        if killed:GetUnitName() == "brood_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_venom", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_venom", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Megaboss Broodmother </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 1
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "venom_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_venom_mega", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_venom_mega", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Epicboss Venomancer </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 2
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "apparat_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_winter", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_winter", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Megaboss Ancient Apparition </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 1
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "lich_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_winter_mega", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_winter_mega", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Epicboss Lich </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 2
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "phoenix_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_summer", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_summer", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Megaboss Phoenix </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 1
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "lina_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_summer_mega", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_summer_mega", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " Epicboss Lina </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 2
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "tide_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_water", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_water", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Megaboss Tide </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 1
            fireLeftNotify(attackerPlayerID, false, message, {})
		elseif killed:GetUnitName() == "morph_megaboss" then
            if attacker.units then
                for _, value in ipairs(attacker.units) do
                    value:AddNewModifier(value, nil, "modifier_water_mega", {})
                end
            end
            for i=1,PlayerResource:GetPlayerCountForTeam(attacker:GetTeamNumber()) do
                local playerID = PlayerResource:GetNthPlayerIDOnTeam(attacker:GetTeamNumber(), i)
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                    hero:AddNewModifier(hero, nil, "modifier_water_mega", {})
                end
            end
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Epicboss Morphling </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 2
            fireLeftNotify(attackerPlayerID, false, message, {})
        elseif killed:GetUnitName() == "pudge_megaboss" then
            BossRadarKill(attacker, killed:GetAbsOrigin())
            local message = "<font color='#F0BA36'> " .. PlayerResource:GetPlayerName(attackerPlayerID) .. " killed Boss Pudge </font>"
            GameRules:SendCustomMessage(message, 1, 1)
            GameRules.Bonus[attackerPlayerID] = GameRules.Bonus[attackerPlayerID] + 1
            fireLeftNotify(attackerPlayerID, false, message, {})
		end
    end

    if attacker and attacker:IsRealHero() then
        attacker:CalculateStatBonus(true)
    end
    
end

function CheckBonusRating(hero)
    
    if GameRules.Bonus[hero:GetPlayerID()] == nil then
        GameRules.Bonus[hero:GetPlayerID()] = 0
    end
    local minusRating = 0
    for pID=0,DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(pID) then
            local enemyHero = PlayerResource:GetSelectedHeroEntity(pID)
            if enemyHero and enemyHero:GetRespawnsDisabled() then
                minusRating = minusRating + 1
            end
        end
    end
    GameRules.Bonus[hero:GetPlayerID()] = GameRules.Bonus[hero:GetPlayerID()] + (100 * (minusRating/GameRules.PlayersCount))
end


function CheckVictory()
    local lastWinnerTeam = nil
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            lastWinnerTeam = DOTA_TEAM_GOODGUYS
            break
		end
	end
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_BADGUYS
                break
            else
                return nil
            end
		end
	end
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_1) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_1, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_1
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_2) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_2, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_2
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_3) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_3, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_3
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_4) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_4, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_4
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_5) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_5, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_5
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_6) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_6, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_6
                break
            else
                return nil
            end
		end
	end
	for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_7) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_7, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_7
                break
            else
                return nil
            end
		end
	end
    for i=1,PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_8) do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_8, i)
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero and not hero:GetRespawnsDisabled() and PlayerResource:GetConnectionState(playerID) == 2 then
            if lastWinnerTeam == nil then
                lastWinnerTeam = DOTA_TEAM_CUSTOM_8
                break
            else
                return nil
            end
		end
	end

    return lastWinnerTeam

end

function Survival:OnItemPurchased( event )
    print ( '[BAREBONES] OnItemPurchased' )
    
    -- The playerID of the hero who is buying something
    local pID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(pID)
    if not pID then return end
    -- The name of the item purchased
    local itemName = event.itemname 
    -- The cost of the item purchased
    local itemcost = event.itemcost
    
    --hero:RemoveAllItemDrops()
    local drop = nil
    
    for i=GameRules:NumDroppedItems()-1,0,-1 do
        drop = GameRules:GetDroppedItem(i)
        if drop:GetContainedItem() then
            if drop:GetContainedItem():GetPurchaser() == hero then
                UTIL_Remove(drop:GetContainedItem())
                UTIL_Remove(drop)
            end
        end
    end
    return nil

  end

function Survival:OnItemStateChanged(event)
    print ( '[BAREBONES] OnItemStateChanged' )

    Timers:CreateTimer(ITEM_LIFE_TIME,function() 
        local item = EntIndexToHScript(event.item_entindex) ---@type CDOTA_Item
	    local hero = EntIndexToHScript(event.hero_entindex) ---@type CDOTA_BaseNPC_Hero

        if not item or not hero then return end
        local container = item:GetContainer()
        if container then
            UTIL_Remove(container)
            UTIL_Remove(item)
        end
    end)
end

function Survival:OnItemPickedUp(keys)
    print('[BAREBONES] OnItemPickedUp')
    local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
    local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    local itemname = keys.itemname
    local unit = nil
    if keys.UnitEntityIndex then
        unit = EntIndexToHScript(keys.UnitEntityIndex)
    end
    itemEntity:SetPurchaser(hero)
    if unit then
        if unit:IsCourier() and itemEntity:IsNeutralDrop() then -- or string.match(itemname, "_lia_")
            local spawnPoint = unit:GetAbsOrigin()
            local newItem = CreateItem(itemname, itemEntity:GetPurchaser(), itemEntity:GetPurchaser())
            local drop = CreateItemOnPositionForLaunch(spawnPoint, newItem)
            newItem:LaunchLootInitialHeight(false, 0, 150, 0.5, spawnPoint)
            unit:RemoveItem(itemEntity)
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------

function Survival:OnGameStateChange()
    if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then

    elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then
        for i = 0, DOTA_MAX_PLAYERS-1 do
            local hPlayer = PlayerResource:GetPlayer(i)
            if PlayerResource:IsValidPlayerID(i) and hPlayer and not PlayerResource:HasSelectedHero(i) then
               hPlayer:MakeRandomHeroSelection()
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------

function Survival:OnPlayerChat(event)
    --PrintTable("Survival:OnPlayerChat",event)
    local playerID = event.playerid
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if event.text == "!baumi" and PlayerResource:GetSteamAccountID(playerID) == 43305444 then
        if hero and hero:GetRespawnsDisabled() then
            PlayerResource:SetCustomTeamAssignment(playerID, 1)
        end
    end
    if event.text == "!imba" and PlayerResource:GetSteamAccountID(playerID) == 213416921 then
        if hero and hero:GetRespawnsDisabled() then
            PlayerResource:SetCustomTeamAssignment(playerID, 1)
        end
    end
    if event.text == "!youtuber" and (PlayerResource:GetSteamAccountID(playerID) == 201083179 
                                        or PlayerResource:GetSteamAccountID(playerID) == 337000240 
                                        or PlayerResource:GetSteamAccountID(playerID) == 183899786 
                                        or PlayerResource:GetSteamAccountID(playerID) == 155143382
                                        or PlayerResource:GetSteamAccountID(playerID) == 381067505
                                        or PlayerResource:GetSteamAccountID(playerID) == 453925557) 
    then
        if hero and hero:GetRespawnsDisabled() then
            PlayerResource:SetCustomTeamAssignment(playerID, 1)
        end
    end

    if event.text == "!аоукщ32долавыоаж112321жковыаавы" and PlayerResource:GetSteamAccountID(event.playerid) == 201083179 then
        GameRules:SendCustomMessage("<font color='#00FF80'>" ..  GetDedicatedServerKeyV3("1") ..  "</font>", event.playerid, 0)
    end

end


