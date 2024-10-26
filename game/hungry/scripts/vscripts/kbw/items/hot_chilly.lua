local PATH = "kbw/items/hot_chilly"

item_kbw_hot_chilly = class{}

function item_kbw_hot_chilly:GetIntrinsicModifierName()
	return 'm_item_generic_stats'
end

function item_kbw_hot_chilly:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	ProjectileManager:CreateTrackingProjectile({
		EffectName = 'particles/econ/events/ti10/hot_potato/hot_potato_projectile.vpcf',
		Source = caster,
		Target = target,
		Ability = self,
		vSourceLoc = caster:GetOrigin(),
		iMoveSpeed = self:GetSpecialValueFor('prjectile_speed')
	})

	caster:EmitSound('SeasonalConsumable.TI10.HotPotato.Cast')
	caster:EmitSound('SeasonalConsumable.TI10.HotPotato.Projectile')
end

function item_kbw_hot_chilly:OnProjectileHit(target, pos)
	if not exist(target) or target:TriggerSpellAbsorb(self)
	or target:IsInvulnerable() or target:IsMagicImmune() then
		return
	end

	AddModifier('m_item_kbw_hot_chilly_held', {
		hTarget = target,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = self:GetSpecialValueFor('delay')
	})
end

------------------------------------------------------------------------

LinkLuaModifier('m_item_kbw_hot_chilly_held', PATH, LUA_MODIFIER_MOTION_NONE)

m_item_kbw_hot_chilly_held = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_hot_chilly_held:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'stun',
		})

		local parent = self:GetParent()

		self.particle = ParticleManager:Create('particles/econ/events/ti10/hot_potato/hot_potato_held.vpcf', PATTACH_OVERHEAD_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), false)
	
		parent:EmitSound('SeasonalConsumable.TI10.HotPotato.Target')
	end
end

function m_item_kbw_hot_chilly_held:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()

		if parent:IsAlive() and not parent:IsInvulnerable() and not parent:IsMagicImmune() then
			AddModifier('m_item_kbw_hot_chilly_stun', {
				hTarget = parent,
				hCaster = self:GetCaster(),
				hAbility = self:GetAbility(),
				duration = self.stun,
			})

			local particle = 'particles/econ/events/ti10/hot_potato/hot_potato_explode.vpcf'
			particle = ParticleManager:Create(particle, PATTACH_OVERHEAD_FOLLOW, parent)
			ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), false)
		end

		ParticleManager:Fade(self.particle, true)

		parent:StopSound('SeasonalConsumable.TI10.HotPotato.Target')
	end
end

------------------------------------------------------------------------

LinkLuaModifier('m_item_kbw_hot_chilly_stun', PATH, LUA_MODIFIER_MOTION_NONE)

m_item_kbw_hot_chilly_stun = ModifierClass{
	bMultiple = true,
}

function m_item_kbw_hot_chilly_stun:IsStunDebuff()
	return true
end

function m_item_kbw_hot_chilly_stun:IsPurgable()
	return false
end

function m_item_kbw_hot_chilly_stun:IsPurgeException()
	return true
end

function m_item_kbw_hot_chilly_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function m_item_kbw_hot_chilly_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function m_item_kbw_hot_chilly_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function m_item_kbw_hot_chilly_stun:OnCreated()
	if IsServer() then
		local parent = self:GetParent()

		self.particle1 = 'particles/econ/events/ti10/hot_potato/hot_potato_debuff.vpcf'
		self.particle1 = ParticleManager:Create(self.particle1, parent)

		self.particle2 = 'particles/generic_gameplay/generic_stunned.vpcf'
		self.particle2 = ParticleManager:Create(self.particle2, PATTACH_OVERHEAD_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle2, 0, parent, PATTACH_OVERHEAD_FOLLOW, nil, parent:GetOrigin(), false)
	
		parent:EmitSound('HotPotato.Ow')
		parent:EmitSound('SeasonalConsumable.TI10.HotPotato.Explode')
	end
end

function m_item_kbw_hot_chilly_stun:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle1, true)
		ParticleManager:Fade(self.particle2, true)
	end
end