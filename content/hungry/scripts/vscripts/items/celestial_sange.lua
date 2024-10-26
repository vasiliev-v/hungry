item_celestial_sange = class({})

function item_celestial_sange:GetIntrinsicModifierName()
	return "modifier_item_celestial_sange"
end

LinkLuaModifier("modifier_item_celestial_sange", "items/celestial_sange", LUA_MODIFIER_MOTION_NONE)

modifier_item_celestial_sange = class({})

function modifier_item_celestial_sange:IsHidden() return true end
function modifier_item_celestial_sange:IsDebuff() return false end
function modifier_item_celestial_sange:IsPurgable() return false end
function modifier_item_celestial_sange:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_item_celestial_sange:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,

		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,

		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE_UNIQUE,
	}
end

function modifier_item_celestial_sange:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self:OnRefresh()
end

function modifier_item_celestial_sange:OnRefresh()
	if (not self.ability) or self.ability:IsNull() then return end

	self.bonus_intellect = self.ability:GetSpecialValueFor("bonus_intellect")
	self.mana_regen_amp = self.ability:GetSpecialValueFor("mana_regen_amp")
	self.spell_lifesteal_amp = self.ability:GetSpecialValueFor("spell_lifesteal_amp")

	self.bonus_strength = self.ability:GetSpecialValueFor("bonus_strength")
	self.status_resistance = self.ability:GetSpecialValueFor("status_resistance")
	self.hp_regen_lifesteal_amp = self.ability:GetSpecialValueFor("hp_regen_lifesteal_amp")

	self.creep_spell_amp = self.ability:GetSpecialValueFor("creep_spell_amp")
	self.duel_spell_amp = self.ability:GetSpecialValueFor("duel_spell_amp")
	
	if IsServer() and self.parent and (not self.parent:IsNull()) and self.parent.CalculateStatBonus then self.parent:CalculateStatBonus(false) end
end

function modifier_item_celestial_sange:GetModifierBonusStats_Intellect() return self.bonus_intellect or 0 end
function modifier_item_celestial_sange:GetModifierMPRegenAmplify_Percentage() return self.mana_regen_amp or 0 end
function modifier_item_celestial_sange:GetModifierSpellLifestealRegenAmplify_Percentage() return self.spell_lifesteal_amp or 0 end

function modifier_item_celestial_sange:GetModifierBonusStats_Strength() return self.bonus_strength or 0 end
function modifier_item_celestial_sange:GetModifierStatusResistance() return self.status_resistance or 0 end
function modifier_item_celestial_sange:GetModifierHPRegenAmplify_Percentage() return self.hp_regen_lifesteal_amp or 0 end
function modifier_item_celestial_sange:GetModifierLifestealRegenAmplify_Percentage() return self.hp_regen_lifesteal_amp or 0 end

function modifier_item_celestial_sange:GetModifierSpellAmplify_PercentageUnique()
	if (not self.parent) or (self.parent:IsNull()) then return end
	if not self.parent.GetIntellect then return 0 end -- Bear exlusion
	
	if self.parent:HasModifier("modifier_hero_dueling") then
		return self.duel_spell_amp * self.parent:GetIntellect()
	else
		return self.creep_spell_amp * self.parent:GetIntellect()
	end
end
