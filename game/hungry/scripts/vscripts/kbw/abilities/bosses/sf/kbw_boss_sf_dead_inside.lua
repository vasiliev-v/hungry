kbw_boss_sf_dead_inside = class{}
LinkLuaModifier( "m_kbw_boss_sf_dead_inside","kbw/abilities/bosses/sf/kbw_boss_sf_dead_inside", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "m_kbw_boss_sf_dead_inside_debuff","kbw/abilities/bosses/sf/kbw_boss_sf_dead_inside", LUA_MODIFIER_MOTION_NONE )

function kbw_boss_sf_dead_inside:GetIntrinsicModifierName()
	return "m_kbw_boss_sf_dead_inside"
end

m_kbw_boss_sf_dead_inside = class{}

function m_kbw_boss_sf_dead_inside:IsHidden()
	return true
end

function m_kbw_boss_sf_dead_inside:OnCreated( tData )
	ReadAbilityData( self, {
		radius = 'radius',
	})
end

function m_kbw_boss_sf_dead_inside:IsAura() return true end

function m_kbw_boss_sf_dead_inside:GetModifierAura()
	return "m_kbw_boss_sf_dead_inside_debuff"
end

function m_kbw_boss_sf_dead_inside:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function m_kbw_boss_sf_dead_inside:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function m_kbw_boss_sf_dead_inside:GetAuraDuration()
	return 0.4
end

function m_kbw_boss_sf_dead_inside:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD 
end

function m_kbw_boss_sf_dead_inside:GetAuraRadius()
	return self.radius
end

m_kbw_boss_sf_dead_inside_debuff = class{}

function m_kbw_boss_sf_dead_inside_debuff:IsDebuff()
    return true
end

function m_kbw_boss_sf_dead_inside_debuff:OnCreated( tData )
	ReadAbilityData( self, {
		bonus_damage_pct = 'bonus_damage_pct',
		bonus_armor_pct = 'bonus_armor_pct',
	})
end

function m_kbw_boss_sf_dead_inside_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_kbw_boss_sf_dead_inside_debuff:GetModifierPhysicalArmorBonus( params )
	if self.bonus_armor_pct then
		return -((self:GetParent():GetPhysicalArmorBaseValue() / 100) * self.bonus_armor_pct)
	else 
		return 0
	end
end

function m_kbw_boss_sf_dead_inside_debuff:GetModifierDamageOutgoing_Percentage( params )
	if self.bonus_damage_pct then
		return -self.bonus_damage_pct
	else
		return 0
	end
end