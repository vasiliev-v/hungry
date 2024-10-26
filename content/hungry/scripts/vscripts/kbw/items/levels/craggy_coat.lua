local base = {}

function base:GetIntrinsicModifierName()
	return 'm_item_generic_armor'
end

CreateLevels({
	'item_shitmail',
	'item_kbw_craggy_coat',
	'item_kbw_craggy_coat_2',
	'item_kbw_craggy_coat_3',
}, base)