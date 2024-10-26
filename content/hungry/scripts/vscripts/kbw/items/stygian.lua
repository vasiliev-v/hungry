local sPath = "kbw/items/stygian"
LinkLuaModifier( 'm_item_kbw_stygian', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_stygian_stats', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_stygian_bash', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_stygian_debuff', sPath, 0 )

item_kbw_stygian = class{}

function item_kbw_stygian:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_kbw_stygian:GetMultModifiers()
	return {
		m_item_kbw_stygian = 1,
		m_item_kbw_stygian_stats = 0,
	}
end

-------------------------------------------------------
-- stats

m_item_kbw_stygian_stats = ModifierClass{
    bHidden = true,
    bMultiple = true,
    bPermanent = true,
}

function m_item_kbw_stygian_stats:OnCreated()
	ReadAbilityData( self, {
		nDamage = 'damage',
		nAttackSpeed = 'attack_speed',
		nStats = 'atr',
	} )
end

function m_item_kbw_stygian_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_item_kbw_stygian_stats:GetModifierPreAttack_BonusDamage()
	return self.nDamage
end
function m_item_kbw_stygian_stats:GetModifierAttackSpeedBonus_Constant()
	return self.nAttackSpeed
end
function m_item_kbw_stygian_stats:GetModifierBonusStats_Strength()
	return self.nStats
end
function m_item_kbw_stygian_stats:GetModifierBonusStats_Agility()
	return self.nStats
end
function m_item_kbw_stygian_stats:GetModifierBonusStats_Intellect()
	return self.nStats
end

-------------------------------------------------------
-- passive

m_item_kbw_stygian = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_stygian:OnCreated()
	ReadAbilityData( self, {
		nDuration = 'duration',
		nProcChance = 'pierce_chance',
		nProcDamage = 'pierce_damage',
	}, function( hAbility )
		self.hAbility = hAbility
	end )

	if IsServer() then
		self.tProcRecords = {}

		self:RegisterSelfEvents()
	end
end

function m_item_kbw_stygian:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_stygian:IsActive()
	return not self:GetParent():NotRealHero()
end

function m_item_kbw_stygian:CheckState()
	if IsServer() then
		if self:IsActive() and RollPercentage(self.nProcChance) then
			self.bProc = true
			return {
				[MODIFIER_STATE_CANNOT_MISS] = true,
			}
		else
			self.bProc = nil
		end
	end

	return {}
end

function m_item_kbw_stygian:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_item_kbw_stygian:GetModifierProjectileName()
	return 'particles/items/skadi/stygian.vpcf'
end

function m_item_kbw_stygian:GetModifierDamageOutgoing_Percentage( t )
	if IsServer() and self:IsActive() and IsNPC( t.target ) then
		local hMod = t.target:FindModifierByNameAndCaster( 'm_item_kbw_stygian_debuff', self:GetParent() )
		if hMod then
			return hMod:OnTooltip2()
		end
	end
end

function m_item_kbw_stygian:OnParentAttackRecord( t )
	if self.bProc and IsNPC( t.target ) then
		-- self.bProc = nil
		self.tProcRecords[ t.record ] = true
	end
end

function m_item_kbw_stygian:OnParentAttackLanded( t )
	if self:IsActive() and t.target.AddAbility then
		local hParent = self:GetParent()

		if self.tProcRecords[ t.record ] then
			self.tProcRecords[ t.record ] = nil

			ApplyDamage({
				victim = t.target,
				attacker = hParent,
				ability = self.hAbility,
				damage = self.nProcDamage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})

			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, t.target, self.nProcDamage, nil)

			t.target:EmitSound('DOTA_Item.MKB.Minibash')
		end

		local hDebuff = t.target:FindModifierByNameAndCaster( 'm_item_kbw_stygian_debuff', hParent )
		local nDuration = self.nDuration * ( 1 - t.target:GetStatusResistance() )

		if hDebuff then
			hDebuff:Stack( nDuration )
		else
			AddModifier( 'm_item_kbw_stygian_debuff', {
				hTarget = t.target,
				hCaster = hParent,
				hAbility = self.hAbility,
				duration = nDuration,
				bIgnoreStatusResist = true,
			})
		end
	end
end

function m_item_kbw_stygian:OnParentAttackFail( t )
	self.tProcRecords[ t.record ] = nil
end

function m_item_kbw_stygian:OnParentAttackCancel( t )
	self.tProcRecords[ t.record ] = nil
end

-------------------------------------------------------
-- bash

m_item_kbw_stygian_bash = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_stygian_bash:GetStatusEffectName()
	return 'particles/status_fx/status_effect_wyvern_cold_embrace.vpcf'
end

function m_item_kbw_stygian_bash:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end

function m_item_kbw_stygian_bash:OnCreated()
	if IsServer() then
		local sParticle = 'particles/generic_gameplay/generic_bashed.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
	end
end

function m_item_kbw_stygian_bash:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
	end
end

-------------------------------------------------------
-- debuff

m_item_kbw_stygian_debuff = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_stygian_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end

function m_item_kbw_stygian_debuff:GetModifierPhysicalArmorBonus()
	return -self.nArmorReduction
end

function m_item_kbw_stygian_debuff:GetModifierAttackSpeedBonus_Constant()
	return -self.nAttackSlow
end

function m_item_kbw_stygian_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -( self.nBaseSlow + ( self:GetStackCount() - 1 ) * self.nSlowInc )
end

function m_item_kbw_stygian_debuff:OnTooltip()
	return self.nHealReduction + self.nHealReductionInc * self:GetStackCount()
end

function m_item_kbw_stygian_debuff:OnTooltip2()
	return self:GetStackCount() * self.nDamageInc
end

function m_item_kbw_stygian_debuff:OnCreated()
	ReadAbilityData( self, {
		nArmorReduction = 'armor_reduction',
		nBaseSlow = 'slow',
		nSlowInc = 'slow_inc',
		nAttackSlow = 'attack_slow',
		nHealReduction = 'heal_reduction',
		nHealReductionInc = 'heal_reduction_inc',
		nDamageInc = 'damage_inc',
		nMaxStacks = 'max_stacks',
	})

	if IsServer() then
		self.hHealAmpModifier = AddSpecialModifier( self:GetParent(), 'nHealAmp', 0 )
		
		self:Stack()
	end
end

function m_item_kbw_stygian_debuff:OnDestroy()
	if IsServer() then
		self.hHealAmpModifier:Destroy()
	end
end

function m_item_kbw_stygian_debuff:Stack( nDuration )
	if self:GetStackCount() < self.nMaxStacks then
		self:IncrementStackCount()
	end

	self.hHealAmpModifier.nValue = -self:OnTooltip()
	CalcSpecialModifierValue(self:GetParent(), 'nHealAmp')

	if nDuration and nDuration > self:GetRemainingTime() then
		self:SetDuration( nDuration, true )
	end
end