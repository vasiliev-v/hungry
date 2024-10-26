LinkLuaModifier('m_monkey_king_jingu_mastery_kbw_counter', "kbw/abilities/heroes/monkey_king/jingu_mastery", 0)
LinkLuaModifier('m_monkey_king_jingu_mastery_kbw_buff', "kbw/abilities/heroes/monkey_king/jingu_mastery", 0)

monkey_king_jingu_mastery_kbw = class{}

function monkey_king_jingu_mastery_kbw:GetIntrinsicModifierName()
	return 'm_monkey_king_jingu_mastery_kbw_counter'
end

function monkey_king_jingu_mastery_kbw:IsValidTarget(hUnit)
	if not exist(hUnit) then
		return false
	end

	return UnitFilter(
		hUnit,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		self:GetCaster():GetTeam()
	) == UF_SUCCESS
end

function monkey_king_jingu_mastery_kbw:OnUpgrade()
	local hMod = self:GetCaster():FindModifierByName('m_monkey_king_jingu_mastery_kbw_buff')
	if exist(hMod) then
		hMod:ForceRefresh()
	end
end

m_monkey_king_jingu_mastery_kbw_counter = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

-- function m_monkey_king_jingu_mastery_kbw_counter:IsHidden()
-- 	return self:GetStackCount() < 1
-- end

function m_monkey_king_jingu_mastery_kbw_counter:OnCreated()
	ReadAbilityData(self, {
		'required_charges',
		'hero_charges',
		'attack_count',
	}, function(hAbility)
		self.hAbility = hAbility
	end)

	self.hParent = self:GetParent()

	if IsServer() then
		self:RegisterSelfEvents()
		self:StartIntervalThink(0.1)
	end
end

function m_monkey_king_jingu_mastery_kbw_counter:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_monkey_king_jingu_mastery_kbw_counter:OnIntervalThink()
	local bParticle = not self.hParent:HasModifier('modifier_monkey_king_transform')

	if bParticle then
		if not self.nCounterParticle then
			local nStacks = self:GetStackCount()
			if nStacks > 0 then
				self:CreateParticle()
				ParticleManager:SetParticleControl(self.nCounterParticle, 1, Vector(0,nStacks,0))
			end
		end
	else
		if self.nCounterParticle then
			self:DestroyParticle()
		end
	end
end

function m_monkey_king_jingu_mastery_kbw_counter:OnParentAttackLanded(t)
	if self.hParent:PassivesDisabled() or self.hParent:HasModifier('m_monkey_king_jingu_mastery_kbw_buff') then
		return
	end

	if not self.hAbility or not self.hAbility.IsValidTarget or not self.hAbility:IsValidTarget(t.target) then
		return
	end

	local nAdd = t.target:IsConsideredHero() and self.hero_charges or 1
	local nStacks = self:GetStackCount() + nAdd

	if nStacks >= self.required_charges then
		local hMod = AddModifier('m_monkey_king_jingu_mastery_kbw_buff', {
			hTarget = self.hParent,
			hCaster = self.hParent,
			hAbility = self.hAbility,
		})

		if hMod then
			hMod:SetStackCount(self.attack_count)
			self:SetStackCount(0)

			if self.nCounterParticle then
				ParticleManager:Fade(self.nCounterParticle, true)
				self.nCounterParticle = nil
			end

			local nParticle = ParticleManager:Create('particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_start.vpcf', self.hParent, 5)
			ParticleManager:SetParticleControl(nParticle, 0, self.hParent:GetOrigin())

			self.hParent:EmitSound('Hero_MonkeyKing.IronCudgel')
		end
	else
		self:SetStackCount(nStacks)

		if not self.nCounterParticle then
			self:CreateParticle()
		end

		ParticleManager:SetParticleControl(self.nCounterParticle, 1, Vector(0,nStacks,0))
	end
end

function m_monkey_king_jingu_mastery_kbw_counter:CreateParticle()
	self:DestroyParticle()

	self.nCounterParticle = ParticleManager:Create('particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_stack.vpcf', PATTACH_CUSTOMORIGIN, self.hParent)
	ParticleManager:SetParticleControlEnt(self.nCounterParticle, 0, self.hParent, PATTACH_OVERHEAD_FOLLOW, nil, Vector(0,0,0), false)
end

function m_monkey_king_jingu_mastery_kbw_counter:DestroyParticle()
	if self.nCounterParticle then
		ParticleManager:Fade(self.nCounterParticle, true)
		self.nCounterParticle = nil
	end
end

function m_monkey_king_jingu_mastery_kbw_counter:OnParentDead()
	self:SetStackCount(0)
	self:DestroyParticle()
end

m_monkey_king_jingu_mastery_kbw_buff = ModifierClass{
	bIgnoreDeath = true,
}

function m_monkey_king_jingu_mastery_kbw_buff:IsHidden()
	return self:GetStackCount() < 1
end

function m_monkey_king_jingu_mastery_kbw_buff:OnCreated(t)
	self:OnRefresh((t))

	self.hParent = self:GetParent()

	if IsServer() then
		self.nLastTime = GameRules:GetGameTime()

		self:RegisterSelfEvents()
		self:StartIntervalThink(0.1)
		self:OnIntervalThink()
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:OnIntervalThink()
	if self.hParent:HasModifier('modifier_monkey_king_transform') then
		if self.nParticle then
			self:DestroyParticle()
		end
	else
		if not self.nParticle then
			self:CreateParticle()
		end
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:CreateParticle()
	self:DestroyParticle()

	self.nParticle = ParticleManager:Create('particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf', PATTACH_CUSTOMORIGIN, self.hParent)
	ParticleManager:SetParticleControlEnt(self.nParticle, 2, self.hParent, PATTACH_POINT_FOLLOW, 'attach_weapon_top', Vector(0,0,0), false)
	ParticleManager:SetParticleControlEnt(self.nParticle, 3, self.hParent, PATTACH_POINT_FOLLOW, 'attach_weapon_bot', Vector(0,0,0), false)
end

function m_monkey_king_jingu_mastery_kbw_buff:DestroyParticle()
	if self.nParticle then
		ParticleManager:Fade(self.nParticle, true)
		self.nParticle = nil
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:OnRefresh(t)
	ReadAbilityData(self, {
		'damage',
		'lifesteal',
	}, function(hAbility)
		self.hAbility = hAbility
	end)
end

function m_monkey_king_jingu_mastery_kbw_buff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
		self:DestroyParticle()
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:OnParentAttackLanded(t)
	if not self:IsActive(t) then
		return
	end

	local nRealDamage = GetDamageWithArmor(t.original_damage, t.attacker, t.target)
	local nHeal = nRealDamage * self.lifesteal / 100

	self.hParent:Heal(nHeal, self.hAbility)

	ParticleManager:Create('particles/generic_gameplay/generic_lifesteal.vpcf', self.hParent, PATTACH_ABSORIGIN_FOLLOW, 2)

	local nTime = GameRules:GetGameTime()
	if self.nLastTime < nTime then
		self.nLastTime = nTime
		local nStacks = self:GetStackCount()
		if nStacks == 1 then
			Timer(1/30, function()
				if exist(self) then
					self:Destroy()
				end
			end)
		elseif nStacks > 1 then
			self:DecrementStackCount()
		end
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:IsActive(t)
	if self.hParent:PassivesDisabled() then
		return false
	end

	if not self.hAbility or not self.hAbility.IsValidTarget or not self.hAbility:IsValidTarget(t.target) then
		return false
	end

	if self:GetElapsedTime() == 0 then
		return false
	end

	return true
end

function m_monkey_king_jingu_mastery_kbw_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_monkey_king_jingu_mastery_kbw_buff:GetModifierPreAttack_BonusDamage(t)
	if self.hParent:PassivesDisabled() then
		return 0
	end

	if IsClient() or not t.target or self:IsActive(t) then
		return self.damage
	end
end

function m_monkey_king_jingu_mastery_kbw_buff:GetActivityTranslationModifiers()
	return 'iron_cudgel_charged_attack'
end

function m_monkey_king_jingu_mastery_kbw_buff:OnTooltip()
	return self.lifesteal
end