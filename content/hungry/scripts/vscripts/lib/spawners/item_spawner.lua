require 'lib/lua/base'
require 'lib/spawners/base'

------------------------------------------------------------

ItemSpawner = ItemSpawner or class( {}, {}, SpawnSystem )

function ItemSpawner:constructor()
	super( self ).constructor( self )
	
	self.tItemSpawners = {}
end

function ItemSpawner:AddItem( sItem, nWeight )
	if not self.tItemSpawners[ sItem ] then
		local cNewClass = class( {}, {}, self.SimpleItemSpawner )
		cNewClass.sItem = sItem
		cNewClass.hSpawnSystem = self
		
		self:AddSpawner( cNewClass, nWeight )
		self.tItemSpawners[ sItem ] = cNewClass
	end
end

function ItemSpawner:RemoveItem( sItem )
	local cOldClass = self.tItemSpawners[ sItem ]
	if cOldClass then
		self:RemoveSpawner( cOldClass )
		self.tItemSpawners[ sItem ] = nil
	end
end

function ItemSpawner:OnSpawn( hItem, hDrop )
	
end

function ItemSpawner:OnDestroy(hItem)

end

------------------------------------------------------------

local SimpleItemSpawner = ItemSpawner.SimpleItemSpawner or class( {}, {}, SimpleSpawner )
ItemSpawner.SimpleItemSpawner = SimpleItemSpawner

function SimpleItemSpawner:Spawn( vPos )
	local hItem = CreateItem( self.sItem, nil, nil )
	
	if hItem then
		local hDrop = CreateItemOnPositionForLaunch( vPos, hItem )
		self.hDrop = hDrop
		
		if hDrop then
			local nParticle
			local tItemKV = hItem:GetAbilityKeyValues()
			self.vPos = vPos
			
			if tItemKV.SpawnerParticle then
				local nParticle = ParticleManager:CreateParticle( tItemKV.SpawnerParticle, PATTACH_ABSORIGIN_FOLLOW, hDrop )
			end
				
			Timer( function()
				if not exist( hDrop ) then
					if nParticle then
						ParticleManager:DestroyParticle( nParticle, false )
						ParticleManager:ReleaseParticleIndex( nParticle )
					end

					if self.hSpawnSystem then
						self.hSpawnSystem:OnDestroy(hItem)
					end
				else
					return 0.5
				end
			end )
			
			if tItemKV.SpawnerScale then
				hDrop:SetModelScale( tonumber( tItemKV.SpawnerScale ) or 1 )
			end
			
			if tItemKV.SpawnerColor then
				local qColor = tItemKV.SpawnerColor:qmatch('%d+')
				hDrop:SetRenderColor( tonumber( qColor[1] ) or 255, tonumber( qColor[2] ) or 255, tonumber( qColor[3] ) or 255 )
			end
		end
		
		if self.hSpawnSystem then
			self.hSpawnSystem:OnSpawn( hItem, hDrop )
		end

		return hItem
	else
		printstack( '[ItemSpawner]: Cannot create item with name "' .. tostring( self.sItem ) .. '"!' )
	end
end

function SimpleItemSpawner:Clear()
	if exist( self.hDrop ) then
		if self.vPos and ( self.hDrop:GetOrigin() - self.vPos ):Length2D() < 64 then
			self.hDrop:GetContainedItem():Destroy()
			self.hDrop:Destroy()
		end
		self.hDrop = nil
	end
end

function SimpleItemSpawner:CanSpawn()
	return self:IsEmpty()
end

function SimpleItemSpawner:IsEmpty()
	return not exist( self.hDrop )
end