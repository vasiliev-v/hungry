local sPath = "kbw/items/chest_of_midas"
LinkLuaModifier( 'm_item_chest_of_midas', sPath, 0 )
LinkLuaModifier( 'm_item_chest_of_midas_passive', sPath, 0 )
LinkLuaModifier( 'm_item_chest_of_midas_counter', sPath, 0 )

item_chest_of_midas = class{}

function item_chest_of_midas:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_chest_of_midas:GetMultModifiers()
	return {
		m_item_chest_of_midas = 0,
		m_item_chest_of_midas_passive = 1,
	}
end


m_item_chest_of_midas = ModifierClass{
    bMultiple = true,
    bHidden = true,
    bPermanent = true,
}

function m_item_chest_of_midas:OnCreated()
    ReadAbilityData( self, {
        bonus_armor = 'bonus_armor',
    })
end

function m_item_chest_of_midas:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function m_item_chest_of_midas:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end


m_item_chest_of_midas_passive = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_chest_of_midas_passive:OnCreated()
    ReadAbilityData( self, {
		xp_creep = 'xp_creep',
		xp_hero = 'xp_hero',
		gold_creep = 'gold_creep',
		gold_hero = 'gold_hero',
		limit_time = 'limit_time',
		limit_attacks = 'limit_attacks',
    })
	
	if IsServer() then
		self:RegisterSelfEvents()
	end	
end

function m_item_chest_of_midas_passive:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_chest_of_midas_passive:OnParentTakeAttackLanded( tEvent )
	local attacker = tEvent.attacker
	local caster = self:GetParent()

	if not attacker then return end
	if not caster then return end

	local hCounter = caster:FindModifierByName('m_item_chest_of_midas_counter')
	if hCounter and hCounter:GetStackCount() >= self.limit_attacks then
		return
	end

	if caster:GetTeamNumber() == attacker:GetTeamNumber() then return end
		
	local gold = self.gold_creep
	local xp = self.xp_creep
		
	if attacker:IsHero() or IsStatBoss(attacker) then
		gold = self.gold_hero
		xp = self.xp_hero
	end

	ModifyExperienceFiltered(caster, xp)
	local nDisplay = GameRules:ModifyGoldFiltered(caster:GetPlayerOwnerID(), gold , true , 0 )
	
	local hPlayer = caster:GetPlayerOwner()
	if hPlayer then
		SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, caster, nDisplay, hPlayer )
	end

	AddModifier('m_item_chest_of_midas_counter', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self:GetAbility(),
		bStacks = true,
		duration = self.limit_time,
	})
end

m_item_chest_of_midas_counter = ModifierClass{
	bIgnoreDeath = true,
}

function m_item_chest_of_midas_counter:OnCreated()
	ReadAbilityData(self, {
		'limit_attacks',
	})
end

function m_item_chest_of_midas_counter:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_item_chest_of_midas_counter:OnTooltip()
	return self.limit_attacks
end