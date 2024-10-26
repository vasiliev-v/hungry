require('kbw/util_spell')
require('kbw/util_c')
m_kbw_crit_cd = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_crit_cd:OnCreated()
	ReadAbilityData(self, {
		'crit',
		'cooldown',
	})

	if IsServer() then
		self.nNextTime = 0
	end
end

function m_kbw_crit_cd:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
end

function m_kbw_crit_cd:GetModifierPreAttack_CriticalStrike()
	if IsServer() then
		local nTime = GameRules:GetGameTime()
		if nTime >= self.nNextTime then
			self.nNextTime = nTime + self.cooldown
			return self.crit
		end
	end
end