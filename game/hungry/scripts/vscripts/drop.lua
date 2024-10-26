if drop == nil then
	_G.drop = class({})
end

local iteamTypes = {
	item_lia_rune_of_healing = 1000,
	item_lia_rune_of_mana = 1000,
	item_lia_rune_of_restoration = 1000,
	item_lia_rune_of_lifesteal = 1000,
	item_lia_rune_gold = 1000,
	item_lia_health_stone_potion = 1000,
	item_lia_mana_stone_potion = 1000,
	item_lia_health_elixir = 1000,
	item_lia_mana_elixir = 1000,
	item_lia_healing_ward = 1000,
	item_clarity = 1000,
	item_faerie_fire = 1000,
	item_smoke_of_deceit = 1000,
	item_enchanted_mango = 1000,
	item_flask = 1000,
	item_tango = 1000,
	item_dust = 1000,
	item_gauntlets = 1000,
	item_slippers = 1000,
	item_mantle = 1000,
	item_circlet = 1000,
	item_quelling_blade = 1000,
	item_ring_of_protection = 1000,
	item_infused_raindrop = 1000,
	item_orb_of_venom = 1000,
	item_blight_stone = 1000,
	item_ring_of_regen = 1000,
	item_sobi_mask = 1000,
	item_fluffy_hat = 1000,
	item_wind_lace = 1000,
	item_buckler = 1000,
	item_magic_wand = 1000,

	item_belt_of_strength = 950,
	item_boots_of_elves = 950,
	item_robe = 950,
	item_crown = 950,
	item_blades_of_attack = 950,
	item_gloves = 950,
	item_chainmail = 950,
	item_cloak = 950,
	item_boots = 950,
	item_voodoo_mask = 950,
	item_null_talisman = 950,
	item_ring_of_basilius = 950,
	item_wraith_band = 950,
	item_bracer = 950,
	item_soul_ring = 950,
	item_blood_grenade = 950, 

	item_lia_rune_of_speed = 900,
	item_ogre_axe = 900,
	item_blade_of_alacrity = 900,
	item_staff_of_wizardry = 900,
	item_diadem = 900, 
	item_quarterstaff = 900,
	item_helm_of_iron_will = 900,
	item_broadsword = 900,
	item_blitz_knuckles = 900,
	item_lifesteal = 900,
	item_shadow_amulet = 900,
	item_glimmer_cape = 900,
	item_headdress = 900,
	item_force_staff = 900,
	item_blade_mail = 900,
	item_tranquil_boots = 900,
	item_orb_of_corrosion = 900,
	item_medallion_of_courage = 900,
	item_pavise = 900,
	item_falcon_blade = 900,
	item_ancient_janggo = 900,
	item_gem = 900,
	item_mithril_hammer = 900,

	item_javelin = 890,
	item_claymore = 890,
	item_ghost = 890,
	item_veil_of_discord = 890,
	item_arcane_boots = 890,
	item_oblivion_staff = 890,
	item_holy_locket = 890,
	item_pers = 890,
	item_ring_of_health = 890,
	item_void_stone = 890,
	item_cornucopia = 890,
	item_energy_booster = 890,
	item_vitality_booster = 890,
	item_point_booster = 890,
	item_talisman_of_evasion = 890,
	item_platemail = 890,
	item_hyperstone = 890,
	item_ultimate_orb = 890,
	

	item_blink = 850,
	item_hood_of_defiance = 850,
	item_lesser_crit = 850,
	item_dragon_lance = 850,
	item_vanguard = 850,
	item_kbw_sange = 850,
	item_armlet = 850,
	item_kbw_yasha = 850,
	item_kbw_kaya = 850,
	item_aether_lens = 850,
	item_basher = 850,
	item_rod_of_atos = 850,
	item_diffusal_blade = 850,
	item_power_treads = 850,
	item_phase_boots = 850,
	item_meteor_hammer = 850,
	item_mask_of_madness = 850,
	item_hand_of_midas = 850, 
	item_demon_edge = 850, 
	item_mystic_staff = 850, 
	item_reaver = 850, 
	item_eagle = 850, 
	tem_relic = 850, 

	item_lia_rune_of_strength = 800,
	item_lia_rune_of_agility = 800,
	item_lia_rune_of_intellect = 800,
	item_kbw_aeon_disk = 800,
	item_echo_sabre = 800,
	item_witch_blade = 800,
	item_invis_sword = 800,
	item_kbw_maelstrom = 800,
	item_dagon = 800, 
	item_lotus_orb = 800, 
	item_mage_slayer = 800,
	item_spirit_vessel = 800,

	item_cyclone = 750,
	item_eternal_shroud = 750,
	item_desolator = 750,
	item_bfury = 750,
	
	item_aghanims_shard = 700,
	item_soul_booster = 700,
	item_ethereal_blade = 700,
	item_mekansm = 700,
	
	item_vladmir = 650,
	item_solar_crest = 650,
	item_kbw_crimson_guard = 650,
	item_kbw_pipe = 650,

	item_orchid = 600,
	item_black_king_bar = 600,
	item_kbw_halberd = 600,
	item_kbw_kaya_sange = 600,
	item_phylactery = 600,
	item_kbw_sange_yasha = 600,
	item_kbw_yasha_kaya = 600,
	item_boots_of_bearing = 600,

	item_hurricane_pike = 550,
	item_manta = 550,
	item_radiance = 550,

	item_nullifier = 500,
	item_monkey_king_bar = 500,
	item_ultimate_scepter = 500,
	item_dagon_4 = 500,
	item_sphere = 500,
	--item_helm_of_the_dominator = 500,

	item_butterfly = 450,
	item_refresher = 450,
	item_guardian_greaves = 450,
	item_travel_boots = 450, 
	item_assault = 450,	

	item_silver_edge = 425,
	item_kbw_gleipnir = 425,
	item_kbw_mjolnir = 425,

	item_kbw_octarine = 400,
	item_kbw_shiva = 400,
	item_greater_crit = 400,
	item_moon_shard = 400,
	item_dagon_5 = 400,

	item_satanic = 350,
	item_sheepstick = 350,
	item_heart = 350,
	item_kbw_skadi = 350,
	item_wraith_pact = 350,
	item_kbw_bloodstone = 350,

	item_rapier = 300,
	item_wind_waker = 300,
	item_abyssal_blade = 300,
	item_bloodthorn = 300,
	item_revenants_brooch = 300,
	item_disperser = 300,

	item_swift_blink = 300,
	item_overwhelming_blink = 300,
	item_arcane_blink = 300,

}

item_drop = {
	--{items = {"item_branches"}, chance = 50, duration = 50, limit = 3, units = {} },
	
	-- слабый босс 
	{items = {"item_lia_totem_of_persistence", "item_glimmer_shield", "item_health_radiance", "item_primal_magic_1", "item_magic_fire_1","item_moon_yasha", "item_moon_sange", "item_moon_kaya", "item_meteor_lens", "item_mana_radiance", "item_torture_pipe_1", "item_lia_blade_of_rage_agi", "item_lia_blade_of_rage_str", "item_lia_blade_of_rage_int", "item_lia_sword_of_solidarity", "item_lia_fire_gloves", "item_lia_pure_light","item_lia_staff_of_illusions","item_lia_staff_of_life","item_lia_fire_rod", "item_lia_fire_gloves_2"}, limit = 100, chance = 500, units = {"pudge_megaboss"} },
	{items = {"item_duelist_gloves","item_spark_of_courage","item_keen_optic", "item_ocean_heart", "item_faded_broach", "item_seeds_of_serenity", "item_broom_handle", "item_arcane_ring", "item_lance_of_pursuit", "item_royal_jelly", "item_chipped_vest","item_possessed_mask","item_mysterious_hat", "item_unstable_wand", "item_pogo_stick"}, limit = 100, chance = 350, units = {"pudge_megaboss"} },
	{items = {"item_ring_of_aquila", "item_imp_claw", "item_specialists_array", "item_nether_shawl", "item_eye_of_the_vizier","item_gossamer_cape", "item_dragon_scale", "item_pupils_gift", "item_vambrace", "item_misericorde","item_grove_bow","item_essence_ring","item_dagger_of_ristul", "item_bullwhip", "item_quicksilver_amulet"}, limit = 100, chance = 250, units = {"pudge_megaboss"} },

	{items = {"item_madness_blade_mail","item_lia_totem_of_persistence", "item_primal_magic_2", "item_magic_fire_2", "item_discord_robe", "item_edge_of_discord", "item_torture_pipe_2", "item_lia_blood_moon", "item_lia_crusher", "item_lia_bounty_hunters_crossbow", "item_lia_ghost_blade", "item_lia_blade_of_incorporeality", "item_lia_sword_of_solidarity_2", "item_lia_divine_armor","item_lia_lunar_necklace"}, limit = 100, chance = 500, units = {"brood_megaboss"} },
	{items = {"item_madness_blade_mail","item_lia_totem_of_persistence", "item_primal_magic_2", "item_magic_fire_2", "item_discord_robe", "item_edge_of_discord", "item_torture_pipe_2", "item_lia_blood_moon", "item_lia_crusher", "item_lia_bounty_hunters_crossbow", "item_lia_ghost_blade", "item_lia_blade_of_incorporeality", "item_lia_sword_of_solidarity_2", "item_lia_divine_armor","item_lia_lunar_necklace"}, limit = 100, chance = 500, units = {"apparat_megaboss"} },
	{items = {"item_madness_blade_mail","item_lia_totem_of_persistence", "item_primal_magic_2", "item_magic_fire_2", "item_discord_robe", "item_edge_of_discord", "item_torture_pipe_2", "item_lia_blood_moon", "item_lia_crusher", "item_lia_bounty_hunters_crossbow", "item_lia_ghost_blade", "item_lia_blade_of_incorporeality", "item_lia_sword_of_solidarity_2", "item_lia_divine_armor","item_lia_lunar_necklace"}, limit = 100, chance = 500, units = {"phoenix_megaboss"} },
	{items = {"item_madness_blade_mail","item_lia_totem_of_persistence", "item_primal_magic_2", "item_magic_fire_2", "item_discord_robe", "item_edge_of_discord", "item_torture_pipe_2", "item_lia_blood_moon", "item_lia_crusher", "item_lia_bounty_hunters_crossbow", "item_lia_ghost_blade", "item_lia_blade_of_incorporeality", "item_lia_sword_of_solidarity_2", "item_lia_divine_armor","item_lia_lunar_necklace"}, limit = 100, chance = 500, units = {"tide_megaboss"} },
	{items = {"item_quickening_charm", "item_black_powder_bag", "item_spider_legs", "item_paladin_sword", "item_titan_sliver", "item_mind_breaker","item_enchanted_quiver","item_elven_tunic","item_cloak_of_flames", "item_ceremonial_robe", "item_psychic_headband", "item_orb_of_destruction","item_defiant_shell", "item_vindicators_axe", "item_dandelion_amulet",  "item_ogre_seal_totem"}, limit = 100, chance = 350, units = {"brood_megaboss"} },
	{items = {"item_quickening_charm", "item_black_powder_bag", "item_spider_legs", "item_paladin_sword", "item_titan_sliver", "item_mind_breaker","item_enchanted_quiver","item_elven_tunic","item_cloak_of_flames", "item_ceremonial_robe", "item_psychic_headband", "item_orb_of_destruction","item_defiant_shell", "item_vindicators_axe", "item_dandelion_amulet",  "item_ogre_seal_totem"}, limit = 100, chance = 350, units = {"apparat_megaboss"} },
	{items = {"item_quickening_charm", "item_black_powder_bag", "item_spider_legs", "item_paladin_sword", "item_titan_sliver", "item_mind_breaker","item_enchanted_quiver","item_elven_tunic","item_cloak_of_flames", "item_ceremonial_robe", "item_psychic_headband", "item_orb_of_destruction","item_defiant_shell", "item_vindicators_axe", "item_dandelion_amulet",  "item_ogre_seal_totem"}, limit = 100, chance = 350, units = {"phoenix_megaboss"} },
	{items = {"item_quickening_charm", "item_black_powder_bag", "item_spider_legs", "item_paladin_sword", "item_titan_sliver", "item_mind_breaker","item_enchanted_quiver","item_elven_tunic","item_cloak_of_flames", "item_ceremonial_robe", "item_psychic_headband", "item_orb_of_destruction","item_defiant_shell", "item_vindicators_axe", "item_dandelion_amulet",  "item_ogre_seal_totem"}, limit = 100, chance = 350, units = {"tide_megaboss"} },	
	{items = {"item_illusionsts_cape", "item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 250, units = {"brood_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 250, units = {"apparat_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 250, units = {"phoenix_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 250, units = {"tide_megaboss"} },	

	{items = {"item_cheese"}, limit = 100, chance = 50, units = {"brood_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 50, units = {"apparat_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 50, units = {"phoenix_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 50, units = {"tide_megaboss"} },	

	{items = {"item_lia_totem_of_persistence", "item_mage_destroyer", "item_diffusal_basher", "item_mask_of_sange_and_yasha", "item_luminance", "item_primal_magic_3", "item_magic_fire_3", "item_celestial_yasha", "item_celestial_sange", "item_lia_lightning_bow", "item_lia_hammer_of_titans", "item_lia_poleaxe_of_rage", "item_lia_ice_sword", "item_lia_armor_of_the_red_mist","item_lia_spellbreaker","item_lia_ferus_shield"}, limit = 100, chance = 500, units = {"venom_megaboss"} },
	{items = {"item_lia_totem_of_persistence", "item_mage_destroyer", "item_diffusal_basher", "item_mask_of_sange_and_yasha", "item_luminance", "item_primal_magic_3", "item_magic_fire_3", "item_celestial_yasha", "item_celestial_sange", "item_lia_lightning_bow", "item_lia_hammer_of_titans", "item_lia_poleaxe_of_rage", "item_lia_ice_sword", "item_lia_armor_of_the_red_mist","item_lia_spellbreaker","item_lia_ferus_shield"}, limit = 100, chance = 500, units = {"lich_megaboss"} },
	{items = {"item_lia_totem_of_persistence", "item_mage_destroyer", "item_diffusal_basher", "item_mask_of_sange_and_yasha", "item_luminance", "item_primal_magic_3", "item_magic_fire_3", "item_celestial_yasha", "item_celestial_sange", "item_lia_lightning_bow", "item_lia_hammer_of_titans", "item_lia_poleaxe_of_rage", "item_lia_ice_sword", "item_lia_armor_of_the_red_mist","item_lia_spellbreaker","item_lia_ferus_shield"}, limit = 100, chance = 500, units = {"lina_megaboss"} },
	{items = {"item_lia_totem_of_persistence", "item_mage_destroyer", "item_diffusal_basher", "item_mask_of_sange_and_yasha", "item_luminance", "item_primal_magic_3", "item_magic_fire_3", "item_celestial_yasha", "item_celestial_sange", "item_lia_lightning_bow", "item_lia_hammer_of_titans", "item_lia_poleaxe_of_rage", "item_lia_ice_sword", "item_lia_armor_of_the_red_mist","item_lia_spellbreaker","item_lia_ferus_shield"}, limit = 100, chance = 500, units = {"morph_megaboss"} },	
	{items = {"item_giants_ring", "item_force_boots", "item_desolator_2", "item_seer_stone", "item_apex","item_fallen_sky","item_force_field","item_pirate_hat","item_ex_machina","item_book_of_shadows"}, limit = 100, chance = 250, units = {"venom_megaboss"} },
	{items = {"item_giants_ring", "item_force_boots", "item_desolator_2", "item_seer_stone", "item_apex","item_fallen_sky","item_force_field","item_pirate_hat","item_ex_machina","item_book_of_shadows"}, limit = 100, chance = 250, units = {"lich_megaboss"} },
	{items = {"item_giants_ring", "item_force_boots", "item_desolator_2", "item_seer_stone", "item_apex","item_fallen_sky","item_force_field","item_pirate_hat","item_ex_machina","item_book_of_shadows"}, limit = 100, chance = 250, units = {"lina_megaboss"} },
	{items = {"item_giants_ring", "item_force_boots", "item_desolator_2", "item_seer_stone", "item_apex","item_fallen_sky","item_force_field","item_pirate_hat","item_ex_machina","item_book_of_shadows"}, limit = 100, chance = 250, units = {"morph_megaboss"} },	
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 350, units = {"venom_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 350, units = {"lich_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 350, units = {"lina_megaboss"} },
	{items = {"item_illusionsts_cape","item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 350, units = {"morph_megaboss"} },	
	
	{items = {"item_keen_optic", "item_ocean_heart", "item_faded_broach", "item_seeds_of_serenity", "item_broom_handle", "item_arcane_ring", "item_lance_of_pursuit", "item_royal_jelly", "item_chipped_vest","item_possessed_mask","item_mysterious_hat", "item_unstable_wand", "item_pogo_stick"}, limit = 100, chance = 500, units = {"1_wave_boss_extreme","2_wave_boss_extreme","3_wave_boss_extreme","4_wave_boss_extreme", "5_wave_boss_extreme"} },
	{items = {"item_ring_of_aquila", "item_imp_claw", "item_specialists_array", "item_nether_shawl", "item_eye_of_the_vizier","item_gossamer_cape", "item_dragon_scale", "item_pupils_gift", "item_vambrace", "item_misericorde","item_grove_bow","item_essence_ring","item_dagger_of_ristul", "item_bullwhip", "item_quicksilver_amulet"}, limit = 100, chance = 500, units = {"6_wave_boss_extreme","7_wave_boss_extreme","8_wave_boss_extreme","9_wave_boss_extreme", "10_wave_boss_extreme"} },
	{items = {"item_quickening_charm", "item_black_powder_bag", "item_spider_legs", "item_paladin_sword", "item_titan_sliver", "item_mind_breaker","item_enchanted_quiver","item_elven_tunic","item_cloak_of_flames", "item_ceremonial_robe", "item_psychic_headband", "item_orb_of_destruction", "item_defiant_shell", "item_vindicators_axe", "item_dandelion_amulet", "item_ogre_seal_totem"}, limit = 100, chance = 500, units = {"11_wave_boss_extreme","12_wave_boss_extreme","13_wave_boss_extreme","14_wave_boss_extreme", "15_wave_boss_extreme"} },	
	{items = {"item_illusionsts_cape", "item_timeless_relic", "item_spell_prism", "item_ascetic_cap", "item_heavy_blade", "item_flicker","item_ninja_gear","item_minotaur_horn","item_martyrs_plate", "item_havoc_hammer","item_trickster_cloak","item_ex_machina","item_stormcrafter","item_penta_edged_sword"}, limit = 100, chance = 500, units = {"16_wave_boss_extreme","17_wave_boss_extreme","18_wave_boss_extreme","19_wave_boss_extreme", "20_wave_boss_extreme"} },
	{items = {"item_lia_rune_of_strength", "item_lia_rune_of_agility", "item_lia_rune_of_intellect", "item_lia_rune_of_knowledge"}, limit = 100, chance = 250, units = {"1_wave_boss_extreme","2_wave_boss_extreme","3_wave_boss_extreme","4_wave_boss_extreme", "5_wave_boss_extreme","6_wave_boss_extreme","7_wave_boss_extreme","8_wave_boss_extreme","9_wave_boss_extreme", "10_wave_boss_extreme","11_wave_boss_extreme","12_wave_boss_extreme","13_wave_boss_extreme","14_wave_boss_extreme", "15_wave_boss_extreme", "16_wave_boss_extreme","17_wave_boss_extreme","18_wave_boss_extreme","19_wave_boss_extreme", "20_wave_boss_extreme"} },

	{items = {"item_cheese"}, limit = 100, chance = 100, units = {"venom_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 100, units = {"lich_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 100, units = {"lina_megaboss"} },
	{items = {"item_cheese"}, limit = 100, chance = 100, units = {"morph_megaboss"} },

	--[[
	item_lia_rune_of_strength = 1,
	item_lia_rune_of_agility = 1,
	item_lia_rune_of_intellect = 1,
	item_lia_rune_gold = 1,
	item_lia_rune_of_knowledge = 1, 
	--]]
}

local sortTable = {}
sortTable[0] = {}

local MAX_CREEP = 19



function GetRandomRuneType(unit_name)
	local rand = 1
	local i = 0

	if string.match(unit_name, "_wave_creep") then
		rand = tonumber(string.match(unit_name,"%d+"))
	elseif string.match(unit_name, "_wave_boss_extreme") then
		rand = tonumber(string.match(unit_name,"%d+")) + 10
	elseif string.match(unit_name, "_wave_boss") then
		rand = tonumber(string.match(unit_name,"%d+")) + 5
	end

	if rand > MAX_CREEP then
		rand = MAX_CREEP
	end
	local minRand = 1000 - ((700/MAX_CREEP) * rand)
	
	local startRand = math.ceil(minRand*2) 
	print(startRand)
	print(minRand)
	print("----")
	for k,v in pairs(iteamTypes) do
		if v >= minRand and v <= startRand then
			sortTable[i] = {k, v }
			i = i + 1
		end
	end
	--print(sortTable[RandomInt(0, #sortTable)][1])
	return sortTable[RandomInt(0, #sortTable)][1]

end

function drop:RollItemDrop(unit, attacker)
	local unit_name = unit:GetUnitName()
	local rand =  RandomFloat(0, 100)
	local spawnPoint = unit:GetAbsOrigin()

	if string.match(unit_name, "_wave_boss") then
		rand = rand + 50
	end
	if string.match(unit_name, "_wave_") and not string.match(unit_name, "_wave_boss_extreme") and rand > 90 then
		local newItem = CreateItem( GetRandomRuneType(unit_name), attacker, attacker )
		newItem:SetShareability(ITEM_FULLY_SHAREABLE)
		local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )
		local dropRadius = RandomFloat( 10, 64 )			
		newItem:LaunchLootInitialHeight( false, 0, 150, 0.50, spawnPoint + RandomVector( dropRadius ) )
		newItem:SetContextThink( "KillLoot", function() return KillLoot( newItem, drop ) end, ITEM_LIFE_TIME_DROP )
	else
		for _,drop in ipairs(item_drop) do
			local items = drop.items or nil
			local items_num = #items
			local units = drop.units or nil -- если юниты не были определены, то срабатывает для любого
			local chance = drop.chance or 500 -- если шанс не был определен, то он равен 100
			local limit = drop.limit or nil -- лимит предметов
			local item_name = items[1] -- название предмета
			local roll_chance = RandomFloat(0, 500)
			
			
			if units then 
				for _,current_name in pairs(units) do
					if current_name == unit_name then
						units = nil
						break
					end
				end
			end
	
			if units == nil and (limit == nil or limit > 0) and roll_chance < chance then
				if limit then
					drop.limit = drop.limit - 1
				end
				
				if items_num > 1 then
					item_name = items[RandomInt(1, #items)]
				end
	
				local newItem = CreateItem( item_name, attacker, attacker )
				newItem:SetShareability(ITEM_FULLY_SHAREABLE)
				local drop = CreateItemOnPositionForLaunch( spawnPoint, newItem )			
				local dropRadius = RandomFloat( 50, 250 )
				newItem:LaunchLootInitialHeight( false, 0, 150, 0.50, spawnPoint + RandomVector( dropRadius ) )
				newItem:SetContextThink( "KillLoot", function() return KillLoot( newItem, drop ) end, ITEM_LIFE_TIME )
			end
		end	


		
	
	end
end


function KillLoot( item, drop )
	
	if drop:IsNull() then
		return
	end
	
	local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, drop )
	ParticleManager:SetParticleControl( nFXIndex, 0, drop:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )
	--	EmitGlobalSound("Item.PickUpWorld")
	
	UTIL_Remove( item )
	UTIL_Remove( drop )
end

