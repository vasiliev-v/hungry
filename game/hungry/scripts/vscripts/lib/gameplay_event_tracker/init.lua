--[[

* Server only

For some reason known only to Valve©, "OnUnitMoved" is called on neutral creeps constantly (regardless of their movement). This will cause lags with 200+ neutrals. If you are making custom neutrals, it's highly recommend to create custom AI for them, instead of using "npc_dota_creep_neutral".

------------------------------------------------------------------------

-- List of enabled events
GameplayEventTracker.tEnabled: table

-- Enable/disable event.
GameplayEventTracker:SetEnabled( sEvent: string, bEnabled: boolean )

]]

if IsClient() then
	return
end

require 'lib/lua/base'

LinkLuaModifier( 'm_gameplay_event_tracker', 'lib/gameplay_event_tracker/m_gameplay_event_tracker', LUA_MODIFIER_MOTION_NONE )

GameplayEventTracker = GameplayEventTracker or {}

GameplayEventTracker.tModifierEvents = GameplayEventTracker.tModifierEvents or {
	OnTakeDamage = MODIFIER_EVENT_ON_TAKEDAMAGE,
	OnAttackStart = MODIFIER_EVENT_ON_ATTACK_START,
	OnAttackRecord = MODIFIER_EVENT_ON_ATTACK_RECORD,
	OnAttack = MODIFIER_EVENT_ON_ATTACK,
	OnAttackLanded = MODIFIER_EVENT_ON_ATTACK_LANDED,
	OnAttackFail = MODIFIER_EVENT_ON_ATTACK_FAIL,
	OnAttackCancel = MODIFIER_EVENT_ON_ATTACK_CANCELLED,
	OnAttackRecordDestroy = MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
	OnAbilityStart = MODIFIER_EVENT_ON_ABILITY_START,
	OnAbilityExecuted = MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	OnAbilityFullyCast = MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	OnAbilityEndChannel = MODIFIER_EVENT_ON_ABILITY_END_CHANNEL,
	OnUnitMoved = MODIFIER_EVENT_ON_UNIT_MOVED,
	OnSetLocation = MODIFIER_EVENT_ON_SET_LOCATION,
	OnDeath = MODIFIER_EVENT_ON_DEATH,
	OnRespawn = MODIFIER_EVENT_ON_RESPAWN,
	OnTakeDamageKillCredit = MODIFIER_EVENT_ON_TAKEDAMAGE_KILLCREDIT,
}

GameplayEventTracker.tDotaEvents = {
	OnNpcSpawned = 'npc_spawned',
}

if not GameplayEventTracker.tEnabled then
	GameplayEventTracker.tEnabled = {}
	for sEvent in pairs( GameplayEventTracker.tModifierEvents ) do
		GameplayEventTracker.tEnabled[ sEvent ] = true
	end
	for sEvent in pairs( GameplayEventTracker.tDotaEvents ) do
		GameplayEventTracker.tEnabled[ sEvent ] = true
	end
end

function GameplayEventTracker:Refresh()
	if exist( self.hModifier ) then
		self.hModifier:Destroy()
	end

	self.hModifier = CreateModifierThinker( GameRules:GetGameModeEntity(), nil, 'm_gameplay_event_tracker', {}, Vector( 0, 0, 0 ), 0, false )
end

function GameplayEventTracker:SetEnabled( sEvent, bEnabled )
	if self.tModifierEvents[ sEvent ] then
		self.tEnabled[ sEvent ] = bEnabled and true or false
	end

	self:Refresh()
end

function GameplayEventTracker:GetTrackerUnit()
	return self.hModifier
end

Events:CallAfter( 'Activate', function()
	GameplayEventTracker:Refresh()
end, {
	sName = 'GameplayEventTracker',
})