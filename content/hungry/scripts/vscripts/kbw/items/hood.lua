local PATH = 'kbw/items/hood'

LinkLuaModifier('m_item_kbw_vanguard_shield', "kbw/items/vanguard", LUA_MODIFIER_MOTION_NONE)

-----------------------------------
-- item

item_kbw_hood = class{}

function item_kbw_hood:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_kbw_hood:GetMultModifiers()
	return { 
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
	}
end

function item_kbw_hood:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('shield_duration')
	
	AddModifier('m_item_kbw_vanguard_shield', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:EmitSound('DOTA_Item.Pipe.Activate')
end