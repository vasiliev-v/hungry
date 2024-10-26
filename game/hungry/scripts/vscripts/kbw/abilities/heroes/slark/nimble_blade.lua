local sPath = "kbw/abilities/heroes/slark/nimble_blade"

slark_nimble_blade = class{}

function slark_nimble_blade:GetIntrinsicModifierName()
	return 'm_slark_nimble_blade'
end

local function fBuffStacks(hUnit, sMod, hAbility, nStacks, nDuration)
	if not hAbility then
		return
	end

	local hCaster = hAbility:GetCaster()

	if hUnit:GetTeam() ~= hCaster:GetTeam() then
		nDuration = nDuration * (1 - hUnit:GetStatusResistance()) * GetDebuffAmp(hCaster)
	end

	local hMod = hUnit:FindModifierByName(sMod)
	if not hMod then
		hMod = hUnit:AddNewModifier(hCaster, hAbility, sMod, {
			duration = nDuration,
		})
	end

	if hMod and nDuration > 0 then
		hMod:SetDuration(math.max(nDuration, hMod:GetRemainingTime()), true)
		if nStacks > 0 then
			hMod:SetStackCount(hMod:GetStackCount() + nStacks)
			Timer(nDuration, function()
				if exist(hMod) then
					hMod:SetStackCount(hMod:GetStackCount() - nStacks)
				end
			end)
		end
	end
end

local function fParticle(hTarget, hAttacker)
	local nParticle = ParticleManager:Create('particles/units/heroes/hero_slark/slark_essence_shift.vpcf', PATTACH_CUSTOMORIGIN, hTarget, 1)
	ParticleManager:SetParticleControlEnt(nParticle, 0, hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false)
	ParticleManager:SetParticleControlEnt(nParticle, 1, hAttacker, PATTACH_POINT_FOLLOW, 'attach_attack1', hAttacker:GetOrigin(), false)
end

LinkLuaModifier('m_slark_nimble_blade', sPath, LUA_MODIFIER_MOTION_NONE)

m_slark_nimble_blade = ModifierClass{
	bPermanent = true,
}

function m_slark_nimble_blade:IsHidden()
	return self:GetStackCount() < 1
end

function m_slark_nimble_blade:OnCreated(tBaseValues)
	self:OnRefresh(t)

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_slark_nimble_blade:OnRefresh(t)
	ReadAbilityData(self, {
		'creep_agi',
		'attack_chance',
		'boss_attack_chance',
		'attack_agi',
		'attack_stats_reduce',
		'duration',
		'hero_kill_agi',
	})
end

function m_slark_nimble_blade:OnDestroy(tBaseValues)
	self:OnRefresh(t)

	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_slark_nimble_blade:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function m_slark_nimble_blade:OnParentKill(t)
	if not exist(t.unit) or not t.unit:IsBaseNPC() then
		return
	end
	
	local hParent = self:GetParent()

	if hParent:PassivesDisabled() then
		return
	end

	if t.unit:IsRealHero() then
		if not t.unit:HasModifier('m_slark_nimble_blade_debuff') then
			self:TriggerHeroKilled()
		end
	else
		fBuffStacks(hParent, 'm_slark_nimble_blade_buff', self:GetAbility(), self.creep_agi, self.duration)
		fParticle(t.unit, hParent)
	end
end

function m_slark_nimble_blade:OnParentAttackLanded(t)
	local hParent = self:GetParent()
	local hAbility = self:GetAbility()

	if not exist(t.target) or not t.target:IsBaseNPC() 
	or UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		hParent:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	if hParent:PassivesDisabled() then
		return
	end

	if t.target.GetStrength then
		fBuffStacks(t.target, 'm_slark_nimble_blade_debuff', hAbility, 0, self.duration)
	end

	local nChance = IsBoss(t.target) and self.boss_attack_chance or self.attack_chance
	if RandomFloat(0, 100) <= nChance then
		fBuffStacks(hParent, 'm_slark_nimble_blade_buff', hAbility, self.attack_agi, self.duration)
		if t.target.GetStrength then
			fBuffStacks(t.target, 'm_slark_nimble_blade_debuff', hAbility, self.attack_stats_reduce, self.duration)
		end

		fParticle(t.target, hParent)
	end
end

function m_slark_nimble_blade:TriggerHeroKilled()
	self:SetStackCount(self:GetStackCount() + self.hero_kill_agi)
end

function m_slark_nimble_blade:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function m_slark_nimble_blade:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

LinkLuaModifier('m_slark_nimble_blade_buff', sPath, LUA_MODIFIER_MOTION_NONE)

m_slark_nimble_blade_buff = ModifierClass{
}

function m_slark_nimble_blade_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function m_slark_nimble_blade_buff:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

LinkLuaModifier('m_slark_nimble_blade_debuff', sPath, LUA_MODIFIER_MOTION_NONE)

m_slark_nimble_blade_debuff = ModifierClass{
}

function m_slark_nimble_blade_debuff:OnDestroy()
	if IsServer() then
		local hParent = self:GetParent()
		local hCaster = self:GetCaster()
		local hAbility = self:GetAbility()
		if hCaster and hAbility and not hParent:IsAlive() and hParent:IsRealHero() and not hCaster:PassivesDisabled()
		and (hParent:GetOrigin() - hCaster:GetOrigin()):Length2D() <= hAbility:GetSpecialValueFor('kill_radius') then
			local hMod = hCaster:FindModifierByName('m_slark_nimble_blade')
			if hMod and hMod.TriggerHeroKilled then
				hMod:TriggerHeroKilled()
			end
		end
	end
end

function m_slark_nimble_blade_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function m_slark_nimble_blade_debuff:GetModifierBonusStats_Agility()
	return -self:GetStackCount()
end
function m_slark_nimble_blade_debuff:GetModifierBonusStats_Strength()
	return -self:GetStackCount()
end