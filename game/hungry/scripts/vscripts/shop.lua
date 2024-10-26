if Shop == nil then
	DebugPrint( 'top' )
	_G.Shop = class({})
end
local dedicatedServerKey = GetDedicatedServerKeyV3("1")
local MatchID = tostring(GameRules:Script_GetMatchID() or 0)
local lastSpray = {}
local lastSounds = {}

 			

function Shop.RequestDonate(pID, steam, callback)
 	local steam = tostring(PlayerResource:GetSteamID(tonumber(pID)))
	local parts = {}
	local req = CreateHTTPRequestScriptVM("GET",GameRules.server .. "vip/" .. steam)
	if not req then
		return
	end
	req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicatedServerKey)
	DebugPrint("RequestVip ***********************************************" .. GameRules.server )
	req:Send(function(res)
		if res.StatusCode ~= 200 then
			DebugPrint("Connection failed! Code: ".. res.StatusCode)
			DebugPrint(res.Body)
			return -1
		end
		
		local obj,pos,err = json.decode(res.Body)
		DeepPrintTable(obj)
		DebugPrint("***********************************************")

		Shop.RequestVip(obj[1], pID, steam, callback)
		Shop.RequestSounds(obj[2], pID, steam, callback)
		Shop.RequestSkin(obj[3], pID, steam, callback)
		Shop.RequestPets(obj[4], pID, steam, callback)
		Shop.RequestEvent(obj[5], pID, steam, callback)
		Shop.RequestVipDefaults(obj[6], pID, steam, callback)
		Shop.RequestSkinDefaults(obj[7], pID, steam, callback)
		Shop.RequestPetsDefaults(obj[8], pID, steam, callback)
		Shop.RequestBonus(obj[9], pID, steam, callback)
		Shop.RequestBPBonus(obj[10], pID, steam, callback)
		Shop.RequestBonusTroll(obj[11], pID, steam, callback)
		Shop.RequestCoint(obj[12], pID, steam, callback)
		Shop.RequestChests(obj[13], pID, steam, callback)
		Shop.RequestXP(obj[14], pID, steam, callback)
		Shop.RequestBan(obj[15], pID, steam, callback)
		Shop.RequestRewards(obj[16], pID, steam, callback)
		Shop.RequestBPplayer(obj[17], pID, steam, callback)
		Stats.RequestData(obj[18], pID)
	
		return obj
	end)
end

function Shop.RequestVip(obj, pID, steam, callback)
	local parts = {}
	DebugPrint("RequestVip ***********************************************" .. GameRules.server )
	DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["5"]["0"] = PlayerResource:GetSteamAccountID(pID)
	PoolTable["5"]["1"] = PlayerResource:GetSteamID(pID)
	for id = 1, 85 do
		if GameRules:IsCheatMode() then 
			PoolTable["1"][id] = tostring(id)
			parts[id] = "normal"
		else
			parts[id] = "nill"
		end
		
	end
	CustomNetTables:SetTableValue("Particles_Tabel",tostring(pID),parts)
	for id=1,#obj do
		parts[obj[id].num] = "normal"
		CustomNetTables:SetTableValue("Particles_Tabel",tostring(pID),parts)
		PoolTable["1"][tostring(obj[id].num+100)] = tostring(obj[id].num+100)
		
		if tonumber(obj[id].num) == 11 then
			PoolTable["1"]["601"] = "601"
			PoolTable["1"]["620"] = "620"
			

			Timers:CreateTimer(120, function()
				local msg = "<font color='#00FFFF '>"  .. tostring(PlayerResource:GetPlayerName(pID)) .. " thank you for your support!" .. "</font>"
				--fireLeftNotify(pID, false, msg, {})
			end);
		end	
	end
	for id = 1, 200 do
		if GameRules:IsCheatMode() then 
			PoolTable["1"][id] = tostring(id)
		end		
	end
	for id = 600, 900 do
		if GameRules:IsCheatMode() then 
			PoolTable["1"][id] = tostring(id)
		end		
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj

end

function Shop.RequestSkin(obj, pID, steam, callback)
	
	DebugPrint("RequestSkin ***********************************************" .. GameRules.server )
	DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))

	for id=1,#obj do
		PoolTable["1"][tostring(obj[id].num)] = tostring(obj[id].num)
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end

function Shop.RequestEvent(obj, pID, steam, callback)
	DebugPrint("***********RequestEvent***********************")
	--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["5"]["2"] = 0
	if #obj > 0 then
		if obj[1].srok ~= nil and #obj == 1 then
			PoolTable["5"]["2"] = obj[1].srok
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end

function Shop.GetVip(data,callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
	data.MatchID = MatchID
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server)
	if not req then
		return
	end
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
			DebugPrint("Error connecting GET VIP")
		end
		
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
		if data.TypeDonate == nil then
			Shop.RequestDonate(tonumber(data.PlayerID), data.SteamID, callback)
		end
	end)
end	


function Shop.RequestVipDefaults(obj, pID, steam, callback)
	DebugPrint("***************RequestVipDefaults********************")
	DeepPrintTable(obj)
	DebugPrint("RequestVipDefaults ***********************************************")
	if #obj > 0 then
		if obj[1].num ~= nil then
			GameRules.PartDefaults[pID] = obj[1].num
		end
	end
	return obj
end

function Shop.RequestSkinDefaults(obj, pID, steam, callback)
	DebugPrint("***********RequestSkinDefaults**********************")
	DeepPrintTable(obj)
	DebugPrint("RequestSkinDefaults ***********************************************")
	if #obj > 0 then
		if obj[1].num ~= nil then
			GameRules.SkinDefaults[pID] = tonumber(obj[1].num)
		end
	end
	return obj
end

function Shop.RequestPetsDefaults(obj, pID, steam, callback)
	DebugPrint("*************RequestPetsDefaults****************")
	DeepPrintTable(obj)
	DebugPrint("RequestPetsDefaults ***********************************************")
	if #obj > 0 then
		if obj[1].num ~= nil then
			GameRules.PetsDefaults[pID] = obj[1].num
		end
	end
	return obj
end

function Shop.RequestBonus(obj, pID, steam, callback)
	DebugPrint("**************RequestBonus********************")
	--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["3"]["0"] = "0"
	PoolTable["3"]["1"] = "none"
	if #obj > 0 then
		if obj[1].srok ~= nil then
			GameRules.BonusPercent = GameRules.BonusPercent  + 0.1
			PoolTable["3"]["0"] = 10
			PoolTable["3"]["1"] = obj[1].srok
			Timers:CreateTimer(60, function()
				local msg = "<font color='#00FFFF '>"  .. tostring(PlayerResource:GetPlayerName(pID)) .. " thanks for the rating bonus!" .. "</font>"
			--	fireLeftNotify(pID, false, msg, {})
			end);
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end
function Shop.RequestBPBonus(obj, pID, steam, callback)
	DebugPrint("**************RequestBPBonus********************")
	--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["10"]["0"] = "none"
	if #obj > 0 then
		if obj[1].srok ~= nil then
			PoolTable["10"]["0"] = obj[1].srok
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end
function Shop.RequestBonusTroll(obj, pID, steam, callback)
	DebugPrint("************RequestBonusTroll****************")
	local tmp = 0
	--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	DebugPrintTable(CustomNetTables:GetTableValue("Shop", tostring(pID)))
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["2"]["0"] = "0"
	PoolTable["2"]["1"] = "none"
	if #obj > 0 then
		if obj[1].chance ~= nil then
			PoolTable["2"]["0"] = obj[1].chance
			PoolTable["2"]["1"] = obj[1].srok
			local roll_chance = RandomFloat(0, 100)
			local msg = "<font color='#00FFFF '>"  .. tostring(PlayerResource:GetPlayerName(pID)) .. " thank you for your support! Your chance is increased by " .. obj[1].chance .. "%.".. "</font>"
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)					
end

function Shop.RequestPets(obj, pID, steam, callback)
	local parts = {}
	DebugPrint("**************RequestPets******************")
		--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	for id = 0, 66 do
		if GameRules:IsCheatMode() then 
			parts[id] = "normal"
		else
			parts[id] = "nill"
		end
	end
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	CustomNetTables:SetTableValue("Pets_Tabel",tostring(pID),parts)
	--DebugPrint("dateos " ..  GetSystemDate())
	
	for id=1,#obj do
		parts[obj[id].num] = "normal"
		PoolTable["1"][tostring(obj[id].num)] = tostring(obj[id].num)
		CustomNetTables:SetTableValue("Pets_Tabel",tostring(pID),parts)
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end	

function Shop.RequestCoint(obj, pID, steam, callback)
	DebugPrint("*****************RequestCoint*******************")
		--DeepPrintTable(obj)
	DebugPrint("***********************************************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["0"]["0"] = "0"
	PoolTable["0"]["1"] = "0"
	if #obj > 0 then
		if obj[1].gold ~= nil then
			if obj[1].gem ~= nil then 
				PoolTable["0"]["0"] = tostring(obj[1].gold)
				PoolTable["0"]["1"] = tostring(obj[1].gem)
			end
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	return obj
end


function Shop:BuyShopItem(table, callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
    local steam = tostring(PlayerResource:GetSteamID(table.PlayerID))
    table.SteamID = steam
    table.MatchID = MatchID
	table.id = tostring(table.PlayerID)
	local cost = nil
	for _, reward in pairs(Shop.DonateList) do
		if reward[1] == table.Num and reward[2] == table.TypeDonate then
		    cost = reward[3]
		end
	end
	
	if cost == nil then
		return
	else
		table.Coint = cost
	end

	local req = CreateHTTPRequestScriptVM("POST",GameRules.server .. "buy/")
	local encData = json.encode(table)
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
			GameRules:SendCustomMessage("Error during purchase. Code: " .. res.StatusCode, 1, 1)
			DebugPrint("Error during purchase.")
		end
		Shop.RequestDonate(tonumber(table.id), steam, callback)
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
	end)
end

function Shop:BuyOpenChests(table, callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
    local steam = tostring(PlayerResource:GetSteamID(table.PlayerID))
    table.SteamID = steam
    table.MatchID = MatchID
	table.id = tostring(table.PlayerID)
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server .. "buy/")
	local encData = json.encode(table)
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
			GameRules:SendCustomMessage("Error during purchase. Code: " .. res.StatusCode, 1, 1)
			DebugPrint("Error during purchase.")
		end
		Shop.RequestDonate(tonumber(table.id), steam, callback)
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
	end)
end

function Shop.GetGem(data,callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
    data.MatchID = MatchID
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server .. "coint/")
	if not req then
		return
	end
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
			DebugPrint("Error connecting GET GEM")
		end
		if data.EndGame == nil then
			Shop.RequestDonate(tonumber(data.playerID), data.SteamID, callback)
		end
		
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
		
	end)
end	


function Shop.RequestChests(obj, pID, steam, callback)
	DebugPrint("************RequestChests*******************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["4"] = {}
	if #obj > 0 then
		for id=1,#obj do
			PoolTable["4"][obj[id].num] = {tostring(obj[id].num), tostring(obj[id].score) }
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)		
	return obj
end

function Shop.RequestSounds(obj, pID, steam, callback)
	DebugPrint("************RequestSounds*********************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	if #obj > 0 then
		for id=1,#obj do
			PoolTable["1"][tostring(obj[id].num)] = tostring(obj[id].num)
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)		
	return obj
end


-- подключи CustomGameEventManager:RegisterListener("OpenChestAnimation", Dynamic_Wrap(Shop, 'OpenChestAnimation'))
-- Так как в жс это довольно убого было бы сделать заранее сделал вот такую штуку в луа
-- Хранишь айди сундука и его шмотки с шансами
-- У gold/gem есть 3 массив это от скольки до скольки
Shop.Chests = {
	--{"501"] = { {1, 25},{2, 25},{3, 25},{4, 25},{5, 25},{6, 25}, {7, 25}, {8, 25}, {9, 25}, {"gold", 10, {100, 300} } },
	--{"502"] = { {103, 25},{11, 25},{12, 25},{13, 25},{14, 25},{15, 25},{16, 25},{17, 25},{18, 25}, {"gold", 10, {100, 300} } }
	
	["501"] = {{704,25},{705,25},{818,25},{24,25},{117,25},{130,25},{116,25},{602,50},{603,100}, 	{"gold", 20, {10, 50} } },
	["502"] = {{712,25},{716,25},{819,25},{25,25},{118,25},{131,25},{602,25},{603,50},{604,100}, 	{"gold", 20, {15, 75} } },
	["503"] = {{723,25},{719,25},{822,25},{26,25},{119,25},{114,25},{115,25},{605,50},{606,100}, 	{"gold", 20, {10, 50} } },
	["504"] = {{724,25},{801,25},{836,25},{20,25},{120,25},{111,25},{605,25},{606,50},{607,100}, 	{"gold", 20, {15, 75} } },
	["505"] = {{720,25},{802,25},{838,25},{21,25},{122,25},{112,25},{606,25},{607,50},{608,100}, 	{"gold", 20, {15, 75} } },
	["506"] = {{706,25},{803,25},{41,25},{31,25},{35,25},{103,25},{607,25},{613,50},{609,100}, 	{"gold", 20, {20, 100} } },
	["507"] = {{707,25},{804,25},{36,25},{37,25},{19,25},{129,25},{113,25},{615,50},{612,100}, 	{"gold", 20, {25, 125} } },
	["508"] = {{708,25},{805,25},{29,25},{39,25},{28,25},{132,25},{615,25},{612,50},{616,100}, 	{"gold", 20, {30, 150} } },
	["509"] = {{709,25},{806,25},{5,25},{10,25},{32,25},{133,25},{614,25},{616,50},{617,100}, 	{"gold", 20, {35, 150} } },
	["510"] = {{710,25},{807,25},{6,25},{38,25},{127,25},{134,25},{46,25},{635,50},{636,100}, 	{"gold", 20, {40, 200} } },
	["511"] = {{713,25},{810,25},{7,25},{40,25},{128,25},{135,25},{47,25},{637,50},{638,100}, 	{"gold", 20, {40, 200} } },
	["512"] = {{717,25},{811,25},{8,25},{42,25},{126,25},{144,25},{48,25},{639,50},{640,100}, 	{"gold", 20, {45, 200} } },
	["513"] = {{711,25},{813,25},{9,25},{43,25},{124,25},{146,25},{49,25},{641,50},{642,100}, 	{"gold", 20, {45, 200} } },
	--66
	["514"] = {{614,25},{602,25},{603,25},{604,25},{605,25},{606,25},{607,25},{608,50},{609,100}, 	{"gold", 20, {50, 250} } },
	["515"] = {{615,25},{612,25},{616,25},{617,25},{613,25},{639,25},{640,25},{641,50},{642,100}, 	{"gold", 20, {50, 250} } },

	--wolf 31
	["516"] = {{701,25},{814,25},{827,25},{18,25},{46,25},{133,25},{134,25},{624,50},{621,100}, 	{"gold", 20, {10, 50} } },
	["517"] = {{702,25},{816,25},{833,25},{23,25},{115,25},{135,25},{624,25},{621,50},{622,100}, 	{"gold", 20, {15, 75} } },
	["518"] = {{703,25},{722,25},{834,25},{27,25},{47,25},{50,25},{621,25},{622,50},{627,100}, 	{"gold", 20, {20, 100} } },
	["519"] = {{715,25},{721,25},{44,25},{22,25},{48,25},{51,25},{623,25},{628,50},{625,100}, 	{"gold", 20, {20, 100} } },
	["520"] = {{714,25},{718,25},{45,25},{34,25},{52,25},{610,25},{611,25},{629,50},{626,100}, 	{"gold", 20, {35, 150} } },

	["521"] = {{620,25},{624,25},{621,25},{622,25},{627,25},{628,25},{625,25},{629,50},{626,100}, {"gold", 20, {40, 200} } },

	["522"] = {{808,25},{809,25},{825,25},{33,25},{53,25},{54,25},{55,25},{618,50},{619,100}, {"gold", 20, {45, 200} } },
	["523"] = {{802,99},{111,99},{112,99},{113,99},{114,99},{115,99},{116,99},{103,99},{127,99}, {"gold", 20, {10, 100} } }
	
}

function Shop:OpenChestAnimation(data)
	local time = 0
	local id = data.PlayerID
	local reward = Shop:GetReward(data.chest_id, id) -- Предлагаю в этой функции возвращать выданный айди предмета

	print(reward)

	Timers:CreateTimer(0.03, function()
		time = time + 0.03
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(id), "ChestAnimationOpen", {time = time})

		if time < 6 then
			return 0.03
		else 
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(id), "shop_reward_request", {reward = reward})
			return
		end
	end)
end

function Shop:GetReward(chest_id, playerID)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
	-- Написал убогий рандом надеюсь перепишешь
	-- vladu4eg: мне нравится твоя идея. Сначала роллятся первые шмотки из списка, а потом уже дорогие шмотки. 
	local reward_recieve = Shop.Chests[chest_id][10][1] 
	local currency = RandomInt(Shop.Chests[chest_id][10][3][1], Shop.Chests[chest_id][10][3][2])
	local data = {}
	data.SteamID = tostring(PlayerResource:GetSteamID(playerID))
	data.PlayerID = playerID
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(playerID))
--	PoolTable["4"][tostring(chest_id)] = {tostring(chest_id), tostring(chest_id.score - 1) }
--	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)
	if PoolTable["4"][tostring(chest_id)] == nil then
		return
	end
	
	DebugPrint("reward_recieve " .. reward_recieve)
	for _, reward in pairs(Shop.Chests[chest_id]) do
		if RollPercentage(reward[2]) then
		    reward_recieve = reward[1]
			DebugPrint("playerID " .. playerID)
			
			
			for i, v in pairs(PoolTable["1"]) do
				if tostring(reward[1]) == tostring(v) then
					reward_recieve = Shop.Chests[chest_id][10][1]
					goto continue
				end
			end
			break
		end

		::continue::
	end
	data.TypeDonate = "chests"
	data.Coint = "0"

	data.Nick = chest_id 
	data.Num = tostring(reward_recieve)
	data.id = tostring(playerID)
	
	if reward_recieve == "gold" then -- Проверка что выпала голда
		data.Gem = 0
		data.Gold = currency
		data.Num = tostring(999)
		print(currency)
	elseif reward_recieve == "gem" then -- Проверка что выпали гемы
		data.Gem = currency
		data.Gold = 0
		data.Num = tostring(999)
	elseif reward_recieve < 100 then
		data.Nick = "pet_open_" .. chest_id 
	elseif reward_recieve >= 100 and reward_recieve < 200 then
		data.Nick = "particle_open_" .. chest_id 
	elseif reward_recieve >= 600 and reward_recieve < 700 then
		data.Nick = "skin_open_" .. chest_id 
	elseif reward_recieve >= 700 and reward_recieve < 900 then
		data.Nick = "sound_open_" .. chest_id 
	end
	
	Shop:BuyOpenChests(data, callback)
	-- Тут сразу можно отправку в базу данных оформить для награды, ее айди это reward_recieve / currency это сколько голды или гемов
	return reward_recieve
end

function DonateShopIsItemBought(id, item)
	local player_shop_table = CustomNetTables:GetTableValue("Shop", tostring(id))
	if player_shop_table then
		for _, item_id in pairs(player_shop_table["1"]) do
			if tostring(item_id) == tostring(item) then
				return true
			end
		end
		return false
	end
	return false
end

-- SOUNDS ----

function Shop:SelectVO(keys)
	local sounds = {
		"801",
		"802",
		"803",
		"804",
		"805",
		"806",
		"807",
		"808",
		"809",
		"810",
		"811",
		"812",
		"813",
		"814",
		"815",
		"816",
		"817",
		"818",
		"819",
		"820",
		"821",
		"822",
		"823",
		"824",
		"825",
		"826",
		"827",
		"828",
		"829",
		"830",
		"831",
		"832",
		"833",
		"834",
		"835",
		"836",
		"837",
		"838",
	}

	local sprays = {
		"701",
		"702",
		"703",
		"704",
		"705",
		"706",
		"707",
		"708",
		"709",
		"710",
		"711",
		"712",
		"713",
		"714",
		"715",
		"716",
		"717",
		"718",
		"719",
		"720",
		"721",
		"722",
		"723",
		"724",
	}

	local player = PlayerResource:GetPlayer(keys.PlayerID)

	if DonateShopIsItemBought(keys.PlayerID, keys.num) then
		for _,sound in pairs(sounds) do
			if tostring(keys.num) == tostring(sound) then
				if lastSounds[keys.PlayerID] == nil or lastSounds[keys.PlayerID] + 240 < GameRules:GetGameTime() then 
					lastSounds[keys.PlayerID] = GameRules:GetGameTime()
				else
					EmitSoundOnEntityForPlayer("General.Cancel", player, keys.PlayerID)
					local timeLeftTime = math.ceil(lastSounds[keys.PlayerID] + 240 - GameRules:GetGameTime())
					SendErrorMessage(keys.PlayerID, "Sound will be available through ".. timeLeftTime .." seconds!")
					return
				end
				local chat = LoadKeyValues("scripts/chat_wheel_rewards.txt")

				local sound_name = "item_wheel_"..keys.num
				for pID=0,DOTA_MAX_TEAM_PLAYERS do
					if PlayerResource:IsValidPlayerID(pID) then
						if GameRules.Mute[pID] == nil then
							DebugPrint(sound_name)
							local hero = PlayerResource:GetPlayer(pID)
							EmitSoundOnEntityForPlayer(sound_name, hero, pID)
							-- EmitSoundOnClient(sound_name, hero)
							--EmitSound(sound_name)
							
						end
					end
				end
				

				local chat = ""

				local chat_sounds = {
					[801] = "Sound - Уху минус три",						
					[802] = "Sound - Heelp",	
					[803] = "Sound - Держи в курсе",						
					[804] = "Sound - Пацаны Вообще Ребята",
					[805] = "Sound - Где враги?",							
					[806] = "Sound - Опять Работа?",
					[807] = "Sound - Лох",
					[808] = "Sound - Да это жестко",
					[809] = "Sound - Я тут притаился",
					[810] = "Sound - Вы хули тут делаете?",
					[811] = "Sound - Убейте меня",
					[812] = "Sound - Большой член Большие яйца",
					[813] = "Sound - Cейчас зарежу",
					[814] = "Sound - Йобаный рот этого казино",
					[815] = "Sound - Шизофрения",
					[816] = "Sound - Я вас уничтожу",
					[817] = "Sound - Узнайте родителей этого ублюдка",
					[818] = "Sound - Майнкрафт моя жизнь",
					[819] = "Sound - Somebody once told me",
					[820] = "Sound - Коно Дио да",
					[821] = "Sound - Яре яре дазе",
					[822] = "Sound - Это Фиаско",
					[823] = "Sound - Помянем",
					[824] = "Sound - Пам парам",
					[825] = "Sound - Отдай сало",
					[826] = "Sound - Чел ты",
					[827] = "Sound - Крип крипочек",
					[828] = "Sound - Нахуй Эту игру",
					[829] = "Sound - Мясо для ебли",
					[830] = "Sound - Rage Daertc",
					[831] = "Sound - Голосование",
					[832] = "Sound - Что вы делаете в холодильнике?",
					[833] = "Sound - Народ погнали",
					[834] = "Sound - Fatality",
					[835] = "Sound - О повезло, повезло",
					[836] = "Sound - Балаанс",
					[837] = "Sound - Нет друг я не оправдываюсь",
					[838] = "Sound - Кто пиздел?",
				}

				for id, chat_sound in pairs(chat_sounds) do
					if id == keys.num then
						chat = chat_sound
						break
					end
				end

				Say(PlayerResource:GetPlayer(keys.PlayerID), chat, false)

				--Say(PlayerResource:GetPlayer(keys.PlayerID), chat["item_wheel_"..keys.num], false)
			end
		end

		for _,spray in pairs(sprays) do
			if tostring(keys.num) == tostring(spray) then
				if lastSpray[keys.PlayerID] == nil or lastSpray[keys.PlayerID] + 15 < GameRules:GetGameTime() then 
					lastSpray[keys.PlayerID] = GameRules:GetGameTime()
				else
					EmitSoundOnEntityForPlayer("General.Cancel", player, keys.PlayerID)
					local timeLeftTime = math.ceil(lastSpray[keys.PlayerID] + 15 - GameRules:GetGameTime())
					SendErrorMessage(keys.PlayerID, "Spray will be available through ".. timeLeftTime .." seconds!")
					return
				end

				local spray_name = "item_wheel_"..keys.num

				local spray = ParticleManager:CreateParticle("particles/birzhapass/"..spray_name..".vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl( spray, 0, PlayerResource:GetSelectedHeroEntity(keys.PlayerID):GetOrigin() )
				ParticleManager:ReleaseParticleIndex( spray )
				PlayerResource:GetSelectedHeroEntity(keys.PlayerID):EmitSound("Spraywheel.Paint")
			end
		end
	else
		EmitSoundOnEntityForPlayer("General.Cancel", player, keys.PlayerID)
	end
end

function Shop.RequestRewards(obj, pID, steam, callback)
	DebugPrint("************RequestRewards*********************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["6"]["0"] = "0"
	PoolTable["6"]["1"] = "1"
	PoolTable["6"]["2"] = "1"
	if #obj > 0 then
		PoolTable["6"]["0"] = tostring(obj[1].score)
		PoolTable["6"]["1"] = tostring(obj[1].num)
		PoolTable["6"]["2"] = tostring(obj[1].srok)
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)		
	return obj
end

function Shop:EventRewards(table, callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() or GameRules.PlayersCount < MIN_RATING_PLAYER then 
			return 
		end
	end

    local steam = tostring(PlayerResource:GetSteamID(table.PlayerID))
    table.SteamID = steam
    table.MatchID = MatchID
	table.playerID = tostring(table.PlayerID)
	table.Gem = 0
	table.Gold = 0
	table.id = tostring(table.PlayerID)
	--table.Count 
	-- table.type
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server .. "postrewards/")
	local encData = json.encode(table)
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
			GameRules:SendCustomMessage("Error take rewards.. Code: " .. res.StatusCode, 1, 1)
			DebugPrint("Error take rewards.")
		end
		Shop.RequestDonate(tonumber(table.playerID), table.SteamID, callback)
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
		
	end)
end

function Shop.RequestXP(obj, pID, steam, callback)
	DebugPrint("*****RequestXP**********************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	local tmp = {}
	if #obj > 0 then
		PoolTable["7"]["0"] = tostring(obj[1].gold)
	end

	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)		
	return obj
end

function Shop.RequestBP(callback)
	local req = CreateHTTPRequestScriptVM("GET",GameRules.server .. "bpday")
	if not req then
		return
	end
	req:SetHTTPRequestHeaderValue("Dedicated-Server-Key", dedicatedServerKey)
	DebugPrint("***********RequestBP*********************")
	req:Send(function(res)
		if res.StatusCode ~= 200 then
			DebugPrint("Connection failed! Code: ".. res.StatusCode)
			DebugPrint(res.Body)
			return -1
		end
		
		local obj,pos,err = json.decode(res.Body)
		local PoolTable = {}
		if #obj > 0 then
			for id=1,#obj do
				PoolTable[id] = {obj[id].matchID, obj[id].nick, obj[id].type, obj[id].log, obj[id].score, obj[id].typeDonate }
			end
		end
		CustomNetTables:SetTableValue("Shop", "bpday", PoolTable)		
		return obj
		
	end)
end

function Shop.RequestBPplayer(obj, pID, steam, callback)
	DebugPrint("************RequestBPplayer***********************")
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(pID))
	PoolTable["10"]["1"] = {}
	if #obj > 0 then
		for id=1,#obj do
			PoolTable["10"]["1"][id] = {obj[id].matchID, obj[id].score, obj[id].typeDonate }
		end
	end
	CustomNetTables:SetTableValue("Shop", tostring(pID), PoolTable)			
	return obj
end

function Shop:EventBattlePass(table, callback)
	if not GameRules.isTesting  then
		if GameRules:IsCheatMode() then return end
	end
    local steam = tostring(PlayerResource:GetSteamID(table.PlayerID))
    table.SteamID = steam
    table.MatchID = MatchID
	table.playerID = tostring(table.PlayerID)
	table.Gem = 0
	table.Gold = 0
	--table.Count 
	-- table.type
	local req = CreateHTTPRequestScriptVM("POST",GameRules.server .. "battlepass/")
	local encData = json.encode(table)
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
			GameRules:SendCustomMessage("Error take rewards.. Code: " .. res.StatusCode, 1, 1)
			DebugPrint("Error take rewards.")
		end
		Shop.RequestDonate(tonumber(table.playerID), steam, callback)
		if callback then
			local obj,pos,err = json.decode(res.Body)
			callback(obj)
		end
		
	end)
end

function Shop:Statistics(table, callback)
	local PoolTable = CustomNetTables:GetTableValue("Shop", tostring(table.id))
	if table.type == "fps" then
		if tonumber(table.count) == 1 then
			GameRules.PlayersFPS[table.PlayerID] = true
		else
			GameRules.PlayersFPS[table.PlayerID] = false
		end
		PoolTable["5"]["4"] = tonumber(table.count)
		CustomNetTables:SetTableValue("Shop", tostring(table.PlayerID), PoolTable)
	elseif table.type == "mute" then
		if tonumber(table.count) == 1 then
			GameRules.Mute[table.PlayerID] = 1
			PoolTable["5"]["3"] = 1
			CustomNetTables:SetTableValue("Shop", tostring(table.PlayerID), PoolTable)
		else
			GameRules.Mute[table.PlayerID] = nil
			PoolTable["5"]["3"] = 0
			CustomNetTables:SetTableValue("Shop", tostring(table.PlayerID), PoolTable)
		end	
	elseif table.type == "block" then
		if tonumber(table.count) == 1 then
			GameRules.Block[table.PlayerID] = true
			PoolTable["5"]["5"] = 1
			CustomNetTables:SetTableValue("Shop", tostring(table.PlayerID), PoolTable)
		else
			GameRules.Block[table.PlayerID] = nil
			PoolTable["5"]["5"] = 0
			CustomNetTables:SetTableValue("Shop", tostring(table.PlayerID), PoolTable)
		end	
	end
end

function Shop.RequestBan(obj, pID, steam, callback)
	DebugPrint("*********RequestBan*************************")
	if #obj > 0 then
		if obj[1].steamID == steam then
			local text = "Nick: " .. PlayerResource:GetPlayerName(pID) .. " pID: " .. pID
			GameRules:SendCustomMessage(text, 1, 1)
			SendToServerConsole("kick " .. PlayerResource:GetPlayerName(pID))
			GameRules.KickList[pID] = 1
		end
	end
	return obj
end


Shop.DonateList = {
	{"523", "gold", "100", "chest_23", "chest_23"  },
	{"501", "gold", "50", "chest_1", "chest_1"},
	{"503", "gold", "50", "chest_3", "chest_3" },
	{"516", "gold", "50", "chest_16", "chest_16" },
	{"502", "gold", "75", "chest_2", "chest_2"},
	{"504", "gold", "75", "chest_4", "chest_4"},
	{"517", "gold", "75", "chest_17", "chest_17"},
	{"505", "gold", "100", "chest_5", "chest_5"},
	{"518", "gold", "100", "chest_18", "chest_18"},
	{"506", "gold", "100", "chest_6", "chest_6"},
	{"519", "gold", "100", "chest_19", "chest_19"},
	{"507", "gold", "125", "chest_7", "chest_7"},
	{"508", "gold", "150", "chest_8", "chest_8"},
	{"509", "gold", "175", "chest_9", "chest_9"},
	{"520", "gold", "175", "chest_20", "chest_20"},
	{"510", "gold", "200", "chest_10", "chest_10"},
	{"511", "gold", "200", "chest_11", "chest_11"},
	{"512", "gold", "225", "chest_12", "chest_12"},
	{"513", "gold", "225", "chest_13", "chest_13"},
	{"522", "gold", "225", "chest_22", "chest_22"},
	{"514", "gold", "250", "chest_14", "chest_14"},
	{"515", "gold", "250", "chest_15", "chest_15"},
	{"521", "gold", "250", "chest_21", "chest_21"},
	{"801",  "gold", "100", "sounds", "sounds_1", false, 1}, 
	{"802",  "gold", "100", "sounds", "sounds_2", false, 1}, 
	{"803",  "gold", "100", "sounds", "sounds_3", false, 1}, 
	{"804",  "gold", "100", "sounds", "sounds_4", false, 1},
	{"805",  "gold", "100", "sounds", "sounds_5", false, 1}, 
	{"806",  "gold", "100", "sounds", "sounds_6", false, 1}, 
	{"807",  "gold", "100", "sounds", "sounds_7", false, 1}, 
	{"808",  "gold", "100", "sounds", "sounds_8", false, 1}, 
	{"809",  "gold", "100", "sounds", "sounds_9", false, 1}, 
	{"810",  "gold", "100", "sounds", "sounds_10", false, 1}, 
	{"811",  "gold", "100", "sounds", "sounds_11", false, 1}, 
	{"813",  "gold", "100", "sounds", "sounds_13", false, 1}, 
	{"814",  "gold", "100", "sounds", "sounds_14", false, 1}, 
    {"816",  "gold", "100", "sounds", "sounds_16", false, 1},
	{"818",  "gold", "100", "sounds", "sounds_18", false, 1}, 
	{"819",  "gold", "100", "sounds", "sounds_19", false, 1}, 
	{"822",  "gold", "100", "sounds", "sounds_22", false, 1}, 
	{"825",  "gold", "100", "sounds", "sounds_25", false, 1}, 
	{"827",  "gold", "100", "sounds", "sounds_27", false, 1}, 
	{"833",  "gold", "100", "sounds", "sounds_33", false, 1}, 
	{"834",  "gold", "100", "sounds", "sounds_34", false, 1}, 
	{"836",  "gold", "100", "sounds", "sounds_36", false, 1}, 
	{"838",  "gold", "100", "sounds", "sounds_38", false, 1}, 
	{"701",  "gold", "50", "spray_1", "spray_1", false, 1}, 
	{"702",  "gold", "50", "spray_2", "spray_2", false, 1}, 
	{"703",  "gold", "50", "spray_3", "spray_3", false, 1}, 
	{"704",  "gold", "50", "spray_4", "spray_4", false, 1}, 

	{"705",  "gold", "50", "spray_5", "spray_5", false, 1}, 
	{"706",  "gold", "50", "spray_6", "spray_6", false, 1}, 
	{"707",  "gold", "50", "spray_7", "spray_7", false, 1}, 
	{"708",  "gold", "50", "spray_8", "spray_8", false, 1},

	{"709",  "gold", "50", "spray_9", "spray_9", false, 1}, 
	{"710",  "gold", "50", "spray_10", "spray_10", false, 1}, 
	{"711",  "gold", "50", "spray_11", "spray_11", false, 1}, 
	{"712",  "gold", "50", "spray_12", "spray_12", false, 1}, 

	{"713",  "gold", "50", "spray_13", "spray_13", false, 1}, 
	{"714",  "gold", "50", "spray_14", "spray_14", false, 1}, 
	{"715",  "gold", "50", "spray_15", "spray_15", false, 1}, 
	{"716",  "gold", "50", "spray_16", "spray_16", false, 1},

	{"717",  "gold", "50", "spray_17", "spray_17", false, 1}, 
	{"718",  "gold", "50", "spray_18", "spray_18", false, 1}, 
	{"719",  "gold", "50", "spray_19", "spray_19", false, 1}, 
	{"720",  "gold", "50", "spray_20", "spray_20", false, 1},

	{"721",  "gold", "50", "spray_21", "spray_21", false, 1}, 
	{"722",  "gold", "50", "spray_22", "spray_22", false, 1}, 
	{"723",  "gold", "50", "spray_23", "spray_23", false, 1}, 
	{"724",  "gold", "50", "spray_24", "spray_24", false, 1}, 
	{"601", "gold", "99999999", "skin_1", "skin_1", false, 7}, 
	{"602", "gold", "500", "skin_2", "skin_2", false, 7}, 
	{"603", "gold", "500", "skin_3", "skin_3", false, 7}, 
	{"604", "gold", "500", "skin_4", "skin_4", false, 7}, 
	{"605", "gold", "500", "skin_5", "skin_5", false, 7}, 
	{"606", "gold", "500", "skin_6", "skin_6", false, 7}, 
	{"607", "gold", "500", "skin_7", "skin_7", false, 7}, 
	{"608", "gold", "500", "skin_8", "skin_8", false, 7}, 
	{"609", "gold", "500", "skin_9", "skin_9", false, 7}, 
	{"610", "gold", "500", "skin_10", "skin_10", false, 7}, 
	{"611", "gold", "500", "skin_11", "skin_11", false, 7}, 
	{"612", "gold", "500", "skin_12", "skin_12", false, 7}, 
	{"613", "gold", "750", "skin_13", "skin_13", false, 7}, 
	{"614", "gold", "750", "skin_14", "skin_14", false, 7}, 
	{"615", "gold", "500", "skin_15", "skin_15", false, 7}, 
	{"616", "gold", "750", "skin_16", "skin_16", false, 7}, 
	{"617", "gold", "750", "skin_17", "skin_17", false, 7}, 
	{"618", "gold", "1000", "skin_18", "skin_18", false, 7}, 
	{"619", "gold", "1000", "skin_19", "skin_19", false, 7}, 
	
	{"635", "gold", "1000", "skin_35", "skin_35", false, 7}, 
	{"636", "gold", "1000", "skin_36", "skin_36", false, 7}, 
	{"637", "gold", "1000", "skin_37", "skin_37", false, 7}, 
	{"638", "gold", "1000", "skin_38", "skin_38", false, 7},
	{"639", "gold", "1000", "skin_39", "skin_39", false, 7}, 
	{"640", "gold", "1000", "skin_40", "skin_40", false, 7}, 
	{"641", "gold", "1000", "skin_41", "skin_41", false, 7}, 
	{"642", "gold", "1000", "skin_42", "skin_42", false, 7},

	{"644", "gold", "1000", "skin_44", "skin_44", false, 7},
	{"645", "gold", "1000", "skin_45", "skin_45", false, 7},
	{"646", "gold", "1000", "skin_46", "skin_46", false, 7},
	{"647", "gold", "1000", "skin_47", "skin_47", false, 7},
	{"648", "gold", "1000", "skin_48", "skin_48", false, 7},
	{"649", "gold", "1000", "skin_49", "skin_49", false, 7},
	{"650", "gold", "1000", "skin_50", "skin_50", false, 7},
	{"651", "gold", "1000", "skin_51", "skin_51", false, 7},
	{"652", "gold", "1000", "skin_52", "skin_52", false, 7},

	
	{"620", "gold", "99999999", "skin_20", "skin_20", false, 7}, 
	{"621", "gold", "800", "skin_21", "skin_21", false, 7}, 
	{"622", "gold", "800", "skin_22", "skin_22", false, 7}, 
	{"623", "gold", "800", "skin_23", "skin_23", false, 7}, 
	{"624", "gold", "800", "skin_24", "skin_24", false, 7}, 
	{"625", "gold", "800", "skin_25", "skin_25", false, 7}, 
	{"626", "gold", "1000", "skin_26", "skin_26", false, 7}, 
	{"627", "gold", "800", "skin_27", "skin_27", false, 7}, 
	{"628", "gold", "800", "skin_28", "skin_28", false, 7}, 
	{"629", "gold", "1000", "skin_29", "skin_29", false, 7},

	{"630", "gold", "5000", "skin_30", "skin_30", false, 7},
	{"631", "gold", "5000", "skin_31", "skin_31", false, 7},

	{"653", "gold", "5000", "skin_53", "skin_53", false, 7},
	{"654", "gold", "5000", "skin_54", "skin_54", false, 7},
	{"655", "gold", "5000", "skin_55", "skin_55", false, 7},
	{"656", "gold", "5000", "skin_56", "skin_56", false, 7},
	{"657", "gold", "5000", "skin_57", "skin_57", false, 7},
	{"658", "gold", "5000", "skin_58", "skin_58", false, 7},
	{"659", "gold", "5000", "skin_59", "skin_59", false, 7},
	{"660", "gold", "5000", "skin_60", "skin_60", false, 7},
	{"661", "gold", "5000", "skin_61", "skin_61", false, 7},
	{"662", "gold", "5000", "skin_62", "skin_62", false, 7},
	{"663", "gold", "5000", "skin_63", "skin_63", false, 7},
	{"664", "gold", "5000", "skin_64", "skin_64", false, 7},
	{"665", "gold", "5000", "skin_65", "skin_65", false, 7},
	{"666", "gold", "99999999", "skin_66", "skin_66", false, 7},
	{"667", "gold", "5000", "skin_67", "skin_67", false, 7},
	{"668", "gold", "5000", "skin_68", "skin_68", false, 7},
	{"669", "gold", "5000", "skin_69", "skin_69", false, 7},
	{"670", "gold", "5000", "skin_70", "skin_70", false, 7},
	{"671", "gold", "5000", "skin_71", "skin_71", false, 7},
	{"672", "gold", "5000", "skin_72", "skin_72", false, 7},
	{"643", "gold", "5000", "skin_43", "skin_43", false, 7}, 

	{"673", "gold", "300", "skin_73", "skin_73", false, 7}, 
	{"674", "gold", "500", "skin_74", "skin_74", false, 7}, 
	{"675", "gold", "500", "skin_75", "skin_75", false, 7}, 
	{"676", "gold", "1000", "skin_76", "skin_76", false, 7}, 
	{"677", "gold", "800", "skin_77", "skin_77", false, 7}, 
	{"678", "gold", "800", "skin_78", "skin_78", false, 7}, 
	{"679", "gold", "300", "skin_79", "skin_79", false, 7}, 
	{"680", "gold", "1000", "skin_80", "skin_80", false, 7}, 
	{"681", "gold", "300", "skin_81", "skin_81", false, 7}, 
	{"682", "gold", "1000", "skin_82", "skin_82", false, 7},

	{"24", "gold", "100", "pet_24", "pet_24", false, 2},
	{"25", "gold", "100", "pet_25", "pet_25", false, 2},
	{"26", "gold", "100", "pet_26", "pet_26", false, 2},
	{"20", "gold", "100", "pet_20", "pet_20", false, 2},
	{"21", "gold", "100", "pet_21", "pet_21", false, 2},
	{"31", "gold", "100", "pet_31", "pet_31", false, 2},
	{"36", "gold", "100", "pet_36", "pet_36", false, 2},
	{"37", "gold", "100", "pet_37", "pet_37", false, 2},
	{"41", "gold", "100", "pet_41", "pet_41", false, 2},

	{"29", "gold", "150", "pet_29", "pet_29", false, 2},
	{"39", "gold", "150", "pet_39", "pet_39", false, 2},
	
	{"5", "gold", "150", "pet_5", "pet_5", false, 3},
	{"6", "gold", "150", "pet_6", "pet_6", false, 3},
	{"7", "gold", "150", "pet_7", "pet_7", false, 3},
	{"8", "gold", "150", "pet_8", "pet_8", false, 3},
	{"9", "gold", "150", "pet_9", "pet_9", false, 3},
	{"10", "gold", "150", "pet_10", "pet_10", false, 3},
	{"38", "gold", "150", "pet_38", "pet_38", false, 3},

	{"40", "gold", "150", "pet_40", "pet_40", false, 3},
	{"42", "gold", "150", "pet_42", "pet_42", false, 3},
	{"43", "gold", "150", "pet_43", "pet_43", false, 3},
	{"44", "gold", "150", "pet_44", "pet_44", false, 3},
	{"45", "gold", "150", "pet_45", "pet_45", false, 3},
	{"18", "gold", "150", "pet_18", "pet_18", false, 3},
	{"23", "gold", "150", "pet_23", "pet_23", false, 3},
	{"27", "gold", "150", "pet_27", "pet_27", false, 3},
	{"22", "gold", "150", "pet_22", "pet_22", false, 3},
	{"54", "gold", "150", "pet_54", "pet_54", false, 3},
	{"53", "gold", "150", "pet_53", "pet_53", false, 3},
	{"34", "gold", "250", "pet_34", "pet_34", false, 4},
	{"35", "gold", "250", "pet_35", "pet_35", false, 4},
	{"19", "gold", "250", "pet_19", "pet_19", false, 4},
	{"28", "gold", "250", "pet_28", "pet_28", false, 5},
	{"32", "gold", "250", "pet_32", "pet_32", false, 5},
	{"33", "gold", "350", "pet_33", "pet_33", false, 5},
	{"55", "gold", "350", "pet_55", "pet_55", false, 5},
	{"56", "gold", "350", "pet_56", "pet_56", false, 5},
	{"57", "gold", "350", "pet_57", "pet_57", false, 5},

	{"46", "gold", "400", "pet_46", "pet_46", false, 5},
	{"47", "gold", "425", "pet_47", "pet_47", false, 5},
	{"48", "gold", "450", "pet_48", "pet_48", false, 5},
	{"49", "gold", "475", "pet_49", "pet_49", false, 5},
	{"50", "gold", "500", "pet_50", "pet_50", false, 5},
	{"51", "gold", "525", "pet_51", "pet_51", false, 5},
	{"52", "gold", "550", "pet_52", "pet_52", false, 5},

	{"58", "gold", "400", "pet_58", "pet_58", false, 5},
	{"59", "gold", "425", "pet_59", "pet_59", false, 5},
	{"60", "gold", "450", "pet_60", "pet_60", false, 5},
	{"61", "gold", "475", "pet_61", "pet_61", false, 5},
	{"62", "gold", "500", "pet_62", "pet_62", false, 5},
	{"63", "gold", "525", "pet_63", "pet_63", false, 5},
	{"64", "gold", "550", "pet_64", "pet_64", false, 5},

	{"1", "gold", "99999999", "pet_1", "pet_1", false, 8}, 
	{"2", "gold", "99999999", "pet_2", "pet_2", false, 8},
	{"3", "gold", "99999999", "pet_3", "pet_3", false, 8},
	{"4", "gold", "99999999", "pet_4", "pet_4", false, 8},

	{"11", "gold", "99999999", "pet_11", "pet_11", false, 8},
	{"12", "gold", "99999999", "pet_12", "pet_12", false, 8},
	{"13", "gold", "99999999", "pet_13", "pet_13", false, 8},
	{"14", "gold", "99999999", "pet_14", "pet_14", false, 8},
	{"15", "gold", "99999999", "pet_15", "pet_15", false, 8},
	{"16", "gold", "99999999", "pet_16", "pet_16", false, 8},

	{"65", "gold", "99999999", "pet_65", "pet_65", false, 8}, 
	{"66", "gold", "99999999", "pet_66", "pet_66", false, 8},
	
	{"17", "gold", "99999999", "pet_17", "pet_17", false, 8},
	{"30", "gold", "99999999", "pet_30", "pet_30", false, 8},
	{"201", "gold", "150", "chance", "subscribe_1", true, 7},
	{"202", "gold", "500", "chance", "subscribe_2", true, 7},
	{"203", "gold", "1000", "chance", "subscribe_3", true, 7},
	{"204", "gold", "150", "bonus", "subscribe_4", true, 7},
	{"205", "gold", "99999999", "battlepass", "subscribe_5", true, 7},
	
	{"111", "gold", "150", "particle_11", "particle_11", false, 7}, 
	{"112", "gold", "75", "particle_12", "particle_12", false, 2}, 
	{"113", "gold", "75", "particle_13", "particle_13", false, 2}, 
	{"114", "gold", "75", "particle_14", "particle_14", false, 2}, 
	{"115", "gold", "75", "particle_15", "particle_15", false, 3}, 
	{"116", "gold", "75", "particle_16", "particle_16", false, 2},
	{"103", "gold", "300", "particle_3", "particle_3", false, 7},
	{"127", "gold", "500", "particle_27", "particle_27", false, 3}, 
	{"128", "gold", "500", "particle_28", "particle_28", false, 3}, 
	{"129", "gold", "500", "particle_29", "particle_29", false, 4}, 
	{"132", "gold", "500", "particle_32", "particle_32", false, 4}, 
	{"133", "gold", "500", "particle_33", "particle_33", false, 4}, 
	{"134", "gold", "500", "particle_34", "particle_34", false, 4}, 
	{"135", "gold", "500", "particle_35", "particle_35", false, 4}, 
	{"144", "gold", "500", "particle_44", "particle_44", false, 5}, 
	{"146", "gold", "500", "particle_46", "particle_46", false, 5},
	{"181", "gold", "500", "particle_81", "particle_81", false, 5}, 
	{"182", "gold", "500", "particle_82", "particle_82", false, 5}, 
	{"183", "gold", "500", "particle_83", "particle_83", false, 5}, 
	{"184", "gold", "500", "particle_84", "particle_84", false, 5},  

	{"117", "gold", "50", "particle_17", "particle_17", false, 2}, 
	{"118", "gold", "50", "particle_18", "particle_18", false, 2}, 
	{"119", "gold", "50", "particle_19", "particle_19", false, 2}, 
	{"120", "gold", "50", "particle_20", "particle_20", false, 2}, 
	{"122", "gold", "50", "particle_22", "particle_22", false, 2}, 
	{"124", "gold", "500", "particle_24", "particle_24", false, 3},
	{"126", "gold", "500", "particle_26", "particle_26", false, 3}, 
	{"130", "gold", "50", "particle_30", "particle_30", false, 2}, 
	{"131", "gold", "50", "particle_31", "particle_31", false, 2}, 

	{"138", "gold", "99999999", "particle_38", "particle_38", false, 8}, 
	{"139", "gold", "99999999", "particle_39", "particle_39", false, 8}, 
	{"140", "gold", "99999999", "particle_40", "particle_40", false, 8}, 
	{"141", "gold", "99999999", "particle_41", "particle_41", false, 8}, 
	{"142", "gold", "99999999", "particle_42", "particle_42", false, 8}, 
	{"143", "gold", "99999999", "particle_43", "particle_43", false, 8},
	{"121", "gold", "99999999", "particle_21", "particle_21", false, 8}, 
	{"125", "gold", "99999999", "particle_25", "particle_25", false, 8},
	{"137", "gold", "99999999", "particle_37", "particle_37", false, 8},
	{"149", "gold", "99999999", "particle_49", "particle_49", false, 8}, 
	{"150", "gold", "99999999", "particle_50", "particle_50", false, 8}, 
	{"105", "gold", "99999999", "particle_5", "particle_5", false, 8}, 

	{"153", "gold", "99999999", "particle_53", "particle_53", false, 8},
	{"152", "gold", "99999999", "particle_52", "particle_52", false, 8},  
	{"154", "gold", "99999999", "particle_54", "particle_54", false, 8}, 
	{"155", "gold", "99999999", "particle_55", "particle_55", false, 8}, 
	{"156", "gold", "99999999", "particle_56", "particle_56", false, 8}, 
	{"157", "gold", "99999999", "particle_57", "particle_57", false, 8}, 
	{"145", "gold", "99999999", "particle_45", "particle_45", false, 8},

	{"106", "gold", "99999999", "particle_6", "particle_6", false, 8},
	{"102", "gold", "99999999", "particle_2", "particle_2", false, 8}, 
	{"110", "gold", "99999999", "particle_10", "particle_10", false, 8}, 
	{"109", "gold", "99999999", "particle_9", "particle_9", false, 8},
	{"123", "gold", "99999999", "particle_23", "particle_23", false, 8},  
	

	{"107", "gold", "99999999", "particle_7", "particle_7", false, 8}, 
	{"108", "gold", "99999999", "particle_8", "particle_8", false, 8},
	{"104", "gold", "99999999", "particle_4", "particle_4", false, 8}, 
	{"147", "gold", "99999999", "particle_47", "particle_47", false, 8}, 
	{"148", "gold", "99999999", "particle_48", "particle_48", false, 8}, 
	

	{"151", "gold", "5000", "particle_51", "particle_51", false, 8}, 
	{"158", "gold", "5000", "particle_58", "particle_58", false, 8}, 
	{"159", "gold", "5000", "particle_59", "particle_59", false, 8}, 
	{"160", "gold", "5000", "particle_60", "particle_60", false, 8}, 
	{"161", "gold", "5000", "particle_61", "particle_61", false, 8}, 
	{"162", "gold", "5000", "particle_62", "particle_62", false, 8}, 
	{"163", "gold", "5000", "particle_63", "particle_63", false, 8}, 
	{"164", "gold", "5000", "particle_64", "particle_64", false, 8}, 
	{"165", "gold", "5000", "particle_65", "particle_65", false, 8}, 
	{"166", "gold", "5000", "particle_66", "particle_66", false, 8}, 
	{"167", "gold", "5000", "particle_67", "particle_67", false, 8}, 
	{"168", "gold", "5000", "particle_68", "particle_68", false, 8}, 
	{"169", "gold", "5000", "particle_69", "particle_69", false, 8}, 
	{"170", "gold", "5000", "particle_70", "particle_70", false, 8}, 
	{"171", "gold", "5000", "particle_71", "particle_71", false, 8}, 
	{"172", "gold", "5000", "particle_72", "particle_72", false, 8}, 

	{"136", "gold", "5000", "particle_36", "particle_36", false, 8},
	{"173", "gold", "5000", "particle_73", "particle_73", false, 8}, 
	{"174", "gold", "5000", "particle_74", "particle_74", false, 8}, 
	{"175", "gold", "5000", "particle_75", "particle_75", false, 8},

	{"176", "gold", "99999999", "particle_76", "particle_76", false, 8},  
	{"177", "gold", "99999999", "particle_77", "particle_77", false, 8},  
	{"178", "gold", "99999999", "particle_78", "particle_78", false, 8},  
	{"179", "gold", "99999999", "particle_79", "particle_79", false, 8},  
	{"180", "gold", "99999999", "particle_80", "particle_80", false, 8},  
	{"185", "gold", "99999999", "particle_85", "particle_85", false, 8},  
	{"201", "gem", "99999999", "chance", "subscribe_1", true, 7},
	{"202", "gem", "99999999", "chance", "subscribe_2", true, 7},
	{"203", "gem", "99999999", "chance", "subscribe_3", true, 7},
	{"204", "gem", "99999999", "bonus", "subscribe_4", true, 7},
	{"205", "gem", "99999999", "battlepass", "subscribe_5", true, 7},
	
	{"111", "gem", "2000", "particle_11", "particle_11", false, 1}, 
	{"112", "gem", "1500", "particle_12", "particle_12", false, 1}, 
	{"113", "gem", "1500", "particle_13", "particle_13", false, 1}, 
	{"114", "gem", "1500", "particle_14", "particle_14", false, 1}, 
	{"115", "gem", "2000", "particle_15", "particle_15", false, 1}, 
	{"116", "gem", "1599", "particle_16", "particle_16", false, 1},
	{"103", "gem", "2500", "particle_3", "particle_3", false, 1},
	{"127", "gem", "3000", "particle_27", "particle_27", false, 1}, 
	{"128", "gem", "3500", "particle_28", "particle_28", false, 1}, 
	{"129", "gem", "4000", "particle_29", "particle_29", false, 1}, 
	{"132", "gem", "4500", "particle_32", "particle_32", false, 1}, 
	{"133", "gem", "4500", "particle_33", "particle_33", false, 1}, 
	{"134", "gem", "4500", "particle_34", "particle_34", false, 1}, 
	{"135", "gem", "4500", "particle_35", "particle_35", false, 1}, 
	{"144", "gem", "5000", "particle_44", "particle_44", false, 1}, 
	{"146", "gem", "5000", "particle_46", "particle_46", false, 1}, 
	{"181", "gem", "5000", "particle_81", "particle_81", false, 5}, 
	{"182", "gem", "5000", "particle_82", "particle_82", false, 5}, 
	{"183", "gem", "5000", "particle_83", "particle_83", false, 5}, 
	{"184", "gem", "5000", "particle_84", "particle_84", false, 5},  

	{"117", "gem", "1100", "particle_17", "particle_17", false, 1}, 
	{"130", "gem", "1100", "particle_30", "particle_30", false, 1}, 
	{"119", "gem", "1300", "particle_19", "particle_19", false, 1},
	{"131", "gem", "1300", "particle_31", "particle_31", false, 1}, 
	{"118", "gem", "1500", "particle_18", "particle_18", false, 1}, 
	{"120", "gem", "1700", "particle_20", "particle_20", false, 1}, 
	{"122", "gem", "1700", "particle_22", "particle_22", false, 1}, 
	{"124", "gem", "1700", "particle_24", "particle_24", false, 1},
	{"126", "gem", "1700", "particle_26", "particle_26", false, 1}, 


	{"5", "gem", "1100", "pet_5", "pet_5", false, 1},
	{"6", "gem", "1100", "pet_6", "pet_6", false, 1},
	{"7", "gem", "1100", "pet_7", "pet_7", false, 1},
	{"8", "gem", "1100", "pet_8", "pet_8", false, 1},
	{"9", "gem", "1100", "pet_9", "pet_9", false, 1},
	{"10", "gem", "1100", "pet_10", "pet_10", false, 1},

	{"40", "gem", "1700", "pet_40", "pet_40", false, 1},
	{"42", "gem", "1700", "pet_42", "pet_42", false, 1},
	{"43", "gem", "1700", "pet_43", "pet_43", false, 1},
	{"44", "gem", "1700", "pet_44", "pet_44", false, 1},
	{"45", "gem", "1700", "pet_45", "pet_45", false, 1},
	{"18", "gem", "1700", "pet_18", "pet_18", false, 1},
	{"23", "gem", "1700", "pet_23", "pet_23", false, 1},
	{"27", "gem", "1700", "pet_27", "pet_27", false, 1},
	{"22", "gem", "1700", "pet_22", "pet_22", false, 1},
	{"54", "gem", "1700", "pet_54", "pet_54", false, 1},
	{"53", "gem", "1700", "pet_53", "pet_53", false, 1},
	{"34", "gem", "2100", "pet_34", "pet_34", false, 1},
	{"35", "gem", "2100", "pet_35", "pet_35", false, 1},
	{"19", "gem", "2100", "pet_19", "pet_19", false, 1},
	{"28", "gem", "2100", "pet_28", "pet_28", false, 1},
	{"32", "gem", "2100", "pet_32", "pet_32", false, 1},
	{"33", "gem", "2500", "pet_33", "pet_33", false, 1},
	{"55", "gem", "2500", "pet_55", "pet_55", false, 1},
	{"56", "gem", "2500", "pet_56", "pet_56", false, 5},
	{"57", "gem", "2500", "pet_57", "pet_57", false, 5},

	{"46", "gem", "3000", "pet_46", "pet_46", false, 5},
	{"47", "gem", "3250", "pet_47", "pet_47", false, 5},
	{"48", "gem", "4000", "pet_48", "pet_48", false, 5},
	{"49", "gem", "4500", "pet_49", "pet_49", false, 5},
	{"50", "gem", "5000", "pet_50", "pet_50", false, 5},
	{"51", "gem", "5250", "pet_51", "pet_51", false, 5},
	{"52", "gem", "5500", "pet_52", "pet_52", false, 5},

	{"58", "gem", "4000", "pet_58", "pet_58", false, 5},
	{"59", "gem", "4250", "pet_59", "pet_59", false, 5},
	{"60", "gem", "4500", "pet_60", "pet_60", false, 5},
	{"61", "gem", "4750", "pet_61", "pet_61", false, 5},
	{"62", "gem", "5000", "pet_62", "pet_62", false, 5},
	{"63", "gem", "5250", "pet_63", "pet_63", false, 5},
	{"64", "gem", "5500", "pet_64", "pet_64", false, 5}	
}