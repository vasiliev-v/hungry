kbw_boss_tiny_craggy_exterior = class{}

require 'lib/modifier_self_events'
LinkLuaModifier( 'm_tiny_boss_craggy_exterior', "kbw/abilities/bosses/tiny/kbw_boss_tiny_craggy_exterior", 0 )

m_tiny_boss_craggy_exterior = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function kbw_boss_tiny_craggy_exterior:GetIntrinsicModifierName()
	return 'm_tiny_boss_craggy_exterior'
end

function m_tiny_boss_craggy_exterior:OnCreated( tData )
	ReadAbilityData( self, {
		stun_duration = 'stun_duration',
		stun_chance = 'stun_chance',
		damage = 'damage',
	})

	if IsServer() then
		self:RegisterSelfEvents()

		self.heroesStun = {}
	end
end

function m_tiny_boss_craggy_exterior:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_tiny_boss_craggy_exterior:OnParentTakeAttackLanded(tEvent)
	if exist( tEvent.attacker ) and tEvent.attacker:IsAlive() and not self:GetParent():PassivesDisabled() then
		local unit = tEvent.attacker

		if self.heroesStun[unit] and (GameRules:GetGameTime() < self.heroesStun[unit] + 3) then return end

		if RollPercentage(self.stun_chance) then
			self.heroesStun[unit] = GameRules:GetGameTime()

			AddModifier('modifier_stunned', {
				hTarget = unit,
				hCaster = self:GetCaster(),
				hAbility = self:GetAbility(),
				duration = self.stun_duration,
			})

			ApplyDamage({
				victim = unit,
				attacker = self:GetCaster(),
				damage = self.damage,
				damage_type = DAMAGE_TYPE_MAGICAL
			})

			unit:EmitSound("Hero_Tiny.CraggyExterior.Stun")
		end
	end
end