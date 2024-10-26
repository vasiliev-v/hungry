LinkLuaModifier("modifier_item_magic_amplify", "items/item_magic_amplify", LUA_MODIFIER_MOTION_NONE)
item_magic_amplify = class({})
function item_magic_amplify:GetIntrinsicModifierName()
	return "modifier_item_magic_amplify"
end
item_magic_fire_1 = class(item_magic_amplify)
item_magic_fire_2 = class(item_magic_amplify)
item_magic_fire_3 = class(item_magic_amplify)
modifier_item_magic_amplify = class({})
--------------------------------------------------------------------------------

function modifier_item_magic_amplify:IsHidden() return true end
function modifier_item_magic_amplify:IsPurgable() return false end
function modifier_item_magic_amplify:DestroyOnExpire() return false end
function modifier_item_magic_amplify:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

--------------------------------------------------------------------------------

function modifier_item_magic_amplify:DeclareFunctions() return 
{
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
}
end

function modifier_item_magic_amplify:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_magic_amplify:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_int")
    self.bonus_mp_regen = self:GetAbility():GetSpecialValueFor("bonus_mp_regen")
    self.magic_amplify_pct = self:GetAbility():GetSpecialValueFor("magic_amplify_pct")
end

function modifier_item_magic_amplify:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magic_amplify:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_magic_amplify:GetModifierSpellAmplify_Percentage()
    return self.magic_amplify_pct
end

