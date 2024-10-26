local sPath = "kbw/items/levels/ninja_gear"
LinkLuaModifier( 'm_item_kbw_ninja_gear', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_ninja_gear_active', sPath, 0 )

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_generic_stats = 0,
        m_item_generic_regen = 0,
        m_item_generic_cast_range_fix = 0,
        m_item_kbw_ninja_gear = self.nLevel,
    }
end

function base:GetCastRange()
	return self:GetSpecialValueFor('reveal_range')
end

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local nToggleCooldown = self:GetSpecialValueFor('toggle_cooldown')

	if hCaster:HasModifier('m_item_kbw_ninja_gear_active') then
		hCaster:RemoveModifierByName('m_item_kbw_ninja_gear_active')

		local nCooldown = 0
		if self.bRefrehsed then
			self.bRefrehsed = nil
		elseif self.nEndCooldown then
			nCooldown = self.nEndCooldown - GameRules:GetGameTime()
		end

		self:EndCooldown()
		self:StartCooldown(math.max(nToggleCooldown, nCooldown))
	else
		AddModifier( 'm_item_kbw_ninja_gear_active', {
			hTarget = hCaster,
			hCaster = hCaster,
			hAbility = self,
			duration = self:GetSpecialValueFor('duration'),
		})

		hCaster:EmitSound('DOTA_Item.ShadowAmulet.Activate')

		self.bRefrehsed = nil
		self.nEndCooldown = GameRules:GetGameTime() + self:GetCooldownTimeRemaining()

		self:EndCooldown()
		self:StartCooldown(nToggleCooldown)
	end
end

function base:OnRefreshed()
	self.bRefrehsed = true
end

local tActiveTextures = {
	[1] = 'item_ninja_gear_active',
	[2] = 'item_ninja_gear2_active',
	[3] = 'item_ninja_gear3_active',
}

function base:GetAbilityTextureName()
	if self:GetCaster():HasModifier('m_item_kbw_ninja_gear_active') then
		return tActiveTextures[self.nLevel]
	end
	return self.BaseClass.GetAbilityTextureName(self)
end

CreateLevels({
    'item_kbw_ninja_gear',
    'item_kbw_ninja_gear_2',
    'item_kbw_ninja_gear_3',
}, base )

--------------------------------------------------------
-- modifier: passive unique

m_item_kbw_ninja_gear = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_ninja_gear:OnCreated()
	ReadAbilityData( self, {
		'attack_range',
		'cast_range',
		'vision',
	} )
end

function m_item_kbw_ninja_gear:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
end

function m_item_kbw_ninja_gear:GetModifierAttackRangeBonus()
	if self:GetParent():IsRangedAttacker() then
		return self.attack_range
	end
end
function m_item_kbw_ninja_gear:GetModifierCastRangeBonusStacking()
	return self.cast_range
end
function m_item_kbw_ninja_gear:GetBonusDayVision()
    return self.vision
end
function m_item_kbw_ninja_gear:GetBonusNightVision()
    return self.vision
end

--------------------------------------------------------
-- modifier: active buff

m_item_kbw_ninja_gear_active = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_ninja_gear_active:GetTexture()
	return 'item_ninja_gear'
end

function m_item_kbw_ninja_gear_active:GetStatusEffectName()
	return 'particles/status_fx/status_effect_blur.vpcf'
end

function m_item_kbw_ninja_gear_active:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
	}
end

function m_item_kbw_ninja_gear_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
end

function m_item_kbw_ninja_gear_active:GetModifierInvisibilityLevel()
	return 1
end

function m_item_kbw_ninja_gear_active:GetModifierTotalDamageOutgoing_Percentage(t)
	if exist(t.target) and t.target:GetTeam() == DOTA_TEAM_NEUTRALS then
		return -228
	end
end

function m_item_kbw_ninja_gear_active:OnCreated()
	if IsServer() then
		ReadAbilityData( self, {
			nRevealRange = 'reveal_range',
		} )

		self:StartIntervalThink( 0.1 )

		local sParticle = 'particles/items2_fx/smoke_of_deceit_buff.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, self:GetParent() )
	end
end

function m_item_kbw_ninja_gear_active:OnDestroy()
	if IsServer() then
		ParticleManager:Fade( self.nParticle, true )
	end
end

function m_item_kbw_ninja_gear_active:OnIntervalThink()
	local qEnemies = Find:UnitsInRadius({
		vCenter = self:GetParent(),
		nRadius = self.nRevealRange,
		nTeam = self:GetParent():GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
	})

	for _, hEnemy in ipairs( qEnemies ) do
		if hEnemy:GetTeam() ~= DOTA_TEAM_NEUTRALS then
			self:GetAbility():OnSpellStart()
			return
		end
	end
end