kbw_boss_necronomicon_archer_rage = class{}

require 'lib/modifier_self_events'

LinkLuaModifier( 'm_kbw_boss_necronomicon_archer_rage', "kbw/abilities/bosses/necronomicon_archer/kbw_boss_necronomicon_archer_rage", 0 )
LinkLuaModifier( 'm_kbw_boss_necronomicon_archer_rage_buff', "kbw/abilities/bosses/necronomicon_archer/kbw_boss_necronomicon_archer_rage", 0 )

function kbw_boss_necronomicon_archer_rage:GetIntrinsicModifierName()
	return 'm_kbw_boss_necronomicon_archer_rage'
end

m_kbw_boss_necronomicon_archer_rage_buff = ModifierClass{
	bHidden = false,
	bPermanent = false,
}

function m_kbw_boss_necronomicon_archer_rage_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function m_kbw_boss_necronomicon_archer_rage_buff:OnCreated()
	ReadAbilityData( self, {
		bonus_pure_damage = 'bonus_pure_damage',
		bonus_damage_pct = 'bonus_damage_pct',
		vampiric = 'vampiric',
		bonus_attack_speed = 'bonus_attack_speed',
	})
	
	if IsServer() then
		self:RegisterSelfEvents()
	end	
end

function m_kbw_boss_necronomicon_archer_rage_buff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_boss_necronomicon_archer_rage_buff:OnParentAttackLanded( tEvent )
	if exist( tEvent.target ) and tEvent.target:IsAlive() then
		local damageTable = {
			victim = tEvent.target,
			attacker = self:GetCaster(),
			damage = self.bonus_pure_damage,
			damage_type = DAMAGE_TYPE_PURE,
			ability = self:GetAbility(),
		}

		ApplyDamage( damageTable )	
	end
	
	local hParent = self:GetParent()
	
	local nHeal = tEvent.damage * self.vampiric / 100
	hParent:Heal( nHeal, self:GetAbility() )

	local nCurTime = GameRules:GetGameTime()
	if not self.nLastParticleTime or self.nLastParticleTime + 0.5 <= nCurTime then
		local sParticle = 'particles/generic_gameplay/generic_lifesteal.vpcf'
		ParticleManager:Create( sParticle, hParent, 2 )

		self.nLastParticleTime = nCurTime
	end	
end

function m_kbw_boss_necronomicon_archer_rage_buff:GetModifierDamageOutgoing_Percentage()
	return self.bonus_damage_pct
end

function m_kbw_boss_necronomicon_archer_rage_buff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function m_kbw_boss_necronomicon_archer_rage_buff:IsDebuff()
	return false
end

m_kbw_boss_necronomicon_archer_rage = ModifierClass{
	bHidden = true,
	bPermanent = false,
}

function m_kbw_boss_necronomicon_archer_rage:OnCreated( tData )
	ReadAbilityData( self, {
		interval = 'interval',
		duration = 'duration',
		need_start_hp_pct = 'need_start_hp_pct',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_boss_necronomicon_archer_rage:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_boss_necronomicon_archer_rage:OnParentAttack( tEvent )
	if self.time and (GameRules:GetGameTime() < self.time + self.interval) then return end

	if self:GetParent():GetHealth() < self:GetParent():GetMaxHealth() and ((self:GetParent():GetHealth() / self:GetParent():GetMaxHealth()) * 100) <= self.need_start_hp_pct then
		self:GetCaster():AddNewModifier( self:GetCaster(), self:GetAbility(), 'm_kbw_boss_necronomicon_archer_rage_buff', {
			duration = self.duration,
		})		

		self:GetParent():EmitSound("DOTA_Item.Satanic.Activate")

		self.time = GameRules:GetGameTime()	
	end
end