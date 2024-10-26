local base = {}
local PATH = "kbw/items/levels/smoke_grenade"
local PATH_COVER = "kbw/items/camouflage_cover"

LinkLuaModifier('m_item_corrosion_applier', PATH_COVER, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_corrosion_debuff', PATH_COVER, LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------
-- passive effects

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_base = 0,
		m_item_corrosion_applier = 0,
	}
end

---------------------------------------------------------
-- active targeting

function base:GetAOERadius()
	return self:GetSpecialValueFor('screen_radius')
end

function base:CastFilterResultTarget(hTarget)
	if IsClient() and hTarget == self:GetCaster() then
		SendToConsole(KbwBuildAutisticCommand('kbw_self_cast', 1, self:entindex()))
	end
	return UF_FAIL_OTHER
end

---------------------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()
	local team = caster:GetTeam()
	local position = self:GetCursorPosition()
	local radius = self:GetAOERadius()
	local duration = self:GetSpecialValueFor('screen_duration')

	local aura1 = CreateAura({
		hAbility = self,
		nLevel = self.nLevel,
		bNoStack = true,
		sModifier = 'm_item_smoke_grenade_screen_buff',
		nRadius = radius,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		vCenter = position,
	})	
	
	local aura2 = CreateAura({
		hAbility = self,
		nLevel = self.nLevel,
		bNoStack = true,
		sModifier = 'm_item_smoke_grenade_screen_debuff',
		nRadius = radius,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		vCenter = position,
	})

	local effect = 'particles/items/smoke_grenade/xueta.vpcf'
	local particles = {}

	for iteam = 1, DOTA_TEAM_CUSTOM_MAX do
		local particle = ParticleManager:CreateParticleForTeam(effect, PATTACH_WORLDORIGIN, nil, iteam)
		ParticleManager:SetParticleControl(particle, 0, position )
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
		if iteam == team or (iteam == 1 and team == DOTA_TEAM_GOODGUYS) then
			ParticleManager:SetParticleControl(particle, 17, Vector(0.3, 0, 0))
		end
		particles[iteam] = particle
	end

	Timer(duration, function()
		aura1:Destroy()
		aura2:Destroy()
		for _, particle in pairs(particles) do
			ParticleManager:Fade(particle, true)
		end
	end)
		
	EmitSoundOnLocationWithCaster(position, "Hero_Riki.Smoke_Screen", caster)	
	EmitSoundOnLocationWithCaster(position, "DOTA_Item.SmokeOfDeceit.Activate", caster)	
end

---------------------------------------------------------
-- levels

CreateLevels({
    'item_smoke_grenade',
    'item_smoke_grenade_2',
    'item_smoke_grenade_3',
}, base )

---------------------------------------------------------
-- active buff

LinkLuaModifier('m_item_smoke_grenade_screen_buff', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_smoke_grenade_screen_buff = ModifierClass{
}

function m_item_smoke_grenade_screen_buff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()
		local time = GameRules:GetGameTime()

		if parent.__smoke_grenade_charge and parent.__smoke_grenade_charge.time >= time - 0.1 then
			parent.__smoke_grenade_charge.time = time
			self:SetStackCount(parent.__smoke_grenade_charge.charge)
		end

		self.applier = parent:AddNewModifier(self:GetCaster(), self:GetAbility(), 'm_item_corrosion_applier', {})
		if exist(self.applier) then
			self.applier:MakeTemporal()
		end

		self:ApplyInvis(0)

		self:RegisterSelfEvents()
		self:StartIntervalThink(1)
	end
end

function m_item_smoke_grenade_screen_buff:OnRefresh()
	ReadAbilityData(self, {
		'screen_fade',
		'screen_max_stack',
		'screen_max_damage',
		'screen_max_slow',
	})
end

function m_item_smoke_grenade_screen_buff:OnDestroy(t)
	if IsServer() then
		local parent = self:GetParent()

		if parent.__smoke_grenade_charge then
			parent.__smoke_grenade_charge.time = GameRules:GetGameTime()
		end

		if exist(self.applier) then
			self.applier:DestroyTemporal()
		end

		self:DestroyInvis()

		self:UnregisterSelfEvents()
	end
end

function m_item_smoke_grenade_screen_buff:DestroyInvis()
	if exist(self.invis_timer) then
		self.invis_timer:Destroy()
	end

	if exist(self.mod_invis) then
		self.mod_invis:Destroy()
	end
end

function m_item_smoke_grenade_screen_buff:ApplyInvis(delay)
	local parent = self:GetParent()

	self:DestroyInvis()

	self.invis_timer = Timer(delay, function()
		if exist(self) then
			self.mod_invis = parent:AddNewModifier(self:GetCaster(), self:GetAbility(), 'm_item_smoke_grenade_screen_invis', {})
		end
	end)
end

function m_item_smoke_grenade_screen_buff:OnParentAttack()
	self:ApplyInvis(self.screen_fade)
end

function m_item_smoke_grenade_screen_buff:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()
		local charge = math.min(self.screen_max_stack, self:GetStackCount() + 1)
		local k = charge / self.screen_max_stack
		
		self:SetStackCount(charge)
		parent.__smoke_grenade_charge = {
			time = GameRules:GetGameTime(),
			charge = charge,
		}

		if exist(self.applier) then
			self.applier:Empower({
				damage = self.screen_max_damage * k,
				slow = self.screen_max_slow * k,
			})
		end
	end
end

---------------------------------------------------------
-- active debuff

LinkLuaModifier('m_item_smoke_grenade_screen_debuff', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_smoke_grenade_screen_debuff = ModifierClass{
}

function m_item_smoke_grenade_screen_debuff:DeclareFunctions(t)
	return {
		MODIFIER_PROPERTY_FIXED_DAY_VISION,
		MODIFIER_PROPERTY_FIXED_NIGHT_VISION ,
	}
end

function m_item_smoke_grenade_screen_debuff:GetFixedDayVision(t)
	return self.screen_vision
end
function m_item_smoke_grenade_screen_debuff:GetFixedNightVision(t)
	return self.screen_vision
end

function m_item_smoke_grenade_screen_debuff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self:ApplyPoison()
		self:StartIntervalThink(1)
	end
end

function m_item_smoke_grenade_screen_debuff:OnRefresh()
	ReadAbilityData(self, {
		'screen_vision',
		'screen_max_stack',
		'screen_max_damage',
		'screen_max_slow',
	})
end

function m_item_smoke_grenade_screen_debuff:OnIntervalThink()
	if IsServer() then
		self:SetStackCount(math.min(self.screen_max_stack, self:GetStackCount() + 1))
		self:ApplyPoison()
	end
end

function m_item_smoke_grenade_screen_debuff:ApplyPoison()
	local applier
	local ability = self:GetAbility()

	for _, mod in ipairs(self:GetCaster():FindAllModifiersByName('m_item_corrosion_applier')) do
		if mod:GetAbility() == ability then
			applier = mod
			break
		end
	end

	if not applier then
		return
	end

	local k = self:GetStackCount() / self.screen_max_stack

	applier:Apply(self:GetParent(), {
		damage = applier.corrosion_damage + self.screen_max_damage * k,
		slow = applier.corrosion_slow + self.screen_max_slow * k,
	})
end

---------------------------------------------------------
-- active invis

LinkLuaModifier('m_item_smoke_grenade_screen_invis', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_smoke_grenade_screen_invis = ModifierClass{
	bHidden = true,
}

function m_item_smoke_grenade_screen_invis:CheckState()
	if IsServer() then
		local parent = self:GetParent()
		local enemies = Find:UnitsInRadius({
			nTeam = parent:GetTeam(),
			vCenter = parent:GetOrigin(),
			nRadius = self.screen_reveal,
			bNoCollision = true,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		})
		self.hidden = (#enemies == 0)

		return {
			[MODIFIER_STATE_INVISIBLE] = true,
			[MODIFIER_STATE_TRUESIGHT_IMMUNE] = self.hidden or nil,
		}
	end
	return {}
end

function m_item_smoke_grenade_screen_invis:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_item_smoke_grenade_screen_invis:GetModifierInvisibilityLevel()
	return 1
end

function m_item_smoke_grenade_screen_invis:GetModifierTotalDamageOutgoing_Percentage(t)
	if self.hidden and IsBoss(t.target) then
		PreventDamage(t.target)
		return -100
	end
end

function m_item_smoke_grenade_screen_invis:OnCreated()
	ReadAbilityData(self, {
		'screen_reveal',
	})
end