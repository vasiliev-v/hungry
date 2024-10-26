local PATH = "kbw/items/levels/ethereal_blade"
local base = {}

------------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_spell_damage = 0,
	}
end

------------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target then
		return
	end

	ProjectileManager:CreateTrackingProjectile({
		EffectName = 'particles/items_fx/ethereal_blade.vpcf',
		Source = caster,
		Target = target,
		Ability = self,
		vSourceLoc = caster:GetOrigin(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		iMoveSpeed = self:GetSpecialValueFor('active_speed'),
	})

	caster:EmitSound('DOTA_Item.EtherealBlade.Activate')
end

function base:OnProjectileHit(target, pos)
	local caster = self:GetCaster()

	if not target then
		return
	end

	if UnitFilter(
		target,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_DAMAGE_FLAG_NONE,
		caster:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	if target:TriggerSpellAbsorb(self) then
		return
	end

	local enemy = (target:GetTeam() ~= caster:GetTeam())
	local buff = enemy and 'm_item_kbw_ethereal_blade_active_debuff' or 'm_item_kbw_ethereal_blade_active_buff'

	AddModifier(buff, {
		hTarget = target,
		hCaster = caster,
		hAbility = self,
		duration = self:GetSpecialValueFor('active_duration')
	})

	if enemy then
		local damage =
			self:GetSpecialValueFor('active_damage_base') +
			target:GetMaxHealth() * self:GetSpecialValueFor('active_damage_pct') / 100

		ApplyDamage({
			victim = target,
			attacker = caster,
			ability = self,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
		})
	end

	target:EmitSound('DOTA_Item.EtherealBlade.Target')
end

------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_ethereal_blade',
	'item_kbw_ethereal_blade_2',
	'item_kbw_ethereal_blade_3',
}, base)


------------------------------------------------
------------------------------------------------
------------------------------------------------
-- active effect

local shared = ModifierClass{
	bPurgable = true,
}

function shared:StatusEffectPriority()
	return 9999
end

function shared:GetStatusEffectName()
	return 'particles/status_fx/status_effect_ghost.vpcf'
end

function shared:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function shared:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function shared:GetAbsoluteNoDamagePhysical()
	return 1
end

for mod_name in pairs({
	m_item_kbw_ethereal_blade_active_buff = 1,
	m_item_kbw_ethereal_blade_active_debuff = 1,
}) do
	LinkLuaModifier(mod_name, PATH, LUA_MODIFIER_MOTION_NONE)
	local mod = class{}
	for k, v in pairs(shared) do
		mod[k] = v
	end
	_G[mod_name] = mod
end

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- active debuff

function m_item_kbw_ethereal_blade_active_debuff:DeclareFunctions()
	return table.overlay(shared:DeclareFunctions(), {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	})
end

function m_item_kbw_ethereal_blade_active_debuff:GetModifierMoveSpeedBonus_Constant()
	return -self.active_slow
end

function m_item_kbw_ethereal_blade_active_debuff:OnRefresh(t)
	self:OnCreated(t)
end

function m_item_kbw_ethereal_blade_active_debuff:OnCreated()
	ReadAbilityData(self, {
		'active_magic_pure',
		'active_slow',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_ethereal_blade_active_debuff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_ethereal_blade_active_debuff:OnParentTakeDamage(t)
	if t.damage_type ~= DAMAGE_TYPE_MAGICAL or t.original_damage <= 0 then
		return
	end

	ApplyDamage({
		victim = t.unit,
		attacker = t.attacker,
		ability = self:GetAbility(),
		damage = t.original_damage * self.active_magic_pure / 100,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, t.damage_flags),
	})
end