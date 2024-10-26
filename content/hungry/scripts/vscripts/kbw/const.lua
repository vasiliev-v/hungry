ITEM_SLOT_LAST = DOTA_ITEM_NEUTRAL_SLOT

self.bToolsQuickStart = true
self.bDisableToolsBan = true
self.bDisableToolsDuel = true

DISABLE_RANK_BALANCE = true

INTELLECT_SPELL_DAMAGE = 0.04
STRENGTH_MAGIC_HEALTH = 0.04
BOSS_DAMAGE_RANGE = 1800
MAX_LEVEL = 30
UNIT_LIMIT = 32
PRE_GAME_TIME = 45
STAT_GAIN_GAIN = 0.175
self.nPostGame = 180
TEAM_RANK_PLAYERS = 5
ESTIMATED_PLAYERS = 10
-- COURIER_RESPAWN_TIME = 50 -- no related API 
SPELL_CLEAVE_RADIUS = 400

self.tAttributeBonuses = {
	-- [DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST] = 0, -- doesn't work
}

self.tBlackList = {
	npc_dota_hero_undying     = 1,
}

BOSS_DAMAGE_INFLICTORS = {
	item_blade_mail = 0.1,
	item_blade_mail2 = 0.1,
	item_blade_mail3 = 0.1,
	item_kbw_ethereal_blade = 0.1,
	item_kbw_ethereal_blade_2 = 0.1,
	item_kbw_ethereal_blade_3 = 0.1,
	zuus_arc_lightning = 0.02,
	bloodseeker_blood_mist = 0.05,
	bloodseeker_rupture = 0.1,
	doom_bringer_infernal_blade = 0.05,
	huskar_life_break = 0.05,
	necrolyte_reapers_scythe = 0.05,
	-- abyssal_underlord_firestorm = 0.05,
	witch_doctor_maledict = 0.05,
	spectre_dispersion = 0.05,
	winter_wyvern_arctic_burn = 0.05,
	jakiro_liquid_ice = 0.1,
	phantom_assassin_fan_of_knives = 0.1,
	bristleback_quill_spray = 0.5,
	venomancer_poison_nova = 0.05,
	venomancer_noxious_plague = 0.05,
	enigma_midnight_pulse = 0.05,
	witch_doctor_voodoo_restoration = 0.05,
	enigma_black_hole = function(hAbility)
		return hAbility:GetCaster():HasScepter() and 0.1 or 1
	end,
}

BOSS_RANGE_INFLICTORS = {
	-- npc_dota_techies_land_mine = true,
}

SUPER_STATIC_UNITS = {
	npc_dota_observer_wards = 1,
	npc_dota_sentry_wards = 1,
	npc_dota_invisible_vision_source = 1,
	npc_dota_aether_remnant = 1,
	npc_dota_wisp_spirit = 1,
	npc_dota_treant_eyes = 1,
	aghsfort_mars_bulwark_soldier = 1,
	npc_dota_templar_assassin_psionic_trap = 1,
	npc_dota_gyrocopter_homing_missile = 1,
	npc_dota_troll_warlord_axe = 1,
	npc_dota_weaver_swarm = 1,
	npc_dota_dark_willow_creature = 1,
	npc_dota_grimstroke_ink_creature = 1,
	npc_dota_techies_remote_mine = 1,
	npc_dota_broodmother_web = 1,

	npc_dota_stormspirit_remnant = 1, -- particle shit
	npc_dota_ember_spirit_remnant = 1, -- particle shit
	npc_dota_ignis_fatuus = 1, -- particle shit (kotl scepter)
	npc_dota_zeus_cloud = 1, -- particle shit
}

ENEMY_FOUNTAIN_FORBIDEN_SPELLS = {
	-- keeper_of_the_light_will_o_wisp = 1,
}

self.tDev = {
	[1106545564] = true,
	[259596687] = true,
	[238074774] = true,
	[171685381] = true,
	[1194628962] = true,
	[1200467410] = true,
	[1228245276] = true,
}
_G.DEV = self.tDev -- for extern console

self.tPlayerColors = {
	[DOTA_TEAM_GOODGUYS] = {
		{ 33, 94, 13 }, -- dark green
		{ 5, 112, 112 }, -- dark cyan
		{ 21, 86, 255 }, -- blue
		{ 43, 150, 255 }, -- sky
		{ 21, 255, 255 }, -- cyan
		{ 21, 240, 128 }, -- teal
		{ 0, 213, 0 }, -- green
		{ 146, 234, 0 }, -- salt
	},
	[DOTA_TEAM_BADGUYS] = {
		{ 244, 216, 11 }, -- yellow
		{ 240, 102, 0 }, -- orange
		{ 239, 38, 16 }, -- red
		{ 251, 47, 149 }, -- pink
		{ 231, 88, 231 }, -- liliac
		{ 146, 36, 255 }, -- purple
		{ 128, 21, 50 }, -- wine
		{ 115, 46, 0 }, -- brown
	},
}

self.tTeleportColors = {
	Vector(0.06, 0.1, 0),
	Vector(0.5, 0, 0),
	Vector(0.34, 0, 0),
	Vector(0.9, 0, 0),
	Vector(0.66, 0, 0),
	Vector(0, 0, 0),
}

self.tHuetaItems = {
	item_assault = 1,
	item_vladmir = 1,
	item_kbw_pipe = 1,
	item_guardian_greaves = 1,
}
