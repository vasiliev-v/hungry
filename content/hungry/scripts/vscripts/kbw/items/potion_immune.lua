item_potion_immune = class{}

function item_potion_immune:Precache(c)
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_rage.vpcf", c)
	PrecacheResource("particle", "particles/status_fx/status_effect_life_stealer_rage.vpcf", c)
end

function item_potion_immune:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	
	hTarget:Purge(false, true, false, false, false)
	
	AddModifier('m_item_potion_immune', {
		hTarget = hTarget,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = self:GetSpecialValueFor('duration')
	})
	
	hTarget:EmitSound('DOTA_Item.BlackKingBar.Activate')

	self:SpendCharge()
end

LinkLuaModifier('m_item_potion_immune', "kbw/items/potion_immune", LUA_MODIFIER_MOTION_NONE)
m_item_potion_immune = ModifierClass{}

function m_item_potion_immune:GetStatusEffectName()
	return 'particles/status_fx/status_effect_life_stealer_rage.vpcf'
end

function m_item_potion_immune:OnCreated()
	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/units/heroes/hero_life_stealer/life_stealer_rage.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 2, hParent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)
	end
end

function m_item_potion_immune:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_item_potion_immune:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end