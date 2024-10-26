local sPath = "kbw/abilities/heroes/pugna/decrepify"

pugna_decrepify_kbw = class{}

function pugna_decrepify_kbw:OnSpellStart()
	local hTarget = self:GetCursorTarget()

	if hTarget:TriggerSpellAbsorb(self) then
		return
	end

	AddModifier('m_pugna_decrepify_kbw', {
		hTarget = hTarget,
		hCaster = self:GetCaster(),
		hAbility = self,
		duration = self:GetSpecialValueFor('duration')
	})

	hTarget:EmitSound('Hero_Pugna.Decrepify')
end

LinkLuaModifier('m_pugna_decrepify_kbw', sPath, LUA_MODIFIER_MOTION_NONE)

m_pugna_decrepify_kbw = ModifierClass{
	bPurgable = true,
}

function m_pugna_decrepify_kbw:GetStatusEffectName()
	return 'particles/status_fx/status_effect_ghost.vpcf'
end

function m_pugna_decrepify_kbw:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self.nParticle = ParticleManager:Create('particles/items_fx/ghost.vpcf', self:GetParent())
	end
end

function m_pugna_decrepify_kbw:OnRefresh(t)
	ReadAbilityData(self, {
		'bonus_spell_damage_pct_allies',
		'bonus_spell_damage_pct',
		'bonus_movement_speed',
	})

	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		self.speed = 0
		self.resist = -self.bonus_spell_damage_pct_allies
	else
		self.speed = -self.bonus_movement_speed
		self.resist = -self.bonus_spell_damage_pct
	end
end

function m_pugna_decrepify_kbw:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_pugna_decrepify_kbw:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function m_pugna_decrepify_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
	}
end

function m_pugna_decrepify_kbw:GetAbsoluteNoDamagePhysical()
	return 1
end
function m_pugna_decrepify_kbw:GetModifierMoveSpeedBonus_Percentage()
	return self.speed
end
function m_pugna_decrepify_kbw:GetModifierMagicalResistanceDecrepifyUnique()
	return self.resist
end