
------------------------------------------------------------------------------------------------
if Survival == nil then
    print("Survival")
    
    _G.Survival = class({})
end

------------------------------------------------------------------------------------------------

require('survival/events')
require('survival/utils')
require('creepSpawner')
------------------------------------------------------------------------------------------------

LinkLuaModifier( "modifier_16_wave_debuff", "survival/modifier_16_wave_debuff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_17_wave_debuff", "survival/modifier_17_wave_debuff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_18_wave_debuff", "survival/modifier_18_wave_debuff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_19_wave_debuff", "survival/modifier_19_wave_debuff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_megaboss_three_stats", "units/modifier_megaboss_three_stats.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_ultimate_upgrade", "items/modifiers/modifier_ultimate_upgrade.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------------------

function Survival:InitSurvival()
    self.tHeroes = {}
    self.hHealer = Entities:FindByName(nil,"lia_trigger_healer")
    GameRules:SetHideKillMessageHeaders(true)
    GameRules:SetTreeRegrowTime(60)
    GameRules:SetHeroRespawnEnabled(true)
    SendToServerConsole("dota_max_physical_items_purchase_limit 9999")
    ListenToGameEvent('entity_killed', Dynamic_Wrap(Survival, 'OnEntityKilled'), self)
    ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(Survival, 'OnPlayerPickHero'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(Survival, 'OnPlayerChat'), self)
   -- ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(Survival, 'OnItemPurchased'), self)
    ListenToGameEvent('dota_hero_inventory_item_change', Dynamic_Wrap(Survival, 'OnItemStateChanged'), self)
    ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(Survival, 'OnItemPickedUp'), self)
    

    for i = 0, DOTA_MAX_PLAYERS-1 do
        if PlayerResource:IsValidTeamPlayerID(i) then
            if PlayerResource:IsValidPlayerID(i) then
                local steam = tostring(PlayerResource:GetSteamID(i))
                Shop.RequestDonate(i, steam, callback)
            end
            CustomPlayerResource:InitPlayer(i)
 
        end
    end
    Stats.RequestDataTop10("5", callback)
    Stats.RequestDataTop10("6", callback)
    StartReklama()
    creepSpawner:Progress() 
end


function Survival:ItemAddFilter(filterTable)
    --DeepPrint(filterTable)
    local item = EntIndexToHScript(filterTable.item_entindex_const)
    local hero = EntIndexToHScript(filterTable.inventory_parent_entindex_const)
    local itemName = item:GetAbilityName()
    if itemName == "item_lia_knight_shield" or itemName == "item_lia_knight_cuirass" then
        if hero:HasItemInInventory("item_lia_knight_shield",false) or hero:HasItemInInventory("item_lia_knight_cuirass",false) then
            for i=6,9 do
                if hero:GetItemInSlot(i) == nil then 
                    filterTable.suggested_slot = i
                    SendErrorMessage(hero:GetPlayerID(), "#lia_hud_error_cant_have_two_items_retdmg")
                    return true
                end
            end
        end
    end

    return true
end

function Survival:IsReincarnationWork(hero)
    
    local bSkeletonKingReincarnationWork = false
    if hero:HasAbility("skeleton_king_reincarnation") then
         local ability = hero:FindAbilityByName("skeleton_king_reincarnation")
         if ability:GetLevel() > 0 then
           if ability:GetCooldownTimeRemaining() == ability:GetEffectiveCooldown(ability:GetLevel()-1) then
              bSkeletonKingReincarnationWork = true 
           end
       end
    end

    return bSkeletonKingReincarnationWork

end

function Survival:RefreshAbilityAndItem(hero, exceptions)
    if not hero or hero:IsNull() then return end
    if not exceptions then
        exceptions = {}
    end

    for i = 0, DOTA_MAX_ABILITIES - 1 do
        local ability = hero:GetAbilityByIndex(i)
        if ability and (not exceptions[ability:GetAbilityName()]) then
            ability:RefreshCharges()
            if ability._RefreshCharges then
                ability:_RefreshCharges() -- also refresh custom charges
            end
            ability:EndCooldown()
        end
    end

    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_MAX do
        local item = hero:GetItemInSlot(i)
        if item then
            local purchaser = item:GetPurchaser()
            if not purchaser or purchaser:GetPlayerOwnerID() == hero:GetPlayerOwnerID()  then
                item:EndCooldown()
            end
        end
    end
end