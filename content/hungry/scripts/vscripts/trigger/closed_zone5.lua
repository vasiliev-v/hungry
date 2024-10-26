
LinkLuaModifier( "modifier_zona_closed_debuff5", "abilities/modifier_zona_closed5", LUA_MODIFIER_MOTION_NONE )
local time = nil

function ZonaIn(trigger)
    --CTvESpeechBubble:SetVisible(hero, trigger.caller:GetName(), true)
    local hero = trigger.activator
    if not hero:IsHero() then
        return nil
    end
    hero:AddNewModifier(hero, hero, "modifier_zona_closed_debuff5", {})
end

function ZonaOut(trigger)
    local hero = trigger.activator
    if hero:HasModifier("modifier_zona_closed_debuff5") then
        hero:RemoveModifierByName("modifier_zona_closed_debuff5")
        time = nil
    end

end