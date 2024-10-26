require 'lib/lua/base'
require 'lib/filters'

local tCastOrders = {
	DOTA_UNIT_ORDER_CAST_POSITION = true,
	DOTA_UNIT_ORDER_CAST_TARGET = true,
	DOTA_UNIT_ORDER_CAST_TARGET_TREE = true,
	DOTA_UNIT_ORDER_CAST_NO_TARGET = true,
	DOTA_UNIT_ORDER_CAST_TOGGLE = true,
	DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO = true,
	DOTA_UNIT_ORDER_CAST_RUNE = true,
}

local tNotInterruptOrders = {
	[DOTA_UNIT_ORDER_NONE] = true,
	[DOTA_UNIT_ORDER_TRAIN_ABILITY] = true,
	[DOTA_UNIT_ORDER_PURCHASE_ITEM] = true,
	[DOTA_UNIT_ORDER_SELL_ITEM] = true,
	[DOTA_UNIT_ORDER_DISASSEMBLE_ITEM] = true,
	[DOTA_UNIT_ORDER_MOVE_ITEM] = true,
	[DOTA_UNIT_ORDER_CAST_TOGGLE] = true,
	[DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO] = true,
	[DOTA_UNIT_ORDER_TAUNT] = true,
	[DOTA_UNIT_ORDER_GLYPH] = true,
	[DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH] = true,
	[DOTA_UNIT_ORDER_PING_ABILITY] = true,
	[DOTA_UNIT_ORDER_RADAR] = true,
	[DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK] = true,
	[DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN] = true,
	[DOTA_UNIT_ORDER_TAKE_ITEM_FROM_NEUTRAL_ITEM_STASH] = true,
}

_G.tNotInterruptingSequence = tNotInterruptingSequence or {}

function IsCastOrder( t )
	return tCastOrders[ t.order_type ] or false
end

function IsInterruptOrder( t, bIgnoreQueue )
	if not bIgnoreQueue and t.queue ~= 0 then
		return false
	end

	if tNotInterruptOrders[ t.order_type ] then
		return false
	end

	if tNotInterruptingSequence[ t.sequence_number_const ] then
		tNotInterruptingSequence[ t.sequence_number_const ] = nil
		return false
	end

	if IsCastOrder( t ) then
		local hAbility = EntIndexToHScript( t.entindex_ability )
		if exist( hAbility ) and binhas( hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_IMMEDIATE ) then
			return false
		end
	end

	return true
end

Filters:Register( 'ExecuteOrder', function( t, fAddFinal )
	if IsInterruptOrder( t, true ) then
		print( 'q', t.queue )
		if t.queue == 0 then
			fAddFinal( function()
				Events:Trigger( 'InterruptOrder', t )
			end )
		else
			tNotInterruptingSequence[ t.sequence_number_const ] = true
		end
	end

	return true
end, {
	sName = 'lib/order_filter'
})