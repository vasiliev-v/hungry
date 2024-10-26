modifier_hero_killer = class({})

function modifier_hero_killer:CheckState() 
    return { [MODIFIER_STATE_BLOCK_DISABLED] = false}
end

function modifier_hero_killer:IsHidden()
    return false
end

function modifier_hero_killer:IsPurgable()
    return false
end

function modifier_hero_killer:IsPermanent()
	return true
end

function modifier_hero_killer:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
             MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_hero_killer:GetModifierBonusStats_Strength()
	--local player
	--if self:GetParent() then
	--	player = self:GetParent()
	--end

	return (math.ceil(GameRules:GetGameTime()/60) + 4 * self:GetStackCount()) 
end

function modifier_hero_killer:GetModifierBonusStats_Agility()

	return (math.ceil(GameRules:GetGameTime()/60) + 4 * self:GetStackCount()) 
end

function modifier_hero_killer:GetModifierBonusStats_Intellect()
	return (math.ceil(GameRules:GetGameTime()/60) + 4 * self:GetStackCount()) 
end
