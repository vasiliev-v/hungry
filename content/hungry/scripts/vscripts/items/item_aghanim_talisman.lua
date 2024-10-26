LinkLuaModifier("modifier_item_aghanim_talisman", "items/item_aghanim_talisman", LUA_MODIFIER_MOTION_NONE)

item_aghanim_talisman = class({})

function item_aghanim_talisman:GetIntrinsicModifierName()
	return "modifier_item_aghanim_talisman"
end

function item_aghanim_talisman:OnSpellStart()
	if not IsServer() then return end
	local mana_restore = self:GetCaster():GetMaxMana() / 100 * self:GetSpecialValueFor("mana_restore")
	self:GetCaster():GiveMana(mana_restore)

	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self:GetCaster(), mana_restore, nil)

	local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(particle, 0, self:GetCaster():GetAbsOrigin())

	self:GetCaster():EmitSound("DOTA_Item.ArcaneBoots.Activate")
end

modifier_item_aghanim_talisman = class({})

function modifier_item_aghanim_talisman:IsHidden() return true end
function modifier_item_aghanim_talisman:IsPurgable() return false end
function modifier_item_aghanim_talisman:IsPurgeException() return false end
function modifier_item_aghanim_talisman:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_aghanim_talisman:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_EXTRA_MANA_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function modifier_item_aghanim_talisman:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_aghanim_talisman:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_aghanim_talisman:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_aghanim_talisman:GetModifierExtraManaPercentage()
	return self:GetAbility():GetSpecialValueFor("bonus_max_mana_percentage")
end

function modifier_item_aghanim_talisman:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end
