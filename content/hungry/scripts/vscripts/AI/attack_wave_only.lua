if IsClient() then return end
require('survival/AIcreeps')

function Spawn(entityKeyValues)
    thisEntity:SetHullRadius(30) 
	if thisEntity:GetPlayerOwnerID() ~= -1 then
		return
	end
	
	thisEntity:SetContextThink( "attack_wave_only", ThinkAllWave , 0.1)
end

function ThinkAllWave()
	if not thisEntity:IsAlive() or thisEntity:IsIllusion() then
		return nil 
	end

	if GameRules:IsGamePaused() then
		return 1
	end

	local radius = 450

	local enemies = FindUnitsInRadius( 
						thisEntity:GetTeamNumber(),		--команда юнита
						thisEntity:GetAbsOrigin(),		--местоположение юнита
						nil,	--айди юнита (необязательно)
						radius,	--радиус поиска
						DOTA_UNIT_TARGET_TEAM_ENEMY,	-- юнитов чьей команды ищем вражеской/дружественной
						DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	--юнитов какого типа ищем 
						DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,	--поиск по флагам
						FIND_CLOSEST,	--сортировка от ближнего к дальнему 
						false )

	local enemy = enemies[1]	-- врагом выбирается первый близжайший
	if thisEntity.vSpawn == nil then
		return 3
	end
	if (thisEntity:GetOrigin() - thisEntity.vSpawn):Length2D() > 600 then
		AttackMove(thisEntity, thisEntity.vSpawn, DOTA_UNIT_ORDER_MOVE_TO_POSITION) 
		print(thisEntity:GetUnitName())
		if string.match(thisEntity:GetUnitName(),"_megaboss") then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf", PATTACH_ABSORIGIN_FOLLOW, nil)
			local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_shadow_wave_impact_damage.vpcf", PATTACH_ABSORIGIN_FOLLOW, nil)
			-- heal and decay
			thisEntity:Heal(1000, thisEntity) 
			-- make the particle shoot to the target
			ParticleManager:SetParticleControl(particle, 1, thisEntity:GetAbsOrigin()) --destination
			ParticleManager:SetParticleControl(particle2, 1, thisEntity:GetAbsOrigin()) --destination	
		end
		return 3
	end
	if enemy ~= nil then
		AttackMove(thisEntity, enemy:GetAbsOrigin(), DOTA_UNIT_ORDER_ATTACK_MOVE)
	end
	
	return 3
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