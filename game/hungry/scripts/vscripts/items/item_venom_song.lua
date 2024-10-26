LinkLuaModifier("modifier_item_venom_song", "items/item_venom_song", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_venom_song_debuff", "items/item_venom_song", LUA_MODIFIER_MOTION_NONE)

item_venom_song = class({})

function item_venom_song:GetIntrinsicModifierName()
	return "modifier_item_venom_song"
end

modifier_item_venom_song = class({})

function modifier_item_venom_song:IsHidden() return true end

function modifier_item_venom_song:IsPurgable() return false end
function modifier_item_venom_song:IsPurgeException() return false end

function modifier_item_venom_song:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_venom_song:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_item_venom_song:GetModifierBonusStats_Agility()
	return  self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_venom_song:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_venom_song:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
        if params.target:IsOther() then
            return nil
        end

        if self:GetParent():IsIllusion() then
            return nil
        end

        local duration = self:GetAbility():GetSpecialValueFor("duration")
        params.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_venom_song_debuff", {duration = duration * (1 - params.target:GetStatusResistance())})
    end
end

modifier_item_venom_song_debuff = class({})

function modifier_item_venom_song_debuff:IsPurgable() return true end

function modifier_item_venom_song_debuff:OnCreated()
    if not IsServer() then return end
    local damage_phys = self:GetAbility():GetSpecialValueFor("damage_phys")
    self.damage = self:GetCaster():GetAverageTrueAttackDamage(nil) / 100 * damage_phys
    self:StartIntervalThink(1)
end

function modifier_item_venom_song_debuff:OnIntervalThink()
    if not IsServer() then return end
    print("dsadsa")
    ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), ability = self:GetAbility(), damage = self.damage, flags=DOTA_DAMAGE_FLAG_BYPASSES_BLOCK+DOTA_DAMAGE_FLAG_HPLOSS +DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR +DOTA_DAMAGE_FLAG_IGNORES_BASE_PHYSICAL_ARMOR , damage_type = DAMAGE_TYPE_MAGICAL})
end

function modifier_item_venom_song_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end

function modifier_item_venom_song_debuff:GetEffectName()
    return "particles/econ/items/venomancer/veno_2021_immortal_arms/veno_2021_immortal_poison_debuff.vpcf"
end

function modifier_item_venom_song_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_venom_song_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("minus_armor")
end

function modifier_item_venom_song_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed_reduce")
end