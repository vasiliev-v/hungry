local PATH = "kbw/items/vanguard"

-- item

item_kbw_vanguard = class{}

function item_kbw_vanguard:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_kbw_vanguard:GetMultModifiers()
	return {
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_kbw_vanguard_block = 0,
	}
end

function item_kbw_vanguard:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('shield_duration')
	
	AddModifier('m_item_kbw_vanguard_shield', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:EmitSound('Item.CrimsonGuard.Cast')
end

-- modifier: passive block

LinkLuaModifier('m_item_kbw_vanguard_block', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_vanguard_block = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_kbw_vanguard_block:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_kbw_vanguard_block:OnRefresh(t)
	ReadAbilityData(self, {
		'block_type',
		'block',
		'block_chance',
		'block_return',
		'shield_chance',
	})
	
	if self.block_type == 0 then
		self.condition = function(t)
			return t.damage_type == DAMAGE_TYPE_PHYSICAL and t.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK
		end
	elseif self.block_type == 1 then
		self.condition = function(t)
			return t.damage_type == DAMAGE_TYPE_MAGICAL
		end
	else
		self.condition = function(t)
			return true			
		end
	end
end

function m_item_kbw_vanguard_block:DeclareFunctions(t)
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
	}
end

function m_item_kbw_vanguard_block:GetModifierTotal_ConstantBlock(t)
	if self.condition(t) then
		local chance = self.block_chance
		if self.shield_chance > 0 then
			local shield = t.target:FindModifierByName('m_item_kbw_vanguard_shield')
			if shield and shield:GetAbility() == self:GetAbility() then
				chance = self.shield_chance
			end
		end
	
		if RandomFloat(0, 100) <= chance then
			if self.block_return > 0 then
				local buff =  AddModifier('m_damage_pct', {
					hTarget = t.target,
					hCaster = t.target,
					hAbility = self:GetAbility(),
					nDamage = self.block_return - 100,
				})
				
				t.target:PerformAttack(t.attacker, true, true, true, true, false, false, false)
				
				if buff then
					buff:Destroy()
				end
			end 
		
			return self.block
		end
	end
end

-- modifier: shield buff

LinkLuaModifier('m_item_kbw_vanguard_shield', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_vanguard_shield = ModifierClass{
	bPurgable = true,
	bMultiple = true,
}

function m_item_kbw_vanguard_shield:OnCreated(t)
	ReadAbilityData(self, {
		'shield_type',
		'shield_health',
		'shield_linger',
		'shield_mana_pct',
		'shield_chance',
		maximal = true,
	})
	
	if self.shield_type == 0 then
		self.shield_condition = function(t)
			return t.damage_type == DAMAGE_TYPE_PHYSICAL
		end
	elseif self.shield_type == 1 then
		self.shield_condition = function(t)
			return t.damage_type == DAMAGE_TYPE_MAGICAL
		end
	else
		self.shield_condition = function(t)
			return true
		end
	end
	
	if IsServer() then
		local parent = self:GetParent()
		
		self:SetHealth(math.max(self.health or 0, self.shield_health))
		
		if self.shield_type == 0 then
			self.particle = ParticleManager:Create('particles/items2_fx/vanguard_active.vpcf', PATTACH_CUSTOMORIGIN, parent)
			ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
			ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
		elseif self.shield_type == 1 then
			if self.shield_linger == 0 then
				self.particle = ParticleManager:Create('particles/items2_fx/pipe_of_insight.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
				ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
				ParticleManager:SetParticleControl(self.particle, 2, Vector(228, 0, 0))
			else
				self.particle = ParticleManager:Create('particles/items2_fx/eternal_shroud.vpcf', PATTACH_CUSTOMORIGIN, parent)
				ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), false)
				ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), false)
				ParticleManager:SetParticleControl(self.particle, 2, Vector(128, 0, 0))
			end
		else
			self.particle = ParticleManager:Create('particles/items/shield2.vpcf', PATTACH_CUSTOMORIGIN, parent)
			ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', parent:GetOrigin(), false)
			ParticleManager:SetParticleControl(self.particle, 1, Vector(115,0,0))
		end
		
		if self.shield_chance > 0 then
			self.particle2 = ParticleManager:Create('particles/econ/items/spectre/spectre_arcana/spectre_arcana_blademail_v2.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		end		
	end
end

function m_item_kbw_vanguard_shield:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

function m_item_kbw_vanguard_shield:OnDestroy()
	if IsServer() then
		if self.particle then
			ParticleManager:Fade(self.particle, true)
			self.particle = nil
		end
		if self.particle2 then
			ParticleManager:Fade(self.particle2, true)
			self.particle2 = nil
		end
	end
end

function m_item_kbw_vanguard_shield:SetHealth(health)
	health = math.max(0, health)

	if self.health and self.health > 0 and health <= 0 then
		if self.shield_linger > 0 then
			local rem = self:GetRemainingTime()
			if self.shield_linger < rem then
				self:SetDuration(self.shield_linger, true)
			end
		else
			self:Destroy()
		end
		
		local parent = self:GetParent()
		
		local particle = ParticleManager:Create('particles/items/shield_break.vpcf', PATTACH_CUSTOMORIGIN, parent, 1)
		ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)
		ParticleManager:SetParticleControl(particle, 1, Vector(350,0,0))
		if self.shield_type == 0 then
			ParticleManager:SetParticleControl(particle, 18, Vector(0,0,0))
		elseif self.shield_type == 1 then
			ParticleManager:SetParticleControl(particle, 18, Vector(0.45,0,0))
		else
			ParticleManager:SetParticleControl(particle, 18, Vector(0.15,0,0))
		end
		
		parent:EmitSound('KBW.Item.Vanguard.Break')
	end
	
	self.health = health
	self:SetStackCount(math.floor(health))
end

function m_item_kbw_vanguard_shield:DeclareFunctions(t)
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
	}
end

function m_item_kbw_vanguard_shield:GetModifierTotal_ConstantBlock(t)
	if self.shield_condition(t) then
		if IsServer() then
			local block = math.min(self.health, t.damage)
		
			self:SetHealth(self.health - block)
		
			if self.shield_linger > 0 then
				block = t.damage
			end

			if self.shield_mana_pct > 0 then
				local parent = self:GetParent()
				local mana = block * self.shield_mana_pct / 100
				
				parent:GiveMana(mana)
			end

			return block
		else
			return t.damage
		end
	end
end