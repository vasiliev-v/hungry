require 'lib/lua/base'

KV = {}

KV.UNITS = table.overlay(
    LoadKeyValues('scripts/npc/npc_units.txt'),
    LoadKeyValues('scripts/npc/npc_heroes.txt'),
    LoadKeyValues('scripts/npc/npc_units_custom.txt'),
    LoadKeyValues('scripts/npc/npc_heroes_custom.txt')
)

KV.SPELLS = table.overlay(
    LoadKeyValues('scripts/npc/npc_abilities.txt'),
    LoadKeyValues('scripts/npc/items.txt'),
    LoadKeyValues('scripts/npc/npc_abilities_custom.txt'),
    LoadKeyValues('scripts/npc/npc_abilities_override.txt'),
    LoadKeyValues('scripts/npc/npc_items_custom.txt')
)

function KV:GetSpellValue(sSpell, sValueName, nLevel)
	local tSpell = self.SPELLS[sSpell]
	if not tSpell then
		return 0
	end

	for _, tVal in pairs(tSpell.AbilitySpecial or {}) do
		local sVal = tVal[sValueName]
		if sVal then
			local tVal = string.qmatch(sVal, '[%d%.%-]+')
			return tonumber(tVal[nLevel or 1] or 0)
		end
	end

	return 0
end