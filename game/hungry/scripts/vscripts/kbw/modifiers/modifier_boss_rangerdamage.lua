local tPurgeModifiers = {
	modifier_axe_counter_helix_damage_reduction = 1,
}

modifier_boss_rangerdamage = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function modifier_boss_rangerdamage:IsPurgable()
	return false
end

function modifier_boss_rangerdamage:IsHidden()
	return true
end

function modifier_boss_rangerdamage:CheckState()
	local bNeutral = (self:GetParent():GetTeamNumber() == DOTA_TEAM_NEUTRALS or nil)

	return {
		[MODIFIER_STATE_ROOTED] = false,
		[MODIFIER_STATE_UNSLOWABLE] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = bNeutral,
		[MODIFIER_STATE_CANNOT_MISS] = IsServer() and RollPercentage(50) or nil,
	}
end

-- function modifier_boss_rangerdamage:DeclareFunctions()
-- 	return {
-- 		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
-- 	}
-- end

function modifier_boss_rangerdamage:OnCreated()
    if IsServer() then
        self:StartIntervalThink( 1/30 )
    end
end

function modifier_boss_rangerdamage:OnIntervalThink()
    if IsServer() then
        local hParent = self:GetParent()

		for modifier in pairs(tPurgeModifiers) do
			hParent:RemoveModifierByName(modifier)
		end
    end
end