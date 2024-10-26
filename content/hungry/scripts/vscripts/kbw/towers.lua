if towers == nil then
	towers = class({})
end

LinkLuaModifier( "towerM", self:Path("modifiers/towerm"), LUA_MODIFIER_MOTION_NONE )

function towers:Init()
	local units = Entities:FindAllByClassname("npc_dota_tower")
	
	for _,unit in pairs(units) do
		if (unit:GetUnitName() == "npc_dota_custom_tower") then
			unit.BaseDamage = 130
			unit.BaseHealth = 2000
			
			unit:SetBaseDamageMin(unit.BaseDamage)
			unit:SetBaseDamageMax(unit.BaseDamage)
			
			unit:SetMaxHealth(unit.BaseHealth)
			unit:SetBaseMaxHealth(unit.BaseHealth)
			unit:SetHealth(unit.BaseHealth)		

			unit.level = 0
			
			unit:SetTeam(4)
			
			unit:Purge( true, true, false, true, true )	
			ProjectileManager:ProjectileDodge( unit )			
			
			unit:RemoveAbility('backdoor_protection')
			unit:RemoveAbility('backdoor_protection_in_base')			
			
			for _, modifier in pairs( unit:FindAllModifiers() ) do
				if modifier:GetName() ~= 'gamerules_modifier' and modifier:GetName() ~= 'modifier_invulnerable' then
					local ability = modifier:GetAbility()
					if not ability then
						modifier:Destroy()
					end
				end
			end				
			
			unit:AddNewModifier( unit, nil, 'modifier_truesight_aura', { } ) 
			unit:AddNewModifier(unit, nil, "towerM", nil):SetStackCount(unit.level)
			
			Shrine = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
										  unit:GetAbsOrigin(),
										  nil,
										  500,
										  DOTA_UNIT_TARGET_TEAM_FRIENDLY,
										  DOTA_UNIT_TARGET_BUILDING,
										  DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
										  FIND_ANY_ORDER,
										  false)
										  
										  
			for _,sh in pairs(Shrine) do
				if (sh:GetUnitName() == "npc_dota_goodguys_healers" or sh:GetUnitName() == "npc_dota_badguys_healers") then
					unit.shrine = sh
					sh:SetTeam(4)
				end
			end
		end
	end 
end