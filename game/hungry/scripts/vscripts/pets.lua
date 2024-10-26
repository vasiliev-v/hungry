Pets = Pets or {
	playerPets = {}
}

-- function Pets:Precache( context )
-- 	print( "Pets precache start" )

-- 	for _, effect in pairs( self.heroEffects ) do
-- 		if effect.resource then
-- 			PrecacheResource( "particle_folder", effect.resource, context )
-- 		end
-- 	end

-- 	for _, p in pairs( self.petsData.particles ) do
-- 		PrecacheResource( "particle", p.particle, context )
-- 	end

-- 	for _, c in pairs( self.petsData.couriers ) do
-- 		PrecacheModel( c.model, context )

-- 		for _, p in pairs( c.particles ) do
-- 			if type( p ) == "string" then
-- 				PrecacheResource( "particle", p, context )
-- 			end
-- 		end
-- 	end

-- 	print( "Pets precache end" )
-- end

function Pets:Init()
	LinkLuaModifier( "modifier_cosmetic_pet", "modifiers/modifier_cosmetic_pet", LUA_MODIFIER_MOTION_NONE )
	-- LinkLuaModifier( "modifier_cosmetic_pet_invisible", "modifiers/modifier_cosmetic_pet_invisible", LUA_MODIFIER_MOTION_NONE )

	-- RegisterCustomEventListener( "cosmetics_select_pet", Dynamic_Wrap( self, "CreatePet" ) )
	-- RegisterCustomEventListener( "cosmetics_remove_pet", Dynamic_Wrap( self, "DeletePet" ) )

	GameRules:GetGameModeEntity():SetContextThink( "pets_think", function()
		self:OnThink()

		return  0.1
	end, 0.4 )
	end

-- local function HidePet( pet, time )
-- 	pet:AddNoDraw()
-- 	pet.isHidden = true
-- 	pet.unhideTime = GameRules:GetDOTATime( false, false ) + time

-- 	local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
-- 	ParticleManager:SetParticleControl( particle, 0, pet:GetAbsOrigin() )
-- 	ParticleManager:ReleaseParticleIndex( particle )
-- end

-- local function UnhidePet( pet )
-- 	pet:RemoveNoDraw()
-- 	pet.isHidden = false

-- 	local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
-- 	ParticleManager:SetParticleControl( particle, 0, pet:GetAbsOrigin() )
-- 	ParticleManager:ReleaseParticleIndex( particle )
-- end

function Pets:OnThink()
	for _, pet in pairs( Pets.playerPets ) do
		local owner = pet:GetOwner()
		local owner_pos = owner:GetAbsOrigin()
		local pet_pos = pet:GetAbsOrigin()
		local distance = ( owner_pos - pet_pos ):Length2D()
		local owner_dir = owner:GetForwardVector()
		local dir = owner_dir * RandomInt( 110, 140 )

		-- if owner:IsInvisible() and not pet:HasModifier( "modifier_cosmetic_pet_invisible" ) then
		-- 	pet:AddNewModifier( pet, nil, "modifier_cosmetic_pet_invisible", {} )
		-- elseif not owner:IsInvisible() and pet:HasModifier( "modifier_cosmetic_pet_invisible" ) then
		-- 	pet:RemoveModifierByName( "modifier_cosmetic_pet_invisible" )
		-- end

		-- local enemy_dis
		-- local near = FindUnitsInRadius(
		-- 	owner:GetTeam(),
		-- 	pet:GetAbsOrigin(),
		-- 	nil,
		-- 	300,
		-- 	DOTA_UNIT_TARGET_TEAM_ENEMY,
		-- 	DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		-- 	DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		-- 	FIND_CLOSEST,
		-- 	false
		-- )[1]

		-- if near then
		-- 	enemy_dis = ( near:GetAbsOrigin() - pet_pos ):Length2D()
		-- end

		if distance > 900 then
			-- if not pet.isHidden then
			-- 	HidePet( pet, 0.35 )
			-- end

			local a = RandomInt( 60, 120 )

			if RandomInt( 1, 2 ) == 1 then
				a = a * -1
			end

			local r = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, a, 0 ), dir )

			pet:SetAbsOrigin( owner_pos + r )
			pet:SetForwardVector( owner_dir )

			FindClearSpaceForUnit( pet, owner_pos + r, true )
		elseif distance > 150 then
			local right = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ) * -1, 0 ), dir ) + owner_pos
			local left = RotatePosition( Vector( 0, 0, 0 ), QAngle( 0, RandomInt( 70, 110 ), 0 ), dir ) + owner_pos

			-- if enemy_dis and enemy_dis < 300 and distance < 400 then
			-- 	pet:Stop()
			-- else
				if ( pet_pos - right ):Length2D() > ( pet_pos - left ):Length2D() then
					pet:MoveToPosition( left )
				else
					pet:MoveToPosition( right )
				end
			-- end
		elseif distance < 90 then
			pet:MoveToPosition( owner_pos + ( pet_pos - owner_pos ):Normalized() * RandomInt( 110, 140 ) )
		-- elseif near and ( near:GetAbsOrigin() - pet_pos ):Length2D() < 110 then
		-- 	pet:MoveToPosition( pet_pos + ( pet_pos - near:GetAbsOrigin() ):Normalized() * RandomInt( 100, 150 ) )
		end
		if owner:IsInvisible() then
            pet:AddNewModifier(pet,nil,"modifier_invisible",{})
		elseif pet:HasModifier("modifier_invisible") then
			pet:RemoveModifierByName("modifier_invisible")
		end
	end
end

function Pets.CreatePet( keys, num )
	local id = keys.PlayerID
	-- local old_pet = Pets.playerPets[id]
	-- local old_pet_pos
	-- local old_pet_dir
	local hero = keys.hero--PlayerResource:GetSelectedHeroEntity(id)--PlayerResource:GetPlayer( id ):GetAssignedHero()
	local model = ""
	local effect = ""
	local matGrp = "0"
	local roll_chance = RandomInt(0, 1)
	-- if old_pet then
	-- 	old_pet_pos = old_pet.unit:GetAbsOrigin()
	-- 	old_pet_dir = old_pet.unit:GetForwardVector()

	-- 	old_pet.unit:Destroy()
	-- end


	-- UnhidePet( pet )
	--local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_monkey_king/monkey_king_disguise_smoke_top.vpcf", PATTACH_WORLDORIGIN, nil )
	--ParticleManager:SetParticleControl( particle, 0, pet:GetAbsOrigin() )
	--ParticleManager:ReleaseParticleIndex( particle )


	--[[

	]]
	if num == "1" then
		model = "models/courier/baby_rosh/babyroshan_ti10_dire.vmdl" -- Baby Roshan  autumn
		effect = "particles/econ/courier/courier_trail_hw_2013/courier_trail_hw_2013.vpcf"
	elseif num == "2" then
		model = "models/courier/baby_rosh/babyroshan_elemental.vmdl" -- winter Roshan 
		effect = "particles/my_new/ambientfx_effigy_wm16_radiant_lvl3.vpcf"
		matGrp = "2"
	elseif num == "3" then
		model = "models/courier/baby_rosh/babyroshan.vmdl" -- spring Roshan
		effect = "particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8_flying.vpcf"
		matGrp = "5"
	elseif num == "4" then
		model = "models/courier/baby_rosh/babyroshan_elemental.vmdl" --  summer
		effect = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
		matGrp = "1"
	elseif num == "5" then
		model = "models/items/courier/butch_pudge_dog/butch_pudge_dog.vmdl" -- Butch
		effect = "particles/econ/courier/courier_butch/courier_butch_ambient.vpcf"
	elseif num == "6" then
		model = "models/courier/doom_demihero_courier/doom_demihero_courier.vmdl" -- Golden Doomling
		effect = "particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf"
	elseif num == "7" then
		model = "models/courier/huntling/huntling.vmdl" -- Golden Huntling
		effect = "particles/econ/courier/courier_huntling_gold/courier_huntling_gold_ambient.vpcf"
	elseif num == "8" then
		model = "models/items/courier/krobeling_gold/krobeling_gold.vmdl" -- Golden Krobeling
		effect = "particles/econ/courier/courier_krobeling_gold/courier_krobeling_gold_ambient.vpcf"
	elseif num == "9" then
		model = "models/courier/venoling/venoling.vmdl" -- Golden Venoling
		effect = "particles/econ/courier/courier_venoling_gold/courier_venoling_ambient_gold.vpcf"
	elseif num == "10" then
		model = "models/courier/beetlejaws/mesh/beetlejaws.vmdl" -- Beetlejaws 
		effect = "particles/econ/courier/courier_beetlejaw_gold/courier_beetlejaw_gold_ambient.vpcf"
	elseif num == "11" then
		model = "models/items/courier/courier_ti9/courier_ti9_lvl7/courier_ti9_lvl7.vmdl" -- Autumn Winner
		effect = "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf"
	elseif num == "12" then
		model = "models/items/courier/duskie/duskie.vmdl" -- Winter Winner
		effect = "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_ice.vpcf"
	elseif num == "13" then
		model = "models/items/courier/little_sapplingnew_bloom_style/little_sapplingnew_bloom_style.vmdl" -- Spring Winner
		effect = "particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_3.vpcf"
	elseif num == "14" then
		model = "models/items/courier/chocobo/chocobo.vmdl" -- Summer Winner
		effect = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
	elseif num == "15" then
		model = "models/items/courier/faceless_rex/faceless_rex.vmdl" -- discord
		effect = "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf"
	elseif num == "16" then
		model = "models/items/courier/courier_ti10_radiant/courier_ti10_radiant_lvl4/courier_ti10_radiant_lvl4.vmdl" -- discord
		effect = "particles/econ/courier/courier_ti10/courier_ti10_lvl4_ambient.vpcf"
	
	elseif num == "17" then
		model = "models/items/courier/starladder_grillhound/starladder_grillhound.vmdl" -- helheim
		effect = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
	elseif num == "18" then
		model = "models/items/courier/virtus_werebear_t2/virtus_werebear_t2.vmdl" -- virtus_1
	elseif num == "19" then
		model = "models/items/courier/virtus_werebear_t3/virtus_werebear_t3.vmdl" -- virus_2
	elseif num == "20" then
		model = "models/items/courier/raiq/raiq.vmdl" -- raiq птица
	elseif num == "21" then
		model = "models/items/courier/green_jade_dragon/green_jade_dragon.vmdl" -- green_jade_dragon дракон
	elseif num == "22" then
		model = "models/items/courier/bajie_pig/bajie_pig.vmdl" -- свинья топ
		matGrp = "1"
	elseif num == "23" then
		model = "models/items/courier/baekho/baekho.vmdl" -- львица
	elseif num == "24" then
		model = "models/items/courier/scuttling_scotty_penguin/scuttling_scotty_penguin.vmdl" -- пингвин
	elseif num == "25" then
		model = "models/items/courier/captain_bamboo/captain_bamboo.vmdl" -- панда
	elseif num == "26" then
		model = "models/items/courier/livery_llama_courier/livery_llama_courier.vmdl" -- лама
	elseif num == "27" then
		model = "models/courier/seekling/seekling.vmdl" -- блудсикер
	elseif num == "28" then
		if roll_chance == 1 then 
			model = "models/items/courier/guardians_of_justice_enix/guardians_of_justice_enix.vmdl" -- волк1
		else
			model = "models/items/courier/guardians_of_justice_phoe/guardians_of_justice_phoe.vmdl" -- волк2
		end
	elseif num == "29" then
		model = "models/items/courier/lilnova/lilnova.vmdl" -- луна
	elseif num == "30" then
		model = "models/items/courier/supernova_rave_courier/supernova_rave_courier.vmdl" -- супер луна
	elseif num == "31" then
		model = "models/items/courier/mei_nei_rabbit/mei_nei_rabbit.vmdl" -- кролик
	elseif num == "32" then
		if roll_chance == 1 then 
			model = "models/items/courier/jin_yin_white_fox/jin_yin_white_fox.vmdl" -- мега лиса 1
		else
			model = "models/items/courier/jin_yin_black_fox/jin_yin_black_fox.vmdl" -- мега лиса 2
		end
	elseif num == "33" then
		model = "models/props_gameplay/pig.vmdl" -- pig

	elseif num == "34" then
		if roll_chance == 1 then 
			model = "models/items/courier/jumo/jumo.vmdl" -- мега девочка 1
		else
			model = "models/items/courier/jumo_dire/jumo_dire.vmdl" -- мега девочка 2
		end
	elseif num == "35" then
		model = "models/items/courier/snaggletooth_red_panda/snaggletooth_red_panda.vmdl" -- panda
		if roll_chance == 1 then 
			matGrp = "1" -- мега panda 1
		else
			matGrp = "2" -- мега panda 2
		end
	elseif num == "36" then
		model = "models/items/courier/el_gato_beyond_the_summit/el_gato_beyond_the_summit.vmdl" -- cat
	elseif num == "37" then
		model = "models/items/courier/hermid/hermid.vmdl" -- crab
	elseif num == "38" then
		model = "models/items/courier/nilbog/nilbog.vmdl" -- pig
	elseif num == "39" then
		model = "models/items/courier/royal_griffin_cub/royal_griffin_cub.vmdl" -- griffin
	elseif num == "40" then
		model = "models/items/courier/blotto_and_stick/blotto.vmdl" -- мужик
	elseif num == "41" then
		model = "models/courier/skippy_parrot/skippy_parrot.vmdl" -- папугай
	elseif num == "42" then
		model = "models/courier/drodo/drodo.vmdl" -- черт дракон
	elseif num == "43" then
		model = "models/courier/otter_dragon/otter_dragon.vmdl" -- минидракон
	elseif num == "44" then
		model = "models/items/courier/pangolier_squire/pangolier_squire.vmdl" -- енот
	elseif num == "45" then
		model = "models/courier/navi_courier/navi_courier.vmdl" -- нави

	elseif num == "46" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv1.vmdl" -- hand_courier lvl 1
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv1.vmdl" -- hand_courier lvl 1
		end
	elseif num == "47" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv2.vmdl" -- hand_courier lvl 2
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv2.vmdl" -- hand_courier lvl 2
		end
	elseif num == "48" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv3.vmdl" -- hand_courier lvl 3
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv3.vmdl" -- hand_courier lvl 3
		end
	elseif num == "49" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv4.vmdl" -- hand_courier lvl 4
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv4.vmdl" -- hand_courier lvl 4
		end
	elseif num == "50" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv5.vmdl" -- hand_courier lvl 5
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv5.vmdl" -- hand_courier lvl 5
		end
	elseif num == "51" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv6.vmdl" -- hand_courier lvl 6
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv6.vmdl" -- hand_courier lvl 6
		end
	elseif num == "52" then
		if roll_chance == 1 then 
			model = "models/items/courier/hand_courier/hand_courier_radiant_lv7.vmdl" -- hand_courier lvl 7
		else
			model = "models/items/courier/hand_courier/hand_courier_dire_lv7.vmdl" -- hand_courier lvl 7
		end
	elseif num == "53" then
		model = "models/items/courier/boooofus_courier/boooofus_courier.vmdl" -- 
	elseif num == "54" then
		model = "models/courier/aghanim_courier/aghanim_courier.vmdl" -- 
	elseif num == "55" then
		if roll_chance == 1 then 
			model = "models/items/courier/vigilante_fox_green/vigilante_fox_green.vmdl" -- 
		else
			model = "models/items/courier/vigilante_fox_red/vigilante_fox_red.vmdl" -- 
		end
	elseif num == "56" then
		if roll_chance == 1 then 
			model = "models/courier/winter2022/taffy_donkey_courier.vmdl" -- 
		else
			model = "models/courier/winter2022/cotton_donkey_courier.vmdl" -- 
		end
	elseif num == "57" then
		model = "models/items/courier/gnomepig/gnomepig.vmdl" -- 
	elseif num == "58" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv1.vmdl" -- 
	elseif num == "59" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv2.vmdl" -- 
	elseif num == "60" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv3.vmdl" -- 
	elseif num == "61" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv4.vmdl" -- 
	elseif num == "62" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv5.vmdl" -- 
	elseif num == "63" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv6.vmdl" -- 
	elseif num == "64" then
		model = "models/items/courier/hamster_courier/hamster_courier_lv7.vmdl" -- 
	elseif num == "65" then
		model = "models/items/courier/deathbringer/deathbringer.vmdl" -- 
		effect = "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_spray_initial.vpcf"
	elseif num == "66" then
		model = "models/items/courier/grim_wolf_radiant/grim_wolf_radiant.vmdl" -- 
		
	end 
	
	if model ~= "" then
		local pet = CreateUnitByName( "npc_cosmetic_pet", hero:GetAbsOrigin() + RandomVector( RandomInt( 6000, 8000 ) ), true, hero, hero, hero:GetTeam() )
		pet:SetForwardVector( hero:GetAbsOrigin() )
		pet:AddNewModifier( pet, nil, "modifier_cosmetic_pet", {} )
		
		pet:SetModel( model )
		pet:SetOriginalModel( model )
		pet:SetModelScale(1.1)
		Pets.playerPets[id] = pet
		pet:SetMaterialGroup(matGrp)--tostring( pet_data.skin ) )
		if effect ~= "" then
			ParticleManager:CreateParticle(effect, PATTACH_POINT_FOLLOW, pet )
		end
	end
end

function Pets.DeletePet( keys )
 	local id = keys.PlayerID

 	if not Pets.playerPets[id] then
 		return
	end

 	--HidePet( Pets.playerPets[id].unit, 0 )
	UTIL_Remove(Pets.playerPets[id])
	Pets.playerPets[id] = nil
end