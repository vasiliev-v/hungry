m_kbw_trident_buff = ModifierClass{
}

function m_kbw_trident_buff:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self.particle = ParticleManager:Create('particles/items/trident/buff.vpcf', PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	end
end

function m_kbw_trident_buff:OnRefresh()
	ReadAbilityData(self, {
		'active_multiplier',
	})
	
	if IsServer() then
		self:RefreshModifiers()
	end
end

function m_kbw_trident_buff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle, true)
		self:RefreshModifiers()
	end
end

function m_kbw_trident_buff:RefreshModifiers()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	if ability and ability.GetMultModifiers then
		Timer(FrameTime(), function()
			if exist(ability) then
				local mult = ability:GetMultModifiers()
				for name in pairs(mult) do
					local mods = parent:FindAllModifiersByName(name)
					for _, mod in ipairs(mods) do
						if mod:GetAbility() == ability then
							mod:ForceRefresh()
						end
					end
				end
			end
		end)
	end
end

function m_kbw_trident_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
	}
end

function m_kbw_trident_buff:GetModifierOverrideAbilitySpecial(t)
	if t.ability == self:GetAbility()
	and t.ability_special_value:match('^%l') and not t.ability_special_value:match('^active') then
		return 1
	end
end

function m_kbw_trident_buff:GetModifierOverrideAbilitySpecialValue(t)
	local value = t.ability:GetLevelSpecialValueNoOverride(t.ability_special_value, t.ability_special_level) * self.active_multiplier
	return value
end