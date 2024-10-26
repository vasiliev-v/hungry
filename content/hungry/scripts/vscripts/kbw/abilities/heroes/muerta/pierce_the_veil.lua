local PATH = "kbw/abilities/heroes/muerta/pierce_the_veil"

----------------------------------------
----------------------------------------
----------------------------------------
-- ability 

muerta_pierce_the_veil_kbw = class{}

----------------------------------------
-- ability thinker. (auto cast tracker)

function muerta_pierce_the_veil_kbw:Spawn()
	if IsServer() then
		local state

		Timer(function()
			if exist(self) then
				local newstate = self:GetAutoCastState()
		
				if state ~= newstate then
					state = newstate
					local caster = self:GetCaster()
					
					if state then
						caster:AddNewModifier(caster, self, 'm_muerta_pierce_the_veil_kbw_gabe_daun', {})
					else
						caster:RemoveModifierByName('m_muerta_pierce_the_veil_kbw_gabe_daun')
					end
				end

				return FrameTime()
			end
		end)
	end
end

----------------------------------------
-- ability texture

function muerta_pierce_the_veil_kbw:GetAbilityTextureName()
	if self:GetCaster():HasModifier('m_muerta_pierce_the_veil_kbw_gabe_daun') then
		return 'muerta_pierce_the_veil_2'
	end
	return self.BaseClass.GetAbilityTextureName(self)
end

----------------------------------------
-- ability passive modifier

function muerta_pierce_the_veil_kbw:GetIntrinsicModifierName()
	return 'm_muerta_pierce_the_veil_kbw'
end

----------------------------------------
-- ability cast

function muerta_pierce_the_veil_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('duration')

	local mod = AddModifier('m_muerta_pierce_the_veil_kbw_buff', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	if mod then
		mod:AddSource(Vector(0,0,0), 99999)
	end

	ProjectileManager:ProjectileDodge(caster)
	caster:Purge(false, true, false, false, false)

	caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)

	caster:EmitSound('Hero_Muerta.PierceTheVeil.Cast')
end

----------------------------------------
-- auto cast flag (gabe daun)

LinkLuaModifier('m_muerta_pierce_the_veil_kbw_gabe_daun', PATH, LUA_MODIFIER_MOTION_NONE)
m_muerta_pierce_the_veil_kbw_gabe_daun = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

----------------------------------------
----------------------------------------
----------------------------------------
-- passive modifier

LinkLuaModifier('m_muerta_pierce_the_veil_kbw', PATH, LUA_MODIFIER_MOTION_NONE)
m_muerta_pierce_the_veil_kbw = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_muerta_pierce_the_veil_kbw:OnCreated()
	if IsServer() then
		self.records = {}
		self.ability = self:GetAbility()

		self:RegisterSelfEvents()
	end
end

function m_muerta_pierce_the_veil_kbw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_muerta_pierce_the_veil_kbw:DeclareFunctions()
	return {
		-- MODIFIER_PROPERTY_PROCATTACK_CONVERT_PHYSICAL_TO_MAGICAL, -- Gabe Daun
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_muerta_pierce_the_veil_kbw:OnParentAttackRecord(t)
	if t.attacker:HasModifier('m_muerta_pierce_the_veil_kbw_buff')
	and not self:GetCaster():HasModifier('m_muerta_pierce_the_veil_kbw_gabe_daun') then
		self.records[t.record] = true
	end
end

function m_muerta_pierce_the_veil_kbw:GetModifierTotalDamageOutgoing_Percentage(t)
	if t.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and self.records[t.record] then
		self.records[t.record] = nil
		if exist(self.ability) then
			if t.target:IsMagicImmune() then
				t.target:EmitSound('Hero_Muerta.PierceTheVeil.ProjectileImpact.MagicImmune')
			else
				local armor = t.target:GetPhysicalArmorValue(false) * self.ability:GetSpecialValueFor('armor_value') / 100
				local resist = GetArmorResist(armor)
				local damage = t.original_damage * (1 - resist)

				ApplyDamage({
					victim = t.target,
					attacker = t.attacker,
					ability = self.ability,
					damage = damage,
					damage_type = DAMAGE_TYPE_MAGICAL,
					damage_flags = DOTA_DAMAGE_FLAG_MAGIC_AUTO_ATTACK,
				})
			end

			return -100
		end
	end
end

----------------------------------------
----------------------------------------
----------------------------------------
-- active buff

LinkLuaModifier('m_muerta_pierce_the_veil_kbw_buff', PATH, LUA_MODIFIER_MOTION_NONE)
m_muerta_pierce_the_veil_kbw_buff = ModifierClass{
}

----------------------------------------
-- active buff util

function m_muerta_pierce_the_veil_kbw_buff:IsMagicalForm()
	return not self:GetCaster():HasModifier('m_muerta_pierce_the_veil_kbw_gabe_daun')
end

function m_muerta_pierce_the_veil_kbw_buff:IsMuerta()
	return self:GetParent():GetUnitName() == 'npc_dota_hero_muerta'
end

function m_muerta_pierce_the_veil_kbw_buff:AddSource(center, radius)
	table.insert(self.sources, {
		center = center,
		radius = radius,
		endtime = GameRules:GetGameTime() + self:GetRemainingTime()
	})
end

----------------------------------------
-- active buff status effect

function m_muerta_pierce_the_veil_kbw_buff:StatusEffectPriority()
	return 99999
end

function m_muerta_pierce_the_veil_kbw_buff:GetStatusEffectName()
	if not self:IsMuerta() then
		return 'particles/status_fx/status_effect_abaddon_borrowed_time.vpcf'
	end
end

----------------------------------------
-- active buff think (form switch + source check)

function m_muerta_pierce_the_veil_kbw_buff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local ability = self:GetAbility()
	if not ability then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local pos = parent:GetOrigin()
	local pad = parent:GetPaddedCollisionRadius()
	local time = GameRules:GetGameTime()

	-- form switch
	local alt = ability:GetAutoCastState()
	if alt ~= self.alt then
		if alt then
			parent:AddNewModifier(caster, ability, 'm_muerta_pierce_the_veil_kbw_buff_alt_status', {})

			ParticleManager:SetParticleControl(self.particle, 17, Vector(0.57, 0, 0))
			ParticleManager:SetParticleControl(self.particle2, 17, Vector(0.57, 0, 0))
		else
			parent:RemoveModifierByName('m_muerta_pierce_the_veil_kbw_buff_alt_status')

			ParticleManager:SetParticleControl(self.particle, 17, Vector(0, 0, 0))
			ParticleManager:SetParticleControl(self.particle2, 17, Vector(0, 0, 0))
		end

		if self.alt ~= nil then
			local particle = 'particles/units/heroes/hero_muerta/muerta_ultimate_form_finish.vpcf'
			particle = ParticleManager:Create(particle, PATTACH_ABSORIGIN_FOLLOW, parent, 2)

			if alt then
				ParticleManager:SetParticleControl(particle, 17, Vector(0.57, 0, 0))
			end

			parent:EmitSound('Hero_Muerta.PierceTheVeil.End')
		end

		self.alt = alt
	end

	-- source check
	for i = #self.sources, 1, -1 do
		local source = self.sources[i]
		if (time >= source.endtime)
		or ((pos - source.center):Length2D() > source.radius + pad) then
			table.remove(self.sources, i)
			if #self.sources == 0 then
				Timer(self.scepter_fade_delay, function()
					if exist(self) then
						self:Destroy()
					end
				end)
			end
		end
	end
end

----------------------------------------
-- active buff cycle

function m_muerta_pierce_the_veil_kbw_buff:OnCreated(t)
	self:OnRefresh(t)

	local parent = self:GetParent()
	local caster = self:GetCaster()

	if IsServer() then
		self.sources = {}

		self:RegisterSelfEvents()
		
		if parent ~= caster then
			parent:RemoveModifierByName('m_muerta_pierce_the_veil_kbw')
			self.passive_modifier = parent:AddNewModifier(caster, self:GetAbility(), 'm_muerta_pierce_the_veil_kbw', {})
		end

		self.particle = ParticleManager:Create('particles/units/heroes/hero_muerta/muerta_ultimate_form_ethereal.vpcf', parent)
		self.particle2 = ParticleManager:CreateParticleForPlayer(
			'particles/units/heroes/hero_muerta/muerta_ultimate_form_screen_effect.vpcf',
			PATTACH_ABSORIGIN_FOLLOW,
			parent,
			parent:GetPlayerOwner()
		)

		self:StartIntervalThink(FrameTime())
		self:OnIntervalThink()
	end
end

function m_muerta_pierce_the_veil_kbw_buff:OnRefresh()
	ReadAbilityData(self, {
		'model_scale',
		'bonus_damage',
		'bonus_speed',
		'scepter_fade_delay',
		'lifesteal',
	})
end

function m_muerta_pierce_the_veil_kbw_buff:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()

		self:UnregisterSelfEvents()
		
		if self.passive_modifier then
			Timer(10, function()
				if exist(self.passive_modifier) then
					self.passive_modifier:Destroy()
				end
			end)
		end
		
		parent:RemoveModifierByName('m_muerta_pierce_the_veil_kbw_buff_alt_status')

		ParticleManager:Fade(self.particle, true)
		ParticleManager:Fade(self.particle2, true)

		local particle = 'particles/units/heroes/hero_muerta/muerta_ultimate_form_finish.vpcf'
		particle = ParticleManager:Create(particle, PATTACH_ABSORIGIN_FOLLOW, parent, 2)

		parent:EmitSound('Hero_Muerta.PierceTheVeil.End')
	end
end

----------------------------------------
-- active buff effects

function m_muerta_pierce_the_veil_kbw_buff:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_CANNOT_TARGET_BUILDINGS] = self:IsMagicalForm() or nil,
		[MODIFIER_STATE_FLYING] = self:GetCaster():HasShard() or nil,
	}
end

function m_muerta_pierce_the_veil_kbw_buff:DeclareFunctions()
	local t = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	if self:IsMuerta() then
		table.insert(t, MODIFIER_PROPERTY_MODEL_CHANGE)
	end

	return t
end

function m_muerta_pierce_the_veil_kbw_buff:OnParentDealDamage(t)
	if self:GetCaster():HasShard() then
		self:GetParent():Heal(t.damage * self.lifesteal / 100, self:GetAbility())
	end
end

function m_muerta_pierce_the_veil_kbw_buff:GetAbsoluteNoDamagePhysical()
	return 1
end

function m_muerta_pierce_the_veil_kbw_buff:GetOverrideAttackMagical()
	if self:IsMagicalForm() then
		return 1
	end
end

function m_muerta_pierce_the_veil_kbw_buff:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function m_muerta_pierce_the_veil_kbw_buff:GetModifierModelChange()
	return 'models/heroes/muerta/muerta_ult.vmdl'
end

function m_muerta_pierce_the_veil_kbw_buff:GetModifierModelScale()
	return self.model_scale
end

function m_muerta_pierce_the_veil_kbw_buff:GetModifierProjectileName()
	if self:IsMagicalForm() then
		return 'particles/units/heroes/hero_muerta/muerta_ultimate_projectile.vpcf'
	else
		return 'particles/units/heroes/hero_muerta/muerta_ultimate_projectile_alternate.vpcf'
	end
end

function m_muerta_pierce_the_veil_kbw_buff:GetAttackSound()
	if self:GetParent():IsRangedAttacker() then
		return 'Hero_Muerta.PierceTheVeil.Attack'
	end
end

function m_muerta_pierce_the_veil_kbw_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetCaster():HasShard() then
		return self.bonus_speed
	end
end

----------------------------------------
----------------------------------------
----------------------------------------
-- active buff alternate statis effect

LinkLuaModifier('m_muerta_pierce_the_veil_kbw_buff_alt_status', PATH, LUA_MODIFIER_MOTION_NONE)
m_muerta_pierce_the_veil_kbw_buff_alt_status = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_muerta_pierce_the_veil_kbw_buff_alt_status:StatusEffectPriority()
	return 99999 + 1
end

function m_muerta_pierce_the_veil_kbw_buff_alt_status:GetStatusEffectName()
	return 'particles/status_fx/status_effect_muerta_veil_alternate.vpcf'
end