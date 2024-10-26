require('kbw/util_spell')
require('kbw/util_c')
m_kbw_magic_damage_stun = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_magic_damage_stun:OnCreated()
	ReadAbilityData(self, {
		'stun',
		'cooldown',
	})

	if IsServer() then
		self.tUnits = {}
		
	end
end

function m_kbw_magic_damage_stun:OnDestroy()
	if IsServer() then
		
	end
end

function m_kbw_magic_damage_stun:OnParentDealDamage(t)
	if t.damage_type ~= DAMAGE_TYPE_MAGICAL or t.attacker:GetTeam() == t.unit:GetTeam() or self.tUnits[t.unit] then
		return
	end

	self.tUnits[t.unit] = true
	Timers:CreateTimer(self.cooldown, function()
		self.tUnits[t.unit] = nil
	end)

	AddModifier('m_kbw_freeze', {
		hTarget = t.unit,
		hCaster = t.attacker,
		hAbility = self:GetAbility(),
		duration = self.stun,
	})
end