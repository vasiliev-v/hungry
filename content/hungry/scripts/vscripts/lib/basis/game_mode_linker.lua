--[[

-- Link or reload existing game mode.
LinkGameMode( gameModeClassName: string [, gameModeName: ? (gameModeClassName) ], path: string ) => gamemode: instance | table

-- Get linked game mode by name
GetGameMode( gameModeName: ? ) => gamemode: instance | table

]]

_tLinkedGameModes = _tLinkedGameModes or {}

function LinkGameMode( sClassName, sGameModeName, sPath )
	if sPath == nil then
		sPath = sGameModeName
		sGameModeName = nil
	end
	
	if sGameModeName == nil then
		sGameModeName = sClassName
	end

	require( sPath )

	local cGameMode = _G[ sClassName ]
	if not isclass( cGameMode ) then
		cGameMode = nil
	end
	
	local hOldGameMode = _tLinkedGameModes[ sGameModeName ]
	if hOldGameMode then
		if getclass( hOldGameMode ) == cGameMode and cGameMode then
			if IsServer() and type( hOldGameMode.Reload ) == 'function' then
				hOldGameMode.tRequired = {}
				hOldGameMode:Reload()
			end
			
			return
		else
			if type( hOldGameMode.Destroy ) == 'function' then
				hOldGameMode:Destroy()
			end
			
			_tLinkedGameModes[ sGameModeName ] = nil
		end
	end
	
	local hGameMode
	if cGameMode then
		hGameMode = cGameMode( sGameModeName )
	else
		hGameMode = _G[ sGameModeName ]
		
		if type( hGameMode ) ~= 'table' then
			return
		end
		
		hGameMode.sName = sGameModeName
		
		if type( hGameMode.PreInit ) == 'function' then
			hGameMode:PreInit()
		end
		
		if IsServer() then
			if type( hGameMode.Init ) == 'function' then
				hGameMode:Init()
			end
		else
			if type( hGameMode.InitClient ) == 'function' then
				hGameMode:InitClient()
			end
		end
	end
	
	_tLinkedGameModes[ sGameModeName ] = hGameMode
	
	return hGameMode
end

function GetGameMode( sGameModeName )
	return _tLinkedGameModes[ sGameModeName ]
end