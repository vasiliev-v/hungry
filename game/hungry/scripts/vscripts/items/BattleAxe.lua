function Bash(event)
	local caster = event.caster
	local ability = event.ability

	if caster:IsIllusion() then
		return
	end

	local modifier = caster:FindModifierByNameAndAbility(event.modifierName,ability)
	
	if IsActiveBash(modifier,caster, event.target) then
		--print(event.modifierName,ability)
		local damageTable = {
						 	victim = event.target, 
						 	attacker = caster, 
						 	damage = ability:GetSpecialValueFor("bash_damage"), 
						 	damage_type = DAMAGE_TYPE_MAGICAL,
						 	ability = ability
						}

		ability:ApplyDataDrivenModifier(caster, event.target, "modifier_stunned", {duration = ability:GetSpecialValueFor("bash_stun")})
		ability:StartCooldown(2)
		event.target:EmitSound("DOTA_Item.MKB.Minibash")
	end

end

function IsActiveBash(modifier, caster, target)
	local ability = modifier:GetAbility()
	local random_int = RandomInt(1, 100)
	local bashChance = ability:GetSpecialValueFor("bash_chance")
	if ability:GetCaster():IsRangedAttacker() then
		bashChance = ability:GetSpecialValueFor("bash_chance_range")
	end

	if bashChance < random_int then
		return false
	end

	for _,mod in pairs(ability:GetCaster():FindAllModifiers()) do
		local modAbility = mod:GetAbility()

		if modAbility and modAbility ~= ability and modAbility:GetSpecialValueFor("bash_chance") then
			local modBashChance = modAbility:GetSpecialValueFor("bash_chance")

			if bashChance < modBashChance then
				return false
			elseif bashChance == modBashChance then
				if modifier:GetCreationTime() < mod:GetCreationTime() then
					return false
				end
			end
		end
	end

	if ability:GetCooldownTime() > 0 then
		return false
	end

	if target:HasModifier("modifier_stunned") then
		return false
	end

	if caster:HasItemInInventory("item_abyssal_blade") or caster:HasItemInInventory("item_basher") then
		return false
	end

	return true
end
