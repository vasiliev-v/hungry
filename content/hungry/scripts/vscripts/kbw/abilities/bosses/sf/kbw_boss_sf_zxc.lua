kbw_boss_sf_zxc = class{}

require 'lib/modifier_self_events'

LinkLuaModifier( 'm_kbw_boss_sf_zxc', "kbw/abilities/bosses/sf/kbw_boss_sf_zxc", 0 )
LinkLuaModifier( 'm_kbw_boss_sf_zxc_stack', "kbw/abilities/bosses/sf/kbw_boss_sf_zxc", 0 )

m_kbw_boss_sf_zxc_stack = ModifierClass{
	bHidden = false,
	bPermanent = false,
	bMultiple = false,
}

function m_kbw_boss_sf_zxc_stack:OnCreated( tData )
	ReadAbilityData( self, {
		bonus_damage_pct_per_stack = 'bonus_damage_pct_per_stack',
	})
end

function m_kbw_boss_sf_zxc_stack:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end

function m_kbw_boss_sf_zxc_stack:OnTooltip()
	return self.bonus_damage_pct_per_stack
end

m_kbw_boss_sf_zxc = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function kbw_boss_sf_zxc:GetIntrinsicModifierName()
	return 'm_kbw_boss_sf_zxc'
end

function m_kbw_boss_sf_zxc:OnCreated( tData )
	ReadAbilityData( self, {
		damage = 'damage',
		duration_stacks = 'duration_stacks',
		bonus_damage_pct_per_stack = 'bonus_damage_pct_per_stack',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_kbw_boss_sf_zxc:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_boss_sf_zxc:OnParentAttackLanded( tEvent )
	if self:GetParent():PassivesDisabled() then
		return
	end

	local  nVector = RandomVector( math.sqrt( RandomFloat( 0, 1 ) ) * 500 )

	local sParticle = 'particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf'
	local nParticle = ParticleManager:Create( sParticle, PATTACH_WORLDORIGIN, 2  )
	ParticleManager:SetParticleControl( nParticle, 0, tEvent.target:GetOrigin() + nVector )
	ParticleManager:SetParticleControl( nParticle, 3, Vector( 2, 2, 2 ) )

	EmitSoundOnLocationWithCaster( tEvent.target:GetOrigin() + nVector, "Hero_Nevermore.Shadowraze", self:GetCaster() )

	local qTargets = FindUnitsInRadius(self:GetParent():GetTeam(), tEvent.target:GetOrigin() + nVector, nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, hTarget in pairs(qTargets) do
		if exist( hTarget ) and hTarget:IsAlive() then
			local mod = hTarget:FindModifierByName("m_kbw_boss_sf_zxc_stack")

			local damage = self.damage

			if mod then
				damage = self.damage + ((self.damage / 100) * (self.bonus_damage_pct_per_stack * mod:GetStackCount()))
			end

			local damageTable = {
				victim = hTarget,
				attacker = self:GetCaster(),
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility(),
			}

			ApplyDamage( damageTable )

			if mod then
				mod:SetStackCount((mod:GetStackCount() + 1) or 0)
				mod:ForceRefresh()
			else
				local hMod = hTarget:AddNewModifier( self:GetCaster(), self:GetAbility(), 'm_kbw_boss_sf_zxc_stack', {duration = self.duration_stacks})
				if hMod then
					hMod:SetStackCount(1)
				end
			end
		end
	end
end