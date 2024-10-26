	if self.qSpecialFixesListeners then
    for _, hListener in ipairs( self.qSpecialFixesListeners ) do
        hListener:Destroy()
    end
end

self.qSpecialFixesListeners = {}

local tModifiers = {
	-- npc_dota_hero_lina= {
	-- 	sPath = 'kbw/abilities/heroes/lina/m_kbw_lina_scepter',
	-- 	sName = 'm_kbw_lina_scepter',
	-- },
	npc_dota_hero_winter_wyvern = { -- #rubick_problem
		sPath = 'kbw/abilities/heroes/winter_wyvern/m_winter_wyvern_arctic_burn_vision',
		sName = 'm_winter_wyvern_arctic_burn_vision',
	},
	npc_dota_hero_abaddon = { -- #rubick_problem
		sPath = 'kbw/abilities/heroes/abaddon/m_abaddon_borrowed_time_autocast',
		sName = 'm_abaddon_borrowed_time_autocast',
	},
}

local tOverrideModifierValues = {
	modifier_nyx_assassin_burrow = {
		sAbility = 'nyx_assassin_burrow',
		sValue = 'damage_reduction',
		sCustomModifier = 'nDamageResist',
		nModifierOperation = OPERATION_ASYMPTOTE,
	},
	modifier_lich_frost_shield = {
		sAbility = 'lich_frost_shield',
		sValue = 'damage_reduction',
		sCustomModifier = 'nAttackResist',
		nModifierOperation = OPERATION_ASYMPTOTE,
	},
	modifier_ursa_enrage = {
		sAbility = 'ursa_enrage',
		sValue = 'damage_reduction',
		sCustomModifier = 'nDamageResist',
		nModifierOperation = OPERATION_ASYMPTOTE,
	},
	modifier_underlord_portal_buff = {
		sAbility = 'abyssal_underlord_dark_portal',
		sValue = 'damage_reduction',
		sCustomModifier = 'nDamageResist',
		nModifierOperation = OPERATION_ASYMPTOTE,
	},
}
_G.__tOverrideModifierValueAbilities = {}
for _, tOverrideData in pairs(tOverrideModifierValues) do
	local values = __tOverrideModifierValueAbilities[tOverrideData.sAbility]
	if not values then
		values = {}
		__tOverrideModifierValueAbilities[tOverrideData.sAbility] = values
	end
	values[tOverrideData.sValue] = 0.0001
end

local tModifierOnModifier = {
	modifier_mirana_moonlight_shadow = {
		m_evasion = {
			condition = function(hMod, hParent, hCaster, hAbility, tData)
				local hTalent = hCaster:FindAbilityByName('special_bonus_unique_mirana_5')
				if hTalent and hTalent:IsTrained() then
					tData.value = hTalent:GetSpecialValueFor('value')
					return true
				end
			end,
		},
	},
	modifier_ember_spirit_fire_remnant = {
		m_rootcast = {},
	},
	modifier_storm_spirit_ball_lightning = {
		m_rootcast = {},
	},
	modifier_centaur_stampede = {
		m_speed_pct = {
			data = {
				speed = 'speed_pct',
			},
		},
	},
	modifier_magnataur_horn_toss = {
		modifier_stunned = {},
	},
	modifier_lycan_shapeshift_speed = {
		m_kbw_status_resist = {},
	},
	modifier_ursa_enrage = {
		m_ursa_enrage_shard = {
			Path = 'kbw/abilities/heroes/ursa/m_ursa_enrage_shard'
		},
	},
	modifier_tusk_snowball_movement = {
		m_tusk_snowball_unmute = {
			Path = 'kbw/abilities/heroes/tusk/m_tusk_snowball_unmute'
		},
	},
	modifier_tusk_snowball_movement_friendly = {
		m_tusk_snowball_unmute = {
			Path = 'kbw/abilities/heroes/tusk/m_tusk_snowball_unmute'
		},
	},
	-- boots override
	modifier_item_phase_boots = {
		m_boots_override = {},
	},
	modifier_item_power_treads = {
		m_boots_override = {},
	},
	modifier_item_tranquil_boots = {
		m_boots_override = {},
	},
	modifier_item_arcane_boots = {
		m_boots_override = {},
	},
	modifier_item_guardian_greaves = {
		m_boots_override = {},
	},
	modifier_item_cyclone = {
		m_boots_override = {stackable = 1},
	},
	modifier_item_wind_waker = {
		m_boots_override = {stackable = 1},
	},
	modifier_dazzle_poison_touch = {
		m_kbw_visible = {
			condition = function(hMod, hParent, hCaster, hAbility, tData)
				local talent = hCaster:FindAbilityByName('special_bonus_unique_dazzle_poison_touch_vision')
				if talent and talent:IsTrained() then
					return true
				end
			end,
		},
	},
}

for _, t in pairs(tModifierOnModifier) do
	for sMod, tMod in pairs(t) do
		if tMod.Path then
			LinkLuaModifier(sMod, tMod.Path, LUA_MODIFIER_MOTION_NONE)
		end
	end
end

local function own(x, sBase)
	return function(t)
		return math.floor(t.fBase(sBase) * t.fParse(x) / 100 + 0.5)
	end
end

local function bas(sBase)
	return function(t)
		return math.floor(t.fBase(sBase, t.hUnit) + 0.5)
	end
end

local function ability(sAbility, sValue)
	return function(t)
		local hAbility = t.hOwner:FindAbilityByName(sAbility)
		if hAbility and hAbility:IsTrained() then
			return hAbility:GetSpecialValueFor(sValue)
		end
		return 0
	end
end

local function pct(n)
	return function(t)
		return math.floor(t.nCurrent * n / 100 + 0.5)
	end
end

_G.tSpecialUnitLimits = _G.tSpecialUnitLimits or {}

local tUnitStats = {
	['npc_dota_venomancer_plague_ward_'] = {
		bPartialMatch = true,
		sAbility = 'venomancer_plague_ward',
		nHealth = 'ward_hp_tooltip',
		nDamage = 'ward_damage_tooltip',
	},
	['npc_dota_furion_treant_large'] = {
		sAbility = 'furion_force_of_nature',
		nHealth = {'large_health', own('large_hero_health_pct')},
		nDamage = {'large_damage', own('large_hero_damage_pct')},
	},
	['npc_dota_furion_treant_%d'] = {
		bPartialMatch = true,
		sAbility = 'furion_force_of_nature',
		nHealth = {'treant_health_tooltip', own('hero_health_pct')},
		nDamage = {'treant_dmg_tooltip', own('hero_damage_pct')},
		nArmor = 'armor',
		nLimit = 'max_treants',
		fCondition = function(hUnit)
			return hUnit:HasModifier('modifier_kill')
		end
	},
	['npc_dota_wraith_king_skeleton_warrior'] = {
		sAbility = 'skeleton_king_vampiric_aura',
		nHealth = own('own_health'),
		nArmor = own('own_armor'),
		nDamage = {own('own_damage'), ability('special_bonus_unique_wraith_king_skeleton_damage', 'value')},
	},
	['npc_dota_lycan_wolf'] = {
		bPartialMatch = true,
		sAbility = 'lycan_summon_wolves',
		nDamage = 'wolf_damage',
		nHealth = 'wolf_hp',
		nArmor = 'armor',
	},
	['npc_dota_beastmaster_boar'] = {
		sAbility = 'beastmaster_call_of_the_wild_boar',
		nArmor = 'boar_armor',
		nSpeed = 'boar_speed',
	},
	['npc_dota_broodmother_spider'] = {
		bPartialMatch = true,
		sAbility = 'broodmother_spawn_spiderlings',
		nHealth = own('health_pct'),
		nDamage = own('base_dmg_pct'),
		nArmor = own('armor_pct'),
		nSpeed = 'speed',
	},
	['npc_dota_warlock_golem'] = {
		sAbility = 'warlock_rain_of_chaos',
		nModelScale = 'model_scale',
	},
	['npc_dota_unit_tombstone'] = {
		bPartialMatch = true,
		sAbility = 'undying_tombstone',
		nHealth = {
			'hits_to_destroy_tooltip',
			ability('special_bonus_unique_undying_5', 'value'),
			pct(300)
		},
	},
	['npc_dota_unit_undying_zombie'] = {
		bPartialMatch = true,
		sAbility = 'undying_tombstone',
		nDamage = 'zombie_damage',
	},
	['_eidolon$'] = {
		bPartialMatch = true,
		sAbility = 'enigma_demonic_conversion',
		nDamage = 'eidolon_dmg_tooltip',
		nHealth = {'eidolon_hp_tooltip', ability('special_bonus_unique_enigma_7', 'value')},
		nArmor = 'armor',
		nModelScale = 'model_scale',
	},
	['npc_dota_brewmaster_earth_%d'] = {
		bPartialMatch = true,
		sAbility = 'brewmaster_primal_split',
		nHealth = 'tooltip_earth_brewling_hp',
		nArmor = 'earth_armor',
		nDamage = 'earth_damage',
		nAttackTime = 'earth_attack',
		nSpeed = 'earth_speed',
	},
	['npc_dota_brewmaster_storm_%d'] = {
		bPartialMatch = true,
		sAbility = 'brewmaster_primal_split',
		nHealth = 'tooltip_storm_brewling_hp',
		nArmor = 'storm_armor',
		nDamage = 'storm_damage',
		nAttackTime = 'storm_attack',
		nSpeed = 'storm_speed',
	},
	['npc_dota_brewmaster_fire_%d'] = {
		bPartialMatch = true,
		sAbility = 'brewmaster_primal_split',
		nHealth = 'tooltip_fire_brewling_hp',
		nArmor = 'fire_armor',
		nDamage = 'fire_damage',
		nAttackTime = 'fire_attack',
		nSpeed = 'fire_speed',
	},
	['npc_dota_brewmaster_void_%d'] = {
		bPartialMatch = true,
		sAbility = 'brewmaster_primal_split',
		nHealth = 'tooltip_void_brewling_hp',
		nArmor = 'void_armor',
		nDamage = 'void_damage',
		nAttackTime = 'void_attack',
		nSpeed = 'void_speed',
	},
}

-- Abaddon Scepter
local function fAbaddonScepter(hAbility)
	if hAbility then
		local hCaster = hAbility:GetCaster()
		if hCaster:HasScepter() then
			local nDuration = hAbility:GetSpecialValueFor('ally_duration')
			local qUnits = FindUnitsInRadius(
				hCaster:GetTeam(),
				hCaster:GetOrigin(),
				hCaster,
				hAbility:GetSpecialValueFor('redirect_range_scepter'),
				DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
				FIND_ANY_ORDER,
				false
			)

			for _, hUnit in ipairs(qUnits) do
				if hUnit ~= hCaster then
					hUnit:AddNewModifier(hCaster, hAbility, 'modifier_abaddon_borrowed_time', {
						duration = nDuration,
					})

					hUnit:Purge(false, true, false, true, true)
				end
			end
		end
	end
end


table.insert(
	self.qSpecialFixesListeners,
	Events:Register( 'KBW_Spawn', function( hUnit )
		local sName = hUnit:GetUnitName()

		-- Unit Stats
		for sPattern, t in pairs(tUnitStats) do
			local function fCond(hUnit, sName)
				sName = sName or hUnit:GetUnitName()

				if t.bPartialMatch then
					return sName:match(sPattern) and true or false
				else
					return (sName == sPattern)
				end

				if not t.fCondition then
					return true
				end

				return t.fCondition(hUnit) and true or false
			end

			if fCond(hUnit, sName) then
				local hInv = hUnit:AddNewModifier(hUnit, nil, 'modifier_invulnerable', {})
				Timer( 1/30, function()
					if exist(hUnit) then
						if exist(hInv) then
							hInv:Destroy()
						end

						local hOwner = hUnit:GetOwner()

						if hOwner and hOwner.FindAbilityByName then
							local _sBase
							local tParse

							local function fParse(x, sBase)
								_sBase = sBase or _sBase
								local sType = type(x)

								if sType == 'string' then
									if tParse.hAbility == nil then
										if t.sAbility then
											tParse.hAbility = hOwner:FindAbilityByName(t.sAbility)
										end
										if not tParse.hAbility or not tParse.hAbility:IsTrained() then
											tParse.hAbility = false
										end
									end
									if tParse.hAbility then
										return tParse.hAbility:GetSpecialValueFor(x)
									end
								elseif sType == 'table' then
									local res = 0
									for _, sub in ipairs(x) do
										res = res + fParse(sub)
										tParse.nCurrent = res
									end
									return res
								elseif sType == 'function' then
									return x(tParse)
								elseif sType == 'number' then
									return x
								end

								return 0
							end

							tParse = {
								nCurrent = 0,
								hUnit = hUnit,
								hOwner = hOwner,
								fParse = fParse,
								fBase = function(sBase, hTarget)
									sBase = sBase or _sBase
									hTarget = hTarget or hOwner
									if sBase == 'health' then
										return hTarget:GetMaxHealth()
									elseif sBase == 'damage' then
										return (hTarget:GetBaseDamageMax() + hTarget:GetBaseDamageMin()) / 2
									elseif sBase == 'armor' then
										return hTarget:GetPhysicalArmorBaseValue()
									elseif sBase == 'attack_time' then
										return hTarget:GetBaseAttackTime()
									elseif sBase == 'speed' then
										return hTarget:GetBaseMoveSpeed()
									else
										return 1
									end
								end,
							}

							local nHealth = fParse(t.nHealth, 'health')
							local nDamage = fParse(t.nDamage, 'damage')
							local nArmor = fParse(t.nArmor, 'armor')
							local nAttackTime = fParse(t.nAttackTime, 'attack_time')
							local nSpeed = fParse(t.nSpeed, 'speed')
							local nModelScale = fParse(t.nModelScale, 'model_scale')
							local nLimit = fParse(t.nLimit, 'limit')

							if nHealth > 0 then
								hUnit:SetBaseMaxHealth( nHealth )
								hUnit:SetMaxHealth( nHealth )
								hUnit:SetHealth( nHealth )
							end

							if nDamage > 0 then
								hUnit:SetBaseDamageMin( nDamage )
								hUnit:SetBaseDamageMax( nDamage )
							end

							if nArmor > 0 then
								hUnit:SetPhysicalArmorBaseValue( nArmor )
							end
							
							if nAttackTime > 0 then
								hUnit:SetBaseAttackTime(nAttackTime)
							end

							if nSpeed > 0 then
								hUnit:SetBaseMoveSpeed( nSpeed )
							end

							if nModelScale > 0 then
								hUnit:SetModelScale( nModelScale )
							end

							if nLimit > 0 then
								local nPlayer = hUnit:GetPlayerOwnerID()
								local tPlayerLimits = _G.tSpecialUnitLimits[nPlayer]
								if not tPlayerLimits then
									tPlayerLimits = {}
									_G.tSpecialUnitLimits[nPlayer] = tPlayerLimits
								end
								local aUnits = tPlayerLimits[sPattern]
								if not aUnits then
									aUnits = {}
									tPlayerLimits[sPattern] = aUnits
								end

								for i = #aUnits, 1, -1 do
									if not exist(aUnits[i]) then
										table.remove(aUnits, i)
									end
								end

								table.insert(aUnits, hUnit)

								if #aUnits > nLimit then
									table.remove(aUnits, 1):Kill()
								end
							end
						end
					end
				end)

				break
			end
		end
	end, {
		sName = 'SpecialFixes'
	})
)

local hListener = Events:Register( 'KBW_FirstSpawn', function( hUnit )
    local sName = hUnit:GetUnitName()

	local tSpecialModifier = tModifiers[sName]
	if tSpecialModifier then
		LinkLuaModifier(tSpecialModifier.sName, tSpecialModifier.sPath, LUA_MODIFIER_MOTION_NONE)
		AddModifier(tSpecialModifier.sName, {
			hTarget = hUnit,
			hCaster = hUnit,
			bAddToDead = true,
		})
	end

	for i = 0, hUnit:GetAbilityCount() - 1 do
		local hAbility = hUnit:GetAbilityByIndex(i)
		if hAbility then
			local sAbility = hAbility:GetName()

			-- Spirit Breaker Bash Cooldown Reduction
			if sAbility == 'spirit_breaker_greater_bash' then
				local bCooldown = false
				Timer(function()
					if not exist(hAbility) then
						return
					end
					local bNewCooldown = not hAbility:IsCooldownReady()
					if bCooldown ~= bNewCooldown then
						if bNewCooldown then
							hAbility:EndCooldown()
							hAbility:StartCooldown(hAbility:GetCooldown(hAbility:GetLevel() - 1))
						end
						bCooldown = bNewCooldown
					end
					return 1/30
				end)
			end
		end
	end

	-- Juggernaut Ward
	if sName == 'npc_dota_juggernaut_healing_ward' then
        local hOwner = hUnit:GetOwner()
        if hOwner and hOwner.FindAbilityByName then
			local nInterval = hOwner:GetSecondsPerAttack()

			hUnit:SetBaseDamageMin(hOwner:GetBaseDamageMin())
			hUnit:SetBaseDamageMax(hOwner:GetBaseDamageMax())

			hUnit:AddNewModifier(hOwner, nil, 'm_disarm', {})

			Timer(nInterval, function()
				if exist(hUnit) and hUnit:IsAlive() then
					local nTeam = hUnit:GetTeam()
					local vPos = hUnit:GetOrigin()
					local hTarget

					local function fUnits(nType)
						return FindUnitsInRadius(
							hUnit:GetTeam(),
							hUnit:GetOrigin(),
							hUnit,
							500,
							DOTA_UNIT_TARGET_TEAM_ENEMY,
							nType,
							DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
							FIND_ANY_ORDER,
							true
						)
					end

					local aHeroes = fUnits(DOTA_UNIT_TARGET_HERO)
					local nHeroes = #aHeroes
					if nHeroes > 0 then
						hTarget = aHeroes[RandomInt(1, nHeroes)]
					else
						local aUnits = fUnits(DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING)
						local nUnits = #aUnits
						if nUnits > 0 then
							hTarget = aUnits[RandomInt(1, nUnits)]
						end
					end

					if hTarget then
						hUnit:PerformAttack(hTarget, true, true, true, false, true, false, false)
					end

					return nInterval
				end
			end)
		end
	end

	-- Pudge MoM
	if sName == 'npc_dota_hero_pudge' then
		Timer(0.1, function()
			GIFT_GIVEOUT = true
			local hItem = hUnit:AddItemByName('item_gift_pudge_mom')
			GIFT_GIVEOUT = nil
			if hItem then
				hItem:SetPurchaseTime(-1000)
			end
		end)
	end
end, {
	sName = 'SpecialFixes'
} )
table.insert( self.qSpecialFixesListeners, hListener )

Events:Register( 'OnAttack', function( t )
    if not exist( t.attacker ) then
        return
    end

    if not exist( t.target ) or not t.target:IsBaseNPC() then
        return
    end

	if t.target:IsAlive() then
		if t.attacker:IsAlive() then
			-- Lina scepter
			local hBuff = t.attacker:FindModifierByName('modifier_lina_flame_cloak')
			if hBuff then
				local hAbility = hBuff:GetAbility()
				if hAbility then
					hAbility.nAttacks = (hAbility.nAttacks or 0) + 1
					if hAbility.nAttacks >= hAbility:GetSpecialValueFor('proc_attacks') then
						local aSpells = {}
						for i = 0, 5 do
							local hSpell = t.attacker:GetAbilityByIndex(i)
							if hSpell and SpellCaster:IsActive(hSpell) and (
								SpellCaster:IsCorrectTarget(hSpell, t.target) or
								SpellCaster:IsCorrectTarget(hSpell, t.attacker)
							) then
								table.insert(aSpells, hSpell)
							end
						end
						local _, hSpell = table.random(aSpells)
						hSpell = t.attacker:GetAbilityByIndex(hSpell)
						if hSpell:IsTrained() then
							if SpellCaster:IsCorrectTarget(hSpell, t.target) then
								SpellCaster:Cast(hSpell, t.target)
							else
								SpellCaster:Cast(hSpell, t.attacker)
							end
						end
						hAbility.nAttacks = 0
					end
				end
			end
		end
	end
-- 		if t.attacker:GetUnitName() == 'npc_dota_hero_lina' and t.attacker:HasScepter() then
-- 			if RandomFloat( 0, 100 ) <= 10 then
-- 				local tAbilities = {}
-- 				for i = 0, 5 do
-- 					local hAbility = t.attacker:GetAbilityByIndex( i )
-- 					if binhas( hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET, DOTA_ABILITY_BEHAVIOR_POINT, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
-- 						tAbilities[ hAbility ] = 1
-- 					end
-- 				end

-- 				local hAbility = table.random( tAbilities )
-- 				if hAbility and hAbility:IsTrained() then
-- 					SpellCaster:Cast( hAbility, t.target )
-- 				end
-- 			end
-- 		end
--     end
end, {
    sName = 'SpecialFixes'
} )


Events:Register( 'OnAttackLanded', function( t )
    if not exist( t.attacker ) then
        return
    end

    if not exist( t.target ) or not t.target:IsBaseNPC() then
        return
    end

	-- bloodseeker shard
	if not IsBoss(t.target) then
		local bloodrage_buff = t.attacker:FindModifierByName('modifier_bloodseeker_bloodrage')
		if bloodrage_buff and bloodrage_buff:GetCaster():HasShard() then
			local spell = bloodrage_buff:GetAbility()
			if spell then
				local value = t.target:GetMaxHealth() * spell:GetSpecialValueFor('shard_override') / 100
			
				ApplyDamage({
					victim = t.target,
					attacker = t.attacker,
					ability = spell,
					damage = value,
					damage_type = DAMAGE_TYPE_PURE,
				})
				
				t.attacker:Heal(value, spell)
			end
		end
	end
end, {
    sName = 'SpecialFixes'
} )

Events:Register('OnTakeDamage', function(t)
	if not exist( t.inflictor ) then
		return
	end
	if not t.inflictor.IsItem then
		return
	end

	local sAbility = t.inflictor:GetName()

	-- AA Blast Scepter
	if sAbility == 'ancient_apparition_ice_blast' then
		if t.unit:IsAlive() and t.attacker:HasScepter() then
			local hVortex = t.attacker:FindAbilityByName('ancient_apparition_ice_vortex')
			if hVortex and hVortex:IsTrained() then
				SpellCaster:Cast(hVortex, t.unit:GetOrigin())
			end
		end
	end

	-- Ursa Talent Stun
	if sAbility == 'ursa_earthshock' or sAbility == 'ursa_earthshock_charges' then
		local hTalent = t.attacker:FindAbilityByName('special_bonus_unique_ursa_earthshock_stun')
		if exist(hTalent) and hTalent:IsTrained() then
			AddModifier('modifier_stunned', {
				hTarget = t.unit,
				hCaster = t.attacker,
				hAbility = t.inflictor,
				duration = hTalent:GetSpecialValueFor('value'),
			})
		end
	end

	-- Pangolier Lucky Shot item procs
	local hAbility = t.attacker:FindAbilityByName('pangolier_lucky_shot')
	if hAbility and hAbility:IsTrained() then
		if t.inflictor:IsItem() and RandomFloat(0, 100) <= hAbility:GetSpecialValueFor('chance_pct') then
			AddModifier('modifier_pangolier_luckyshot_disarm', {
				hTarget = t.unit,
				hCaster = t.attacker,
				hAbility = t.inflictor,
				duration = hAbility:GetSpecialValueFor('duration'),
			})
		end
	end

	-- Luna Lucent Beam Talent
	if sAbility == 'luna_lucent_beam' then
		local hTalent = t.attacker:FindAbilityByName('special_bonus_unique_luna_lucent_beam_attacks')
		if hTalent and hTalent:IsTrained() then
			local bOriginal = t.inflictor:GetCooldownTimeRemaining() == t.inflictor:GetEffectiveCooldown(t.inflictor:GetLevel() - 1)
			local nCount = hTalent:GetSpecialValueFor(bOriginal and 'count' or 'eclipse_count')
			local nInterval = hTalent:GetSpecialValueFor('interval')
			Timer(nInterval, function()
				if exist(t.attacker) and exist(t.unit) and nCount > 0 then
					t.attacker:PerformAttack(t.unit, true, true, true, false, false, false, false)
					nCount = nCount - 1
					return nInterval
				end
			end)
		end
	end

	-- Enigma Shard
	if sAbility == 'enigma_malefice' then
		local cdr = t.inflictor:GetSpecialValueFor('cooldown_reductions')
		if cdr > 0 then
			for _, targetname in ipairs{
				'enigma_midnight_pulse',
				'enigma_black_hole',
			} do
				local spell = t.attacker:FindAbilityByName(targetname)
				if spell then
					local rem = spell:GetCooldownTimeRemaining()
					if rem > 0 then
						spell:EndCooldown()
						rem = rem - cdr
						if rem > 0 then
							spell:StartCooldown(rem)
						end
					end
				end
			end
		end
	end
end, {
	sName = 'SpecialFixes',
})

Events:Register('OnAbilityStart', function(t)
	if not exist( t.ability ) then
		return
	end

	local sAbility = t.ability:GetName()
	local hCaster = t.ability:GetCaster()

	-- Spirit Breaker Shard
	if sAbility == 'spirit_breaker_nether_strike' then
		if not t.ability.bShardBuffGiven then
			local nDuration = t.ability:GetSpecialValueFor('total_buff_duration')
			if nDuration > 0 then
				local tCreateData = {
					hTarget = hCaster,
					hCaster = hCaster,
					hAbility = t.ability,
					duration = nDuration,
					hide = 1,
				}

				AddModifier('modifier_black_king_bar_immune', tCreateData)
				AddModifier('m_kbw_antistun', tCreateData)

				t.ability.bShardBuffGiven = true
			end
		end
	end
end, {
	sName = 'SpecialFixes',
})


Events:Register( 'OnAbilityExecuted', function( t )
	if not exist( t.ability ) then
		return
	end

	local sAbility = t.ability:GetName()
	local hCaster = t.ability:GetCaster()

	-- TA Meld interrupt moving
	if sAbility == 'templar_assassin_meld' then
		if hCaster:IsMoving() then
			hCaster:Stop()
		end
	end

	-- Axe vs custom fix
	if sAbility == 'axe_culling_blade' then
		if t.target:GetHealth() <= t.ability:GetSpecialValueFor('damage') then
			MakeKillable(t.target)
		end
	end

	-- Invoker Forges Resumon
	if sAbility == 'invoker_forge_spirit' then
		local nPlayer = hCaster:GetPlayerOwnerID()
		local aForges = Find:UnitsInRadius({
			nFilterFlag_ = DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED,
			fCondition = function(hUnit)
				return hUnit:GetUnitName() == 'npc_dota_invoker_forged_spirit' and hUnit:GetPlayerOwnerID() == nPlayer
			end,
		})
		for _, hForge in ipairs(aForges) do
			MakeKillable(hForge, true)
			hForge:ForceKill(false)
		end
	end
end, {
	sName = 'SpecialFixes',
})

Events:Register( 'OnAbilityFullyCast', function( t )
	if not exist( t.ability ) then
		return
	end

	local sAbility = t.ability:GetName()
	local hCaster = t.ability:GetCaster()

	-- Creeps Abilities Shitfix
	if sAbility == 'chen_holy_persuasion'
	or sAbility == 'life_stealer_infest' then
		if exist(t.target) and not t.target:IsHero() then
			t.target:AddAbility('generic_hidden')
		end
	end

	-- Refershers full refresh
	if sAbility:match('item_refresher%d?') then
		RefreshSpells(hCaster, true, true)
	end

	-- Pike vision
	if sAbility:match('item_hurricane_pike') then
		local nDuration = t.ability:GetSpecialValueFor('range_duration')
		local nTeam = hCaster:GetTeam()

		Timer(function(nDT)
			if not exist(t.target) or not t.target:IsAlive() then
				return
			end

			nDuration = nDuration - nDT
			if nDuration <= 0 then
				return
			end

			AddFOWViewer(nTeam, t.target:GetOrigin(), 150, 0.2, false)

			return 0.1
		end)
	end

	-- Lotus Orb strong dispel
	if sAbility:match('^item_lotus_orb') then
		if exist(t.target) then
			t.target:Purge(false, true, false, true, true)
		end
	end

	-- Hoodwing Scepter Cooldown
	if sAbility == 'hoodwink_hunters_boomerang' then
		Timer(1/30, function()
			local hTarget
			local nMinDistance
			local vCaster = hCaster:GetOrigin()
			for _, hEnt in ipairs(Entities:FindAllByClassnameWithin('npc_dota_base_additive', vCaster, 600)) do
				local nDistance = (hEnt:GetOrigin() - vCaster):Length2D()
				if not nMinDistance or nDistance < nMinDistance then
					nMinDistance = nDistance
					hTarget = hEnt
				end
			end
			if hTarget then
				local nTimeOut = GameRules:GetGameTime() + 10
				Timer(function()
					if GameRules:GetGameTime() > nTimeOut or t.ability:IsNull() then
						return
					end
					if not exist(hTarget) or not hTarget:IsAlive() then
						t.ability:EndCooldown()
					else
						return 1/30
					end
				end)
			end
		end)
	end

	-- Puck infinite Shift fix
	if sAbility == 'puck_phase_shift' then
		local nAttackInterval = t.ability:GetSpecialValueFor('attack_interval')
		local nAttackRange = t.ability:GetSpecialValueFor('shard_attack_range_bonus')
		local nCooldown = t.ability:GetSpecialValueFor('min_cd')
		local nTeam = hCaster:GetTeam()
		local nAttackTimer = 0

		t.ability:SetActivated( false )

		Timer( 1/30, function(dt)
			if not exist( t.ability ) or not exist( hCaster ) then
				return
			end

			if hCaster:HasModifier('modifier_puck_phase_shift') then
				if nAttackInterval > 0 then
					nAttackTimer = nAttackTimer + dt
					if nAttackTimer >= nAttackInterval then
						nAttackTimer = nAttackTimer - nAttackInterval

						local enemies = FindUnitsInRadius(
							nTeam,
							hCaster:GetOrigin(),
							hCaster,
							hCaster:GetAttackRange() + nAttackRange,
							DOTA_UNIT_TARGET_TEAM_ENEMY,
							DOTA_UNIT_TARGET_ALL,
							DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
								+ DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE
								+ DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
							FIND_ANY_ORDER,
							false
						)

						for _, enemy in ipairs(enemies) do
							hCaster:PerformAttack(enemy, true, true, true, false, true, false, false)
						end
					end
				end

				return 1/30
			end

			if t.ability:GetCooldownTimeRemaining() < 1 then
				t.ability:EndCooldown()
				t.ability:StartCooldown( nCooldown )
			end
			t.ability:SetActivated( true )
		end )
	end

	-- Dark Willow infinite Realm fix
	if sAbility == 'dark_willow_shadow_realm' then
		local nMinCd = t.ability:GetSpecialValueFor('duration') + t.ability:GetSpecialValueFor('min_invterval')
		if t.ability:GetCooldownTimeRemaining() < nMinCd then
			t.ability:EndCooldown()
			t.ability:StartCooldown( nMinCd )
		end
	end

	-- WindWaker Cooldown
	if sAbility:match('item_wind_waker') then
		local nMinCd = 5
		if t.ability:GetCooldownTimeRemaining() < nMinCd then
			t.ability:EndCooldown()
			t.ability:StartCooldown( nMinCd )
		end
	end

	-- Pangolier Shield Crash Ball CD
	if sAbility == 'pangolier_shield_crash' then
		if t.ability:GetCooldownTimeRemaining() < 0.9 then
			t.ability:EndCooldown()
			t.ability:StartCooldown(0.9)
		end
	end

	-- Lycan Shard
	if sAbility == 'lycan_shapeshift' then
		if hCaster:HasShard() then
			local hWolveAbility = hCaster:FindAbilityByName('lycan_summon_wolves')
			if hWolveAbility and hWolveAbility:IsTrained() then
				local hPlayer = hCaster:GetPlayerOwner()
				local nPlayer = hCaster:GetPlayerOwnerID()
				local nTeam = hCaster:GetTeam()
				local nCount = t.ability:GetSpecialValueFor('shard_wolves')
				local nLevel = hWolveAbility:GetLevel()
				local nDuration = hWolveAbility:GetSpecialValueFor('wolf_duration')
				local sWolve = 'npc_dota_lycan_wolf' .. nLevel

				if t.ability.aShardWolves then
					for _, hWolf in ipairs(t.ability.aShardWolves) do
						if exist(hWolf) then
							hWolf:ForceKill(false)
						end
					end
				end

				if nCount > 0 then
					local vPos = hCaster:GetOrigin()
					local vForward = hCaster:GetForwardVector()
					local vDelta = Vector(vForward.y, -vForward.x, 0) * 100
					vPos = vPos + vForward * 200 - vDelta * (nCount-1)/2

					t.ability.aShardWolves = {}

					for i = 1, nCount do
						local hUnit = CreateUnitByName(sWolve, vPos, true, hCaster, hCaster:GetOwner(), nTeam)
						if hUnit then
							hUnit:SetControllableByPlayer(nPlayer, false)
							hUnit:SetOwner(hCaster)
							hUnit:SetForwardVector(vForward)
							hUnit:FaceTowards(hUnit:GetOrigin() + vForward*1000)
							hUnit:AddNewModifier(hUnit, t.ability, 'modifier_kill', {
								duration = nDuration,
							})

							table.insert(t.ability.aShardWolves, hUnit)
						end

						vPos = vPos + vDelta
					end
				end
			end
		end
	end

	-- Treant Scepter
	if sAbility == 'treant_overgrowth' and hCaster:HasScepter() then
		AddFOWViewer(hCaster:GetTeam(), hCaster:GetOrigin(), t.ability:GetSpecialValueFor('radius'), t.ability:GetSpecialValueFor('duration'), false)
	end

	-- Abaddon Scepter
	if sAbility == 'abaddon_borrowed_time_2' then
		fAbaddonScepter(t.ability)
	end

	-- Clockwerk Scepter
	if sAbility == 'rattletrap_overclocking' then
		RefreshSpells(hCaster, true, false, function(hSpell)
			return not IsRefresher(hSpell) and hSpell ~= t.ability
		end)
	end

	-- Invoker Alacrity AOE Talent
	if sAbility == 'invoker_alacrity' and exist(t.target) then
		local hTalent = hCaster:FindAbilityByName('special_bonus_unique_invoker_alacrity_aoe')
		if hTalent and hTalent:IsTrained() then
			local aUnits = FindUnitsInRadius(
				hCaster:GetTeam(),
				t.target:GetOrigin(),
				nil,
				hTalent:GetSpecialValueFor('aoe'),
				DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false
			)

			for _, hUnit in ipairs(aUnits) do
				if hUnit ~= t.target then
					SpellCaster:Cast(t.ability, hUnit)
				end
			end
		end
	end

	-- Doom Devour Duration
	if sAbility == 'doom_bringer_devour' then
		for _, hMod in ipairs(hCaster:FindAllModifiersByName('modifier_doom_bringer_devour')) do
			if math.abs(hMod:GetRemainingTime() - hMod:GetDuration()) <= FrameTime() then
				hMod:SetDuration(t.ability:GetSpecialValueFor('duration'), true)
			end
		end
	end

	-- Rubick self cooldown fix
	if sAbility == 'rubick_telekinesis' then
		t.ability:EndCooldown()
		t.ability:StartCooldown(t.ability:GetEffectiveCooldown(t.ability:GetLevel() - 1))
	end

	-- Spirit Breaker Shard
	if sAbility == 'spirit_breaker_nether_strike' then
		local nDuration = t.ability:GetSpecialValueFor('break_duration')
		if nDuration > 0 and exist(t.target) and t.target:IsAlive() then
			AddModifier('m_kbw_break', {
				hTarget = t.target,
				hCaster = hCaster,
				hAbility = t.ability,
				duration = nDuration,
			})
		end

		t.ability.bShardBuffGiven = nil
	end

	-- Ursa Enrage Heal
	if sAbility == 'ursa_enrage' then
		local heal = t.ability:GetSpecialValueFor('heal_pct')
		if heal > 0 then
			heal = heal * hCaster:GetMaxHealth() / 100
			hCaster:Heal(heal, t.ability)
		end
	end

	-- Storm Spirit Ult CD
	if sAbility == 'storm_spirit_ball_lightning' then
		local hBuff = hCaster:FindModifierByName('modifier_storm_spirit_ball_lightning')

		if hBuff then
			local nCooldown = t.ability:GetCooldownTimeRemaining()

			t.ability:SetActivated(false)
			t.ability:EndCooldown()

			Timer(function()
				if not exist(hCaster) or not exist(t.ability) then
					return
				end

				if exist(hBuff) then
					return FrameTime()
				end

				if t.ability:GetCooldownTimeRemaining() < nCooldown then
					t.ability:EndCooldown()
					t.ability:StartCooldown(nCooldown)
				end

				t.ability:SetActivated(true)
			end)
		end
	end

	-- Muerta The Calling (Vision & Scepter)
	if sAbility == 'muerta_the_calling' then
		local team = hCaster:GetTeam()
		local target = t.ability:GetCursorPosition()
		local radius = t.ability:GetAOERadius()
		local duration = t.ability:GetSpecialValueFor('duration')

		AddFOWViewer(
			team,
			target,
			radius,
			duration,
			false
		)

		if hCaster:HasScepter() then
			local veil = hCaster:FindAbilityByName('muerta_pierce_the_veil_kbw')
			if veil and veil:GetLevel() > 0 then
				local allies = FindUnitsInRadius(
					team,
					target,
					nil,
					radius,
					DOTA_UNIT_TARGET_TEAM_FRIENDLY,
					DOTA_UNIT_TARGET_HERO,
					DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
					FIND_ANY_ORDER,
					false
				)

				for _, ally in ipairs(allies) do
					local ability = veil
					local caster = hCaster

					local own_veil = ally:FindAbilityByName('muerta_pierce_the_veil_kbw')
					if own_veil then
						ability = own_veil
						caster = ally
					end

					local mod = AddModifier('m_muerta_pierce_the_veil_kbw_buff', {
						hCaster = caster,
						hTarget = ally,
						hAbility = ability,
						duration = duration,
					})
					if mod then
						mod:AddSource(target, radius)
					end
				end
			end
		end
	end
	
	-- Jakiro Skepter
	if sAbility == 'jakiro_dual_breath'
	or sAbility == 'jakiro_ice_path'
	or sAbility == 'jakiro_macropyre_kbw' then
		if hCaster:HasScepter() then
			local target = t.ability:GetCursorPosition()
			local start = hCaster:GetOrigin()
			local dir = target - start
			local length = dir:Length2D()
			dir = dir:Normalized()
			local angle = math.atan2(dir.y, dir.x)
			local dangle = t.ability:GetSpecialValueFor('scepter_angle') * math.pi / 180
			
			for i = -1, 1, 2 do
				local angle = angle + dangle * i
				local dir = Vector(math.cos(angle), math.sin(angle), 0)
				local target = GetGroundPosition(start + dir * length, nil)
				
				SpellCaster:Cast(t.ability, target)
			end
		end
	end
end, {
	sName = 'SpecialFixes',
} )

Events:Register( 'OnAbilityEndChannel', function( t )
	if not exist( t.ability ) then
		return
	end

	local sAbility = t.ability:GetName()

	-- Duel Leave:
	-- Templar Assassin Scepter
	-- Elder Titan Shard
	if sAbility == 'templar_assassin_trap_teleport'
	or sAbility == 'elder_titan_echo_stomp' then
		Timer( 1/30, function()
			Area._fUpdateUnit( t.ability:GetCaster() )
		end )
	end
end, {
	sName = 'SpecialFixes',
})

local tBlockModifiers = {
	modifier_item_mekansm_noheal = 1,
	modifier_item_crimson_guard_nostack = 1,
	modifier_fountain_invulnerability = 1,
}

local tBlockBossModifiers = {
	modifier_ice_blast = 1,
	modifier_viper_nethertoxin = 1,
	modifier_disruptor_kinetic_field = 1,
	modifier_techies_land_mine_burn = 1,
}

local function reapply(t)
	local hParent = EntIndexToHScript(t.entindex_parent_const)
	local hCaster = EntIndexToHScript(t.entindex_caster_const or -1)
	local hAbility = EntIndexToHScript(t.entindex_ability_const or -1)
	Timer(FrameTime(), function()
		hParent:AddNewModifier(hCaster, hCaster, t.name_const, {duration = t.duration})
	end)
	return false
end

local function track(mod, callback)
	local duration
	Timer(function()
		if exist(mod) then
			local rem = mod:GetRemainingTime()
			if not duration or rem > duration then
				callback()
			end
			duration = rem
			return FrameTime()
		end
	end)
end

local bSHRINE

Filters:Register( 'ModifierGained', function( t )
	local hParent = EntIndexToHScript( t.entindex_parent_const )
	local hCaster = EntIndexToHScript(t.entindex_caster_const or -1)
	local hAbility = EntIndexToHScript(t.entindex_ability_const or -1)

	if tBlockModifiers[t.name_const] then
		return false
	end

	if tBlockBossModifiers[t.name_const] then
		if IsBoss(hParent) then
			return false
		end
	end

	if IsDebuffImmune(hParent) and hCaster and hParent:GetTeam() ~= hCaster:GetTeam() then
		return false
	end

	local hMod
	for _, hMod_ in ipairs(hParent:FindAllModifiersByName(t.name_const)) do
		if hMod_:GetCaster() == hCaster and math.abs(hMod_:GetRemainingTime() - t.duration) < 0.01 then
			hMod = hMod_
			break
		end
	end

	-- Override modifiers
	local tOverrideData = tOverrideModifierValues[t.name_const]
	if tOverrideData then
		local hCaster = EntIndexToHScript( t.entindex_caster_const )
		local hAbility = hCaster:FindAbilityByName(tOverrideData.sAbility)
		if hAbility and (not tOverrideData.fCondition or tOverrideData.fCondition(hCaster, hAbility)) then
			local nValue = hAbility:GetLevelSpecialValueNoOverride(tOverrideData.sValue, hAbility:GetLevel()-1) / 100
			local hCustomModifier = AddSpecialModifier(hParent, tOverrideData.sCustomModifier, nValue, tOverrideData.nModifierOperation)
			Timer(function()
				if hParent:HasModifier(t.name_const) then
					return 1/30
				else
					hCustomModifier:Destroy()
				end
			end)
		end
	end

	-- Extend modifiers
	if exist(hMod) then
		local tExtendModifiers = tModifierOnModifier[t.name_const]
		if tExtendModifiers then
			local aMods = {}
			for sMod, tData in pairs(tExtendModifiers) do
				if not tData.condition or tData.condition(hMod, hParent, hCaster, hAbility, tData) then
					local tCreateData = {}
					if tData.data then
						for k, v in pairs(tData.data) do
							if type(v) == 'string' then
								v = hAbility:GetSpecialValueFor(v)
							end
							tCreateData[k] = v
						end
					end

					local hMod = hParent:AddNewModifier(hCaster, hAbility, sMod, tCreateData)
					if hMod then
						table.insert(aMods, hMod)
					end
				end
			end
			Timer(function()
				if exist(hMod) then
					return 1/30
				else
					for _, hMod in ipairs(aMods) do
						if exist(hMod) then
							hMod:Destroy()
						end
					end
				end
			end)
		end
	end

	-- Scepter granted abilities autolearn fix (also in filters.lua)
	if exist(hMod) and hParent:IsRealHero() then
		local bScepter = hMod:HasFunction(MODIFIER_PROPERTY_IS_SCEPTER)
		local bShard = hMod:HasFunction(MODIFIER_PROPERTY_IS_SHARD)
		if bScepter or bShard then
			for i = 0, hParent:GetAbilityCount() - 1 do
				local ability = hParent:GetAbilityByIndex(i)
				if ability and not ability:IsStolen() and IsAbilityLinked(ability) then
					local kv = ability:GetAbilityKeyValues()
					if tostring(kv.AutoLearn or 0) == '0' then
						if (bScepter and tostring(kv.IsGrantedByScepter or 0) ~= '0')
						or (bShard and tostring(kv.IsGrantedByShard or 0) ~= '0') then
							local level = ability._honest_level or 0
							local function fUpdateThisAndLinked(ability)
								if ability and ability:GetLevel() ~= level then
									ability:SetLevel(level)
									local kv = ability:GetAbilityKeyValues()
									if kv.LinkedAbility then
										fUpdateThisAndLinked(hParent:FindAbilityByName(kv.LinkedAbility))
									end
								end
							end
							fUpdateThisAndLinked(ability)
							
							-- shitfix
							if level == 0 then
								local name = ability:GetName()

								-- riki invis
								if name == 'riki_poison_dart' then
									hParent:RemoveModifierByName('modifier_riki_backstab')
									hParent:RemoveModifierByName('modifier_invisible')
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- shrine
	if t.name_const == 'modifier_filler_heal' and not bSHRINE then
		local units = FindUnitsInRadius(
			hParent:GetTeam(),
			hCaster:GetOrigin(),
			hCaster,
			hAbility:GetSpecialValueFor('radius'),
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
			FIND_ANY_ORDER,
			false
		)
		
		for _, unit in ipairs(units) do
			if not unit:HasModifier('modifier_filler_heal') then
				unit:AddNewModifier(hCaster, hAbility, 'modifier_filler_heal', {
					duration = t.duration,
				})
			end
		end
	end

	-- WK hueta
	if t.name_const == 'modifier_skeleton_king_reincarnation_scepter_active' then
		if hParent._prevent_wk_hueta == GameRules:GetGameTime() then
			return false
		end
	end

	-- Sphere duration
	if t.name_const == 'modifier_item_sphere_target' then
		for _, hMod in ipairs(hParent:FindAllModifiersByName('modifier_item_sphere_target')) do
			if hMod:GetElapsedTime() > 0 then
				hMod:Destroy()
			end
		end
		t.duration = hAbility:GetSpecialValueFor('buff_duration')
	end

	-- Ogre Bloodlust Talent
	if t.name_const == 'modifier_ogre_magi_bloodlust' then
		track(hMod, function()
			local talent = hCaster:FindAbilityByName('special_bonus_unique_ogre_magi_bloodlust_immune')
			if talent and talent:IsTrained() then
				AddModifier('m_kbw_spell_immune_block', {
					hTarget = hParent,
					hCaster = hCaster,
					hAbility = hAbility,
					duration = talent:GetSpecialValueFor('duration'),
				})

				hCaster:Purge(false, true, false, false, false)
			end
		end)
	end

	-- Silencer Last Word Vision
	if t.name_const == 'modifier_silencer_last_word' and exist(hAbility) then
		AddModifier('m_kbw_durty_vision', {
			hTarget = hParent,
			hCaster = hCaster,
			hAbility = hAbility,
			duration = hAbility:GetSpecialValueFor('vision_duration'),
			purgable = 1,
		})
	end

	-- Abaddon Scepter
	if t.name_const == 'modifier_abaddon_borrowed_time' then
		if t.entindex_caster_const == t.entindex_parent_const then
			fAbaddonScepter(hAbility)
		end
	end

	-- Razor Stacks Limit
	if t.name_const == 'modifier_razor_eye_of_the_storm_armor' then
		Timer(function()
			if exist(hMod) then
				local ability = hMod:GetAbility()
				if ability then
					hMod.max_limit = math.max(hMod.max_limit or 0, ability:GetSpecialValueFor('armor_cap'))
					if hMod:GetStackCount() > hMod.max_limit then
						hMod:SetStackCount(hMod.max_limit)
					end
				end
				return FrameTime()
			end
		end)
	end
	
	-- Dazzle Grave Heal Talent
	if t.name_const == 'modifier_dazzle_shallow_grave' and hAbility:GetName() == 'dazzle_shallow_grave' then
		Timer(function()
			if not exist(hMod) or hMod:GetRemainingTime() < 1/20 then
				if exist(hParent) and hParent:IsAlive() then
					local talent = hCaster:FindAbilityByName('special_bonus_unique_dazzle_grave_heal')
					if talent and talent:IsTrained() then
						local heal = hParent:GetMaxHealth() * talent:GetSpecialValueFor('value') / 100
						hParent:Heal(heal, hAbility)
						SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, hParent, heal, nil)
					end
				end
			else
				return FrameTime()
			end
		end)
	end

	return true
end, {
	sName = 'SpecialFixes'
} )