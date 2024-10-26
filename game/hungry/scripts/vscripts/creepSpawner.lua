if creepSpawner == nil then
	_G.creepSpawner = class({})
end

LinkLuaModifier("modifier_fow_vision", "modifiers/modifier_fow_vision", LUA_MODIFIER_MOTION_NONE )

function creepSpawner:Progress() 
	
	Timers:CreateTimer(function() 
		local creep = Entities:FindAllByName("creep")
		local creep10 = Entities:FindAllByName("creep10")
		local creep15 = Entities:FindAllByName("creep15")
		for i=1, #creep do
			startSpawn(creep[i])
		end
		for i=1, #creep10 do
			startSpawn(creep10[i])
		end	
		for i=1, #creep15 do
			startSpawn(creep15[i])
		end	
	return 20 
	end)
end

function startSpawn(thisEntity)
	local camp_counter = 0 
	local count = Entities:FindAllByClassnameWithin( "npc_dota_creature", thisEntity:GetAbsOrigin(), 700 )
	local classUnit = ""
	
	for _,entity in pairs(count) do
		if string.match(entity:GetUnitName(), "wave_creep") or string.match(entity:GetUnitName(), "wave_boss") then
			classUnit = "creep"
		end
		if string.match(thisEntity:GetName(), classUnit) and entity:GetUnitName() ~= "npc_cosmetic_pet"  then
			camp_counter = camp_counter + 1
			break
		end
		--DebugPrint(entity:GetUnitName() .. " " .. thisEntity:GetName() )
		--print(entity:GetClassname())
	end

	if camp_counter == 0 then
		
		local numberToSpawn = RandomInt(1,2)
		
		local max = math.floor((GameRules:GetGameTime()/60) + 1)
		if max > 19 then
			max = 19
		end
		local id = RandomInt(math.ceil(max*0.5), max)
		local randomWave = RandomInt(1,100) 
		local name
		if thisEntity:GetName() == "creep10" and id < 10 then
			id = RandomInt(10,14)
		elseif thisEntity:GetName() == "creep15" and id < 15 then
			id = RandomInt(15,19)
		end

		if randomWave >= 1 and randomWave <= 60 then
			name = id .. "_wave_creep"
		elseif randomWave > 60 and randomWave <= 96 then
			name = id .. "_wave_boss"
			numberToSpawn = 1
		else
			if id == 5 or id == 10 or id == 15 then
				id = id + 4
			end
			name = id .. "_wave_boss_extreme"
			numberToSpawn = 1
		end

		for i = 1, numberToSpawn do
			--if IsServer() then
				local unit  = CreateUnitByName(name, thisEntity:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS)
				unit.vSpawn = thisEntity:GetOrigin()
				SpawnBuff(unit)
				unit:SetCustomHealthLabel("#" .. unit:GetUnitName(),  250, 129, 129)
				if string.match(unit:GetUnitName(), "_wave_boss_extreme") then
					--	unit:AddNewModifier(unit, nil, "modifier_fow_vision", {})
				end	
			--end
		end
	end

end

function SpawnBuff(unit)	
	local hp = 1
	local dmg = 1
	if string.match(GetMapName(),"1x10") then
		hp = 1.10
		dmg = 1.05
	elseif string.match(GetMapName(),"2x20") then
		hp = 1.60
		dmg = 1.15
	elseif string.match(GetMapName(),"3x21") then
		hp = 2.10
		dmg = 1.20
	elseif string.match(GetMapName(),"5x20") then
		hp = 3.10
		dmg = 1.30
	end
	--local tmp = GameRules:GetGameTime()/1200
	unit:SetMaxHealth(unit:GetMaxHealth() * hp)
	unit:SetBaseMaxHealth(unit:GetBaseMaxHealth() * hp)
	unit:SetHealth(unit:GetHealth() * hp)
	unit:SetBaseDamageMin(unit:GetBaseDamageMin() * dmg)	
	unit:SetBaseDamageMax(unit:GetBaseDamageMax() * dmg)
end

--[[
	local hero = FindUnitsInRadius( 
									1,	--команда юнита
									thisEntity:GetOrigin(),		--местоположение юнита
									nil,	--айди юнита (необязательно)
									4500,	--радиус поиска
									DOTA_UNIT_TARGET_TEAM_BOTH,	-- юнитов чьей команды ищем вражеской/дружественной
									DOTA_UNIT_TARGET_HERO,	--юнитов какого типа ищем 
									DOTA_UNIT_TARGET_FLAG_NONE,	--поиск по флагам
									FIND_ANY_ORDER,	--сортировка от ближнего к дальнему или от дальнего к ближнему
									false )
	DebugPrint("hero# ".. #hero)
	if #hero == 0 then
		return
	end
	--]]