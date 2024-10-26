LinkLuaModifier("modifier_item_diffusal_basher", "items/item_diffusal_basher", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_diffusal_basher_debuff", "items/item_diffusal_basher", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_diffusal_basher_cooldown", "items/item_diffusal_basher", LUA_MODIFIER_MOTION_NONE)

item_diffusal_basher = class({})

function item_diffusal_basher:GetIntrinsicModifierName()
	return "modifier_item_diffusal_basher"
end

function item_diffusal_basher:OnSpellStart()
	if not IsServer() then return end
	local duration = self:GetSpecialValueFor("purge_slow_duration")
	local target = self:GetCursorTarget()
	if target:IsMagicImmune() then return end
	if target:TriggerSpellAbsorb(self) then return end
	self:GetCaster():EmitSound("DOTA_Item.DiffusalBlade.Activate")
	target:EmitSound("DOTA_Item.DiffusalBlade.Target")
	target:AddNewModifier(self:GetCaster(), self, "modifier_item_diffusal_basher_debuff", {duration = duration * (1 - target:GetStatusResistance())})
end

modifier_item_diffusal_basher = class({})

function modifier_item_diffusal_basher:IsHidden()		return true end
function modifier_item_diffusal_basher:IsPurgable() return false end
function modifier_item_diffusal_basher:IsPurgeException() return false end
function modifier_item_diffusal_basher:RemoveOnDeath()	return false end

function modifier_item_diffusal_basher:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_diffusal_basher:GetModifierPreAttack_BonusDamage()
    if self:GetAbility() then
    	return self:GetAbility():GetSpecialValueFor("bonus_damage")
    end
end

function modifier_item_diffusal_basher:GetModifierBonusStats_Agility()
    if self:GetAbility() then
    	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_diffusal_basher:GetModifierBonusStats_Intellect()
    if self:GetAbility() then
    	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_diffusal_basher:GetModifierBonusStats_Strength()
    if self:GetAbility() then
    	return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
    end
end

function modifier_item_diffusal_basher:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_diffusal_basher:OnAttackLanded(params)
    if params.attacker == self:GetParent() then
    	if self:GetParent():FindAllModifiersByName("modifier_item_diffusal_basher")[1] ~= self then return end
    	local target = params.target
    	local chance = self:GetAbility():GetSpecialValueFor("chance_melee")
    	if self:GetParent():IsRangedAttacker() then
    		chance = self:GetAbility():GetSpecialValueFor("chance_range")
    	end
    	local cooldown_bash = self:GetAbility():GetSpecialValueFor("cooldown_bash")

    	if RollPercentage(chance) and not self:GetParent():HasModifier("modifier_item_diffusal_basher_cooldown") and not self:GetParent():IsIllusion() then
    		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_diffusal_basher_cooldown", {duration = cooldown_bash})

    		self:GetParent():EmitSound("DOTA_Item.SkullBasher")

			local manaburn_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(manaburn_pfx, 0, target:GetAbsOrigin() )
			ParticleManager:ReleaseParticleIndex(manaburn_pfx)

			local manaBurn = self:GetAbility():GetSpecialValueFor("feedback_mana_burn")
			local manaDamage = self:GetAbility():GetSpecialValueFor("damage_per_burn")
			local stun_duration = self:GetAbility():GetSpecialValueFor("stun_duration")

			params.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration = stun_duration * (1 - params.target:GetStatusResistance())})

			local damageTable = {}
			damageTable.attacker = self:GetParent()
			damageTable.victim = target
			damageTable.damage_type = DAMAGE_TYPE_PHYSICAL
			damageTable.ability = self:GetAbility()

			if(target:GetMana() >= manaBurn) then
				damageTable.damage = manaBurn * manaDamage
				target:ReduceMana(manaBurn)
			else
				damageTable.damage = target:GetMana() * manaDamage
				target:ReduceMana(manaBurn)
			end

			ApplyDamage(damageTable)
		end
    end
end

modifier_item_diffusal_basher_debuff = class({
	IsDebuff =            function() return true end,
	GetEffectAttachType = function() return PATTACH_OVERHEAD_FOLLOW end,
	GetEffectName =       function() return "particles/items_fx/diffusal_slow.vpcf" end,
})

function modifier_item_diffusal_basher_debuff:OnCreated()
    self.mv = -100
end

function modifier_item_diffusal_basher_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_item_diffusal_basher_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.mv
end

modifier_item_diffusal_basher_cooldown = class({})

function modifier_item_diffusal_basher_cooldown:IsHidden() return true end
function modifier_item_diffusal_basher_cooldown:IsPurgable() return false end
function modifier_item_diffusal_basher_cooldown:RemoveOnDeath() return false end