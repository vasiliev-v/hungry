m_kbw_kill_agility = ModifierClass{
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_kill_agility:GetTexture()
	return 'icon_agility'
end

function m_kbw_kill_agility:OnCreated()
	ReadAbilityData( self, {'value'} )

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_kill_agility:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_kill_agility:OnParentKill( t )
	if t.unit:IsRealHero() and t.unit:GetTeam() ~= t.attacker:GetTeam() then
		self:SetStackCount( self:GetStackCount() + self.value )
	end
end

function m_kbw_kill_agility:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	}
end

function m_kbw_kill_agility:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end