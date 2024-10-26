
LinkLuaModifier( "modifier_zona_closed_debuff4", "abilities/modifier_zona_closed4", LUA_MODIFIER_MOTION_NONE )
local time = nil

function ZonaIn(trigger)
    --CTvESpeechBubble:SetVisible(hero, trigger.caller:GetName(), true)
    local hero = trigger.activator
    if not hero:IsHero() then
        return nil
    end

        hero:AddNewModifier(hero, hero, "modifier_zona_closed_debuff4", {})
        MinimapEvent(hero:GetTeamNumber(), hero, 0, 0, DOTA_MINIMAP_EVENT_HINT_LOCATION, 10 )
        time = 60
        Timers:CreateTimer(time, function() 
            if time ~= nil then
                MinimapEvent(trigger.activator:GetTeamNumber(), trigger.activator, 0, 0, DOTA_MINIMAP_EVENT_HINT_LOCATION, 10 )
                SendErrorMessage(trigger.activator:GetPlayerOwnerID(), "#error_you_died2")
            --    fireLeftNotify(trigger.activator:GetPlayerOwnerID(), true, "#error_you_died", {})
            end
            
            return time 
        end)

end

function ZonaOut(trigger)
    local hero = trigger.activator
    if hero:HasModifier("modifier_zona_closed_debuff4") then
        hero:RemoveModifierByName("modifier_zona_closed_debuff4")
        time = nil
    end

end