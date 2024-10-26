LinkLuaModifier("modifier_fow_vision", "modifiers/modifier_fow_vision", LUA_MODIFIER_MOTION_NONE )

local camp_counter = 0 
local vacated_time = 0


-- Think that checks if neutral creeps are close to spawner entities

function OnTriggerThink_Timer()
	camp_counter = 0
	local count = Entities:FindAllByClassnameWithin( "npc_dota_creature", thisEntity:GetAbsOrigin(), 600 )
	local classUnit = ""
	for _,entity in pairs(count) do
		if string.match(entity:GetUnitName(), "wave_creep") or string.match(entity:GetUnitName(), "wave_boss") then
			classUnit = "creep"
		end
		if string.match(thisEntity:GetName(), classUnit) and entity:GetUnitName() ~= "npc_cosmetic_pet"  then
			camp_counter = camp_counter + 1
		end
		--DebugPrint(entity:GetUnitName() .. " " .. thisEntity:GetName() )
		--print(entity:GetClassname())
	end
	if camp_counter == 0 then
		if vacated_time == 0 then
			vacated_time = GameRules:GetGameTime()
		end
		--print("camp_counter is zero")
	else
		vacated_time = 0
		return 30
	end

	if vacated_time > 0 and GameRules:GetGameTime() > vacated_time + 30 then
		
		local numberToSpawn = RandomInt(1,3)
		
		local max = math.floor((GameRules:GetGameTime()/60) + 1)
		if max > 19 then
			max = 19
		end
		local id = RandomInt(math.ceil(max*0.5), max)
		local randomWave = RandomInt(1,100) 
		local name
		if thisEntity:GetName() == "creep10" then
			id = RandomInt(10,14)
		elseif thisEntity:GetName() == "creep15" then
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
				if string.match(unit:GetUnitName(), "_wave_boss_extreme") then
					--	unit:AddNewModifier(unit, nil, "modifier_fow_vision", {})
				end	
			--end
		end
	end
	--print(camp_counter)
	return 30
end


thisEntity:SetThink( "OnTriggerThink_Timer", 30 )

function SpawnBuff(unit)	
		local hp = 1
		local dmg = 1
		local randomWave = RandomInt(1,100) 

		if string.match(GetMapName(),"1x10") then
			hp = 1
			dmg = 1
		elseif string.match(GetMapName(),"2x20") then
			hp = 2
			dmg = 2
		elseif string.match(GetMapName(),"3x21") then
			hp = 3
			dmg = 3
		elseif string.match(GetMapName(),"5x20") then
			hp = 3
			dmg = 1.25
		end
		--local tmp = GameRules:GetGameTime()/1200
		unit:SetMaxHealth(unit:GetMaxHealth() * hp)
		unit:SetBaseMaxHealth(unit:GetBaseMaxHealth() * hp)
		unit:SetHealth(unit:GetHealth() * hp)
		unit:SetBaseDamageMin(unit:GetBaseDamageMin() * dmg)	
		unit:SetBaseDamageMax(unit:GetBaseDamageMax() * dmg)
end



--[[
				CreateUnitByNameAsync(name , , true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
					unit.vSpawn = thisEntity:GetOrigin()
					SpawnBuff(unit)
					if string.match(unit:GetUnitName(), "_wave_boss_extreme") then
					--	unit:AddNewModifier(unit, nil, "modifier_fow_vision", {})
					end	
				end)

]]