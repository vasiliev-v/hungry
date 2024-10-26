modifier_torture_pipe_buff = class({})

function modifier_torture_pipe_buff:IsHidden()
	return true
end

function modifier_torture_pipe_buff:IsPermanent()
	return true
end

function modifier_torture_pipe_buff:IsPurgable()
	return false
end

function modifier_torture_pipe_buff:OnCreated()
	RegisterSpecialValuesModifier(self)

	self.parent = self:GetParent()
end

function modifier_torture_pipe_buff:CacheDOTBoost()
	if not self.parent or self.parent:IsNull() then return end
	
	local boost = 0
	local modifier_list = self.parent:FindAllModifiers()
	for _, modifier in pairs(modifier_list) do
		local item = modifier:GetAbility()
		if item and not item:IsNull() then
			boost = math.max(boost, item:GetSpecialValueFor("torture_pipe_dot_boost"))
		end
	end

	for ability_name, _ in pairs(self.reapply_modifiers) do
		local ability = self.parent:FindAbilityByName(ability_name)
		if ability and not ability:IsNull() and ability.OnUpgrade then
			ability:OnUpgrade()
			-- OnUpgrade works, but not if ability is maxed out, have to reapply modifier with changed values
			local intrinsic = ability:GetIntrinsicModifierName()
			if intrinsic then
				local modifier = self.parent:FindModifierByName(intrinsic)
				if modifier and not modifier:IsNull() then 
					local duration = modifier:GetDuration()
					local fields = table.deepcopy(self.whitelist[ability_name])
					for name, _ in pairs(fields) do
						fields[name] = ability:GetSpecialValueFor(name)
					end
					fields["duration"] = duration
					modifier:Destroy() 
					Timers:CreateTimer(0, function()
						self.parent:AddNewModifier(self.parent, ability, intrinsic, fields)
					end)
				end
			end
		end
	end

	self:SetStackCount(boost)
end

function modifier_torture_pipe_buff:GetAbilitySpecialValueMultiplier(keys)
	if keys.ability and self.whitelist and self.whitelist[keys.ability:GetAbilityName()] and self.whitelist[keys.ability:GetAbilityName()][keys.ability_special_value] then
		return 0.01 * self:GetStackCount()
	end

	return 0
end

modifier_torture_pipe_buff.whitelist = {
	alchemist_acid_spray 				= {damage = true},
	silencer_curse_of_the_silent 		= {damage = true},										special_bonus_unique_silencer			= {value = true},
	tiny_avalanche 						= {avalanche_damage = true},							special_bonus_unique_tiny				= {value = true},
	rattletrap_battery_assault			= {damage = true},										special_bonus_unique_clockwerk_3		= {value = true},
	axe_battle_hunger					= {damage_per_second = true}, 							special_bonus_unique_axe				= {value = true},
	enigma_black_hole					= {damage = true},
	juggernaut_blade_fury				= {blade_fury_damage = true}, 							special_bonus_unique_juggernaut_3 		= {value = true},
	dark_willow_bramble_maze			= {latch_damage = true},
	huskar_burning_spear_lua			= {burn_damage = true},									special_bonus_unique_huskar_2			= {value = true},
	dawnbreaker_celestial_hammer		= {burn_damage = true},
	invoker_chaos_meteor_ad				= {burn_dps = true},
	brewmaster_cinder_brew				= {total_damage = true},
	ancient_apparition_cold_feet		= {damage = true},
	viper_corrosive_skin				= {damage = true},
	slark_dark_pact						= {total_damage = true},								special_bonus_unique_slark_2			= {value = true},
	pudge_dismember						= {dismember_damage = true, strength_damage = true},
	doom_bringer_doom					= {damage = true},										special_bonus_unique_doom_5				= {value = true},
	jakiro_dual_breath					= {burn_damage = true},
	dragon_knight_elder_dragon_form_lua	= {corrosive_breath_damage = true},
	sandking_epicenter					= {epicenter_damage = true},							special_bonus_unique_sand_king_5		= {value = true},
	phoenix_fire_spirits				= {damage_per_second = true},							special_bonus_unique_phoenix_3			= {value = true},
	bane_fiends_grip_lua				= {fiend_grip_damage = true},
	ember_spirit_flame_guard			= {damage_per_second = true},							special_bonus_unique_ember_spirit_3		= {value = true},
	batrider_firefly					= {damage_per_second = true},
	dragon_knight_fireball				= {damage = true},
	batrider_flamebreak					= {damage_per_second = true},
	shredder_flamethrower				= {damage_per_second = true},
	batrider_flaming_lasso				= {damage = true},
	arc_warden_flux						= {damage_per_second = true},
	crystal_maiden_freezing_field		= {damage = true},										special_bonus_unique_crystal_maiden_3	= {value = true},
	lich_frost_shield					= {damage = true},
	crystal_maiden_frostbite			= {damage_per_second = true, creep_damage_per_second = true},
	phoenix_icarus_dive					= {damage_per_second = true},
	ancient_apparition_ice_blast_lua	= {dot_damage = true},
	invoker_ice_wall_ad					= {damage_per_second = true},
	ogre_magi_ignite					= {burn_damage = true},									special_bonus_unique_ogre_magi_4		= {value = true},
	grimstroke_spirit_walk_lua			= {damage_per_tick = true, tick_dps_tooltip = true},
	dark_seer_ion_shell					= {damage_per_second = true},							special_bonus_unique_dark_seer			= {value = true},
	treant_leech_seed					= {leech_damage = true},								special_bonus_unique_treant_2			= {value = true},
	pugna_life_drain					= {health_drain = true, scepter_health_drain = true},
	jakiro_liquid_fire					= {damage = true},										special_bonus_unique_jakiro_8			= {value = true},
	jakiro_macropyre					= {damage = true},										special_bonus_unique_jakiro_7			= {value = true},
	earth_spirit_magnetize				= {damage_per_second = true},
	enigma_malefice						= {damage = true},										special_bonus_unique_enigma_5			= {value = true},
	snapfire_mortimer_kisses			= {burn_damage = true},
	skywrath_mage_mystic_flare			= {damage = true},										special_bonus_unique_skywrath_5			= {value = true},
	treant_natures_grasp				= {damage_per_second = true},							special_bonus_unique_treant_9			= {value = true},
	viper_nethertoxin					= {min_damage = true, max_damage = true},
	treant_overgrowth					= {damage = true},										special_bonus_unique_treant_11			= {value = true},
	grimstroke_ink_creature				= {damage_per_tick = true, dps_tooltip = true},			special_bonus_unique_grimstroke_8		= {value = true},
	viper_poison_attack					= {damage = true},
	venomancer_poison_nova				= {base_damage = true},
	venomancer_poison_sting				= {damage = true},
	dazzle_poison_touch					= {damage = true},										special_bonus_unique_dazzle_3			= {value = true},
	templar_assassin_psionic_trap		= {trap_bonus_damage = true},							special_bonus_unique_templar_assassin_3	= {value = true},
	leshrac_pulse_nova					= {damage = true},										special_bonus_unique_leshrac_3			= {value = true},
	gyrocopter_rocket_barrage			= {rocket_damage = true},								special_bonus_unique_gyrocopter_3		= {value = true},
	pudge_rot							= {rot_damage = true, scepter_rot_damage_bonus = true},	special_bonus_unique_pudge_2			= {value = true},
	sandking_sand_storm					= {sand_storm_damage = true},							special_bonus_unique_sand_king_2		= {value = true},
	doom_bringer_scorched_earth			= {damage_per_second = true},							special_bonus_unique_doom_4				= {value = true},
	ember_spirit_searing_chains			= {total_damage = true},
	shadow_shaman_shackles_lua			= {total_damage = true},								special_bonus_unique_shadow_shaman_6	= {value = true},
	queenofpain_shadow_strike			= {duration_damage = true},
	warlock_shadow_word					= {damage = true},										special_bonus_unique_warlock_7			= {value = true},
	sniper_shrapnel						= {shrapnel_damage = true},								special_bonus_unique_sniper_1			= {value = true},
	dawnbreaker_solar_guardian			= {base_damage = true},
	disruptor_static_storm				= {damage_max = true},
	disruptor_thunder_strike			= {strike_damage = true},								special_bonus_unique_disruptor_3		= {value = true},
	faceless_void_time_dilation			= {damage_per_stack = true},
	kunkka_torrent						= {torrent_damage = true},								special_bonus_unique_kunkka_2			= {value = true},
	venomancer_venomous_gale_lua		= {tick_damage = true},
	viper_viper_strike					= {damage = true},										special_bonus_unique_viper_2			= {value = true},
	skeleton_king_hellfire_blast		= {blast_dot_damage = true},							special_bonus_unique_wraith_king_3		= {value = true},
	timbersaw_chakram_lua				= {damage_per_second = true},
	timbersaw_chakram_2_lua				= {damage_per_second = true},
	leshrac_diabolic_edict				= {num_explosions = true},								special_bonus_unique_leshrac_1			= {value = true},	
	ancient_apparition_ice_vortex		= {vortex_shard_dps = true},
	bane_nightmare						= {nightmare_tick_damage = true},
	doom_bringer_infernal_blade			= {burn_damage = true},
	razor_eye_of_the_storm				= {damage = true},
	abyssal_underlord_firestorm			= {wave_damage = true},
	death_prophet_spirit_siphon			= {damage = true},
	witch_doctor_voodoo_restoration_lua	= {damage = true},
	luna_eclipse_lua					= {damage = true},										special_bonus_unique_luna_1				= {value = true},
	beastmaster_drums_of_slom			= {base_damage = true},
	warlock_upheaval					= {damage_per_second = true, max_damage = true},
	item_witch_blade					= {int_damage_multiplier = true},
	item_orb_of_venom					= {poison_damage_melee = true, poison_damage_range = true},
	item_orb_of_corrosion				= {damage = true},
	item_meteor_hammer					= {burn_dps_units = true, burn_dps_buildings = true},
	item_dragon_scale					= {damage_per_sec = true},
	item_paintball						= {dps = true},
	item_cloak_of_flames				= {damage = true, damage_illusions = true},
	item_stormcrafter					= {damage = true},
	item_turbulent_sturmaz				= {damage = true},
	item_fallen_sky						= {burn_dps_units = true, burn_dps_buildings = true},
	item_teleports_behind_you			= {meteor_burn_dps = true},
	item_revenants_brooch 				= {int_damage_multiplier = true},
	item_radiance						= {aura_damage = true, aura_damage_illusions = true},
	item_luminance 						= {aura_damage = true},
}


modifier_torture_pipe_buff.reapply_modifiers = {
	venomancer_poison_sting = true,
}

function RegisterSpecialValuesModifier(modifier)
    local parent = modifier:GetParent()

    parent.special_values_modifiers = parent.special_values_modifiers or {}
    table.insert(parent.special_values_modifiers, modifier)
end