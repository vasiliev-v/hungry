require 'lib/lua/base'
require 'lib/gameplay_event_tracker/init'

self.tConsole = {}
self.tConsole.tCommands = {}
self.tConsole.tFlags = {}
self.tConsole.tConditions = {}

------------------------------------------------------------------

local function GetClient()
	return Convars:GetCommandClient():GetController()
end

self.tConsole.tCommands.kbw_dump_players = function()
	for i = DOTA_TEAM_FIRST, DOTA_TEAM_COUNT do
		print( 'Players in team ' .. i .. ': ' .. PlayerResource:GetPlayerCountForTeam( i ) )
	end
	print()

	local qTest = {
		'IsValidPlayer',
		'IsValidPlayerID',
		'IsValidTeamPlayer',
		'IsValidTeamPlayerID',
		'GetConnectionState',
		'GetCustomTeamAssignment',
		'GetDeaths',
		'GetGold',
		'GetLevel',
		'GetPartyID',
		'GetPlayer',
		'GetPlayerName',
		'GetSelectedHeroEntity',
		'GetSteamAccountID',
		'GetTeam',
		'HasSelectedHero',
	}

	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		print( 'PLAYER ' .. i )
		for _, sTestFunction in ipairs( qTest ) do
			local fTest = PlayerResource[ sTestFunction ]
			if fTest then
				print( 'PlayerResource:' .. sTestFunction .. '( ' .. i .. ' ): ' .. tostring( fTest( PlayerResource, i ) ) )
			end
		end
		print()
	end
end

self.tConsole.tConditions.kbw_force_pick = {'DEV'}
self.tConsole.tCommands.kbw_force_pick = function(_, sHero)
	GetGameMode('GameModeKBW'):ForcePick( GetClient():GetPlayerID(), sHero )
end

self.tConsole.tConditions.kbw_create_point = {'DEV'}
self.tConsole.tCommands.kbw_create_point = function()
	local hPlayer = GetClient()
	local hHero = hPlayer:GetAssignedHero()
	if hHero then
		ControlPoint{
			vPos = hHero:GetOrigin(),
			nRadius = 300,
			nCaptureTime = 12,
			nCaptureFallFactor = 0.5,
		}
	end
end

self.tConsole.tConditions.kbw_get_units = { 'CHEAT' }
self.tConsole.tCommands.kbw_get_units = function()
	local qUnits = PlayerResource:FindUnits( GetClient():GetPlayerID() )
	for _, hUnit in ipairs( qUnits ) do
		GameRules:SendCustomMessage( hUnit:GetUnitName(), 0, 0 )	
	end
end

self.tConsole.tConditions.kbw_spawn_runes = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_spawn_runes = function()
	self.hRuneSpawner1:Spawn()
	self.hRuneSpawner2:Spawn()
end

self.tConsole.tConditions.kbw_spawn_shit = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_spawn_shit = function( _, nCount, sUnit, nTeam, bDontControl )
	nCount = tonumber( nCount ) or 100
	nTeam = tonumber( nTeam ) or DOTA_TEAM_NEUTRALS
	bDontControl = ( bDontControl and tonumber( bDontControl ) ~= 0 )
	hPlayer = GetClient()
	local nPlayer
	local hHero
	local vPos = Vector( 0, 0, 0 )
	
	if not sUnit or sUnit == 'nil' or sUnit == '0' then
		sUnit = 'npc_dota_creep_badguys_ranged'
	end
	
	if hPlayer then
		hHero = hPlayer:GetAssignedHero()
		nPlayer = hPlayer:GetPlayerID()
		
		if hHero then
			vPos = hHero:GetOrigin()
		end
	end

	if sUnit:match('player%d+') then
		if hHero then
			local nTargetPlayer = tonumber( sUnit:match('%d+') )
			local hTargetHero = PlayerResource:GetSelectedHeroEntity( nTargetPlayer )

			if exist( hTargetHero ) then
				CreateIllusions( hHero, hTargetHero, {}, nCount, 32, false, true )
			end
		end

		return
	end
	
	for i = 1, nCount do
		local hUnit = CreateUnitByName( sUnit, vPos, true, nil, nil, nTeam )
		
		if hUnit then		
			ResolveNPCPositions( hUnit:GetOrigin(), hUnit:GetPaddedCollisionRadius() )
			
			if not bDontControl then
				if nPlayer then
					hUnit:SetControllableByPlayer( nPlayer, true )
				end
				
				ExecuteOrderFromTable{
					UnitIndex= hUnit:entindex(),
					OrderType= DOTA_UNIT_ORDER_HOLD_POSITION,
				}
			end
		else
			break
		end
	end
end

self.tConsole.tConditions.kbw_disable_spawner = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_disable_spawner = function( _, bDisable )
	if bDisable then
		bDisable = ( tonumber( bDisable ) ~= 0 )
	else
		bDisable = not bDisableSpawner
	end
	bDisableSpawner = bDisable
end

self.tConsole.tConditions.kbw_boss_refrseh = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_boss_refrseh = function()
	if exist( boss ) then
		boss:SetHealth( boss:GetMaxHealth() )
		boss:SetMana( boss:GetMaxMana() )
	end
end

-- self.tConsole.tConditions.kbw_set_tracker_enabled = { 'CHEAT', 'DEV' }
-- self.tConsole.tCommands.kbw_set_tracker_enabled = function( _, sEnabled )
-- 	if toboolean( tonumber( sEnabled ) ) then
-- 		if not exist( GameplayEventTracker ) then
-- 			-- GameplayEventTracker = CreateModifierThinker( nil, nil, 'm_gameplay_event_tracker', {}, Vector( 0, 0, 0 ), 0, false )
-- 			GameplayEventTracker = CreateModifierThinker( nil, nil, 'm_tracker', {}, Vector( 0, 0, 0 ), 0, false )
-- 		end
-- 	else
-- 		if exist( GameplayEventTracker ) then
-- 			GameplayEventTracker:Destroy()
-- 		end
-- 	end
-- end

self.tConsole.tConditions.modifier_data = {'DEV' }
self.tConsole.tCommands.modifier_data = function( _, bFormat, sPlayer)
	local nPlayer = tonumber(sPlayer) or GetClient():GetPlayerID()
	local hHero = PlayerResource:GetSelectedHeroEntity(nPlayer)

	if sPlayer and sPlayer:match('^_') then
		local nIndex = tonumber(sPlayer:sub(2))
		print(sPlayer:sub(2), nIndex)
		local aUnits = Find:UnitsInRadius({
			vCenter = hHero:GetOrigin(),
			nOrder = FIND_CLOSEST,
		})
		hHero = aUnits[nIndex + 1]
	end
	

	if hHero then
		bFormat = bFormat and bFormat ~= '0' and bFormat ~= 'false'

		for _, hMod in ipairs(hHero:FindAllModifiers()) do
			local tState = {}
			local tFormatState = {}
			hMod:CheckStateToTable(tState)
			local aFuncs = {}

			if bFormat then
				for sName, xVal in pairs(_G) do
					if type(xVal) == 'number' then
						if sName:match('MODIFIER_STATE') then
							tFormatState[sName] = tState[tostring(xVal)]
						elseif sName:match('MODIFIER_PROPERTY') or sName:match('MODIFIER_EVENT') then
							if hMod:HasFunction(xVal) then
								table.insert(aFuncs, sName)
							end
						end
					end
				end
			else
				for i = 0, 253 do
					if hMod:HasFunction(i) then
						table.insert(aFuncs, i)
					end
				end
				tFormatState = tState
			end

			print(hMod:GetName())
			table.print(tFormatState)
			table.print(aFuncs)
		end
	end
end

self.tConsole.tConditions.kbw_restrict_tracker = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_restrict_tracker = function( _, sEnabled, ... )
	local bEnbled = tonumber( sEnabled )
	if bEnbled then
		bEnbled = ( bEnbled ~= 0 )
	end
	local qFunc = {...}
	
	for _, sEvent in ipairs( qFunc ) do
		if tTrack[ sEvent ] ~= nil then
			if bEnbled == nil then
				tTrack[ sEvent ] = not tTrack[ sEvent ]
			else
				tTrack[ sEvent ] = bEnbled
			end
			print( sEvent, tTrack[ sEvent ] )
		end
	end
end

self.tConsole.tConditions.kbw_kill_creeps = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_kill_creeps = function()
	local qCreeps = FindUnitsInRadius( 0, Vector(0,0,0), nil, 99999, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, 0, false )
	for _, hCreep in pairs( qCreeps ) do
		hCreep:Kill( nil, nil )
	end
end

self.tConsole.tConditions.kbw_kill_illusions = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_kill_illusions = function()
	local qUnits = FindUnitsInRadius( 0, Vector(0,0,0), nil, 99999, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, 0, false )
	for _, hUnit in pairs( qUnits ) do
		if hUnit:IsIllusion() then
			hUnit:Kill( nil, nil )
		end
	end
end

self.tConsole.tConditions.kbw_end_game = { 'CHEAT', 'DEV' }
self.tConsole.tCommands.kbw_end_game = function( _, sTeam )
	local nTeam = tonumber( sTeam )
	if not nTeam then
		local hPlayer = GetClient()
		if hPlayer then
			nTeam = hPlayer:GetTeam()
		else
			return
		end
	end

	if GameRules:State_Get() < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules:ForceGameStart()
	end

	local hKiller = CreateUnitByName( 'npc_dota_thinker', Vector(0,0,0), false, nil, nil, nTeam )
	if exist( boss ) then
		boss:RemoveModifierByName('m_kbw_boss_flag')
		boss:__Kill( nil, hKiller )
	end
end

self.tConsole.tConditions.kbw_run_code = { 'DEV' }
self.tConsole.tCommands.kbw_run_code = function( _, sURL, sPlayer )
	if sPlayer then
		FireGameEvent( 'lua_client_run_url', {
			player = tonumber( sPlayer ),
			url = sURL,
		})
	else
		self:RunUrl( sURL )
	end
end

-- self.tConsole.tConditions.getKey = { 'DEV' }
-- self.tConsole.tCommands.getKey = function(_, s)
-- 	CustomGameEventManager:Send_ServerToPlayer(GetClient(), 'cl_print', {
-- 		msg = GetDedicatedServerKeyV2(s)
-- 	})
-- end

self.tConsole.tConditions.kbw_gen_talents = { 'DEV' }
self.tConsole.tCommands.kbw_gen_talents = function( _, sTable )
	local nTable = tonumber( sTable ) or 0
	local tNewHeroes, tNewAbilities, tLocalization = self:GenTalentsKV()
	local tPrint = ( nTable == 0 ) and tNewHeroes or ( nTable == 1 and tNewAbilities or tLocalization )

	self:PrintKV( tPrint )
end

self.tConsole.tConditions.kbw_quicktest = { 'DEV' }
self.tConsole.tCommands.kbw_quicktest = function( _, sPath )
	self:Quicktest( sPath )
end

------------------------------------------------------------------

for sCommand, fCallback in pairs( self.tConsole.tCommands ) do
	local tConditions = self.tConsole.tConditions[ sCommand ]
	local fCondition fCondition = function()
		return true
	end

	if tConditions then
		fCondition = function( nPlayer )
			for _, sCondition in pairs( tConditions ) do
				if sCondition == 'CHEAT' and GameRules:IsCheatMode() then
					return true
				end

				if sCondition == 'DEV' and self.tDev[ PlayerResource:GetSteamAccountID( nPlayer ) ] then
					return true
				end
			end

			print( '"' .. sCommand .. '" was denied' )

			return false
		end
	end

	Convars:RegisterCommand( sCommand, function( ... )
		local hPlayer = GetClient()
		if hPlayer and fCondition( hPlayer:GetPlayerID() ) then
			fCallback( ... )
		end
	end, '', self.tConsole.tFlags[ sCommand ] or 0 )
end