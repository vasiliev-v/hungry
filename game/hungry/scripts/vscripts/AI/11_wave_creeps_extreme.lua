if IsClient() then return end
require('survival/AIcreeps')

function Spawn(entityKeyValues)
	--print("Spawn")
    thisEntity:SetHullRadius(30) 
	if thisEntity:GetPlayerOwnerID() ~= -1 then
		return
	end
	
	ABILITY_11_wave_immolation = thisEntity:FindAbilityByName("11_wave_immolation_extreme")
	thisEntity:SetContextThink( "AIThink", AIThink , 0.1)
end

function AIThink()
	if not thisEntity:IsAlive() or thisEntity:IsIllusion() then
		return nil 
	end

	if GameRules:IsGamePaused() then
		return 1
	end

	if thisEntity:IsStunned() then 
		return 2 
	end

	--AICreepsAttackOneUnit({unit = thisEntity})
	--print(Survival.AICreepCasts)
	local targets = FindUnitsInRadius(thisEntity:GetTeam(), 
						  thisEntity:GetOrigin(), 
						  nil, 
						  200, 
						  DOTA_UNIT_TARGET_TEAM_ENEMY, 
						  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
						  DOTA_UNIT_TARGET_FLAG_NONE, 
						  FIND_ANY_ORDER, 
						  false)

	local abilityToggleState = ABILITY_11_wave_immolation:GetToggleState()

	if #targets > 0 then
		if ABILITY_11_wave_immolation:IsFullyCastable()  and not abilityToggleState then
			thisEntity:CastAbilityToggle(ABILITY_11_wave_immolation, -1)
			
		end
	elseif abilityToggleState then
		thisEntity:CastAbilityToggle(ABILITY_11_wave_immolation, -1)
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