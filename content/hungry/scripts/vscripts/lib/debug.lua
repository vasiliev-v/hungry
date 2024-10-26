Debug = {}

function Debug:Pcall( fRun, fErr, ... )
	local qArgs = {...}

	local bStatus, xResult = xpcall( function()
		return fRun( table.unpack( qArgs ) )
	end, function( sErr )
		fErr( sErr )
	end )

	return xResult, bStatus
end

function Debug:PcallChat( fRun, ... )
	return self:Pcall( fRun, function( sErr )
		GameRules:SendCustomMessage( sErr, 0, 0 )
	end, ... )
end