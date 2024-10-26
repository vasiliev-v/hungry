m_kbw_hero = class{}

INTELLECT_SPELL_DAMAGE = 0.04
STRENGTH_MAGIC_HEALTH = 0.04
BOSS_DAMAGE_RANGE = 1800
UNIT_LIMIT = 32
PRE_GAME_TIME = 45
STAT_GAIN_GAIN = 0.175

local tAutoAttacks = {
	ancient_apparition_chilling_touch = true,
	drow_ranger_frost_arrows = true,
	huskar_burning_spear = true,
	silencer_glaives_of_wisdom = true,
	obsidian_destroyer_arcane_orb = true,
	jakiro_liquid_fire = true,
	jakiro_liquid_ice = true,
	enchantress_impetus = true,
	viper_poison_attack = true,
	clinkz_searing_arrows = true,
	tusk_walrus_punch = true,
	kunkka_tidebringer = true,
	doom_bringer_infernal_blade = true,
	omniknight_hammer_of_purity = true,
}

local tCustomProperties = {
	-- nDamageResist = {
    --     nModifierProperty = MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    --     sModifierFunction = 'GetModifierIncomingDamage_Percentage',
    --     sBaseGetter = 'KbwDamageInc',
    --     nOperation = OPERATION_ADD,
	-- 	nMultiplier = -100,
	-- },
    nHealAmp = {
        nModifierProperty = MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        sModifierFunction = 'GetModifierConstantHealthRegen',
        sBaseGetter = 'GetHealthRegen',
        nOperation = OPERATION_PCT,
		bUseRecForBase = true,
        bClient = true,
    },
    nStrAmp = {
        nModifierProperty = MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        sModifierFunction = 'GetModifierBonusStats_Strength',
        sBaseGetter = 'GetStrength',
        nOperation = OPERATION_PCT,
		bRound = true,
    },
    nAgiAmp = {
        nModifierProperty = MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        sModifierFunction = 'GetModifierBonusStats_Agility',
        sBaseGetter = 'GetAgility',
        nOperation = OPERATION_PCT,
		bRound = true,
    },
    nIntAmp = {
        nModifierProperty = MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        sModifierFunction = 'GetModifierBonusStats_Intellect',
        sBaseGetter = 'GetIntellect',
        nOperation = OPERATION_PCT,
		bRound = true,
    },
}

local tFunc = {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_HEALTH_BONUS,
}

for sSpecialName, tData in pairs( tCustomProperties ) do
    table.insert( tFunc, tData.nModifierProperty )

	if tData.bUseRecForBase then
		tData.sRecKey = 'Call' .. tData.sBaseGetter

		m_kbw_hero[ tData.sModifierFunction ] = function( self, tEvent )
			if self.hParent[ tData.sRecKey ] then
				return 0
			end
			return self[ tData.sBaseGetter ] or 0
		end
	else
		m_kbw_hero[ tData.sModifierFunction ] = function( self, tEvent )
			return self[ tData.sBaseGetter ] or 0
		end
	end
end

function m_kbw_hero:IsHidden()
    return true
end

function m_kbw_hero:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function m_kbw_hero:DeclareFunctions()
    return tFunc
end

function m_kbw_hero:GetCustomPropertyBaseValue( sSpecialName )
	local tData = tCustomProperties[ sSpecialName ]
	local fGetter = self.hParent[ tData.sBaseGetter ]

	if type( fGetter ) == 'function' then
		if tData.bUseRecForBase then
			self.hParent[ tData.sRecKey ] = true
			local nValue = round( fGetter( self.hParent ), 10 )
			self.hParent[ tData.sRecKey ] = nil
			return nValue
		else
			return round( fGetter( self.hParent ) - ( self[ tData.sBaseGetter ] or 0 ), 10 )
		end
	end
end

function m_kbw_hero:UpdateCustomProperty( sSpecialName, nBase )
	local tData = tCustomProperties[ sSpecialName ]
	local nValue = self.hParent[ sSpecialName ]
	local nResult

	nBase = nBase or self:GetCustomPropertyBaseValue( sSpecialName ) or 0

	if nValue then
		local fOperation = SpecialModifier.tOperations[ tData.nOperation ]

		if tData.nMultiplier then
			nValue = nValue * tData.nMultiplier
		end

		nResult = fOperation( nBase, nBase, nValue ) - nBase
	end

	if tData.bRound and nResult then
		nResult = math.floor( nResult + 0.5 )
	end

	self[ tData.sBaseGetter ] = nResult
	self.hParent:CalculateStatBonus()

	if tData.bClient then
		UpdateGenStat( self.hParent, tData.sBaseGetter, nResult )
	end
end

function m_kbw_hero:OnCreated()
    self.hParent = self:GetParent()
	self.nPlayer = self.hParent:GetPlayerOwnerID()
	self.nTick = 0
	

	if IsServer() then
		self.tBaseValues = {}

		for sSpecialName, tData in pairs( tCustomProperties ) do
			AddSpecialModifierListener( self.hParent, sSpecialName, function( nValue )
				self:UpdateCustomProperty( sSpecialName )
			end )
		end

		self.hParent.DAMAGE_DEAL_EVENT = {}
		
		self.INT_MAG_RESIST = GameRules:GetGameModeEntity():GetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MAGIC_RESIST)
	end

	self:StartIntervalThink( 0.1 )
end

function m_kbw_hero:OnDestroy()
	if IsServer() then
		Events:RemoveAllListeners( self.hParent.DAMAGE_DEAL_EVENT )
	end
end

function m_kbw_hero:OnIntervalThink()
    for sSpecialName, tData in pairs( tCustomProperties ) do
		if IsServer() then
			local nBase = self:GetCustomPropertyBaseValue( sSpecialName )

			if nBase ~= self.tBaseValues[ sSpecialName ] then
				self.tBaseValues[ sSpecialName ] = nBase
				self:UpdateCustomProperty( sSpecialName, nBase )
			end
		else
			if tData.bClient then
				self[ tData.sBaseGetter ] = GenTable:Get( 'GenStats.' .. self.hParent:entindex() .. '.' .. tData.sBaseGetter )
			end
		end
    end

	if IsServer() then
		self.nTick = self.nTick + 1
		if self.nTick > 9 then
			self.nTick = 0

			self.hParent:CalculateStatBonus()
		end

		local bScepter = self.hParent:HasScepter()
		if bScepter ~= self.bScepter then
			self.bScepter = bScepter
			for i = 0, self.hParent:GetAbilityCount() - 1 do
				local hAbility = self.hParent:GetAbilityByIndex(i)
				if hAbility and not hAbility:IsStolen() and hAbility.bScepterGranted then
					hAbility:SetHidden(not bScepter)
				end
			end
		end

		-- desolator fix
		IterateInventory(self.hParent, 'ACTIVE', function(nSlot, hItem)
			if hItem and hItem:GetName():match('desolator') then
				local nCharges = hItem:GetCurrentCharges()
				if not self.hParent.nDesolatorCharges or self.hParent.nDesolatorCharges <= nCharges then
					self.hParent.nDesolatorCharges = nCharges
				else
					hItem:SetCurrentCharges(math.min(hItem:GetSpecialValueFor('max_damage'), self.hParent.nDesolatorCharges))
				end
			end
		end)
		
		-- int mag resist disable
		local int = self.hParent:GetIntellect()
		if int ~= self.int then
			self.int = int
			local resist = self.INT_MAG_RESIST * int
			self.hParent:SetBaseMagicalResistanceValue(25 - resist)
		end
	end
end

function m_kbw_hero:GetModifierTotalDamageOutgoing_Percentage( t )
	if IsServer() then
		local tEvent = {
			bChange = false,
			hTarget = t.target,
			nDamage = t.original_damage,
			nDamageType = t.damage_type,
			nDamageFlags = t.damage_flags,
			hAbility = t.inflictor,
			nMultiplier = 1,
			nCrit = 100,
		}

		if t.inflictor then
			local sAbility = t.inflictor:GetName()
			if sAbility == 'sniper_concussive_grenade' then
				tEvent.bChange = true
				tEvent.nDamage = 750
			end
		end

		Events:Trigger( self.hParent.DAMAGE_DEAL_EVENT, tEvent )

		local tExtraData = _G.EXTRA_DAMAGE_DATA or {}
		_G.EXTRA_DAMAGE_DATA = nil

		if tEvent.bChange then
			local nDamage = tEvent.nDamage * tEvent.nMultiplier

			if tEvent.nCrit > 100 then
				local nCritBase = tExtraData.nCritBase or nDamage
				local nCritDisplay = nCritBase * tEvent.nCrit / 100
				nDamage = nDamage + nCritDisplay - nCritBase

				local nRound = round( nCritDisplay )
				local nDigits = math.floor( math.log( nRound, 10 ) ) + 2

				local vColor = ({
					[DAMAGE_TYPE_PHYSICAL] = Vector( 255, 0, 0 ),
					[DAMAGE_TYPE_MAGICAL] = Vector( 0, 110, 255 ),
					[DAMAGE_TYPE_PURE] = Vector( 255, 215, 0 ),
				})[ t.damage_type ] or Vector( 255, 255, 255 )

				local nParticle = ParticleManager:Create( 'particles/msg_fx/msg_crit.vpcf', PATTACH_CUSTOMORIGIN, t.target, 2 )
				ParticleManager:SetParticleControl( nParticle, 0, t.target:GetOrigin() + Vector( 0, 0, 150 ) )
				ParticleManager:SetParticleControl( nParticle, 1, Vector( 9, nRound, 4 ) )
				ParticleManager:SetParticleControl( nParticle, 2, Vector( 3, nDigits, 0 ) )
				ParticleManager:SetParticleControl( nParticle, 3, vColor )

				t.target:EmitSound('DOTA_Item.Daedelus.Crit')
			end

			return 100 * ( nDamage / t.original_damage - 1 )
		end
	end
end

function m_kbw_hero:GetModifierSpellAmplify_Percentage()
	if self.hParent.GetIntellect then
		return self.hParent:GetIntellect() * INTELLECT_SPELL_DAMAGE
	end
end

function m_kbw_hero:GetModifierMagicalResistanceBonus()
	if self.hParent.GetStrength then
		return 100 - 10000 / (100 + self.hParent:GetStrength() * STRENGTH_MAGIC_HEALTH)
	end
end

local function fGetSpecialAbilityValue(t)
	local name = t.ability:GetName()
	local value = t.ability_special_value
	local level = t.ability_special_level

	if IsServer() then
		if name == 'dawnbreaker_celestial_hammer' and value == 'range' then
			return 99999
		end

		local force_values = __tOverrideModifierValueAbilities[name]
		if force_values then
			local force_value = force_values[value]
			if force_value then
				return force_value
			end
		end
	end

	return GetModifiedAbilityValue(t.ability, value, level)
end

function m_kbw_hero:GetModifierOverrideAbilitySpecial( t )
    return fGetSpecialAbilityValue(t) ~= nil and 1 or 0
end

function m_kbw_hero:GetModifierOverrideAbilitySpecialValue( t )
    return fGetSpecialAbilityValue(t)
end

function m_kbw_hero:GetModifierCastRangeBonusStacking( t )
    if t.ability then
		-- if IsClient() and tAutoAttacks[ t.ability:GetName() ] then
		-- 	return -t.ability:GetCaster():GetCastRangeBonus()
		-- end

        local nLevel = t.ability_special_level
		if not nLevel or nLevel < 0 then
			nLevel = t.ability:GetLevel() - 1
		end

        local nValue = GetModifiedAbilityValue( t.ability, 'AbilityCastRange', nLevel )

        if nValue then
            return nValue - GetAbilityBaseValue( t.ability, 'AbilityCastRange', nLevel + 1 )
        end
    end
end

function m_kbw_hero:GetModifierHealthBonus()
	--return GetPlayerHealthBonus(self.nPlayer)
end

local function fGetVortexScepter(hUnit, hAttacker)
	if exist(hUnit) and hUnit:IsBaseNPC() and hAttacker:IsRangedAttacker() then
		local hMod = hUnit:FindModifierByName('modifier_ice_vortex')
		if hMod then
			local hCaster = hMod:GetCaster()
			if hCaster and hCaster:HasScepter() then
				return hMod:GetAbility()
			end
		end
	end
end

function m_kbw_hero:GetModifierAttackRangeBonus(t)
	if IsServer() then
		local hAbility = fGetVortexScepter(t.unit, self.hParent)
		if hAbility then
			return hAbility:GetSpecialValueFor('scepter_attack_range')
		end
	end
	return 0
end

function m_kbw_hero:GetModifierProjectileSpeedBonus(t)
	if IsServer() then
		local hAbility = fGetVortexScepter(t.target, self.hParent)
		if hAbility then
			return hAbility:GetSpecialValueFor('scepter_proj_speed')
		end
	end
	return 0
end

function m_kbw_hero:GetModifierMoveSpeedBonus_Percentage()
	local nBonus = 0

	-- Axe ms talent
	local hTalent = self.hParent:FindAbilityByName('special_bonus_unique_axe_8')
	if hTalent and hTalent:GetLevel() > 0 then
		nBonus = nBonus + self.hParent:GetModifierStackCount('modifier_axe_battle_hunger_self', self.hParent) * 10
	end

	return nBonus
end