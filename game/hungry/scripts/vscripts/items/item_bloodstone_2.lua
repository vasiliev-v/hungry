LinkLuaModifier("modifier_item_bloodstone_2", "items/item_bloodstone_2", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_modifier_item_bloodstone_2_active", "items/item_bloodstone_2", LUA_MODIFIER_MOTION_NONE )
require( "utils/bit" )

item_bloodstone_2 							= class({})
modifier_item_bloodstone_2 					= class({})
modifier_modifier_item_bloodstone_2_active 	= class({})

function item_bloodstone_2:GetIntrinsicModifierName()
	return "modifier_item_bloodstone_2"
end

function item_bloodstone_2:GetManaCost()
	-- There's like one server-tick where the caster is nil so add this conditional to prevent random error
	if self and not self:IsNull() and self.GetCaster and self:GetCaster() ~= nil then
		return self:GetCaster():GetMaxMana() * (self:GetSpecialValueFor("mana_cost_percentage") / 100)
	end
end

function item_bloodstone_2:OnSpellStart()
	self.caster	= self:GetCaster()
	self.restore_duration			= self:GetSpecialValueFor("restore_duration")

	if not IsServer() then return end
	--self.caster:EmitSound("shamp_cast")	
	self.caster:EmitSound("DOTA_Item.Bloodstone.Cast")
	--self.caster:EmitSound("beer_cast")

	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_modifier_item_bloodstone_2_active", {duration = self.restore_duration})
end

function modifier_modifier_item_bloodstone_2_active:OnCreated()
	if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

	self.ability	= self:GetAbility()
	self.parent		= self:GetParent()
	
	self.restore_duration			= self.ability:GetSpecialValueFor("restore_duration")
	self.mana_cost					= self.ability:GetManaCost()
	
	if not IsServer() then return end
	
	self.cooldown_remaining			= math.max(self:GetAbility():GetCooldownTimeRemaining() - self:GetRemainingTime(), 0)

	self.particle = ParticleManager:CreateParticle("particles/items_fx/bloodstone_heal.vpcf", PATTACH_OVERHEAD_FOLLOW, self.parent)
	ParticleManager:SetParticleControlEnt(self.particle, 2, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", self.parent:GetAbsOrigin(), true)
	self:AddParticle(self.particle, false, false, -1, false, false)

end


function modifier_modifier_item_bloodstone_2_active:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_modifier_item_bloodstone_2_active:GetModifierConstantHealthRegen()
    return self.mana_cost / self.restore_duration
end

function modifier_modifier_item_bloodstone_2_active:OnTooltip()
    return self.mana_cost
end

--------------------------------------
-- BLOODSTONE PASSIVE MODIFIER 7.20 --
--------------------------------------

function modifier_item_bloodstone_2:IsHidden()		return true end
function modifier_item_bloodstone_2:IsPurgable()	return false end
function modifier_item_bloodstone_2:RemoveOnDeath()	return false end

function modifier_item_bloodstone_2:OnCreated()
	if not self:GetAbility() then self:Destroy() return end

	self.ability	= self:GetAbility()
	self.parent		= self:GetParent()
	
	self.bonus_health				= self.ability:GetSpecialValueFor("bonus_health")
	self.bonus_mana					= self.ability:GetSpecialValueFor("bonus_mana")
	self.bonus_intellect			= self.ability:GetSpecialValueFor("bonus_intellect")
	self.mana_regen_multiplier	    = self.ability:GetSpecialValueFor("mana_regen_multiplier")
	self.spell_amp					= self.ability:GetSpecialValueFor("spell_amp")
	self.regen_per_charge			= self.ability:GetSpecialValueFor("regen_per_charge")
	self.amp_per_charge				= self.ability:GetSpecialValueFor("amp_per_charge")
	self.death_charges				= self.ability:GetSpecialValueFor("death_charges")
	self.kill_charges				= self.ability:GetSpecialValueFor("kill_charges")
	self.charge_range				= self.ability:GetSpecialValueFor("charge_range")
	self.initial_charges_tooltip	= self.ability:GetSpecialValueFor("initial_charges_tooltip")
	self.hp_regen_lifesteal_amp     = self.ability:GetSpecialValueFor("hero_lifesteal")		
	self.hp_regen_amp_creep     	= self.ability:GetSpecialValueFor("creep_lifesteal")		
end

function modifier_item_bloodstone_2:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,	
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE_UNIQUE,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,

    }
end

function modifier_item_bloodstone_2:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_bloodstone_2:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_bloodstone_2:GetModifierTotalPercentageManaRegen()
	return self.mana_regen_multiplier / 100
end

function modifier_item_bloodstone_2:GetModifierSpellAmplify_PercentageUnique()
	if self:GetParent():HasModifier("modifier_skill_bloodmage") then
		return self.spell_amp * 2
	end
	return self.spell_amp
end


function modifier_item_bloodstone_2:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end


function modifier_item_bloodstone_2:GetModifierConstantManaRegen()
	return self.regen_per_charge * self:GetStackCount()
end

function modifier_item_bloodstone_2:GetModifierSpellAmplify_Percentage()
	if self:GetParent():HasModifier("modifier_skill_bloodmage") then
		return (self.amp_per_charge*2) * self:GetStackCount()
	end
	return self.amp_per_charge * self:GetStackCount()
end

function modifier_item_bloodstone_2:GetModifierSpellLifestealRegenAmplify_Percentage() 
	return self.hp_regen_lifesteal_amp or 0
end

function modifier_item_bloodstone_2:GetModifierHPRegenAmplify_Percentage() 
	return self.hp_regen_lifesteal_amp or 0
end
function modifier_item_bloodstone_2:GetModifierLifestealRegenAmplify_Percentage() 
	return self.hp_regen_lifesteal_amp or 0
end
