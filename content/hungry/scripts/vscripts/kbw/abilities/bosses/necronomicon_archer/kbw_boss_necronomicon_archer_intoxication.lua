kbw_boss_necronomicon_archer_intoxication = class{}

require 'lib/modifier_self_events'

LinkLuaModifier( 'm_kbw_boss_necronomicon_archer_intoxication', "kbw/abilities/bosses/necronomicon_archer/kbw_boss_necronomicon_archer_intoxication", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_kbw_boss_necronomicon_archer_intoxication_debuff', 'kbw/abilities/bosses/necronomicon_archer/kbw_boss_necronomicon_archer_intoxication', LUA_MODIFIER_MOTION_NONE )

function kbw_boss_necronomicon_archer_intoxication:GetIntrinsicModifierName()
	return 'm_kbw_boss_necronomicon_archer_intoxication'
end


m_kbw_boss_necronomicon_archer_intoxication = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = false,
}

function m_kbw_boss_necronomicon_archer_intoxication:OnCreated( tData )
	ReadAbilityData( self, {
		duration_debuff = 'duration_debuff',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_boss_necronomicon_archer_intoxication:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_boss_necronomicon_archer_intoxication:OnParentDealDamage( tEvent )
	if exist( tEvent.unit ) and tEvent.unit:IsAlive() then
		if tEvent.damage_type == DAMAGE_TYPE_PHYSICAL then
			local modifier = tEvent.unit:AddNewModifier( self:GetCaster(), self:GetAbility(), 'm_kbw_boss_necronomicon_archer_intoxication_debuff', {
				duration = self.duration_debuff,
			})
		end
	end
end

m_kbw_boss_necronomicon_archer_intoxication_debuff = ModifierClass{
	bHidden = false,
	bPermanent = false,
}

function m_kbw_boss_necronomicon_archer_intoxication_debuff:IsPurgable()
	return true
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:IsDebuff()
	return true
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:OnCreated( tData )
	ReadAbilityData( self, {
		damage_pct_per_second = 'damage_pct_per_second',
		bonus_move_speed_pct = 'bonus_move_speed_pct',
		bonus_attack_speed = 'bonus_attack_speed',
		interval = 'interval',
	})

	if IsServer() then
		self.timer = Timer( self.interval, function()
			local damage = (self:GetParent():GetMaxHealth() / 100 * self.damage_pct_per_second)
				
			ApplyDamage({
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL
			})	
			
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), damage, nil)
			
			return self.interval
		end )	

		self.nParticleIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_viper/viper_nethertoxin_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())	
	end	
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:OnDestroy()
	if IsServer() then
		self.timer:Destroy()
		
		ParticleManager:DestroyParticle(self.nParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(self.nParticleIndex)			
	end
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:DestroyOnExpire()
	return true
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_move_speed_pct
end

function m_kbw_boss_necronomicon_archer_intoxication_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end