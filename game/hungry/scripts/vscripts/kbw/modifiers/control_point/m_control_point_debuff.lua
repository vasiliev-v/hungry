m_control_point_debuff = ModifierClass{}

function m_control_point_debuff:IsDebuff()
	return true
end

function m_control_point_debuff:GetTexture()
	return 'control_point'
end

function m_control_point_debuff:OnCreated()
	if IsServer() then
		self.hParent = self:GetParent()
		self.hAttacker = _G.FOUNTAINS[self.hParent:GetOpposingTeamNumber()]
		self.nInterval = 0.1
		self:StartIntervalThink(0.1)
	end
end

function m_control_point_debuff:OnIntervalThink()
	if self.hAttacker then
		ApplyDamage({
			victim = self.hParent,
			attacker = self.hAttacker,
			damage = self.hParent:GetMaxHealth() * 0.03 * self.nInterval,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT
				+ DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_PROPERTY_FIRE,
		})
	end
end