part_mod = class({})
--------------------------------------------------------------------------------
function part_mod:GetEffectName()
    local partcls = {
    "particles/econ/items/dazzle/dazzle_ti6_gold/dazzle_ti6_shallow_grave_gold.vpcf", -- 1
    "particles/econ/courier/courier_greevil_orange/courier_greevil_orange_ambient_3.vpcf",--2
    "particles/econ/events/ti7/fountain_regen_ti7_lvl3.vpcf",--3
    "particles/econ/events/ti8/ti8_hero_effect.vpcf",--4
    "particles/units/heroes/hero_mars/mars_arena_of_blood_heal.vpcf",--5
    "particles/econ/courier/courier_shagbark/courier_shagbark_ambient.vpcf",--6
    "particles/my_new/courier_roshan_darkmoon.vpcf",--7
    "particles/econ/events/ti7/ti7_hero_effect.vpcf",--8
    "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_ice.vpcf",--9
    "particles/econ/courier/courier_wyvern_hatchling/courier_wyvern_hatchling_fire.vpcf",--др 10
    "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf",--P lvl 1 11 10ktrolleffect.vpcf particles/tryforpulsetrolleffect.vcpf
    "particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8_flying.vpcf",--P lvl 2 12
    "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf",--P lvl 3 13
    "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf",--P lvl 4 14
    "particles/econ/items/dazzle/dazzle_ti6_gold/dazzle_ti6_shallow_grave_gold.vpcf",--P lvl 5 15
    "particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf",--молнии платиного рошана 16
    "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf",--др2 17
    "particles/my_new/ambientfx_effigy_wm16_radiant_lvl3.vpcf",--19 /                                               18
    "particles/econ/courier/courier_greevil_blue/courier_greevil_blue_ambient_3.vpcf",--23/                         19
    "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf",--24                      20
    "particles/econ/items/nightstalker/nightstalker_black_nihility/nightstalker_black_nihility_void_swarm.vpcf",--сталкера 27/ 21
    "particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_3.vpcf",--сильная трава 28
    "particles/dev/curlnoise_test.vpcf", -- много частичек 30                                                               //23
    "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf",--send roshan 34             //24
    "particles/econ/items/bane/slumbering_terror/bane_slumbering_terror_ambient_a.vpcf",--штука бейна 35                    //25
    "particles/units/heroes/hero_invoker/invoker_ghost_walk_debuff.vpcf",--инвок 36                                         //26
    "particles/econ/golden_ti7.vpcf", --27
    "particles/econ/events/ti9/ti9_emblem_effect.vpcf", --28
    "particles/econ/events/ti10/emblem/ti10_emblem_effect.vpcf", --29
    "particles/econ/courier/courier_trail_hw_2013/courier_trail_hw_2013.vpcf", --30
    "particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_sprint_fire.vpcf", --31

    "particles/econ/events/diretide_2020/emblem/fall20_emblem_v3_effect.vpcf", --32
    "particles/econ/events/diretide_2020/emblem/fall20_emblem_v2_effect.vpcf", --33
    "particles/econ/events/diretide_2020/emblem/fall20_emblem_v1_effect.vpcf", --34
	"particles/econ/events/diretide_2020/emblem/fall20_emblem_effect.vpcf", --35

    "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_casterribbons_arcana1.vpcf", -- 36 топ2-3 винтер
    "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_snow_arcana1.vpcf", --37 top1

    "particles/econ/events/fall_major_2016/radiant_fountain_regen_fm06_lvl3.vpcf", -- 38 top1 spring
    "particles/econ/events/fall_major_2016/force_staff_fm06.vpcf", -- 39 top2 spring
    "particles/econ/events/fall_major_2016/force_staff_fm06_glow_trail.vpcf", -- 40 top3 sring


    "particles/econ/items/omniknight/omniknight_fall20_immortal/omniknight_fall20_immortal_degen_aura_debuff.vpcf", -- 41 TOP1 SUMMER
    "particles/econ/events/ti10/aghanim_aura_ti10/agh_aura_ti10.vpcf", --TOP2 SUMMER 42
    "particles/econ/events/spring_2021/agh_aura_spring_2021_lvl2.vpcf", --TOP2 SUMMER 43

    "particles/econ/events/summer_2021/summer_2021_emblem_effect.vpcf", --44 донат 12  
    "particles/econ/events/spring_2021/fountain_regen_spring_2021_lvl3.vpcf", --45 топ патреон

    "particles/econ/events/fall_2021/fall_2021_emblem_game_effect.vpcf", -- 46 donate 13
    "particles/units/heroes/hero_void_spirit/planeshift/void_spirit_planeshift_untargetable.vpcf", -- 47 event Alma




    "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff.vpcf", -- 48 event direc

    "particles/econ/events/fall_2021/fountain_regen_fall_2021_lvl3.vpcf",  -- winter TOP2 49
    "particles/econ/items/effigies/status_fx_effigies/ambientfx_effigy_wm16_dire_lvl3.vpcf", -- winter TOP3 50

    "particles/tve_magic_aghanim_pulse_ambient_c.vpcf", -- ивент 51

    "particles/units/heroes/hero_oracle/oracle_fatesedict_arc_pnt.vpcf", -- TOP2 52
    "particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf",  -- TOP 1 53
    "particles/units/heroes/hero_oracle/oracle_fatesedict_arc_thin.vpcf", -- TOP3 54

    "particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_buff.vpcf", -- TOP1 55
    "particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_pulse.vpcf", -- TOP2 56
    "particles/units/heroes/hero_omniknight/omniknight_heavenly_grace_beam.vpcf", -- TOP3  57

    "particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard.vpcf", -- ТОП шар 58

    -- ивент гуд
    "particles/econ/items/omniknight/omni_ti8_head/omniknight_repel_buff_ti8.vpcf", -- синяя фигня с кругом  59
    "particles/econ/items/oracle/oracle_ti10_immortal/oracle_ti10_immortal_purifyingflames.vpcf", -- грин с кругом  60
    "particles/econ/items/silencer/silencer_ti6/silencer_last_word_status_ti6.vpcf", -- фил с кругом  61
    "particles/econ/treasures/aghanim_2021_treasure/aghanim_2021_treasure_ambient.vpcf", -- син кольцо 62
    "particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf", -- ивент 63
    "particles/econ/items/medusa/medusa_daughters/medusa_daughters_mana_shield.vpcf", -- сфера медузы грин 64
    "particles/omni_2021_immortal_final.vpcf", -- кольцо огня от омника 65

    -- ивент
    "particles/units/heroes/hero_rubick/rubick_doom_ring.vpcf", -- биг метка 66
    "particles/units/heroes/hero_rubick/rubick_doom_sigil_c.vpcf", -- метка мини 67
    "particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_pushrocks.vpcf", -- камни 68
    "particles/econ/items/bane/slumbering_terror/bane_slumber_nightmare.vpcf", -- son 69
    "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf", -- аура дума кольцо ОГОнь 70
    "particles/econ/courier/courier_hermit_crab/hermit_crab_skady_ambient.vpcf", -- хрень топ10 71
    "particlesecon/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient.vpcf",  -- хрень донат7 72


    "particles/tve_void_spirit_planeshift.vpcf", -- крылья гуд 73
    "particles/tve_slark_fall20_shadow_dance.vpcf", -- аква 74
    "particles/tve_cold_monkey_king_arcana_crown_fire_core.vpcf",  -- сфера 75


    "particles/top1duel.vpcf",--P 76 top 1 1x1
    "particles/top2duel.vpcf",--P 77 top 2 1x1
    "particles/top3duel.vpcf",--P 78 top 3 1x1
    "particles/econ/events/fall_2021/bottle_fall_2021.vpcf",--P 79 trenir
    "particles/pulse_effect.vpcf",--P 80 10k TROLL particles/econ/items/grimstroke/gs_fall20_immortal/gs_fall20_immortal_soul_debuff.vpcf
    
    "particles/econ/events/fall_2022/agh/agh_aura_fall2022_lvl2.vpcf", -- 81 donate lvl 14
	"particles/econ/events/fall_2022/player/fall_2022_emblem_effect_player_base.vpcf", -- 82 donate lvl 15
    "particles/econ/items/hoodwink/hoodwink_2022_immortal/hoodwink_2022_immortal_sharpshooter.vpcf",-- 83 donate lvl 16
    "particles/econ/items/hoodwink/hoodwink_2022_immortal/hoodwink_2022_immortal_sharpshooter_blossom.vpcf",-- 84 donate lvl 16
    "particles/units/heroes/heroes_underlord/au_debut_rift.vpcf", -- 85 youtuber






    "particles/econ/courier/courier_dc/dccourier_angel_flame.vpcf", -- ангелы и лед

    "particles/econ/events/ti9/bottle_ti9.vpcf", -- 39 top2 sring
    "particles/econ/events/ti9/bottle_b_ti9.vpcf", -- 40 top3 spring

    "particles/customgames/capturepoints/cp_allied_fire.vpcf", -- крутой зеленый эффект

    "particles/econ/items/windrunner/windranger_arcana/windranger_arcana_ambient.vpcf", --38
	"particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf", --39




    --"particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_eztzhok.vpcf", --30

    --------------------------------------------------------------------------------------------------------------------------------
   -- "particles/econ/courier/courier_crystal_rift/courier_ambient_crystal_rift.vpcf",-- 37
   -- "particles/econ/courier/courier_oculopus/courier_oculopus_ambient.vpcf",-- 38
   -- "particles/econ/items/rubick/rubick_arcana/rubick_arc_ambient_detail.vpcf",-- 39
    --"particles/econ/items/skywrath_mage/hero_skywrath_dpits3_wings/skywrath_dpits3_backwing_p.vpcf",-- 40
   -- "particles/econ/courier/courier_gold_horn/courier_gold_horn_ambient.vpcf",--old др 41
    -------
       -- "particles/econ/courier/courier_trail_divine/courier_divine_ambient.vpcf",-- 18
         --  "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient_lvl4.vpcf",-- 20
  --  "particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf",--21
  --  "particles/econ/items/ember_spirit/ember_spirit_vanishing_flame/ember_spirit_vanishing_flame_ambient.vpcf",--22
    --  "particles/econ/courier/courier_greevil_yellow/courier_greevil_yellow_ambient_3.vpcf",--25
   -- "particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_2.vpcf",--26
      -- "particles/econ/courier/courier_golden_doomling/courier_golden_doomling_bloom_ambient.vpcf",--слабые золотые частички 29 /22
         -- "particles/econ/courier/courier_axolotl_ambient/courier_axolotl_ambient.vpcf",--розавая дичь 31
    --"particles/econ/items/sniper/sniper_charlie/sniper_shrapnel_charlie_ground.vpcf",--поляна 32
   -- "particles/econ/courier/courier_faceless_rex/cour_rex_ground_a.vpcf",--"шипы" из под земли 33
    "particles/econ/courier/courier_baekho/courier_baekho_ambient.vpcf",--слабая розавая дичь 42
    "particles/econ/courier/courier_jade_horn/courier_jade_horn_ambient.vpcf",--слабый зелёный эффект 43
    "particles/econ/courier/courier_red_horn/courier_red_horn_ambient.vpcf",--слабый красный эффект 44
    "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_arcana_ground_ambient.vpcf",--слабые снежинки под ногами 45
    "particles/econ/courier/courier_smeevil_flying_carpet/courier_smeevil_flying_carpet_ambient.vpcf",--слабые очень маленикие жёлтые частички 46

    }
	return partcls[self:GetStackCount()]
end

function part_mod:IsHidden()
	return true
end
--------------------------------------------------------------------------------
function part_mod:OnCreated( kv )
    if IsServer() then
        self:SetStackCount(tonumber(kv.part))
    end
end

function part_mod:IsPurgable()
	return false
end

function part_mod:RemoveOnDeath()
    return false
end
