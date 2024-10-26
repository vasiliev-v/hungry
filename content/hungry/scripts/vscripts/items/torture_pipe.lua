item_torture_pipe = class({})
item_torture_pipe_1 = item_torture_pipe
item_torture_pipe_2 = item_torture_pipe

LinkLuaModifier("modifier_item_torture_pipe", "items/torture_pipe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_torture_pipe_buff", "items/torture_pipe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_torture_pipe_debuff", "items/torture_pipe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_torture_pipe_buff",	"heroes/modifier_torture_pipe_buff", 	LUA_MODIFIER_MOTION_NONE)

function item_torture_pipe:GetIntrinsicModifierName()
	return "modifier_item_torture_pipe"
end

function item_torture_pipe:OnSpellStart()
	local caster = self:GetCaster()
	local unit = self:GetCursorTarget()

	if unit:TriggerSpellAbsorb(self) then return end
	if unit:IsMagicImmune() then return end

	local duration = self:GetSpecialValueFor("buff_duration")
	
	caster:EmitSound("DOTA_Item.SpiritVessel.Cast")
	local pfx = ParticleManager:CreateParticle("particles/items4_fx/spirit_vessel_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, unit:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx)

	if caster:GetTeamNumber() == unit:GetTeamNumber() then
		unit:AddNewModifier(caster, self, "modifier_item_torture_pipe_buff", {duration = duration})
	else
		unit:AddNewModifier(caster, self, "modifier_item_torture_pipe_debuff", {duration = duration})
	end
end

function item_torture_pipe:CastFilterResultTarget(target)
	local caster = self:GetCaster()

	-- Should not be cast on enemy ancients and magic immune enemies
	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		if target:IsAncient() then return UF_FAIL_ANCIENT end
		if target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
	end

	if target:IsOther() then return UF_FAIL_OTHER end

	return UF_SUCCESS
end

-- Item's passive component

modifier_item_torture_pipe = class({})

function modifier_item_torture_pipe:IsDebuff() return false end
function modifier_item_torture_pipe:IsHidden() return true end
function modifier_item_torture_pipe:IsPurgable() return false end
function modifier_item_torture_pipe:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_item_torture_pipe:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_item_torture_pipe:OnCreated(keys)
	self:OnRefresh(keys)
end

function modifier_item_torture_pipe:OnRefresh(keys)
	self.bonus_all_stats = self:GetAbility():GetSpecialValueFor("bonus_all_stats")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")

	if IsServer() then
		self:CacheDOTBoost()

		if self:GetParent() and self:GetParent().CalculateStatBonus then
			self:GetParent():CalculateStatBonus(false)
		end
	end
end

function modifier_item_torture_pipe:CacheDOTBoost()
	local torture_modifier = self:GetParent():FindModifierByName("modifier_torture_pipe_buff")
	if not torture_modifier then
		torture_modifier = self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_torture_pipe_buff", {})
	end

	if torture_modifier and not torture_modifier:IsNull() then
		torture_modifier:CacheDOTBoost()
	end
end

function modifier_item_torture_pipe:OnRemoved()
	if IsClient() then return end
	self:CacheDOTBoost()
end

function modifier_item_torture_pipe:GetModifierBonusStats_Strength()
	return self.bonus_all_stats or 0
end

function modifier_item_torture_pipe:GetModifierBonusStats_Agility()
	return self.bonus_all_stats or 0
end

function modifier_item_torture_pipe:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats or 0
end

function modifier_item_torture_pipe:GetModifierHealthBonus()
	return self.bonus_health or 0
end

function modifier_item_torture_pipe:GetModifierConstantManaRegen()
	return self.bonus_mana_regen or 0
end

function modifier_item_torture_pipe:GetModifierPhysicalArmorBonus()
	return self.bonus_armor or 0
end

-- 
-- Torture Pipe Buff/Debuff
--
modifier_item_torture_pipe_buff = class({})
function modifier_item_torture_pipe_buff:IsDebuff() return false end
function modifier_item_torture_pipe_buff:IsHidden() return false end
function modifier_item_torture_pipe_buff:IsPurgable() return true end

function modifier_item_torture_pipe_buff:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	self.ally_heal = self.ability:GetSpecialValueFor("ally_heal")

	if IsServer() then self:StartIntervalThink(1) end
end

function modifier_item_torture_pipe_buff:GetEffectName()
	return "particles/items2_fx/urn_of_shadows_heal.vpcf"
end

function modifier_item_torture_pipe_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_torture_pipe_buff:OnIntervalThink()
	self.parent:Heal(self.ally_heal, self.ability)
end

function modifier_item_torture_pipe_buff:DeclareFunctions() 
	return {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_item_torture_pipe_buff:GetModifierAvoidDamage(kv)
	-- Healing version of buff gets removed by player damage
	if (not kv.attacker:IsControllableByAnyPlayer()) then return end
	if bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then return end
	if kv.damage <= 0 then return end

	self:Destroy()
end

function modifier_item_torture_pipe_buff:OnTooltip()
	return self.ally_heal or 0
end

modifier_item_torture_pipe_debuff = class({})
function modifier_item_torture_pipe_debuff:IsDebuff() return true end
function modifier_item_torture_pipe_debuff:IsHidden() return false end
function modifier_item_torture_pipe_debuff:IsPurgable() return true end

function modifier_item_torture_pipe_debuff:OnCreated()
	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.enemy_dot_base = self.ability:GetSpecialValueFor("enemy_dot_base")
	self.enemy_dot_current_health = self.ability:GetSpecialValueFor("enemy_dot_current_health")
	self.heal_reduction = self.ability:GetSpecialValueFor("heal_reduction")

	if IsServer() then self:StartIntervalThink(1) end
end

function modifier_item_torture_pipe_debuff:GetEffectName()
	return "particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_item_torture_pipe_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_torture_pipe_debuff:OnIntervalThink()
	-- Attempts to damage through spell immunity
	if self.parent:IsMagicImmune() then return end

	-- Only base damage is amplified by spell amp
	local current_health_damage = self.parent:GetHealth() * self.enemy_dot_current_health * 0.01
	local total_damage = current_health_damage + self.enemy_dot_base * (1 + self.caster:GetSpellAmplification(false))

	ApplyDamage({
		victim = self.parent,
		attacker = self.caster,
		damage = total_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = self.ability
	})
end

function modifier_item_torture_pipe_debuff:DeclareFunctions() 
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end

function modifier_item_torture_pipe_debuff:GetModifierHealAmplify_PercentageTarget()
	return -1 * self.heal_reduction or 0
end

function modifier_item_torture_pipe_debuff:GetModifierHPRegenAmplify_Percentage()
	return -1 * self.heal_reduction or 0
end

function modifier_item_torture_pipe_debuff:OnTooltip()
	return self.enemy_dot_base or 0
end

function modifier_item_torture_pipe_debuff:OnTooltip2()
	return self.enemy_dot_current_health or 0
end
