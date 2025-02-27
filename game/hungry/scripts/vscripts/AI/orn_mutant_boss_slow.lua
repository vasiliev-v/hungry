if IsClient() then return end
require('survival/AIcreeps')

function Spawn(entityKeyValues)
	--print("Spawn")
    thisEntity:SetHullRadius(30) 
	if thisEntity:GetPlayerOwnerID() ~= -1 then
		return
	end
	
	ABILITY_orn_mutant_boss_slow = thisEntity:FindAbilityByName("orn_mutant_boss_slow")
	thisEntity:SetContextThink( "8_wave_think", Think8Wave , 0.1)
end

function Think8Wave()
	if not thisEntity:IsAlive() or thisEntity:IsIllusion() then
		return nil 
	end

	if GameRules:IsGamePaused() then
		return 1
	end

	if thisEntity:IsStunned() then 
		return 2 
	end

	AICreepsAttackOneUnit({unit = thisEntity})
	--print(Survival.AICreepCasts)
		
	if ABILITY_orn_mutant_boss_slow:IsFullyCastable()  then
		local targets = FindUnitsInRadius(thisEntity:GetTeam(), 
						  thisEntity:GetOrigin(), 
						  nil, 
						  250, 
						  DOTA_UNIT_TARGET_TEAM_ENEMY, 
						  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
						  DOTA_UNIT_TARGET_FLAG_NONE, 
						  FIND_ANY_ORDER, 
						  false)
		if #targets ~= 0 then
			thisEntity:CastAbilityOnTarget(targets[RandomInt(1,#targets)], ABILITY_orn_mutant_boss_slow, -1)
		end
	end
	return 2
end
