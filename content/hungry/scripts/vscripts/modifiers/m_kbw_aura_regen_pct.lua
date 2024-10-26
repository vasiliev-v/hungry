require('kbw/util_spell')
require('kbw/util_c')
m_kbw_aura_regen_pct = ModifierClass{
	bPermanent = true,
	bHidden = true,
	bMultiple = true,
}

function m_kbw_aura_regen_pct:OnCreated()
	ReadAbilityData(self, {
		'regen',
		'radius',
	})
end

function m_kbw_aura_regen_pct:IsAura()
	return self:GetCaster() == self:GetParent()
end
function m_kbw_aura_regen_pct:GetModifierAura()
	return 'm_kbw_aura_regen_pct'
end
function m_kbw_aura_regen_pct:GetAuraRadius()
	return self.radius
end
function m_kbw_aura_regen_pct:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function m_kbw_aura_regen_pct:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function m_kbw_aura_regen_pct:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end
function m_kbw_aura_regen_pct:GetAuraEntityReject(hUnit)
	return hUnit == self:GetCaster()
end

function m_kbw_aura_regen_pct:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function m_kbw_aura_regen_pct:GetModifierConstantHealthRegen()
	return self:GetCaster():GetMaxHealth() * self.regen / 100
end