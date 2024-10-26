local DRUM_PATH = "kbw/items/drum"
local PATH = "kbw/items/levels/flag"
LinkLuaModifier('m_item_kbw_drum', DRUM_PATH, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_drum_effect', DRUM_PATH, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_kbw_drum_active', DRUM_PATH, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('m_item_teleporter', "kbw/items/levels/teleporter", LUA_MODIFIER_MOTION_NONE)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = -1,
		m_item_kbw_drum = self.nLevel + 1,
		m_item_teleporter = self.nLevel + 1,
		m_item_flag_fast_tpscroll = self.nLevel,
	}
end

function base:GetAOERadius()
	return self:GetSpecialValueFor('radius')
end

function base:CastFilterResultTarget(target)
	if target == self:GetCaster() then
		return UF_SUCCESS
	end
	return UF_FAIL_OTHER
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local center = self:GetCursorPosition()
	local target = self:GetCursorTarget()
	local team = caster:GetTeam()
	local radius = self:GetAOERadius()
	local duration = self:GetSpecialValueFor('active_duration')

	if target then
		center = caster:GetOrigin()

		local owner = caster:GetPlayerOwnerID()
		local area_radius = self:GetSpecialValueFor('creep_tp_area')
		local tp_target = center + caster:GetForwardVector():Normalized() * self:GetSpecialValueFor('creep_tp_offset')
		local time = GameRules:GetGameTime() - self:GetSpecialValueFor('creep_tp_damage_cooldown')

		local units = Find:UnitsInRadius({
			nTeam = team,
			vCenter = center,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			fCondition = function(hUnit)
				return hUnit ~= caster
					and not hUnit:IsCourier()
					and hUnit:GetPlayerOwnerID() == owner
					and not SUPER_STATIC_UNITS[hUnit:GetUnitName()]
					and (not hUnit.nLastTimeDamaged or time >= hUnit.nLastTimeDamaged)
			end
		})

		for _, unit in ipairs(units) do
			local pos = tp_target + RandomVector(area_radius * RandomFloat(0, 1)^0.5)
			
			FindClearSpaceForUnit(unit, pos, true)
			ProjectileManager:ProjectileDodge(unit)

			local particle = ParticleManager:Create('particles/units/heroes/hero_chen/chen_holy_persuasion.vpcf', unit)
			ParticleManager:Fade(particle, 3)
			ParticleManager:SetParticleControl(particle, 1, unit:GetOrigin())
		end
	end

	local allies = FindUnitsInRadius(
		team,
		center,
		caster,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, ally in ipairs(allies) do
		AddModifier('m_item_kbw_drum_active', {
			hTarget = ally,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
	end

	PlaySound('DOTA_Item.DoE.Activate', center, team)
end

CreateLevels({
	'item_kbw_flag',
	'item_kbw_flag_2',
	'item_kbw_flag_3',
}, base)

-------------------------------

LinkLuaModifier('m_item_flag_fast_tpscroll', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_flag_fast_tpscroll = ModifierClass{
	bPermanent = true,
	bHidden = true,
}