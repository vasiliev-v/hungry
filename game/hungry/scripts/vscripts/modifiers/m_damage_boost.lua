require('kbw/util_spell')
require('kbw/util_c')
m_damage_boost = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_damage_boost:OnCreated(t)
	if IsServer() then
		self.damage = t.damage
		self.inflictor = t.inflictor
	end
end

function m_damage_boost:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_damage_boost:GetModifierTotalDamageOutgoing_Percentage(t)
	if t.inflictor and t.inflictor:GetName() == self.inflictor then
		return self.damage
	end
end