LinkLuaModifier("modifier_item_magic_crit", "items/item_magic_crit", LUA_MODIFIER_MOTION_NONE, modifier_item_magic_crit)
LinkLuaModifier("modifier_item_primal_magic", "items/item_magic_crit", LUA_MODIFIER_MOTION_NONE, modifier_item_primal_magic)

item_primal_magic = class({})
function item_primal_magic:GetIntrinsicModifierName()
	return "modifier_item_primal_magic"
end
item_primal_magic_1 = class(item_primal_magic)
item_primal_magic_2 = class(item_primal_magic)
item_primal_magic_3 = class(item_primal_magic)

modifier_item_magic_crit = class({})

--------------------------------------------------------------------------------

function modifier_item_magic_crit:IsHidden() return true end
function modifier_item_magic_crit:IsPurgable() return false end
function modifier_item_magic_crit:DestroyOnExpire() return false end
function modifier_item_magic_crit:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

--------------------------------------------------------------------------------

function modifier_item_magic_crit:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
}
end

function modifier_item_magic_crit:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_magic_crit:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")
end

function modifier_item_magic_crit:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magic_crit:GetModifierTotalDamageOutgoing_Percentage(params)
	if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then 
		if self:GetParent():FindAllModifiersByName("modifier_item_magic_crit")[1] ~= self then return end
		if self:GetParent().block_crit ~= nil then return end
		if RollPercentage(self:GetAbility():GetSpecialValueFor("magic_crit_chance")) then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, params.original_damage + (params.original_damage / 100 * (self:GetAbility():GetSpecialValueFor("magic_crit_multiplier") - 100)), nil)
			return self:GetAbility():GetSpecialValueFor("magic_crit_multiplier") - 100
		end
	end
end

modifier_item_primal_magic = class({})
--------------------------------------------------------------------------------

function modifier_item_primal_magic:IsHidden() return true end
function modifier_item_primal_magic:IsPurgable() return false end
function modifier_item_primal_magic:DestroyOnExpire() return false end
function modifier_item_primal_magic:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

--------------------------------------------------------------------------------

function modifier_item_primal_magic:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
}
end

function modifier_item_primal_magic:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_primal_magic:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")

    self.threshold_pct = self.ability:GetSpecialValueFor("threshold_pct")
    self.threshold_chance_bonus = self.ability:GetSpecialValueFor("threshold_chance_bonus")
end

function modifier_item_primal_magic:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_primal_magic:GetModifierTotalDamageOutgoing_Percentage(params)
	if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then 
		if self:GetParent():FindAllModifiersByName("modifier_item_primal_magic")[1] ~= self then return end
		if self:GetParent().block_crit ~= nil then return end
		if RollPercentage(self:GetAbility():GetSpecialValueFor("magic_crit_chance")) then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, params.original_damage + (params.original_damage / 100 * (self:GetAbility():GetSpecialValueFor("magic_crit_multiplier") - 100)), nil)
			return self:GetAbility():GetSpecialValueFor("magic_crit_multiplier") - 100
		end
	end
end