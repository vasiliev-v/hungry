basis_use_action = class{}

function basis_use_action:CastFilterResultTarget()
	return UF_SUCCESS
end

function basis_use_action:GetCastRange( vPos, hTarget )
	if self.qCallbacks then
		local tData = self.qCallbacks[1]
		if tData and tData.nRange then
			return tData.nRange
		end
	end

	return 64
end

function basis_use_action:OnSpellStart()
	if self.qCallbacks then
		local tData = table.remove( self.qCallbacks, 1 )
		if tData and type( tData.fCallback ) == 'function' then
			bSkip = tData.fCallback()
		end
	end
end

function basis_use_action:ClearCallbacks()
	self.qCallbacks = {}
end

function basis_use_action:AddCallback( tData )
	if not self.qCallbacks then
		self.qCallbacks = {}
	end

	table.insert( self.qCallbacks, tData )
end