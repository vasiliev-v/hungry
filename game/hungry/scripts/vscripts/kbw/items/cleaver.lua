
LinkLuaModifier( 'm_item_kbw_battle_fury', "kbw/items/levels/battle_fury", 0 )
LinkLuaModifier("m_leaf_buckler_buff", 'kbw/items/item_leaf_buckler', LUA_MODIFIER_MOTION_NONE)

---------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_attack = 0,
		m_item_generic_regen = 0,
		m_item_generic_stats = 0,
		m_item_generic_speed = 0,
		m_item_kbw_battle_fury = 0,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('hungry_duration')
	
	AddModifier('m_leaf_buckler_buff', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:EmitSound('KBW.Item.LeafPlate.Cast')
end

---------------------------------------------
-- levels

CreateLevels({
	'item_kbw_cleaver',
	'item_kbw_cleaver_2',
	'item_kbw_cleaver_3',
}, base)