m_gameplay_event_tracker = class{}

function m_gameplay_event_tracker:AssociateEvents( sDotaEvent, sEvent )
	local nListener = self.tDotaListeners[ sDotaEvent ]
	if nListener then
		StopListeningToGameEvent( nListener )
	end

	nListener = ListenToGameEvent( sDotaEvent, function( tEvent )
		Events:Trigger( sEvent, tEvent )
	end, nil )

	self.tDotaListeners[ sDotaEvent ] = nListener
end

function m_gameplay_event_tracker:OnDestroy()
	for sDotaEvent, nListener in pairs( self.tDotaListeners ) do
		StopListeningToGameEvent( nListener )
	end

	self.tDotaListeners = nil
end

function m_gameplay_event_tracker:OnCreated()
	self.tDotaListeners = {}

	for sEvent, sDotaEvent in pairs( GameplayEventTracker.tDotaEvents ) do
		if GameplayEventTracker.tEnabled[ sEvent ] then
			self:AssociateEvents( sDotaEvent, sEvent )
		end
	end
end

function m_gameplay_event_tracker:DeclareFunctions()
	if IsServer() and not self.bInited then
		self.bInited = true
		local qFunc = {}
		
		for sEvent, nModifierEvent in pairs( GameplayEventTracker.tModifierEvents ) do
			if GameplayEventTracker.tEnabled[ sEvent ] then
				table.insert( qFunc, nModifierEvent )
			
				self[ sEvent ] = function( self, tEvent )
					Events:Trigger( sEvent, tEvent )
				end
			end
		end

		return qFunc
	else
		return {}
	end
end