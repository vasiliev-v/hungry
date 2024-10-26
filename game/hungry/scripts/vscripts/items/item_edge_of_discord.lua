LinkLuaModifier("modifier_item_edge_of_discord", "items/item_edge_of_discord", LUA_MODIFIER_MOTION_NONE)

item_edge_of_discord = class({})

function item_edge_of_discord:GetIntrinsicModifierName()
	return "modifier_item_edge_of_discord"
end

modifier_item_edge_of_discord = class({})

function modifier_item_edge_of_discord:IsHidden()
	return true
end

function modifier_item_edge_of_discord:IsPurgable() return false end
function modifier_item_edge_of_discord:IsPurgeException() return false end

function modifier_item_edge_of_discord:DeclareFunctions()
	return 
	{
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_item_edge_of_discord:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_edge_of_discord:GetModifierTotalDamageOutgoing_Percentage(params)
	if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then 
		if self:GetParent():FindAllModifiersByName("modifier_item_edge_of_discord")[1] ~= self then return end
		if self:GetParent().block_crit ~= nil then return end
		if RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, params.original_damage + (params.original_damage / 100 * (self:GetAbility():GetSpecialValueFor("spell_damage_crit") - 100)), nil)
			return self:GetAbility():GetSpecialValueFor("spell_damage_crit") - 100
		end
	end
end

function modifier_item_edge_of_discord:GetModifierConstantManaRegen(params)
	return self:GetAbility():GetSpecialValueFor("mana_regen")
end

function modifier_item_edge_of_discord:GetModifierBonusStats_Strength(params)
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_edge_of_discord:GetModifierBonusStats_Agility(params)
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_edge_of_discord:GetModifierBonusStats_Intellect(params)
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_edge_of_discord:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("lifesteal_amplify")
end

function modifier_item_edge_of_discord:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amplify")
end

