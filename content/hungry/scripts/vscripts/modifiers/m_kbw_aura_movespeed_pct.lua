require('kbw/util_spell')
require('kbw/util_c')
m_kbw_aura_movespeed_pct = ModifierClass{
	bPermanent = true,
	bHidden = true,
	bMultiple = true,
}

function m_kbw_aura_movespeed_pct:OnCreated()
	ReadAbilityData(self, {
		'speed',
		'radius',
	})
end

function m_kbw_aura_movespeed_pct:IsAura()
	return self:GetCaster() == self:GetParent()
end
function m_kbw_aura_movespeed_pct:GetModifierAura()
	return 'm_kbw_aura_movespeed_pct'
end
function m_kbw_aura_movespeed_pct:GetAuraRadius()
	return self.radius
end
function m_kbw_aura_movespeed_pct:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function m_kbw_aura_movespeed_pct:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end
function m_kbw_aura_movespeed_pct:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end
function m_kbw_aura_movespeed_pct:GetAuraEntityReject(hUnit)
	return hUnit == self:GetCaster()
end

function m_kbw_aura_movespeed_pct:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_kbw_aura_movespeed_pct:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end