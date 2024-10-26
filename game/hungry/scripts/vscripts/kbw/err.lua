require 'lib/debug'

local _pcall = pcall
local _xpcall = xpcall

function track_pcall( f, ... )
	local qArgs = {...}

	local bStatus, xErr = _xpcall( function()
		return f( table.unpack( qArgs ) )
	end, function( sErr )
		xErr = sErr
		printstack( sErr, 2 )
		GameRules:SendCustomMessage( sErr, 0, 0 )
	end )

	return bStatus, xErr
end

pcall = track_pcall
xpcall = track_pcall