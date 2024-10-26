local items = {
	item_kbw_bracer = {
		m_item_generic_stats = 0,
		m_item_generic_regen = 0,
		m_item_generic_armor = 0,
	},
	item_kbw_wraith_band = {
		m_item_generic_stats = 0,
		m_item_generic_attack = 0,
	},
	item_kbw_null_talisman = {
		m_item_generic_stats = 0,
		m_item_generic_regen = 0,
		m_item_generic_spell_cleave = 0,
	},
}

local env = getfenv(1)

for name, modifiers in pairs(items) do
	local item = class{}

	function item:GetIntrinsicModifierName()
		return 'm_mult'
	end
	
	function item:GetMultModifiers()
		return modifiers
	end

	env[name] = item
end