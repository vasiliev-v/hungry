require 'lib/finder'
require 'lib/particle_manager'
require 'lib/modifier_self_events'

---------------------------------------------
-- item

local base = {}

function base:OnSpellStart()
	local hTarget = self:GetCursorTarget()

	if hTarget then
		if hTarget.CutDown then
			hTarget:CutDown( self:GetCaster():GetTeam() )
		else
			hTarget:Kill()
		end
	end
end

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_attack = 0,
		m_item_generic_regen = 0,
		m_item_kbw_battle_fury = 0,
	}
end

---------------------------------------------
-- levels

CreateLevels({
	'item_kbw_quelling_fury',
	'item_kbw_battle_fury',
	'item_kbw_battle_fury_2',
	'item_kbw_battle_fury_3',
}, base )

---------------------------------------------
-- modifier: cleave

LinkLuaModifier( 'm_item_kbw_battle_fury', "kbw/items/levels/battle_fury", 0 )
m_item_kbw_battle_fury = ModifierClass{
	bMultiple = true,
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_battle_fury:OnCreated()
	ReadAbilityData( self, {
		'cleave',
		'cleave_start_radius',
		'cleave_range',
		'cleave_angle',
		'cleave_ranged_offset',
	})

	if IsServer() then
		self.tRecords = {}
	
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_battle_fury:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_battle_fury:OnParentAttack(t)
	self.tRecords[t.record] = self:GetParent():GetOrigin()
end

function m_item_kbw_battle_fury:OnParentAttackRecordDestroy(t)
	self.tRecords[t.record] = nil
end

function m_item_kbw_battle_fury:OnParentAttackLanded( t )
	if not exist( t.target ) or not t.target.AddAbility then
		return
	end
	
	local hAbility = self:GetAbility()
	local sParticle = 'particles/items/battle_fury/battle_fury.vpcf'
	local nDamage = t.original_damage * self.cleave / 100
	local vCenter = t.attacker:GetOrigin()
	local vForward = self:GetParent():GetForwardVector():Normalized()
	
	if t.attacker:IsRangedAttacker() then
		vForward = (t.target:GetOrigin() - (self.tRecords[t.record] or vCenter))
		vForward.z = 0
		vForward = vForward:Normalized()
		vCenter = t.target:GetOrigin() - vForward * self.cleave_ranged_offset
	end

	local aVictims = FindUnitsInCone(
		t.attacker:GetTeam(),
		vCenter,
		self.cleave_range,
		vForward,
		self.cleave_start_radius,
		self.cleave_angle,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE
	)
	
	local nParticle = ParticleManager:Create( sParticle )
	ParticleManager:SetParticleControl( nParticle, 0, vCenter )
	ParticleManager:SetParticleFoWProperties( nParticle, 0, 0, self.cleave_range )
	ParticleManager:Fade( nParticle, 1 )

	for nOrder, hUnit in ipairs( aVictims ) do
		if hUnit ~= t.target then
			ApplyDamage({
				victim = hUnit,
				attacker = t.attacker,
				ability = hAbility,
				damage = nDamage,
				damage_type = DAMAGE_TYPE_PHYSICAL,
				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
			})

			Timer( 1/30, function()
				if nOrder <= 16 then
					ParticleManager:SetParticleControl( nParticle, nOrder, hUnit:GetOrigin() )
				end
			end )
		end
	end
end