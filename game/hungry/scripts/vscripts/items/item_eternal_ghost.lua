LinkLuaModifier("modifier_item_eternal_ghost", "items/item_eternal_ghost.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_eternal_ghost_active", "items/item_eternal_ghost.lua", LUA_MODIFIER_MOTION_NONE)

item_eternal_ghost = class({})

function item_eternal_ghost:GetIntrinsicModifierName()
	return "modifier_item_eternal_ghost"
end

function item_eternal_ghost:OnSpellStart()
	if not IsServer() then return end
	local duration = self:GetSpecialValueFor("duration")
	self:GetCaster():EmitSound("DOTA_Item.GhostScepter.Activate")
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_eternal_ghost_active", {duration = duration})
end

modifier_item_eternal_ghost = class({})

function modifier_item_eternal_ghost:IsHidden() return true end
function modifier_item_eternal_ghost:IsPurgable() return false end
function modifier_item_eternal_ghost:IsPurgeException() return false end
function modifier_item_eternal_ghost:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_eternal_ghost:DeclareFunctions()
	return 
	{
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_item_eternal_ghost:GetModifierBonusStats_Strength()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_eternal_ghost:GetModifierBonusStats_Agility()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_eternal_ghost:GetModifierBonusStats_Intellect()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_eternal_ghost:GetModifierMagicalResistanceBonus()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("magical_resistance")
    end
end

function modifier_item_eternal_ghost:GetModifierConstantHealthRegen()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
    end
end

function modifier_item_eternal_ghost:OnTakeDamage(params)
    if not IsServer() then return end

    if self:GetParent() ~= params.attacker then return end

    if self:GetParent() == params.unit then return end

    if params.unit:IsBuilding() then return end

    if params.inflictor ~= nil and not self:GetParent():IsIllusion() and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then 
        
        if self:GetParent():FindAllModifiersByName("modifier_item_eternal_ghost")[1] ~= self then return end

        local bonus_percentage = 0
        
        for _, mod in pairs(self:GetParent():FindAllModifiers()) do
            if mod.GetModifierSpellLifestealRegenAmplify_Percentage and mod:GetModifierSpellLifestealRegenAmplify_Percentage() then
                bonus_percentage = bonus_percentage + mod:GetModifierSpellLifestealRegenAmplify_Percentage()
            end
        end

        local heal = self:GetAbility():GetSpecialValueFor("spell_lifesteal") / 100 * params.damage

        heal = heal * (bonus_percentage / 100 + 1)

        self:GetParent():Heal(heal, params.inflictor)

        local octarine = ParticleManager:CreateParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker )
        ParticleManager:ReleaseParticleIndex( octarine )
    end
end

modifier_item_eternal_ghost_active = class({})

function modifier_item_eternal_ghost_active:GetStatusEffectName()
    return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_item_eternal_ghost_active:CheckState()
    local state = {
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
        [MODIFIER_STATE_DISARMED] = true
    }
    
    return state
end

function modifier_item_eternal_ghost_active:DeclareFunctions()
    local decFuncs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    }
    
    return decFuncs
end

function modifier_item_eternal_ghost_active:GetAbsoluteNoDamagePhysical()
    return 1
end