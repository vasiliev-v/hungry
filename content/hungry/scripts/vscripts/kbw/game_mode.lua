-- require 'lib/lua/base'

GameModeKBW = GameModeKBW or class( {}, {}, GameModeBase )


function GameModeKBW:PreInit()
	self:SetRoot('kbw')

	require 'lib/kv'
	require 'lib/gentable'
	require 'lib/special_modifier'
	self:Require('api_fix')
	self:Require('value_modifier')
	self:Require('util_spell')
	self:Require('util_c')
	self:Require('const')
	require('kbw/items/generic_modifiers/require')
end

function GameModeKBW:InitClient()
	self:ListenToGameEventUnique( 'lua_client_run_url', function( tEvent )
		if tEvent.player == GetLocalPlayerID() then
			self:RunUrl( tEvent.url )
		end
	end )
end

function GameModeKBW:Init()
	require 'kbw/err'
end

function GameModeKBW:Preload()
	require 'lib/gameplay_event_tracker/init'
	require 'lib/modifier_self_events'
	require 'lib/modifier'
	require 'lib/finder'
	require 'lib/m_mult'
	require 'lib/particle_manager'
	require 'lib/spell_caster'
	require 'lib/relations'
	require 'lib/player_resource'
	require 'lib/filters'
	require 'lib/timer'
	require('runes')
	self.tPlayers = {}

	self:Require('util')
end

function GameModeKBW:Activate()
	require 'extern/utils'
	require 'extern/console/init'

	self:Preload()

	self:Load()
end

function GameModeKBW:Reload()
	self:Require('const')
	self:Require('util_spell')

	if Events:WasCalled('Activate') then
		self:Preload()
		self:Load()
	end
end

function GameModeKBW:Load()
	self:Require('console')
	self:Require('core/init')
	self:Require('listeners')
	self:Require('filters')
	self:Require('balance/init')
	self:Require('special_fixes')
	self:Require('control_point')

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
		LinkLuaModifier( sModifier, self:Path('modifiers/'..sModifier), LUA_MODIFIER_MOTION_NONE )
	end
end