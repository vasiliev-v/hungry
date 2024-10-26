m_tracker = class{}

function m_tracker:AssociateEvents( sDotaEvent, sEvent )
	local nListener = self.tDotaListeners[ sDotaEvent ]
	if nListener then
		StopListeningToGameEvent( nListener )
	end

	nListener = ListenToGameEvent( sDotaEvent, function( tEvent )
		Events:Trigger( sEvent, tEvent )
	end, nil )

	self.tDotaListeners[ sDotaEvent ] = nListener
end

function m_tracker:OnDestroy()
	for sDotaEvent, nListener in pairs( self.tDotaListeners ) do
		StopListeningToGameEvent( nListener )
	end

	self.tDotaListeners = nil
end

function m_tracker:OnCreated()
	self.tDotaListeners = {}

	self:AssociateEvents( 'npc_spawned', 'OnNpcSpawned' )
end

local tModifierEvents = {
	OnTakeDamage = MODIFIER_EVENT_ON_TAKEDAMAGE,
	OnAttack = MODIFIER_EVENT_ON_ATTACK,
	OnAttackLanded = MODIFIER_EVENT_ON_ATTACK_LANDED,
	OnAttackFail = MODIFIER_EVENT_ON_ATTACK_FAIL,
	OnAbilityExecuted = MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	OnAbilityFullyCast = MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	OnUnitMoved = MODIFIER_EVENT_ON_UNIT_MOVED,
	OnSetLocation = MODIFIER_EVENT_ON_SET_LOCATION,
}

_G.tTrack = tTrack or {}
local qFunc = {}

for sEvent, nModifierEvent in pairs( tModifierEvents ) do
    tTrack[ sEvent ] = true
	table.insert( qFunc, nModifierEvent )

    m_tracker[ sEvent ] = function( self, tEvent )
        if tTrack[ sEvent ] then
            Events:Trigger( sEvent, tEvent )

            if tTrackerTest and tEvent.unit then
                tTrackerTest[ sEvent ][ tEvent.unit ] = ( tTrackerTest[ sEvent ][ tEvent.unit ] or 0 ) + 1
            end
        end
	end
end

function m_tracker:DeclareFunctions()
	return qFunc
end