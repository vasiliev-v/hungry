local PATH = 'kbw/abilities/heroes/dark_willow/shadow_realm'

dark_willow_shadow_realm_kbw = class{}

-------------------------------------------------------------------
-- passive attack tracker

function dark_willow_shadow_realm_kbw:GetIntrinsicModifierName()
	return 'm_dark_willow_shadow_realm_kbw'
end

-------------------------------------------------------------------
-- active

function dark_willow_shadow_realm_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('duration')
	local delay = self:GetSpecialValueFor('delay')

	Timer(delay, function()
		if exist(caster) and exist(self) and caster:IsAlive() then
			AddModifier('m_dark_willow_shadow_realm_kbw_buff', {
				hTarget = caster,
				hCaster = caster,
				hAbility = self,
				duration = duration,
			})
		end

		ProjectileManager:ProjectileDodge(caster)
	end)
end

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------
-- active buff

LinkLuaModifier('m_dark_willow_shadow_realm_kbw_buff', PATH, LUA_MODIFIER_MOTION_NONE)
m_dark_willow_shadow_realm_kbw_buff = ModifierClass{
	bPurgable = true,
}

function m_dark_willow_shadow_realm_kbw_buff:GetStatusEffectName()
	return 'particles/status_fx/status_effect_dark_willow_shadow_realm.vpcf'
end

function m_dark_willow_shadow_realm_kbw_buff:StatusEffectPriority()
	return 9999 + 1
end

function m_dark_willow_shadow_realm_kbw_buff:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function m_dark_willow_shadow_realm_kbw_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_AUTOATTACK,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function m_dark_willow_shadow_realm_kbw_buff:GetDisableAutoAttack()
	if not self:HasScepter() then
		return 1
	end
end

function m_dark_willow_shadow_realm_kbw_buff:GetModifierAttackRangeBonus()
	return self.attack_range_bonus
end

function m_dark_willow_shadow_realm_kbw_buff:GetModifierProjectileName(t)
	return self.projectile
end

-------------------------------------------------------------------
-- active buff lifecycle

function m_dark_willow_shadow_realm_kbw_buff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()
		local duration = self:GetRemainingTime()

		if not self:HasScepter() then
			PreventAttack(parent)
		end

		self.particle = ParticleManager:Create('particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)

		self.sound_stop = PlaySound('Hero_DarkWillow.Shadow_Realm', parent, parent:GetTeam(), duration)
	end
end

function m_dark_willow_shadow_realm_kbw_buff:OnRefresh(t)
	ReadAbilityData(self, {
		'attack_range_bonus',
		'max_damage_duration',
		'damage',
		'pierce_bkb',
	})

	self.scepter = self:GetCaster():HasScepter()
end

function m_dark_willow_shadow_realm_kbw_buff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle, true)

		self.sound_stop()
	end
end

-------------------------------------------------------------------
-- active buff util

function m_dark_willow_shadow_realm_kbw_buff:HasScepter()
	return self.scepter
end

-------------------------------------------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------
-- passive attack tracker

LinkLuaModifier('m_dark_willow_shadow_realm_kbw', PATH, LUA_MODIFIER_MOTION_NONE)
m_dark_willow_shadow_realm_kbw = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_dark_willow_shadow_realm_kbw:OnCreated()
	if IsServer() then
		self.records = {}

		self:RegisterSelfEvents()
	end
end

function m_dark_willow_shadow_realm_kbw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

local function IsValidTarget(target, attacker)
	if not exist(target) or not target:IsBaseNPC() then
		return false
	end

	if UnitFilter(
		target,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		attacker:GetTeam()
	) ~= UF_SUCCESS then
		return false
	end

	return true
end

function m_dark_willow_shadow_realm_kbw:OnParentAttackStart(t)
	local buff = t.attacker:FindModifierByName('m_dark_willow_shadow_realm_kbw_buff')

	if buff then
		if IsValidTarget(t.target, t.attacker) then
			buff.projectile = 'particles/dev/empty_particle.vpcf'
		else
			buff.projectile = nil
		end
	end
end

function m_dark_willow_shadow_realm_kbw:OnParentAttack(t)
	if not IsValidTarget(t.target, t.attacker) then
		return
	end

	local buff = t.attacker:FindModifierByName('m_dark_willow_shadow_realm_kbw_buff')

	if buff and buff.max_damage_duration and buff.damage and buff.pierce_bkb and buff.HasScepter then

		local duration = GameRules:GetGameTime() - buff:GetCreationTime()
		local power = math.min(1, duration / buff.max_damage_duration)
		local damage = buff.damage * power

		local particle = ParticleManager:Create('particles/units/heroes/hero_dark_willow/dark_willow_shadow_attack.vpcf', PATTACH_CUSTOMORIGIN)
		local attach = (RandomFloat(0,1) > 0.5 and 'attach_attack1' or 'attach_attack2')
		ParticleManager:SetParticleControlEnt(particle, 0, t.attacker, PATTACH_POINT_FOLLOW, attach, t.attacker:GetOrigin(), false)
		ParticleManager:SetParticleControlEnt(particle, 1, t.target, PATTACH_POINT_FOLLOW, 'attach_hitloc', t.target:GetOrigin(), false)
		ParticleManager:SetParticleControl(particle, 2, Vector(t.attacker:GetProjectileSpeed(), 0, 0))
		ParticleManager:SetParticleControl(particle, 5, Vector(power, 0, 0))

		if power >= 1 then
			t.attacker:EmitSound('Hero_DarkWillow.Shadow_Realm.Attack')
		end

		self.records[t.record] = {
			particle = particle,
			damage = damage,
			pierce_bkb = (buff.pierce_bkb ~= 0),
		}

		if not buff:HasScepter() then
			buff:Destroy()
		end
	end
end

function m_dark_willow_shadow_realm_kbw:OnParentAttackLanded(t)
	local record = self.records[t.record]

	if record and record.damage then
		if exist(t.target) and t.target:IsAlive() then
			if record.pierce_bkb or not t.target:IsMagicImmune() then

				local ability = self:GetAbility()

				local damage = ApplyDamage({
					victim = t.target,
					attacker = t.attacker,
					ability = ability,
					damage = record.damage,
					damage_type = ability:GetAbilityDamageType(),
				})

				if damage > 0 then
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, t.target, damage, nil)
				end

				t.target:EmitSound('Hero_DarkWillow.Shadow_Realm.Damage')
			end
		end
	end
end

function m_dark_willow_shadow_realm_kbw:OnParentAttackRecordDestroy(t)
	local record = self.records[t.record]

	if record and record.particle then
		ParticleManager:Fade(record.particle, true)
	end

	self.records[t.record] = nil
end