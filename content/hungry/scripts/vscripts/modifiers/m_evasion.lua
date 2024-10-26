require('kbw/util_spell')
require('kbw/util_c')
m_evasion = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_evasion:OnCreated(t)
	self:SetStackCount(t.value or 0)
end

function m_evasion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
end

function m_evasion:GetModifierEvasion_Constant()
	return self:GetStackCount()
end