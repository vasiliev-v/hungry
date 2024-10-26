local PATH = "kbw/items/drum"

item_kbw_drum = class{}

function item_kbw_drum:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_kbw_drum:GetMultModifiers()
	return {
		m_item_generic_stats = -1,
		m_item_kbw_drum = 1,
	}
end

function item_kbw_drum:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor('radius')
	local duration = self:GetSpecialValueFor('active_duration')
	local allies = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetOrigin(),
		caster,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, ally in ipairs(allies) do
		AddModifier('m_item_kbw_drum_active', {
			hTarget = ally,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
	end

	caster:EmitSound('DOTA_Item.DoE.Activate')
end

------------------------------

LinkLuaModifier('m_item_kbw_drum', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_drum = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_item_kbw_drum:OnCreated(t)
	ReadAbilityData(self, {
		'radius',
	})

	if IsServer() then
		self.aura = CreateAura{
			hSource = self,
			sModifier = 'm_item_kbw_drum_effect',
			nRadius = self.radius,
			bNoStack = true,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		}
	end
end

function m_item_kbw_drum:OnDestroy(t)
	if exist(self.aura) then
		self.aura:Destroy()
	end
end

function m_item_kbw_drum:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

------------------------------

LinkLuaModifier('m_item_kbw_drum_effect', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_drum_effect = ModifierClass{}

function m_item_kbw_drum_effect:OnCreated(t)
	self:OnRefresh(t)
end

function m_item_kbw_drum_effect:OnRefresh(t)
	ReadAbilityData(self, {
		'aura_speed',
		'aura_regen',
	})
end

function m_item_kbw_drum_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function m_item_kbw_drum_effect:GetModifierMoveSpeedBonus_Percentage()
	return self.aura_speed
end
function m_item_kbw_drum_effect:GetModifierConstantHealthRegen()
	return self.aura_regen
end

------------------------------

LinkLuaModifier('m_item_kbw_drum_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_drum_active = ModifierClass{
	bPurgable = true,
	bMultiple = true,
}

function m_item_kbw_drum_active:OnCreated()
	local parent = self:GetParent()

	ReadAbilityData(self, {
		'active_attack',
		'active_speed_pct',
		'active_max_hp_regen',
		'active_max_hp_regen_creep',
	}, function()
		self.max_hp_regen =	(parent:IsHero() or IsBoss(parent))
			and self.active_max_hp_regen
			or self.active_max_hp_regen_creep
	end)

	if IsServer() then
		self.particle = ParticleManager:Create('particles/items_fx/drum_of_endurance_buff.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), false)
	end
end

function m_item_kbw_drum_active:OnDestroy()
	if IsServer() then
		if self.particle then
			ParticleManager:Fade(self.particle, true)
		end
	end
end

function m_item_kbw_drum_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_item_kbw_drum_active:GetModifierMoveSpeedBonus_Percentage()
	return self.active_speed_pct
end
function m_item_kbw_drum_active:GetModifierAttackSpeedBonus_Constant()
	return self.active_attack
end
function m_item_kbw_drum_active:GetModifierConstantHealthRegen()
	return self:GetParent():GetMaxHealth() * self.max_hp_regen / 100
end
function m_item_kbw_drum_active:OnTooltip()
	return self.max_hp_regen
end