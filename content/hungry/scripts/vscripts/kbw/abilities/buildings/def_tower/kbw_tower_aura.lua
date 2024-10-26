local sPath = "kbw/abilities/buildings/def_tower/kbw_tower_aura"
LinkLuaModifier('m_kbw_tower_aura', sPath, 0)
LinkLuaModifier('m_kbw_tower_aura_debuff', sPath, 0)

kbw_tower_aura = class{}

function kbw_tower_aura:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor('radius')
end

function kbw_tower_aura:GetIntrinsicModifierName()
	return 'm_kbw_tower_aura'
end

m_kbw_tower_aura = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_tower_aura:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {'radius', 'duration'})
		self.hParent = self:GetParent()
		self.hAbility = self:GetAbility()
		self:StartIntervalThink(0.1)
	end
end

function m_kbw_tower_aura:OnIntervalThink()
	if self.hParent:PassivesDisabled() then
		return
	end
	
	local qUnits = Find:UnitsInRadius({
		vCenter = self.hParent,
		nRadius = self.radius,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	})

	for _, hUnit in ipairs(qUnits) do
		hUnit:AddNewModifier(self.hParent, self.hAbility, 'm_kbw_tower_aura_debuff', {
			duration = self.duration,
		})
	end
end

m_kbw_tower_aura_debuff = ModifierClass{
}

function m_kbw_tower_aura_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function m_kbw_tower_aura_debuff:GetDisableHealing()
	return 1
end