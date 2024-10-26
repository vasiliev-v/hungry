require('events_protector')
require('internal/util')
require('LiA_GameMode')
require('utils')
require('survival/AIcreeps')
require('timers')

--require('physics')



require('top')
require('wearables')
require('SelectPets')
require('pets')
require('shop')
require("PrecacheLoad")
require('reklama')

LinkLuaModifier( "modifier_ward_stack", "modifiers/modifier_ward_stack", LUA_MODIFIER_MOTION_NONE )

local aModifiers = {
	-- internal
	'm_kbw_hero',
	'm_kbw_boss_flag',
	'ml_marker',
	'm_tower_buildup',
	'm_kbw_unit',
	'modifier_boss_duel',
	'modifier_boss_rangerdamage',
	'modifier_neutral_champion',
	'modifier_courier',
	'm_bosses_modifier',
	'm_custom_truesight',
	'm_kbw_endgame',
	'm_kbw_boss_healthbar',
	-- public
	'm_kbw_multicast',
	'm_kbw_kill_agility',
	'm_mag_attack',
	'm_kbw_cdr_stackable',
	'm_kbw_spell_lifesteal',
	'm_kbw_aura_movespeed_pct',
	'm_kbw_aura_regen_pct',
	'm_kbw_effect_duration',
	'm_kbw_base_agility',
	'm_kbw_cast_fly_movement',
	'm_kbw_bash_cd',
	'm_kbw_magic_damage_stun',
	'm_kbw_max_hp_regen',
	'm_kbw_max_mp_regen',
	'm_crit',
	'm_speed_pct',
	'm_kbw_no_speed_limit',
	'm_damage_pct',
	'm_evasion',
	'm_agility_pct',
	'm_rootcast',
	'm_disarm',
	'm_attack_speed_unlimited',
	'm_attack_heal_reduction',
	'm_kbw_attack_immune',
	'm_kbw_crit_cd',
	'm_kbw_ability_attack_damage',
	'm_kbw_freeze',
	'm_kbw_attack_cast',
	'm_kbw_multishot',
	'm_kbw_spell_damage_type',
	'm_kbw_respawn_reduction',
	'm_kbw_antistun',
	'm_kbw_break',
	'm_kbw_durty_vision',
	'm_kbw_cast_attack_range',
	'm_kbw_status_resist',
	'm_kbw_invuln',
	'm_kbw_true_strike',
	'm_kbw_spell_immune_block',
	'm_kbw_attack_mag_weakness',
	'm_kbw_min_health',
	'm_kbw_no_damage',
	'm_kbw_attack_range_melee',
	'm_kbw_no_castpoint',
	'm_kbw_visible',
}

for _, sModifier in ipairs(aModifiers) do
	LinkLuaModifier( sModifier, 'modifiers/'..sModifier, LUA_MODIFIER_MOTION_NONE )
end

function Activate()
	GameRules.LiA = LiA()
	GameRules.LiA:InitGameMode()
	GameRules.spawn_points = Entities:FindAllByName("angel_spawn_point")
	Events:Trigger( 'Activate' )
	
end

function Precache( context )
		PrecacheResource("particle","particles/black_screen.vpcf", context)

		PrecacheModel("models/creeps/lane_creeps/creep_dire_hulk/creep_dire_diretide_ancient_hulk.vmdl", context)
		PrecacheModel("models/creeps/lane_creeps/creep_radiant_hulk/creep_radiant_diretide_ancient_hulk.vmdl", context)

		--Неоригинальные модели крипов
		PrecacheModel("models/creeps/thief/thief_01_leader.vmdl", context)
		PrecacheModel("models/creeps/thief/thief_01.vmdl", context)
		PrecacheResource("soundfile", "soundevents/game_sounds_birzha_new.vsndevts", context) 
		PrecacheLoad:PrecacheLoad (context)

		GameRules.isTesting = false
		GameRules.server =  "https://tve3.us/hungry/"  -- "https://localhost:5001/hungry/" -- 

		GameRules.Bonus = {}
		GameRules.PartDefaults = {}
		GameRules.PetsDefaults = {}
		GameRules.scores = {} 
		GameRules.BonusPercent = 0
		GameRules.PlayersCount = 0
		GameRules.Score = {}
		GameRules.MapLVL = tonumber(string.match(GetMapName(),"%d+")) or 10
		GameRules.checkResult = {}
		GameRules.Mute = {}
end