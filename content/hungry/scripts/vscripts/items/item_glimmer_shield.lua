LinkLuaModifier("modifier_item_glimmer_shiled_active", "items/item_glimmer_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_glimmer_shiled_passive", "items/item_glimmer_shield", LUA_MODIFIER_MOTION_NONE)

item_glimmer_shield = class({})

function item_glimmer_shield:OnSpellStart()
    if not IsServer() then return end
    self:GetCaster():EmitSound("Item.GlimmerCape.Activate")
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_glimmer_shiled_active", {duration = self:GetSpecialValueFor("duration")})
end

function item_glimmer_shield:GetIntrinsicModifierName()
	return "modifier_item_glimmer_shiled_passive"
end

modifier_item_glimmer_shiled_passive = class({})

function modifier_item_glimmer_shiled_passive:IsHidden() return true end

function modifier_item_glimmer_shiled_passive:IsPurgable() return false end
function modifier_item_glimmer_shiled_passive:IsPurgeException() return false end

function modifier_item_glimmer_shiled_passive:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_glimmer_shiled_passive:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }
end

function modifier_item_glimmer_shiled_passive:GetModifierMagicalResistanceBonus() return self:GetAbility():GetSpecialValueFor("bonus_magical_armor") end
function modifier_item_glimmer_shiled_passive:GetModifierPercentageCooldown() return self:GetAbility():GetSpecialValueFor("cooldown_reduce") end
function modifier_item_glimmer_shiled_passive:GetModifierBonusStats_Intellect() return self:GetAbility():GetSpecialValueFor("bonus_intellect") end

modifier_item_glimmer_shiled_active = class({})

function modifier_item_glimmer_shiled_active:IsHidden()     return false end
function modifier_item_glimmer_shiled_active:IsPurgable()   return false end

function modifier_item_glimmer_shiled_active:OnCreated(table)
    self.speed = self:GetAbility():GetSpecialValueFor("bonus_movespeed")
    self.active_magical_armor = self:GetAbility():GetSpecialValueFor("active_magical_armor")
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle("particles/glimmer_cape5initial.vpcf", PATTACH_RENDERORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(particle, false, false, -1, false, false)
    self:StartIntervalThink(FrameTime())
end

function modifier_item_glimmer_shiled_active:OnIntervalThink()
    if not IsServer() then return end
    AddFOWViewer(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), self:GetAbility():GetSpecialValueFor("vision_radius"), FrameTime(), false)
end

function modifier_item_glimmer_shiled_active:CheckState() 
    return 
    {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_item_glimmer_shiled_active:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
end

function modifier_item_glimmer_shiled_active:GetModifierMoveSpeedBonus_Percentage() return self.speed end
function modifier_item_glimmer_shiled_active:GetModifierMagicalResistanceBonus() return self.active_magical_armor end

function modifier_item_glimmer_shiled_active:OnAttackLanded(params)
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() then return end
	self:Destroy()
end