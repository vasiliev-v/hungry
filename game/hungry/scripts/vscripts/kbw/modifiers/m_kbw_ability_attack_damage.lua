m_kbw_ability_attack_damage = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_ability_attack_damage:OnCreated(t)
	if IsServer() then
		self.ability = t.ability
		self.damage_pct = t.damage_pct
		self.procs = toboolean(t.procs)
		self.nomiss = toboolean(t.nomiss)
		self:RegisterSelfEvents()
	end
end

function m_kbw_ability_attack_damage:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_ability_attack_damage:OnParentDealDamage(t)
	if t.inflictor and t.inflictor:GetName() == self.ability then
		Timer(1/30, function()
			if exist(t.unit) and exist(t.attacker) and t.unit:IsAlive() then
				local hDamageBuff

				if self.damage_pct then
					hDamageBuff = AddModifier('m_damage_pct', {
						hTarget = t.attacker,
						hCaster = t.attacker,
						hAbility = t.inflictor,
						nDamage = self.damage_pct - 100,
					})
				end

				if self.procs then
					t.attacker:PerformAttack(t.unit, true, true, true, true, false, false, self.nomiss)
				else
					ApplyDamage({
						victim = t.unit,
						attacker = t.attacker,
						damage = t.attacker:GetAverageTrueAttackDamage(t.unit),
						damage_type = DAMAGE_TYPE_PHYSICAL,
					})
				end

				if exist(hDamageBuff) then
					hDamageBuff:Destroy()
				end
			end
		end)
	end
end