LinkLuaModifier('m_kbw_skadi', "kbw/items/levels/skadi", 0)
LinkLuaModifier('m_kbw_skadi_debuff', "kbw/items/levels/skadi", 0)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_kbw_skadi'
end

CreateLevels({
    'item_kbw_skadi',
    'item_kbw_skadi_2',
    'item_kbw_skadi_3',
}, base )

m_kbw_skadi = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_kbw_skadi:OnCreated()
	ReadAbilityData(self, {
		'all_stats',
		'duration',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_skadi:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_skadi:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function m_kbw_skadi:GetModifierBonusStats_Strength()
	return self.all_stats
end
function m_kbw_skadi:GetModifierBonusStats_Agility()
	return self.all_stats
end
function m_kbw_skadi:GetModifierBonusStats_Intellect()
	return self.all_stats
end

function m_kbw_skadi:GetModifierProjectileName()
	return 'particles/items2_fx/skadi_projectile.vpcf'
end

function m_kbw_skadi:OnParentAttackLanded(t)
	if exist(t.target) and t.target:IsBaseNPC() then
		local hAbility = self:GetAbility()
		if not hAbility then
			return
		end

		local hBuff = t.target:FindModifierByName('m_kbw_skadi_debuff')

		if hBuff then
			local hBuffAbility = hBuff:GetAbility()
			if hBuffAbility and (hBuffAbility.nLevel or 0) > (hAbility.nLevel or 0) then
				local duration = self.duration * (1 - t.target:GetStatusResistance())
				if duration > hBuff:GetRemainingTime() then
					hBuff:SetDuration(duration, true)
					return
				end
			end
		end

		AddModifier('m_kbw_skadi_debuff', {
			hTarget = t.target,
			hCaster = self:GetParent(),
			hAbility = hAbility,
			duration = self.duration,
		})
	end
end

m_kbw_skadi_debuff = ModifierClass{
}

function m_kbw_skadi_debuff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		if self.heal_reduction then
			self.hHealAmpModifier = AddSpecialModifier(self:GetParent(), 'nHealAmp', -self.heal_reduction)
		end
	end
end

function m_kbw_skadi_debuff:OnRefresh(t)
	ReadAbilityData(self, {
		'speed_slow',
		'attack_slow',
		'heal_reduction',
	}, function(hAbility)
		self.hAbility = hAbility
	end)
end

function m_kbw_skadi_debuff:OnDestroy()
	if IsServer() then
		if exist(self.hHealAmpModifier) then
			self.hHealAmpModifier:Destroy()
		end
	end
end

function m_kbw_skadi_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_kbw_skadi_debuff:GetModifierAttackSpeedBonus_Constant()
	return -self.attack_slow
end
function m_kbw_skadi_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.speed_slow
end

function m_kbw_skadi_debuff:GetTexture()
	if self.hAbility and self.hAbility.nLevel and self.hAbility.nLevel > 1 then
		return 'item_skadi' .. self.hAbility.nLevel
	end
	return 'item_skadi'
end