require 'lib/lua/base'
require 'lib/player_resource'
require 'lib/relations'
require 'lib/timer'
require 'lib/finder'
require 'lib/gameplay_event_tracker/init'

Area = Area or class({})

Area.tTracking = Area.tTracking or {}

function Area:IsInside( hUnit )
	if hUnit.GetOrigin then
		hUnit = hUnit:GetOrigin()
	end
	return self:IsPositionInside( hUnit )
end

function Area:IsPositionInside( vPos )
	return true
end

function Area:FindUnits()
	return Find:UnitsInRadius({
		fCondition = function( hUnit )
			return self:IsInside( hUnit )
		end
	})
end

function Area:ForceUpdate()
	local qUnits = self:FindUnits()
	for _, hUnit in ipairs( qUnits ) do
		Area._fUpdateUnit( hUnit, true )
	end
end

function Area:GetCenterDirection( vPos )
	return Vector( 1, 0, 0 )
end

function Area:GetNearestEdgePoint( vPos )
	return zV
end

function Area:PlaceInside( hUnit, _vPrevTry, _nLimit )
	local bPrevTry = _vPrevTry and true or false
	
	if bPrevTry or not self:IsInside( hUnit ) then
		_vPrevTry = _vPrevTry or self:GetNearestEdgePoint( hUnit:GetOrigin() )
		_vPrevTry = _vPrevTry + self:GetCenterDirection( _vPrevTry ) * ( bPrevTry and 64 or 4 )
		
		FindClearSpaceForUnit( hUnit, _vPrevTry, true )
		
		if self:IsInside( hUnit ) then
			return true
		end
		
		_nLimit = _nLimit or 100
		if _nLimit < 1 then
			print( '[Area.PlaceInside]: Cant find corret space!', 2 )
			return true
		end
		
		self:PlaceInside( hUnit, _vPrevTry, _nLimit - 1 )
		return true
	end
	
	return false
end

Area._tUpdatingUnits = Area._tUpdatingUnits or {}

Area._fUpdateUnit = function( hUnit, bForce )
	if not exist(hUnit) then return end
	if not bForce and Area.bUpdating or Area._tUpdatingUnits[ hUnit ] then
		return
	end

	if not exist(hUnit) or not hUnit:IsAlive() then
		return
	end
	
	local bDelayCheck = false
	Area.bUpdating = true

	local qUnitAreaDatas = table.contact( Area.tTracking['ALL'], Area.tTracking[ hUnit ] )
	
	local nPlayer = hUnit:GetPlayerOwnerID()
	if nPlayer >= 0 then
		qUnitAreaDatas = table.contact( qUnitAreaDatas, Area.tTracking[ nPlayer ] )
	end
	
	for _, tAreaData in ipairs( qUnitAreaDatas ) do
		local bOk = not tAreaData.fCondition

		if not bOk then
			bOk, bCheckNext = tAreaData.fCondition( hUnit )

			if bCheckNext then
				bDelayCheck = true
			end
		end

		if bOk then
			local fCallback = tAreaData.hArea.PlaceInside

			if tAreaData.hArea.fCallback then
				fCallback = function( ... )
					local bStatus, xResult = ppcall( tAreaData.hArea.fCallback, ... )

					if bStatus then
						return xResult
					end
				end
			end

			if fCallback( tAreaData.hArea, hUnit ) then
				bDelayCheck = true
				break
			end
		end
	end
	
	if bDelayCheck then
		Area._tUpdatingUnits[ hUnit ] = true
		Timer( 1/30, function()
			Area._tUpdatingUnits[ hUnit ] = nil
			Area._fUpdateUnit( hUnit )
		end )
	end

	Area.bUpdating = nil
end

function Area:Track( xUnit, xTrack )
	if xUnit == nil then
		for xUnit, qUnitAreaDatas in pairs( Area.tTracking ) do
			self:Track( xUnit, false )
		end
		
		return
	end

	local qUnitAreaDatas = Area.tTracking[ xUnit ]
		
	if xTrack then		
		if not qUnitAreaDatas then
			qUnitAreaDatas = {}
			Area.tTracking[ xUnit ] = qUnitAreaDatas
		end
		
		local tAreaData = {
			hArea = self,
		}
		
		if type( xTrack ) == 'function' then
			tAreaData.fCondition = xTrack
		end
		
		local bNew = true
		
		for i, tOtherData in pairs( qUnitAreaDatas ) do
			if tOtherData.hArea == self then
				bNew = false
				qUnitAreaDatas[ i ] = tAreaData
				break
			end
		end
		
		if bNew then
			table.insert( qUnitAreaDatas, tAreaData )
		end
		
		if IsNPC( xUnit ) then
			Area._fUpdateUnit( xUnit )
		elseif type( xUnit ) == 'number' then
			local qUnits = PlayerResource:FindUnits( xUnit )
			
			for _, hUnit in pairs( qUnits ) do
				Area._fUpdateUnit( hUnit )
			end
		elseif xUnit == 'ALL' then
			local qUnits = FindUnitsInRadius( 0, Vector(0,0,0), nil, 99999, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false )
		
			for _, hUnit in pairs( qUnits ) do
				Area._fUpdateUnit( hUnit )
			end
		end
	
		if not Area.bTrackersRegistred then
			Area.bTrackersRegistred = true
			
			local fCallback = function( tEvent )
				if Area.bUpdating then
					return
				end
				
				Area._fUpdateUnit( tEvent.unit )
			end
			
			Events:Register( 'OnUnitMoved', fCallback, { sName = 'Area' } )
			Events:Register( 'OnSetLocation', fCallback, { sName = 'Area' } )

			Events:Register( 'OnNpcSpawned', function( tEvent )
				local hUnit = EntIndexToHScript( tEvent.entindex )

				if hUnit then
					fCallback{ unit = hUnit }
				end
			end )
		end
	else
		if qUnitAreaDatas then
			for i = #qUnitAreaDatas, 1, -1 do
				if qUnitAreaDatas[i].hArea == self then
					table.remove( qUnitAreaDatas, i )
				end
			end
			
			if #qUnitAreaDatas == 0 then
				Area.tTracking[ xUnit ] = nil
			end
		end
	end
end

function Area:SetCallback( fCallback )
	if type( fCallback ) == 'function' then
		self.fCallback = fCallback
	else
		self.fCallback = nil
	end
end

------------------------------------------------------------------------------------------
-- Box

AreaBox = AreaBox or class( {}, {}, Area )

AreaBox.EDGE = {
	TOP = 1,
	LEFT = 3,
	RIGHT = 2,
	BOT = 4,
}

function AreaBox:constructor( nMinX, nMinY, nMaxX, nMaxY, bPushOut )
	self.tBlockedEdges = {}
	self.bPushOut = bPushOut
	self:SetEdges( nMinX, nMinY, nMaxX, nMaxY )
end

function AreaBox:SetEdges( nMinX, nMinY, nMaxX, nMaxY )
	self.nMinX = math.min( nMinX or 0, nMaxX or 0 )
	self.nMinY = math.min( nMinY or 0, nMaxY or 0 )
	self.nMaxX = math.max( nMinX or 0, nMaxX or 0 )
	self.nMaxY = math.max( nMinY or 0, nMaxY or 0 )
end

function AreaBox:IsPositionInside( vPos )
	local bInside = ( vPos.x <= self.nMaxX and vPos.x >= self.nMinX and vPos.y <= self.nMaxY and vPos.y >= self.nMinY )
	return xor( bInside, self.bPushOut )
end

function AreaBox:GetCenterDirection( vPos )
	local tDelta = self:GetDeltas( vPos )
	local vDir = Vector( 0, 0, 0 )
	
	if not tDelta.min then
		return vDir
	end	
	
	if tDelta.r and ( tDelta.r < 0 or tDelta.r == tDelta.min ) then
		vDir.x = vDir.x - 1
	end
	
	if tDelta.l and ( tDelta.l < 0 or tDelta.l == tDelta.min ) then
		vDir.x = vDir.x + 1
	end
	
	if tDelta.t and ( tDelta.t < 0 or tDelta.t == tDelta.min ) then
		vDir.y = vDir.y - 1
	end
	
	if tDelta.b and ( tDelta.b < 0 or tDelta.b == tDelta.min ) then
		vDir.y = vDir.y + 1
	end
	
	return self.bPushOut and -vDir or vDir
end

function AreaBox:GetNearestEdgePoint( vPos )
	local tDelta = self:GetDeltas( vPos )
	local vNewPos = VectorCopy( vPos )
	
	if not tDelta.min then
		return vNewPos
	end
	
	if tDelta.r and ( tDelta.r < 0 or tDelta.r == tDelta.min ) then
		vNewPos.x = self.nMaxX
	end
	
	if tDelta.l and ( tDelta.l < 0 or tDelta.l == tDelta.min ) then
		vNewPos.x = self.nMinX
	end
	
	if tDelta.t and ( tDelta.t < 0 or tDelta.t == tDelta.min ) then
		vNewPos.y = self.nMaxY
	end
	
	if tDelta.b and ( tDelta.b < 0 or tDelta.b == tDelta.min ) then
		vNewPos.y = self.nMinY
	end
	
	return vNewPos
end

function AreaBox:GetDeltas( vPos )
	local tDelta = {}
	
	if not self.tBlockedEdges[ self.EDGE.RIGHT ] then
		tDelta.r = self.nMaxX - vPos.x
		tDelta.min = tDelta.r
	end
	
	if not self.tBlockedEdges[ self.EDGE.LEFT ] then
		tDelta.l = vPos.x - self.nMinX 
		
		if not tDelta.min or tDelta.l < tDelta.min then
			tDelta.min = tDelta.l
		end
	end
	
	if not self.tBlockedEdges[ self.EDGE.TOP ] then
		tDelta.t = self.nMaxY - vPos.y
		
		if not tDelta.min or tDelta.t < tDelta.min then
			tDelta.min = tDelta.t
		end
	end
	
	if not self.tBlockedEdges[ self.EDGE.BOT ] then
		tDelta.b = vPos.y - self.nMinY 
		
		if not tDelta.min or tDelta.b < tDelta.min then
			tDelta.min = tDelta.b
		end
	end
	
	return tDelta
end

function AreaBox:BlockEdge( nEdge, bBlock )
	if table.key( self.EDGE, nEdge ) ~= nil then
		self.tBlockedEdges[ nEdge ] = bBlock and true or nil
	end
end

------------------------------------------------------------------------------------------
-- Circle

AreaCircle = AreaCircle or class( {}, {}, Area )

function AreaCircle:constructor( nX, nY, nRadius, bPushOut )
	self.bPushOut = bPushOut
	self:SetCenter( nX, nY )
	self:SetRadius( nRadius )
end

function AreaCircle:SetCenter( nX, nY )
	self.nX = nX or 0
	self.nY = nY or 0
end

function AreaCircle:GetCenterVector()
	return Vector( self.nX, self.nY, 0 )
end

function AreaCircle:SetRadius( nRadius )
	self.nRadius = nRadius or 0
end

function AreaCircle:IsPositionInside( vPos )
	local bInside = ( ( vPos - self:GetCenterVector() ):Length2D() <= self.nRadius )
	return xor( bInside, self.bPushOut )
end

function AreaCircle:GetCenterDirection( vPos )
	local vDir = self:GetCenterVector() - vPos
	vDir.z = 0
	vDir = vDir:Normalized()

	return self.bPushOut and -vDir or vDir
end

function AreaCircle:GetNearestEdgePoint( vPos )
	local vCenter = self:GetCenterVector()
	local vDir = vPos - vCenter
	vDir.z = 0
	vDir = vDir:Normalized()
	
	return vCenter + vDir * self.nRadius
end