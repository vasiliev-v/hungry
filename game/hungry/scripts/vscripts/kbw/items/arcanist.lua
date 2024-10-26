local PATH = "kbw/items/arcanist"
LinkLuaModifier('m_item_kbw_blade_mail_return', "kbw/items/blade_mail", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_cast_range_fix = 0,
		m_item_kbw_arcanist_aura = 0,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor('radius')
	local duration = self:GetSpecialValueFor('return_duration')
	
	local units = FindUnitsInRadius(
		caster:GetTeam(),
		caster:GetOrigin(),
		caster,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		FIND_ANY_ORDER,
		false
	)
	
	for _, unit in ipairs(units) do
		AddModifier('m_item_kbw_blade_mail_return', {
			hTarget = unit,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
	end
	
	caster:EmitSound('Item.ForceField.Cast')
end

---------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_arcanist',
	'item_kbw_arcanist_2',
	'item_kbw_arcanist_3',
}, base)

---------------------------------------------------
-- modifier: aura source

LinkLuaModifier('m_item_kbw_arcanist_aura', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_arcanist_aura = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_kbw_arcanist_aura:OnCreated(t)
	ReadAbilityData(self, {
		'radius',
	})
	
	if IsServer() then
		if not self:GetParent():NotRealHero() then
			self.aura = CreateAura({
				sModifier = 'm_item_kbw_arcanist_aura_effect',
				hSource = self,
				nRadius = self.radius,
			})
		end
	end
end

function m_item_kbw_arcanist_aura:OnDestroy()
	if IsServer() then
		if exist(self.aura) then
			self.aura:Destroy()
		end
	end
end

function m_item_kbw_arcanist_aura:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

---------------------------------------------------
-- modifier: aura effect

LinkLuaModifier('m_item_kbw_arcanist_aura_effect', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_arcanist_aura_effect = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_arcanist_aura_effect:OnCreated()
	ReadAbilityData(self, {
		'aura_hp',
	})
end

function m_item_kbw_arcanist_aura_effect:OnRefresh(t)
	-- self:OnDestroy()
	self:OnCreated(t)
end

function m_item_kbw_arcanist_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end

function m_item_kbw_arcanist_aura_effect:GetModifierHealthBonus()
	return self.aura_hp
end