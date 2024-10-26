--[[

-- Custom event manager (lua only, single side).



-- Register listener for the event.
Events:Register( eventName: ?, callback: function( [ params: ? ... ] ) [, options: table ] ) => listener: EventListener
	options: {
		sName = ? (nil), -- Unique listener name. Old listener with the same name for the same event will be replaced.
		nOrder = ? -> number > 0 | nil (nil), -- Listener call order (nil = last)
		nLimit = ? -> number > 0 | nil (nil), -- Listener call count limit (nil = unlimited)
	}
	
-- Register listener for single triggering before the event was called, or trigger the callback with last event arguments, if event already was dispatched.
Events:CallAfter( eventName: ?, callback: function( [ params: ? ... ] ) [, options: table ] ) => listener: EventListener | nil

-- Check if the event was called at least once.
Events:WasCalled( eventName: ? ) => boolean

-- Stop and destroy the listener. Returns false, if listener wasn't registered or was already removed.
Events:RemoveListener( listener: EventListener ) => success: boolean
	
-- Trigger all listeners for the event.
Events:Trigger( eventName: ? [, params: ? ... ] )

-- Array of all currently registered listeners for the event. Order equals the listeners call order.
Events:FindAllListeners( eventName: ? ) => listeners: { EventListener ... }

-- Find listener by name for the event.
Events:FindListenerByName( eventName: ?, listenerName: ? ) => listener: EventListener | nil



-- Stop and destroy listener.
EventListener:Destroy()

-- Is destroyed?
EventListener:IsNull() => boolean

-- Is removed from tracking the event?
EventListener:IsStopped() => boolean

-- Get listener name.
EventListener:GetName() => listenerName: ? | nil

-- Get event name this listener registered for.
EventListener:GetEventName() => eventName: ?

-- Get register order.
EventListener:GetRegisterOrder() => order: number

-- Call listener's callback
EventListener:Call( [ params: ? ... ] )

]]

EventListener = EventListener or class{}

function EventListener:constructor( tManager, sEvent, fCallback, sName, nLimit, nOrder )
	self.bNull = false
	self.bStopped = false
	self.tManager = tManager
	self.sEvent = sEvent
	self.sName = sName
	self.fCallback = fCallback
	self.nLimit = tonumber( nLimit )
	self.nOrder = tonumber( nOrder )
	
	if self.nLimit then
		self.nLimit = math.max( 0, self.nLimit )
	end
end

function EventListener:GetName()
	return self.sName
end

function EventListener:GetEventName()
	return self.sEvent
end

function EventListener:GetRegisterOrder()
	return self.nOrder
end

function EventListener:Destroy()
	if self.bNull then
		return
	end
	
	self.bNull = true
	
	self.tManager:RemoveListener( self )
end

function EventListener:IsNull()
	return self.bNull
end

function EventListener:IsStopped()
	return self.bStopped
end

function EventListener:Call( ... )
	if self.bNull then
		local sMsg = 'Attempt to call destroyed listener'
		local sName = self:GetName()
		
		if sName ~= nil then
			sMsg = sMsg .. ' (' .. tostring( sName ) .. ')'
		end
		
		debug.traceback( sMsg, 2 )	
		return
	end
	
	if not self.nLimit or self.nLimit > 0 then
		if self.nLimit then
			self.nLimit = self.nLimit - 1
		end
		
		local bStatus, sErr = pcall( self.fCallback, ... )

		if not bStatus then
			print( 'Events callback error!' )
			print( sErr )
		end
		
		if self.nLimit and self.nLimit < 1 then
			self:Destroy()
		end
	end
end

Events = Events or {
	tRegister = {},
	tLastCalls = {},
	tActiveCalls = {},
}

function Events:Register( sEvent, fCallback, tOptions )
	tOptions = tOptions or {}
	
	if tOptions.sName then
		local hOldListener = self:FindListenerByName( sEvent, tOptions.sName )
		
		if hOldListener then
			hOldListener:Destroy()
		end
	end
	
	local nOrder = tonumber( tOptions.nOrder )
	
	local hListener = EventListener( self, sEvent, fCallback, tOptions.sName, tOptions.nLimit, nOrder )
	
	local qListeners = self.tRegister[ sEvent ]
	if not qListeners then
		qListeners = {}
		self.tRegister[ sEvent ] = qListeners
	end
	
	if nOrder then
		local nRealOrder = 1
		
		while true do
			local hOtherListener = qListeners[ nRealOrder ]
			if not hOtherListener then
				break
			end
			
			local nOtherOrder = hOtherListener:GetRegisterOrder()
			if not nOtherOrder or nOtherOrder > nOrder then
				break
			end
			
			nRealOrder = nRealOrder + 1
		end
		
		table.insert( qListeners, nRealOrder, hListener )
	else
		table.insert( qListeners, hListener )
	end
	
	return hListener
end

function Events:CallAfter( sEvent, fCallback, tOptions )
	local qLastCallArgs = self.tLastCalls[ sEvent ]
	if qLastCallArgs and not self.tActiveCalls[ sEvent ] then
		fCallback( table.unpack( qLastCallArgs ) )
	else
		return self:Register( sEvent, fCallback, table.overlay( tOptions or {}, {
			nLimit = 1,
		}))
	end
end

function Events:WasCalled( sEvent )
	return self.tLastCalls[ sEvent ] and true or false
end

function Events:RemoveListener( hListener )
	if hListener:IsStopped() then
		return false
	end
	
	hListener.bStopped = true
	
	local sEvent = hListener:GetEventName()
	local qListeners = self.tRegister[ sEvent ]
	
	if not qListeners then
		return false
	end
	
	for i, hOtherListener in ipairs( qListeners ) do
		if hOtherListener == hListener then
			table.remove( qListeners, i )
			
			if #qListeners == 0 then
				self.tRegister[ sEvent ] = nil
			end
			
			hListener:Destroy()
			
			return true
		end
	end
	
	return false
end

function Events:Trigger( sEvent, ... )
	if self.tActiveCalls[ sEvent ] then
		return true
	end

	local qListeners = self.tRegister[ sEvent ]
	self.tLastCalls[ sEvent ] = {...}
	
	if qListeners then
		self.tActiveCalls[ sEvent ] = true

		local nOrder = 1
		local hListener = qListeners[ nOrder ]
		
		while hListener do
			hListener:Call( ... )
			
			if exist( hListener ) then
				nOrder = nOrder + 1
			end
			
			hListener = qListeners[ nOrder ]
		end

		self.tActiveCalls[ sEvent ] = nil
	end
end

function Events:FindAllListeners( sEvent )
	local qReturn = {}
	local qListeners = self.tRegister[ sEvent ]

	if qListeners then
		for _, hListener in ipairs( qListeners ) do
			table.insert( qReturn, hListener )
		end
	end
	
	return qReturn
end

function Events:RemoveAllListeners( sEvent )
	local qListeners = self.tRegister[ sEvent ]

	if qListeners then
		for _, hListener in ipairs( qListeners ) do
			hListener:Destroy()
		end
	end
end

function Events:FindListenerByName( sEvent, sName )
	local qListeners = self.tRegister[ sEvent ]
	if not qListeners then
		return
	end
	
	for _, hListener in ipairs( qListeners ) do
		if hListener:GetName() == sName then
			return hListener
		end
	end
end