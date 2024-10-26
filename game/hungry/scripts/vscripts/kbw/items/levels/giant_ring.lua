LinkLuaModifier('m_kbw_giant_ring_stats', "kbw/items/levels/giant_ring", 0)
LinkLuaModifier('m_kbw_giant_ring_buff', "kbw/items/levels/giant_ring", 0)

local base = {}

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local nDuration = self:GetSpecialValueFor('duration')
	if nDuration <= 0 then
		return
	end

	local hMod = hCaster:FindModifierByName('m_kbw_giant_ring_buff')
	if hMod then
		local hProvider = hMod:GetAbility()
		if hProvider and hProvider.nLevel > self.nLevel then
			return
		end
	end

	AddModifier('m_kbw_giant_ring_buff', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		duration = nDuration,
	})
end

function base:GetIntrinsicModifierName()
	return 'm_kbw_giant_ring_stats'
end

-- function base:GetIntrinsicModifierName()
-- 	return 'm_mult'
-- end

-- function base:GetMultModifiers()
-- 	local t = {
-- 		m_kbw_giantgiant_ring_stats = -1,
-- 	}

-- 	if self.nLevel > 2 then
-- 		t.m_kbw_giant_ring_buff = self.nLevel
-- 	end

-- 	return t
-- end

CreateLevels({
	'item_kbw_giant_ring',
	'item_kbw_giant_ring_2',
	'item_kbw_giant_ring_3',
}, base)

m_kbw_giant_ring_stats = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_giant_ring_stats:OnCreated()
	ReadAbilityData(self, {
		'speed',
		'attr',
	})
end

function m_kbw_giant_ring_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_kbw_giant_ring_stats:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end
function m_kbw_giant_ring_stats:GetModifierBonusStats_Strength()
	return self.attr
end
function m_kbw_giant_ring_stats:GetModifierBonusStats_Agility()
	return self.attr
end
function m_kbw_giant_ring_stats:GetModifierBonusStats_Intellect()
	return self.attr
end

m_kbw_giant_ring_buff = ModifierClass{}

function m_kbw_giant_ring_buff:RemoveOnDeath()
	return false
end

function m_kbw_giant_ring_buff:GetTexture()
	local hAbility = self:GetAbility()
	if hAbility then
		return 'item_'..hAbility:GetAbilityTextureName()
	end
end

function m_kbw_giant_ring_buff:IsHidden()
	return self:GetStackCount() > 0
end

function m_kbw_giant_ring_buff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		if self:GetParent():IsMonkeyKingShit() then
			return
		end

		self.nInterval = 0.5
		self.nNoThinkTime = 0
		self:OnIntervalThink()
		self:StartIntervalThink(0.1)
	end
end

function m_kbw_giant_ring_buff:OnRefresh(t)
	self:OnDestroy()

	ReadAbilityData(self, {
		'attr_pct',
		'attr_damage_pct',
		'damage_radius',
		'model_scale',
		'visible_range',
	}, function(hAbility)
		if IsServer() and hAbility then
			-- if hAbility.nLevel > 2 then
			-- 	self:SetStackCount(1)
			-- end

			local hParent = self:GetParent()
			self.qStatAmps = {}
			table.insert(self.qStatAmps, AddSpecialModifier(hParent, 'nStrAmp', self.attr_pct))
			table.insert(self.qStatAmps, AddSpecialModifier(hParent, 'nAgiAmp', self.attr_pct))
			table.insert(self.qStatAmps, AddSpecialModifier(hParent, 'nIntAmp', self.attr_pct))
		end
	end)
end

function m_kbw_giant_ring_buff:OnDestroy()
	if self.qStatAmps then
		for _, hAmp in ipairs(self.qStatAmps) do
			hAmp:Destroy()
		end
	end
end

function m_kbw_giant_ring_buff:OnIntervalThink()
	local hParent = self:GetParent()
	if not hParent:IsAlive() then
		return
	end

	local nTeam = hParent:GetTeam()
	local vPos = hParent:GetOrigin()
	local hAbility = self:GetAbility()
	local nDamage = (hParent:GetStrength()+hParent:GetAgility()+hParent:GetIntellect())*self.attr_damage_pct/100 * self.nInterval

	local qEnemies = Find:UnitsInRadius({
		vCenter = vPos,
		nTeam = nTeam,
		nRadius = self.visible_range,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO,
		fCondition = function(hUnit)
			return hUnit:GetTeam() ~= DOTA_TEAM_NEUTRALS
		end
	})

	if #qEnemies > 0 then
		AddFOWViewer(hParent:GetOpposingTeamNumber(), vPos, 128, 0.2, false)
	end

	self.nNoThinkTime = self.nNoThinkTime + 0.1
	if self.nNoThinkTime >= self.nInterval then
		self.nNoThinkTime = self.nNoThinkTime - self.nInterval
		
		local qUnits = Find:UnitsInRadius({
			vCenter = vPos,
			nTeam = nTeam,
			nRadius = self.damage_radius,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			nFIlterFlag = 0,
		})

		for _, hUnit in ipairs(qUnits) do
			ApplyDamage({
				victim = hUnit,
				attacker = hParent,
				ability = hAbility,
				damage = nDamage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})
		end

		local nParticle = ParticleManager:Create('particles/units/heroes/hero_sandking/sandking_epicenter.vpcf', PATTACH_CUSTOMORIGIN, hParent, 2)
		ParticleManager:SetParticleControl(nParticle, 0, vPos)
		ParticleManager:SetParticleControl(nParticle, 1, Vector(math.max(1, self.damage_radius-100), self.damage_radius, self.damage_radius))
	end
end

function m_kbw_giant_ring_buff:CheckState()
	return {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function m_kbw_giant_ring_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end

function m_kbw_giant_ring_buff:GetModifierModelScale()
	return self.model_scale
end