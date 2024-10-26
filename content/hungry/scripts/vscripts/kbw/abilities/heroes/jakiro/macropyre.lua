local PATH = 'kbw/abilities/heroes/jakiro/macropyre'

-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-- ability

jakiro_macropyre_kbw = class{}

function jakiro_macropyre_kbw:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor('duration')
	local radius = self:GetSpecialValueFor('radius')
	local interval = self:GetSpecialValueFor('interval')
	local linger_duration = self:GetSpecialValueFor('linger_duration')
	local range = self:GetEffectiveCastRange(target, nil)
	local endtime = GameRules:GetGameTime() + duration
	
	-- target geometry
	local start = caster:GetOrigin()
	local dir = target - start
	dir.z = 0
	dir = dir:Normalized()
	target = GetGroundPosition(start + dir * range, nil)
	start = GetGroundPosition(start + dir * radius, nil)
	
	-- tracking
	Timer(function()
		if not exist(self) or GameRules:GetGameTime() >= endtime then
			return
		end
		
		local enemies = FindUnitsInLine(
			caster:GetTeam(),
			start,
			target,
			nil,
			radius,
			GetAbilityTargetTeam(self),
			GetAbilityTargetType(self),
			GetAbilityTargetFlags(self)
		)
		for _, enemy in ipairs(enemies) do
			AddModifier('m_jakiro_macropyre_kbw_debuff', {
				hTarget = enemy,
				hCaster = caster,
				hAbility = self,
				duration = linger_duration + FrameTime(),
			})
		end
		
		return interval
	end)

	-- visual
	local particle = 'particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf'
	particle = ParticleManager:Create(particle, PATTACH_WORLDORIGIN, duration + 5)
	ParticleManager:SetParticleControl(particle, 0, start)
	ParticleManager:SetParticleControl(particle, 1, target)
	ParticleManager:SetParticleControl(particle, 2, Vector(duration, 0, 0))
	ParticleManager:SetParticleFoWProperties(particle, 0, 1, radius)
	
	-- sound
	caster:EmitSound('Hero_Jakiro.Macropyre.Cast')
end

-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-- burn debuff

LinkLuaModifier('m_jakiro_macropyre_kbw_debuff', PATH, LUA_MODIFIER_MOTION_NONE)
m_jakiro_macropyre_kbw_debuff = ModifierClass{
}

function m_jakiro_macropyre_kbw_debuff:OnCreated(t)
	local ability = self:GetAbility()
	if not ability then
		return
	end
	
	self.interval = ability:GetSpecialValueFor('interval')
	
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()
		self.damage_type = ability:GetAbilityDamageType()
		
		-- visual
		self.particle = ParticleManager:Create('particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf', parent)
	
		-- start think
		self:OnIntervalThink()
		self:StartIntervalThink(self.interval)
	end
end

function m_jakiro_macropyre_kbw_debuff:OnRefresh(t)
	local ability = self:GetAbility()
	if not ability then
		return
	end
	
	self.damage = ability:GetSpecialValueFor('damage') * self.interval
end
	
function m_jakiro_macropyre_kbw_debuff:OnDestroy()
	if IsServer() then
		-- destroy visual
		ParticleManager:Fade(self.particle, true)
	end
end
	
function m_jakiro_macropyre_kbw_debuff:OnIntervalThink()
	if IsClient() then
		return
	end
	
	local parent = self:GetParent()
	
	--damage
	local damage = ApplyDamage({
		victim = parent,
		attacker = self:GetCaster(),
		ability = self:GetAbility(),
		damage = self.damage,
		damage_type = self.damage_type,
	})
	
	--damage display
	if damage > 1 then
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, parent, damage, nil)
	end
end