local sPath = "kbw/items/witch_blade"

item_kbw_witch_blade = class{}

function item_kbw_witch_blade:GetIntrinsicModifierName()
	return 'm_item_kbw_witch_blade'
end

LinkLuaModifier('m_item_kbw_witch_blade', sPath, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_witch_blade = ModifierClass{
	bHidden = true,
	bMultiple = true,
}

function m_item_kbw_witch_blade:OnCreated()
	ReadAbilityData(self, {
		'health',
		'damage',
		'attack',
		'proj_speed',
		'mp_regen',
		'duration',
	})

	if IsServer() then
		self.tProcs = {}

		self:RegisterSelfEvents()
	end
end

function m_item_kbw_witch_blade:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_witch_blade:IsReady()
	local hAbility = self:GetAbility()
	if hAbility and hAbility:IsCooldownReady() and self:GetParent():IsRealHero() then
		return true
	end
	return false
end

function m_item_kbw_witch_blade:CheckState()
	if IsServer() then
		if self:IsReady() then
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

function m_item_kbw_witch_blade:OnParentAttackRecord(t)
	if self.bProc and t.target and t.target:IsBaseNPC()
	and UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		t.attacker:GetTeam()
	) == UF_SUCCESS then
		self.bProc = nil
		self.tProcs[t.record] = true
	end
end

function m_item_kbw_witch_blade:OnParentAttackCancel(t)
	self.tProcs[t.record] = nil
end

function m_item_kbw_witch_blade:OnParentAttack(t)
	if self.tProcs[t.record] then
		local hAbility = self:GetAbility()
		if hAbility then
			hAbility:StartCooldown(hAbility:GetEffectiveCooldown(hAbility:GetLevel() - 1))
		end
	end
end

function m_item_kbw_witch_blade:OnParentAttackFail(t)
	self.tProcs[t.record] = nil
end

function m_item_kbw_witch_blade:OnParentAttackLanded(t)
	if self.tProcs[t.record] then
		if exist(t.target) then
			AddModifier('m_item_kbw_witch_blade_debuff', {
				hTarget = t.target,
				hCaster = t.attacker,
				hAbility = self:GetAbility(),
				duration = self.duration + 0.1,
			})

			t.target:EmitSound('Item.WitchBlade.Target')
		end
		self.tProcs[t.record] = nil
	end
end

function m_item_kbw_witch_blade:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_item_kbw_witch_blade:GetModifierHealthBonus()
	return self.health
end
function m_item_kbw_witch_blade:GetModifierPreAttack_BonusDamage()
	return self.damage
end
function m_item_kbw_witch_blade:GetModifierAttackSpeedBonus_Constant()
	return self.attack
end
function m_item_kbw_witch_blade:GetModifierProjectileSpeedBonus()
	return self.proj_speed
end
function m_item_kbw_witch_blade:GetModifierConstantManaRegen()
	return self.mp_regen
end

LinkLuaModifier('m_item_kbw_witch_blade_debuff', sPath, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_witch_blade_debuff = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_witch_blade_debuff:OnCreated()
	ReadAbilityData(self, {
		'slow',
		'atr_damage_pct',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self:StartIntervalThink(1)

		self.nParticle = ParticleManager:Create('particles/items3_fx/witch_blade_debuff.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, hParent:GetOrigin(), false)
	end
end

function m_item_kbw_witch_blade_debuff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_item_kbw_witch_blade_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_item_kbw_witch_blade_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function m_item_kbw_witch_blade_debuff:OnIntervalThink()
	local hParent = self:GetParent()
	local hCaster = self:GetCaster()
	local hAbility = self:GetAbility()

	if hCaster and hCaster.GetPrimaryStatValue then
		local nDamage = math.floor(hCaster:GetPrimaryStatValue() * self.atr_damage_pct / 100 + 0.5)

		ApplyDamage({
			victim = hParent,
			attacker = hCaster,
			ability = hAbility,
			damage = nDamage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		})

		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, hParent, nDamage, nil)
	end
end