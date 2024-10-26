return {
	ARMADILLO = {
		Model = 'models/pets/armadillo/armadillo.vmdl'
	},
	PUDGE_DOG = {
		Model = 'models/items/courier/butch_pudge_dog/butch_pudge_dog_flying.vmdl',
		ModelScale = 1.6,
		SpeedBonus = 200,
		MaxDistance = 600,
		Flying = true
	},
	ICE_WOLF = {
		Model = 'models/pets/icewrack_wolf/icewrack_wolf.vmdl',
		Particle = 'particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_arcana_ground_ambient.vpcf'
	},
	BABYROSH_DESERT = {
		Model = 'models/courier/baby_rosh/babyroshan.vmdl',
		Material = '4',
		ModelScale = 0.8,
		Particle = {
			Name = 'particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf',
			ControlPoints = {
				[0] = 'attach_eye_l'
			}
		}
	},
	BABYROSH_JADE = {
		Model = 'models/courier/baby_rosh/babyroshan.vmdl',
		Material = '5',
		ModelScale = 0.8,
		Particle = {
			Name = 'particles/econ/items/effigies/status_fx_effigies/jade_effigy_ambient_dire.vpcf',
			ControlPoints = {
				[0] = 'attach_eye_l'
			}
		}
	},	
	BABYROSH_DARK_MOON = {
		Model = 'models/courier/baby_rosh/babyroshan.vmdl',
		Material = '3',
		ModelScale = 0.8,
		Particle = {
			Name = 'particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf',
			ControlPoints = {
				[0] = 'attach_eye_l'
			}
		}
	},		
	BABYROSH_LAVA = {
		Model = 'models/courier/baby_rosh/babyroshan_elemental.vmdl',
		Material = '1',
		ModelScale = 0.8,
		Particle = {
			Name = 'particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf',
			ControlPoints = {
				[0] = 'attach_eye_l'
			}
		}
	},
	BABYROSH_WINTER18 = {
		Model = 'models/courier/baby_rosh/babyroshan_winter18.vmdl',
		Material = '1',
		ModelScale = 0.8,
		Particle = {
			Name = 'particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf',
			ControlPoints = {
				[0] = 'attach_eye_l'
			}
		}
	},		
	SPIDER_LYCOSIDAE = {
		Model = 'models/items/broodmother/spiderling/lycosidae_spiderling/lycosidae_spiderling.vmdl',
		Particle = {
			Name = 'particles/econ/items/luna/luna_ti9_weapon/luna_ti9_moon_glaive_model_glow.vpcf',
			ControlPoints = {
				[3] = true
			},
		},
		Vision = 50,
		ModelScale = 0.35,
		Pathing = true
	},
	TI10_RADIANT = {
		Model = 'models/items/courier/courier_ti10_radiant/courier_ti10_radiant_lvl5/courier_ti10_radiant_lvl5.vmdl',
	},	
	SAPPLING = {
		Model = 'models/items/courier/little_sapplingnew_bloom_style/little_sapplingnew_bloom_style.vmdl',
		Particle = {
			'particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient_bees.vpcf',
			'particles/econ/events/ti9/fountain_regen_ti9_lvl3.vpcf'
		}
	},
	BAJIE = {
		Model = 'models/items/courier/bajie_pig/bajie_pig.vmdl',
		Particle = {
			'particles/econ/courier/courier_bajie/courier_bajie.vpcf',
		}
	},	
	PANDA = {
		Model = 'models/items/lone_druid/viciouskraitpanda/viciouskrait_panda.vmdl',
		ModelScale = 0.8,
		SpeedBonus = 50,
	},
	PENGUIN = {
		Model = 'models/items/courier/scuttling_scotty_penguin/scuttling_scotty_penguin.vmdl',
	},
	HUNTLING = {
		Model = 'models/courier/huntling/huntling.vmdl',
	},
	HUNTLING_FLY = {
		Model = 'models/courier/huntling/huntling_flying.vmdl',
		SpeedBonus = 80,
		MaxDistance = 450,
		Flying = true
	},
	SEEKLING = {
		Model = 'models/courier/seekling/seekling.vmdl',
	},
	VENOLING = {
		Model = 'models/courier/venoling/venoling.vmdl',
	},
	DEVOLING = {
		Model = 'models/items/courier/devourling/devourling_flying.vmdl',
		Zoffset = 30
	},
	KROBLING = {
		Model = 'models/items/courier/krobeling/krobeling_flying.vmdl',
	},
	KROBLING_GOLD = {
		Model = 'models/items/courier/krobeling_gold/krobeling_gold_flying.vmdl',
	},
	DOOMLING = {
		Model = 'models/courier/doom_demihero_courier/doom_demihero_courier.vmdl',
	},
}