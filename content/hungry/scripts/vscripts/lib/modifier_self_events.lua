require 'lib/lua/base'
require 'lib/gameplay_event_tracker/init'

_tSelfModifiers = _tSelfModifiers or {}

local tSelfEvents = {
	OnParentTakeDamage = {
		sEvent = 'OnTakeDamage',
		sTarget = 'unit',
	},
	OnParentDealDamage = {
		sEvent = 'OnTakeDamage',
		sTarget = 'attacker',
	},
	OnParentAttackStart = {
		sEvent = 'OnAttackStart',
		sTarget = 'attacker',
	},
	OnParentAttackRecord = {
		sEvent = 'OnAttackRecord',
		sTarget = 'attacker',
	},
	OnParentAttack = {
		sEvent = 'OnAttack',
		sTarget = 'attacker',
	},
	OnParentAttackLanded = {
		sEvent = 'OnAttackLanded',
		sTarget = 'attacker',
	},
    OnParentTakeAttackLanded = {
        sEvent = 'OnAttackLanded',
        sTarget = 'target',
    },
	OnParentAttackFail = {
		sEvent = 'OnAttackFail',
		sTarget = 'attacker',
	},
	OnParentAttackCancel = {
		sEvent = 'OnAttackCancel',
		sTarget = 'attacker',
	},
	OnParentAttackRecordDestroy = {
		sEvent = 'OnAttackRecordDestroy',
		sTarget = 'attacker',
	},
	OnParentAbilityExecuted = {
		sEvent = 'OnAbilityExecuted',
		sTarget = 'unit',
	},
	OnParentAbilityFullyCast = {
		sEvent = 'OnAbilityFullyCast',
		sTarget = 'unit',
	},
	OnParentKill = {
		sEvent = 'OnDeath',
		sTarget = 'attacker',
	},
	OnParentDead = {
		sEvent = 'OnDeath',
		sTarget = 'unit',
	},
	OnParentRespawn = {
		sEvent = 'OnRespawn',
		sTarget = 'unit',
	},
	OnParentTakeDamageKillCredit = {
		sEvent = 'OnTakeDamageKillCredit',
		sTarget = 'target',
	},
}

for sCallbackName, tData in pairs( tSelfEvents ) do
	local tEventUnits = _tSelfModifiers[ sCallbackName ]

	if not tEventUnits then
		tEventUnits = {}
		_tSelfModifiers[ sCallbackName ] = tEventUnits
	end

	Events:Register( tData.sEvent, function( tEvent )
		local hTarget = tEvent[ tData.sTarget ]
		if exist( hTarget ) then
			local qModifiers = tEventUnits[ hTarget ]
			if qModifiers then
				local i = 1 while i <= #qModifiers do
					local hMod = qModifiers[ i ]
					if hMod then
						if hMod:IsNull() then
							hMod:UnregisterSelfEvents()
						else
							hMod[ sCallbackName ]( hMod, tEvent )
							i = i + 1
						end
					end
				end
			end
		end
	end, {
		sName = 'ModifierSelfEvents_' .. sCallbackName,
	})
end

function CDOTA_Buff:UnregisterSelfEvents()

end

function CDOTA_Buff:RegisterSelfEvents()
	self:UnregisterSelfEvents()

	local hParent = self:GetParent()
	local tRegisteredEvents = {}

	for sCallbackName in pairs( tSelfEvents ) do
		if type( self[ sCallbackName ] ) == 'function' then
			tRegisteredEvents[ sCallbackName ] = true

			local tEventUnits = _tSelfModifiers[ sCallbackName ]
			local qModifiers = tEventUnits[ hParent ]

			if qModifiers then
				table.insert( qModifiers, self )
			else
				tEventUnits[ hParent ] = { self }
			end
		end
	end

	function self:UnregisterSelfEvents()
		for sCallbackName in pairs( tRegisteredEvents ) do
			local tEventUnits = _tSelfModifiers[ sCallbackName ]
			local qModifiers = tEventUnits[ hParent ]

			if qModifiers then
				local nIndex = table.key( qModifiers, self )
				if nIndex then
					table.remove( qModifiers, nIndex )

					if #qModifiers == 0 then
						tEventUnits[ hParent ] = nil
					end
				end
			end
		end

		self.UnregisterSelfEvents = nil
	end
end