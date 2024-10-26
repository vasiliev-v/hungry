LinkLuaModifier("modifier_item_soul_nullifier", "items/item_soul_nullifier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_soul_nullifier_debuff", "items/item_soul_nullifier", LUA_MODIFIER_MOTION_NONE)

item_soul_nullifier = class({})

function item_soul_nullifier:GetIntrinsicModifierName()
	return "modifier_item_soul_nullifier"
end

function item_soul_nullifier:OnSpellStart()
	if not IsServer() then return end
	local target = self:GetCursorTarget()
	self:GetCaster():EmitSound("DOTA_Item.Nullifier.Cast")

	local projectile =
	{
		Target 				= target,
		Source 				= self:GetCaster(),
		Ability 			= self,
		EffectName 			= "particles/items4_fx/nullifier_proj.vpcf",
		iMoveSpeed			= 1100,
		vSourceLoc 			= self:GetCaster():GetAbsOrigin(),
		bDrawsOnMinimap 	= false,
		bDodgeable 			= true,
		bIsAttack 			= false,
		bVisibleToEnemies 	= true,
		bReplaceExisting 	= false,
		flExpireTime 		= GameRules:GetGameTime() + 10,
		bProvidesVision 	= false,
	}
		
	ProjectileManager:CreateTrackingProjectile(projectile)
end

function item_soul_nullifier:OnProjectileHit(target, location)
	if target and not target:IsMagicImmune() then
		if target:TriggerSpellAbsorb(self) then return nil end
		target:Purge(true, false, false, false, false)
		target:EmitSound("DOTA_Item.Nullifier.Target")
		target:AddNewModifier(self:GetCaster(), self, "modifier_item_soul_nullifier_debuff", {duration = self:GetSpecialValueFor("mute_duration") * (1 - target:GetStatusResistance())})
	end
end

modifier_item_soul_nullifier = class({})

function modifier_item_soul_nullifier:IsHidden() return true end
function modifier_item_soul_nullifier:IsPurgable() return false end
function modifier_item_soul_nullifier:IsPurgeException() return false end
function modifier_item_soul_nullifier:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_soul_nullifier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_soul_nullifier:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_soul_nullifier:GetModifierManaBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_soul_nullifier:OnTakeDamage(params)
    if not IsServer() then return end

    if self:GetParent() ~= params.attacker then return end

    if self:GetParent() == params.unit then return end

    if params.unit:IsBuilding() then return end

    if params.inflictor ~= nil and not self:GetParent():IsIllusion() and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= DOTA_DAMAGE_FLAG_REFLECTION then 
        
        if self:GetParent():FindAllModifiersByName("modifier_item_soul_nullifier")[1] ~= self then return end

        local bonus_percentage = 0
        
        for _, mod in pairs(self:GetParent():FindAllModifiers()) do
            if mod.GetModifierSpellLifestealRegenAmplify_Percentage and mod:GetModifierSpellLifestealRegenAmplify_Percentage() then
                bonus_percentage = bonus_percentage + mod:GetModifierSpellLifestealRegenAmplify_Percentage()
            end
        end

        local heal = self:GetAbility():GetSpecialValueFor("magic_lifesteal") / 100 * params.damage

        heal = heal * (bonus_percentage / 100 + 1)

        self:GetParent():Heal(heal, params.inflictor)

        local octarine = ParticleManager:CreateParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.attacker )
        ParticleManager:ReleaseParticleIndex( octarine )
    end
end

modifier_item_soul_nullifier_debuff = class({})

function modifier_item_soul_nullifier_debuff:IsPurgable() return false end

function modifier_item_soul_nullifier_debuff:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.2)

		local overhead_particle = ParticleManager:CreateParticle("particles/items4_fx/nullifier_mute.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
		self:AddParticle(overhead_particle, false, false, -1, false, false)
	end
end

function modifier_item_soul_nullifier_debuff:OnIntervalThink()
	if IsServer() then
		if not self:GetParent():IsMagicImmune() then
			self:GetParent():Purge(true, false, false, false, true)
		end
	end
end

function modifier_item_soul_nullifier_debuff:GetEffectName()
	return "particles/items4_fx/nullifier_mute_debuff.vpcf"
end

function modifier_item_soul_nullifier_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_nullifier.vpcf"
end




