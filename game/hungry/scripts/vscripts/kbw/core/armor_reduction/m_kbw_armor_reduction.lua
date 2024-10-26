local MIN_ARMOR = -10
local REDUCTION_LIMIT = 50
local MAX_EXPECTED = 200
local reduction_base = 100 / REDUCTION_LIMIT - 1

m_kbw_armor_reduction = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_armor_reduction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_kbw_armor_reduction:GetModifierPhysicalArmorBonus()
	if self.parent.GetModifierPhysicalArmorBonus then
		return 0
	end
	return self:GetStackCount()
end

function m_kbw_armor_reduction:OnCreated()
	self.parent = self:GetParent()

	if IsServer() then
		self.instances = {}
		self:StartIntervalThink(FrameTime())
	end
end

function m_kbw_armor_reduction:GetBaseArmor()
end

function m_kbw_armor_reduction:OnIntervalThink()
	if IsServer() then
		if self.parent.__armor_reductors then
			local armor = GetBaseArmor(self.parent)
			if armor ~= self.armor then
				self.armor = armor
				self:Update({
					armor = armor,
				})
			end
		end
	end
end

function m_kbw_armor_reduction:Update(t)
	if self.parent.__armor_reductors then
		t = t or {}
		t.armor = t.armor or GetBaseArmor(self.parent)
		local armor = math.min(MAX_EXPECTED, t.armor - MIN_ARMOR)
		if armor <= 1 then
			self:SetStackCount(0)
		else
			local value = 0
			for reductor in pairs(self.parent.__armor_reductors) do
				value = value + reductor:GetValue()
			end
			local max = armor * REDUCTION_LIMIT / 100
			if value > max then
				local power = value / max
				value = armor * power / (power + reduction_base)
			end
			self:SetStackCount(-math.floor(value + 0.5))
		end
	else
		self:SetStackCount(0)
	end
end