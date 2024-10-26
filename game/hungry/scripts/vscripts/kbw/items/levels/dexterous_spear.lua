LinkLuaModifier('m_dexterous_spear', "kbw/items/levels/dexterous_spear", 0)
LinkLuaModifier('m_dexterous_spear_unique', "kbw/items/levels/dexterous_spear", 0)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_dexterous_spear = -1,
		m_dexterous_spear_unique = self.nLevel,
	}
end

CreateLevels({
	'item_dexterous_spear',
	'item_dexterous_spear_2',
	'item_dexterous_spear_3',
}, base)

m_dexterous_spear_unique = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_dexterous_spear_unique:OnCreated()
	ReadAbilityData(self, {
		'speed_pct',
		'lifesteal',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_dexterous_spear_unique:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_dexterous_spear_unique:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_dexterous_spear_unique:GetModifierMoveSpeedBonus_Percentage()
	return self.speed_pct
end

function m_dexterous_spear_unique:OnParentAttackLanded(t)
	if exist(t.target) and t.target:IsAlive()
	and UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		t.attacker:GetTeam()
	) == UF_SUCCESS then
		local nHeal = GetDamageWithArmor(t.original_damage, t.attacker, t.target)
		nHeal = nHeal * self.lifesteal / 100

		t.attacker:Heal(nHeal, self:GetAbility())

		local nTime = GameRules:GetGameTime()
		if not self.nNextParticle or nTime >= self.nNextParticle then
			self.nNextParticle = nTime + 0.1
			ParticleManager:Create('particles/generic_gameplay/generic_lifesteal.vpcf', PATTACH_ABSORIGIN_FOLLOW, t.attacker, 2)
		end
	end
end

m_dexterous_spear = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_dexterous_spear:OnCreated()
	ReadAbilityData(self, {
		'agility',
		'attack_speed',
	})
end

function m_dexterous_spear:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function m_dexterous_spear:GetModifierBonusStats_Agility()
	return self.agility
end
function m_dexterous_spear:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end