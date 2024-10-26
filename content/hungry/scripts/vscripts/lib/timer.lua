--[[

* Server only



-- Register game time based timer. Arguments order does not matter.
Timer( callback: function( dt: number ) => nextDelay: ? -> number [, delay: number, uniqueName: ? ] ) => Timer

Timer:Destroy()

Timer:IsNull() => boolean

-- Get timer by its unique name.
Timer:FindByName( name: ? ) => Timer | nil

-- Get unique timer name
Timer:GetName() => name: ?

-- Trigger timer callback.
Timer:Call( [ time: number ] ) => nextDelay: ?

Timer:SetLastTime( [ time: number ] ) =>

-- Delay next timer call.
Timer:Delay( delay: number [, time: number ] )

-- Call timer at the passed game time.
Timer:Schedule( time: number )

-- Remove timer from queue, preventing it from triggering.
Timer:Remove()

-- Trigger timer callback and delay next call.
Timer:Skip( [ time: number ] )

]]

if IsClient() then
	return
end

require('lib/lua/base')

Timer = Timer or class{}
Timer.qTicks = Timer.qTicks or {}
Timer.tNamed = Timer.tNamed or {}
Timer.MIN = FrameTime()

function Timer:OnInterrupted()
	-----
end

function Timer:OnDestroy()
	-----
end

function Timer:constructor( ... )
	local nDelay
	local sName
	local fCallback
	local qArgs = {...}
	
	for i = 1, 3 do
		local sType = type( qArgs[i] )
		
		if sType == 'number' and not nDelay then
			nDelay = qArgs[i]
		elseif sType == 'function' and not fCallback then
			fCallback = qArgs[i]
		elseif not sName then
			sName = qArgs[i]
		end
	end

	self.sStack = debug.traceback( '', 3 )
	
	if not fCallback then
		error('[Timer]: callback function unspecified!')
		print( self.sStack )
	end
	
	nDelay = nDelay or 0
	local nTime = GameRules:GetGameTime()
	
	if sName then
		local hOldTimer = Timer.tNamed[ sName ]
		if exist( hOldTimer ) then
			hOldTimer:Destroy()
		end
		
		Timer.tNamed[ sName ] = self
	end
	
	self.bNull = false
	self.fCallback = fCallback
	self.sName = sName
	
	self:SetLastTime( nTime )
	self:Delay( nDelay, nTime )
end

function Timer:Destroy( bSelfDestroed )
	if self.bNull then
		return
	end
	
	if not bSelfDestroed then
		self:OnInterrupted()
	end

	self:OnDestroy()
	
	if self.sName then
		Timer.tNamed[ self.sName ] = nil
	end
	
	self:Remove()
	self.bNull = true
end

function Timer:IsNull()
	return self.bNull
end

function Timer:GetName()
	return self.sName
end

function Timer:FindByName( sName )
	return self.tNamed[ sName ]
end

function Timer:Call( nTime )
	if self.bNull then
		return
	end
	
	nTime = nTime or GameRules:GetGameTime()
	local nDelta = nTime - self.nLastTime
	
	local _, nDelay = ppcall( self.fCallback, nDelta, self )
	
	self:SetLastTime( nTime )
	
	return nDelay
end

function Timer:SetLastTime( nTime )
	if self.bNull then
		return
	end
	
	self.nLastTime = nTime or GameRules:GetGameTime()
end

function Timer:Skip( nTime )
	if self.bNull then
		return
	end
	
	nTime = nTime or GameRules:GetGameTime()
	local nDelay = tonumber( self:Call( nTime ) )
	
	if nDelay then
		if nDelay < 1/30 then
			nDelay = 1/30
		end
		
		self:Delay( nDelay, self.nNextTime or nTime )
	else
		self:Destroy( true )
	end
end

function Timer:Delay( nDelay, nTime )
	if self.bNull then
		return
	end
	
	if nTime == nil and nDelay == 0 then
		self:Skip()
	else
		self:Schedule( ( nTime or GameRules:GetGameTime() ) + nDelay )
	end
end

function Timer:Schedule( nTime )
	if self.bNull then
		return
	end
	
	self:Remove()
	
	self.nNextTime = nTime
	
	local nCurrent = GameRules:GetGameTime()
	
	if nCurrent >= nTime then
		self:Skip( nTime )
		return
	end
	
	local nNewTickIndex = 1
	
	self.tQueueData = {
		hTimer = self,
		bRemoved = false,
	}
	
	for nTickIndex, tTickInfo in ipairs( Timer.qTicks ) do
		if nTime == tTickInfo.nTime then
			table.insert( tTickInfo.qTimers, self.tQueueData )
			return
		elseif nTime > tTickInfo.nTime then
			nNewTickIndex = nTickIndex + 1
		else
			break
		end
	end
	
	local tTickInfo = {
		nTime = nTime,
		qTimers = { self.tQueueData }
	}
	
	table.insert( Timer.qTicks, nNewTickIndex, tTickInfo )
end

function Timer:Remove()
	if self.bNull then
		return
	end
	
	if self.tQueueData then
		self.tQueueData.bRemoved = true
	end
	
	self.nNextTime = nil
end

Events:CallAfter( 'Activate', function()
	GameRules:GetGameModeEntity():SetThink( function()
		local nTime = GameRules:GetGameTime()
		
		while true do
			local tTickInfo = Timer.qTicks[1]
			
			if not tTickInfo then
				break
			end
			
			if tTickInfo.nTime > nTime then
				break
			end
			
			for _, tQueueData in ipairs( tTickInfo.qTimers ) do
				if not tQueueData.bRemoved and exist( tQueueData.hTimer ) then
					tQueueData.hTimer:Skip( nTime )
				end
			end
			
			table.remove( Timer.qTicks, 1 )
		end
		
		return 1/30
	end, 'TimerThinker' )
end, {
	sName = 'Timer',
})