require 'lib/lua/base'

Events:CallAfter( 'Activate', function()
	function PlayerResource:FindUnits( nPlayer, nTypeFilter, nFlagFilter )
		local nTeam = self:GetTeam( nPlayer )
		local nTeamFilter = DOTA_UNIT_TARGET_TEAM_BOTH
		nTypeFilter = nTypeFilter or DOTA_UNIT_TARGET_ALL
		nFlagFilter = nFlagFilter or DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		
		local qUnits = FindUnitsInRadius( nTeam, Vector( 0, 0, 0 ), nil, FIND_UNITS_EVERYWHERE, nTeamFilter, nTypeFilter, nFlagFilter, 0, false )
		
		for i = #qUnits, 1, -1 do
			if qUnits[i]:GetPlayerOwnerID() ~= nPlayer then
				table.remove( qUnits, i )
			end
		end
		
		return qUnits
	end

	PlayerResource.tWrongConnects = {
		[DOTA_CONNECTION_STATE_UNKNOWN] = 1,
		[DOTA_CONNECTION_STATE_ABANDONED] = 1,
		[DOTA_CONNECTION_STATE_FAILED] = 1,
	}

	function PlayerResource:HasClient( nPlayer )
		return self:IsValidPlayer( nPlayer ) and self:GetSteamAccountID( nPlayer ) > 0
			and not self.tWrongConnects[ self:GetConnectionState( nPlayer ) ]
	end
end )