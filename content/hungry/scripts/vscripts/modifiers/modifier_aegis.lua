LinkLuaModifier("modifier_aegis_buff", "modifiers/modifier_aegis_buff.lua",LUA_MODIFIER_MOTION_NONE)
modifier_aegis = class({})

function modifier_aegis:IsHidden()
	return false
end

function modifier_aegis:GetTexture()
	return "item_aegis"
end

function modifier_aegis:IsPermanent()
	return true
end

function modifier_aegis:IsPurgable()
	return false
end


function modifier_aegis:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_REINCARNATION,
		MODIFIER_EVENT_ON_RESPAWN,
	}

	return funcs
end

function modifier_aegis:OnCreated()
	if IsServer() then
       self.reincarnate_time = 5.0
    end
end


function modifier_aegis:ReincarnateTime()
	
	local nPlayerID
	if self:GetParent().GetPlayerOwnerID then
		nPlayerID = self:GetParent():GetPlayerOwnerID()
	end

	if nPlayerID then
		return nil
	end

	if nPlayerID then
		return self.reincarnate_time
	else
		return nil
	end
end


function modifier_aegis:OnStackCountChanged(old_stack_count)
	if not IsServer() then return end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
end


function modifier_aegis:OnDestroy()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end

end


function modifier_aegis:OnDeath(keys)
	if not IsServer() then return end
	if keys.unit ~= self:GetParent() then return end
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	DebugPrint("parent:GetUnitName()1")
	DebugPrint(parent:GetUnitName())
	if parent:GetUnitName() == "npc_dota_hero_meepo" then
		parent = PlayerResource:GetSelectedHeroEntity(parent:GetPlayerOwnerID())
	end

	if keys.attacker:IsCreep() and not keys.attacker:IsCreepHero() and not string.match(keys.attacker:GetUnitName(), "_megaboss") and 
		(not keys.unit:HasModifier("modifier_zona_summer_debuff") and not keys.unit:HasModifier("modifier_zona_venom_debuff") 
		and not keys.unit:HasModifier("modifier_zona_winter_debuff") and not keys.unit:HasModifier("modifier_zona_water_debuff")) then
		parent:SetTimeUntilRespawn(5) -- (keys.unit:GetDeaths()*2)+20
		return
	end
	
	--

	if Survival:IsReincarnationWork(parent) then return end

	Survival:RefreshAbilityAndItem(parent, {skeleton_king_reincarnation = true})
	if parent:GetUnitName() == "npc_dota_hero_meepo" then
		if parent:GetModifierStackCount("modifier_aegis", parent) > 0 then
			parent:SetModifierStackCount("modifier_aegis",parent, parent:GetModifierStackCount("modifier_aegis", parent)-1)
		else
			parent:RemoveModifierByName("modifier_aegis")
		end
		
	else
		local current_stacks = self:GetStackCount()
		self:SetStackCount(current_stacks - 1)
	end
	self.aegis_respawn = true
	parent:SetRespawnPosition(Survival:RandomLocation(parent))
    parent:SetTimeUntilRespawn( self.reincarnate_time)
end

function modifier_aegis:OnRespawn(event)
	local parent = self:GetParent()
	if not parent or parent:IsNull() or parent ~= event.unit then return end
	
	if not self.aegis_respawn then return end
	self.aegis_respawn = nil

	local respawn_timer_pfx = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_timer.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(respawn_timer_pfx, 1, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(respawn_timer_pfx, 3, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(respawn_timer_pfx)


	local origin = parent:GetAbsOrigin()
	local radius = 700

	local knockback_table = {
		should_stun = 1,
		knockback_duration = 0.5,
		duration = 1,
		knockback_distance = radius,
		knockback_height = 50,
		center_x = origin.x,
		center_y = origin.y,
		center_z = origin.z
	}

	local targets = FindUnitsInRadius(
		parent:GetTeam(), 
		origin, 
		nil, 
		radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _,unit in pairs(targets) do
		unit:AddNewModifier(parent, nil, "modifier_knockback", knockback_table)
	end

	local particle_name = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_aoe.vpcf"
	local pfx = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, parent)
	ParticleManager:SetParticleControl(pfx, 0, origin)
	ParticleManager:SetParticleControl(pfx, 1, origin)
	ParticleManager:SetParticleControl(pfx, 2, Vector(700,0,0))
	ParticleManager:ReleaseParticleIndex(pfx)
	if GameRules:GetGameTime() < 2100 then
        parent:AddNewModifier(parent, nil, "modifier_invulnerable", {Duration = 5})
        parent:AddNewModifier(parent, nil, "modifier_invisible", {Duration = 10})
	--	parent:AddNewModifier(parent, nil, "modifier_aegis_buff", {Duration = 10})
	else
		parent:AddNewModifier(parent, nil, "modifier_invulnerable", {Duration = 1.5})
	--	parent:AddNewModifier(parent, nil, "modifier_aegis_buff", {Duration = 3.5})
	end
	if self:GetStackCount() <= 0 then
		self:Destroy()
	end
end

