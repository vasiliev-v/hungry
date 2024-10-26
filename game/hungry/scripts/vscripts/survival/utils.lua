function Survival:GetHeroCount(bOnlyAlive)
	local count = 0
	for _,hero in pairs(self.tHeroes) do
		if not hero.hidden and (not bOnlyAlive or hero:IsAlive() or hero:IsReincarnating()) then  
			count = count + 1
		end
	end
	return count
end

function DoWithAllHeroes(whatDo)
	if type(whatDo) ~= "function" then
		print("DoWithAllHeroes:not func")
		return
	end
	for i = 0, DOTA_MAX_PLAYERS-1 do
        if PlayerResource:IsValidTeamPlayerID(i) then
            if PlayerResource:IsValidPlayerID(i) then
                whatDo(PlayerResource:GetSelectedHeroEntity(i))
            end
        end
    end

end

function ChangeWorldBounds(vMax,vMin)
	local oldBounds = Entities:FindByClassname(nil, "world_bounds")
	if oldBounds then 
		oldBounds:RemoveSelf()
	end

	SpawnEntityFromTableSynchronous("world_bounds", {Max = vMax, Min = vMin})
end


function FindClearSpaceForUnit_IgnoreNeverMove(unit,position,useInterp)
	if unit.neverMoveToClearSpace then
		unit:SetNeverMoveToClearSpace(false)
	end
 	
 	FindClearSpaceForUnit(unit,position,useInterp)
	
 	if unit.neverMoveToClearSpace then
		unit:SetNeverMoveToClearSpace(true)
	end
end

function CDOTA_BaseNPC:ManaBurn(hCaster, hAbility, fManaAmount, fDamagePerMana, iDamageType, bAffectedByManaLossReduction)
	if bAffectedByManaLossReduction then
		fManaAmount = fManaAmount * (100 - self:GetManaLossReductionPercentage()) * 0.01
	end

	local fCurrentMana = self:GetMana()
	if fCurrentMana < fManaAmount then
		fManaAmount = fCurrentMana
	end

	self:Script_ReduceMana(fManaAmount, nil)
	if fDamagePerMana and iDamageType then
		local fDamageToDeal = fManaAmount * fDamagePerMana
		ApplyDamage({ victim = self, attacker = hCaster, damage = fDamageToDeal, damage_type = iDamageType, ability = hAbility })
	end 
end

function CDOTA_BaseNPC:GetManaLossReductionPercentage()
	local mana_loss_reduction = 0
	local mana_loss_reduction_unique = 0
	for _, parent_modifier in pairs(self:FindAllModifiers()) do

		if parent_modifier.GetCustomManaLossReductionPercentageUnique then
			mana_loss_reduction_unique = math.max(mana_loss_reduction_unique, parent_modifier:GetCustomManaLossReductionPercentageUnique())
		end

		if parent_modifier.GetCustomManaLossReductionPercentage then
			mana_loss_reduction = mana_loss_reduction + parent_modifier:GetCustomManaLossReductionPercentage()
		end
	end

	mana_loss_reduction = mana_loss_reduction + mana_loss_reduction_unique

	return mana_loss_reduction
end

function fireLeftNotify(pid, bSameTeam,msg, data)

    local team=-1
    if bSameTeam then
        local pdata=PlayerResource:GetPlayer(pid)
        if pdata then
            team=pdata:GetTeamNumber()
        end
        
    end
    local gameEvent = {}
    gameEvent["player_id"] = pid
    gameEvent["teamnumber"] = team
    gameEvent["player_id2"] = data.pid2
    gameEvent["value"] = data.float0
    gameEvent["value1"] = data.float1
    gameEvent["value2"] = data.float2
    gameEvent["value3"] = data.float3
    gameEvent["int_value"] = data.int1
    gameEvent["int_value2"] = data.int2
    gameEvent["ability_name"] = data.ability
    gameEvent["locstring_value"] = data.str1
    gameEvent["locstring_value2"] = data.str2
    --
    gameEvent["message"] = msg
    --
    FireGameEvent("dota_combat_event_message", gameEvent)
end