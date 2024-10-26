local PATH = "kbw/items/levels/eternal_shroud"

LinkLuaModifier('m_item_kbw_vanguard_shield', "kbw/items/vanguard", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_armor = 0,
		m_item_generic_regen = 0,
		m_item_kbw_eternal_shroud = self.nLevel,
	}
end

function base:OnSpellStart()
	local caster = self:GetCaster()

	AddModifier('m_item_kbw_vanguard_shield', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = self:GetSpecialValueFor('shield_duration'),
	})

	caster:EmitSound('DOTA_Item.Pipe.Activate')
end

------------------------------------------------
-- levels

CreateLevels({
	'item_kbw_eternal_shroud',
	'item_kbw_eternal_shroud_2',
	'item_kbw_eternal_shroud_3',
}, base)

------------------------------------------------
-- modifier: spell lifesteal

LinkLuaModifier('m_item_kbw_eternal_shroud', PATH, 0)
m_item_kbw_eternal_shroud = ModifierClass {
	bHidden = true,
	bPermanent = true,
}

function m_item_kbw_eternal_shroud:OnCreated()
	ReadAbilityData(self, {
		nLifesteal = 'hero_lifesteal',
		nLifestealCreeps = 'creep_lifesteal',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_eternal_shroud:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_eternal_shroud:OnParentDealDamage(tEvent)
	if tEvent.inflictor and tEvent.unit:GetTeam() ~= tEvent.attacker:GetTeam() and not binhas(tEvent.damage_flags,
		DOTA_DAMAGE_FLAG_REFLECTION,
		DOTA_DAMAGE_FLAG_HPLOSS,
		DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
	) then

		local nMultiplier = self.nLifestealCreeps
		if tEvent.unit:IsConsideredHero() and not tEvent.unit:IsIllusion() then
			nMultiplier = self.nLifesteal
		end

		local hParent = self:GetParent()

		local nHeal = tEvent.damage * nMultiplier / 100
		hParent:Heal(nHeal, self:GetAbility())

		local nCurTime = GameRules:GetGameTime()
		if not self.nLastParticleTime or self.nLastParticleTime + 0.5 <= nCurTime then
			local sParticle = 'particles/items3_fx/octarine_core_lifesteal.vpcf'
			ParticleManager:Create(sParticle, hParent, 2)

			self.nLastParticleTime = nCurTime
		end
	end
end