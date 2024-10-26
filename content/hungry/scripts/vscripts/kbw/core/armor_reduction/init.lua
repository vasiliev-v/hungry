LinkLuaModifier('m_kbw_armor_reduction', PATH .. 'm_kbw_armor_reduction', LUA_MODIFIER_MOTION_NONE)

function _G.ApplyArmorReduction(unit, red, inst)
	if exist(inst) then
		inst:Update(red)
	else
		inst = {}

		function inst:FindModifier()
			local mod = unit:FindModifierByName('m_kbw_armor_reduction')
			if not mod then
				mod = unit:AddNewModifier(unit, nil, 'm_kbw_armor_reduction', {})
			end
			return mod
		end

		function inst:Update(value)
			self.value = value
			local mod = self:FindModifier()
			if mod and mod.Update then
				mod:Update()
			end
		end

		function inst:Create(value)
			self.null = false
			if not unit.__armor_reductors then
				unit.__armor_reductors = {}
			end
			unit.__armor_reductors[self] = true
			self:Update(value)
		end

		function inst:Destroy()
			self:Update(0)
			if unit.__armor_reductors then
				unit.__armor_reductors[self] = nil
				if table.size(unit.__armor_reductors) == 0 then
					unit.__armor_reductors = nil
				end
			end
			self.null = true
		end

		function inst:IsNull()
			return self.null
		end

		function inst:GetValue()
			return self.value
		end

		inst:Create(red)
	end

	return inst
end

function _G.GetBaseArmor(unit)
	unit.GetModifierPhysicalArmorBonus = true
	local armor = unit:GetPhysicalArmorValue(false)
	unit.GetModifierPhysicalArmorBonus = nil
	return armor
end