modifier_armor_bonus = class({
	IsHidden =      function() return true end,
	IsPurgable =    function() return false end,
	IsBuff =        function() return true end,
})

function modifier_armor_bonus:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_armor_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_armor_bonus:OnCreated()
	self.parent = self:GetParent()
	self.bBoss = IsStatBoss(self.parent)
end

function modifier_armor_bonus:GetModifierPhysicalArmorBonus()
	local nTarget = self:GetStackCount()
	if self.rec then
		return nTarget
	end
	if self.bBoss then
		self.rec = true
		local nArmor = self.parent:GetPhysicalArmorValue(true) - nTarget
		self.rec = nil
		return math.max(nTarget, nTarget * 0.4 - nArmor)
	end
	return nTarget
end