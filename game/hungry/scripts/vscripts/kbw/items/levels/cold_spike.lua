LinkLuaModifier('m_item_cold_spike_debuff', "kbw/items/levels/cold_spike", 0)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_attack = 0,
		m_item_generic_regen = 0,
	}
end

function base:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	local hCaster = self:GetCaster()
	local nDuration = self:GetSpecialValueFor('duration')

	if hTarget:IsMagicImmune() or hTarget:TriggerSpellAbsorb(self) then
		return
	end

	AddModifier('m_item_cold_spike_debuff', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = nDuration,
	})

	hTarget:EmitSoundParams('Hero_Abaddon.Curse.Proc', 3, 3, 0)
end

CreateLevels({
    'item_cold_spike',
    'item_cold_spike_2',
    'item_cold_spike_3',
}, base)

m_item_cold_spike_debuff = ModifierClass{
	bPurgable = true,
}

function m_item_cold_spike_debuff:GetStatusEffectName()
	return 'particles/items/cold_spike/status.vpcf'
end

function m_item_cold_spike_debuff:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end

function m_item_cold_spike_debuff:OnCreated()
	ReadAbilityData(self, {
		'damage_amp',
	})
end

function m_item_cold_spike_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function m_item_cold_spike_debuff:GetDisableHealing()
	return 1
end