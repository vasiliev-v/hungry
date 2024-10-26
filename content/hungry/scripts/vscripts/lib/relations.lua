require 'lib/lua/base'

function IsNPC( obj )
	return isdotaobject( obj ) and exist( obj ) and type( obj.IsBaseNPC ) == 'function' and obj:IsBaseNPC()
end