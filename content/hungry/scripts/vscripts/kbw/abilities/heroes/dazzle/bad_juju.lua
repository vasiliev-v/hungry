LinkLuaModifier('m_dazzle_bad_juju', "kbw/abilities/heroes/dazzle/bad_juju", 0)
LinkLuaModifier('m_dazzle_bad_juju_debuff', "kbw/abilities/heroes/dazzle/bad_juju", 0)

dazzle_bad_juju_kbw = class{}

function dazzle_bad_juju_kbw:GetCastRange()
	return self:GetSpecialValueFor('radius')
end

function dazzle_bad_juju_kbw:GetIntrinsicModifierName()
	return 'm_dazzle_bad_juju'
end

m_dazzle_bad_juju = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_dazzle_bad_juju:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_dazzle_bad_juju:OnRefresh(t)
	ReadAbilityData(self, {
		'cooldown_reduction',
		'duration',
		'radius',
	})
end

function m_dazzle_bad_juju:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_dazzle_bad_juju:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
end

function m_dazzle_bad_juju:GetModifierPercentageCooldown()
	return self.cooldown_reduction
end

function m_dazzle_bad_juju:OnParentAbilityFullyCast(t)
	if exist(t.ability) and not t.ability:IsItem() then
		local qUnits = Find:UnitsInRadius({
			nTeam = t.unit:GetTeam(),
			vCenter = t.unit,
			nRadius = self.radius,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		})

		for _, hUnit in ipairs(qUnits) do
			AddModifier('m_dazzle_bad_juju_debuff', {
				hTarget = hUnit,
				hCaster = t.unit,
				hAbility = self:GetAbility(),
				bStacks = true,
				duration = self.duration,
			})
		end
	end
end

m_dazzle_bad_juju_debuff = ModifierClass{
}

function m_dazzle_bad_juju_debuff:GetStatusEffectName()
	return 'particles/status_fx/status_effect_armor_dazzle.vpcf'
end

function m_dazzle_bad_juju_debuff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/units/heroes/hero_dazzle/dazzle_armor_enemy.vpcf', hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControlEnt(self.nParticle, 1, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
	end
end

function m_dazzle_bad_juju_debuff:OnRefresh(t)
	ReadAbilityData(self, {
		'armor_reduction',
	})
end

function m_dazzle_bad_juju_debuff:OnDestroy()
	if IsServer() then
		if self.nParticle then
			ParticleManager:Fade(self.nParticle, true)
		end
	end
end

function m_dazzle_bad_juju_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_dazzle_bad_juju_debuff:GetModifierPhysicalArmorBonus()
	return -self:GetStackCount() * self.armor_reduction
end