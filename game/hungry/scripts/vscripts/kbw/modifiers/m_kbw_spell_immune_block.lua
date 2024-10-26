m_kbw_spell_immune_block = ModifierClass{

}

function m_kbw_spell_immune_block:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}
end

function m_kbw_spell_immune_block:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSORB_SPELL,
	}
end

function m_kbw_spell_immune_block:GetAbsorbSpell()
	local parent = self:GetParent()

	local particle = ParticleManager:Create('particles/items_fx/immunity_sphere.vpcf', PATTACH_POINT_FOLLOW, parent, 2)
	ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)

	parent:EmitSound('DOTA_Item.LinkensSphere.Activate')

	return 1
end

function m_kbw_spell_immune_block:OnCreated()
	if IsServer() then
		local parent = self:GetParent()

		self.particle1 = ParticleManager:Create('particles/items_fx/black_king_bar_avatar.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)

		self.particle2 = ParticleManager:Create('particles/items_fx/immunity_sphere_buff.vpcf', PATTACH_POINT_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle2, 0, parent, PATTACH_POINT_FOLLOW, 'attach_hitloc', Vector(0,0,0), false)
	end
end

function m_kbw_spell_immune_block:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle1, true)
		ParticleManager:Fade(self.particle2, true)
	end
end