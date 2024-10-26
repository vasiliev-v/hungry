local PATH = "kbw/items/levels/rusher"
local base = {}

---------------------------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_base = 0,
		m_item_generic_regen = 0,
		m_item_generic_attack = 0,
		m_item_generic_lifesteal = 0,
	}
end

---------------------------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()

	AddModifier('m_item_kbw_rusher_active', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = self:GetSpecialValueFor('active_duration')
	})

	caster:EmitSound('DOTA_Item.MaskOfMadness.Activate')
end

---------------------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_rusher',
	'item_kbw_rusher_2',
	'item_kbw_rusher_3',
}, base)

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- active buff

LinkLuaModifier('m_item_kbw_rusher_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_rusher_active = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_rusher_active:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_UNSLOWABLE] = true,
	}
end

function m_item_kbw_rusher_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end
function m_item_kbw_rusher_active:GetModifierAttackSpeedBonus_Constant()
	return self.active_attack
end
function m_item_kbw_rusher_active:GetModifierMoveSpeedBonus_Constant()
	return self.active_speed
end
function m_item_kbw_rusher_active:GetModifierMagicalResistanceBonus()
	return self.active_magic_resist
end
function m_item_kbw_rusher_active:GetModifierStatusResistanceStacking()
	return self.active_status_resist
end

function m_item_kbw_rusher_active:OnCreated()
	ReadAbilityData(self, {
		'active_attack',
		'active_speed',
		'active_magic_resist',
		'active_status_resist',
	})

	if IsServer() then
		local parent = self:GetParent()

		self.particle1 = ParticleManager:Create('particles/items2_fx/mask_of_madness.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)

		self.particle2 = ParticleManager:Create('particles/gameplay/effects/ascetic_cap.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.particle2, 17, Vector(0,0,0))
	end
end

function m_item_kbw_rusher_active:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle1, true)
		ParticleManager:Fade(self.particle2, true)
	end
end