--[[

-- occuiped fields:
	bNull
	bInited
	sName
	sRoot
	tListeners
	tRequired

-- Called when first time linked
GameModeBase:PreInit()

-- Called when first time linked on server
GameModeBase:Init()

-- Called when first time linked on client
GameModeBase:InitClient()

-- Called in addon_game_mode Precache()
GameModeBase:Precache( context: CScriptPrecacheContext  )

-- Called in addon_game_mode Activate()
GameModeBase:Activate()

-- Called on server when relinked (usually triggered by 'script_reload' console command)
GameModeBase:Reload()

-- Called before destroy
GameModeBase:OnDestroy()



GameModeBase:Destroy()

GameModeBase:IsNull() => boolean

-- Get name with which gamemode was registred.
GameModeBase:GetName() => name: string

-- Print with game mode name prefix
GameModeBase:Print( [ params: ? ... ] )

-- Set root path
GameModeBase:SetRoot( root: string )

-- Connect path with game mode root path.
GameModeBase:Path( path: string ) => fullPath: string

-- Require from game mode root path
GameModeBase:Require( path: string ) => require_result: ?

-- Register unique game event listener. If callback is string, the function of game mode with the passed name will be registred as callback.
GameModeBase:ListenToGameEventUnique( event: string, callback: function( tEvent ) | string | nil )

-- Unregister all unique listeners.
GameModeBase:StopListeningToGameEvents()
]]

GameModeBase = GameModeBase or class{}

function GameModeBase:constructor( sName )
	self.bNull = false
	self.bInited = false
	self.sName = sName
	self.sRoot = ''
	self.tListeners = {}
	self.tRequired = {}
	
	self:PreInit()
	
	if IsServer() then
		Events:Register( 'Precache', function( ... ) self:Precache( ... ) end )
		Events:Register( 'Activate', function( ... ) self:Activate( ... ) end )
		
		self:Init()
	else
		self:InitClient()
	end
	
	self.bInited = true
end

function GameModeBase:PreInit()

end

function GameModeBase:Init()

end

function GameModeBase:InitClient()

end

function GameModeBase:Precache( hContext )

end

function GameModeBase:Activate()

end

function GameModeBase:Reload()

end

function GameModeBase:OnDestroy()

end

function GameModeBase:Destroy()
	self:OnDestroy()
	self.bNull = true
end

function GameModeBase:IsNull()
	return self.bNull
end

function GameModeBase:GetName()
	return self.sName
end

function GameModeBase:Print( ... )
	if self.sName ~= nil then
		print( '[' .. tostring( self.sName ) .. ']:', ... )
	else
		print( ... )
	end
end

function GameModeBase:SetRoot( sRoot )
	if type( sRoot ) == 'string' then
		self.sRoot = sRoot
	end
end

function GameModeBase:Path( sPath )
	if string.len( self.sRoot ) > 0 then
		return self.sRoot .. '/' .. sPath
	end
	return sPath
end

function GameModeBase:ListenToGameEventUnique( sEvent, xCallback )
	local nOldListener = self.tListeners[ sEvent ]
	if nOldListener then
		StopListeningToGameEvent( nOldListener )
	end
	
	local nListener
	local sType = type( xCallback )
	
	if sType == 'function' then
		nListener = ListenToGameEvent( sEvent, xCallback, nil )
	elseif sType == 'string' then
		nListener = ListenToGameEvent( sEvent, Dynamic_Wrap( self, xCallback ), self )
	end
	
	self.tListeners[ sEvent ] = nListener
end

function GameModeBase:StopListeningToGameEvents()
	for _, nListener in pairs( self.tListeners ) do
		StopListeningToGameEvent( nListener )
	end
	
	self.tListeners = {}
end

function GameModeBase:Require( sPath )
	if self.tRequired[ sPath ] ~= nil then
		return self.tRequired[ sPath ]
	end

	local tEnv = { self = self }
	setmetatable( tEnv, {
		__index = _G,
		__newindex = _G,
	})
	
	local fCode, sErr = loadfile( self:Path( sPath ) )

	local fErr = function( sErr )
		print( '[' .. self:GetName() .. ']: Error in required file "' .. sPath .. '"' )
		print( sErr )
	end
	
	if type( fCode ) == 'function' then
		setfenv( fCode, tEnv )

		local bStatus, xResult = xpcall( function()
			return fCode()
		end, function( sErr )
			fErr( sErr )
		end )
		
		if bStatus then
			self.tRequired[ sPath ] = xResult
			return xResult
		end
	else
		fErr( sErr )
	end
end