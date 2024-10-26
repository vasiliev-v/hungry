require 'lib/timer'

function TeleportHero(hero, point)
	hero:SetAbsOrigin( point )
	FindClearSpaceForUnit( hero, point, true )
	hero:Stop()

	PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)		

	Timer(0.3, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)	
		return nil
	end )		
end

function GetTotalPr(playerid)
    local streak = PlayerResource:GetStreak(playerid)
    local gold_per_streak = 1000;
    local gold_per_level  = 100;
    local minute = GameRules:GetGameTime() / 60
    if minute < 10 then
        gold_per_streak = 210 + (RandomInt(-1, 1)) * RandomInt(0, 100)
    elseif  minute < 20 then
        gold_per_streak = 300 + (RandomInt(-1, 1)) * RandomInt(0, 100)
    elseif  minute < 30 then
        gold_per_streak = 1000 + (RandomInt(-1, 1)) * RandomInt(0, 110)
    elseif  minute < 50 then
        gold_per_streak = 3000 + (RandomInt(-1, 1)) * RandomInt(0, 220)
    elseif  minute > 50 then
        gold_per_streak = 5000 + (RandomInt(-1, 1)) * RandomInt(0, 250)
    end

    local total_gold = gold_per_streak*streak
    return total_gold
end

function GetAllPlayers(teamNumber)
	local players = {}

	if teamNumber ~= nil then
		for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(i) then
				local hero = PlayerResource:GetSelectedHeroEntity(i)
				if hero and not hero:HasOwnerAbandoned() then	
					if (hero:GetTeamNumber() == teamNumber) then
						table.insert(players, hero)
					end
				end
			end
		end
	else
		for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(i) then
				local hero = PlayerResource:GetSelectedHeroEntity(i)
				if hero and not hero:HasOwnerAbandoned() then	
					table.insert(players, hero)
				end
			end
		end	
	end
	
	return players
end
