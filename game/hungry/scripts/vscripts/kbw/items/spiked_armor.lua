LinkLuaModifier('m_item_kbw_vanguard_block', "kbw/items/vanguard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_vanguard_shield', "kbw/items/vanguard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_blade_mail_return', "kbw/items/blade_mail", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_base = 0,
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_kbw_vanguard_block = 0,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local return_duration = self:GetSpecialValueFor('return_duration')
	local shield_duration = self:GetSpecialValueFor('shield_duration')
	
	AddModifier('m_item_kbw_vanguard_shield', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = shield_duration,
	})
	
	AddModifier('m_item_kbw_blade_mail_return', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = return_duration,
	})
	
	caster:EmitSound('Item.CrimsonGuard.Cast')
	caster:EmitSound('DOTA_Item.BladeMail.Activate')
end

---------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_spiked_armor',
	'item_kbw_spiked_armor_2',
	'item_kbw_spiked_armor_3',
}, base)