-- require panorama 'gentable.js'
require 'lib/lua/base'
require 'lib/timer'

GenTable = GenTable or {}
GenTable.tData = GenTable.tData or {}
GenTable.tListen = GenTable.tListen or {}
GenTable.NIL = { _gen_table_remove = 1892374 }

if IsServer() then
	GenTable.tLuaClientData = GenTable.tLuaClientData or {}
end

local function fSplitKey( sKey )
	return string.qmatch( sKey, '[%a%d_]+' )
end

local function fFindByPath( xTarget, sPath, bDonCopy, nApproximate )
	local qPath = fSplitKey( sPath or '' )

	for _, sSubKey in ipairs( qPath ) do
		if type( xTarget ) ~= 'table' then
			return
		end
		
		local tSource = xTarget
		xTarget = tSource[ sSubKey ]

		if xTarget == nil and nApproximate then
			local nKey = tonumber( sSubKey )
			if nKey then
				for sOtherKey, xValue in pairs( tSource ) do
					local nOtherKey = tonumber( sOtherKey )
					if nOtherKey and math.abs( nOtherKey - nKey ) <= nApproximate then
						xTarget = xValue
						break
					end
				end
			end
		end
	end
	
	if not bDonCopy then
		xTarget = table.deepcopy( xTarget )
	end
	
	return xTarget
end

if IsServer() then
	function GenTable:Get( nPlayer, sKey, bDonCopy )
		return fFindByPath( self.tData[ nPlayer ], sKey, bDonCopy )
	end

	function GenTable:Set( nPlayer, sKey, xData, bLuaClient, bPreventDublicate )
		local qPath = fSplitKey( sKey )
		sKey = table.remove( qPath, #qPath )

		if not self.tUpdate then
			self.tUpdate = {}
		end

		local qFill = { self.tData, self.tUpdate }
		
		if bLuaClient then
			if not self.tLuaClientUpdate then
				self.tLuaClientUpdate = {}
			end

			table.insert( qFill, self.tLuaClientData )
			table.insert( qFill, self.tLuaClientUpdate )
		end

		local qTargets = {}
		
		for i, tTable in ipairs( qFill ) do
			qTargets[i] = tTable[ nPlayer ]
			if not qTargets[i] then
				qTargets[i] = {}
				tTable[ nPlayer ] = qTargets[i]
			end
		end

		for _, sSubKey in ipairs( qPath ) do
			for i, xTarget in ipairs( qTargets ) do
				if type( qTargets[i][ sSubKey ] ) ~= 'table' or qTargets[i][ sSubKey ] == self.NIL then
					qTargets[i][ sSubKey ] = {}
				end

				qTargets[i] = qTargets[i][ sSubKey ]
			end
		end

		for i, xTarget in ipairs( qTargets ) do
			if not bPreventDublicate or not table.equal( xTarget[ sKey ], xData ) then
				local bUpdater = ( i % 2 == 0 )

				if bUpdater and xData == nil then
					xTarget[ sKey ] = self.NIL
				else
					xTarget[ sKey ] = table.deepcopy( xData, function( v, bKey )
						if bKey then
							return tostring( v )
						end
						return v
					end )

					if bUpdater and type( xData ) == 'table' then
						xTarget[ sKey ].__bClear = true
					end
				end
			end
		end

		if exist( self.hUpdateTimer ) then
			return
		end
		
		self.hUpdateTimer = Timer( 1/30, function()
			if self.tUpdate then
				for nPlayer, tPlayerUpdate in pairs( self.tUpdate ) do
					self:UpdateClientJs( nPlayer, tPlayerUpdate )
				end
			end
			
			if self.tLuaClientUpdate then
				self:UpdateLuaClients( self.tLuaClientUpdate )
			end

			self.tUpdate = nil
			self.tLuaClientUpdate = nil
			self.hUpdateTimer = nil
		end )
	end

	function GenTable:SetAll( sKey, xData, bLuaClient, bPreventDublicate )
		if PlayerResource then
			for nPlayer = 0, DOTA_MAX_PLAYERS - 1 do
				if PlayerResource:IsValidPlayerID( nPlayer ) then
					GenTable:Set( nPlayer, sKey, xData, bLuaClient, bPreventDublicate )
				end
			end
		end
	end

	function GenTable:UpdateClientJs( nPlayer, tUpdate, bNew, bImportant )
		if bNew then
			tUpdate = table.copy( tUpdate )
			tUpdate.__bClear = true
		end
	--	CustomGameEventManager:SendProtected( nPlayer, 'cl_basis_gentable_update', tUpdate, bImportant and {bImportant = true} )
	end

	function GenTable:UpdateLuaClients( tUpdate )
		local tUpdatedPaths = {}
		local fIter
		
		fIter = function( tTargets, sPath )
			local tValueGroups = {}
			local tSubKeys = {}

			local fShouldTriggerEvent = function( x )
				return type( x ) ~= 'table' or x == self.NIL or x.__bClear
			end

			local fAreEqualEvents = function( x1, x2 )
				if x1 == x2 then
					return true
				end

				if type( x1 ) == 'table' and type( x2 ) == 'table' and x1.__bClear and x2.__bClear then
					return true
				end

				return false
			end

			local fFind = function( tSource, sTargetKey )
				for sKey, xValue in pairs( tSource ) do
					if fAreEqualEvents( sKey, sTargetKey ) then
						return sKey, xValue
					end
				end
			end

			for nPlayer, xValue in pairs( tTargets ) do
				if fShouldTriggerEvent( xValue ) then
					local xSameValue, sGroup = fFind( tValueGroups, xValue )

					if sGroup then
						tValueGroups[ xSameValue ] = sGroup .. ' ' .. nPlayer
					else
						tValueGroups[ xValue ] = tostring( nPlayer )
					end
				end

				if type( xValue ) == 'table' and xValue ~= self.NIL then
					for sSubKey, xSubValue in pairs( xValue ) do
						if sSubKey ~= '__bClear' then
							local tSubTargets = tSubKeys[ sSubKey ]
							if not tSubTargets then
								tSubTargets = {}
								tSubKeys[ sSubKey ] = tSubTargets
							end
							tSubTargets[ nPlayer ] = xSubValue
						end
					end
				end
			end

			for xValue, sPlayers in pairs( tValueGroups ) do
				if xValue == self.NIL then
					xValue = nil
				end

				local sType = type( xValue )
				if sType == 'table' then
					xValue = 'nil'
				else
					xValue = tostring( xValue )
				end

				FireGameEvent( 'basis_gentable_set', {
					players = sPlayers,
					key = sPath,
					type = sType,
					value = xValue,
				})
			end

			for sSubKey, tSubTargets in pairs( tSubKeys ) do
				fIter( tSubTargets, sPath .. '.' .. sSubKey )
			end
		end

		fIter( tUpdate, '' )
	end

else
	function GenTable:Get( sKey, bDonCopy, nApproximate )
		return fFindByPath( self.tData, sKey, bDonCopy, nApproximate )
	end

	function GenTable:Parse( tData )
		local nPlayer = GetLocalPlayerID()
		local bUpdate = false

		for sPlayer in tData.players:gmatch('%d+') do
			if tonumber( sPlayer ) == nPlayer then
				bUpdate = true
				break
			end
		end

		if bUpdate then
			local sKey = tData.key
			local sValueType = tData.type
			local xValue = tData.value

			if sValueType == 'boolean' then
				xValue = ( xValue == 'true' )
			elseif sValueType == 'table' then
				xValue = {}
			elseif sValueType == 'number' then
				xValue = tonumber( xValue )
			elseif sValueType == 'nil' then
				xValue = nil
			end
			
			local xTarget = self.tData
			local qPath = fSplitKey( sKey )
			sKey = table.remove( qPath, #qPath )
						
			for _, sSubKey in ipairs( qPath ) do
				if type( xTarget[ sSubKey ] ) ~= 'table' then
					xTarget[ sSubKey ] = {}
				end
				
				xTarget = xTarget[ sSubKey ]
			end
			
			xTarget[ sKey ] = xValue

			-- trigger listeners
			local sPath
			table.insert(qPath, sKey)

			for _, sSubKey in ipairs(qPath) do
				if sPath then
					sPath = sPath .. '.' .. sSubKey
				else
					sPath = sSubKey
				end

				local qListeners = self.tListen[sPath]
				if qListeners then
					for _, tListener in ipairs(qListeners) do
						tListener.fCallback(tData.key, xValue)
					end
				end
			end
		end
	end

	function GenTable:Listen(sKey, fCallback)
		local qListeners = self.tListen[sKey]
		if not qListeners then
			qListeners = {}
			self.tListen[sKey] = qListeners
		end

		local tListener = {
			fCallback = fCallback,
			bNull = false,
			IsNull = function(self)
				return self.bNull
			end,
			Destroy = function(self)
				if not self.bNull then
					self.bNull = true
					table.remove(qListeners, table.key(qListeners, self))
				end
			end,
		}

		table.insert(qListeners, tListener)

		return tListener
	end

	if GenTable.nSetListener then
		StopListeningToGameEvent( GenTable.nSetListener )
	end

	GenTable.nSetListener = ListenToGameEvent( 'basis_gentable_set', function( tData )
		GenTable:Parse( tData )
	end, nil )
end