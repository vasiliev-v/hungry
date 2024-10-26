local sPath = 'kbw/abilities/bosses/mid/boss_ability_hardcore'

LinkLuaModifier("m_boss_ability_hardcore", sPath, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("m_boss_ability_hardcore_damage", sPath, LUA_MODIFIER_MOTION_NONE)

boss_ability_hardcore = class({})

function boss_ability_hardcore:GetIntrinsicModifierName(  )
	return "m_boss_ability_hardcore"
end

---------------------------------------------

m_boss_ability_hardcore = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_boss_ability_hardcore:OnCreated()
	if IsServer() then
		ReadAbilityData( self, {
			nDuration = 'duration',
			nCreepDamage = 'creep_extra_damage',
		})

		self:RegisterSelfEvents()
	end
end

function m_boss_ability_hardcore:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_boss_ability_hardcore:OnParentAttackLanded( t )
	if IsNPC( t.target ) and t.target:IsAlive() then
		local hParent = self:GetParent()
		local hAbility = self:GetAbility()

		if hParent:PassivesDisabled() then
			return
		end

		local hModifier = t.target:FindModifierByName('m_boss_ability_hardcore_damage')
		local nDuration = self.nDuration * ( 1 - t.target:GetStatusResistance() )

		if not hModifier then
			hModifier = AddModifier( 'm_boss_ability_hardcore_damage', {
				hTarget = t.target,
				hAbility = hAbility,
				hCaster = hParent,
			})
		end

		if hModifier then
			hModifier:SetDuration( nDuration, true )
			hModifier:IncrementStackCount()
			hModifier:ForceRefresh()
		end
	end
end

function m_boss_ability_hardcore:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_boss_ability_hardcore:GetModifierTotalDamageOutgoing_Percentage(t)
	if not t.target:IsRealHero() and not self:GetParent():PassivesDisabled() then
		return self.nCreepDamage
	end
end

-------------------------

m_boss_ability_hardcore_damage = ModifierClass{}

function m_boss_ability_hardcore_damage:GetTexture()
	return "boss_ability_hardcore"
end

function m_boss_ability_hardcore_damage:OnCreated()
	ReadAbilityData( self, {
		nDamagePct = 'damage_pct',
	})
end

function m_boss_ability_hardcore_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function m_boss_ability_hardcore_damage:GetModifierIncomingDamage_Percentage()
	return self:GetStackCount() * ( self.nDamagePct or 0 )
end