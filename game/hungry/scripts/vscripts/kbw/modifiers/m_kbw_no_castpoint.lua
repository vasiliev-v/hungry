m_kbw_no_castpoint = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_kbw_no_castpoint:OnCreated()
	if IsServer() then
		self.overriden = {}
		
		self:StartIntervalThink(0.1)
	end
end

function m_kbw_no_castpoint:OnIntervalThink()
	if IsClient() then
		return
	end
	
	local parent = self:GetParent()
	
	for i = 0, parent:GetAbilityCount() - 1 do
		local ability = parent:GetAbilityByIndex(i)
		if ability then
			if not self.overriden[ability] then
				self.overriden[ability] = true
				if bit.band(
					ability:GetBehaviorInt(),
					DOTA_ABILITY_BEHAVIOR_NO_TARGET +
					DOTA_ABILITY_BEHAVIOR_UNIT_TARGET +
					DOTA_ABILITY_BEHAVIOR_POINT 
				) ~= 0 then
					ability:SetOverrideCastPoint(0)
				end
			end
		end
	end
end