function LiA:FilterDamage( filterTable )
	--for k, v in pairs( filterTable ) do
	--	print("Damage: " .. k .. " " .. tostring(v) )
	--end
	local victim_index = filterTable["entindex_victim_const"]
	local attacker_index = filterTable["entindex_attacker_const"]
	local inflictor_index = filterTable["entindex_inflictor_const"] or -1
	--print(inflictor_index)
	if not victim_index or not attacker_index then
		return true
	end

	local victim = EntIndexToHScript( victim_index )
	local attacker = EntIndexToHScript( attacker_index )
	local inflictor = EntIndexToHScript( inflictor_index )

	if string.match(attacker:GetUnitName(), "boss") and victim:IsIllusion() then
		filterTable.damage = filterTable.damage * 3
	end

	return true
end
