m_item_generic_lifesteal = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_generic_lifesteal:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self.last_particle = -1

		self:RegisterSelfEvents()
	end
end

function m_item_generic_lifesteal:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_generic_lifesteal:OnRefresh()
	ReadAbilityData(self, {
		'hero_lifesteal',
		'creep_lifesteal',
	})
end

function m_item_generic_lifesteal:OnParentDealDamage(t)
	-- ignore non-attacks
	if t.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then
		return
	end

	-- ignore invalid unit types
	if not exist(t.unit) or not t.unit.IsBaseNPC or not t.unit:IsBaseNPC()
	or UnitFilter(
		t.unit,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_DEAD,
		t.attacker:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	local time = GameRules:GetGameTime()
	local hero = (t.unit:IsConsideredHero() and not IsBoss(t.unit))
	local pct = hero and self.hero_lifesteal or self.creep_lifesteal
	local heal = t.damage * pct / 100

	t.attacker:Heal(heal, self:GetAbility())

	if time - self.last_particle > 0.3 then
		local particle = hero
			and	'particles/generic_gameplay/generic_lifesteal.vpcf'
			or	'particles/generic_gameplay/generic_lifesteal_lanecreeps.vpcf'
		self.last_particle = time

		ParticleManager:Create(particle, PATTACH_ABSORIGIN_FOLLOW, t.attacker, 1.5)
	end
end