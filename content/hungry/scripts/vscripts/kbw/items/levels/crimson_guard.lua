LinkLuaModifier('m_item_kbw_vanguard_block', 'kbw/items/vanguard', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_vanguard_shield', 'kbw/items/vanguard', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_fury_shield_buff', 'kbw/items/fury_shield', LUA_MODIFIER_MOTION_NONE)

-- item

local base = {}

function base:Precache(c)
	PrecacheResource('particle', 'particles/items2_fx/vanguard_active.vpcf', c)
	PrecacheResource('particle', 'particles/items2_fx/vanguard_active_launch.vpcf', c)
	PrecacheResource('particle', 'particles/items2_fx/vanguard_active_impact.vpcf', c)
end

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_kbw_vanguard_block = 0,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('duration')
	local radius = self:GetSpecialValueFor('radius')
	
	local units = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetOrigin(),
		caster,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in ipairs(units) do
		AddModifier('m_item_fury_shield_buff', {
			hTarget = unit,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})

		AddModifier('m_item_kbw_vanguard_shield', {
			hTarget = unit,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
	end

	caster:EmitSound('Item.CrimsonGuard.Cast')
end

-- levels

CreateLevels({
	'item_kbw_crimson_guard',
	'item_kbw_crimson_guard_2',
	'item_kbw_crimson_guard_3',
}, base)