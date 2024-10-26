local tExceptionModifiers = {
	modifier_spirit_breaker_charge_of_darkness = 1,
	modifier_lycan_shapeshift_speed = 1,
	modifier_rattletrap_jetpack = 1,
	m_kbw_no_speed_limit = 1,
}

m_kbw_unit = class({})

function m_kbw_unit:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function m_kbw_unit:IsHidden()
    return true
end

function m_kbw_unit:OnCreated()
	self.spell_cleave_cd = {}
	self.hParent = self:GetParent()
	if self.hParent:IsRealHero() then
		self.nPlayer = self.hParent:GetPlayerOwnerID()
	end
	self.cour = self.hParent:IsCourier()

	self:StartIntervalThink(FrameTime())

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_unit:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_unit:OnIntervalThink()
	self.bBoss = IsBoss(self.hParent)

	self:StartIntervalThink(-1)
end

function m_kbw_unit:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    }
end

function m_kbw_unit:GetModifierIgnoreMovespeedLimit()
    return 1
end
function m_kbw_unit:GetModifierMoveSpeedBonus_Constant()
    return -self:GetStackCount() -- boots speed override
end

function m_kbw_unit:GetModifierMoveSpeed_Limit()
	if self.cour then
		return
	end
	for sMod in pairs(tExceptionModifiers) do
		if self.hParent:HasModifier(sMod) then
			return
		end
	end
	return 1000
end

local function mult(v, m)
	return 1 - (1 - v) * m
end

function m_kbw_unit:GetModifierIncomingDamage_Percentage(t)
	local v = self.hParent.nDamageResist or 0

	if self.hParent.nAttackResist and t.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		v = mult(v, 1 - self.hParent.nAttackResist)
	end

	if self.bBoss and self.hParent:GetTeam() == DOTA_TEAM_NEUTRALS and t.inflictor then
		local sName = t.inflictor:GetName()
		local nMultiplier = BOSS_DAMAGE_INFLICTORS[ sName ]

		if type( nMultiplier ) == 'function' then
			nMultiplier = nMultiplier( t.inflictor )
		end

		if nMultiplier then
			v = mult(v, nMultiplier)
		end
		
		local veil_buff = self.hParent:FindModifierByName('modifier_item_veil_of_discord_debuff')
		if veil_buff then
			local veil = veil_buff:GetAbility()
			if veil then
				local amp = veil:GetSpecialValueFor('spell_amp')
				v = v * (1 + amp/100)
			end
		end
	end

	return -100 * v
end

function m_kbw_unit:GetModifierStatusResistanceStacking()
	if self.hParent.nStatusAbsorb then
		return 100 * self.hParent.nStatusAbsorb / (self.hParent.nStatusAbsorb + 100)
	end 
end

function m_kbw_unit:OnParentDealDamage(t)
	if self.hParent.nSpellCleave and self.hParent.nSpellCleave > 0 then
		if t.damage_category == DOTA_DAMAGE_CATEGORY_SPELL
		and bit.band(
			t.damage_flags,
			DOTA_DAMAGE_FLAG_REFLECTION
			+ DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
			+ DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
		) == 0 then
			local time = GameRules:GetGameTime()

			local flags = DOTA_UNIT_TARGET_FLAG_NONE
			if t.damage_type ~= DAMAGE_TYPE_MAGICAL then
				flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			end

			local units = Find:UnitsInRadius({
				nTeam = self.hParent:GetTeam(),
				vCenter = t.unit:GetOrigin(),
				nRadius = SPELL_CLEAVE_RADIUS,
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				nFilterFlag = flags,
				fCondition = function(unit)
					return unit ~= t.unit
				end
			})

			local count = #units

			if count > 0 then
				local damage = t.original_damage * math.min(1, self.hParent.nSpellCleave / 100 / count)
				local damage_flags = t.damage_flags + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION

				for _, unit in ipairs(units) do
					ApplyDamage({
						victim = unit,
						attacker = self.hParent,
						ability = t.inflictor,
						damage = damage,
						damage_type = t.damage_type,
						damage_flags = damage_flags, 
					})
				end

				for unit, endtime in pairs(self.spell_cleave_cd) do
					if time >= endtime then
						self.spell_cleave_cd[unit] = nil
					end
				end

				if not self.spell_cleave_cd[t.unit] then
					self.spell_cleave_cd[t.unit] = time + 0.5
					local pos = t.unit:GetOrigin()

					for _, unit in ipairs(units) do
						local particle = ParticleManager:Create('particles/gameplay/effects/spell_cleave.vpcf', PATTACH_CUSTOMORIGIN, 1)
						ParticleManager:SetParticleControlEnt(particle, 0, t.unit, PATTACH_POINT_FOLLOW, 'attach_hitloc', pos, false)
						ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, 'attach_hitloc', unit:GetOrigin(), false)
						ParticleManager:SetParticleFoWProperties(particle, 0, 1, 16)
					end
				end
			end
		end
	end
end