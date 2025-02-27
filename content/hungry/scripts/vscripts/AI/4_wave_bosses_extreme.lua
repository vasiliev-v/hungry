if IsClient() then return end
require('survival/AIcreeps')

function Spawn(entityKeyValues)
	--print("Spawn")
    thisEntity:SetHullRadius(30) 
	if thisEntity:GetPlayerOwnerID() ~= -1 then
		return
	end
	
	ABILITY_4_wave_death_coil = thisEntity:FindAbilityByName("4_wave_death_coil")
	ABILITY_4_wave_ensnare_extreme = thisEntity:FindAbilityByName("4_wave_ensnare_extreme")
	thisEntity:SetContextThink( "4_wave_think", Think4Wave , 0.1)
end

function Think4Wave()
	if not thisEntity:IsAlive() or thisEntity:IsIllusion() then
		return nil 
	end

	if GameRules:IsGamePaused() then
		return 1
	end

	--AICreepsAttackOneUnit({unit = thisEntity})
	--print(Survival.AICreepCasts)

	if thisEntity:IsStunned() then 
		return 2 
	end
		
	if ABILITY_4_wave_death_coil:IsFullyCastable()  then
		local targets = FindUnitsInRadius(thisEntity:GetTeam(), 
						  thisEntity:GetOrigin(), 
						  nil, 
						  450, 
						  DOTA_UNIT_TARGET_TEAM_ENEMY, 
						  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
						  DOTA_UNIT_TARGET_FLAG_NONE, 
						  FIND_ANY_ORDER, 
						  false)
		if #targets ~= 0 then
			thisEntity:CastAbilityOnTarget(targets[RandomInt(1,#targets)], ABILITY_4_wave_death_coil, -1)
			
		end
	else
		if ABILITY_4_wave_ensnare_extreme:IsFullyCastable()  then
			local targets = FindUnitsInRadius(thisEntity:GetTeam(), 
							  thisEntity:GetOrigin(), 
							  nil, 
							  800, 
							  DOTA_UNIT_TARGET_TEAM_ENEMY, 
							  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
							  DOTA_UNIT_TARGET_FLAG_NONE, 
							  FIND_ANY_ORDER, 
							  false)
			if #targets ~= 0 then
				thisEntity:CastAbilityOnTarget(targets[RandomInt(1,#targets)], ABILITY_4_wave_ensnare_extreme, -1)
				
			end
		end
	end
	
	if thisEntity.vSpawn == nil then
		return 2
	end
	if (thisEntity:GetOrigin() - thisEntity.vSpawn):Length2D() > 600 then
		AttackMove(thisEntity, thisEntity.vSpawn, DOTA_UNIT_ORDER_MOVE_TO_POSITION) 
		return 2
	end
	return 2
end

function AttackMove ( unit, point, order )
	
	Timers:CreateTimer(0.1, function()
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = order,
			Position = point,
			Queue = false,
		})
	end)
end