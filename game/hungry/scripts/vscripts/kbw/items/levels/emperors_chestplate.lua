local sPath = "kbw/items/levels/emperors_chestplate"
LinkLuaModifier( 'm_item_emperors_chestplate_stats', sPath, 0 )
LinkLuaModifier( 'm_item_emperors_chestplate_buff', sPath, 0 )
LinkLuaModifier( 'm_item_emperors_chestplate', sPath, 0 )

base = {}

function base:OnSpellStart()
	if IsServer() then
		local Modifier = self:GetParent():FindModifierByName( "m_item_emperors_chestplate" ) 
		
		if Modifier and Modifier:GetStackCount() > 0 then
			self:GetCaster():AddNewModifier( self:GetCaster(), self, 'm_item_emperors_chestplate_buff', {duration = self:GetSpecialValueFor('duration_buff')}):SetStackCount(Modifier:GetStackCount())	
			
			Modifier:SetStackCount(0)
			
			for _, timer in pairs( Modifier.timers ) do
				timer:Destroy()
			end			
		end
	end
end

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_emperors_chestplate_stats = 0,
		m_item_emperors_chestplate = self.nLevel,
    }
end

CreateLevels({
    'item_emperors_chestplate',
    'item_emperors_chestplate_2',
    'item_emperors_chestplate_3',
}, base )

m_item_emperors_chestplate_stats = ModifierClass{
    bMultiple = true,
    bHidden = true,
    bPermanent = true,
}

function m_item_emperors_chestplate_stats:OnCreated()
    ReadAbilityData( self, {
        bonus_armor = 'bonus_armor',
		bonus_hp_regen = 'bonus_hp_regen',
		bonus_mag_resist = 'bonus_mag_resist',
    })
end

function m_item_emperors_chestplate_stats:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function m_item_emperors_chestplate_stats:GetModifierMagicalResistanceBonus()
	return self.bonus_mag_resist
end

function m_item_emperors_chestplate_stats:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function m_item_emperors_chestplate_stats:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen
end

m_item_emperors_chestplate = ModifierClass{
    bPermanent = true,
}

function m_item_emperors_chestplate:GetTexture( tData )
	return self:GetAbility():GetName()
end

function m_item_emperors_chestplate:OnCreated()
    ReadAbilityData( self, {
        gold_per_stack = 'gold_per_stack',
		xp_per_stack = 'xp_per_stack',
		need_damage_per_stack = 'need_damage_per_stack',
		max_stacks = 'max_stacks',
		duration_stuck = 'duration_stuck',
    })
	
	if IsServer() then
		self.timers = {}
		self.damage = 0
		self:RegisterSelfEvents()
	end	
end

function m_item_emperors_chestplate:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_emperors_chestplate:OnParentTakeDamage( tEvent )
	if self:GetStackCount() >= self.max_stacks then return end
	local attacker = tEvent.attacker
	local caster = self:GetCaster()

	if not attacker then return end
	if not caster then return end

	if caster:GetTeamNumber() == attacker:GetTeamNumber() then return end
	
	local Modifier = caster:FindModifierByName( "m_item_emperors_chestplate_buff" )
	
	if Modifier ~= nil then return end
	
	self.damage = self.damage + tEvent.damage

	while self.damage > self.need_damage_per_stack and self:GetStackCount() < self.max_stacks do
		self.damage = self.damage - self.need_damage_per_stack
		self:IncrementStackCount()
		
		local gold = self.gold_per_stack
		local xp = self.xp_per_stack 	
		
		ModifyExperienceFiltered(caster, xp)
		local nDisplay = GameRules:ModifyGoldFiltered(caster:GetPlayerOwnerID(), gold, true, 0)

		local hPlayer = caster:GetPlayerOwner()
		if hPlayer then
			SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, caster, nDisplay, hPlayer )
		end

		local mod = self
		local timer = Timer( mod.duration_stuck, function()
			if exist( self ) then
				self:DecrementStackCount()
			end
			
			return nil
		end)

		table.insert( self.timers, timer )
	end	
end

function m_item_emperors_chestplate:GetTexture()
	return self:GetAbility():GetName()
end

m_item_emperors_chestplate_buff = ModifierClass{

}

function m_item_emperors_chestplate_buff:GetTexture( tData )
	return self:GetAbility():GetName()
end

function m_item_emperors_chestplate_buff:OnCreated()
    ReadAbilityData( self, {
		armor_per_stack = 'armor_per_stack',
		mag_resist_per_stack = 'mag_resist_per_stack',
		hp_regen_per_stack = 'hp_regen_per_stack',
    })
end

function m_item_emperors_chestplate_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function m_item_emperors_chestplate_buff:GetModifierMagicalResistanceBonus()
	return self.mag_resist_per_stack * self:GetStackCount()
end

function m_item_emperors_chestplate_buff:GetModifierPhysicalArmorBonus()
    return self.armor_per_stack * self:GetStackCount()
end

function m_item_emperors_chestplate_buff:GetModifierConstantHealthRegen()
	return self.hp_regen_per_stack * self:GetStackCount()
end

function m_item_emperors_chestplate_buff:GetTexture()
	return self:GetAbility():GetName()
end