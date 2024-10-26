require 'lib/lua/base'
require 'lib/timer'

------------------------------------------------------------

SimpleSpawner = SimpleSpawner or class{}

function SimpleSpawner:Spawn( tData )
	print 'simple spawner spawn'
end

function SimpleSpawner:Clear()
	print 'simple spawner clear'
end

function SimpleSpawner:CanSpawn()
	return true
end

function SimpleSpawner:IsEmpty()
	return false
end

------------------------------------------------------------

SpawnSystem = SpawnSystem or class{}

function SpawnSystem:SetInterval( nInterval )
	self.nInterval = nInterval
end

function SpawnSystem:GetInterval()
	return self.nInterval
end

function SpawnSystem:SetSpawnCount( nSpawnCount )
	self.nSpawnCount = nSpawnCount
end

function SpawnSystem:GetSpawnCount()
	return self.nSpawnCount
end

function SpawnSystem:SetClearBeforeSpawn( bClear )
	self.bClear = bClear
end

function SpawnSystem:DoClearBeforeSpawn()
	return self.bClear
end

function SpawnSystem:SetReassignEmptySpawners( bReassignEmpty )
	self.bReassignEmpty = bReassignEmpty
end

function SpawnSystem:DoReassignEmptySpawners()
	return self.bReassignEmpty
end

function SpawnSystem:constructor()
	self.tPoints = {}
	self.tSpawners = {}
	self.nNextPoint = 1
	self.nNextSpawn = 1
	
	self.nInterval = 60
	self.nSpawnCount = -1
	self.bClear = false
	self.bReassignEmpty = true
end

function SpawnSystem:AddSpawnPoint( tData, nWeight )
	local tPoint = {
		tData = tData,
		nIndex = self.nNextPoint,
		nWeight = nWeight or 1,
		hSpawner = nil,
	}
	
	self.tPoints[ tPoint.nIndex ] = tPoint
	self.nNextPoint = self.nNextPoint + 1
	
	return tPoint.nIndex
end

function SpawnSystem:RemoveSpawnPoint( nPoint, bClearSpawner )
	if bClearSpawner then
		local hSpawner = self:GetPointSpawner( nPoint )
		if hSpawner then
			hSpawner:Clear()
		end
	end
	
	self.tPoints[ nPoint ] = nil
end

function SpawnSystem:AddSpawner( cSpawner, nWeight )
	self.tSpawners[ cSpawner ] = nWeight or 1
end

function SpawnSystem:RemoveSpawner( cSpawner )
	self.tSpawners[ cSpawner ] = nil	
end

function SpawnSystem:AssignSpawnerToPoint( nPoint, hSpawner, bClearOld )
	local tPoint = self.tPoints[ nPoint ]
	
	if tPoint then
		if bClearOld then
			self:ClearPoint( nPoint )
		end
	
		tPoint.hSpawner = hSpawner
	end
end

function SpawnSystem:AssignRandomSpawnerToPoint( nPoint, bClearOld )
	local cSpawner = table.random( self.tSpawners, true )
	if cSpawner then
		local hSpawner = cSpawner()
		self:AssignSpawnerToPoint( nPoint, hSpawner, bClearOld )
		return hSpawner
	end
end

function SpawnSystem:GetPointSpawner( nPoint )
	local tPoint = self.tPoints[ nPoint ]
	if tPoint then
		if tPoint.hSpawner then
			return tPoint.hSpawner
		end
		
		return self:AssignRandomSpawnerToPoint( nPoint )
	end
end

function SpawnSystem:GetPointWeight( nPoint )
	local tPoint = self.tPoints[ nPoint ]
	if tPoint then
		return tPoint.nWeight or 0
	end
	
	return 0
end

function SpawnSystem:GetPointData( nPoint )
	local tPoint = self.tPoints[ nPoint ]
	if tPoint then
		return tPoint.tData
	end
end

function SpawnSystem:SpawnPoint( nPoint )
	local hSpawner = self:GetPointSpawner( nPoint )
	if hSpawner and hSpawner:CanSpawn() then
		hSpawner:Spawn( self:GetPointData( nPoint ) )
	end
end

function SpawnSystem:CanPointSpawn( nPoint )
	local hSpawner = self:GetPointSpawner( nPoint )
	
	if hSpawner then
		return hSpawner:CanSpawn()
	end
	
	return false
end

function SpawnSystem:ClearPoint( nPoint )
	local hSpawner = self:GetPointSpawner( nPoint )
	if hSpawner then
		hSpawner:Clear()
	end
end

function SpawnSystem:ReassignSpawnersToPoints( bEmptyOnly, bClearOld )
	for nPoint, tPoint in pairs( self.tPoints ) do
		local bSkip = false
		
		if bEmptyOnly then
			local hSpawner = self:GetPointSpawner( nPoint )
			if hSpawner and not hSpawner:IsEmpty() then
				bSkip = true
			end
		end
		
		if not bSkip then
			self:AssignRandomSpawnerToPoint( nPoint, bClearOld )
		end
	end
end

function SpawnSystem:GetNextSpawnNumber()
	return self.nNextSpawn
end

function SpawnSystem:Reset()
	self.nNextSpawn = 1
	self:Clear()
	self:ReassignSpawnersToPoints()
end

function SpawnSystem:Start( nDelay )
	self:Stop()

	self.hTimer = Timer( nDelay or 0, function()
		self:Spawn( true )
		
		return self:GetInterval()
	end )
end

function SpawnSystem:Stop()
	if exist( self.hTimer ) then
		self.hTimer:Destroy()
		self.hTimer = nil
	end
end

function SpawnSystem:Spawn( bSequencive )
	if self:DoClearBeforeSpawn() then
		self:Clear()
	end
	
	if self:DoReassignEmptySpawners() then
		self:ReassignSpawnersToPoints( true, true )
	end

	local nSpawnCount = tonumber( self:GetSpawnCount() ) or -1
	local tPoints = {}
	
	for nPoint in pairs( self.tPoints ) do
		if self:CanPointSpawn( nPoint ) then
			tPoints[ nPoint ] = self:GetPointWeight( nPoint )
		end
	end
	
	while true do
		if nSpawnCount == 0 then
			break
		end
		
		local nPoint = table.random( tPoints, true )
		
		if not nPoint then
			break
		end
		
		self:SpawnPoint( nPoint )
		
		tPoints[ nPoint ] = nil
		
		if nSpawnCount > 0 then
			nSpawnCount = nSpawnCount - 1
		end
	end
	
	if bSequencive then
		self.nNextSpawn = self.nNextSpawn + 1
	end
end

function SpawnSystem:Clear()
	for nPoint in pairs( self.tPoints ) do
		self:ClearPoint( nPoint )
	end
end