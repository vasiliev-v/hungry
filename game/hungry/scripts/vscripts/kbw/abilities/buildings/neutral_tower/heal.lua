LinkLuaModifier('m_watchtower_heal', "kbw/abilities/buildings/neutral_tower/heal", 0)
LinkLuaModifier('m_watchtower_heal_effect', "kbw/abilities/buildings/neutral_tower/heal", 0)

watchtower_heal = class{}

function watchtower_heal:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function watchtower_heal:GetIntrinsicModifierName()
	return 'm_watchtower_heal'
end

m_watchtower_heal = class{}

function m_watchtower_heal:IsHidden()
	return true
end

function m_watchtower_heal:OnCreated()
	ReadAbilityData( self, {'radius'})
end

function m_watchtower_heal:IsAura()
	return true
end

function m_watchtower_heal:GetAuraDuration()
	return 0.01
end

function m_watchtower_heal:GetModifierAura()
	return 'm_watchtower_heal_effect'
end

function m_watchtower_heal:GetAuraRadius()
	return self.radius
end

function m_watchtower_heal:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function m_watchtower_heal:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING
end

function m_watchtower_heal:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

m_watchtower_heal_effect = class{}

function m_watchtower_heal_effect:IsDebuff()
	return false
end

function m_watchtower_heal_effect:IsPurgable()
	return false
end

function m_watchtower_heal_effect:IsPurgeException()
	return false
end

function m_watchtower_heal_effect:OnCreated()
	ReadAbilityData( self, {'self_heal_pct', 'ally_heal_pct', 'ally_mana_pct'})
end

function m_watchtower_heal_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
	}
end

function m_watchtower_heal_effect:GetModifierHealthRegenPercentage()
	return self:GetParent() == self:GetCaster() and self.self_heal_pct or self.ally_heal_pct
end

function m_watchtower_heal_effect:GetModifierConstantManaRegen()
	return self:GetParent():GetMaxMana() * self.ally_mana_pct / 100
end