
require('kbw/util_spell')
require('kbw/util_c')
m_speed_pct = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_speed_pct:OnCreated(t)
	if IsServer() then
		self:SetStackCount(t.speed or 0)
	end
end

function m_speed_pct:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_speed_pct:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount()
end