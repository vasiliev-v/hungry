local BASIC_LIST_PATH = 'kbw/items/basic_list'
local env = getfenv(1)
local list = LoadKeyValues('scripts/npc/items2.txt')

for name, t in pairs(list) do
	if type(t) == 'table' and t.ScriptFile == "kbw/items/basic" then
		local item = class{}
		
		local mult = {}
		
		for value in pairs(t.AbilityValues or {}) do
			local mod = GENERIC_MODIFIER_VALUES[value]
			if mod then
				mult[mod] = 0
			end
		end
		
		function item:GetIntrinsicModifierName()
			return 'm_mult'
		end
		
		function item:GetMultModifiers()
			return mult
		end
		
		env[name] = item
	end
end