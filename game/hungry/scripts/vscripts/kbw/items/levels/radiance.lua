local PATH = "kbw/items/levels/radiance"

-- item

local base = {}

-- local tTextures = {
-- 	[false] = {
-- 		'candle',
-- 		'radiance',
-- 		'radiance2',
-- 		'radiance3',
-- 	},
-- 	[true] = {
-- 		'candle_off',
-- 		'radiance_off',
-- 		'radiance_off2',
-- 		'radiance_off3',
-- 	},
-- }

-- function base:GetAbilityTextureName( bToggle )
-- 	if bToggle == nil then
-- 		bToggle = self:GetToggleState()
-- 	end

-- 	return tTextures[ bToggle ][ self.nLevel ]
-- end

-- function base:ResetToggleOnRespawn()
-- 	return false
-- end

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_generic_stats = 0,
        m_item_generic_base = 0,
        m_item_generic_regen = 0,
        m_item_generic_armor = 0,
        m_item_generic_status_absorb = 0,
        m_item_generic_rune_counter = 0,
        m_item_kbw_radiance_aura = self.nLevel,
    }
end

function base:CastFilterResult()
	if self:GetCurrentCharges() <= 0 then
		self.fail = 1
		return UF_FAIL_CUSTOM
	end
	
	if self:GetCaster():HasModifier('m_item_kbw_radiance_flame') then
		self.fail = 2
		return UF_FAIL_CUSTOM
	end
end

function base:GetCustomCastError()
	if self.fail == 1 then
		return '#dota_hud_error_no_charges'
	end
	return '#kbw_hud_error_already_affected'
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('flame_duration')
	
	AddModifier('m_item_kbw_radiance_flame', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	AddRuneCharges(caster, -1)
end

--[[
function base:OnToggle()
	local hCaster = self:GetCaster()
	local hMod = hCaster:FindModifierByName('m_item_kbw_radiance_aura')
	local bToggle = self:GetToggleState()

	if hMod and hMod:GetAbility() == self then
		hMod:Toggle( bToggle )
	end

	if self.bForceToggle then
		return
	end

	IterateInventory( hCaster, 'ACTIVE', function( nSlot, hItem )
		if exist( hItem ) and self:IsSameItem( hItem ) and hItem ~= self and hItem:GetToggleState() ~= bToggle then
			hItem:ForceToggle()
		end
	end)
end

function base:ForceToggle()
	self.bForceToggle = true
	self:ToggleAbility()
	self.bForceToggle = nil
end
]]

-- levels

CreateLevels({
	'item_candle',
    'item_kbw_radiance',
    'item_kbw_radiance_2',
    'item_kbw_radiance_3',
}, base )

-- modifier: burn source

LinkLuaModifier( 'm_item_kbw_radiance_aura', PATH, 0 )
m_item_kbw_radiance_aura = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_radiance_aura:OnCreated(t)
    ReadAbilityData( self, {
        'burn_radius',
    }, function( ability )
		if IsServer() then
			self.ability = ability
			local parent = self:GetParent()

			if not parent:IsMonkeyKingShit() then
				self.aura = CreateAura({
					hSource = self,
					sModifier = 'm_item_kbw_radiance_debuff',
					nRadius = self.burn_radius,
					nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				})
			
				self.particle = ParticleManager:CreateParticle( "particles/items2_fx/radiance_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
			end
		end
	end )
end

function m_item_kbw_radiance_aura:OnRefresh(t)
    self:OnDestroy()
	self:OnCreated(t)
end

--[[
function m_item_kbw_radiance_aura:Toggle( bToggle )
	if IsServer() then
		if self.aura and self.bToggle ~= bToggle then
			self.bToggle = bToggle

			self.aura.bActive = not bToggle

			if self.nParticle then
				ParticleManager:Fade( self.nParticle, true )
			end

			if not bToggle then
				self.nParticle = ParticleManager:CreateParticle( "particles/items2_fx/radiance_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
			end
		end
	end
end
]]

function m_item_kbw_radiance_aura:OnDestroy()
	if IsServer() then
		if exist(self.aura) then
			self.aura:Destroy()
		end
	
		if self.particle then
			ParticleManager:Fade(self.particle, true)
		end
	end
end

-- modifier: burn

LinkLuaModifier( 'm_item_kbw_radiance_debuff', PATH, 0 )
m_item_kbw_radiance_debuff = ModifierClass{
    bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_kbw_radiance_debuff:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self.particle = ParticleManager:CreateParticle("particles/items2_fx/radiance.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())	
		ParticleManager:SetParticleControlEnt( self.particle, 1, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', self:GetCaster():GetOrigin(), false )
	end
end

function m_item_kbw_radiance_debuff:OnRefresh(t)
	ReadAbilityData( self, {
		'burn_damage',
		'burn_health_pct',
		'burn_tick',
		'flame_health_pct',
	})
	
	if IsServer() then
		self:StartIntervalThink(self.burn_tick)
	end
end

function m_item_kbw_radiance_debuff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle, true)
	end
end

function m_item_kbw_radiance_debuff:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
	local damage = self.burn_damage
	if not IsBoss(parent) then
		damage = damage + parent:GetMaxHealth() * self.burn_health_pct / 100
	end
	
	local buff = caster:FindModifierByName('m_item_kbw_radiance_flame')
	if buff and buff:GetAbility() == ability then
		damage = damage + caster:GetMaxHealth() * self.flame_health_pct / 100
	end
	
	damage = damage * self.burn_tick
	
	ApplyDamage( {
		victim = parent,
		attacker = caster,
		ability =	ability,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	} )
end

-- modifier: flame (active burn enchance)

LinkLuaModifier( 'm_item_kbw_radiance_flame', PATH, LUA_MODIFIER_MOTION_NONE )
m_item_kbw_radiance_flame = ModifierClass{
    bPurgable = true,
}

function m_item_kbw_radiance_flame:DestroyOnExpire()
	return false
end

function m_item_kbw_radiance_flame:OnCreated(t)
	ReadAbilityData(self, {
		'burn_radius',
		'burn_tick',
	})
	
	if IsServer() then
		local parent = self:GetParent()
		
		self:StartIntervalThink(self.burn_tick)
		
		self.particle = ParticleManager:Create('particles/items/radiance/flame.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.particle, 3, Vector(self.burn_radius, 0, 0))
		ParticleManager:SetParticleControl(self.particle, 18, Vector(1.0, 0.62, 0.25) * 255)
		ParticleManager:SetParticleControl(self.particle, 61, Vector(1, 0, 0))
		
		parent:EmitSound('Kbw.Item.Radiance.Flame.Loop')
	end
end

function m_item_kbw_radiance_flame:OnRefresh(t)
	self:OnCreated(t)
	self:OnDestroy()
end

function m_item_kbw_radiance_flame:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		
		ParticleManager:Fade(self.particle, true)
		
		parent:StopSound('Kbw.Item.Radiance.Flame.Loop')
	end
end

function m_item_kbw_radiance_flame:OnIntervalThink()
	if IsServer() then
		if self:GetRemainingTime() <= 0 then
			local parent = self:GetParent()
			local mod_burn = parent:FindModifierByName('m_item_kbw_radiance_aura')
			
			if not mod_burn or not exist(mod_burn.aura) or table.size(mod_burn.aura.tModifiers) == 0 then
				self:Destroy()
			end
		end
	end
end