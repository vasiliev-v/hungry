LinkLuaModifier('m_custom_truesight_effect', 'kbw/modifiers/m_custom_truesight', 0)
require('kbw/util_spell')
require('kbw/util_c')
m_custom_truesight = class{
	bMultiple = true,
	bPermanent = true,
}

function m_custom_truesight:IsHidden()
	return true
end

function m_custom_truesight:IsAura()
	return true
end

function m_custom_truesight:GetModifierAura()
	return 'modifier_truesight'
end

function m_custom_truesight:GetAuraRadius()
	return self.radius
end

function m_custom_truesight:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function m_custom_truesight:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function m_custom_truesight:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function m_custom_truesight:OnCreated(t)
	if IsServer() then
		self.radius = t.radius or 0
	end
end