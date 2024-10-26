local tCastOrders = {
	[DOTA_UNIT_ORDER_CAST_POSITION] = 1,
	[DOTA_UNIT_ORDER_CAST_TARGET] = 1,
	[DOTA_UNIT_ORDER_CAST_TARGET_TREE] = 1,
	[DOTA_UNIT_ORDER_CAST_NO_TARGET] = 1,
	[DOTA_UNIT_ORDER_CAST_TOGGLE] = 1,
	[DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO] = 1,
	[DOTA_UNIT_ORDER_CAST_RIVER_PAINT] = 1,
}

local tItemOrders = {
	[DOTA_UNIT_ORDER_DROP_ITEM] = 1,
	[DOTA_UNIT_ORDER_GIVE_ITEM] = 1,
	[DOTA_UNIT_ORDER_SELL_ITEM] = 1,
	[DOTA_UNIT_ORDER_DISASSEMBLE_ITEM] = 1,
	[DOTA_UNIT_ORDER_MOVE_ITEM] = 1,
	[DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH] = 1,
	[DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK] = 1,
	[DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN] = 1,
	[DOTA_UNIT_ORDER_PREGAME_ADJUST_ITEM_ASSIGNMENT] = 1,
}

local tNotInterruptOrders = {
	[DOTA_UNIT_ORDER_NONE] = 1,
	[DOTA_UNIT_ORDER_TRAIN_ABILITY] = 1,
	[DOTA_UNIT_ORDER_PURCHASE_ITEM] = 1,
	[DOTA_UNIT_ORDER_SELL_ITEM] = 1,
	[DOTA_UNIT_ORDER_DISASSEMBLE_ITEM] = 1,
	[DOTA_UNIT_ORDER_MOVE_ITEM] = 1,
	[DOTA_UNIT_ORDER_CAST_TOGGLE] = 1,
	[DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO] = 1,
	[DOTA_UNIT_ORDER_TAUNT] = 1,
	[DOTA_UNIT_ORDER_GLYPH] = 1,
	[DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH] = 1,
	[DOTA_UNIT_ORDER_PING_ABILITY] = 1,
	[DOTA_UNIT_ORDER_RADAR] = 1,
	[DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK] = 1,
	[DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN] = 1,
	[DOTA_UNIT_ORDER_TAKE_ITEM_FROM_NEUTRAL_ITEM_STASH] = 1,
}

local TBlockAbilitiesOnArea = {
	viper_nethertoxin = 1,
	techies_land_mines = 1,
	techies_remote_mines = 1,
	arc_warden_spark_wraith = 1,
}

local tGifts = {
	item_gift_pudge_mom = 1,
}

local tBlockMainBoss = {
	-- death_prophet_spirit_siphon = 1,
}

local tBlockBosses = {
	razor_static_link = 1,
}

local function FixCombine(hItem)
	Timer(1/30, function()
		if exist(hItem) then
			local hParent = hItem:GetParent()
			if hParent then
			--	CustomShop:CombineItems(hParent, hItem:GetName(), true)
			end
		end
	end)
end

function IsInterruptOrder(t)
	local bInterrupt = ( not tNotInterruptOrders[ t.order_type ] and t.queue == 0 )

	if bInterrupt and tCastOrders[ t.order_type ] then
		local hAbility = EntIndexToHScript( t.entindex_ability or -1 )
		if hAbility and binhas( tonumber( tostring( hAbility:GetBehavior() ) ), DOTA_ABILITY_BEHAVIOR_IMMEDIATE ) then
			return false
		end
	end

	return bInterrupt
end

function IsStopOrder(t)
	return
		t.queue == 0 and (
			t.order_type == DOTA_UNIT_ORDER_HOLD_POSITION or
			t.order_type == DOTA_UNIT_ORDER_STOP
		)
end

Filters:Register( 'ExecuteOrder', function( tData )
	if IGNORE_ORDER_FILTER then
		return true
	end

	if STOP_GAME then
		return false
	end

	local t = tData
	local nPlayer = t.issuer_player_id_const
	local ability = EntIndexToHScript(tData.entindex_ability)
	local hAbility = ability
	local bAbility = exist(ability) and ability.GetBehavior
	local sAbility = bAbility and ability:GetName()
	local vTarget = Vector(t.position_x, t.position_y, t.position_z)
	local target = EntIndexToHScript(tData.entindex_target)
	local bDefault = true

	if ability and ability.bDestroying then
		return false
	end

	local qUnits = {}
	for sUnitOrder, nUnitIndex in pairs( tData.units ) do
		qUnits[ tonumber( sUnitOrder ) + 1 ] = EntIndexToHScript( nUnitIndex )
	end
	local hUnit = qUnits[1]

	-- cast in mute
	if tCastOrders[t.order_type] and ability and ability.IgnoreSilence and ability:IgnoreSilence() then
		local isitem = ability:IsItem()
		local caster = ability:GetCaster()
		if (isitem and caster:IsMuted())
		or (not isitem and caster:IsSilenced()) then
			if not target or SpellCaster:IsCorrectTarget(ability, target) then
				SpellCaster:Cast(ability, target or vTarget, true)
				return false
			end
		end
	end
	
	-- enemy shrines activate
	if t.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET and target
	and target:GetName() == 'shrain_blyat' and target:GetTeam() ~= hUnit:GetTeam() then
		SendHudError(nPlayer, '#dota_hud_error_target_invulnerable')
		return false
	end

	-- Scepter granted abilities autolearn fix (also in special_fiexs.lua)
	if t.order_type == DOTA_UNIT_ORDER_TRAIN_ABILITY then
		local points = hUnit:GetAbilityPoints()
		if bAbility and points > 0 then
			if hUnit:GetLevel() >= ability:GetHeroLevelRequiredToUpgrade() then
				local level = ability:GetLevel() + 1
				local function fUpdateLinked(spell)
					if spell then
						spell._honest_level = level
						if spell:GetLevel() ~= level then
							spell:SetLevel(level)
							local kv = spell:GetAbilityKeyValues()
							if kv.LinkedAbility then
								fUpdateLinked(hUnit:FindAbilityByName(kv.LinkedAbility))
							end
						end
					end
				end
				fUpdateLinked(ability)
				hUnit:SetAbilityPoints(points - 1)
			end
			return false
		end
	end


	if t.order_type == DOTA_UNIT_ORDER_CAST_POSITION and hAbility then
		local hCaster = hAbility:GetCaster()

		-- Dawnbreaker Hammer Range
		if sAbility == 'dawnbreaker_celestial_hammer' then
			local vStart = hCaster:GetOrigin()
			local vDelta = vTarget - vStart
			local nRange = hAbility:GetSpecialValueFor('real_range') + hCaster:GetCastRangeBonus()
			vDelta.z = 0

			if #vDelta > nRange then
				vTarget = GetGroundPosition(vStart + vDelta:Normalized() * nRange, nil)
				t.position_x = vTarget.x
				t.position_y = vTarget.y
				t.position_z = vTarget.z
			end
		end

		-- Zeus Nimbus
		if sAbility == 'zuus_cloud' then
			local units = Find:UnitsInRadius({
				nTeam = hUnit:GetTeam(),
				vCenter = vTarget,
				nRadius = hAbility:GetSpecialValueFor('cloud_radius'),
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				nFilterType = DOTA_UNIT_TARGET_OTHER,
				fCondition = function(unit)
					return unit:GetUnitName() == 'npc_dota_zeus_cloud'
				end
			})
			if #units > 0 then
				SendHudError(hCaster:GetPlayerOwnerID(), '#kbw_hud_error_zuus_double_nimbus')
				return false
			end
		end
	end

	-- disable help
	if t.order_type == DOTA_UNIT_ORDER_CAST_TARGET and bAbility and target then
		local hCaster = ability:GetCaster()
		if hCaster:GetTeam() == target:GetTeam() then
			local nPlayerCaster = hCaster:GetPlayerOwnerID()
			local nPlayerTarget = target:GetPlayerOwnerID()
			if nPlayerCaster >= 0 and nPlayerTarget >= 0
			and PlayerResource:IsDisableHelpSetForPlayerID(nPlayerTarget, nPlayerCaster) then
				SendHudError(nPlayerCaster, '#dota_hud_error_target_has_disable_help')
				return false
			end
		end
	end

	if tData.order_type == DOTA_UNIT_ORDER_CAST_TARGET and exist( ability ) and IsNPC( target ) then
		local hCaster = ability:GetCaster()
		local sAbility = ability:GetName()

		if target == _G.boss and tBlockMainBoss[sAbility] then
			return false
		end

		if tBlockBosses[sAbility] and IsStatBoss(target) then
			return false
		end

		if target:HasModifier("modifier_fountain_aura_effect_lua") and hCaster:GetTeam() ~= target:GetTeam() then
			return false
		end

		-- Pugna Shard
		if sAbility == 'pugna_life_drain' and target:GetUnitName():match('npc_dota_pugna_nether_ward_') and not hCaster:HasShard() then
			SendHudError(nPlayer, '#dota_hud_error_cant_cast_on_other')
			return false
		end

		-- Chen Scepter self Cast
		if sAbility == 'chen_martyrdom' and target == hCaster then
			SendHudError(nPlayer, '#dota_hud_error_cant_cast_on_self')
			return false
		end

		if tData.queue == 0 and not hCaster:IsStunned() then
			local function fForceCast()
				if ability:IsFullyCastable() then
					_G.IGNORE_ORDER_FILTER = true
					SpellCaster:Cast(ability, target, true)
					_G.IGNORE_ORDER_FILTER = nil
				end
				return false
			end

			if not hCaster:IsMuted() then
				if sAbility:match('item_kbw_bullwhip') and target == hCaster then
					return fForceCast()
				end
			end

			if not hCaster:IsSilenced() then
				if sAbility:match('pugna_decrepify_kbw') then
					local vTarget = target:GetOrigin()
					if hCaster:IsChanneling() and (hCaster:GetOrigin() - vTarget):Length2D() <= ability:GetEffectiveCastRange(vTarget, target) then
						return fForceCast()
					end
				end
			end
		end
	end

	-- tp interrupt
	if t.queue == 0 and not IsStopOrder(t) then
		for _, hUnit in pairs(qUnits) do
			local hTp = hUnit:FindItemInInventory('item_kbw_tpscroll')
			if hTp and hTp:IsChanneling() then
				local bInterrupt = not tNotInterruptOrders[t.order_type]
				if bInterrupt and bAbility then
					if binhas(ability:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL) then
						bInterrupt = false
					end
				end
				if bInterrupt then
					t.queue = 1
				end
			end
		end
	end

	-- clone abilities
	if tCastOrders[t.order_type] and qUnits[1].bPreventCast then
		SendHudError(nPlayer, 'dota_hud_error_unit_muted')
		return false
	end

	-- ursa earthshock stack
	if t.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and ability and ability:GetCaster():HasModifier('modifier_ursa_earthshock_move')
	and (sAbility == 'ursa_earthshock' or sAbility == 'ursa_earthshock_charges') then
		return false
	end

	-- transfer gifts
	if ({
		[DOTA_UNIT_ORDER_DROP_ITEM] = 1,
		[DOTA_UNIT_ORDER_GIVE_ITEM] = 1,
		[DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH] = 1,
		[DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN] = 1,
	 })[tData.order_type] then
		if exist(ability) and tGifts[ability:GetName()] then
			return false
		end
	end

	if tData.order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
		if target and target.GetContainedItem then
			local item = target:GetContainedItem()

			-- prevent pickup runes by courier
			if item then
				if qUnits[1] and qUnits[1]:IsCourier() and item:GetName():match('item_custom_rune') then
					return false
				end
			end

			-- prevent cores steal
			if item.nPickupTeam and exist(qUnits[1]) and item.nPickupTeam ~= qUnits[1]:GetTeam() then
				return false
			end
		end
	end

	-- prevent casting shit on arena
	-- if tData.order_type == DOTA_UNIT_ORDER_CAST_POSITION and exist( ability ) and TBlockAbilitiesOnArea[ability:GetAbilityName()] then
	-- 	local hHero = PlayerResource:GetSelectedHeroEntity( ability:GetCaster():GetPlayerOwnerID() )

	-- 	if hHero and not hHero.duel then
	-- 		local vPos = Vector( tData.position_x, tData.position_y, tData.position_z )
	-- 		for _, hArea in ipairs(self.qArenaAbilityBlockers) do
	-- 			if hArea:IsPositionInside( vPos ) then
	-- 				SendHudError(t.issuer_player_id_const, '#dota_hud_error_cant_cast_on_other')
	-- 				return false
	-- 			end
	-- 		end
	-- 	end
	-- end

	-- enemy fountain shitcast
	if tData.order_type == DOTA_UNIT_ORDER_CAST_POSITION and exist(hAbility)
	and ENEMY_FOUNTAIN_FORBIDEN_SPELLS[sAbility] then
		local hCaster = hAbility:GetCaster()
		if hCaster then
			local hArea = self.tFountainAreas[hCaster:GetOpposingTeamNumber()]
			if hArea and hArea:IsPositionInside(vTarget) then
				SendHudError(t.issuer_player_id_const, '#custom_hud_error_enemy_fountain')
				return false
			end
		end
	end

	-- sell tp
	if t.order_type == DOTA_UNIT_ORDER_SELL_ITEM and sAbility == 'item_kbw_tpscroll' then
		return false
	end

	tData.units = {}
	local nOrder = 0
	for _, hUnit in ipairs( qUnits ) do
		if exist( hUnit ) then
			tData.units[ tostring( nOrder ) ] = hUnit:entindex()
			nOrder = nOrder + 1
		end
	end

	local bInterrupt = IsInterruptOrder(tData)

	local hUnit
	local nMinIndex

	for sIndex, nUnitIndex in pairs( tData.units ) do
		local hiUnit = EntIndexToHScript( nUnitIndex )
		if hiUnit then
			local nIndex = tonumber( sIndex )
			if not nMinIndex or nIndex < nMinIndex then
				hUnit = hiUnit
				nMinIndex = nIndex
			end

			if bInterrupt then
				if hiUnit.tDropThinkers then
					for hTimer in pairs( hiUnit.tDropThinkers ) do
						if exist( hTimer ) then
							hTimer:Destroy()
						end
					end

					hiUnit.tDropThinkers = nil
				end
			end
		end
	end

	-- local tOldSlots = {}

	-- allow move items to neutral slot
	if tData.order_type == DOTA_UNIT_ORDER_MOVE_ITEM then
		local hAbility = EntIndexToHScript(tData.entindex_ability or -1)
		if not hAbility or not hAbility.GetParent then
			return true
		end

		local hUnit = hAbility:GetParent()
		if not hUnit then
			return true
		end

		if exist(hAbility) then
			local nCurrentSlot = hAbility:GetItemSlot()

			if nCurrentSlot == -1 then
				nCurrentSlot = DOTA_ITEM_NEUTRAL_SLOT
			end

			local bCurrentStash = IsStash(nCurrentSlot)
			local bTargetStash = IsStash(tData.entindex_target)
			local bStashTransfer = (bCurrentStash ~= bTargetStash)
			local bInShop = qUnits[1]:IsInRangeOfShop(DOTA_SHOP_HOME, true)

			if nCurrentSlot ~= DOTA_ITEM_TP_SCROLL and tData.entindex_target ~= DOTA_ITEM_TP_SCROLL
			and (not bStashTransfer or bInShop) then
				local nPlayer = hUnit:GetPlayerOwnerID()
				local hHero = PlayerResource:GetSelectedHeroEntity(nPlayer)
				local hTargetOwner = bTargetStash and hHero or qUnits[1]
				local hItemOwner = bCurrentStash and hHero or hUnit
				local hTargetItem = hTargetOwner:GetItemInSlot(tData.entindex_target)

				if hAbility == hTargetItem then
					return true
				end

				if hAbility:GetName() == 'item_aegis' or (hTargetItem and hTargetItem:GetName() == 'item_aegis') then
					return true
				end

				if not hTargetOwner:HasInventory() then
					return true
				end

				if hItemOwner == hTargetOwner then
					hItemOwner:SwapItems(nCurrentSlot, tData.entindex_target)
					return false
				end

				if tData.issuer_player_id_const ~= nPlayer or tData.issuer_player_id_const ~= hTargetOwner:GetPlayerOwnerID() then
					return true
				end

				if hHero ~= hUnit then
					return true
				end

				if hItemOwner ~= hTargetOwner and not bCurrentStash and not bTargetStash then
					return true
				end

				HideItem(hAbility)
				if hTargetItem then
					HideItem(hTargetItem)
				end

				AddItem(hTargetOwner, hAbility, {
					nSlot = tData.entindex_target,
				})
				if hTargetItem then
					AddItem(hItemOwner, hTargetItem, {
						nSlot = nCurrentSlot,
					})
				end

				return false
			end
		end
	end


	if tData.order_type == DOTA_UNIT_ORDER_DISASSEMBLE_ITEM then
		local hItem = EntIndexToHScript( tData.entindex_ability or -1 )
		if exist(hItem) then
			if hItem.bDisassemblable == false then
				return false
			end

			local tKV = hItem:GetAbilityKeyValues()
			if tKV.ItemDisassembleRule ~= 'DOTA_ITEM_DISASSEMBLE_ALWAYS'
			and GameRules:GetGameTime() - hItem:GetPurchaseTime() > 10 then
				return false
			end
		end
	end

	-- if exist( hUnit ) and tItemOrders[ tData.order_type ] then
	-- 	local hItem = EntIndexToHScript( tData.entindex_ability or -1 )
	-- 	if exist( hItem ) then
	-- 		local bInstant = tNotInterruptOrders[ tData.order_type ]

	-- 		local fCheckItem = function( hItem )
	-- 			local sName = hItem:GetName()

	-- 			if sName == 'item_kbw_dummy' then
	-- 				return true
	-- 			end

	-- 			if bInstant or tData.queue == 0 then
	-- 				for sHuetaKey in pairs( self.tHuetaItems ) do
	-- 					if sName:match( sHuetaKey ) then
	-- 						if tData.order_type == DOTA_UNIT_ORDER_DISASSEMBLE_ITEM
	-- 						and GameRules:GetGameTime() - hItem:GetPurchaseTime() > 10 then
	-- 							return true
	-- 						end

	-- 						local nSlot = tOldSlots[hItem] or hItem:GetItemSlot()
	-- 						local hParent = hItem:GetParent()

	-- 						local fCheck = function()
	-- 							if not exist( hItem ) then
	-- 								return true
	-- 							end

	-- 							if hItem:GetItemSlot() ~= nSlot then
	-- 								return true
	-- 							end

	-- 							if hItem:GetParent() ~= hParent then
	-- 								return true
	-- 							end
	-- 						end

	-- 						local hTimer = Timer( 1/30, function()
	-- 							if fCheck() then
	-- 								self:FixHueta( hParent )
	-- 								return
	-- 							end

	-- 							if not bInstant then
	-- 								return 0.1
	-- 							end
	-- 						end )

	-- 						if not hParent.tDropThinkers then
	-- 							hParent.tDropThinkers = {}
	-- 						end

	-- 						hParent.tDropThinkers[ hTimer ] = 1

	-- 						break
	-- 					end
	-- 				end
	-- 			end
	-- 		end

	-- 		if fCheckItem( hItem ) then
	-- 			return false
	-- 		end

	-- 		if tData.order_type == DOTA_UNIT_ORDER_MOVE_ITEM then
	-- 			local hTargetItem = hUnit:GetItemInSlot( tData.entindex_target )
	-- 			if exist( hTargetItem ) and fCheckItem( hTargetItem ) then
	-- 				return false
	-- 			end
	-- 		end
	-- 	end
	-- end

	return bDefault
end, { sName = 'KBW' } )

local fUseBuffMultiplier = function( nBase, hHero, sPositive, sNegative )
	local hBuff = hHero:FindModifierByName( sPositive )
	if hBuff then
		nBase = nBase * ( 100 + hBuff:GetStackCount() ) / 100
	end

	local hBuff = hHero:FindModifierByName( sNegative )
	if hBuff then
		nBase = nBase * ( 100 - hBuff:GetStackCount() ) / 100
	end

	return nBase
end

Filters:Register( 'Damage', function( kv )
	if STOP_GAME then
		return false
	end

	local hAbility = EntIndexToHScript(kv.entindex_inflictor_const or -1)
	local attacker = EntIndexToHScript( kv.entindex_attacker_const or -1 )
	local victim = EntIndexToHScript(kv.entindex_victim_const)
	local damage = kv.damage

	-- WK hueta
	if victim._prevent_wk_hueta then
		if hAbility then
			local name = hAbility:GetName()
			if name == 'skeleton_king_reincarnation' then
				return false
			end
			if name == victim:GetUnitName() and kv.damagetype_const == 0 then
				if victim._prevent_wk_hueta == GameRules:GetGameTime() then
					victim:SetHealth(1)
					return false
				end
				victim._prevent_wk_hueta = nil
			end
		end
	end

	if victim._prevent_damage then
		victim:SetHealth(victim._prevent_damage)
		victim._prevent_damage = nil
		return false
	end

	if not attacker or attacker == GameplayEventTracker.hModifier then
		return true
	end

	if not exist(victim) or not exist(attacker) then
		return true
	end

	local hVictimHero = PlayerResource:GetSelectedHeroEntity( victim:GetPlayerOwnerID() )
	local hAttackerHero = PlayerResource:GetSelectedHeroEntity( attacker:GetPlayerOwnerID() )

	if hVictimHero and hAttackerHero and ( not hVictimHero.duel ) ~= ( not hAttackerHero.duel ) then
		return false
	end

	if attacker:GetUnitName():match('shrine') and IsBoss( victim )
	and victim:GetTeam() == DOTA_TEAM_NEUTRALS then
		return false
	end

	-- cleave damage on neutrals in smoke (gabe daun)
	if attacker:HasModifier('m_item_kbw_ninja_gear_active') and victim:GetTeam() == DOTA_TEAM_NEUTRALS then
		return false
	end

	if victim:HasModifier("modifier_fountain_aura_effect_lua") and attacker:GetTeamNumber() ~= victim:GetTeamNumber() then
		if kv.damagetype_const ~= 0 and (not hAbility or hAbility:GetName() ~= 'oracle_false_promise') then
			return false
		end
	end

	if attacker:IsTower() and victim.spawner then
		return false
	end

	if hAbility then
		local name = hAbility:GetName()

		-- Beastmaster Shard
		if name == 'beastmaster_hawk_dive' then
			local hCaster = hAbility:GetCaster()
			local nDamage = hCaster:GetMaxHealth() * hAbility:GetSpecialValueFor('damage') / 100
			kv.damage = nDamage * (1 - victim:GetMagicalArmorValue()) -- хуета но и похуй

		-- Tusk Scepter on creeps
		elseif name == 'tusk_walrus_kick' then
			if victim:IsCreep() then
				kv.damage = math.min(kv.damage, victim:GetMaxHealth() * hAbility:GetSpecialValueFor('max_creep_damage') / 100)
			end
		end
	end

	if not ApplyPersonalFilters(victim, 'DamageTaker', kv) then
		return false
	end

	return true
end, { sName = 'KBW' } )

Filters:Register( 'Healing', function( tData )
	if STOP_GAME then
		return false
	end

	if tData.entindex_inflictor_const then
		local hUnit = EntIndexToHScript( tData.entindex_target_const or -1 )
		local hAbility = EntIndexToHScript( tData.entindex_inflictor_const or -1 )

		if hUnit and hAbility then		
			if hUnit.nHealAmp then
				tData.heal = math.max(0, math.floor( tData.heal * ( 100 + hUnit.nHealAmp ) / 100 + 0.5 ))
			end
		end
	end

	return true
end, { sName = 'KBW' } )

Filters:Register( 'ItemAddedToInventory', function( tData )
	local hItem = EntIndexToHScript( tData.item_entindex_const or -1 )
	local hUnit = EntIndexToHScript( tData.inventory_parent_entindex_const or -1 )

	local function fDestroy()
		hItem.bDestroying = true
		Timer(1/30, function()
			if exist(hItem) then
				local hParent = hItem:GetParent()
				if hParent then
					hParent:RemoveItem(hItem)
				else
					hItem:Destroy()
				end
			end
		end)
	end

	if hItem.OnPickupCustom and exist(hUnit) then
		if hItem:OnPickupCustom(hUnit) then
			return false
		end
	end

	return true
end, { sName = 'KBW' } )

-- ModifierGained in special_fixes.lua