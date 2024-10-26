local PATH = 'kbw/items/levels/dagon'
local base = {}

-----------------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_item_generic_stats'
end

-----------------------------------------------------
-- indicator

function base:GetAOERadius()
	return self:GetSpecialValueFor('active_aoe')
end

-----------------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target then
		return
	end

	self:TargetParticle(target, caster)

	caster:EmitSound('DOTA_Item.Dagon.Activate')

	if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
		return
	end

	target:EmitSound('DOTA_Item.Dagon5.Target')

	local damage_type = self:GetAbilityDamageType()
	local damage = self:GetSpecialValueFor('active_damage')
	local radius = self:GetAOERadius()

	local victims = FindUnitsInRadius(
		caster:GetTeam(),
		target:GetOrigin(),
		target,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, victim in ipairs(victims) do
		if victim:IsIllusion() then
			MakeKillable(victim)
			victim:Kill(self, caster)
		else
			ApplyDamage({
				victim = victim,
				attacker = caster,
				ability = self,
				damage = damage,
				damage_type = damage_type,
			})
		end

		if victim ~= target then
			self:TargetParticle(victim, target)
		end
	end
end

function base:TargetParticle(target, caster)
	caster = caster or self:GetCaster()

	local particle = ParticleManager:Create('particles/items_fx/dagon.vpcf', PATTACH_CUSTOMORIGIN, 2)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, 'attach_attack1', caster:GetOrigin(), false)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, 'attach_hitloc', target:GetOrigin(), false)
	ParticleManager:SetParticleFoWProperties(particle, 0, 1, 10)
end

-----------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_dagon',
	'item_kbw_blaze_rod',
	'item_kbw_blaze_rod_2',
	'item_kbw_blaze_rod_3',
}, base)