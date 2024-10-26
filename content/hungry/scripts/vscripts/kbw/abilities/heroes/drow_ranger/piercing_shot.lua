local sPath = "kbw/abilities/heroes/drow_ranger/piercing_shot"

local nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
local nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
local nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE

drow_ranger_piercing_shot = class{}

function drow_ranger_piercing_shot:GetIntrinsicModifierName()
	return 'm_drow_ranger_piercing_shot'
end

function drow_ranger_piercing_shot:GetPlaybackRateOverride()
	return 1.8
end

function drow_ranger_piercing_shot:GetCastRange()
	return self:GetSpecialValueFor('range')
end

function drow_ranger_piercing_shot:OnSpellStart()
	self:CastPoint({
		vTarget = self:GetCursorPosition(),
	})
end

function drow_ranger_piercing_shot:CastPoint(t)
	local hCaster = self:GetCaster()
	t.nStun = t.nStun or self:GetSpecialValueFor('stun')

	local hTalent = hCaster:FindAbilityByName('special_bonus_unique_drow_ranger_piercing_shot_multiply')
	if hTalent and hTalent:GetLevel() > 0 then
		local vStart = hCaster:GetOrigin()
		local vDir = (t.vTarget-vStart)
		vDir.z = 0
		if #vDir < 0.1 then
			vDir = hCaster:GetForwardVector()
		end
		vDir = vDir:Normalized()

		local nBaseAngle = math.atan2(vDir.y, vDir.x)
		local nDeltaAngle = hTalent:GetSpecialValueFor('angle') * math.pi / 180
		local nArrows = hTalent:GetSpecialValueFor('arrows')
		self.nNextHit = (self.nNextHit or 0) + 1

		for nArrow = -nArrows, nArrows do
			local nAngle = nBaseAngle + nDeltaAngle * nArrow
			local vDir = Vector(math.cos(nAngle), math.sin(nAngle), 0)
			local t = table.copy(t)
			t.vTarget = vStart + vDir
			t.nHitIndex = self.nNextHit
			self:ThrowPoint(t)
		end
	else
		self:ThrowPoint(t)
	end

	hCaster:EmitSoundParams('Hero_DrowRanger.FrostArrows', 2, 2.5, 0)
end

function drow_ranger_piercing_shot:ThrowPoint(t)
	local hCaster = self:GetCaster()
	local vStart = hCaster:GetOrigin()
	local nRange = self:GetEffectiveCastRange(t.vTarget, nil)
	local nSpeed = self:GetSpecialValueFor('speed')
	local nWidth = self:GetSpecialValueFor('width')
	local nVision = self:GetSpecialValueFor('vision_radius')
	t.nStun = t.nStun or self:GetSpecialValueFor('stun')

	local vDir = (t.vTarget-vStart)
	vDir.z = 0
	if #vDir < 0.1 then
		vDir = hCaster:GetForwardVector()
	end
	vDir = vDir:Normalized()

	local vVel = vDir * nSpeed

	local nParticle = ParticleManager:Create('particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf')
	ParticleManager:SetParticleControl(nParticle, 0, vStart)
	ParticleManager:SetParticleControlForward(nParticle, 0, vDir)
	ParticleManager:SetParticleControl(nParticle, 1, vVel)
	ParticleManager:SetParticleControl(nParticle, 60, Vector(60, 90, 200))
	ParticleManager:SetParticleControl(nParticle, 61, Vector(1, 0, 0))

	if t.nHitIndex then
		if not self.tHits then
			self.tHits = {}
		end

		local tHits = self.tHits[t.nHitIndex]
		if not tHits then
			tHits = {
				tAffected = {},
				nCount = 0
			}
			self.tHits[t.nHitIndex] = tHits
		end

		tHits.nCount = tHits.nCount + 1
	end

	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		Source = hCaster,
		vSpawnOrigin = vStart,
		vVelocity = vVel,
		fDistance = nRange,
		fStartRadius = nWidth,
		fEndRadius = nWidth,
		iUnitTargetTeam = self:GetAbilityTargetTeam(),
		iUnitTargetType = self:GetAbilityTargetType(),
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		ExtraData = {
			nParticle = nParticle,
			nDamage = nDamage,
			nStun = t.nStun,
			nWidth = nWidth,
			nVision = nVision,
			nVisionTeam = hCaster:GetTeam(),
			nHitIndex = t.nHitIndex,
			bLinear = true,
		},
	})
end

function drow_ranger_piercing_shot:ThrowTarget(t)
	if not t or not exist(t.hTarget) or not t.hTarget:IsAlive() then
		return
	end

	t = table.copy(t)
	t.nSplits = t.nSplits or self:GetSpecialValueFor('scepter_max_splits') - 1
	local hCaster = self:GetCaster()
	local nSpeed = hCaster:GetProjectileSpeed()
	local bProc = (t.nSplits > 0) and (RandomFloat(0,100) <= self:GetSpecialValueFor('chance'))
	local sParticle = bProc
			and 'particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf'
			or hCaster:GetRangedProjectileName()

	if t.hSource then
		ProjectileManager:CreateTrackingProjectile({
			Ability = self,
			Target = t.hTarget,
			Source = t.hSource,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
			iMoveSpeed = nSpeed,
			EffectName = sParticle,
			ExtraData = {
				bTracking = true,
				bProc = bProc and 1 or 0,
				nSplits = t.nSplits,
			}
		})
	else
		local nHeight = 600
		local vPos = t.hTarget:GetOrigin()
		local nParticle = ParticleManager:CreateParticle(sParticle, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(nParticle, 0, vPos + Vector(0,0,nHeight))
		ParticleManager:SetParticleControlEnt(nParticle, 1, t.hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', vPos, false)
		ParticleManager:SetParticleControl(nParticle, 2, Vector(nSpeed, 0, 0))

		Timer(nHeight / nSpeed, function()		
			if exist(t.hTarget) and t.hTarget:IsAlive() then
				self:Effect2({
					hTarget = t.hTarget,
					bProc = bProc,
					nSplits = t.nSplits,
				})
			end

			ParticleManager:Fade(nParticle, true)
		end)
	end
end

function drow_ranger_piercing_shot:OnProjectileThink_ExtraData(vPos, tData)
	if tData.bLinear then
		AddFOWViewer(tData.nVisionTeam, vPos, tData.nVision, 1/30, false)
		GridNav:DestroyTreesAroundPoint(vPos, tData.nWidth, false)
	end
end

function drow_ranger_piercing_shot:OnProjectileHit_ExtraData(hTarget, vPos, tData)
	if tData.bLinear then
		if hTarget then
			if tData.nHitIndex and self.tHits then
				local tHits = self.tHits[tData.nHitIndex]
				if tHits then
					if tHits.tAffected[hTarget] then
						return
					end
					tHits.tAffected[hTarget] = true
				end
			end

			self:Effect({
				hTarget = hTarget,
				nDamage = tData.nDamage,
				nStun = tData.nStun,
			})
		else
			if tData.nHitIndex and self.tHits then
				local tHits = self.tHits[tData.nHitIndex]
				if tHits then
					if tHits.nCount < 2 then
						self.tHits[tData.nHitIndex] = nil
					else
						tHits.nCount = tHits.nCount - 1
					end
				end
			end

			if tData.nParticle then
				ParticleManager:Fade(tData.nParticle, true)
				tData.nParticle = nil
			end
		end
	elseif tData.bTracking then
		if hTarget and hTarget:IsAlive() and not hTarget:IsAttackImmune() then
			self:Effect2({
				hTarget = hTarget,
				bProc = (tData.bProc and tData.bProc ~= 0),				
				nSplits = tData.nSplits,
			})
		end
	end
end

function drow_ranger_piercing_shot:Effect(t)
	if not t or not exist(t.hTarget) then
		return
	end

	local hCaster = self:GetCaster()
	t.nStun = t.nStun or self:GetSpecialValueFor('stun')

	t.hTarget:EmitSound('Hero_DrowRanger.Marksmanship.Target')

	ApplyDamage({
		victim = t.hTarget,
		attacker = hCaster,
		ability = self,
		damage = hCaster:GetAverageTrueAttackDamage(t.hTarget),
		damage_type = self:GetAbilityDamageType(),
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
	})

	if t.hTarget:IsAlive() and not t.hTarget:IsMagicImmune() then
		AddModifier('modifier_stunned', {
			hTarget = t.hTarget,
			hCaster = hCaster,
			hAbility = self,
			duration = t.nStun,
		})
	end
end

function drow_ranger_piercing_shot:Effect2(t)
	if not t or not exist(t.hTarget) then
		return
	end
	
	self.bProc, self.nSplits = t.bProc or false, t.nSplits
	self:GetCaster():PerformAttack(t.hTarget, false, true, true, false, false, false, self.bProc)
	self.bProc, self.nSplits = nil, nil
end

------------------------------------------------------------------------

LinkLuaModifier('m_drow_ranger_piercing_shot', sPath, LUA_MODIFIER_MOTION_NONE)
m_drow_ranger_piercing_shot = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_drow_ranger_piercing_shot:GetPriority()
	return 100
end

function m_drow_ranger_piercing_shot:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self.tProcs = {}

		self:RegisterSelfEvents()
	end
end

function m_drow_ranger_piercing_shot:OnRefresh(t)
	ReadAbilityData(self, {
		'chance',
		'attack_damage',
		'scepter_radius',
		'scepter_count',
	})
end

function m_drow_ranger_piercing_shot:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_drow_ranger_piercing_shot:CheckState()
	if IsServer() then
		self.bProc = (RandomFloat(0, 100) <= self.chance)
		if self.bProc then
			return {
				[MODIFIER_STATE_CANNOT_MISS] = true,
			}
		end
	end
end

function m_drow_ranger_piercing_shot:OnParentAttackRecord(t)
	local hAbility = self:GetAbility()
	if hAbility then
		local bProc =  hAbility.bProc
		if bProc == nil then
			bProc = self.bProc
		end
		if bProc and t.target and t.target:IsBaseNPC()
		and UnitFilter(
			t.target,
			nFilterTeam,
			nFilterType,
			nFilterFlag,
			t.attacker:GetTeam()
		) == UF_SUCCESS then
			self.tProcs[t.record] = {
				bAbilityProc = hAbility.bProc,
				nSplits = hAbility.nSplits,
			}
		end
	end
end

function m_drow_ranger_piercing_shot:OnParentAttack(t)
	local tProc = self.tProcs[t.record]
	if tProc and not tProc.bAbilityProc and t.attacker:IsRangedAttacker() then
		ProjectileManager:CreateTrackingProjectile({
			Ability = self:GetAbility(),
			Target = t.target,
			Source = t.attacker,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
			iMoveSpeed = t.attacker:GetProjectileSpeed(),
			EffectName = 'particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf',
		})
	end
end

function m_drow_ranger_piercing_shot:OnParentAttackLanded(t)
	local tProc = self.tProcs[t.record]
	if tProc and t.target then
		local hAbility = self:GetAbility()

		ApplyDamage({
			victim = t.target,
			attacker = t.attacker,
			ability = hAbility,
			damage = t.original_damage * self.attack_damage / 100,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		})

		if hAbility and hAbility.ThrowTarget and t.attacker:HasScepter() then
			local qUnits = FindUnitsInRadius(
				t.attacker:GetTeam(),
				t.target:GetOrigin(),
				t.target,
				self.scepter_radius,
				nFilterTeam,
				nFilterType,
				nFilterFlag,
				FIND_CLOSEST,
				false
			)

			local nSplits = tProc.nSplits and tProc.nSplits - 1

			for i = 1, self.scepter_count do
				local hTarget = qUnits[i]
				if hTarget then
					hAbility:ThrowTarget({
						hTarget = hTarget,
						hSource = (hTarget ~= t.target) and t.target or nil,
						nSplits = nSplits,
					})
				else
					break
				end
			end
		end
	end
end

function m_drow_ranger_piercing_shot:OnParentAttackRecordDestroy(t)
	self.tProcs[t.record] = nil
end