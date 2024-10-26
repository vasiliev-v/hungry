local sPath = "kbw/items/blade_of_discord"
LinkLuaModifier( 'm_item_kbw_blade_of_discord', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_blade_of_discord_debuff', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_blade_of_discord_buff', sPath, 0 )

item_kbw_blade_of_discord = class{}

function item_kbw_blade_of_discord:GetAOERadius()
	return self:GetSpecialValueFor('aoe')
end

function item_kbw_blade_of_discord:GetIntrinsicModifierName()
	return 'm_item_kbw_blade_of_discord'
end

function item_kbw_blade_of_discord:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	local hCaster = self:GetCaster()

	if hTarget then
		local nSpeed = self:GetSpecialValueFor('ally_projectile_speed')

		local sParticle = 'particles/items/blade_of_discord/projectile.vpcf'
		local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN )
		ParticleManager:SetParticleControlEnt( nParticle, 0, hCaster, PATTACH_POINT_FOLLOW, 'attach_hitloc', hCaster:GetOrigin(), false )
		ParticleManager:SetParticleControlEnt( nParticle, 1, hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false )
		ParticleManager:SetParticleControl( nParticle, 2, Vector( nSpeed, 0, 0 ) )
		ParticleManager:SetParticleControl( nParticle, 17, Vector( 0.3, 0, 0 ) )

		local nProjectile = ProjectileManager:CreateTrackingProjectile({
			Target = hTarget,
			Source = hCaster,
			Ability = self,
			iMoveSpeed = nSpeed,
		})

		Timer( function()
			if ProjectileManager:IsValidProjectile( nProjectile ) then
				return 1/30
			end

			ParticleManager:Fade( nParticle, true )
		end )

		hCaster:EmitSound('DOTA_Item.EtherealBlade.Activate')

		return
	end

	local vTarget = self:GetCursorPosition()
	local nDuration = self:GetSpecialValueFor('duration')
	local nRadius = self:GetSpecialValueFor('aoe')
	local nDamage = hCaster:GetPrimaryStatValue() * self:GetSpecialValueFor('atr_damage_pct') / 100

	local qUnits = Find:UnitsInRadius{
		vCenter = vTarget,
		nRadius = nRadius,
		nTeam = hCaster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		nFilterFlag = 0,
	}

	for _, hUnit in ipairs( qUnits ) do
		AddModifier( 'm_item_kbw_blade_of_discord_debuff', {
			hTarget = hUnit,
			hCaster = hCaster,
			hAbility = self,
			duration = nDuration,
		})

		ApplyDamage({
			victim = hUnit,
			attacker = hCaster,
			ability = self,
			damage = nDamage,
			damage_type = DAMAGE_TYPE_MAGICAL,
		})

		local sParticle = 'particles/items/blade_of_discord/impact.vpcf'
		local nParticle = ParticleManager:Create( sParticle, hUnit, 3 )
		ParticleManager:SetParticleControl( nParticle, 1, hUnit:GetAttachmentOrigin( hUnit:ScriptLookupAttachment('attach_hitloc') ) )
		ParticleManager:SetParticleControl( nParticle, 17, Vector( 0.5, 0, 0 ) )
	end

	local sParticle = 'particles/items/blade_of_discord/explosion.vpcf'
	local nParticle = ParticleManager:Create( sParticle, PATTACH_WORLDORIGIN, 2 )
	ParticleManager:SetParticleControl( nParticle, 0, vTarget )
	ParticleManager:SetParticleControl( nParticle, 1, Vector( nRadius, 0, nRadius ) )
	ParticleManager:SetParticleFoWProperties( nParticle, 0, 0, nRadius )

	EmitSoundOnLocationWithCaster( vTarget, 'DOTA_Item.VeilofDiscord.Activate', hCaster )
	EmitSoundOnLocationWithCaster( vTarget, 'DOTA_Item.EtherealBlade.Target', hCaster )
end

function item_kbw_blade_of_discord:OnProjectileHit( hTarget, vPos )
	if hTarget then
		AddModifier( 'm_item_kbw_blade_of_discord_buff', {
			hTarget = hTarget,
			hCaster = self:GetCaster(),
			hAbility = self,
			duration = self:GetSpecialValueFor('duration'),
		})

		hTarget:EmitSound('DOTA_Item.EtherealBlade.Target')
	end
end

-------------------------------------------------------
-- stats

m_item_kbw_blade_of_discord = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_item_kbw_blade_of_discord:OnCreated()
	ReadAbilityData( self, {
		nStats = 'atr',
	} )
end

function m_item_kbw_blade_of_discord:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_item_kbw_blade_of_discord:GetModifierBonusStats_Strength()
	return self.nStats
end
function m_item_kbw_blade_of_discord:GetModifierBonusStats_Agility()
	return self.nStats
end
function m_item_kbw_blade_of_discord:GetModifierBonusStats_Intellect()
	return self.nStats
end

-------------------------------------------------------
-- debuff

m_item_kbw_blade_of_discord_debuff = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_blade_of_discord_debuff:GetTexture()
	return 'item_blade_of_discord'
end

function m_item_kbw_blade_of_discord_debuff:GetStatusEffectName()
	return 'particles/items/blade_of_discord/status.vpcf'
end

function m_item_kbw_blade_of_discord_debuff:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function m_item_kbw_blade_of_discord_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function m_item_kbw_blade_of_discord_debuff:GetModifierMagicalResistanceBonus()
	return self.nMagResist
end

function m_item_kbw_blade_of_discord_debuff:GetAbsoluteNoDamagePhysical()
	return 1
end

function m_item_kbw_blade_of_discord_debuff:OnCreated()
	ReadAbilityData( self, {
		nMagResist = 'mag_resist_reduction',
	})

	self.nMagResist = -self.nMagResist

	if IsServer() then
		self:StartIntervalThink( 1/30 )

		local hParent = self:GetParent()
		local sParticle = 'particles/items/blade_of_discord/debuff.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, hParent )
		ParticleManager:SetParticleControlEnt( self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hParent:GetOrigin(), false )
	end
end

function m_item_kbw_blade_of_discord_debuff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
	end
end

function m_item_kbw_blade_of_discord_debuff:OnIntervalThink()
	local hParent = self:GetParent()
	hParent:RemoveModifierByName('modifier_item_ethereal_blade_ethereal')
	hParent:RemoveModifierByName('modifier_item_ethereal_blade_slow')
	-- hParent:RemoveModifierByName('modifier_item_veil_of_discord_debuff')
end

-------------------------------------------------------
-- buff

m_item_kbw_blade_of_discord_buff = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_blade_of_discord_buff:GetTexture()
	return 'item_blade_of_discord'
end

function m_item_kbw_blade_of_discord_buff:GetStatusEffectName()
	return 'particles/items/blade_of_discord/status_ally.vpcf'
end

function m_item_kbw_blade_of_discord_buff:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function m_item_kbw_blade_of_discord_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function m_item_kbw_blade_of_discord_buff:GetAbsoluteNoDamagePhysical()
	return 1
end

function m_item_kbw_blade_of_discord_buff:OnCreated()
	if IsServer() then
		-- BKB check
		-- self:StartIntervalThink( 1/30 )
	end
end

-- function m_item_kbw_blade_of_discord_buff:OnIntervalThink()
-- 	if self:GetParent():IsMagicImmune() then
-- 		self:Destroy()
-- 	end
-- end