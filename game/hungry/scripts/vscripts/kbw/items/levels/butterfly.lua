local PATH = "kbw/items/levels/butterfly"
local base = {}

-------------------------------------------------
-- stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_base_damage = 0,
		m_item_generic_evasion = 0,
	}
end

-------------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()

	AddModifier('m_item_kbw_butterfly_ghost', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = self:GetSpecialValueFor('duration')
	})

	caster:EmitSound('DOTA_Item.GhostScepter.Activate')
end

-------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_butterfly',
	'item_kbw_butterfly_2',
	'item_kbw_butterfly_3',
}, base)

-------------------------------------------------
-- active buff

LinkLuaModifier('m_item_kbw_butterfly_ghost', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_butterfly_ghost = ModifierClass{
	bPurgable = true
}

function m_item_kbw_butterfly_ghost:GetStatusEffectName()
	return 'particles/status_fx/status_effect_ghost.vpcf'
end

function m_item_kbw_butterfly_ghost:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function m_item_kbw_butterfly_ghost:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function m_item_kbw_butterfly_ghost:GetAbsoluteNoDamagePhysical()
	return 1
end

function m_item_kbw_butterfly_ghost:OnCreated()
	if IsServer() then
		local parent = self:GetParent()
		self.particle = ParticleManager:Create('particles/items/butterfly/ghost.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', parent:GetOrigin(), false)
	end
end

function m_item_kbw_butterfly_ghost:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle, true)
	end
end