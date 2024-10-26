return {
	FOUNTAIN_17_3 = 'particles/econ/events/winter_major_2017/radiant_fountain_regen_wm07_lvl3.vpcf',
	FOUNTAIN_18_3 = 'particles/econ/events/ti8/fountain_regen_ti8_lvl3.vpcf',
	GRASS = {
		Name = 'particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_3.vpcf',
		ControlPoints = {
			[0] = 'attach_eye_l'
		}
	},
	
	TI7 = 'particles/pass/ti7.vpcf',
	
	MUSHROOM = 'particles/pass/toxic_mushroom.vpcf',
	
	FOUNTAIN_9 = 'particles/econ/events/ti9/fountain_regen_ti9_lvl3.vpcf',
	
	BOTTLE_TI9 = 'particles/econ/events/ti9/bottle_ti9.vpcf',
	
	TI9_WOUNDS = 'particles/econ/items/lifestealer/ls_ti9_immortal/ls_ti9_open_wounds.vpcf',
	
	TI8 = 'particles/econ/events/ti8/ti8_hero_effect.vpcf',
	
	RAINB = 'particles/rainbow.vpcf',
	
	GOB = 'particles/gob/gob_effect.vpcf',
	
	SUMMER_2021 = 'particles/econ/events/summer_2021/summer_2021_emblem_effect.vpcf',
	
	BOUNTY = {
		'particles/sponsor/sponsor_effect.vpcf',
		'particles/sponsor/templar_assassin_refraction.vpcf'
	},
	DARK_WINGS = {
		'particles/world_environmental_fx/rune_ambient_01_smoke.vpcf',
		{
			Name = 'particles/econ/items/juggernaut/jugg_fortunes_tout/jugg_healling_ward_fortunes_tout_ward_edge_glow.vpcf',
			ControlPoints = {
				[0] = true
			}
		},
		{
			Name = 'particles/econ/items/skywrath_mage/hero_skywrath_dpits3_wings/skywrath_dpits3_backwing_p.vpcf',
			WorldAttach = true,
			DeathTime = 1,
			ControlPoints = {
				[0] = {
					Attach = true,
					Forward = 90
				}
			},
		}
	},
	GOLD_WINGS = {
		'particles/pass/golden_wings/golden_wings_ambient.vpcf',
		{
			Name = 'particles/pass/golden_wings/golden_wings.vpcf',
			WorldAttach = true,
			DeathTime = 1,
			ControlPoints = {
				[0] = {
					Attach = true,
					Forward = 90
				},
				[13] = Vector( 0.5, 1, 2.5 )
			},
		}
	},
	FIRE_HANDS = {
		Name = 'particles/econ/items/warlock/warlock_hellsworn_construct/golem_hellsworn_ambient_hands.vpcf',
		ControlPoints = {
			[0] = true,
			[10] = 'attach_attack1',
			[11] = 'attach_attack2'
		}
	},
	EXCLUSIVE_1 = {
		Name = 'particles/particles/econ/rich.vpcf',
		ControlPoints = {
			[0] = PATTACH_OVERHEAD_FOLLOW,
		}
	}
}