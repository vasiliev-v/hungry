local PATH = "kbw/items/levels/halberd"

LinkLuaModifier('m_halberd_disarm', "kbw/items/levels/halberd", 0)
LinkLuaModifier('m_item_kbw_vanguard_block', 'kbw/items/vanguard', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_vanguard_shield', 'kbw/items/vanguard', LUA_MODIFIER_MOTION_NONE)

-- item

local base = {}

function base:CastFilterResultTarget(target)
	if target == self:GetCaster() then
		return UF_SUCCESS
	end
	return self.BaseClass.CastFilterResultTarget(self, target)
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target == caster then
		AddModifier('m_item_kbw_vanguard_shield', {
			hTarget = caster,
			hCaster = caster,
			hAbility = self,
			duration = self:GetSpecialValueFor('shield_duration'),
		})
		
		caster:EmitSound('Item.CrimsonGuard.Cast')
	else
		if target:TriggerSpellAbsorb(self) then
			return
		end

		AddModifier('m_halberd_disarm',{
			hTarget = target,
			hCaster = caster,
			hAbility = self,
			duration = self:GetSpecialValueFor('disarm'),
		})

		target:EmitSound('DOTA_Item.HeavensHalberd.Activate')
	end
end

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_generic_status_absorb = 0,
		m_item_kbw_vanguard_block = 0,
	}
end

-- levels

CreateLevels({
	'item_kbw_halberd',
	'item_kbw_halberd_2',
	'item_kbw_halberd_3',
}, base)

-- modifier: disarm

m_halberd_disarm = ModifierClass({
	bPurgable = true,
})

function m_halberd_disarm:OnCreated()
	if IsServer() then
		self.nParticle = ParticleManager:Create('particles/items2_fx/heavens_halberd_debuff_disarm.vpcf', self:GetParent())
	end
end

function m_halberd_disarm:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_halberd_disarm:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function m_halberd_disarm:GetTexture()
	return 'item_heavens_halberd'
end