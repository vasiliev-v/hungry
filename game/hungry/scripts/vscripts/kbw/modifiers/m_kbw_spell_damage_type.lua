m_kbw_spell_damage_type = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_spell_damage_type:OnCreated(t)
	if IsServer() then
		self.ability = t.ability
		self.damage_pct = t.damage_pct
		self.damage_type = _G[t.damage_type]

		self:RegisterSelfEvents()
	end
end

function m_kbw_spell_damage_type:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_spell_damage_type:OnParentDealDamage(t)
	if exist(t.inflictor) and t.inflictor:GetName() == self.ability
	and not binhas(t.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) then
		ApplyDamage({
			victim = t.unit,
			attacker = t.attacker,
			ability = t.inflictor,
			damage = t.original_damage * self.damage_pct / 100,
			damage_type = self.damage_type,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		})
	end
end