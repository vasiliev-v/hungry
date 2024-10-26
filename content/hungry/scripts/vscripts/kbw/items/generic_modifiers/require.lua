local list = {
	m_item_generic_stats = {'all','str','agi','int'},
	m_item_generic_prime = {'prime','other'},
	m_item_generic_base = {'hp','mp'},
	m_item_generic_attack = {'damage','attack'},
	m_item_generic_base_damage = {'base_damage','base_damage_amp'},
	m_item_generic_regen = {'hp_regen','mp_regen'},
	m_item_generic_armor = {'armor'},
	m_item_generic_evasion = {'evasion'},
	m_item_generic_speed = {'movespeed','movespeed_pct'},
	m_item_generic_lifesteal = {'hero_lifesteal','creep_lifesteal'},
	m_item_generic_status_absorb = {'status_absorb'},
	m_item_generic_spell_damage = {'spell_damage'},
	m_item_generic_spell_cleave = {'spell_cleave'},
	m_item_generic_rune_counter = {'runes_max', 'runes_hp_regen', 'runes_mp_regen'},
	m_item_generic_cast_range_fix = {'fix_cast_range'},
	m_boots_override = {},
}

_G.GENERIC_MODIFIER_VALUES = {}

for mod, values in pairs(list) do
	LinkLuaModifier(mod, 'kbw/items/generic_modifiers/' .. mod, LUA_MODIFIER_MOTION_NONE)
	
	for _, value in ipairs(values) do
		_G.GENERIC_MODIFIER_VALUES[value] = mod
	end
end
