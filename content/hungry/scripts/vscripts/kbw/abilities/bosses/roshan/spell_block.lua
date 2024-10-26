local PATH = "kbw/abilities/bosses/roshan/spell_block"

roshan_spell_block_kbw = class{}

function roshan_spell_block_kbw:GetIntrinsicModifierName()
	return 'm_roshan_spell_block_kbw'
end

LinkLuaModifier('m_roshan_spell_block_kbw', PATH, LUA_MODIFIER_MOTION_NONE)
m_roshan_spell_block_kbw = ModifierClass{
	bPermanent = true,
}

function m_roshan_spell_block_kbw:IsDebuff()
	return false
end

function m_roshan_spell_block_kbw:DestroyOnExpire()
	return false
end

function m_roshan_spell_block_kbw:OnCreated()
	ReadAbilityData(self, {'status_resist'})
end

function m_roshan_spell_block_kbw:OnIntervalThink()
	self:SetDuration(-1, true)
	self:StartIntervalThink(-1)
end

function m_roshan_spell_block_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSORB_SPELL,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function m_roshan_spell_block_kbw:GetAbsorbSpell(t)
	local source = self:GetAbility()
	if source and source:IsCooldownReady() then
		local caster = t.ability:GetCaster()
		local parent = self:GetParent()
		if exist(caster) and caster:GetTeam() ~= parent:GetTeam() then
			local cd = source:GetEffectiveCooldown(source:GetLevel() - 1)
			source:StartCooldown(cd)
			self:SetDuration(cd, true)
			self:StartIntervalThink(cd)

			local particle = ParticleManager:Create('particles/items_fx/immunity_sphere.vpcf', parent)
			ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)
			ParticleManager:Fade(particle, 2)

			parent:EmitSound('DOTA_Item.LinkensSphere.Activate')

			return 1
		end
	end
end

function m_roshan_spell_block_kbw:GetModifierStatusResistanceStacking()
	return self.status_resist
end