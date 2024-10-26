-- -- require 'scripts/npc/basis_spells.txt' / basis_use_action
-- require 'lib/lua/base'
-- require 'lib/order_filter'

-- function UseAction( hUnit, xTarget, fCallback, tData )
-- 	tData = table.copy( tData or {} )
-- 	tData.nRange = tData.nRange or 64
-- 	tData.bQueue = tData.bQueue or false

-- 	local hAbility = hUnit:FindAbilityByName('basis_use_action')

-- 	if not hAbility then
-- 		hAbility = hUnit:AddAbility('basis_use_action')

-- 		if hAbility then
-- 			hAbility:SetLevel( 1 )
-- 		else
-- 			printstack('[UseAction]: Cannot create ability basis_use_action')
-- 			return
-- 		end
-- 	end

-- 	local nTarget
-- 	local vTarget
-- 	local nOrder = DOTA_UNIT_ORDER_CAST_POSITION

-- 	if IsVector( xTarget ) then
-- 		vTarget = xTarget
-- 	else
-- 		nTarget = xTarget:entindex()
-- 		nOrder = DOTA_UNIT_ORDER_CAST_TARGET

-- 		if xTarget.GetContainedItem then
-- 			local hMarker = xTarget.hCastTargetMarker

-- 			if not hMarker then
-- 				hMarker = CreateUnitByName( 'npc_dota_base', xTarget:GetOrigin(), false, nil, nil, 0 )
-- 				xTarget.hCastTargetMarker = hMarker

-- 				Timer( function()
-- 					if exist( xTarget ) then
-- 						hMarker:SetAbsOrigin( xTarget:GetOrigin() )
-- 						return 1/30
-- 					else
-- 						hMarker:Destroy()
-- 					end
-- 				end )
-- 			end

-- 			nTarget = hMarker:entindex()

-- 		elseif not IsNPC( xTarget ) then
-- 			nOrder = DOTA_UNIT_ORDER_CAST_TARGET_TREE
-- 		end
-- 	end

-- 	if not tData.bQueue then
-- 		hAbility:ClearCallbacks()
-- 	end

-- 	local tCallbackData = {
-- 		fCallback = fCallback,
-- 		nRange = tData.nRange,
-- 	}

-- 	if nTarget then
-- 		tCallbackData.hTarget = xTarget
-- 	end

-- 	hAbility:AddCallback( tCallbackData )

-- 	ExecuteOrderFromTable({
-- 		OrderType = nOrder,
-- 		UnitIndex = hUnit:entindex(),
-- 		AbilityIndex = hAbility:entindex(),
-- 		TargetIndex = nTarget,
-- 		Position = vTarget,
-- 		Queue = tData.bQueue,
-- 	})
-- end

-- Filters:Register( 'ExecuteOrder', function( t )
-- 	local hAbility = EntIndexToHScript( t.entindex_ability )

-- 	if hAbility and hAbility:GetName() then

-- 	end

-- 	return true
-- end )

-- Events:Register( 'InterruptOrder', function( t )
-- 	for _, nUnitIndex in pairs( t.units ) do
-- 		local hUnit = EntIndexToHScript( nUnitIndex )
-- 		if exist( hUnit ) then
-- 			local hAbility = hUnit:FindAbilityByName('basis_use_action')
-- 			if exist( hAbility ) and t.entindex_ability ~= hAbility:entindex() then
-- 				print'inerrupt'
-- 				hAbility:ClearCallbacks()
-- 			end
-- 		end
-- 	end
-- end, {
-- 	sName = 'UseAction'
-- })