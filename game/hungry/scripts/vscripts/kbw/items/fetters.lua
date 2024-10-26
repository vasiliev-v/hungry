sPath = "kbw/items/fetters"
LinkLuaModifier( 'm_item_kbw_fetters', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_fetters_stun', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_fetters_hex', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_fetters_null', sPath, 0 )

item_kbw_fetters = class{}

function item_kbw_fetters:GetIntrinsicModifierName()
	return 'm_item_kbw_fetters'
end

function item_kbw_fetters:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	local hCaster = self:GetCaster()

	if hTarget:IsMagicImmune() or hTarget:TriggerSpellAbsorb( self ) then
		return
	end

	AddModifier( 'm_item_kbw_fetters_stun', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor('stun_duration'),
	})

	AddModifier( 'm_item_kbw_fetters_hex', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor('hex_duration'),
	})

	AddModifier( 'm_item_kbw_fetters_null', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor('other_duration'),
	})

	hTarget:EmitSound('DOTA_Item.RodOfAtos.Target')
	hTarget:EmitSound('DOTA_Item.Nullifier.Target')
end

-------------------------------------------------------
-- stats

m_item_kbw_fetters = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_item_kbw_fetters:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_item_kbw_fetters:GetModifierBonusStats_Strength()
	return self.nStats
end
function m_item_kbw_fetters:GetModifierBonusStats_Agility()
	return self.nStats
end
function m_item_kbw_fetters:GetModifierBonusStats_Intellect()
	return self.nStats
end
function m_item_kbw_fetters:GetModifierPreAttack_BonusDamage()
	return self.nDamage
end
function m_item_kbw_fetters:GetModifierConstantManaRegen()
	return self.nMpRegen
end
function m_item_kbw_fetters:GetModifierConstantManaRegen()
	return self.nMpRegen
end
function m_item_kbw_fetters:GetModifierConstantHealthRegen()
	return self.nHpRegen
end
function m_item_kbw_fetters:GetModifierPhysicalArmorBonus()
	return self.nArmor
end

function m_item_kbw_fetters:OnCreated()
	ReadAbilityData( self, {
		nDamage = 'damage',
		nStats = 'atr',
		nArmor = 'armor',
		nHpRegen = 'hp_regen',
		nMpRegen = 'mp_regen',
	})
end

-------------------------------------------------------
-- stun

m_item_kbw_fetters_stun = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_fetters_stun:IsStunDebuff()
	return true
end

function m_item_kbw_fetters_stun:GetTexture()
	return 'item_fetters'
end

function m_item_kbw_fetters_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function m_item_kbw_fetters_stun:OnCreated()
	if IsServer() then
		local hParent = self:GetParent()
		local sParticle = 'particles/items3_fx/gleipnir_root.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, hParent )
		ParticleManager:SetParticleControl( self.nParticle, 0, hParent:GetOrigin() )
	end
end

function m_item_kbw_fetters_stun:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
	end
end

-------------------------------------------------------
-- hex

m_item_kbw_fetters_hex = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_fetters_hex:GetTexture()
	return 'item_fetters'
end

function m_item_kbw_fetters_hex:GetStatusEffectName()
	return 'particles/status_fx/status_effect_nullifier.vpcf'
end

function m_item_kbw_fetters_hex:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
	}
end

function m_item_kbw_fetters_hex:OnCreated()
	if IsServer() then
		local hParent = self:GetParent()
		local sParticle = 'particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, hParent )
		ParticleManager:SetParticleControlEnt( self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hParent:GetOrigin(), false )
		ParticleManager:SetParticleControl( self.nParticle, 60, Vector( 106, 13, 153 ) )
		ParticleManager:SetParticleControl( self.nParticle, 61, Vector( 1, 0, 0 ) )
	end
end

function m_item_kbw_fetters_hex:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
	end
end

-------------------------------------------------------
-- null

m_item_kbw_fetters_null = ModifierClass{}

function m_item_kbw_fetters_null:GetTexture()
	return 'item_fetters'
end

function m_item_kbw_fetters_null:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end

function m_item_kbw_fetters_null:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MAX,
	}
end

function m_item_kbw_fetters_null:GetModifierMoveSpeed_AbsoluteMax()
	return self.nMaxSpeed
end

function m_item_kbw_fetters_null:OnCreated()
	ReadAbilityData( self, {
		nMaxSpeed = 'fixed_speed',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self:StartIntervalThink( 1/30 )

		local sParticle = 'particles/items4_fx/nullifier_mute_debuff.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, hParent )

		sParticle = 'particles/items4_fx/nullifier_mute.vpcf'
		self.nParticle2 = ParticleManager:Create( sParticle, PATTACH_OVERHEAD_FOLLOW, hParent )
	end
end

function m_item_kbw_fetters_null:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
		ParticleManager:Fade( self.nParticle2, true )
	end
end

function m_item_kbw_fetters_null:OnIntervalThink()
	self:GetParent():Purge( true, false, false, false, false )
end