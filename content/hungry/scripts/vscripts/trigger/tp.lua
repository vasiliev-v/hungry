function Hide_Touch(trigger)
    --CTvESpeechBubble:SetVisible(trigger.activator, trigger.caller:GetName(), true)
	if trigger.activator:IsAngel() then
		FindClearSpaceForUnit(trigger.activator, RandomAngelLocation(), true)
	end
end

function RandomAngelLocation()
        return (GameRules.angel_spawn_points and #GameRules.angel_spawn_points and
    #GameRules.angel_spawn_points > 0) and
    GameRules.angel_spawn_points[RandomInt(1,
    #GameRules.angel_spawn_points)]:GetAbsOrigin() or
    Vector(0, 0, 0)
end