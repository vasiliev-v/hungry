local PATH = "kbw/items/levels/aeon_disk"
local base = {}

-- function base:IgnoreSilence()
-- 	return true
-- end

function base:GetAbilityTextureName()
	local texture = self.BaseClass.GetAbilityTextureName(self)
	if self:IsPassiveCooldown() then
		return texture .. '_empty'
	end
	return texture
end

----------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_base = 0,
		m_item_generic_regen = 0,
		m_item_generic_armor = 0,
		m_item_kbw_aeon_disk_passive = self.nLevel,
	}
end

----------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('active_duration')

	-- dispel
	caster:Purge(false, true, false, true, true)

	-- add boost buff
	AddModifier('m_item_kbw_aeon_disk_active', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})

	-- decorate

	local particle = ParticleManager:Create('particles/items/aeon_disk/burst.vpcf', PATTACH_ABSORIGIN_FOLLOW, caster, duration + 1)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, 'attach_hitloc', caster:GetOrigin(), true)

	caster:EmitSound('KBW.Item.AeonDisk.Cast')
end

----------------------------------------------
-- passive cooldown

function base:StartPassiveCooldown()
	local caster = self:GetCaster()

	AddModifier('m_item_kbw_aeon_disk_cd',{
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		bAddToDead = true,
		bCalcDeadDuration = true,
		duration = self:GetSpecialValueFor('passive_cd'),
	})
end

function base:IsPassiveCooldown()
	return self:GetCaster():HasModifier('m_item_kbw_aeon_disk_cd')
end

----------------------------------------------
-- levels

CreateLevels({
	'item_kbw_aeon_disk',
	'item_kbw_aeon_disk_2',
	'item_kbw_aeon_disk_3',
}, base)

----------------------------------------------
----------------------------------------------
----------------------------------------------
-- active buff

LinkLuaModifier('m_item_kbw_aeon_disk_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_aeon_disk_active = ModifierClass{
	bPurgable = true,
}

----------------------------------------------
-- active buff stats

function m_item_kbw_aeon_disk_active:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function m_item_kbw_aeon_disk_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
	}
end

function m_item_kbw_aeon_disk_active:GetModifierMoveSpeed_AbsoluteMin()
	return self.active_speed
end

----------------------------------------------
-- active buff constructor

function m_item_kbw_aeon_disk_active:OnCreated()
	ReadAbilityData(self, {
		'active_speed',
	})

	if IsServer() then
		local parent = self:GetParent()

		self.mod_speed = parent:AddNewModifier(parent, nil, 'm_kbw_no_speed_limit', {})

		self.particle = ParticleManager:Create('particles/items/aeon_disk/boost.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', parent:GetOrigin(), true)
	end
end

function m_item_kbw_aeon_disk_active:OnDestroy()
	if IsServer() then
		if exist(self.mod_speed) then
			self.mod_speed:Destroy()
		end

		ParticleManager:Fade(self.particle, true)
	end
end

----------------------------------------------
----------------------------------------------
----------------------------------------------
-- passive tracker

LinkLuaModifier('m_item_kbw_aeon_disk_passive', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_aeon_disk_passive = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

----------------------------------------------
-- passive tracker constructor

function m_item_kbw_aeon_disk_passive:OnCreated()
	ReadAbilityData(self, {
		'passive_duration',
		'passive_restore',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_aeon_disk_passive:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
		FixItemModifierRemoved(self)
	end
end

----------------------------------------------
-- passive tracker death prevention

function m_item_kbw_aeon_disk_passive:IsDeathPreventor()
	return true
end

function m_item_kbw_aeon_disk_passive:IsDeathPreventorSoft()
	return true
end

function m_item_kbw_aeon_disk_passive:OnParentTakeDamageKillCredit(t)
	-- skip if inactive
	if not self:CanPassiveProc() then
		return
	end

	-- skip if damage is not lethal
	if t.damage + 1 < t.target:GetHealth() then
		return
	end

	-- skip insta killing effects
	if ShouldDie(t) then
		return
	end

	-- skip if blocked by other preventor
	if not IsKillable(t.target, self) then
		return
	end

	local ability = self:GetAbility()
	if not exist(ability) then
		return
	end

	-- add shield
	AddModifier('m_item_kbw_aeon_disk_shield', {
		hTarget = t.target,
		hCaster = self:GetCaster(),
		hAbility = ability,
		duration = self.passive_duration
	})

	-- restore
	t.target:SetHealth(1)
	t.target:Heal(t.target:GetMaxHealth() * self.passive_restore / 100, ability)

	-- dispel
	t.target:Purge(false, true, false, true, true)

	-- sound
	t.target:EmitSound('DOTA_Item.ComboBreaker')

	-- start cd
	ability:StartPassiveCooldown()

	-- prevent damage
	PreventDamage(t.target)
	PreventWkHueta(t.target)
end

----------------------------------------------
-- passive tracker util

function m_item_kbw_aeon_disk_passive:CanPassiveProc()
	local parent = self:GetParent()

	-- skip on illusions and on dead
	if parent:IsIllusion() or not parent:IsAlive() then
		return false
	end

	-- skip during cooldown
	if self:IsPassiveCooldown() then
		return false
	end

	return true
end

function m_item_kbw_aeon_disk_passive:IsPassiveCooldown()
	local ability = self:GetAbility()

	return not ability or not ability.IsPassiveCooldown or ability:IsPassiveCooldown()
end

----------------------------------------------
----------------------------------------------
----------------------------------------------
-- passive shield

LinkLuaModifier('m_item_kbw_aeon_disk_shield', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_aeon_disk_shield = ModifierClass{
	bPurgable = true,
}

----------------------------------------------
-- passive shield stats

function m_item_kbw_aeon_disk_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function m_item_kbw_aeon_disk_shield:GetModifierTotal_ConstantBlock(t)
	return t.damage
end

function m_item_kbw_aeon_disk_shield:GetModifierStatusResistanceStacking()
	return self.passive_status_resist
end

----------------------------------------------
-- passive shield costructor

function m_item_kbw_aeon_disk_shield:OnCreated()
	ReadAbilityData(self, {
		'passive_status_resist',
	})

	if IsServer() then
		local parent = self:GetParent()
		local origin = parent:GetOrigin()

		self.particle = ParticleManager:Create('particles/items4_fx/combo_breaker_buff.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, origin, false)
		-- ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', origin, false)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', origin, false)
	end
end

function m_item_kbw_aeon_disk_shield:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle)
	end
end

----------------------------------------------
----------------------------------------------
----------------------------------------------
-- passive cooldown

LinkLuaModifier('m_item_kbw_aeon_disk_cd', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_aeon_disk_cd = ModifierClass{
	bIgnoreDeath = true,
}

function m_item_kbw_aeon_disk_cd:IsDebuff()
	return true
end

function m_item_kbw_aeon_disk_cd:RemoveOnDuel()
	return false
end