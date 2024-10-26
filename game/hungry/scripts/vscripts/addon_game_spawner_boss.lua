local camp_counter = 0 
local vacated_time = 0

-- Think that checks if neutral creeps are close to spawner entities

function OnTriggerThink_Timer()
	camp_counter = 0
	local count = Entities:FindAllByClassnameWithin( "npc_dota_creature", thisEntity:GetAbsOrigin(), 900 )

	for _,entity in pairs(count) do
		if string.match(thisEntity:GetName(), entity:GetUnitName()) then
			camp_counter = camp_counter + 1
		end
	end
	if camp_counter == 0 then
		if vacated_time == 0 then
			vacated_time = GameRules:GetGameTime()
		end

	else
		vacated_time = 0
		return 30
	end

	if vacated_time > 0 and GameRules:GetGameTime() > vacated_time + 30 then
		local unit  = CreateUnitByName(thisEntity:GetName(), thisEntity:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS)
		unit.vSpawn = thisEntity:GetOrigin()
		SpawnBuff(unit)
	end
	--print(camp_counter)
	return 30
end


thisEntity:SetThink( "OnTriggerThink_Timer", 30 )

function SpawnBuff(unit)	
		local hp = 1
		local dmg = 1
		if string.match(GetMapName(),"1x10") then
			hp = 1
			dmg = 1
		elseif string.match(GetMapName(),"2x20") then
			hp = 3
			dmg = 3
		elseif string.match(GetMapName(),"3x21") then
			hp = 4
			dmg = 4
		elseif string.match(GetMapName(),"5x20") then
			hp = 5
			dmg = 5
		end
		--local tmp = GameRules:GetGameTime()/1200
		unit:SetMaxHealth(unit:GetMaxHealth() * hp)
		unit:SetBaseMaxHealth(unit:GetBaseMaxHealth() * hp)
		unit:SetHealth(unit:GetHealth() * hp)
		unit:SetBaseDamageMin(unit:GetBaseDamageMin() * dmg)	
		unit:SetBaseDamageMax(unit:GetBaseDamageMax() * dmg)
end