LinkLuaModifier( "modifier_zona_winter", "abilities/modifier_zona_winter", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_zona_winter_debuff", "abilities/modifier_zona_winter", LUA_MODIFIER_MOTION_NONE )

function ZonaIn(trigger)
    --CTvESpeechBubble:SetVisible(hero, trigger.caller:GetName(), true)
    local hero = trigger.activator
    if not hero:IsRealHero() then
        return nil
    end

    if not hero:HasModifier("modifier_zona_winter_debuff") and not hero:HasModifier("modifier_winter")  then
        hero:AddNewModifier(hero, hero, "modifier_zona_winter_debuff", {Duration = 2})
        SendErrorMessage(trigger.activator:GetPlayerOwnerID(), "#error_you_winter2")
      --  fireLeftNotify(trigger.activator:GetPlayerOwnerID(), true, "#error_you_winter", {})
        local point = Entities:FindAllByName("apparat_megaboss")
        MinimapEvent(trigger.activator:GetTeamNumber(), trigger.activator, point[1]:GetAbsOrigin().x, point[1]:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 30 )
        
    end

end

function ZonaOut(trigger)
    local hero = trigger.activator
   -- if hero:HasItemInInventory("item_lia_health_stone_potion") and hero:HasModifier("modifier_zona_winter_debuff") then
  --      hero:RemoveModifierByName("modifier_zona_winter_debuff")
  --  end
end