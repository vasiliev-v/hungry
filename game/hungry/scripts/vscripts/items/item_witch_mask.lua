LinkLuaModifier("modifier_item_witch_mask", "items/item_witch_mask", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_witch_mask_debuff", "items/item_witch_mask", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_witch_mask_buff", "items/item_witch_mask", LUA_MODIFIER_MOTION_NONE)

item_witch_mask = class({})

function item_witch_mask:GetIntrinsicModifierName()
	return "modifier_item_witch_mask"
end

function item_witch_mask:OnSpellStart()
	if not IsServer() then return end
	local duration = self:GetSpecialValueFor("berserk_duration")
    self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_item_witch_mask_buff", {duration = duration} )
end

modifier_item_witch_mask = class({})

function modifier_item_witch_mask:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_witch_mask:IsHidden() return true end
function modifier_item_witch_mask:IsPurgable() return false end
function modifier_item_witch_mask:IsPurgeException() return false end

function modifier_item_witch_mask:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_witch_mask:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_witch_mask:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_witch_mask:OnTakeDamage(params)
    if not IsServer() then return end
    if self:GetParent() ~= params.attacker then return end
    if self:GetParent() == params.unit then return end
    if params.unit:IsBuilding() then return end
    if params.inflictor == nil and not self:GetParent():IsIllusion() and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then 
    	if self:GetParent():FindAllModifiersByName("modifier_item_witch_mask")[1] ~= self then return end
        local heal = self:GetAbility():GetSpecialValueFor("lifesteal_percent") / 100 * params.damage
        self:GetParent():Heal(heal, nil)
        local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker )
        ParticleManager:ReleaseParticleIndex( effect_cast )
    end
end

function modifier_item_witch_mask:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_witch_mask:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_witch_mask:GetModifierProjectileSpeedBonus()
	return self:GetAbility():GetSpecialValueFor("attack_speed_proj")
end

modifier_item_witch_mask_buff = class({})

function modifier_item_witch_mask_buff:IsPurgable()
	return false
end

function modifier_item_witch_mask_buff:OnCreated()
	if not IsServer() then return end
	local particle = ParticleManager:CreateParticle("particles/items2_fx/mask_of_madness.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
	self:AddParticle(particle, false, false, -1, false, false)
	self:GetParent():EmitSound("DOTA_Item.MaskOfMadness.Activate")
end

function modifier_item_witch_mask_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_item_witch_mask_buff:OnDestroy()
	if not IsServer() then return end
	self:GetParent():EmitSound("DOTA_Item.BladeMail.Deactivate")
end

function modifier_item_witch_mask_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("berserk_bonus_attack_speed") 
end

function modifier_item_witch_mask_buff:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("berserk_bonus_movement_speed") 
end

function modifier_item_witch_mask_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("berserk_armor_reduction") 
end

function modifier_item_witch_mask_buff:OnAttackLanded(params)
	if not IsServer() then return end

	if params.attacker == self:GetParent() then
		params.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_witch_mask_debuff", {duration = self:GetAbility():GetSpecialValueFor("slow_duration") * (1 - params.target:GetStatusResistance())})
	end
end

modifier_item_witch_mask_debuff = class({})

function modifier_item_witch_mask_debuff:OnCreated()
	self.int_damage_multiplier = self:GetAbility():GetSpecialValueFor('int_damage_multiplier')
	self.slow = self:GetAbility():GetSpecialValueFor('slow')
	if not IsServer() then return end
	self:StartIntervalThink(1)
	self:GetParent():RemoveModifierByName("modifier_item_witch_blade_slow")
end

function modifier_item_witch_mask_debuff:OnIntervalThink()
	if not IsServer() then return end
	local damage = self:GetCaster():GetIntellect() * self.int_damage_multiplier
	ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	self:GetParent():RemoveModifierByName("modifier_item_witch_blade_slow")
end

function modifier_item_witch_mask_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end

function modifier_item_witch_mask_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_item_witch_mask_debuff:GetEffectName()
	return "particles/items3_fx/witch_blade_debuff.vpcf"
end

function modifier_item_witch_mask_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end


