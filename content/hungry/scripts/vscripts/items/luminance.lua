item_luminance = class({})

LinkLuaModifier("modifier_item_luminance", "items/luminance", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_luminance_unique_passive", "items/luminance", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_luminance_active", "items/luminance", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_luminance_burn", "items/luminance", LUA_MODIFIER_MOTION_NONE)

function item_luminance:GetAbilityTextureName()
	local caster = self:GetCaster()
	if not caster.GetStrength then return "luminance_off" end
	if caster:GetStrength() > max(caster:GetIntellect(), caster:GetAgility()) then
		return "luminance"
	end
	return "luminance_off"
end

-- Item Passive
function item_luminance:GetIntrinsicModifierName()
	return "modifier_item_luminance"
end

-- Item Active
function item_luminance:OnSpellStart()
	local caster = self:GetCaster()

	local duration = self:GetSpecialValueFor("duration")
	local aura_radius = self:GetSpecialValueFor("aura_radius")
	local active_reflection_pct = self:GetSpecialValueFor("active_reflection_pct")

	caster:EmitSound("DOTA_Item.BladeMail.Activate")
	caster:AddNewModifier(caster, self, "modifier_item_luminance_active", {
		duration = duration, 
		aura_radius = aura_radius, 
		reflect_pct = active_reflection_pct
	})
end

modifier_item_luminance_active = class({})

-- Blademail active
function modifier_item_luminance_active:IsDebuff() return false end
function modifier_item_luminance_active:IsPurgable() return false end
function modifier_item_luminance_active:IsHidden() return false end

function modifier_item_luminance_active:GetTexture() return "item_luminance" end

function modifier_item_luminance_active:GetEffectName()
	return "particles/items/luminance_active.vpcf"
end

function modifier_item_luminance_active:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_luminance_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_AVOID_DAMAGE
	}
	return funcs
end

function modifier_item_luminance_active:OnCreated(keys)
	if not IsServer() then return end

	self.reflect_pct = keys.reflect_pct
	self.aura_radius = keys.aura_radius

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local origin = parent:GetAbsOrigin()

	local particle = ParticleManager:CreateParticle("particles/items/luminance.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, origin)
	ParticleManager:SetParticleControl(particle, 2, Vector(self.aura_radius, 1, 1))

	self:AddParticle(particle, true, false, 1, true, false)

	self.parent = parent

end

function modifier_item_luminance_active:GetModifierAvoidDamage(keys)
	if not keys.target or keys.target:IsNull() then return end
	if not keys.attacker or keys.attacker:IsNull() then return end
	if not self.parent or self.parent:IsNull() then return end
	if not self.parent:IsAlive() then return end
	if keys.attacker:IsMagicImmune() then return end
	if keys.attacker:GetTeamNumber() == self.parent:GetTeamNumber() then return end
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then return end
	if keys.target:IsOther() then return end

	if keys.attacker.GetPlayerOwner then
		EmitSoundOnClient("DOTA_Item.BladeMail.Damage", keys.attacker:GetPlayerOwner())
	end

	local damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION

	if keys.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_DISABLE_WHILE_ETHEREAL
	end

	local damage_table = {
		victim = keys.attacker,
		damage = keys.original_damage * self.reflect_pct * 0.01,
		damage_type = keys.damage_type,
		damage_flags = damage_flags,
		attacker = self.parent,
		ability = self:GetAbility()
	}
	
	ApplyDamage(damage_table)

	return 0
end



modifier_item_luminance = class({})

function modifier_item_luminance:IsDebuff() return false end
function modifier_item_luminance:IsHidden() return true end
function modifier_item_luminance:IsPurgable() return false end
function modifier_item_luminance:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_item_luminance:GetEffectName()
	return "particles/items/luminance_passive.vpcf"
end

function modifier_item_luminance:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_luminance:OnCreated(keys)
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if IsServer() then
	parent:AddNewModifier(parent, self:GetAbility(), "modifier_item_luminance_unique_passive", {
		passive_reflection_pct = ability:GetSpecialValueFor("passive_reflection_pct"),
		str_reflect_multiplier_duel = ability:GetSpecialValueFor("str_reflect_multiplier_duel"),
		str_reflect_multiplier_round = ability:GetSpecialValueFor("str_reflect_multiplier_round")
	})
    end
    
	self.bonus_dmg = ability:GetSpecialValueFor("bonus_dmg")
	self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
	self.bonus_str = ability:GetSpecialValueFor("bonus_str")
	self.status_resistance = ability:GetSpecialValueFor("status_resistance")
	self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
end

-- Remove unique effect if this is the last Luminance in this unit's inventory
function modifier_item_luminance:OnDestroy()
	if not IsServer() then return end

    local parent = self:GetParent()

	if not parent:HasModifier("modifier_item_luminance") then
		parent:RemoveModifierByName("modifier_item_luminance_unique_passive")
	end
end

function modifier_item_luminance:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_item_luminance:GetModifierPreAttack_BonusDamage()
	return self.bonus_dmg
end

function modifier_item_luminance:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end



-- Unique passive
modifier_item_luminance_unique_passive = class({})

function modifier_item_luminance_unique_passive:IsDebuff() return false end
function modifier_item_luminance_unique_passive:IsHidden() return true end
function modifier_item_luminance_unique_passive:IsPurgable() return false end
function modifier_item_luminance_unique_passive:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_item_luminance_unique_passive:IsAura() return true end
function modifier_item_luminance_unique_passive:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_item_luminance_unique_passive:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_item_luminance_unique_passive:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_item_luminance_unique_passive:GetModifierAura() return "modifier_item_luminance_burn" end
function modifier_item_luminance_unique_passive:GetAuraRadius() return self.aura_radius end

function modifier_item_luminance_unique_passive:OnCreated(keys)
	if not IsServer() then return end

	if self:GetParent():IsIllusion() then
		self:Destroy()
	end

	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
	self.passive_reflection_pct = keys.passive_reflection_pct
	self.str_reflect_multiplier_duel = keys.str_reflect_multiplier_duel
	self.str_reflect_multiplier_round = keys.str_reflect_multiplier_round
end

function modifier_item_luminance_unique_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
	}
	return funcs
end

function modifier_item_luminance_unique_passive:GetModifierAvoidDamage(keys)
	-- Does not stack with blademail
	if keys.target:HasModifier("modifier_item_blade_mail_lua") then
		return
	end

	-- Does not pierce spell immunity
	if keys.attacker:IsMagicImmune() then return end

	-- Does not work on allies
	if keys.attacker:GetTeamNumber() == keys.target:GetTeamNumber() then return end

	-- Does not work on hp removal, reflected damage, and spell damage
	if bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION
	or bit.band(keys.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS
	or keys.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK
	then return 0 end

	-- For units with an inventory but no attributes
	local strength = 0
	if keys.target.GetStrength then
		strength = keys.target:GetStrength()
	end

	-- Calculate and deal damage
	local str_multiplier = keys.target:HasModifier("modifier_hero_dueling") and self.str_reflect_multiplier_duel or self.str_reflect_multiplier_round
	local damage = (keys.original_damage * self.passive_reflection_pct + strength * str_multiplier) * 0.01

	local damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION

	if keys.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		damage_flags = damage_flags + DOTA_DAMAGE_FLAG_DISABLE_WHILE_ETHEREAL
	end

	local damage_table = {
		victim = keys.attacker,
		attacker = keys.target,
		damage = damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		damage_flags = damage_flags,
	}

	ApplyDamage(damage_table)

	return 0
end


modifier_item_luminance_burn = class({})

function modifier_item_luminance_burn:IsDebuff() return true end
function modifier_item_luminance_burn:IsHidden() return false end
function modifier_item_luminance_burn:IsPurgable() return false end

function modifier_item_luminance_burn:GetTexture()
	return "item_luminance"
end

function modifier_item_luminance_burn:OnCreated(keys)
	if not IsServer() then return end

	local ability = self:GetAbility()

	if not ability or ability:IsNull() then
		self:Destroy() 
		return 
	end

	local parent = self:GetParent()

	if parent.GetPlayerOwnerID then
		EmitSoundOnEntityForPlayer("DOTA_Item.Radiance.Target.Loop", self:GetParent(), parent:GetPlayerOwnerID())
	end

	self.base_damage 				= ability:GetSpecialValueFor("aura_damage")
	self.str_aura_multiplier_duel 	= ability:GetSpecialValueFor("str_aura_multiplier_duel")
	self.str_aura_multiplier_round 	= ability:GetSpecialValueFor("str_aura_multiplier_round")
	self.high_str_multiplier 		= ability:GetSpecialValueFor("high_str_multiplier")

	self.burn_pfx = ParticleManager:CreateParticle("particles/items/luminance_burn.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.burn_pfx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), false)
	ParticleManager:SetParticleControlEnt(self.burn_pfx, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), false)

	self:StartIntervalThink(ability:GetSpecialValueFor("think_interval"))
end

function modifier_item_luminance_burn:OnDestroy()
	if not IsServer() then return end

	StopSoundOn("DOTA_Item.Radiance.Target.Loop", self:GetParent())

	if self.burn_pfx then
		ParticleManager:DestroyParticle(self.burn_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.burn_pfx)
	end
end

function modifier_item_luminance_burn:OnIntervalThink()
	if not IsServer() then return end

	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end

	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then return end

	local str_aura_multiplier = parent:HasModifier("modifier_hero_dueling") and self.str_aura_multiplier_duel or self.str_aura_multiplier_round
	local strength = 0
	if caster.GetStrength and caster.GetIntellect and caster.GetAgility then
		strength = caster:GetStrength() * str_aura_multiplier * 0.01
		if caster:GetStrength() > max(caster:GetIntellect(), caster:GetAgility()) then
			strength = strength * self.high_str_multiplier
		end
	end
    
	local damage_table = {
		victim = parent,
		attacker = caster,
		ability = ability,
		damage = self.base_damage + strength / (1 + caster:GetSpellAmplification(false)),
		damage_type = DAMAGE_TYPE_MAGICAL
	}
	ApplyDamage(damage_table)
end
