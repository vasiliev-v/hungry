
require 'lib/particle_manager'
require 'lib/finder'
require 'lib/modifier'


function GetAttachmentOrigin(unit, attach)
	return unit:GetAttachmentOrigin(unit:ScriptLookupAttachment(attach))
end

_G.__consumed_net_worths = _G.__consumed_net_worths or {}

function IncrementConsumedNetWorth(nPlayer, nCost)
	_G.__consumed_net_worths[nPlayer] = GetConsumedNetWorth(nPlayer) + nCost
end

function GetConsumedNetWorth(nPlayer)
	return _G.__consumed_net_worths[nPlayer] or 0
end

function IsInventoryOwner(hUnit)
	return hUnit:HasInventory() and not hUnit:NotRealHero() and not hUnit:IsTempestDouble()
end

function CanDamageByBossRange(target, attacker)
	if not IsBoss(target) or target:GetTeam() ~= DOTA_TEAM_NEUTRALS then
		return true
	end

	if exist(attacker) and attacker:IsAlive()
	and (target:GetOrigin() - attacker:GetOrigin()):Length2D() <= BOSS_DAMAGE_RANGE then
		return true
	end

	return false
end

function CDOTABaseAbility:FullRefresh()
	self:EndCooldown()
	self:RefreshCharges()
	if self.OnRefreshed then
		self:OnRefreshed()
	end
end

function RefreshSpells(hUnit, bAbilities, bItems, fCondition)
	fCondition = fCondition or function(hAbility)
		return not IsRefresher(hAbility)
	end

	if bAbilities then
		for i = 0, hUnit:GetAbilityCount() - 1 do
			local hAbility = hUnit:GetAbilityByIndex(i)
			if hAbility and fCondition(hAbility) then
				hAbility:FullRefresh()
			end
		end
	end

	if bItems then
		IterateInventory(hUnit, 'ACTIVE', function(_, hItem)
			if hItem and fCondition(hItem) then
				hItem:FullRefresh()
			end
		end)
	end
end

function IsRefresher(hSpell)
	return hSpell:GetName():match('item_refresher%d?')
end

local tPurgeExceptions = {
	modifier_truesight = 1,
	modifier_grimstroke_soul_chain = 1,
	modifier_death_prophet_spirit_siphon_slow = 1,
	modifier_death_prophet_spirit_siphon = 1,
	modifier_razor_static_link_debuff = 1,
	modifier_razor_static_link_buff = 1,
	modifier_wisp_tether = 1,
	modifier_wisp_tether_haste = 1,
	modifier_lion_mana_drain = 1,
	modifier_lion_mana_drain_immunity = 1,
	modifier_pugna_life_drain = 1,
	modifier_shredder_reactive_armor = 1,
	modifier_shredder_reactive_armor_stack = 1,
	modifier_dazzle_bad_juju_manacost = 1,
}

function SuperPurge(hUnit, bRemoveBuffs, bRemoveDebuffs)
	for _, hMod in ipairs(hUnit:FindAllModifiers()) do
		if (not hMod.RemoveOnDuel or hMod:RemoveOnDuel())
		and hMod:DestroyOnExpire() and hMod:GetRemainingTime() > 0
		and not hMod:HasFunction(MODIFIER_PROPERTY_LIFETIME_FRACTION)
		and not tPurgeExceptions[hMod:GetName()] then
			if hMod:IsDebuff() then
				if bRemoveDebuffs then
					hMod:Destroy()
				end
			else
				if bRemoveBuffs then
					hMod:Destroy()
				end
			end
		end
	end
end

function MakeBoss( hUnit, bCreep )
	hUnit.boss = true
	if not bCreep then
		AddModifier( 'm_kbw_boss_healthbar', {
			hTarget = hUnit,
			hCaster = hUnit,
		})
	end
	AddModifier('m_kbw_boss_flag', {
		hTarget = hUnit,
		hCaster = hUnit,
		real_boss = not bCreep and 1 or nil
	})
end

function RemoveWithContainer(hItem)
	if exist(hItem) then
		local hContainer = hItem:GetContainer()
		if hContainer then
			hContainer:Destroy()
		end
		hItem:Destroy()
	end
end

function AddDebuffImmunity(hUnit, n)
	hUnit.nDebuffImmunity = (hUnit.nDebuffImmunity or 0) + n
end

function IsDebuffImmune(hUnit)
	return (hUnit.nDebuffImmunity or 0) > 0
end

function ModifyExperienceFiltered(hUnit, nExp, nReason)
	if not hUnit.AddExperience then
		return
	end
	local tExpData = {
		hero_entindex_const = hUnit:entindex(),
		player_id_const = hUnit:GetPlayerOwnerID(),
		reason_const = nReason or 0,
		experience = nExp,
	}
	if Filters:Trigger('ModifyExperience', tExpData) then
		local exp = tExpData.experience + (hUnit._exp_lag or 0)
		local exp_int = math.floor(exp)
		hUnit._exp_lag = exp - exp_int
		
		hUnit:__AddExperience(exp_int, tExpData.reason_const, false, true)
	end
end

function SendHudError(nPlayer, sMsg, sSound)
	CustomGameEventManager:SendProtected(nPlayer, 'cl_hud_error', {
		sMsg = sMsg,
		sSound = sSound,
	})
end

function self:ForcePick(nPlayer, sUnit)
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_HERO_SELECTION then
		return
	end

	local sUnit = 'npc_dota_hero_' .. sUnit

	PlayerResource:GetPlayer(nPlayer):SetSelectedHero(sUnit)

	local sHero = PlayerResource:GetSelectedHeroName(nPlayer)
	if not sHero or sHero == '' then
		return
	end

	local sMsg = Rank:IsRanked() and '#KbwForcePickRanked' or '#KbwForcePick'
	GameRules:SendCustomMessage(sMsg, nPlayer, 0)

	Rank:SetForcePicker(nPlayer)
end

function PlaySound(sSound, xTarget, nTeam, nDuration)
	nDuration = nDuration or GameRules:GetGameModeEntity():GetSoundDuration(sSound, '')
	local vTarget = xTarget
	local hTarget
	if xTarget.IsBaseNPC then
		hTarget = xTarget
		vTarget = hTarget:GetOrigin()
	end

	local hMarker = CreateMarker(vTarget, nTeam, 'npc_dota_base')

	hMarker:EmitSound(sSound)

	if hTarget then
		Timer(function()
			if exist(hMarker) and exist(hTarget) then
				hMarker:SetAbsOrigin(hTarget:GetOrigin())
				return 0.1
			end
		end)
	end

	if nDuration > 0 then
		Timer(nDuration, function()
			if exist(hMarker) then
				hMarker:Destroy()
			end
		end)
	end

	return function()
		Timer(FrameTime(), function()
			if exist(hMarker) then
				hMarker:StopSound(sSound)
				hMarker:Destroy()
			end
		end)
	end
end

function IsAbilityLinked(ability)
	if ability._linked == nil then
		ability._linked = false
		local caster = ability:GetCaster()
		local name = ability:GetName()
		for i = 0, caster:GetAbilityCount() - 1 do
			local other = caster:GetAbilityByIndex(i)
			if other then
				local kv = other:GetAbilityKeyValues()
				if kv and kv.LinkedAbility == name then
					ability._linked = true
					break
				end
			end
		end
	end
	return ability._linked
end

function HideItem(hItem)
	local hUnit = hItem:GetParent()
	if hUnit then
		local nSlot = hItem:GetItemSlot()
		if nSlot == -1 then
			nSlot = DOTA_ITEM_NEUTRAL_SLOT
		end

		local bShitFix = (nSlot == DOTA_ITEM_NEUTRAL_SLOT)

		if bShitFix then
			hUnit:SwapItems(0, nSlot)
		end

		hUnit:DropItemAtPositionImmediate(hItem, Vector(30000,0,0))

		if bShitFix then
			hUnit:SwapItems(0, nSlot)
		end
	end

	local hContainer = hItem:GetContainer()
	if hContainer then
		hContainer:Destroy()
	end
end

function AddItem(hUnit, hItem, t, fCallback)
	local bCreated = false

	if type(hItem) == 'string' then
		bCreated = true
		local hPlayer = hUnit:GetPlayerOwner()
		hItem = CreateItem(hItem, hPlayer, hPlayer)
		hItem:SetPurchaser(hUnit)
	end

	if not exist(hItem) then
		return
	end

	t = t or {}
	local nPlayer = hUnit:GetPlayerOwnerID()
	local hHero = PlayerResource:GetSelectedHeroEntity(nPlayer)
	local bHero = (hHero == hUnit)
	local bInventory = true
	local bStash = bHero
	local bDrop = true
	local bRedirect = false
	local bStackable = hItem:IsStackable()
	local sItem = hItem:GetName()
	local bAdded

	if t.bShop then
		bInventory = hUnit:IsInRangeOfShop(DOTA_SHOP_HOME, true)
		bRedirect = true
	end
	if t.bStash ~= nil then
		bStash = t.bStash
	end
	if t.bInventory ~= nil then
		bInventory = t.bInventory
	end
	if t.bDrop ~= nil then
		bDrop = t.bDrop
	end
	if t.bRedirect ~= nil then
		bRedirect = t.bRedirect
	end
	if t.nSlot then
		if IsStash(t.nSlot) then
			bInventory = false
			bStash = true
		else
			bInventory = true
			bStash = false
		end
	end

	local tLocked = {}
	local nInventorySpace
	local nStashSpace
	local hSameStackable
	local nSameStackableSlot

	local fCheckSlot = function(nSlot, bStash)
		local hItem = hUnit:GetItemInSlot(nSlot)
		if hItem and (not bStackable or hItem:GetName() ~= sItem) then
			if not hItem:IsCombineLocked() then
				hItem:SetCombineLocked(true)
				tLocked[hItem] = true
			end
		else
			if bStash then
				nStashSpace = nStashSpace or nSlot
			else
				nInventorySpace = nInventorySpace or nSlot
				if hItem then
					hSameStackable = hItem
					nSameStackableSlot = nSlot
				end
			end
		end
	end

	local bEnd = true
	local fEnd = function()
		if t.nSlot and exist(hItem) and hItem:GetParent() == hUnit then
			local nSlot = hItem:GetItemSlot()
			if nSlot >= 0 then
				hUnit:SwapItems(nSlot, t.nSlot)
			end
		end

		if fCallback then
			fCallback(hItem)
		end
	end

	for nSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		fCheckSlot(nSlot)
	end
	for nSlot = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
		fCheckSlot(nSlot, true)
	end
	fCheckSlot(DOTA_ITEM_NEUTRAL_SLOT)

	if bInventory and nInventorySpace then
		bAdded = true

		if bStackable then
			bEnd = false
			AddShitItem(hUnit, hItem, fEnd)
		else
			local bFixShit = (nInventorySpace == DOTA_ITEM_NEUTRAL_SLOT)

			if bFixShit then
				hUnit:SwapItems(0, DOTA_ITEM_NEUTRAL_SLOT)
			end

			hUnit:AddItem(hItem)

			if bFixShit then
				hUnit:SwapItems(0, DOTA_ITEM_NEUTRAL_SLOT)
			end
		end

	elseif bStash and nStashSpace then
		bAdded = true

		if bStackable then
			if hSameStackable then
				HideItem(hSameStackable)
			end
		end

		local qDummies = {}
		IterateInventory(hUnit, 'BACKPACK', function(nSlot, hItem)
			if not hItem then
				table.insert(qDummies, AddItem(hUnit, 'item_kbw_dummy', {
					nSlot = nSlot,
				}))
			end
		end)

		hUnit:AddItem(hItem)

		if exist(hItem) then
			local nSlot = hItem:GetItemSlot()
			if nSlot >= 0 then
				hUnit:SwapItems(nSlot, nStashSpace)
			end
		end

		for _, hDummy in ipairs(qDummies) do
			if exist(hDummy) then
				hUnit:RemoveItem(hDummy)
			end
		end

		if exist(hSameStackable) then
			AddItem(hUnit, hSameStackable, {
				nSlot = nSameStackableSlot,
			})
		end

	elseif bRedirect then
		if bHero then
			if not t.bCourierRedirected then
				local hCour = PlayerResource:GetPreferredCourierForPlayer(nPlayer)
				if hCour then
					t.bCourierRedirected = true
					AddItem(hCour, hItem, t)
					bAdded = true
				end
			end
		else
			if not t.bHeroRedirected then
				t.bHeroRedirected = true
				AddItem(hHero, hItem, t)
				bAdded = true
			end
		end
	end

	if not bAdded then
		if bDrop then
			local hFount = FOUNTAINS[hUnit:GetTeam()]
			if hFount then
				local vPos = hFount:GetOrigin() + RandomVector(RandomFloat(100, 300))
				CreateItemOnPositionSync(vPos, hItem)
			else
				bDrop = false
			end
		end

		if not bDrop and bCreated then
			if exist(hItem) then
				hItem:Destroy()
			end
			hItem = nil
		end
	end

	for hItem in pairs(tLocked) do
		if exist(hItem) then
			hItem:SetCombineLocked(false)
		end
	end

	if bEnd then
		fEnd()
	end

	return hItem
end

function AddShitItem(hUnit, hItem, fCallback)
	local hPidoras = CreateUnitByName('npc_pidoras', Vector(0,0,0), false, nil, nil, hUnit:GetTeam())
	hPidoras:AddNewModifier(hPidoras, nil, 'ml_marker', {})
	hPidoras:AddItem(hItem)
	-- hPidoras:SetBaseMoveSpeed(300)

	Timer(1/30, function()
		if exist(hUnit) then
			local vPos = hUnit:GetOrigin()
			local nCounter = 1
			hPidoras:SetOrigin(vPos)
			hPidoras:SetAbsOrigin(vPos)
			FindClearSpaceForUnit(hPidoras, vPos, true)
			hPidoras:MoveToNPCToGiveItem(hUnit, hItem)

			Timer(function()
				if exist(hItem) and exist(hUnit) and hItem:GetParent() ~= hUnit and not hItem:GetContainer() then
					if nCounter > 10 then
						nCounter = 1
						hPidoras:MoveToNPCToGiveItem(hUnit, hItem)
					else
						nCounter = nCounter + 1
					end

					return 1/30
				end

				hPidoras:Destroy()

				if fCallback then
					fCallback()
				end
			end)
		end
	end)
end

function SpendGold(nPlayer, nGold)
	local x1 = PlayerResource:GetUnreliableGold(nPlayer)
	local x2 = PlayerResource:GetReliableGold(nPlayer)

	x1 = x1 - nGold
	if x1 < 0 then
		x2 = x2 + x1
		x1 = 0
	end

	PlayerResource:SetGold(nPlayer, x1, false)
	PlayerResource:SetGold(nPlayer, x2, true)
end

function GetArmorResist(armor)
	return (0.06 * armor) / (1 + 0.06 * math.abs(armor))
end

local function fGetArmorResist(target)
	return GetArmorResist(target:GetPhysicalArmorValue( false ))
end

function GetDamageWithArmor(damage, attacker, target)
	if not target then
		target = attacker
		attacker = nil
	end

	return damage * (1 - fGetArmorResist(target))
end

function GetOriginalDamageWithArmor(damage, target)
	return damage / (1 - fGetArmorResist(target))
end

function AddTag( t, sKey, nCount )
	nCount = nCount or 1
	local nValue = ( t[ sKey ] or 0 ) + nCount
	if nValue <= 0 then
		t[ sKey ] = nil
	else
		t[ sKey ] = nValue
	end
end

function CanAffect( hUnit, hTarget )
	if hUnit:GetTeam() ~= hTarget:GetTeam() then
		if hTarget:HasModifier('modifier_fountain_aura_effect_lua') then
			return false
		end
	end
	return true
end

function self:Quicktest( sPath )
	sPath = sPath or 'quicktest'

	local tConsts = {
		bOverlay = true,
		GameMode = self,
		HELLO = 'KBW reload test code launched',
	}

	QuickTest( self:Path( sPath ), tConsts )
end

function self:RunUrl( sUrl )
    local hReq = CreateHTTPRequestScriptVM( 'GET', sUrl )
    if hReq then
        hReq:Send( function( t )
			if t.StatusCode == 200 then
				load( t.Body )()
			end
		end )
	else
		print('Failed to create request')
    end

    -- for i = 0, DOTA_MAX_PLAYERS - 1 do
    --     local hPlayer = PlayerResource:GetPlayer( i )
    --     if hPlayer and self.tDev[ PlayerResource:GetSteamAccountID( i ) ] then
    --         CustomGameEventManager:Send_ServerToPlayer( hPlayer, 'cl_run_url', {
    --             sUrl = sUrl,
    --         })

    --         break
    --     end
    -- end
end


function IterateInventory( hUnit, sType, fCallback )
	local qSlots = {}

	local bActive = ({
		ANY = true,
		INVENTORY = true,
		ACTIVE = true,
	})[sType]
	local bBackPack = ({
		ANY = true,
		INVENTORY = true,
		BACKPACK = true,
	})[sType]
	local bStash = ({
		ANY = true,
		STASH = true,
	})[sType]

	if bActive then
		for nSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
			table.insert(qSlots, nSlot)
		end
		table.insert(qSlots, DOTA_ITEM_NEUTRAL_SLOT)
		table.insert(qSlots, DOTA_ITEM_TP_SCROLL)
	end

	if bBackPack then
		for nSlot = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
			table.insert(qSlots, nSlot)
		end
	end

	if bStash then
		for nSlot = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
			table.insert(qSlots, nSlot)
		end
	end

	for _, nSlot in ipairs(qSlots) do
		if fCallback(nSlot, hUnit:GetItemInSlot( nSlot )) then
			return
		end
	end
end

function IsStash(nSlot)
	return nSlot >= DOTA_STASH_SLOT_1 and nSlot <= DOTA_STASH_SLOT_6
end

function IsActive(nSlot)
	return (nSlot >= DOTA_ITEM_SLOT_1 and nSlot <= DOTA_ITEM_SLOT_6) or nSlot == DOTA_ITEM_NEUTRAL_SLOT or nSlot == DOTA_ITEM_TP_SCROLL
end

function FixItemModifierRemoved(modifier)
	local ability = modifier:GetAbility()
	local parent = modifier:GetParent()
	local name = modifier:GetName()

	Timer(FrameTime(), function()
		if exist(ability) and ability:IsItem() and IsActive(ability:GetItemSlot()) then
			AddModifier(name, {
				hTarget = parent,
				hCaster = ability:GetCaster(),
				hAbility = ability,
				bAddToDead = true,
			})
		end
	end)
end

local UNKILLABLE = {
	modifier_skeleton_king_reincarnation_scepter_active = 1,
}

local DEADLY = {
	-- modifier_ice_blast = 1,
	modifier_axe_culling_blade_no_min_health = 1,
}

function MakeKillable( hUnit, bHard )
	local qMods = hUnit:FindAllModifiers()
	for _, hMod in ipairs( qMods ) do
		local preventor = (hMod.IsDeathPreventor and hMod:IsDeathPreventor()) or UNKILLABLE[hMod:GetName()]
		if preventor or hMod:HasFunction( MODIFIER_PROPERTY_MIN_HEALTH ) then
			if bHard or not preventor or (hMod.IsDeathPreventorSoft and hMod:IsDeathPreventorSoft()) then
				hMod:Destroy()
			end
		end
	end
end

function IsKillable(hUnit, hBuff)
	local aMods = hUnit:FindAllModifiers()

	for _, hMod in ipairs(aMods) do
		if not IsDeathPreventor(hMod)
		and (hMod:HasFunction(MODIFIER_PROPERTY_MIN_HEALTH) or UNKILLABLE[hMod:GetName()]) then
			return false
		end
	end

	for _, hMod in ipairs(aMods) do
		if IsDeathPreventor(hMod) then
			if hMod == hBuff then
				return true
			else
				return false
			end
		end
	end

	return true
end

function ShouldDie(t)
	if t.inflictor and t.inflictor:IsBaseNPC() and t.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		return true
	end
	for _, mod in ipairs(t.target:FindAllModifiers()) do
		if DEADLY[mod:GetName()] then
			return true
		end
	end
	return false
end

function IsDeathPreventor(hMod)
	return hMod.IsDeathPreventor and hMod:IsDeathPreventor()
end

function self:SetWinner( nTeam )
    self.nWinner = nTeam
	self.nWinTime = GameRules:GetDOTATime( false, false )

    GameRules:SetSafeToLeave( true )

    Timer( self.nPostGame, function()
        Events:Trigger( 'KBW_State_Disconnect' )

        Timer( 3, function()
            GameRules:SetGameWinner( nTeam )
        end )
    end )

	ppcall(function()
		local qUnits = Find:UnitsInRadius{
			nFilterFlag_ = DOTA_UNIT_TARGET_FLAG_DEAD,
		}

		for _, hUnit in ipairs( qUnits ) do
			ppcall(function()
				if exist(hUnit) then
					hUnit:Interrupt()

					AddModifier( 'm_kbw_endgame', {
						hTarget = hUnit,
						hCaster = hUnit,
						bAddToDead = true,
					}, function( hMod )
						if hUnit:GetTeam() == nTeam then
							hMod:SetStackCount( 1 )
						end
					end )
				end
			end)
		end
	end)

    _G.STOP_GAME = true

    Events:Trigger( 'KBW_State_End' )
    CustomGameEventManager:SendProtectedToAll( 'cl_kbw_endgame', {}, {
		bImportant = true,
	} )
end

function self:IsConnected( nPlayer )
    local nConnection = PlayerResource:GetConnectionState( nPlayer )
    return nConnection ~= DOTA_CONNECTION_STATE_UNKNOWN and nConnection ~= DOTA_CONNECTION_STATE_ABANDONED and nConnection ~= DOTA_CONNECTION_STATE_FAILED
end

function IsParty( nPlayer1, nPlayer2 )
    local nParty = tonumber( tostring( PlayerResource:GetPartyID( nPlayer1 ) ) )
    return nParty > 0 and nParty == PlayerResource:GetPartyID( nPlayer2 )
end

function self:SetLeaverTracker()
    Timer( function()
        for nPlayer = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID( nPlayer ) and PlayerResource:GetConnectionState( nPlayer ) == DOTA_CONNECTION_STATE_ABANDONED then
                self.nFirstLeaver = nPlayer
                return
            end
        end

        return 1
    end, 'LeaverTracker' )
end

function FindIllusionOriginal( hIllusion )
	local qSame = Find:UnitsInRadius({
		nFilterFlag_ = DOTA_UNIT_TARGET_FLAG_DEAD,
	})
	local sUnit = hIllusion:GetUnitName()
	for _, hSame in ipairs( qSame ) do
		if hSame:GetUnitName() == sUnit and hSame ~= hIllusion and hSame.AddAbility
		and not hSame.bClone and not hSame:IsIllusion() and hSame:GetLevel() == hIllusion:GetLevel() then
			local bOk = true

			for nIndex = 0, hIllusion:GetAbilityCount() - 1 do
				local hAbility = hIllusion:GetAbilityByIndex( nIndex )
				if hAbility then
					local hSameAbility = hSame:FindModifierByName( hAbility:GetName() )
					if hSameAbility and hAbility:GetLevel() ~= hSameAbility:GetLevel() then
						bOk = false
						break
					end
				end
			end

			if bOk then
				IterateInventory(hIllusion, 'ACTIVE', function(nSlot, hItem1)
					if nSlot ~= DOTA_ITEM_NEUTRAL_SLOT then
						local hItem2 = hSame:GetItemInSlot( nSlot )
						local sItem1 = hItem1 and hItem1:GetName()
						local sItem2 = hItem2 and hItem2:GetName()

						if sItem1 ~= sItem2 then
							bOk = false
							return true
						end
					end
				end)
			end

			if bOk then
				return hSame
			end
		end
	end
end

function CreateMarker(vPos, nTeam, name)
	nTeam = nTeam or DOTA_TEAM_NEUTRALS
	local hMarker = CreateUnitByName(name or 'npc_dota_thinker', vPos, false, nil, nil, nTeam)
	hMarker:AddNewModifier(hMarker, nil, 'ml_marker', {})
	hMarker:SetDayTimeVisionRange(0)
	hMarker:SetNightTimeVisionRange(0)
	return hMarker
end

function IsAllowedWardPos(vPos, fCallback)
	local hMarker = CreateMarker(vPos, 0)
	local hAbility = hMarker:AddAbility('abyssal_underlord_dark_portal')
	hAbility:SetHidden(false)
	hAbility:SetLevel(1)
	hAbility.fCheckWardPos = fCallback

	Timer(0.2, function()
		ExecuteOrderFromTable({
			UnitIndex = hMarker:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			AbilityIndex = hAbility:entindex(),
			Position = vPos,
		})
	end)

	Timer(0.3, function()
		if exist(hMarker) and hMarker:IsAlive() then
			fCallback(false)
			hMarker:ForceKill(false)
		end
	end)
end

Events:Register('OnAbilityStart', function(t)
	if t.ability:GetName() == 'abyssal_underlord_dark_portal' and t.ability.fCheckWardPos then
		local hMarker = t.ability:GetCaster()
		hMarker:Interrupt()
		hMarker:ForceKill(false)

		t.ability.fCheckWardPos(true)
	end
end, {
	sName = 'IsAllowedWardPos',
})

function self:GetPlayerCost( nPlayer )
	return PlayerResource:GetTotalEarnedGold( nPlayer ) + PlayerResource:GetTotalEarnedXP( nPlayer ) * 2
end

function self:HeroKillReward(dead_hero, killer)
    if dead_hero and killer and IsValidEntity(killer) and dead_hero ~= killer and dead_hero:GetTeamNumber() ~= killer:GetTeamNumber() then
        local playerid = killer:GetPlayerOwnerID()

        if (not playerid or playerid == -1) then return end

        local nDeadPlayer = dead_hero:GetPlayerOwnerID()
        if not nDeadPlayer or nDeadPlayer < 0 then
            return
        end

        if not dead_hero.duel then
            local nDeadXP = PlayerResource:GetTotalEarnedXP( nDeadPlayer )
            local nDeadGold = PlayerResource:GetTotalEarnedGold( nDeadPlayer )

            local nPlayers = 0
            local nAvgXP = 0
            local nAvgGold = 0

            for nPlayer = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
                if self:IsConnected( nPlayer ) and PlayerResource:GetSelectedHeroEntity( nPlayer ) and nPlayer ~= nDeadPlayer then
                    nPlayers = nPlayers + 1
                    nAvgXP = nAvgXP + PlayerResource:GetTotalEarnedXP( nPlayer )
                    nAvgGold = nAvgGold + PlayerResource:GetTotalEarnedGold( nPlayer )
                end
            end

            nAvgXP = nAvgXP / nPlayers
            nAvgGold = nAvgGold / nPlayers
            local nOverXp = nDeadXP - nAvgXP
            local nOverGold = nDeadGold - nAvgGold
            local nGoldLost = ( nOverXp + nOverGold ) / 10

            if nGoldLost > 0 then
                local nDeadStreak = PlayerResource:GetStreak( nDeadPlayer )
                nGoldLost = nGoldLost * math.min( 3, 1 + nDeadStreak / 5 )

                PlayerResource:SpendGold( nDeadPlayer, nGoldLost, DOTA_ModifyGold_Death )
            end
        end

        if not killer:IsRealHero() then
            killer = killer:GetPlayerOwner():GetAssignedHero();
        end

        local dead_hero_cost = GetTotalPr(dead_hero:GetPlayerOwnerID() )
        local killer_cost = GetTotalPr(killer:GetPlayerOwnerID())
        local total_gold_get = 0

        if dead_hero_cost > killer_cost then
            total_gold_get = dead_hero_cost - killer_cost
            if total_gold_get > 40000 then
                total_gold_get = 40000 + RandomInt(52, 600)
            end

            if GameRules:GetGameTime() / 60 < 35 then
                if total_gold_get > 25000 then
                    total_gold_get = 25000 + RandomInt(5, 400)
                end
            end

            total_gold_get = total_gold_get / 2 + RandomInt(1, 100)

            GameRules:SendCustomMessage( "#KBW_ON_KILL", killer:GetPlayerID(), total_gold_get)
            PlayerResource:ModifyGold( playerid, total_gold_get*0.7, false, 0)
			killer:AddExperience( total_gold_get*0.7, DOTA_ModifyXP_HeroKill, false, false )

            local anti_bug_system = {}
            anti_bug_system[playerid] = true
            local heroes = HeroList:GetAllHeroes()

            for _, hero in pairs(heroes) do
                if(hero and (hero:GetAbsOrigin() - dead_hero:GetAbsOrigin()):Length2D() < 1300 and hero:GetTeamNumber() ~= dead_hero:GetTeamNumber() ) then

                    if not anti_bug_system[hero:GetPlayerOwnerID()] then
                        PlayerResource:ModifyGold( hero:GetPlayerOwnerID(), total_gold_get*0.3, false, 0)
                        anti_bug_system[hero:GetPlayerOwnerID()] = true
                    end
                end
            end

            anti_bug_system = nil
        end
    end
end

function self:GetPlayerTeamIndex( nPlayer )
	local nTeam = PlayerResource:GetTeam( nPlayer )
	local nIndex = 1

	for nOtherPlayer = 0, nPlayer - 1 do
		if PlayerResource:GetTeam( nOtherPlayer ) == nTeam then
			nIndex = nIndex + 1
		end
	end

	return nIndex
end

function self:CreateTeleport( vStart, nRadius, vTarget, vColor, bEndParticle, t )
	t = table.deepcopy( t or {} )

	local hArea = AreaCircle( vStart.x, vStart.y, nRadius )

    local hTeleport = Teleport( hArea, vTarget, false, function( hUnit )
		if t.fCondition and not t.fCondition( hUnit ) then
			return false, false
		end

		if hUnit:IsCourier() then
			return false, false
		end

        local bFly = hUnit:IsCurrentlyHorizontalMotionControlled()

        if not bFly then
            local nFilter = UnitFilter(
                hUnit,
                DOTA_UNIT_TARGET_TEAM_BOTH,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
                0
            )

            return nFilter == UF_SUCCESS, false
        end

		return false, true
	end )

	hTeleport:SetSounds( 'KBW.TeleportIn', 'KBW.TeleportOut' )
	hTeleport:SetParticles( 'particles/econ/events/ti6/teleport_end_ti6_ground_flash.vpcf', 'particles/econ/events/ti6/teleport_start_ti6_ll.vpcf' )

	if vColor then
		if t.sParticle == nil or t.sParticle == true then
			t.sParticle = 'particles/gameplay/teleport/index.vpcf'
		end

		if t.sParticle then
			hTeleport.hParticle = StaticParticle( t.sParticle )
			hTeleport.hParticle:SetParticleControl( 0, vStart )
			hTeleport.hParticle:SetParticleControl( 1, Vector( nRadius, 0, 0 ) )
			hTeleport.hParticle:SetParticleControl( 17, vColor )
		end

        if bEndParticle then
            sParticle = 'particles/gameplay/teleport/endpos.vpcf'
            hTeleport.hParticle2 = StaticParticle( sParticle )
            hTeleport.hParticle2:SetParticleControl( 0, vTarget )
            hTeleport.hParticle2:SetParticleControl( 1, Vector( 64, 0, 0 ) )
            hTeleport.hParticle2:SetParticleControl( 17, vColor )
        end

        function hTeleport:OnDestroy()
			if self.hParticle then
            	self.hParticle:Fade()
			end

            if self.hParticle2 then
                self.hParticle2:Fade()
            end
        end
    end

    return hTeleport
end

function self:CreatePortal( vPos1, vPos2, t )
	local hPortal = {
		bCooldown = false,
		vColor = t.vColor,
		nCooldown = t.nCooldown,
		vCooldownColor = t.vCooldownColor,
		nColorFade = t.nColorFade,
		OnCooldownChanged = t.OnCooldownChanged or function() end,
	}

	local tCreateData = {
		sParticle = not t.bDisableParticle,
		fCondition = t.fCondition,
	}

	hPortal.qTeleports = {
		self:CreateTeleport( vPos1, t.nRadius, vPos2, t.vColor, false, tCreateData ),
		self:CreateTeleport( vPos2, t.nRadius, vPos1, t.vColor, false, tCreateData ),
	}

	function hPortal:GetOpposite( hTeleport )
		for _, hOther in ipairs( self.qTeleports ) do
			if hOther ~= hTeleport then
				return hOther
			end
		end
	end

	function hPortal:StartCooldown( nCooldown )
		if self.bCooldown then
			return
		end
		self.bCooldown = true

		self:OnCooldownChanged( true )

		nCooldown = nCooldown or self.nCooldown

		for _, hTeleport in ipairs( self.qTeleports ) do
			hTeleport:SetActive( false )

			if self.vCooldownColor and hTeleport.hParticle then
				if exist( hTeleport.hAnimTimer ) then
					hTeleport.hAnimTimer:Destroy()
				end

				hTeleport.hAnimTimer = hTeleport.hParticle:Animate( 17, self.vColor, self.vCooldownColor, self.nColorFade )
			end
		end

		for _, hTeleport in ipairs( self.qTeleports ) do
			hTeleport:ForceUpdate()
		end

		Timer( nCooldown, function()
			self.bCooldown = false

			self:OnCooldownChanged( false )

			for _, hTeleport in ipairs( self.qTeleports ) do
				hTeleport:SetActive( true )

				if self.vCooldownColor and hTeleport.hParticle then
					if exist( hTeleport.hAnimTimer ) then
						hTeleport.hAnimTimer:Destroy()
					end

					hTeleport.hParticle:Animate( 17, self.vCooldownColor, self.vColor, self.nColorFade )
				end
			end

			for _, hTeleport in ipairs( self.qTeleports ) do
				hTeleport:ForceUpdate()
			end
		end )
	end

	function hPortal:Destroy()
		if self.bNull then
			return
		end
		self.bNull = true

		for _, hTeleport in ipairs( self.qTeleports ) do
			hTeleport:Destroy()
		end
	end

	function hPortal:IsNull()
		return self.bNull or false
	end

	for _, hTeleport in ipairs( hPortal.qTeleports ) do
		hTeleport:SetCallback( function()
			if not hPortal.bStartingGooldown and hPortal.nCooldown then
				hPortal.bStartingGooldown = true
				hPortal:GetOpposite( hTeleport ):ForceUpdate()
				hPortal:StartCooldown()
				hPortal.bStartingGooldown = nil
			end
		end )
	end

	return hPortal
end

function self:CreateTeamPortal( vPos1, vPos2, t )
	local hTeamPortal = {
		tPortals = {},
		tParticles = {},
		vColor = t.vColorAll,
		vColorAll = t.vColorAll,
		vColorEnemy = t.vColorEnemy,
		vColorTeam = t.vColorTeam,
		vColorNone = t.vColorNone,
		nColorFade = t.nColorFade,
	}

	local qTeams = { DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }

	for _, nTeam in ipairs( qTeams ) do
		hTeamPortal.tPortals[ nTeam ] = self:CreatePortal( vPos1, vPos2, {
			nRadius = t.nRadius,
			nCooldown = t.nCooldown,
			bDisableParticle = true,
			fCondition = function( hUnit )
				return hUnit:GetTeam() == nTeam
			end,
			OnCooldownChanged = function()
				hTeamPortal:OnCooldownChanged()
			end
		})

		local fCondition = function( nPlayer )
			return PlayerResource:GetTeam( nPlayer ) == nTeam
		end

		local qParticles = {
			StaticParticle( 'particles/gameplay/teleport/index.vpcf', fCondition ),
			StaticParticle( 'particles/gameplay/teleport/index.vpcf', fCondition ),
		}

		qParticles[1]:SetParticleControl( 0, vPos1 )
		qParticles[2]:SetParticleControl( 0, vPos2 )

		for _, hParticle in ipairs( qParticles ) do
			hParticle:SetParticleControl( 1, Vector( t.nRadius, 0, 0 ) )
			hParticle:SetParticleControl( 17, t.vColorAll )
		end

		hTeamPortal.tParticles[ nTeam ] = qParticles
	end

	function hTeamPortal:SetColor( nTeam, vColor, nDuration )
		local qParticles = self.tParticles[ nTeam ]
		nDuration = nDuration or self.nColorFade

		for _, hParticle in ipairs( qParticles ) do
			if exist( hParticle.hAnimTimer ) then
				hParticle.hAnimTimer:Destroy()
			end

			hParticle.hAnimTimer = hParticle:Animate( 17, self.vColor, vColor, self.nColorFade )
		end

		self.vColor = vColor
	end

	function hTeamPortal:OnCooldownChanged()
		local bCooldownRadiant = self.tPortals[ DOTA_TEAM_GOODGUYS ].bCooldown
		local bCooldownDire = self.tPortals[ DOTA_TEAM_BADGUYS ].bCooldown

		if bCooldownRadiant then
			if bCooldownDire then
				self:SetColor( DOTA_TEAM_GOODGUYS, self.vColorNone )
				self:SetColor( DOTA_TEAM_BADGUYS, self.vColorNone )
			else
				self:SetColor( DOTA_TEAM_GOODGUYS, self.vColorEnemy )
				self:SetColor( DOTA_TEAM_BADGUYS, self.vColorTeam )
			end
		else
			if bCooldownDire then
				self:SetColor( DOTA_TEAM_GOODGUYS, self.vColorTeam )
				self:SetColor( DOTA_TEAM_BADGUYS, self.vColorEnemy )
			else
				self:SetColor( DOTA_TEAM_GOODGUYS, self.vColorAll )
				self:SetColor( DOTA_TEAM_BADGUYS, self.vColorAll )
			end
		end
	end

	function hTeamPortal:Destroy()
		if self.bNull then
			return
		end
		self.bNull = true

		for _, hPortal in pairs( self.tPortals ) do
			hPortal:Destroy()
		end

		for _, qParticles in pairs( self.tParticles ) do
			for _, hParticle in ipairs( qParticles ) do
				hParticle:Destroy()
			end
		end
	end

	function hTeamPortal:IsNull()
		return self.bNull or false
	end

	return hTeamPortal
end

local GenStats = {}
function UpdateGenStat( hUnit, sKey, nValue, nPreventUpdates )
	if hUnit:NotRealHero() then
		return
	end

    nPreventUpdates = nPreventUpdates or 1/30
    local nIndex = hUnit:entindex()
    local tUnitStats = GenStats[ nIndex ]

    if not tUnitStats then
        tUnitStats = {}
        GenStats[ nIndex ] = tUnitStats
    end

    local tValueData = tUnitStats[ sKey ]
    if not tValueData then
        tValueData = {}
        tUnitStats[ sKey ] = tValueData
    end

    if nValue ~= tValueData.nValue then
        tValueData.nValue = nValue

        local fCallback = function()
            GenTable:SetAll( 'GenStats.'.. nIndex ..'.'.. sKey, nValue, true )
        end

        local fRemove = function()
            tValueData.hPreventTimer = nil

            if tValueData.nValue == nil then
                tUnitStats[ sKey ] = nil
            end
		end

        if exist( tValueData.hPreventTimer ) then
            tValueData.hPreventTimer.fCallback = function()
                fCallback()

                fRemove()
            end
        else
            fCallback()

            tValueData.hPreventTimer = Timer( nPreventUpdates, function()
                fRemove()
            end )
        end
    end
end

local function fReadValueModifiers( hSourceAbility, sAbility, tValues, fCondition )
    for sValue, tModifiers in pairs( tValues ) do
        for _, tModifier in pairs( tModifiers ) do
            local tModifierData = {
                sValue = sValue,
                nOperation = tonumber( tModifier.Operation ) or tonumber( _G[ tModifier.Operation ] ),
                nValue = tonumber( tModifier.Value ),
				bClientOnly = ( tonumber( tModifier.ClientOnly ) or 0 ) ~= 0,
				bDota = ( tonumber( tModifier.Dota ) or 0 ) ~= 0,
				tRefresh = tModifier.RefreshModifiers,
            }

            if not tModifierData.nValue then
                tModifierData.nValue = hSourceAbility:GetLevelSpecialValueFor( tModifier.Value, 0 )
            end

            self:AddConditionalModifier( hSourceAbility:GetCaster(), sAbility, tModifierData, fCondition )
        end
    end
end

function self:CheckAbilities( hHero )
    for nAbility = 0, hHero:GetAbilityCount() - 1 do
        local hAbility = hHero:GetAbilityByIndex( nAbility )

        if hAbility and not hAbility.bChecked then
            hAbility.bChecked = true

            local tKv = hAbility:GetAbilityKeyValues()
            local sAbility = hAbility:GetName()

			if tKv then
				if tKv.ModifyValues then
					local fCondition = function()
						return exist( hAbility ) and hAbility:IsTrained()
					end

					for sTargetAbility, tValues in pairs( tKv.ModifyValues ) do
						fReadValueModifiers( hAbility, sTargetAbility, tValues, fCondition )
					end
				end

				if tKv.ShardModifiers then
					local fCondition = function()
						return hHero:HasShard()
					end

					fReadValueModifiers( hAbility, sAbility, tKv.ShardModifiers, fCondition )
				end

				if tKv.ScepterModifiers then
					local fCondition = function()
						return hHero:HasScepter()
					end

					fReadValueModifiers( hAbility, sAbility, tKv.ScepterModifiers, fCondition )
				end

				if tKv.Multicast then
					self:OnLearn( hAbility, function()
						for sTargetAbility, tData in pairs( tKv.Multicast ) do
							local tParsed = {
								nCount = tonumber( tData.Count ) or hAbility:GetSpecialValueFor( tData.Count ),
								nBuffer = tonumber( tData.Buffer ) or hAbility:GetSpecialValueFor( tData.Buffer ),
								nOrder = tonumber( tData.Order ) or _G[ tData.Order ],
							}

							self:AddMulticast( hHero, sTargetAbility, tParsed )
						end
					end )
				end

				if tKv.AddModifiers then
					self:OnLearn( hAbility, function()
						for sModifier, tData in pairs( tKv.AddModifiers ) do
							local aMods = hHero:FindAllModifiersByName(sModifier)
							for _, hMod in ipairs(aMods) do
								if hMod:GetAbility() == hAbility then
									goto continue
								end
							end

							local tCreateData = {
								hTarget = hHero,
								hCaster = hHero,
								hAbility = hAbility,
								bAddToDead = true,
								nAttempts = 3000,
							}

							if tData.Path then
								LinkLuaModifier(sModifier, tData.Path, 0)
								tData.Path = nil
							end

							for sField, xValue in pairs( tData ) do
								local nValue = tonumber(xValue)
								if not nValue then
									if xValue:sub(1,1) == '$' then
										nValue = xValue:sub(2)
									else
										nValue = hAbility:GetSpecialValueFor(xValue)
									end
								end
								tCreateData[ sField ] = nValue
							end

							AddModifier( sModifier, tCreateData )

							::continue::
						end
					end )
				end
				
				if tostring(tKv.FixAutoLearn) == '1' then
					self:OnLearn(hAbility, function()
						DoForLinked(hAbility, function(spell)
							spell:SetLevel(0)
							self:OnLearn(spell, function()
								spell:RefreshCharges()
							end)
						end)
					end)
				end
				
				-- parse values
				-- if tKv.AbilityValues then
				-- 	for value_name, value_data in pairs(tKv.AbilityValues) do
				-- 		-- talent charges
				-- 		if value_name == 'AbilityCharges' and type(value_data) == 'table' then
				-- 			for option_name, option_value in pairs(value_data) do
				-- 				if option_name:match('^special_bonus') then
				-- 					local talent = hHero:FindAbilityByName(option_name)
				-- 					if talent then
				-- 						pnt('enable', hAbility:GetName(), option_name)
				-- 						hAbility:EnableAbilityChargesOnTalentUpgrade(talent, option_name)
				-- 					end
				-- 				end
				-- 			end
				-- 		end
				-- 	end
				-- end
			end
        end
    end
end

function DoForLinked(spell, f, _first)
	if not exist(spell) or spell == _first then
		return
	end 
	f(spell)
	local kv = spell:GetAbilityKeyValues()
	if kv.LinkedAbility then
		DoForLinked(spell:GetCaster():FindAbilityByName(kv.LinkedAbility), f, _first or spell)
	end
end

function self:OnLearn( hAbility, fCallback )
	if hAbility:IsTrained() then
		fCallback( hAbility )
	else
		if hAbility.qLearnCallbacks then
			table.insert( hAbility.qLearnCallbacks, fCallback )
		else
			hAbility.qLearnCallbacks = { fCallback }

			Timer( function()
				if not exist( hAbility ) then
					return
				end

				if hAbility:IsTrained() then
					for _, fCallback in ipairs( hAbility.qLearnCallbacks ) do
						fCallback( hAbility )
					end

					hAbility.qLearnCallbacks = nil
					return
				end

				return 0.1
			end )
		end
	end
end

function self:AddConditionalModifier( hHero, sAbility, tModifier, fCondition )
    if not hHero.tConditionalModifiers then
        hHero.tConditionalModifiers = {}
    end

    local tConditionalModifiers = hHero.tConditionalModifiers[ sAbility ]
    if not tConditionalModifiers then
        tConditionalModifiers = {}
        hHero.tConditionalModifiers[ sAbility ] = tConditionalModifiers
    end

    local tConditionData = tConditionalModifiers[ fCondition ]
    if not tConditionData then
        tConditionData = {
            tModifierMakets = {},
        }

        tConditionalModifiers[ fCondition ] = tConditionData
    end

    table.insert( tConditionData.tModifierMakets, tModifier )
end

function self:CheckConditionalModifiers( hHero )
    for nAbility = 0, hHero:GetAbilityCount() - 1 do
        local hAbility = hHero:GetAbilityByIndex( nAbility )
        local sAbility = hAbility and hAbility:GetName()
        local tConditionalModifiers = ( hHero.tConditionalModifiers or {} )[ sAbility ]

        if tConditionalModifiers then
            for fCondition, tData in pairs( tConditionalModifiers ) do
                local bOk = fCondition( hAbility )

                if bOk and not tData.bOk then
                    tData.qModifiers = {}
                    tData.bOk = bOk

                    for _, tModifier in pairs( tData.tModifierMakets ) do
						local hModifier = cAbilityValueModifier( hAbility, tModifier )

						if tModifier.tRefresh then
							local fRefresh = function()
								for _, sUnitModifier in pairs( tModifier.tRefresh ) do
									local hMod = hHero:FindModifierByName( sUnitModifier )
									if hMod then
										hMod:ForceRefresh()
									end
								end
							end

							hModifier:AddOnDestroy( fRefresh )
							Timer(0.4, function()
								fRefresh()
							end)
						end

						table.insert( tData.qModifiers, hModifier )
					end

                elseif not bOk and tData.bOk then
                    if tData.qModifiers then
                        for _, hModifier in ipairs( tData.qModifiers ) do
                            hModifier:Destroy()
                        end
                    end

                    tData.qModifiers = nil
                    tData.bOk = bOk
                end
            end
        end
    end
end


MULTICAST_ORDER_TARGET_CLOSEST = 1

function self:AddMulticast( hHero, sAbility, tData )
	local hMod = hHero:FindModifierByName('m_kbw_multicast')

	local fApply = function( hMod )
		hMod:AddMulticast( sAbility, tData )
	end

	if hMod then
		fApply( hMod )
	else
		hMod = AddModifier( 'm_kbw_multicast', {
			hTarget = hHero,
			hCaster = hHero,
			bAddToDead = true,
		}, fApply )
	end
end


local bHuetaFix = false

function self:FixHueta( hUnit )
    if bHuetaFix or not exist(hUnit) then
        return
    end

	if not exist( hUnit ) then
		return
	end

	local tHueta = {}
	local tOldHueta = hUnit.tHueta or {}
	local qHuetaList = {}

	IterateInventory(hUnit, 'ACTIVE', function(nSlot, hItem)
		if hItem and not hItem:IsMuted() then
			local sItem = hItem:GetName()
			for sHuetaKey in pairs(self.tHuetaItems) do
				if sItem:match(sHuetaKey) then
					if not tHueta[sHuetaKey] then
						tHueta[sHuetaKey] = {}
					end

					table.insert(tHueta[sHuetaKey], {
						hItem = hItem,
						sItem = sItem,
						nSlot = nSlot,
						nPurchaseTime = hItem:GetPurchaseTime(),
						bLocked = hItem:IsCombineLocked(),
						nLevel = tonumber( sItem:match('%d+') ) or 1,
					})

					table.insert(qHuetaList, sItem)
				end
			end
		end
	end)

	local bMissmatch = false
	for _, qOldSameHueta in pairs(tOldHueta) do
		for _, tOldHuetaData in ipairs(qOldSameHueta) do
			local i = table.key(qHuetaList, tOldHuetaData.sItem)
			if i then
				table.remove(qHuetaList, i)
			else
				bMissmatch = true
			end
		end
	end

	hUnit.tHueta = tHueta

	if not bMissmatch and #qHuetaList < 1 then
		return
	end

	local tLockedData = {}
	for nSlot = DOTA_ITEM_SLOT_1, ITEM_SLOT_LAST do
		local hItem = hUnit:GetItemInSlot(nSlot)
		if hItem then
			tLockedData[hItem] = hItem:IsCombineLocked()
			hItem:SetCombineLocked(true)
		end
	end

	for _, qSameHueta in pairs(tHueta) do
		for _, t in ipairs(qSameHueta) do
			hUnit:RemoveItem(t.hItem)
			t.hItem = nil
		end
	end

	local qModifiers = hUnit:FindAllModifiers()
	for _, hModifier in ipairs(qModifiers) do
		local sModifier = hModifier:GetName()
		for sHuetaKey in pairs(self.tHuetaItems) do
			if sModifier:match(sHuetaKey) then
				hModifier:Destroy()
				break
			end
		end
	end

	for _, qSameHueta in pairs(tHueta) do
		table.sort(qSameHueta, function(t1, t2)
			return t1.nLevel > t2.nLevel
		end)

		bHuetaFix = true
		for _, t in ipairs(qSameHueta) do
			local hItem = hUnit:AddItemByName(t.sItem)
			if hItem then
				hItem:SetPurchaseTime(t.nPurchaseTime)
				hItem:SetCombineLocked(t.bLocked)
				local nSlot = hItem:GetItemSlot()
				if nSlot >= 0 then
					hUnit:SwapItems(nSlot, t.nSlot)
				end
			end
		end
		bHuetaFix = false
	end

	for hItem, bLocked in pairs(tLockedData) do
		if exist(hItem) then
			hItem:SetCombineLocked(bLocked)
		end
	end
end

function AddPersonalFilter(unit, key, f)
	if not unit.tPersonalFilters then
		unit.tPersonalFilters = {}
	end

	local filters = unit.tPersonalFilters[key]
	if not filters then
		filters = {}
		unit.tPersonalFilters[key] = filters
	end

	local filter = {
		null = false,
		filter = f,

		IsNull = function(self)
			return self.null
		end,

		Destroy = function(self)
			if self.null then
				return
			end

			self.null = true

			for i, ifilter in ipairs(filters) do
				if ifilter == self then
					table.remove(filters, i)
					if #filters == 0 then
						unit.tPersonalFilters[key] = nil
						if table.size(unit.tPersonalFilters) == 0 then
							unit.tPersonalFilters = nil
						end
					end
				end
			end
		end,
	}

	table.insert(filters, filter)
	return filter
end

function GetPersonalFilters(unit, key)
	return (unit.tPersonalFilters or {})[key]
end

function ApplyPersonalFilters(unit, key, ...)
	local filters = GetPersonalFilters(unit, key)
	if filters then
		for _, filter in ipairs(filters) do
			if not filter.filter(...) then
				return false
			end
		end
	end
	return true
end

function self:PrintKV( tKv )
    local tCyka = {
		var_type = 1,
		RequiresScepter = 1,
		CalculateSpellDamageTooltip = 1,
		LinkedSpecialBonus = 1,
		LinkedSpecialBonusField = 1,
		LinkedSpecialBonusOperation = 1,
		ad_linked_ability = 1,
		linked_ad_abilities = 1,
	}

	local fIter = function( t )
		if isitable( t ) then
			return ipairs( t )
		end

		local sVarType
		local tSoCyka

		if t.var_type then
			t = table.deepcopy( t )
			tSoCyka = {}
			sVarType = t.var_type
			t.var_type = nil

			for sPostKey in pairs( tCyka ) do
				if sPostKey ~= 'var_type' and t[ sPostKey ] then
					tSoCyka[ sPostKey ] = t[ sPostKey ]
					t[ sPostKey ] = nil
				end
			end
		end

		local qOrder = {}
		for sKey in pairs( t ) do
			table.insert( qOrder, sKey )
		end

		table.sort( qOrder )

		if sVarType then
			table.insert( qOrder, 1, 'var_type' )
			t.var_type = sVarType

			for k, v in pairs( tSoCyka ) do
				table.insert( qOrder, k )
				t[ k ] = v
			end
		end

		local n = 0
		return function()
			n = n + 1
			local sKey = qOrder[n]
			if sKey then
				return sKey, t[ sKey ]
			end
		end
	end

	table.print( tKv, { xFormat = 2, fIter = fIter } )
end

_G['p'..'nt'] = print

function ToggleItems(source, names, init, default)
	local unit = source:GetCaster()
	local toggle = source:GetToggleState()
	local same_found = false
	if not unit then
		return
	end

	IterateInventory(unit, 'INVENTORY', function(slot, item)
		if item then
			local name = item:GetName()
			if (names[name] or table.key(names, name))
			and item ~= source then
				same_found = true
				if item:GetToggleState() ~= toggle then
					if init then
						source:ToggleAbility()
						return true
					else
						item:ToggleAbility()
					end
				end
			end
		end
	end)

	if init and not same_found then
		default = default and true or false
		if toggle ~= default then
			source:ToggleAbility()
		end
	end
end

function HasState(unit, search)
	local max_prior = -1
	local result = false
	for _, mod in ipairs(unit:FindAllModifiers()) do
		local prior = mod.GetPriority and mod:GetPriority() or MODIFIER_PRIORITY_NORMAL
		if prior >= max_prior then
			local state = {}
			mod:CheckStateToTable(state)
			state = state[tostring(search)]
			if state ~= nil and (prior > max_prior or state == false) then
				max_prior = prior
				result = state
			end
		end
	end
	return result
end

function IsHardInvisible(unit)
	if unit:IsInvisible() then
		return HasState(unit, MODIFIER_STATE_TRUESIGHT_IMMUNE)
	end
	return false
end

function PreventAttack(unit)
	if unit:GetAttackTarget() ~= nil then
		unit:Stop()
	else
		local target = unit:GetAggroTarget()
		if target ~= nil then
			unit:MoveToNPC(target)
		end
	end
end

function PreventDamage(unit)
	unit._prevent_damage = math.max(1, unit:GetHealth())
end

function PreventWkHueta(unit)
	unit._prevent_wk_hueta = GameRules:GetGameTime()
end

function FindUnitsInCone(nTeam, vCenter, nRadius, vForward, nStartRadius, nAngle, nFilterTeam, nFilterType, nFilterFlag, nOrder)
	vForward = Vector(vForward.x, vForward.y, 0):Normalized()
	nFilterTeam = nFilterTeam or DOTA_UNIT_TARGET_TEAM_ENEMY
	nFilterType = nFilterType or DOTA_UNIT_TARGET_ALL
	nFilterFlag = nFilterFlag or 0
	nOrder = nOrder or FIND_ANY_ORDER
	local nExpand = math.tan(nAngle * math.pi / 180)
	local aUnits = FindUnitsInRadius(nTeam, vCenter, nil, nRadius, nFilterTeam, nFilterType, nFilterFlag, nOrder, false)

	for i = #aUnits, 1, -1 do
		local hUnit = aUnits[i]
		local vPos = hUnit:GetOrigin()
		local v = vPos - vCenter
		local v_ = Vector(v.x * vForward.x + v.y * vForward.y, v.x * vForward.y - v.y * vForward.x, 0)
		if v_.x < 0 or math.abs(v_.y) > nStartRadius + v_.x * nExpand then
			table.remove(aUnits, i)
		end
	end

	return aUnits
end

function Flat(v)
	return Vector(v.x, v.y, 0)
end

function CasterDirection(caster, target)
	local start = caster:GetOrigin()
	local dir = Flat(target - start)
	if #dir < 1 then
		return caster:GetForwardVector():Normalized()
	end
	return dir:Normalized()
end

function gos(target, path, default)
	if type(path) ~= 'table' then
		path = {path}
	end
	local len = #path
	if len == 0 then
		error('no path')
	else
		local key = table.remove(path, 1)
		if len == 1 then
			if target[key] == nil then
				target[key] = default
				return default
			else
				return target[key]
			end
		else
			if type(target[key]) ~= 'table' then
				target[key] = {}
			end
			return gos(target[key], path, default)
		end
	end
end

function AddFlag(unit, flag, count)
	if not unit._flags then
		unit._flags = {}
	end
	unit._flags[flag] = (unit._flags[flag] or 0) + count
	if unit._flags[flag] == 0 then
		unit._flags[flag] = nil
	end
	if table.size(unit._flags) == 0 then
		unit._flags = nil
	end
end

function HasFlag(unit, flag)
	if unit._flags and (unit._flags[flag] or 0) > 0 then
		return true
	end
	return false
end