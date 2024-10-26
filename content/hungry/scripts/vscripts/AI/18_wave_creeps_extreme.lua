if IsClient() then return end
require('survival/AIcreeps')

function Spawn(entityKeyValues)
	--print("Spawn")
    thisEntity:SetHullRadius(30) 
	if thisEntity:GetPlayerOwnerID() ~= -1 then
		return
	end
	
	ABILITY_18_wave_silence = thisEntity:FindAbilityByName("18_wave_silence_extreme")
	thisEntity:SetContextThink( "AIThink", AIThink , 0.1)
end

function AIThink()
	if not thisEntity:IsAlive() or thisEntity:IsIllusion() then
		return nil 
	end

	if GameRules:IsGamePaused() then
		return 1
	end

	--AICreepsAttackOneUnit({unit = thisEntity})
	--print(LiA.AICreepCasts)
		
	if thisEntity:IsStunned() then 
		return 2 
	end

	if ABILITY_18_wave_silence:IsFullyCastable()  then
		local targets = FindUnitsInRadius(thisEntity:GetTeam(), 
						  thisEntity:GetOrigin(), 
						  nil, 
						  450, 
						  DOTA_UNIT_TARGET_TEAM_ENEMY, 
						  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
						  DOTA_UNIT_TARGET_FLAG_MANA_ONLY, 
						  FIND_ANY_ORDER, 
						  false)
		--print(#targets)
		for k,unit in pairs(targets) do 
			if unit:HasModifier("modifier_18_wave_silence") then 
				table.remove(targets,k)
			end 
		end 
		
		if #targets ~= 0 then
			thisEntity:CastAbilityOnTarget(targets[RandomInt(1,#targets)], ABILITY_18_wave_silence, -1)
			
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