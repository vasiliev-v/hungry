require('kbw/util_spell')
require('kbw/util_c')
m_kbw_max_mp_regen = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_max_mp_regen:OnCreated()
	ReadAbilityData(self, {'value'}, function()
		self.value = self.value / 100 
	end)
end

function m_kbw_max_mp_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_kbw_max_mp_regen:GetModifierConstantManaRegen()
	return self:GetParent():GetMaxMana() * self.value
end