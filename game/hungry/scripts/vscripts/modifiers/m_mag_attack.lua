require('kbw/util_spell')
require('kbw/util_c')
m_mag_attack = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_mag_attack:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'value',
			'raw'
		})
		
	end
end

function m_mag_attack:OnDestroy()
	if IsServer() then
		
	end
end

function m_mag_attack:DeclareFunctions()
	local func = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return func
end

function m_mag_attack:OnAttackLanded(t)
	if UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES,
		t.attacker:GetTeam()
	) == UF_SUCCESS then
		local nDamage = self.value
		if self.raw == 0 then
			nDamage = t.damage * self.value / 100
		end

		ApplyDamage({
			victim = t.target,
			attacker = t.attacker,
			ability = self:GetAbility(),
			damage = nDamage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		})
	end
end