LinkLuaModifier('m_sand_king_burrowstrike_kbw_phase', "kbw/abilities/heroes/sand_king/burrowstrike", LUA_MODIFIER_MOTION_HORIZONTAL)

sand_king_burrowstrike_kbw = class{}

function sand_king_burrowstrike_kbw:GetCastRange(vPos, hTarget)
	return self:GetSpecialValueFor('cast_range')
end

function sand_king_burrowstrike_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	local vStart = self:GetCaster():GetOrigin()
	local vTarget = self:GetCursorPosition()
	local hTarget = self:GetCursorTarget()
	local nWidth = self:GetSpecialValueFor('width')
	local nDuration = self:GetSpecialValueFor('phase_time')
	local nDamage = self:GetSpecialValueFor('damage')
	local nStun = self:GetSpecialValueFor('stun')
	local nScepterAttack = self:GetSpecialValueFor('scepter_damage_mult') * 100
	local nKnockbackDuration = self:GetSpecialValueFor('knockback_duration')
	local nKnockbackHeight = self:GetSpecialValueFor('knockback_height')
	self.vPos = vStart

	if hTarget then
		vTarget = hTarget:GetOrigin()
	end

	local vDir = vTarget - vStart
	vDir.z = 0
	local nRange = #vDir
	if nRange < 0.1 then
		vDir = hCaster:GetForwardVector()
		nRange = 1
	end
	vDir = vDir:Normalized()

	local nSpeed = nRange / nDuration

	local nParticle = ParticleManager:CreateParticle('particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf', PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(nParticle, 0, vStart)
	ParticleManager:SetParticleControl(nParticle, 1, vTarget)

	local hMod = AddModifier('m_sand_king_burrowstrike_kbw_phase', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
	})

	Timer(0.1, function()
		if exist(hMod) then
			hCaster:AddNoDraw()
		end
	end)

	ProjectileManager:CreateLinearProjectile({
		Source = hCaster,
		Ability = self,
		vSpawnOrigin = vStart,
		vVelocity = vDir * nSpeed,
		fDistance = nRange,
		fStartRadius = nWidth,
		fEndRadius = nWidth,
		iUnitTargetTeam = self:GetAbilityTargetTeam(),
		iUnitTargetType = self:GetAbilityTargetType(),
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		ExtraData = {
			nParticle = nParticle,
			nDamage = nDamage,
			nStun = nStun,
			nScepterAttack = nScepterAttack,
			nKnockbackHeight = nKnockbackHeight,
		},
	})

	hCaster:EmitSound('Ability.SandKing_BurrowStrike')
end

function sand_king_burrowstrike_kbw:OnProjectileThink(vPos)
	self.vPos = vPos
end

function sand_king_burrowstrike_kbw:OnProjectileHit_ExtraData(hTarget, vPos, tData)
	if hTarget then
		self:AffectUnit({
			hTarget = hTarget,
			nDamage = tData.nDamage,
			nStun = tData.nStun,
			nScepterAttack = tData.nScepterAttack,
			nKnockbackDuration = tData.nKnockbackDuration,
			nKnockbackHeight = tData.nKnockbackHeight,
		})
	else
		local hCaster = self:GetCaster()

		hCaster:RemoveNoDraw()
		hCaster:StartGesture(ACT_DOTA_SAND_KING_BURROW_OUT)

		if hCaster:HasModifier('m_sand_king_burrowstrike_kbw_phase') then
			hCaster:RemoveModifierByName('m_sand_king_burrowstrike_kbw_phase')
			FindClearSpaceForUnit(hCaster, vPos, false)
		end

		if tData.nParticle then
			ParticleManager:Fade(tData.nParticle, true)
		end
	end
end

function sand_king_burrowstrike_kbw:AffectUnit(t)
	if not t or not exist(t.hTarget) then
		return
	end

	if t.hTarget:TriggerSpellAbsorb(self) then
		return
	end

	local hCaster = self:GetCaster()
	local vPos = t.hTarget:GetOrigin()
	t.nDamage = t.nDamage or self:GetSpecialValueFor('damage')
	t.nStun = t.nStun or self:GetSpecialValueFor('stun')
	t.nScepterAttack = t.nScepterAttack or self:GetSpecialValueFor('scepter_damage_mult') * 100
	t.nKnockbackDuration = t.nKnockbackDuration or self:GetSpecialValueFor('knockback_duration')
	t.nKnockbackHeight = t.nKnockbackHeight or self:GetSpecialValueFor('knockback_height')

	t.hTarget:AddNewModifier(hCaster, self, 'modifier_knockback', {
		should_stun = 0,
		knockback_distance = 0,
		knockback_duration = t.nKnockbackDuration,
		duration = t.nKnockbackDuration,
		knockback_height = t.nKnockbackHeight,
		center_x = vPos.x,
		center_y = vPos.y,
		center_z = vPos.z,
	})

	AddModifier('modifier_stunned', {
		hTarget = t.hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = t.nStun,
	})

	if hCaster:HasScepter() then
		local hDamageBuff =  AddModifier('m_damage_pct', {
			hTarget = hCaster,
			hCaster = hCaster,
			hAbility = self,
			nDamage = t.nScepterAttack - 100,
		})

		hCaster:PerformAttack(t.hTarget, true, true, true, true, false, false, true)

		if exist(hDamageBuff) then
			hDamageBuff:Destroy()
		end
	end

	if t.hTarget:IsAlive() then
		ApplyDamage({
			victim = t.hTarget,
			attacker = hCaster,
			ability = self,
			damage = t.nDamage,
			damage_type = self:GetAbilityDamageType(),
		})
	end
end

m_sand_king_burrowstrike_kbw_phase = ModifierClass{
	bHidden = true,
}

function m_sand_king_burrowstrike_kbw_phase:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function m_sand_king_burrowstrike_kbw_phase:OnCreated()
	if IsServer() then
		self.hParent = self:GetParent()
		self.hAbility = self:GetAbility()

		if not self.hAbility or not self:ApplyHorizontalMotionController() then
			self:Destroy()
		end
	end
end

function m_sand_king_burrowstrike_kbw_phase:UpdateHorizontalMotion(hUnit, nDT)
	if self.hAbility.vPos then
		self.hParent:SetAbsOrigin(self.hAbility.vPos)
	end
end

function m_sand_king_burrowstrike_kbw_phase:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function m_sand_king_burrowstrike_kbw_phase:OnDestroy()
	if IsServer() then
		self.hParent:RemoveHorizontalMotionController(self)
		FindClearSpaceForUnit(self.hParent, self.hParent:GetOrigin(), false)
	end
end