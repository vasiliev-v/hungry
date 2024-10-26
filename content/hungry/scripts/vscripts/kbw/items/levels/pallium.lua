local PATH = "kbw/items/levels/pallium"
local base = {}

-------------------------------------------
-- indicator

function base:GetAOERadius()
	return self:GetSpecialValueFor('active_radius')
end

-------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_armor = 0,
		m_item_kbw_pallium_passive = self.nLevel,
	}
end

-------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()
	local radius = self:GetAOERadius()
	local duration = self:GetSpecialValueFor('active_duration')

	-- blast

	local units = Find:UnitsInRadius{
		vCenter = pos,
		nRadius = radius,
		nTeam = caster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		nFilterFlag = 0,
	}

	for _, unit in ipairs(units) do
		local mod = unit:FindModifierByName('m_item_kbw_pallium_active')

		if mod and mod.level and mod.level > self.nLevel then
			mod:SetDuration(duration * (1 - unit:GetStatusResistance()), true)
		else
			mod = AddModifier('m_item_kbw_pallium_active', {
				hTarget = unit,
				hCaster = caster,
				hAbility = self,
				duration = duration,
			})
			if mod then
				mod.level = self.nLevel
			end
		end
	end

	-- decorate

	local particle = ParticleManager:Create('particles/items/blade_of_discord/explosion.vpcf', PATTACH_WORLDORIGIN, 2)
	ParticleManager:SetParticleControl( particle, 0, pos )
	ParticleManager:SetParticleControl( particle, 1, Vector( radius, 0, radius ) )
	ParticleManager:SetParticleFoWProperties( particle, 0, 0, radius )

	EmitSoundOnLocationWithCaster(pos, 'DOTA_Item.VeilofDiscord.Activate', caster)
end

-------------------------------------------
-- levels

CreateLevels({
	'item_kbw_pallium',
	'item_kbw_pallium_2',
	'item_kbw_pallium_3',
}, base)

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- active debuff

LinkLuaModifier('m_item_kbw_pallium_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pallium_active = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_pallium_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_item_kbw_pallium_active:OnTooltip()
	return self.active_damage_amp
end

function m_item_kbw_pallium_active:OnCreated()
	ReadAbilityData(self, {
		'active_damage_amp',
	})

	if IsServer() then
		local parent = self:GetParent()

		self.mod_damage = AddSpecialModifier(parent, 'nDamageResist', -self.active_damage_amp / 100, OPERATION_ASYMPTOTE)

		self.particle = ParticleManager:Create('particles/items/pallium/buff.vpcf', parent)
	end
end

function m_item_kbw_pallium_active:OnDestroy()
	if IsServer() then
		if exist(self.mod_damage) then
			self.mod_damage:Destroy()
		end

		ParticleManager:Fade(self.particle, true)
	end
end

function m_item_kbw_pallium_active:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- passive aura source

LinkLuaModifier('m_item_kbw_pallium_passive', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pallium_passive = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_item_kbw_pallium_passive:OnCreated()
	ReadAbilityData(self, {
		'aura_radius',
	})

	if IsServer() then
		local ability = self:GetAbility()
		if not ability then
			return
		end

		self.aura1 = CreateAura{
			sModifier = 'm_item_kbw_pallium_aura_effect',
			nLevel = ability.nLevel,
			hSource = self,
			nRadius = self.aura_radius,
			bNoStack = true,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		}

		self.aura2 = CreateAura{
			sModifier = 'm_item_kbw_pallium_aura_debuff',
			nLevel = ability.nLevel,
			hSource = self,
			nRadius = self.aura_radius,
			bNoStack = true,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		}
	end
end

function m_item_kbw_pallium_passive:OnDestroy()
	if IsServer() then
		if exist(self.aura1) then
			self.aura1:Destroy()
		end
		if exist(self.aura2) then
			self.aura2:Destroy()
		end
	end
end

function m_item_kbw_pallium_passive:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- passive aura buff

LinkLuaModifier('m_item_kbw_pallium_aura_effect', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pallium_aura_effect  = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_pallium_aura_effect:DeclareFunctions(t)
	return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_item_kbw_pallium_aura_effect:GetModifierConstantManaRegen(t)
	return self.aura_mp_regen
end

function m_item_kbw_pallium_aura_effect:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_kbw_pallium_aura_effect:OnRefresh()
	ReadAbilityData(self, {
		'aura_mp_regen',
	})
end

-------------------------------------------
-------------------------------------------
-------------------------------------------
-- passive aura debuff

LinkLuaModifier('m_item_kbw_pallium_aura_debuff', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pallium_aura_debuff  = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_pallium_aura_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_item_kbw_pallium_aura_debuff:OnTooltip()
	return self.aura_spell_deamp
end

function m_item_kbw_pallium_aura_debuff:GetModifierTotalDamageOutgoing_Percentage(t)
	if t.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		return -self.aura_spell_deamp
	end
end

function m_item_kbw_pallium_aura_debuff:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_kbw_pallium_aura_debuff:OnRefresh()
	ReadAbilityData(self, {
		'aura_spell_deamp',
	})
end