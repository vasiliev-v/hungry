LinkLuaModifier( "modifier_test_lia", LUA_MODIFIER_MOTION_NONE )
require('top')

Stats = Stats or {}
local dedicatedServerKey = GetDedicatedServerKeyV3("1")
local checkResult = {}
local winnerID = {}
function Stats.SubmitMatchData(winner,callback)
	if GameRules.startTime == nil then
		GameRules.startTime = 1
	end
	PedistalEnd()
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then 
			GameRules:SetGameWinner(winner)
			SetResourceValues()
			return 
		end
	end
	local data = {}
	
	for pID=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(pID) then
			if GameRules.scores[pID] == nil then
				GameRules.scores[pID] = {x1 = 0, x2 = 0, x3 = 0, x5 = 0 }
				GameRules.scores[pID].x1 = 0
				GameRules.scores[pID].x2 = 0
				GameRules.scores[pID].x3 = 0
				GameRules.scores[pID].x5 = 0
			end
			DebugPrint("pID " .. pID )
			if GameRules.Bonus[pID] == nil then
				GameRules.Bonus[pID] = 0
			end
			if checkResult[pID] == nil then
				checkResult[pID] = 1
			else
				goto continue
			end
		end
	end
	if GameRules.BonusPercent  >  0.77 then
		GameRules.BonusPercent = 0.77
	end

	if GameRules.PlayersCount >= MIN_RATING_PLAYER then
		for pID=0,DOTA_MAX_TEAM_PLAYERS do
			if PlayerResource:IsValidPlayerID(pID) then
				data.MatchID = tostring(GameRules:Script_GetMatchID() or 0)
				data.Gem = 0
				data.Team = "33"
				if string.find(GetMapName(),"1x10") then
					data.Team = "1"
				elseif string.find(GetMapName(),"2x20") then
					data.Team = "2"
				elseif string.find(GetMapName(),"3x21") then
					data.Team = "3"
				elseif string.find(GetMapName(),"5x21") then
					data.Team = "5"
				end
				
				--data.duration = GameRules:GetGameTime() - GameRules.startTime
				data.Map = GetMapName()
				local hero = PlayerResource:GetSelectedHeroEntity(pID)
				data.SteamID = tostring(PlayerResource:GetSteamID(pID) or 0)
				data.Time = tostring(tonumber(GameRules:GetGameTime() - GameRules.startTime)/60 or 0)
				data.GoldGained = tostring(PlayerResource:GetTotalEarnedGold(pID)) 
				data.GoldGiven = tostring(PlayerResource:GetTotalGoldSpent(pID))   
				data.LumberGained = tostring(PlayerResource:GetGoldSpentOnItems(pID))   
				data.LumberGiven =  tostring(PlayerResource:GetGoldSpentOnConsumables(pID))    
				
				data.Kill = tostring(PlayerResource:GetKills(pID) or 0)
				data.Death = tostring(PlayerResource:GetDeaths(pID) or 0)
				
				data.Nick = tostring(PlayerResource:GetPlayerName(pID))
				data.GPS = tostring(PlayerResource:GetGoldPerMin(pID)) 
				data.LPS =  tostring(PlayerResource:GetXPPerMin(pID))
				
				data.GetScoreBonusGoldGained = tostring(GameRules.scores[pID].x1) or "0"
				data.GetScoreBonusGoldGiven = tostring(GameRules.scores[pID].x2) or "0"
				data.GetScoreBonusLumberGained = tostring(GameRules.scores[pID].x3) or "0"
				data.GetScoreBonusLumberGiven = tostring(GameRules.scores[pID].x4) or "0"
				data.GetScoreBonus = tostring(GameRules.Bonus[pID])
				if hero then
					data.Type = tostring(hero:GetUnitName() or "null")  -- tostring(DOTAGameManager:GetHeroIDByName(hero:GetUnitName()) or "null")
					data.GetScoreBonusRank = tostring(hero:GetLevel()) 
					if PlayerResource:GetTeam(pID) == winner then
						data.Score = tostring(50 + math.floor(GameRules.Bonus[pID] - PlayerResource:GetDeaths(pID)*2 + PlayerResource:GetKills(pID)*2))
						winnerID[#winnerID+1] = pID
					elseif PlayerResource:GetTeam(pID) ~= winner then
						data.Score = tostring(-50 + math.floor(GameRules.Bonus[pID] - PlayerResource:GetDeaths(pID)*5))
					end 
					if (GameRules.scores[pID].x1 + GameRules.scores[pID].x2 + GameRules.scores[pID].x3 + GameRules.scores[pID].x5) == 0 and tonumber(data.Score) < 0 then
						data.Score = "0"
						data.Type = "NEWBIE"
					end
					if tonumber(data.Score) >= 0 then
						data.Score = tostring(math.floor(tonumber(data.Score) *  (1 + GameRules.BonusPercent)))
						data.Gem = tonumber(data.Score) + 1
					else 
						data.Score = tostring(math.floor(tonumber(data.Score) *  (1 - GameRules.BonusPercent)))
						data.Gem = tonumber(1)
					end
				else
					data.Type = "HERO KICK"
					data.Score = tostring(-15)
					data.Team = tostring(2)
				end
				data.Key = dedicatedServerKey
				data.BonusPercent = tostring(GameRules.BonusPercent)
				local text = tostring(PlayerResource:GetPlayerName(pID)) .. " got " .. data.Score
				GameRules.Score[pID] = data.Score
				CustomNetTables:SetTableValue("scorestats", tostring(pID), { x1 = tostring(GameRules.scores[pID].x1), 
																	x2 = tostring(GameRules.scores[pID].x2), 
																	x3 = tostring(GameRules.scores[pID].x3),
																	x5 = tostring(GameRules.scores[pID].x5),
																	playerScoreEnd = tostring(data.Score)})
				GameRules:SendCustomMessage(text, 1, 1)
				Stats.SendData(data,callback)
				if data.Gem > 0 then
					data.EndGame = 1
					Shop.GetGem(data)
				end
			end 
		end
	end
	::continue::
	Timers:CreateTimer(5, function() 
		SetResourceValues()
		GameRules:SetGameWinner(winner)
	end)
end

function SetResourceValues()
    for pID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayer(pID) then
            if GameRules.startTime == nil then
                GameRules.startTime = 1
            end
            CustomNetTables:SetTableValue("resources",
                tostring(pID) .. "_resource_stats", {
                    GGPM = PlayerResource:GetGoldPerMin(pID),
                    GXPM = PlayerResource:GetXPPerMin(pID),
                    GTEG = PlayerResource:GetTotalEarnedGold(pID),
                    GTGS = PlayerResource:GetTotalGoldSpent(pID),
                    GGSOI = PlayerResource:GetGoldSpentOnItems(pID),
                    GGSOC = PlayerResource:GetGoldSpentOnConsumables(pID),
                    PlayerChangeScore = GameRules.Score[pID]
                })
        end
    end
end

function Stats.SendData(data,callback)
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server)
	local encData = json.encode(data)
	DebugPrint("***********************************************")
	DebugPrint(GameRules.server)
	DebugPrint(encData)
	DebugPrint("***********************************************")
	req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicatedServerKey)
	req:SetHTTPRequestRawPostBody("application/json", encData)
	req:Send(function(res)
		DebugPrint("***********************************************")
		DebugPrint(res.Body)
		DebugPrint("Response code: " .. res.StatusCode)
		DebugPrint("***********************************************")
		if res.StatusCode ~= 200 then
			GameRules:SendCustomMessage("Error connecting", 1, 1)
			DebugPrint("Error connecting")
		end
		
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
		
	end)
end

function Stats.RequestData(obj, pId, callback)
	DebugPrint("***********************************************Rating")
	GameRules.scores[pId] = {x1 = 0, x2 = 0, x3 = 0, x5 = 0}
	GameRules.scores[pId].x1 = 0
	GameRules.scores[pId].x2 = 0
	GameRules.scores[pId].x3 = 0
	GameRules.scores[pId].x5 = 0
	CustomNetTables:SetTableValue("scorestats", tostring(pId), { x1 = tostring(GameRules.scores[pId].x1), 
																	x2 = tostring(GameRules.scores[pId].x2), 
																	x3 = tostring(GameRules.scores[pId].x3),
																	x4 = tostring(GameRules.scores[pId].x5)})	
	DebugPrint(obj.steamID)
	DebugPrint("***********************************************")
	DebugPrintTable(obj)

	for id=1,#obj do
		if obj[id].team == "1" then
			GameRules.scores[pId].x1 = obj[id].score
		else
			GameRules.scores[pId].x2 = GameRules.scores[pId].x2 + obj[id].score
		end
	end

	CustomNetTables:SetTableValue("scorestats", tostring(pId), { x1 = tostring(GameRules.scores[pId].x1), 
																x2 = tostring(GameRules.scores[pId].x2)})	
	DebugPrint("rating done done done")
	return obj
end

function Stats.RequestDataTop10(idTop, callback)
	local req = CreateHTTPRequestScriptVM("GET",GameRules.server .. "all/" .. idTop)
	req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicatedServerKey)
	DebugPrint("***********************************************")
	req:Send(function(res)
		if res.StatusCode ~= 200 then
			DebugPrint("Connection failed! Code: ".. res.StatusCode)
			DebugPrint(res.Body)
			return -1
		end
		
		local obj,pos,err = json.decode(res.Body)
		--DeepPrintTable(obj)
		DebugPrint("***********************************************")
		top:OnLoadTop(obj,idTop)
		---CustomNetTables:SetTableValue("stats", tostring( pId ), { steamID = obj.steamID, score = obj.score })
		return obj
		
	end)
end


function PedistalEnd()
    Timers:CreateTimer(1,function()
		local vecFirstPlace = Entities:FindByName(nil, "1_place"):GetAbsOrigin()
		local vecCamera = vecFirstPlace-Vector(-470,370,0)

		ChangeWorldBounds(vecCamera,vecCamera)
		SetCameraToPosForPlayer(-1,vecCamera)

		for i = 1, #winnerID do
			HeroToPedestal(PlayerResource:GetSelectedHeroEntity( winnerID[i] ), i)
		end
		
    end)
end

function HeroToPedestal(hero,place)
    if not hero then
        return 
    end

    local vecOrigin = Entities:FindByName(nil, tostring(place).."_place"):GetAbsOrigin()
    local forward = { 
        Vector(2,-1,0), 
        Vector(5,-1,0), 
        Vector(1,-1,0) 
    }

    if not hero:IsAlive() then
        hero:RespawnHero(false,false)
    end

    hero:Purge(true, true, false, true, true)

    hero:RemoveModifierByName("modifier_item_sphere_target")
    
    local fire_gloves = GetItemInInventory(hero,"item_lia_fire_gloves") or GetItemInInventory(hero,"item_lia_fire_gloves_2")
    if fire_gloves and fire_gloves:GetToggleState() then 
        fire_gloves:ToggleAbility()
    end 

    hero:SetAbsOrigin(vecOrigin)
    hero:SetForwardVector(forward[place])
    hero:Interrupt()
    hero:StartGesture(ACT_DOTA_IDLE)
    hero:StartGesture(ACT_DOTA_VICTORY)
    --DebugDrawLine(self.tHeroes[2]:GetAbsOrigin(), self.tHeroes[2]:GetAbsOrigin()+self.tHeroes[2]:GetForwardVector()*100, 100, 100, 100, true, 100)
end