local PATH = 'kbw/modifiers/m_kbw_attack_mag_weakness'

m_kbw_attack_mag_weakness = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_attack_mag_weakness:OnCreated()
	ReadAbilityData(self, {
		'value',
		'duration',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_attack_mag_weakness:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_attack_mag_weakness:OnParentAttackLanded(t)
	if not exist(t.target) or not t.target:IsBaseNPC() or not t.target:IsAlive() then
		return
	end

	if UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		t.attacker:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	local debuff = t.target:FindModifierByName('m_kbw_mag_weakness')
	if debuff and debuff:GetStackCount() > self.value then
		local duration = self.duration * (1 - t.target:GetStatusResistance())
		if duration > debuff:GetRemainingTime() then
			debuff:SetDuration(duration, true)
		end
	else
		AddModifier('m_kbw_mag_weakness', {
			hTarget = t.target,
			hCaster = t.attacker,
			hAbility = self:GetAbility(),
			duration = self.duration,
			value = self.value,
		})
	end
end

LinkLuaModifier('m_kbw_mag_weakness', PATH, LUA_MODIFIER_MOTION_NONE)
m_kbw_mag_weakness = ModifierClass{
	bPurgable = true,
	-- bMultiple = true,
}

function m_kbw_mag_weakness:IsDebuff()
	return true
end

function m_kbw_mag_weakness:OnCreated(t)
	if IsServer() then
		self:SetStackCount(t.value or 0)
	end
end

function m_kbw_mag_weakness:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function m_kbw_mag_weakness:GetModifierMagicalResistanceBonus()
	return -self:GetStackCount()
end