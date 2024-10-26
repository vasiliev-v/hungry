--[[

AddModifier( name: string, data: table, callback: function( modifier ) ) => modifier?
	data: {
		hTarget,
		hCaster,
		hAbility,
		bIgnoreStatusResist = ? -> boolean (false),
		bAddToDead = ? -> boolean (false),
		bCalcDeadDuration = ? -> boolean (false),
		bStacks = ? -> boolean (false),
		... -- modifier create data
	}
]]

require 'lib/lua/base'
require 'lib/timer'

local tReserverdNames = {
	hTarget = true,
	hCaster = true,
	hAbility = true,
	bReapply = true,
	bStacks = true,
	bAddToDead = true,
	bCalcDeadDuration = true,
	bIgnoreStatusResist = true,
	nAttempts = true,
}

local tDebuffAmps = {
	modifier_item_arcane_blink_buff = 'debuff_amp',
}

function GetDebuffAmp(hUnit)
	local n = 1
	for _, hMod in ipairs(hUnit:FindAllModifiers()) do
		if hMod:HasFunction(MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER) then
			local sValName = tDebuffAmps[hMod:GetName()]
			if sValName then
				local hAbility = hMod:GetAbility()
				if hAbility then
					n = n + hAbility:GetSpecialValueFor(sValName) / 100
				end
			elseif type(hMod.GetModifierStatusResistanceCaster) == 'function' then
				n = n - hMod:GetModifierStatusResistanceCaster() / 100
			end
		end
	end
	return n
end

function AddModifier( sModifier, tData, fCallback )
    if not exist( tData.hTarget ) then
        printstack('[AddModifier]: No target specified')
        return
    end

	local tModifierData = {}
	local t = {}

	for k, v in pairs( tData ) do
		if tReserverdNames[ k ] then
			t[ k ] = v
		else
			tModifierData[ k ] = v
		end
	end

	if tModifierData.duration and exist( t.hCaster ) and t.hTarget:GetTeam() ~= t.hCaster:GetTeam() then
		if not t.bIgnoreStatusResist then
			tModifierData.duration = tModifierData.duration * ( 1 - t.hTarget:GetStatusResistance() )
		end
		if not t.bIgnoreDebuffAmp then
			tModifierData.duration = tModifierData.duration * GetDebuffAmp(t.hCaster)
		end
	end
	
	local bDuration = ( tModifierData.duration and tModifierData.duration > 0 )

    local hMod
    local nStartTime = GameRules:GetGameTime()

    Timer( function()
        if not exist( t.hTarget ) then
            return
        end

        if not t.hTarget:IsAlive() then
            if not t.bAddToDead then
                return
            end

            return 1/30
        end

        if t.bCalcDeadDuration and bDuration then
            tModifierData.duration = tModifierData.duration + nStartTime - GameRules:GetGameTime()

            if tModifierData.duration <= 0 then
                return
            end
        end

		if t.bReapply then
			t.hTarget:RemoveModifierByName( sModifier )
		end

        if t.bStacks then
            hMod = t.hTarget:FindModifierByName( sModifier )

            if hMod and bDuration then
                hMod:SetDuration( tModifierData.duration, true )
                hMod:ForceRefresh()
            end
        end

        if not hMod then
            hMod = t.hTarget:AddNewModifier( t.hCaster, t.hAbility, sModifier, tModifierData )
        end

		if hMod then
			if t.bStacks then
				hMod:IncrementStackCount()

				if type( hMod.OnChangeStackCount ) == 'function' then
					hMod:OnChangeStackCount()
				end

				if bDuration then
					Timer( tModifierData.duration, function()
						if exist( hMod ) then
							if hMod:GetStackCount() < 2 then
								hMod:Destroy()
							else
								hMod:DecrementStackCount()

								if type( hMod.OnChangeStackCount ) == 'function' then
									hMod:OnChangeStackCount()
								end
							end
						end
					end )
				end
			end

			if type( fCallback ) == 'function' then
				fCallback( hMod )
			end
		else
			if not t.nAttempts or t.nAttempts < 1 then
				-- local sMsg = '[AddModifier]: Failed to create modifier "' .. sModifier .. '" '
				-- if exist( t.hTarget ) then
				-- 	sMsg = sMsg .. 'on target ' .. t.hTarget:GetName()
				-- else
				-- 	sMsg = sMsg .. 'with no target'
				-- end

				printstack( sMsg )
				-- GameRules:SendCustomMessage( sMsg, 0, 0 )
			else
				t.nAttempts = t.nAttempts - 1
				return 1/30
			end
		end
    end )

	return hMod
end