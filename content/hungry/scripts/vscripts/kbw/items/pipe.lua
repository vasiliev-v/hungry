local PATH = "kbw/items/pipe"

LinkLuaModifier('m_item_kbw_vanguard_shield', "kbw/items/vanguard", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_cast_range_fix = 0,
		m_item_generic_base = 0,
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_kbw_pipe_aura = self.nLevel,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('shield_duration')
	local radius = self:GetSpecialValueFor('radius')
	
	local units = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetOrigin(),
		caster,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in ipairs(units) do
		AddModifier('m_item_kbw_vanguard_shield', {
			hTarget = unit,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
	end

	caster:EmitSound('DOTA_Item.Pipe.Activate')
end

------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_pipe',
	'item_kbw_pipe_2',
	'item_kbw_pipe_3',
}, base)

------------------------------------------------
-- modifier: aura source

LinkLuaModifier('m_item_kbw_pipe_aura', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pipe_aura = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_pipe_aura:OnCreated(t)
	ReadAbilityData(self, {
		'radius',
	}, function(ability)
		if IsServer() then
			self.aura = CreateAura({
				sModifier = 'm_item_kbw_pipe_aura_buff',
				hSource = self,
				bNoStack = true,
				nLevel = ability.nLevel,
				nRadius = self.radius,
			})
		end
	end)
end

function m_item_kbw_pipe_aura:OnDestroy(t)
	if exist(self.aura) then
		self.aura:Destroy()
	end
end

function m_item_kbw_pipe_aura:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

------------------------------------------------
-- modifier: aura effect

LinkLuaModifier('m_item_kbw_pipe_aura_buff', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_pipe_aura_buff = ModifierClass{
}

function m_item_kbw_pipe_aura_buff:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_kbw_pipe_aura_buff:OnRefresh(t)
	ReadAbilityData(self, {
		'aura_magic_resist',
		'aura_hp_regen',
	})
end

function m_item_kbw_pipe_aura_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function m_item_kbw_pipe_aura_buff:GetModifierMagicalResistanceBonus()
	return self.aura_magic_resist
end

function m_item_kbw_pipe_aura_buff:GetModifierConstantHealthRegen()
	return self.aura_hp_regen
end