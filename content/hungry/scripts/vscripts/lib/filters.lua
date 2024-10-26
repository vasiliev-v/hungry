--[[

Multiple filters system. Similar to event manager, but also returns filtration boolean result.

Allows to register multiple dota filters. This feature implies you are not using default dota Set...Filter nor Clear...Filter functions.
To set dota filter just register this filter for event name same to the dota filter name (which replaces ellipsis in function name examples above).



-- Register filter
Filters:Register( filterEventName: ?, callback: function( [ params: ? ... ] ) => filterResult: ? -> boolean [, options: table ] ) => filter: DynamicFilter
	options: {
		sName = ? (nil), -- Unique filter name. Old filter with the same name for the same event will be replaced.
		nOrder = ? -> number > 0 | nil (nil), -- Filter order (nil = last)
	}
	
-- Stop and destroy passed filter. Returns false, if filter wasn't registered or was already removed.
Filters:RemoveFilter( filter: DynamicFilter ) => success: boolean

-- Filter the params. First negative filter result prevents subsequent filters and returns false.
Filters:Trigger( filterEventName: ? [, params: ? ... ] ) => filterResult: boolean

-- Array of all currently registered filters for the event. Order equals the filters call order.
Filters:FindAll( filterEventName: ? ) => filters: { DynamicFilter ... }

-- Find filter by name for the event.
Filters:FindFilterByName( filterEventName: ?, filterName: ? ) => filter: DynamicFilter | nil

-- Works automatically and should not be directly called. Sets all possible dota filters from currently registered filter events. Uses GameModeEntity:Set<filterEventName>Filter() function.
Filters:RegisterDotaFilters()



DynamicFilter:Destroy()

DynamicFilter:IsNull()

-- Is removed from filtering the event?
DynamicFilter:IsStopped()

-- Get filter name.
DynamicFilter:GetName() => filterName: ? | nil

-- Get event name this filter registered for.
DynamicFilter:GetFilterEventName() => filterEventName: ?

-- Order with which filter was register.
DynamicFilter:GetRegisterOrder() => order: number

-- Trigger filter function.
DynamicFilter:Filter( [ params: ? ... ] ) => filterResult: ?

]]

require 'lib/lua/base'

DynamicFilter = DynamicFilter or class{}

function DynamicFilter:constructor( tManager, sFilter, fFilter, sName, nOrder )
	self.bNull = false
	self.bStopped = false
	self.tManager = tManager
	self.sFilter = sFilter
	self.sName = sName
	self.fFilter = fFilter
	self.nOrder = tonumber( nOrder )
end

function DynamicFilter:GetName()
	return self.sName
end

function DynamicFilter:GetFilterEventName()
	return self.sFilter
end

function DynamicFilter:GetRegisterOrder()
	return self.nOrder
end

function DynamicFilter:Destroy()
	if self.bNull then
		return
	end
	
	self.bNull = true
	
	self.tManager:RemoveFilter( self )
end

function DynamicFilter:IsNull()
	return self.bNull
end

function DynamicFilter:IsStopped()
	return self.bStopped
end

function DynamicFilter:Filter( ... )
	if self.bNull then
		local sMsg = '[DynamicFilter.Filter]: Filter'
		local sName = self:GetName()
		
		if sName ~= nil then
			sMsg = sMsg .. ' "' .. tostring( sName ) .. '"'
		end
		
		debug.traceback( sMsg .. ' is destroyed!', 2 )
		return true
	end
	
	local bStatus, bResult = ppcall( self.fFilter, ... )

	if bStatus then
		return bResult
	end

	return true
end

Filters = Filters or {}

Filters.tFilters = Filters.tFilters or {}
Filters.tDotaFilters = Filters.tDotaFilters or {}

function Filters:Register( sFilter, fFilter, tOptions )
	tOptions = tOptions or {}
	
	if tOptions.sName then
		local hOldFilter = self:FindFilterByName( sFilter, tOptions.sName )
		
		if hOldFilter then
			hOldFilter:Destroy()
		end
	end
	
	local nOrder = tonumber( tOptions.nOrder )
	
	local hFilter = DynamicFilter( self, sFilter, fFilter, tOptions.sName, nOrder )
	
	local qFilters = self.tFilters[ sFilter ]
	if not qFilters then
		qFilters = {}
		self.tFilters[ sFilter ] = qFilters
	end
	
	if nOrder then
		local nRealOrder = 1
		
		while true do
			local hOtherFilter = qFilters[ nRealOrder ]
			if not hOtherFilter then
				break
			end
			
			local nOtherOrder = hOtherFilter:GetRegisterOrder()
			if not nOtherOrder or nOtherOrder > nOrder then
				break
			end
			
			nRealOrder = nRealOrder + 1
		end
		
		table.insert( qFilters, nRealOrder, hFilter )
	else
		table.insert( qFilters, hFilter )
	end
	
	self:RegisterDotaFilters()
	
	return hFilter
end

function Filters:RemoveFilter( hFilter )
	if hFilter.bStopped then
		return false
	end
	
	hFilter.bStopped = true
	
	local sFilter = hFilter:GetFilterEventName()
	local qFilters = self.tFilters[ sFilter ]
	
	if not qFilters then
		return false
	end
	
	for i, hOtherFilter in ipairs( qFilters ) do
		if hOtherFilter == hFilter then
			table.remove( qFilters, i )
			
			if #qFilters == 0 then
				self.tFilters[ sFilter ] = nil
			end
			
			hFilter:Destroy()
			
			return true
		end
	end
	
	return false
end

function Filters:Trigger( sFilter, t )
	local qFilters = self.tFilters[ sFilter ]
	
	if qFilters then
		local qFinal = {}
		local fAddFinal = function( fCallback )
			table.insert( qFinal, fCallback )
		end

		for _, hFilter in ipairs( qFilters ) do
			if not hFilter:Filter( t, fAddFinal ) then
				return false
			end
		end

		for _, fCallback in ipairs( qFinal ) do
			fCallback()
		end
	end
	
	return true
end

function Filters:FindAll( sFilter )
	local qFilters = self.tFilters[ sFilter ]
	local qResult = {}
	
	if qFilters then
		for _, hFilter in ipairs( qFilters ) do
			table.insert( qResult, hFilter )
		end
	end
	
	return qResult
end

function Filters:FindFilterByName( sFilter, sName )
	local qFilters = self.tFilters[ sFilter ]
	
	if qFilters then
		for _, hFilter in ipairs( qFilters ) do
			if hFilter:GetName() == sName then
				return hFilter
			end
		end
	end
end

if IsClient() then
	return
end

function Filters:RegisterDotaFilters()
	if not GameRules then
		return
	end
	
	local hGameModeEntity = GameRules:GetGameModeEntity()
	
	for sFilter in pairs( self.tFilters ) do
		if type( sFilter ) == 'string' and not self.tDotaFilters[ sFilter ] then
			local sSetterName = 'Set' .. sFilter .. 'Filter'
			DebugPrint(sSetterName)
			local fSetter = hGameModeEntity[ sSetterName ]
			
			if fSetter then
				local fDotaFilter = function( self, tFilter )
					return self:Trigger( sFilter, tFilter )
				end
				
				self.tDotaFilters[ sFilter ] = fDotaFilter
				fSetter( hGameModeEntity, fDotaFilter, self )
			end
		end
	end
end
