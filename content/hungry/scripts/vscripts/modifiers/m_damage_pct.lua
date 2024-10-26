require('kbw/util_spell')
require('kbw/util_c')
m_damage_pct = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_damage_pct:OnCreated(t)
	if IsServer() then
		self.nDamage = t.nDamage or 0
	end
end

function m_damage_pct:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_damage_pct:GetModifierDamageOutgoing_Percentage()
	return self.nDamage
end