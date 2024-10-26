m_boots_override = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

local function fix_boots_speed(unit)
	local mod_unit = unit:FindModifierByName('m_kbw_unit')
	if not mod_unit then
		return
	end
	local speed = 0
	local mods = unit:FindAllModifiersByName('m_boots_override')
	for _, mod in ipairs(mods) do
		if not mod.stackable and mod.speed > speed then
			speed = mod.speed
		end
	end
	mod_unit:SetStackCount(math.floor(speed + 0.5))
end

function m_boots_override:OnCreated(t)
	ReadAbilityData(self, {
		'bonus_movement_speed',
		'bonus_movement',
	})
	
	self.speed = math.max(self.bonus_movement_speed, self.bonus_movement)
	
	if IsServer() then
		self.stackable = (t.stackable or 0) ~= 0
		self:SetStackCount(self.stackable and 1 or 0)
		if not self.stackable then
			fix_boots_speed(self:GetParent())
		end
	end
end

function m_boots_override:OnDestroy()
	if IsServer() then
		if not self.stackable then
			fix_boots_speed(self:GetParent())		
		end
	end
end

function m_boots_override:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_boots_override:GetModifierMoveSpeedBonus_Constant()
	if self:GetStackCount() ~= 0 then
		return -self.speed
	end
end

function m_boots_override:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end