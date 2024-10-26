kbw_boss_tiny_stun = class{}

require 'lib/modifier_self_events'
LinkLuaModifier( 'm_tiny_boss_stun', "kbw/abilities/bosses/tiny/kbw_boss_tiny_stun", 0 )
LinkLuaModifier( 'm_tiny_boss_stun_debuff', "kbw/abilities/bosses/tiny/kbw_boss_tiny_stun", 0 )

m_tiny_boss_stun_debuff = ModifierClass{
	bHidden = false,
	bPermanent = false,
}

function m_tiny_boss_stun_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_tiny_boss_stun_debuff:OnCreated()
	ReadAbilityData( self, {
		bonus_move_speed_pct = 'bonus_move_speed_pct',
	})
end

function m_tiny_boss_stun_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_move_speed_pct
end

function m_tiny_boss_stun_debuff:IsDebuff()
	return true
end

m_tiny_boss_stun = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function kbw_boss_tiny_stun:GetIntrinsicModifierName()
	return 'm_tiny_boss_stun'
end

function m_tiny_boss_stun:OnCreated( tData )
	ReadAbilityData( self, {
		interval = 'interval',
		radius = 'radius',
		stun_duration = 'stun_duration',
		duration_slow = 'duration_slow',
		damage = 'damage',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_tiny_boss_stun:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_tiny_boss_stun:OnParentAttackLanded( tEvent )
	if self.time and (GameRules:GetGameTime() < self.time + self.interval) then return end
	if self:GetParent():PassivesDisabled() then
		return
	end

	if tEvent.damage_type == DAMAGE_TYPE_PHYSICAL then
		local nTypeFilter = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
		local nFlagFilter = DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()

		local qTargets = FindUnitsInRadius( self:GetParent():GetTeam(), self:GetCaster():GetOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, nTypeFilter, nFlagFilter, FIND_CLOSEST, false )

		local unitsFind = 0

		for _, hTarget in ipairs( qTargets ) do
			if exist( hTarget ) and hTarget:IsAlive() then

				AddModifier('modifier_stunned', {
					hTarget = hTarget,
					hCaster = hCaster,
					hAbility = hAbility,
					duration = self.stun_duration,
				})

				AddModifier('m_tiny_boss_stun_debuff', {
					hTarget = hTarget,
					hCaster = hCaster,
					hAbility = hAbility,
					duration = self.duration_slow,
				})

				ApplyDamage({
					victim = hTarget,
					attacker = hCaster,
					ability = hAbility,
					damage = self.damage,
					damage_type = DAMAGE_TYPE_MAGICAL
				})

				unitsFind = unitsFind + 1
			end
		end

		if unitsFind > 0 then
			self.time = GameRules:GetGameTime()
			self:GetParent():EmitSound("Hero_Leshrac.Split_Earth")
		end
	end
end