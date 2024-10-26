local PATH = "kbw/items/daedalus"

------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_attack = 0,
		m_item_kbw_daedalus = 0,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local range = self:GetEffectiveCastRange(target, nil)
	local radius = self:GetSpecialValueFor('arrow_radius')
	local speed = self:GetSpecialValueFor('arrow_speed')
	local vision = self:GetSpecialValueFor('arrow_vision')

	local start = caster:GetOrigin()
	local dir = CasterDirection(caster, target)
	local vel = dir * speed
	local time = range / speed
	
	local particle = ParticleManager:Create('particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf')
	ParticleManager:SetParticleControl(particle, 0, start)
	ParticleManager:SetParticleControlForward(particle, 0, dir)
	ParticleManager:SetParticleControl(particle, 1, vel)
	ParticleManager:SetParticleControl(particle, 60, Vector(190, 40, 30))
	ParticleManager:SetParticleControl(particle, 61, Vector(1, 0, 0))
	ParticleManager:Fade(particle, time, true)
	
	caster:EmitSound('Kbw.Item.Daedalus.Cast')

	ProjectileManager:CreateLinearProjectile({
		Source = caster,
		Ability = self,
		vSpawnOrigin = start,
		vVelocity = vel,
		fDistance = range,
		fStartRadius = radius,
		fEndRadius = radius,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeam(),
		iVisionRadius = vision,
	})
end

function base:OnProjectileHit(target, pos)
	if target then
		local caster = self:GetCaster()
		
		self.proc = true
		caster:PerformAttack(target, false, true, true, true, false, false, true)
		self.proc = nil
		
		target:EmitSound('Kbw.Item.Daedalus.Hit')
	end
end

------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_daedalus',
	'item_kbw_daedalus_2',
	'item_kbw_daedalus_3',
}, base)

------------------------------------------------
-- modifier: passive

LinkLuaModifier('m_item_kbw_daedalus', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_daedalus = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_kbw_daedalus:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self.records = {}
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_daedalus:OnDestory()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_daedalus:OnRefresh(t)
	ReadAbilityData(self, {
		"crit",
		"crit_chance",
	})
	
	self.ability = self:GetAbility()
end

function m_item_kbw_daedalus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
end

function m_item_kbw_daedalus:GetModifierPreAttack_CriticalStrike(t)
	if (self.ability and self.ability.proc) or RandomFloat(0,100) <= self.crit_chance then
		self.records[t.record] = 1
		return self.crit
	end
end

function m_item_kbw_daedalus:OnParentAttackLanded(t)
	if self.records[t.record] then
		t.target:EmitSound('DOTA_Item.Daedelus.Crit')
	end
end

function m_item_kbw_daedalus:OnParentAttackRecordDestroy(t)
	if self.records[t.record] then
		self.records[t.record] = nil
	end
end