modifier_courier = class({})

function modifier_courier:IsHidden()
	return true
end

function modifier_courier:IsPermanent()
	return true
end

function modifier_courier:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

function modifier_courier:GetModifierIncomingDamage_Percentage(t)
	if exist(t.attacker) and t.attacker:IsBuilding() then
		return -1000
	end
end

function modifier_courier:GetModifierMoveSpeedBonus_Percentage()
	return 50
end