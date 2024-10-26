LinkLuaModifier('m_kbw_shiva', "kbw/items/levels/shiva", 0)
LinkLuaModifier('m_kbw_shiva_debuff', "kbw/items/levels/shiva", 0)
LinkLuaModifier('m_kbw_shiva_aura_provider', "kbw/items/levels/shiva", 0)
LinkLuaModifier('m_kbw_shiva_aura_debuff', "kbw/items/levels/shiva", 0)

local base = {}

function base:GetModifierTexture()
	if self.nLevel > 1 then
		return 'item_shivas_guard' .. self.nLevel
	end
	return 'item_shivas_guard'
end

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local nTeam = hCaster:GetTeam()
	local nRadius = self:GetSpecialValueFor('blast_radius')
	local nSpeed = self:GetSpecialValueFor('blast_speed')
	local nDuration = self:GetSpecialValueFor('blast_debuff_duration')
	local nVisionDuration = self:GetSpecialValueFor('vision_duration')
	local nDamage = self:GetSpecialValueFor('blast_damage')

	local vOldVision
	local tAffected = {}
	local nCurrentRadius = 0
	local nBlastDuration = nRadius / nSpeed
	nVisionDuration = nVisionDuration + nBlastDuration

	hCaster:EmitSound('DOTA_Item.ShivasGuard.Activate')

	local nParticle = ParticleManager:Create('particles/items2_fx/shivas_guard_active.vpcf', PATTACH_ABSORIGIN_FOLLOW, hCaster, nBlastDuration*3)
	ParticleManager:SetParticleControlEnt(nParticle, 0, hCaster, PATTACH_ABSORIGIN_FOLLOW, nil, hCaster:GetOrigin(), false)
	ParticleManager:SetParticleControl(nParticle, 1, Vector(nRadius, nBlastDuration*2, nSpeed))

	Timer(1/30, function(nDT)
		if not exist(self) or not exist(hCaster) then
			return
		end

		local vPos = hCaster:GetOrigin()
		local bBreak = false

		nCurrentRadius = nCurrentRadius + nSpeed * nDT
		nVisionDuration = nVisionDuration - nDT

		if nCurrentRadius >= nRadius then
			nCurrentRadius = nRadius
			bBreak = true
		end

		if not vOldVision or (vOldVision-vPos):Length2D() >= 200 then
			vOldVision = vPos
			AddFOWViewer(nTeam, vPos, nRadius, nVisionDuration, false)
		end

		local qEnemies = Find:UnitsInRadius({
			vCenter = vPos,
			nRadius = nCurrentRadius,
			nTeam = nTeam,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			nFilterFlag = 0,
			fCondition = function(hUnit)
				return not tAffected[hUnit]
			end
		})

		for _, hEnemy in ipairs(qEnemies) do
			tAffected[hEnemy] = true

			ApplyDamage({
				victim = hEnemy,
				attacker = hCaster,
				ability = self,
				damage = nDamage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})

			if hEnemy:IsAlive() then
				AddModifier('m_kbw_shiva_debuff', {
					hTarget = hEnemy,
					hCaster = hCaster,
					hAbility = self,
					duration = nDuration,
				})
			end
		end

		if not bBreak then
			return 1/30
		end
	end)
end

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_kbw_shiva = -1,
		m_kbw_shiva_aura_provider = self.nLevel,
	}
end

CreateLevels({
	'item_kbw_shiva',
	'item_kbw_shiva_2',
	'item_kbw_shiva_3',
}, base)

m_kbw_shiva = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_shiva:OnCreated()
	ReadAbilityData(self, {
		'int',
		'armor',
	})
end

function m_kbw_shiva:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_kbw_shiva:GetModifierBonusStats_Intellect()
	return self.int
end
function m_kbw_shiva:GetModifierPhysicalArmorBonus()
	return self.armor
end

m_kbw_shiva_aura_provider = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_kbw_shiva_aura_provider:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {'aura_radius'})

		self.hAura = CreateAura({
			sModifier = 'm_kbw_shiva_aura_debuff',
			hSource = self,
			nRadius = self.aura_radius,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		})
	end
end

function m_kbw_shiva_aura_provider:OnDestroy()
	if IsServer() and exist(self.hAura) then
		self.hAura:Destroy()
	end
end

m_kbw_shiva_aura_debuff = ModifierClass{
}

function m_kbw_shiva_aura_debuff:GetTexture()
	local hAbility = self:GetAbility()
	if hAbility then
		return hAbility:GetModifierTexture()
	end
	return 'item_shivas_guard'
end

function m_kbw_shiva_aura_debuff:OnCreated()
	ReadAbilityData(self, {
		'aura_attack_speed',
		'heal_amp_reduction',
	})

	if IsServer() then
		self.hHealModifier = AddSpecialModifier(self:GetParent(), 'nHealAmp', -self.heal_amp_reduction)
	end
end

function m_kbw_shiva_aura_debuff:OnDestroy()
	if IsServer() then
		if exist(self.hHealModifier) then
			self.hHealModifier:Destroy()
		end
	end
end

function m_kbw_shiva_aura_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_kbw_shiva_aura_debuff:GetModifierAttackSpeedBonus_Constant()
	return -(self.aura_attack_speed or 0)
end
function m_kbw_shiva_aura_debuff:OnTooltip()
	return self.heal_amp_reduction
end

m_kbw_shiva_debuff = ModifierClass{
	bPurgable = true,
}

function m_kbw_shiva_debuff:GetTexture()
	local hAbility = self:GetAbility()
	if hAbility then
		return hAbility:GetModifierTexture()
	end
	return 'item_shivas_guard'
end

function m_kbw_shiva_debuff:GetStatusEffectName()
	return 'particles/status_fx/status_effect_frost.vpcf'
end

function m_kbw_shiva_debuff:OnCreated()
	ReadAbilityData(self, {'blast_slow'})
end

function m_kbw_shiva_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_kbw_shiva_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.blast_slow
end