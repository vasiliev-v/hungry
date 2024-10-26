local PATH = "kbw/abilities/heroes/faceless_void/faceless_void_time_lock"

faceless_void_time_lock_kbw = class {}

LinkLuaModifier('m_faceless_void_time_lock_buff', PATH, 0)
LinkLuaModifier('m_faceless_void_time_lock_passive', PATH, 0)
LinkLuaModifier('m_faceless_void_time_lock_stun', PATH, 0)
LinkLuaModifier('m_faceless_void_time_lock_damage', PATH, 0)

function faceless_void_time_lock_kbw:GetIntrinsicModifierName()
	return 'm_faceless_void_time_lock_passive'
end

function faceless_void_time_lock_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	hCaster:EmitSound('Hero_FacelessVoid.TimeDilation.Target')
	AddModifier('m_faceless_void_time_lock_buff', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor("duration"),
	})
end

function faceless_void_time_lock_kbw:AffectPoint(t)
	local hCaster = self:GetCaster()
	t = t or {}
	t.vPos = t.vPos or hCaster:GetOrigin()
	t.nRadius = t.nRadius or self:GetSpecialValueFor('scepter_radius')

	local qUnits = Find:UnitsInRadius({
		vCenter = t.vPos,
		nRadius = t.nRadius,
		nTeam = hCaster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	})

	local tAffect = {
		nStun = t.nStun,
		nAttacks = t.nAttacks,
	}

	for _, hUnit in ipairs(qUnits) do
		tAffect.hTarget = hUnit
		self:AffectUnit(tAffect)
	end

	hCaster:EmitSound('Hero_FacelessVoid.TimeWalk.Aeons')

	ParticleManager:Create('particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf',
		PATTACH_ABSORIGIN_FOLLOW, hCaster, 1)
end

function faceless_void_time_lock_kbw:AffectUnit(t)
	if not t or not exist(t.hTarget) then
		return
	end

	local hTarget = t.hTarget
	t.nDamage = t.nDamage or self:GetSpecialValueFor('proc_damage')
	t.nStun = t.nStun or self:GetSpecialValueFor('duration_stun')
	t.nDelay = t.nDelay or self:GetSpecialValueFor('delay')
	t.nAttacks = t.nAttacks or 1

	local vPos = hTarget:GetOrigin()
	local hCaster = self:GetCaster()

	local nParticle = ParticleManager:Create("particles/units/heroes/hero_faceless_void/faceless_void_time_lock_bash.vpcf",
		PATTACH_CUSTOMORIGIN, 3)
	ParticleManager:SetParticleControl(nParticle, 0, vPos)
	ParticleManager:SetParticleControl(nParticle, 1, vPos)
	ParticleManager:SetParticleControlEnt(nParticle, 2, hCaster, PATTACH_ABSORIGIN, "attach_hitloc", Vector(0, 0, 0), false)

	hTarget:EmitSound("Hero_FacelessVoid.TimeLockImpact")

	AddModifier('m_faceless_void_time_lock_stun', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = t.nStun,
	})

	Timer(t.nDelay, function()
		if exist(hCaster) and exist(hTarget) then
			if t.nAttacks > 1 then
				self.nAttacks = t.nAttacks - 1
			end

			local hMod = hCaster:AddNewModifier(hCaster, self, 'm_faceless_void_time_lock_damage', {
				damage = t.nDamage,
			})

			hCaster:PerformAttack(hTarget, true, true, true, true, false, false, true)

			self.nAttacks = nil

			if hMod then
				hMod:Destroy()
			end
		end
	end)
end

-----------------------------------------------

m_faceless_void_time_lock_buff = class {}

function m_faceless_void_time_lock_buff:IsPurgable()
	return false
end

function m_faceless_void_time_lock_buff:IsPurgeException()
	return false
end

function m_faceless_void_time_lock_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function m_faceless_void_time_lock_buff:OnCreated()
	if IsServer() then
		self.nParticle = ParticleManager:Create('particles/units/heroes/hero_void_spirit/astral_step/void_spirit_astral_step_debuff.vpcf'
			, self:GetParent())
	end

	ReadAbilityData(self, {
		'bonus_attack_speed',
	}, function(hAbility)
		self.hAbility = hAbility
	end)
end

function m_faceless_void_time_lock_buff:OnDestroy()
	if IsServer() then
		if self.nParticle then
			ParticleManager:Fade(self.nParticle, true)
		end
	end
end

function m_faceless_void_time_lock_buff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

-----------------------------------------------

m_faceless_void_time_lock_passive = ModifierClass {
	bHidden = true,
	bPermanent = true,
}

function m_faceless_void_time_lock_passive:OnCreated()
	ReadAbilityData(self, {
		'chance_pct',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_faceless_void_time_lock_passive:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_faceless_void_time_lock_passive:OnParentAttackLanded(t)
	local hCaster = self:GetCaster()

	if not t.target or not t.target:IsBaseNPC()
		or UnitFilter(
			t.target,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			hCaster:GetTeam()
		) ~= UF_SUCCESS then
		return
	end

	local hAbility = self:GetAbility()

	if hAbility.nAttacks
		or (hCaster:HasModifier('m_faceless_void_time_lock_buff') and RollPercentage(self.chance_pct)) then
		if hAbility and hAbility.AffectUnit then
			hAbility:AffectUnit({
				hTarget = t.target,
				nAttacks = hAbility.nAttacks,
			})
		end
	end
end

function m_faceless_void_time_lock_passive:OnParentAbilityFullyCast(t)
	local hCaster = self:GetParent()

	if not hCaster:HasScepter() then
		return
	end

	if not exist(t.ability) or t.ability:GetName() ~= 'faceless_void_time_walk' then
		return
	end

	local hTimeLock = hCaster:FindAbilityByName('faceless_void_time_lock_kbw')

	if not exist(hTimeLock) or not hTimeLock:IsTrained() or not hTimeLock.AffectPoint then
		return
	end

	local hBuff = hCaster:FindModifierByName('modifier_faceless_void_time_walk')

	Timer(function()
		if exist(hBuff) then
			return FrameTime()
		end

		if exist(hTimeLock) and exist(t.ability) then
			hTimeLock:AffectPoint({
				vPos = hCaster:GetOrigin(),
				nRadius = t.ability:GetSpecialValueFor('radius_scepter'),
				nAttacks = t.ability:GetSpecialValueFor('scepter_procs'),
			})
		end
	end)
end

-----------------------------------------------

m_faceless_void_time_lock_damage = ModifierClass {
	bHidden = true,
	bPermanent = true,
}

function m_faceless_void_time_lock_damage:OnCreated(t)
	if IsServer() then
		self.damage = t.damage
	end
end

function m_faceless_void_time_lock_damage:DeclareFunctions()
	if IsServer() then
		return {
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		}
	end
end

function m_faceless_void_time_lock_damage:GetModifierPreAttack_BonusDamage()
	return self.damage
end

m_faceless_void_time_lock_stun = ModifierClass {}

function m_faceless_void_time_lock_stun:IsPurgable()
	return false
end

function m_faceless_void_time_lock_stun:IsStunDebuff()
	return true
end

function m_faceless_void_time_lock_stun:GetStatusEffectName()
	return 'particles/status_fx/status_effect_faceless_chronosphere.vpcf'
end

function m_faceless_void_time_lock_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end

function m_faceless_void_time_lock_stun:OnCreated()
	if IsServer() then
		local parent = self:GetParent()
		self.particle = ParticleManager:Create('particles/generic_gameplay/generic_stunned.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), false)
	end
end

function m_faceless_void_time_lock_stun:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle)
	end
end
