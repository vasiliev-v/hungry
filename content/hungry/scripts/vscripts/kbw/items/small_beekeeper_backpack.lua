local PATH = "kbw/items/small_beekeeper_backpack.lua"
LinkLuaModifier("m_small_beekeeper_backpack_active", PATH, LUA_MODIFIER_MOTION_NONE)

-- item

item_small_beekeeper_backpack = item_small_beekeeper_backpack or class({}) 

function item_small_beekeeper_backpack:GetIntrinsicModifierName()
    return 'm_mult'
end

function item_small_beekeeper_backpack:GetMultModifiers()
    return {
        m_item_generic_base = 0,
        m_item_generic_regen = 0,
        m_item_generic_rune_counter = 0,
    }
end

function item_small_beekeeper_backpack:CastFilterResult()
	if self:GetCurrentCharges() <= 0 then
		self.fail = 1
		return UF_FAIL_CUSTOM
	end
	
	if self:GetCaster():HasModifier('m_small_beekeeper_backpack_active') then
		self.fail = 2
		return UF_FAIL_CUSTOM
	end
end

function item_small_beekeeper_backpack:GetCustomCastError()
	if self.fail == 1 then
		return '#dota_hud_error_no_charges'
	end
	return '#kbw_hud_error_already_affected'
end

function item_small_beekeeper_backpack:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('bees_duration')
	
	AddModifier('m_small_beekeeper_backpack_active', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	AddRuneCharges(caster, -1)
end

-- modifier: active

m_small_beekeeper_backpack_active = ModifierClass{
	bPurgable = true,
}

function m_small_beekeeper_backpack_active:DestroyOnExpire()
	return false
end

function m_small_beekeeper_backpack_active:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		local parent = self:GetParent()
		
		self.particle = ParticleManager:Create('particles/items/bees.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.particle, 3, Vector(self.bees_radius, 0, 0))
		
		parent:EmitSound('Kbw.Item.Beekeeper.Bees')
		
		self:OnIntervalThink()
	end
end

function m_small_beekeeper_backpack_active:OnRefresh(t)
	ReadAbilityData(self, {
		'bees_damage',
		'bees_tick',
		'bees_radius',
	})
	
	self.damage = self.bees_damage * self.bees_tick
	
	if IsServer() then	
		self:StartIntervalThink(self.bees_tick)
	end
end

function m_small_beekeeper_backpack_active:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
	
		ParticleManager:Fade(self.particle, true)
		
		parent:StopSound('Kbw.Item.Beekeeper.Bees')
	end
end

function m_small_beekeeper_backpack_active:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()
		local units = FindUnitsInRadius(
			parent:GetTeam(),
			parent:GetOrigin(),
			parent,
			self.bees_radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)
		
		local count = #units
		
		if count > 0 then
			local damage = self.damage / count
		
			for _, unit in ipairs(units) do
				ApplyDamage({
					victim = unit,
					attacker = parent,
					ability = self:GetAbility(),
					damage = damage,
					damage_type = DAMAGE_TYPE_MAGICAL,
				})
			end
		else
			if self:GetRemainingTime() <= 0 then
				self:Destroy()
			end
		end
	end
end