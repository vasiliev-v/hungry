if Runes == nil then
	_G.Runes = class({})
end

local runeTypes = {
	item_lia_rune_of_strength = 1,
	item_lia_rune_of_agility = 1,
	item_lia_rune_of_intellect = 1,
	item_lia_rune_gold = 1,
	item_lia_rune_of_knowledge = 1, 

	item_keen_optic = 2,
	item_royal_jelly = 2,
	item_ocean_heart = 2,
	item_broom_handle = 2,
	item_arcane_ring = 2,
	item_chipped_vest = 2,
	item_possessed_mask = 2,
	item_mysterious_hat = 2,
	item_unstable_wand = 2,
	item_pogo_stick = 2,
	item_seeds_of_serenity = 2,
	item_lance_of_pursuit = 2,
	item_faded_broach = 2,
	item_duelist_gloves = 2,
	item_spark_of_courage = 2,

	item_ring_of_aquila = 3,
	item_nether_shawl = 3,
	item_dragon_scale = 3,
	item_pupils_gift = 3,
	item_vambrace = 3,
	item_misericorde = 3,
	item_grove_bow = 3,
	item_philosophers_stone = 3,
	item_essence_ring = 3,
	item_dagger_of_ristul = 3,
	item_bullwhip = 3,
	item_quicksilver_amulet = 3,
	item_specialists_array = 3,
	item_eye_of_the_vizier = 3,
	item_gossamer_cape = 3,

	item_quickening_charm = 4,
	item_black_powder_bag = 4,
	item_spider_legs = 4,
	item_paladin_sword = 4,
	item_titan_sliver = 4,
	item_mind_breaker = 4,
	item_enchanted_quiver = 4,
	item_elven_tunic = 4,
	item_cloak_of_flames = 4,
	item_ceremonial_robe = 4,
	item_psychic_headband = 4,
	item_orb_of_destruction = 4,
	item_ogre_seal_totem = 4,
	item_defiant_shell = 4, 
	item_vindicators_axe = 4, 
	item_dandelion_amulet = 4,

	item_timeless_relic = 5,
	item_spell_prism = 5,
	item_ascetic_cap = 5,
	item_heavy_blade = 5,
	item_flicker = 5,
	item_ninja_gear = 5,
	item_illusionsts_cape = 5,
	item_havoc_hammer = 5,
	item_trickster_cloak = 5,
	item_stormcrafter = 5,
	item_penta_edged_sword = 5,
	item_martyrs_plate = 5,

	item_force_boots = 6,
	item_desolator_2 = 6,
	item_seer_stone = 6,
	--item_ballista = 6,
	item_apex = 6,
	item_fallen_sky = 6,
	item_force_field = 6,
	item_pirate_hat = 6,
	item_ex_machina = 6,
	item_book_of_shadows = 6,
	item_giants_ring = 6, 

}

local runeSpawnTime = 60 --период появления рун
local Q = 1
local vRuneSpawnMin = Vector(-80, -80, 0)
local vRuneSpawnMax = Vector(80, 80, 0)
local sortTable = {}
sortTable[0] = {}
--for k,v in pairs(runeTypes) do
--	runeTypes[k] = v
--end


function Runes:GetRandomRuneType()
	local f = math.ceil(GameRules:GetGameTime()/300)
	local i = 0
	for k,v in pairs(runeTypes) do
		-- sortTable[i] = {k, v }
		--print(k)
		--print(v)
		--print("----------")
		if v<=f then
			sortTable[i] = {k, v }
			i = i + 1
		end
	end
	--print(sortTable[RandomInt(0, #sortTable)][1])
	return sortTable[RandomInt(0, #sortTable)][1]
end

function Runes:GetRuneSpawnPos()
	if runeSpawnRegionType == "rectangle" then
		return Vector(RandomFloat(vRuneSpawnMin.x,vRuneSpawnMax.x), RandomFloat(vRuneSpawnMin.y,vRuneSpawnMax.y), 0)
	elseif runeSpawnRegionType == "circle" then
		return vRuneSpawnMin+RandomVector(RandomInt(0,16000))
	else
		return Vector(RandomFloat(vRuneSpawnMin.x,vRuneSpawnMax.x), RandomFloat(vRuneSpawnMin.y,vRuneSpawnMax.y), 0)
	end
end

function Runes:SpawnRune()
	local rune = CreateItem(Runes:GetRandomRuneType(), nil, nil)
	local drop = CreateItemOnPositionSync(Runes:GetRuneSpawnPos(), rune)
	local message = "#drop_center_item"
    GameRules:SendCustomMessage(message, 1, 1)
	fireLeftNotify(0, false, "#drop_center_item", {})
	for i = 0, 13 do
        MinimapEvent(i, nil, 0, 0, DOTA_MINIMAP_EVENT_HINT_LOCATION, 10 )
    end  
	rune:SetContextThink( "KillLoot", function() return KillLoot( rune, drop ) end, 300 )
	if Q == 5 then
		rune = CreateItem("item_rapier", nil, nil)
		drop = CreateItemOnPositionSync(Vector(0,0,0), rune)
		message = "#drop_center_item_rapier"
    	GameRules:SendCustomMessage(message, 1, 1)
		fireLeftNotify(0, false, "#drop_center_item_rapier", {})
		rune:SetContextThink( "KillLoot", function() return KillLoot( rune, drop ) end, 10 )
	end
end

function Runes:StartRunesSpawn()
	Timers:CreateTimer("LiAruneSpawner",
		{
            endTime = runeSpawnTime, 
            callback = function() 
            	Runes:SpawnRune() 
            	Q = Q + 1
            	if Q == 35 then 
            		return nil 
            	end
            	return runeSpawnTime 
            end
        }
    )
end

function Runes:StopRunesSpawn()
	Timers:RemoveTimer("LiAruneSpawner")
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


function Runes:StartOutPost()
	Timers:CreateTimer("LiAruneSpawner2",
		{
            endTime = runeSpawnTime, 
            callback = function() 
			local units = Entities:FindAllByClassname("npc_dota_watch_tower")
			for _,unit in pairs(units) do
				print(unit:GetUnitName())
				if unit:GetTeamNumber() ~= 5 then
					for pID = 0, DOTA_MAX_PLAYERS do
						if PlayerResource:IsValidPlayer(pID) then
							if PlayerResource:GetTeam(pID) == unit:GetTeamNumber() then
								local hero = PlayerResource:GetSelectedHeroEntity(pID)
								if hero then
									local valueGold = GOLD_OUTPOST_PER_MIN * math.ceil(GameRules:GetDOTATime(false, false)/60)
									hero:ModifyGold(valueGold, false, DOTA_ModifyGold_Unspecified)
									SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, hero, valueGold, nil )
									local valueXP = XP_OUTPOST_PER_MIN * math.ceil(GameRules:GetDOTATime(false, false)/60)
									hero:AddExperience(valueXP, DOTA_ModifyXP_Unspecified, false,false)
								end
							end
						end
					end
				end
			end
            	return runeSpawnTime 
            end
        }
    )
end