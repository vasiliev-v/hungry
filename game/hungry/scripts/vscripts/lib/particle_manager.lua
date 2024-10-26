--[[

ParticleManager:Create( particleName: string [, attachType: number ] [, parent: handle ] [, lifeTime: number, fade: boolean ] ) => particleIndex: number

]]

-- require panorama 'init.js'
require 'lib/lua/base'
require 'lib/timer'

Events:CallAfter( 'Activate', function()
	function ParticleManager:Create( sParticle, ... )
		local qArgs = {...}
		
		if isdotaobject( qArgs[1] ) then
			table.insert( qArgs, 1, PATTACH_ABSORIGIN_FOLLOW )
		elseif qArgs[1] == nil then
			qArgs[1] = PATTACH_WORLDORIGIN
		end
		
		if qArgs[2] ~= nil and not isdotaobject( qArgs[2] ) then
			table.insert( qArgs, 2, nil )
		end
	
		local nParticle = self:CreateParticle( sParticle, qArgs[1], qArgs[2] )
		
		if qArgs[3] then
			self:Fade( nParticle, qArgs[3], qArgs[4] )
		end
		
		return nParticle
	end
	
	function ParticleManager:Fade( nParticle, nDelay, bFaded )
		if type( nDelay ) == 'boolean' then
			nDelay = 0
			bFaded = nDelay
		end

		Timer( nDelay or 0, function()
			self:DestroyParticle( nParticle, not bFaded )
			self:ReleaseParticleIndex( nParticle )
		end )
	end

	function ParticleManager:Animate( nParticle, nPoint, vStart, vTarget, nDuration, bForceEnd )
		nDuration = nDuration or 0
		local vDelta
		
		if nDuration > 0 then
			vDelta = ( vTarget - vStart ) / nDuration
		end

		local hTimer = Timer( function( nTime )
			if nDuration <= 0 then
				bForceEnd = true
				return
			end

			self:SetParticleControl( nParticle, nPoint, vStart )

			vStart = vStart + vDelta * nTime
			nDuration = nDuration - nTime

			return 1/30
		end )

		hTimer.OnDestroy = function()
			if bForceEnd then
				self:SetParticleControl( nParticle, nPoint, vTarget )
			end
		end

		return hTimer
	end

	StaticParticle = StaticParticle or class{}

	function StaticParticle:constructor( sName, ... )
		self.bNull = false
		self.qCall = {}
		self.tParticles = {}
		self.sName = sName

		local tArgs = args( {...}, {
			'number',
			isdotaobject,
			'function',
		})

		self.hParent = tArgs[2]
		self.nAttach = tArgs[1] or ( self.hParent and PATTACH_ABSORIGIN_FOLLOW or PATTACH_WORLDORIGIN )
		self.fCondition = tArgs[3] or function() return true end

		for nPlayer = 0, DOTA_MAX_PLAYERS - 1 do
			self:InitPlayer( nPlayer )
		end

	--	self.nInitListener = CustomGameEventManager:RegisterListenerInited( 'sv_client_init', function( tEvent )
	--		self:InitPlayer( tEvent.PlayerID )
	--	end )
	end

	function StaticParticle:InitPlayer( nPlayer )
		if self:IsNull() then
			return
		end
		
		if PlayerResource:IsValidPlayer( nPlayer ) and self.fCondition( nPlayer ) then
			local nOldParticle = self.tParticles[ nPlayer ]
			if nOldParticle then
				ParticleManager:Fade( nOldParticle )
				self.tParticles[ nPlayer ] = nil
			end

			local hPlayer = PlayerResource:GetPlayer( nPlayer )
			if hPlayer then
				local nParticle = ParticleManager:CreateParticleForPlayer( self.sName, self.nAttach, self.hParent, hPlayer )
				self.tParticles[ nPlayer ] = nParticle

				for _, qCall in ipairs( self.qCall ) do
					local sFunctionName = qCall[1]
					local qArgs = {}
					for i = 2, #qCall do
						table.insert( qArgs, qCall[i] )
					end

					ParticleManager[ sFunctionName ]( ParticleManager, nParticle, table.unpack( qArgs ) )
				end
			end
		end
	end

	function StaticParticle:Destroy( bFaded )
		if self.bNull then
			return
		end

		self.bNull = true

		for nPlayer, nParticle in pairs( self.tParticles ) do
			ParticleManager:Fade( nParticle, bFaded )
		end

		CustomGameEventManager:UnregisterListener( self.nInitListener )

		self.tParticles = nil
		self.nInitListener = nil
	end

	function StaticParticle:IsNull()
		return self.bNull
	end

	local fCopyFunctions = function( tSource )
		for sFunctionName, fCall in pairs( tSource ) do
			if not StaticParticle[ sFunctionName ] and type( fCall ) == 'function' and not sFunctionName:match('Create') then
				StaticParticle[ sFunctionName ] = function( self, ... )
					if self.bNull then
						return
					end

					table.insert( self.qCall, { sFunctionName, ... } )

					for nPlayer, nParticle in pairs( self.tParticles ) do
						fCall( ParticleManager, nParticle, ... )
					end
				end
			end
		end
	end

	local tSource = ParticleManager
	while type( tSource ) == 'table' do
		fCopyFunctions( tSource )
		tSource = ( getmetatable( tSource ) or {} ).__index
	end
end )