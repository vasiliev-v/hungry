m_tower_buildup = ModifierClass{
	bPermanent = true,
}

function m_tower_buildup:GetTexture()
	return 'item_repair_kit'
end

function m_tower_buildup:OnCreated()
	local hParent = self:GetParent()
	self.nTeam = hParent:GetTeamNumber()

	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/items5_fx/repair_kit.vpcf', PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.nParticle, 1, hParent:GetOrigin())
		ParticleManager:SetParticleShouldCheckFoW(self.nParticle, false)
	end
end

function m_tower_buildup:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_tower_buildup:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end

function m_tower_buildup:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
	}
end

function m_tower_buildup:GetModifierModelChange()
	if self.nTeam == DOTA_TEAM_BADGUYS then
		return 'models/props_structures/dire_statue002.vmdl'
	end
	return 'models/props_structures/radiant_statue002.vmdl'
end

function m_tower_buildup:GetFixedDayVision()
	return 0.1
end

function m_tower_buildup:GetFixedNightVision()
	return 0.1
end