local sPath = "kbw/items/mjolnir"

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_kbw_maelstrom = self.nLevel,
		m_kbw_maelstrom_stats = -1,
	}
end

function base:GetAOERadius()
	return self:GetSpecialValueFor('gleipnir_radius')
end

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local vTarget = self:GetCursorPosition()

	if hTarget then
		AddModifier('m_kbw_mjolnir', {
			hTarget = hTarget,
			hCaster = hCaster,
			hAbility = self,
			duration = self:GetSpecialValueFor('static_duration'),
		})

		hTarget:EmitSound('DOTA_Item.Mjollnir.Activate')
	elseif vTarget ~= Vector(0,0,0) then
		local aUnits = Find:UnitsInRadius({
			vCenter = vTarget,
			nTeam = hCaster:GetTeam(),
			nRadius = self:GetSpecialValueFor('gleipnir_radius'),
			nFilterTeam = self:GetAbilityTargetTeam(),
			nFilterType = self:GetAbilityTargetType(),
			nFilterFlag = self:GetAbilityTargetFlags(),
		})

		for _, hUnit in pairs(aUnits) do
			self:ThrowGleipnir({
				target = hUnit,
			})
		end

		if #aUnits > 0 then
			hCaster:EmitSound('Item.Gleipnir.Cast')
		end
	end
end

function base:ThrowGleipnir(t_)
	local hCaster = self:GetCaster()
	local t = table.copy(t_)
	t.speed = t.speed or self:GetSpecialValueFor('gleipnir_speed')

	if not exist(t.target) then
		return
	end

	ProjectileManager:CreateTrackingProjectile({
		Ability = self,
		Source = hCaster,
		EffectName = 'particles/items3_fx/gleipnir_projectile.vpcf',
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		vSourceLoc = hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment('attach_attack1')),
		Target = t.target,
		iMoveSpeed = t.speed,
	})
end

function base:OnProjectileHit(hTarget, vPos)
	self:HitGleipnir({
		target = hTarget,
	})
end

function base:HitGleipnir(t_)
	local hCaster = self:GetCaster()
	local t = table.copy(t_)
	t.damage = t.damage or self:GetSpecialValueFor('gleipnir_damage')
	t.duration = t.duration or self:GetSpecialValueFor('gleipnir_duration')

	if not exist(t.target) then
		return
	end

	t.target:EmitSound('Item.Gleipnir.Target')

	AddModifier('m_kbw_gleipnir', {
		hTarget = t.target,
		hCaster = hCaster,
		hAbility = self,
		duration = t.duration,
	})

	ApplyDamage({
		victim = t.target,
		attacker = hCaster,
		ability = self,
		damage = t.damage,
		damage_type = self:GetAbilityDamageType(),
	})
end

function base:ThrowChain(t_)
	local t = table.copy(t_)
	local hCaster = self:GetCaster()
	t.count = t.count or self:GetSpecialValueFor('chain_strikes')
	t.damage = t.damage or self:GetSpecialValueFor('chain_damage')
	t.boss_pct = t.boss_pct or self:GetSpecialValueFor('boss_pct')
	t.source = t.source or hCaster

	if t.count < 1 or not exist(t.target) or not exist(t.source) then
		return
	end

	local vTarget = t.target:GetOrigin()
	local bFirst = (t.source:GetTeam() ~= t.target:GetTeam())
	local sSourceAttach = bFirst and 'attach_attack1' or 'attach_hitloc'
	local sSound = bFirst and 'Item.Maelstrom.Chain_Lightning' or 'Item.Maelstrom.Chain_Lightning.Jump'
	local nDamage = IsBoss(t.target) and t.damage * t.boss_pct / 100 or t.damage

	local nParticle = ParticleManager:Create('particles/items_fx/chain_lightning.vpcf', PATTACH_CUSTOMORIGIN, t.target, 1)
	ParticleManager:SetParticleControlEnt(nParticle, 0, t.source, PATTACH_POINT_FOLLOW, sSourceAttach, t.source:GetOrigin(), false)
	ParticleManager:SetParticleControlEnt(nParticle, 1, t.target, PATTACH_POINT_FOLLOW, 'attach_hitloc', vTarget, false)
	ParticleManager:SetParticleControl(nParticle, 2, Vector(1,0,0))

	t.source:EmitSound(sSound)

	ApplyDamage({
		victim = t.target,
		attacker = hCaster,
		ability = self,
		damage = nDamage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	})

	if t.count > 1 then
		t.radius = t.radius or self:GetSpecialValueFor('chain_radius')
		t.delay = t.delay or self:GetSpecialValueFor('chain_delay')
		t.affected = t.affected or {}
		t.affected[t.target] = true

		Timer(t.delay, function()
			if not exist(self) or not exist(t.target) then
				return
			end

			local hTarget = Find:UnitsInRadius({
				vCenter = vTarget,
				nRadius = t.radius,
				nTeam = hCaster:GetTeam(),
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				nFilterFlag = DOTA_UNIT_TARGET_FLAG_NONE,
				nOrder = FIND_CLOSEST,
				fCondition = function(hUnit)
					return not t.affected[hUnit]
				end
			})[1]

			if hTarget then
				t.count = t.count - 1
				t.source = t.target
				t.target = hTarget

				self:ThrowChain(t)
			end
		end)
	end
end

CreateLevels({
	'item_kbw_maelstrom',
	'item_kbw_gleipnir',
	'item_kbw_mjolnir',
	'item_kbw_gleipnir_2',
	'item_kbw_mjolnir_2',
	'item_kbw_gleipnir_3',
	'item_kbw_mjolnir_3',
}, base)

LinkLuaModifier('m_kbw_maelstrom_stats', sPath, LUA_MODIFIER_MOTION_NONE)
m_kbw_maelstrom_stats = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_maelstrom_stats:OnCreated()
	ReadAbilityData(self, {
		'damage',
		'attack',
		'all',
	})
end

function m_kbw_maelstrom_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_kbw_maelstrom_stats:GetModifierPreAttack_BonusDamage()
	return self.damage
end
function m_kbw_maelstrom_stats:GetModifierAttackSpeedBonus_Constant()
	return self.attack
end
function m_kbw_maelstrom_stats:GetModifierBonusStats_Strength()
	return self.all
end
function m_kbw_maelstrom_stats:GetModifierBonusStats_Agility()
	return self.all
end
function m_kbw_maelstrom_stats:GetModifierBonusStats_Intellect()
	return self.all
end

LinkLuaModifier('m_kbw_maelstrom', sPath, LUA_MODIFIER_MOTION_NONE)
m_kbw_maelstrom = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_maelstrom:OnCreated()
	ReadAbilityData(self, {
		'chain_chance',
	})

	if IsServer() then
		self.tRecords = {}
		if not self:GetParent():IsIllusion() then
			self.bActive = true
			self:RegisterSelfEvents()
		end
	end
end

function m_kbw_maelstrom:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_maelstrom:CheckState()
	if IsServer() and self.bActive then
		if RandomFloat(0, 100) <= self.chain_chance then
			self.bProc = true
			return {
				[MODIFIER_STATE_CANNOT_MISS] = true,
			}
		else
			self.bProc = nil
		end
	end
	return {}
end

function m_kbw_maelstrom:OnParentAttackRecord(t)
	if self.bProc and t.target:IsBaseNPC() and UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		t.attacker:GetTeam()
	) == UF_SUCCESS then

		self.tRecords[t.record] = true
		-- self.bProc = nil
	end
end

function m_kbw_maelstrom:OnParentAttackLanded(t)
	if self.tRecords[t.record] then
		self.tRecords[t.record] = nil

		local hAbility = self:GetAbility()
		if hAbility and hAbility.ThrowChain then
			hAbility:ThrowChain({
				target = t.target,
			})
		end
	end
end

function m_kbw_maelstrom:OnParentAttackFail( t )
	self.tRecords[t.record] = nil
end

function m_kbw_maelstrom:OnParentAttackCancel( t )
	self.tRecords[t.record] = nil
end

LinkLuaModifier('m_kbw_gleipnir', sPath, LUA_MODIFIER_MOTION_NONE)
m_kbw_gleipnir = ModifierClass{
	bIgnoreDeath = true,
	bPurgable = true,
}

function m_kbw_gleipnir:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function m_kbw_gleipnir:OnCreated()
	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/items3_fx/gleipnir_root.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControl(self.nParticle, 0, GetGroundPosition(hParent:GetOrigin(), nil))
	end
end

function m_kbw_gleipnir:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

LinkLuaModifier('m_kbw_mjolnir', sPath, LUA_MODIFIER_MOTION_NONE)
m_kbw_mjolnir = ModifierClass{
}

function m_kbw_mjolnir:OnCreated()
	ReadAbilityData(self,{
		'static_chance',
		'static_strikes',
		'static_damage',
		'static_radius',
		'static_cooldown',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self:RegisterSelfEvents()

		self.nParticle = ParticleManager:Create('particles/items2_fx/mjollnir_shield.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)

		hParent:EmitSound('DOTA_Item.Mjollnir.Loop')
	end
end

function m_kbw_mjolnir:OnDestroy()
	if IsServer() then
		local hParent = self:GetParent()

		self:UnregisterSelfEvents()

		ParticleManager:Fade(self.nParticle, true)

		hParent:EmitSound('DOTA_Item.Mjollnir.DeActivate')
		hParent:StopSound('DOTA_Item.Mjollnir.Loop')
	end
end

function m_kbw_mjolnir:OnParentTakeDamage(t)
	local nTime = GameRules:GetGameTime()
	if self.nNextTime and self.nNextTime > nTime then
		return
	end

	if RandomFloat(0, 100) > self.static_chance then
		return
	end

	local hCaster = self:GetCaster()
	local hAbility = self:GetAbility()
	local vCenter = t.unit:GetOrigin()
	local nTeam = hCaster:GetTeam()
	local nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
	local nFilterFlag = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE

	local aTargets = {}
	local aUnits = Find:UnitsInRadius({
		vCenter = vCenter,
		nRadius = self.static_radius,
		nTeam = nTeam,
		nFilterTeam = nFilterTeam,
		nFilterType = nFilterType,
		nFilterFlag = nFilterFlag,
		nOrder = FIND_CLOSEST,
		fCondition = function(hUnit)
			return hUnit ~= t.attacker
		end,
	})

	for i = 1, self.static_strikes do
		if aUnits[i] then
			table.insert(aTargets, aUnits[i])
		else
			break
		end
	end

	if UnitFilter(
		t.attacker,
		nFilterTeam,
		nFilterType,
		nFilterFlag,
		nTeam
	) == UF_SUCCESS then
		table.insert(aTargets, t.attacker)
	end

	if #aTargets > 0 then
		for _, hTarget in ipairs(aTargets) do
			ApplyDamage({
				victim = hTarget,
				attacker = hCaster,
				ability = hAbility,
				damage = self.static_damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})

			local nParticle = ParticleManager:Create('particles/items_fx/chain_lightning.vpcf', PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:Fade(nParticle, 1)
			ParticleManager:SetParticleControlEnt(nParticle, 0, t.unit, PATTACH_POINT_FOLLOW, 'attach_hitloc', vCenter, false)
			ParticleManager:SetParticleControlEnt(nParticle, 1, hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false)
			ParticleManager:SetParticleControl(nParticle, 2, Vector(4,0,0))
		end

		t.unit:EmitSound('Item.Maelstrom.Chain_Lightning')

		self.nNextTime = nTime + self.static_cooldown
	end
end

function m_kbw_mjolnir:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_kbw_mjolnir:OnTooltip(t)
	local nTime = GameRules:GetGameTime()
	if nTime == self.nLastTooltipTime then
		return self.static_strikes
	else
		self.nLastTooltipTime = nTime
		return self.static_chance
	end
end