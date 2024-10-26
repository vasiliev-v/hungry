LinkLuaModifier( "modifier_zona_venom", "abilities/modifier_zona_venom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_zona_venom_debuff", "abilities/modifier_zona_venom", LUA_MODIFIER_MOTION_NONE )

function ZonaIn(trigger)
    --CTvESpeechBubble:SetVisible(hero, trigger.caller:GetName(), true)
    local hero = trigger.activator
    if not hero:IsRealHero() then
        return nil
    end

    if not hero:HasModifier("modifier_zona_venom_debuff") and not hero:HasModifier("modifier_venom") then
        hero:AddNewModifier(hero, hero, "modifier_zona_venom_debuff", {Duration = 2})
        SendErrorMessage(trigger.activator:GetPlayerOwnerID(), "#error_you_venom2")
       -- fireLeftNotify(trigger.activator:GetPlayerOwnerID(), true, "#error_you_venom", {})
        local point = Entities:FindAllByName("brood_megaboss")
        MinimapEvent(trigger.activator:GetTeamNumber(), trigger.activator, point[1]:GetAbsOrigin().x, point[1]:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 30 )
        
    end

end

function ZonaOut(trigger)

    local hero = trigger.activator
 --   if hero:HasItemInInventory("item_lia_health_stone_potion") and hero:HasModifier("modifier_zona_venom_debuff") then
 --       hero:RemoveModifierByName("modifier_zona_venom_debuff")
 --   end
    
end