local PATH = "kbw/abilities/heroes/sniper/shrapnel"

sniper_shrapnel_kbw = class{}

function sniper_shrapnel_kbw:GetAOERadius()
	return self:GetSpecialValueFor('radius')
end

function sniper_shrapnel_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()
	local delay = self:GetSpecialValueFor('delay')
	local radius = self:GetAOERadius()
	local duration = self:GetSpecialValueFor('duration')
	local height = self:GetSpecialValueFor('visual_height')

	local particle = 'particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf'
	particle = ParticleManager:Create(particle, PATTACH_CUSTOMORIGIN, 2)
	ParticleManager:SetParticleControl(particle, 0, GetAttachmentOrigin(caster, 'attach_attack1'))
	ParticleManager:SetParticleControl(particle, 1, pos + Vector(0, 0, height))
	
	caster:EmitSound('Hero_Sniper.ShrapnelShoot')

	Timer(delay, function()
		local aura = CreateAura({
			sModifier = 'm_sniper_shrapnel_kbw',
			hUnit = caster,
			hAbility = self,
			vCenter = pos,
			nRadius = radius,
			bNoStack = true,
			bDead = true,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		})

		AddFOWViewer(caster:GetTeam(), pos, radius, duration, false)

		local particle = 'particles/units/heroes/hero_sniper/sniper_shrapnel.vpcf'
		particle = ParticleManager:Create(particle)
		ParticleManager:SetParticleControl(particle, 0, pos)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
		ParticleManager:SetParticleFoWProperties(particle, 0, 0, radius)

		EmitSoundOnLocationWithCaster(pos, 'KBW.Sniper.Shrapnel.ShatterNoDelay', caster)

		Timer(duration, function()
			aura:Destroy()

			ParticleManager:Fade(particle, true)
		end)
	end)
end

-----------------------------------------------------------

LinkLuaModifier('m_sniper_shrapnel_kbw', PATH, LUA_MODIFIER_MOTION_NONE)

m_sniper_shrapnel_kbw = ModifierClass{}

function m_sniper_shrapnel_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_sniper_shrapnel_kbw:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function m_sniper_shrapnel_kbw:GetModifierPhysicalArmorBonus()
	return -self.armor_reduction
end

function m_sniper_shrapnel_kbw:OnCreated()
	ReadAbilityData(self, {
		'armor_reduction',
		'damage',
		'slow',
		'tick',
	}, function(ability)
		if IsServer() and ability then
			self.damage = self.damage * self.tick
			self.damage_type = ability:GetAbilityDamageType()

			self:StartIntervalThink(self.tick)
		end
	end)
end

function m_sniper_shrapnel_kbw:OnIntervalThink()
	if IsServer() then
		ApplyDamage({
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = self.damage,
			damage_type = self.damage_type
		})
	end
end