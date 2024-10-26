m_kbw_spell_lifesteal = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_spell_lifesteal:OnCreated()
	ReadAbilityData(self, {
		'value',
		'creeps_devider',
	}, function(hAbility)
		self.hAbility = hAbility
	end)

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_spell_lifesteal:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_spell_lifesteal:OnParentDealDamage(t)
	if not t.unit:IsBaseNPC() or UnitFilter(
		t.unit,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		t.attacker:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	if bit.band(t.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= 0 then
		return
	end

	local nLifesteal = self.value / 100
	if t.unit:IsIllusion() or (not IsBoss(t.unit) and not t.unit:IsConsideredHero()) then
		nLifesteal = nLifesteal / self.creeps_devider
	end
	
	t.attacker:Heal(t.damage * nLifesteal, self.hAbility)

	local nTime = GameRules:GetGameTime()
	if not self.nLastParticle or nTime > self.nLastParticle + 0.5 then
		self.nLastParticle = nTime
		ParticleManager:Create('particles/items3_fx/octarine_core_lifesteal.vpcf', PATTACH_ABSORIGIN_FOLLOW, t.attacker, 1)
	end
end