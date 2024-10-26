local sURL = "https://dota-kbw.ru/game/donate.php"

local testers = {
	419306496, 1022906984, 1027663033, 395370232, 180850054, 381814077, 79590379, 458720928, 888838564, 327070922,
	1007774718, 211037875, 859735357, 114202099, 303228308, 315376629, 303440462, 104012557, 381784228, 384951963
}
local super_testers = {	463772480, 296670265, 430263167, 311982867 }

Pass.TESTERS = {}
for k, v in pairs( testers ) do
	Pass.TESTERS[v] = true
end
for k, v in pairs( super_testers ) do
	Pass.TESTERS[v] = true
end

local t = {
	-- flower
	-- [171685381] = {
	-- 	Effect = {'EXCLUSIVE_1'},
	-- 	-- Pet = {'SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE','SPIDER_LYCOSIDAE'},
	-- },
	
	-- [1106545564] = {
	-- 	Pet = {'ARMADILLO','PANDA','ICE_WOLF','BABYROSH_LAVA'},
	-- 	Effect = {'GRASS', 'GOLD_WINGS', 'FOUNTAIN_18_3'}
	-- },
	
	-- [1200467410] = {
	-- 	Pet = {'ARMADILLO','ARMADILLO','ARMADILLO','ICE_WOLF','ICE_WOLF','BABYROSH_LAVA'},
	-- 	Effect = {'GRASS', 'GOLD_WINGS'}
	-- },		
	
	-- [201292507] = {
	-- 	Pet = {'ARMADILLO','ARMADILLO','ARMADILLO','ICE_WOLF','ICE_WOLF','SAPPLING','SAPPLING','SAPPLING','SAPPLING'},
	-- 	Effect = {'GRASS', 'GOLD_WINGS'}
	-- },		
	
	-- [259596687] = {
	-- 	Pet = {'ARMADILLO','ARMADILLO','ARMADILLO','ICE_WOLF','ICE_WOLF','SAPPLING','SAPPLING','SAPPLING','SAPPLING'},
	-- 	Effect = {'GRASS', 'GOLD_WINGS'}
	-- },
	-- [128319295] = {
	-- 	Effect = {'GOLD_WINGS'}
	-- },
	-- [201292507] = {
	-- 	Pet = {'SEEKLING','HUNTLING','DOOMLING'},
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [180850054] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [421732227] = {
	-- 	Effect = 'CURSE',
	-- 	Pet = {'BABYROSH_LAVA'}
	-- },
	-- [994130067] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [161116983] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [200405341] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [1017526177] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [235293205] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [137600947] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [159072789] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [874573501] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [331597622] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [935042645] = {
	-- 	Effect = 'GOLD_WINGS'
	-- },
	-- [994130067] = {
	-- 	Pet = {'ICE_WOLF'}
	-- },
	-- [1056466261] = {
	-- 	Pet = {'ICE_WOLF'}
	-- },
}

-- local function add( id, bonus )
-- 	local eff = t[ id ] or {}
-- 	t[ id ] = eff
-- 	for k, v in pairs( bonus ) do
-- 		if type(eff[k]) ~= 'table' then
-- 			eff[k] = {eff[k]}
-- 		end
-- 		if type(v) ~= 'table' then
-- 			v = {v}
-- 		end
-- 		for _, name in pairs(v) do
-- 			table.insert( eff[k], name )
-- 		end
-- 	end
-- end

-- for _, id in pairs( testers ) do
-- 	add( id, {
-- 		Pet = {'PUDGE_DOG'},
-- 		Effect = 'FOUNTAIN_18_3'
-- 	})
-- end

-- for _, id in pairs( super_testers ) do
-- 	add( id, {
-- 		Pet = {'PANDA','PUDGE_DOG'},
-- 		Effect = {'DARK_WINGS','FOUNTAIN_17_3'}
-- 	})
-- end

return t