function ZonaIn(trigger)
    --CTvESpeechBubble:SetVisible(trigger.activator, trigger.caller:GetName(), true)
    local playerID = trigger.activator:GetPlayerID()
    PlayerResource:SetCustomTeamAssignment(playerID, CustomPlayerResource.data[playerID].team )
    trigger.activator:SetTeam(CustomPlayerResource.data[playerID].team )
end

function ZonaOut(trigger)
    --CTvESpeechBubble:SetVisible(trigger.activator, trigger.caller:GetName(), false)
    local playerID = trigger.activator:GetPlayerID()
    PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
    trigger.activator:SetTeam(DOTA_TEAM_GOODGUYS)
end