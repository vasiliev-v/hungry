Find = {}

local function fParseTeam( nTeam, hSource )
	if nTeam then
		return nTeam
	end

	if not hSource or type( hSource.GetTeam ) ~= 'function' then
		return 0
	end

	return hSource:GetTeam()
end

local function fParseVector( vSource )
	if not vSource then
		return Vector( 0, 0, 0 )
	end

	if type( vSource.GetOrigin ) == 'function' then
		return vSource:GetOrigin()
	end

	return vSource
end

function Find:UnitsInRadius( t )
    t = t or {}
	t.nTeam = fParseTeam( t.nTeam, t.vCenter )
	t.vCenter = fParseVector( t.vCenter )
    t.nRadius = t.nRadius or 99999
    t.nFilterTeam = t.nFilterTeam or DOTA_UNIT_TARGET_TEAM_BOTH
    t.nFilterType = t.nFilterType or DOTA_UNIT_TARGET_ALL
    t.nFilterFlag = t.nFilterFlag or (DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
    t.nOrder = t.nOrder or FIND_ANY_ORDER

    t.nFilterType = binor( t.nFilterType, t.nFilterType_ or 0 )
    t.nFilterFlag = binor( t.nFilterFlag, t.nFilterFlag_ or 0 )

    local qUnits = FindUnitsInRadius( t.nTeam, t.vCenter, nil, t.nRadius, t.nFilterTeam, t.nFilterType, t.nFilterFlag, t.nOrder, false )

	if t.bNoCollision then
		qUnits = table.filter(qUnits, function(unit)
			return (unit:GetOrigin() - t.vCenter):Length2D() <= t.nRadius
		end)
	end

    if type( t.fCondition ) == 'function' then
		qUnits = table.filter( qUnits, t.fCondition )
    end

    return qUnits
end

function Find:UnitsInLine( t )
	t = t or {}
	t.nTeam = fParseTeam( t.nTeam, t.vStart )
	t.vStart = fParseVector( t.vStart )
	t.vEnd = fParseVector( t.vEnd )
	t.nWidth = t.nWidth or 0
	t.nFilterTeam = t.nFilterTeam or DOTA_UNIT_TARGET_TEAM_BOTH
    t.nFilterType = t.nFilterType or DOTA_UNIT_TARGET_ALL
    t.nFilterFlag = t.nFilterFlag or (DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)

	if t.bStartOffset then
		t.vStart = t.vStart + ( t.vEnd - t.vStart ):Normalized() * t.nWidth
	end

	local qUnits = FindUnitsInLine( t.nTeam, t.vStart, t.vEnd, nil, t.nWidth, t.nFilterTeam, t.nFilterType, t.nFilterFlag )

	if type( t.fCondition ) == 'function' then
		qUnits = table.filter( qUnits, t.fCondition )
	end

	return qUnits
end