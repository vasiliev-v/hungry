local PATH = "kbw/abilities/heroes/zuus/thunder"

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- ability

zuus_thunder_kbw = class{}

function zuus_thunder_kbw:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	local particle = 'particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf'
	self.particle = ParticleManager:Create(particle, PATTACH_CUSTOMORIGIN, caster, 2)
	ParticleManager:SetParticleControl(self.particle, 0, caster:GetOrigin())
	ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, 'attach_attack1', Vector(0,0,0), false)
	ParticleManager:SetParticleControlEnt(self.particle, 2, caster, PATTACH_POINT_FOLLOW, 'attach_attack2', Vector(0,0,0), false)

	caster:EmitSound('Hero_Zuus.GodsWrath.PreCast')
end

function zuus_thunder_kbw:OnAbilityPhaseInterrupted()
	if self.particle then
		ParticleManager:Fade(self.particle)
		self.particle = nil
	end
end

function zuus_thunder_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local sight_duration = self:GetSpecialValueFor('sight_duration')
	local damage_delay = self:GetSpecialValueFor('damage_delay')

	caster:EmitSound('Hero_Zuus.GodsWrath')

	local enemies = Find:UnitsInRadius({
		nTeam = caster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO,
	})

	for _, enemy in ipairs(enemies) do
		if enemy:IsRealHero() and not enemy:NotRealHero() then
			AddModifier('m_zuus_thunder_kbw_vision', {
				hTarget = enemy,
				hCaster = caster,
				hAbility = self,
				bIgnoreStatusResist = true,
				duration = sight_duration,
			})

			AddModifier('m_zuus_thunder_kbw_strike', {
				hTarget = enemy,
				hCaster = caster,
				hAbility = self,
				bIgnoreStatusResist = true,
				duration = damage_delay,
			})
		end
	end
end

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- vision modifier

LinkLuaModifier('m_zuus_thunder_kbw_vision', PATH, LUA_MODIFIER_MOTION_NONE)
m_zuus_thunder_kbw_vision = ModifierClass{
	bHidden = true,
	bFountain = true,
}

function m_zuus_thunder_kbw_vision:CheckState()
	if IsServer() and not self.immune then
		return {
			[MODIFIER_STATE_PROVIDES_VISION] = true,
		}
	end
end

function m_zuus_thunder_kbw_vision:OnCreated()
	if IsServer() then
		self.truesight = self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_truesight', {})
	
		self:OnIntervalThink()
		self:StartIntervalThink(FrameTime())
	end
end

function m_zuus_thunder_kbw_vision:OnDestroy()
	if IsServer() then
		if exist(self.truesight) then
			self.truesight:Destroy()
		end
	end
end

function m_zuus_thunder_kbw_vision:OnIntervalThink()
	if IsServer() then
		self.immune = HasState(self:GetParent(), MODIFIER_STATE_TRUESIGHT_IMMUNE)
	end
end

---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------
-- strike modifier

LinkLuaModifier('m_zuus_thunder_kbw_strike', PATH, LUA_MODIFIER_MOTION_NONE)
m_zuus_thunder_kbw_strike = ModifierClass{
	bHidden = true,
	bFountain = true,
}

function m_zuus_thunder_kbw_strike:OnCreated(t)
	ReadAbilityData(self, {
		'safe_radius',
		'safe_offset_min',
		'safe_offset_max',
		'safe_angle_max',
	})

	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local player = parent:GetPlayerOwner()
		local pos = parent:GetOrigin()
		local dir = -parent:GetForwardVector()
		dir.z = 0
		dir = dir:Normalized()

		local angle = math.atan2(dir.y, dir.x)
		angle = angle + RandomFloat(-self.safe_angle_max, self.safe_angle_max) * math.pi / 180
		dir = Vector(math.cos(angle), math.sin(angle), 0)
		self.center = pos + dir * (self.safe_radius + RandomFloat(self.safe_offset_min, self.safe_offset_max))
		self.center = GetGroundPosition(self.center, nil)

		self.particle1 = ParticleManager:CreateParticleForPlayer('particles/units/heroes/hero_zuus/thunder_safe.vpcf', PATTACH_WORLDORIGIN, nil, player)
		ParticleManager:SetParticleControl(self.particle1, 0, self.center)
		ParticleManager:SetParticleControl(self.particle1, 1, Vector(self.safe_radius, 0, 0))
		ParticleManager:SetParticleControl(self.particle1, 7, Vector(0.4, 0.8, 1))
		ParticleManager:SetParticleFoWProperties(self.particle1, 0, 0, 99999)
		
		self.particle2 = ParticleManager:CreateParticleForTeam('particles/units/heroes/hero_zuus/thunder_safe.vpcf', PATTACH_WORLDORIGIN, nil, caster:GetTeam())
		ParticleManager:SetParticleControl(self.particle2, 0, self.center)
		ParticleManager:SetParticleControl(self.particle2, 1, Vector(self.safe_radius, 0, 0))
		ParticleManager:SetParticleControl(self.particle2, 7, Vector(0.8, 0.4, 1))
		ParticleManager:SetParticleFoWProperties(self.particle2, 0, 0, 99999)
		
		self.particle3 = ParticleManager:CreateParticleForTeam('particles/units/heroes/hero_zuus/thunder_safe.vpcf', PATTACH_WORLDORIGIN, nil, 1)
		ParticleManager:SetParticleControl(self.particle3, 0, self.center)
		ParticleManager:SetParticleControl(self.particle3, 1, Vector(self.safe_radius, 0, 0))
		ParticleManager:SetParticleControl(self.particle3, 7, Vector(0.4, 0.8, 1))
		ParticleManager:SetParticleFoWProperties(self.particle3, 0, 0, 99999)
	end

	self:OnRefresh(t)
end

function m_zuus_thunder_kbw_strike:OnRefresh()
	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if not ability then
			return
		end

		local damage = ability:GetSpecialValueFor('damage')

		parent:EmitSoundParams('Hero_Zuus.StaticField', 1.2, 2, 0)

		Timer(self:GetRemainingTime(), function()
			if not exist(parent) or not exist(caster) or not exist(ability) then
				return
			end

			local pos = parent:GetOrigin()
			local team = caster:GetTeam()

			if (parent:GetOrigin() - self.center):Length2D() > self.safe_radius then
				if not parent:IsMagicImmune() then
					ApplyDamage({
						victim = parent,
						attacker = caster,
						ability = ability,
						damage = damage,
						damage_type = ability:GetAbilityDamageType(),
					})
				end

				PlaySound('Hero_Zuus.GodsWrath.Target', pos, team)

				local particle = ParticleManager:Create('particles/units/heroes/hero_zuus/zuus_smaller_lightning_bolt.vpcf', PATTACH_CUSTOMORIGIN, nil, 2)
				ParticleManager:SetParticleControl(particle, 0, pos + Vector(0,0,2000) + RandomVector(RandomFloat(0,350)))
				ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', pos, false)
			else
				parent:EmitSoundParams('Hero_Disruptor.ThunderStrike.Target', 1, 1, 0)

				local particle = ParticleManager:Create('particles/units/heroes/hero_zuus/thunder_saved.vpcf', PATTACH_WORLDORIGIN, 2)
				ParticleManager:SetParticleControl(particle, 0, self.center + Vector(0,0,2000) + RandomVector(RandomFloat(0,1000)))
				ParticleManager:SetParticleControl(particle, 1, self.center)
				ParticleManager:SetParticleControl(particle, 2, self.center)
				ParticleManager:SetParticleControl(particle, 3, self.center)
				ParticleManager:SetParticleControl(particle, 7, Vector(self.safe_radius,0,0))
			end

			AddFOWViewer(team, pos, 128, 0.5, false)
		end)
	end
end

function m_zuus_thunder_kbw_strike:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle1, true)
		ParticleManager:Fade(self.particle2, true)
		ParticleManager:Fade(self.particle3, true)
	end
end