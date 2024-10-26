m_item_generic_cast_range_fix = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_generic_cast_range_fix:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,	-- client range fix
    }
end

function m_item_generic_cast_range_fix:GetModifierCastRangeBonusStacking(t)
    if IsServer() or self.bGetModifierCastRangeBonusStacking then
		return
	end

	if t.ability == self:GetAbility() then
		self.bGetModifierCastRangeBonusStacking = true
		local bonus = t.ability:GetEffectiveCastRange(Vector(0,0,0), nil)
					- t.ability:GetCastRange(Vector(0,0,0), nil)
		self.bGetModifierCastRangeBonusStacking = nil
		return -bonus
	end
end
