item_celestial_yasha = class({})

function item_celestial_yasha:GetIntrinsicModifierName()
	return "modifier_item_celestial_yasha"
end

LinkLuaModifier("modifier_item_celestial_yasha", "items/celestial_yasha", LUA_MODIFIER_MOTION_NONE)

modifier_item_celestial_yasha = class({})

function modifier_item_celestial_yasha:IsHidden() return true end
function modifier_item_celestial_yasha:IsDebuff() return false end
function modifier_item_celestial_yasha:IsPurgable() return false end
function modifier_item_celestial_yasha:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_item_celestial_yasha:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,

		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,

		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE_UNIQUE,
	}
end

function modifier_item_celestial_yasha:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self:OnRefresh()
end

function modifier_item_celestial_yasha:OnRefresh()
	if (not self.ability) or self.ability:IsNull() then return end

	self.bonus_intellect = self.ability:GetSpecialValueFor("bonus_intellect")
	self.mana_regen_amp = self.ability:GetSpecialValueFor("mana_regen_amp")
	self.spell_lifesteal_amp = self.ability:GetSpecialValueFor("spell_lifesteal_amp")

	self.bonus_agility = self.ability:GetSpecialValueFor("bonus_agility")
	self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_movement_speed = self.ability:GetSpecialValueFor("bonus_movement_speed")

	self.creep_spell_amp = self.ability:GetSpecialValueFor("creep_spell_amp")
	self.duel_spell_amp = self.ability:GetSpecialValueFor("duel_spell_amp")
	
	if IsServer() and self.parent and (not self.parent:IsNull()) and self.parent.CalculateStatBonus then self.parent:CalculateStatBonus(false) end
end

function modifier_item_celestial_yasha:GetModifierBonusStats_Intellect() return self.bonus_intellect or 0 end
function modifier_item_celestial_yasha:GetModifierMPRegenAmplify_Percentage() return self.mana_regen_amp or 0 end
function modifier_item_celestial_yasha:GetModifierSpellLifestealRegenAmplify_Percentage() return self.spell_lifesteal_amp or 0 end

function modifier_item_celestial_yasha:GetModifierBonusStats_Agility() return self.bonus_agility or 0 end
function modifier_item_celestial_yasha:GetModifierAttackSpeedBonus_Constant() return self.bonus_attack_speed or 0 end
function modifier_item_celestial_yasha:GetModifierMoveSpeedBonus_Percentage_Unique() return self.bonus_movement_speed or 0 end

function modifier_item_celestial_yasha:GetModifierSpellAmplify_PercentageUnique()
	if (not self.parent) or (self.parent:IsNull()) then return end
	if not self.parent.GetIntellect then return 0 end -- Bear exlusion
	
	if self.parent:HasModifier("modifier_hero_dueling") then
		return self.duel_spell_amp * self.parent:GetIntellect()
	else
		return self.creep_spell_amp * self.parent:GetIntellect()
	end
end
