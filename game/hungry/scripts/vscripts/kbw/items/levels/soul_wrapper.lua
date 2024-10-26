require 'lib/m_mult'
require 'lib/particle_manager'

LinkLuaModifier('m_item_kbw_witch_blade_debuff', "kbw/items/witch_blade", LUA_MODIFIER_MOTION_NONE)

local sPath = "kbw/items/levels/soul_wrapper"
LinkLuaModifier( 'm_item_soul_wrapper_stats', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_soul_wrapper', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_soul_wrapper_dash', sPath, LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( 'm_item_soul_wrapper_buff', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_soul_wrapper_charge', sPath, LUA_MODIFIER_MOTION_NONE )

local function fFilterTarget(hUnit, hAttacker)
	return hUnit and hUnit:IsBaseNPC()
	and UnitFilter(
		hUnit,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		hAttacker:GetTeam()
	) == UF_SUCCESS
end

local base = {}

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_soul_wrapper_stats = -1,
        m_item_generic_base_damage = -1,
        m_item_soul_wrapper = self.nLevel,
    }
end

function base:Precache(c)
	PrecacheResource("particle", 'particles/items/soul_wrapper/cleave.vpcf', c)
	PrecacheResource("particle", 'particles/items/soul_wrapper/status_effect.vpcf', c)
	PrecacheResource("particle", 'particles/econ/courier/courier_trail_divine/courier_divine_ambient.vpcf', c)
	PrecacheResource("particle", 'particles/items/soul_wrapper/trail.vpcf', c)	
end
-- function base:GetCastRange( hTarget, vTarget )
--     if IsClient() then
--         return self:GetSpecialValueFor('dash_range')
--     end

--     return 0
-- end

function base:OnSpellStart()
    local hCaster = self:GetCaster()
    local vStart = hCaster:GetOrigin()
    local vTarget = self:GetCursorPosition()
    local nRange = self:GetSpecialValueFor('dash_range') -- + hCaster:GetCastRangeBonus()
    local nSpeed = self:GetSpecialValueFor('dash_speed')
    local nDuration = self:GetSpecialValueFor('buff_duration')
    local nTreeBreak = self:GetSpecialValueFor('tree_cut_range')

    local vDelta = vTarget - vStart
    local nDelta = vDelta:Length2D()

    if nDelta > nRange then
        nDelta = nRange
        vTarget = vStart + vDelta:Normalized() * nRange
    end

    local nFlyTime = nDelta / nSpeed

    hCaster:Purge( false, true, false, false, false )
	
	hCaster:AddNewModifier( hCaster, self, 'm_item_soul_wrapper_buff', {
		duration = nDuration + nFlyTime,
	})
	hCaster:AddNewModifier( hCaster, self, 'm_item_soul_wrapper_charge', {
		duration = self:GetSpecialValueFor('charge_duration') + nFlyTime,
	})

	local hMotion = hCaster:AddNewModifier( hCaster, self, 'm_item_soul_wrapper_dash', {} )
	if hMotion then
		hMotion:Start( vTarget, nSpeed, nTreeBreak )
	end

    hCaster:EmitSound('KBW.Item.SoulWrapper.Dash')
end

CreateLevels({
    'item_soul_wrapper',
    'item_soul_wrapper_2',
    'item_soul_wrapper_3',
}, base )

m_item_soul_wrapper_stats = ModifierClass{
    bMultiple = true,
    bPermanent = true,
    bHidden = true,
}

function m_item_soul_wrapper_stats:OnCreated()
    ReadAbilityData( self, {
        nAgi = 'agi',
        nAttackSpeed = 'attack_speed',
        nDamage = 'damage',
        nHealth = 'health',
        nProjSpeed = 'proj_speed',
        nMpRegen = 'mp_regen',
        nAccuracy = 'accuracy',
    })
end

function m_item_soul_wrapper_stats:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

function m_item_soul_wrapper_stats:GetModifierBonusStats_Agility()
    return self.nAgi
end
function m_item_soul_wrapper_stats:GetModifierAttackSpeedBonus_Constant()
    return self.nAttackSpeed
end
function m_item_soul_wrapper_stats:GetModifierPreAttack_BonusDamage()
    return self.nDamage
end
function m_item_soul_wrapper_stats:GetModifierHealthBonus()
    return self.nHealth
end
function m_item_soul_wrapper_stats:GetModifierProjectileSpeedBonus()
    return self.nProjSpeed
end
function m_item_soul_wrapper_stats:GetModifierConstantManaRegen()
    return self.nMpRegen
end

function m_item_soul_wrapper_stats:CheckState()
	if IsServer() then
		if RandomFloat(0, 100) <= self.nAccuracy then
			return {
				[MODIFIER_STATE_CANNOT_MISS] = true,
			}
		end
	end
	return {}
end

m_item_soul_wrapper = ModifierClass{
    bMultiple = true,
    bPermanent = true,
    bHidden = true,
}

-- function m_item_soul_wrapper:IsActive()
-- 	return not self:GetParent():NotRealHero()
-- end

-- function m_item_soul_wrapper:CheckState()
-- 	if IsServer() then
-- 		if self:IsActive() and RollPercentage(self.nAccuracy) then
-- 			self.bProc = true
-- 			return {
-- 				[MODIFIER_STATE_CANNOT_MISS] = true,
-- 			}
-- 		else
-- 			self.bProc = nil
-- 		end
-- 	end

-- 	return {}
-- end

function m_item_soul_wrapper:OnCreated()
    ReadAbilityData( self, {
        'poison_duration',
        -- nAccuracy = 'accuracy',
        -- nSplash = 'splash',
        -- nSplashRadius = 'splash_radius',
        -- nSplashBase = 'base_damage',
    })

	if IsServer() then
		self.tProcs = {}
		self.nProcs = 0

		self:RegisterSelfEvents()
	end
end

function m_item_soul_wrapper:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_soul_wrapper:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_OVERRIDE_ATTACK_MAGICAL,
    }
end

function m_item_soul_wrapper:GetOverrideAttackMagical(t)
	if IsServer() then
		return (self.nProcs > 0 or self:GetParent():HasModifier('m_item_soul_wrapper_charge')) and 1 or 0
	end
	return 1
end

function m_item_soul_wrapper:OnParentAttackLanded(t)
	if fFilterTarget(t.target, t.attacker) then
		AddModifier('m_item_kbw_witch_blade_debuff', {
			hTarget = t.target,
			hCaster = t.attacker,
			hAbility = self:GetAbility(),
			duration = self.poison_duration + 0.1,
		})
	end

	if self.tProcs[t.record] then
		t.target:AddNewModifier(t.target, nil, 'm_kbw_attack_immune', {duration = 0})

		if not t.target:IsMagicImmune() then
			ApplyDamage({
				victim = t.target,
				attacker = t.attacker,
				ability = self:GetAbility(),
				damage = t.damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})
		end
	end
end

function m_item_soul_wrapper:OnParentAttackRecordDestroy(t)
	self:UnrecordProc(t.record)
end

function m_item_soul_wrapper:RecordMagic(nRecord)
	self.tProcs[nRecord] = true
	self.nProcs = self.nProcs + 1
end

function m_item_soul_wrapper:UnrecordProc(nRecord)
	if self.tProcs[nRecord] then
		self.tProcs[nRecord] = nil
		self.nProcs = self.nProcs - 1
	end
end

-- function m_item_soul_wrapper:OnParentAttackRecord(t)
-- 	if self.bProc and t.target:IsBaseNPC() then
-- 		self.bProc = nil
-- 		self.tProcRecords[ t.record ] = true
-- 	end
-- end

-- function m_item_soul_wrapper:OnParentAttackLanded(t)
-- 	if self:IsActive() and self.tProcRecords[ t.record ] then
-- 		local nDamage = self.nSplashBase + t.original_damage * self.nSplash / 100
-- 		local vCenter = t.target:GetOrigin()
-- 		local hAbility = self:GetAbility()

-- 		local qEnemies = Find:UnitsInRadius({
-- 			vCenter = vCenter,
-- 			nRadius = self.nSplashRadius,
-- 			nTeam = t.attacker:GetTeam(),
-- 			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
-- 			nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
-- 			nFilterFlag = 0,
-- 		})

-- 		local nParticle = ParticleManager:Create('particles/items/soul_wrapper/cleave.vpcf', PATTACH_CUSTOMORIGIN, nil, 1)
-- 		ParticleManager:SetParticleControl(nParticle, 0, vCenter)
--         ParticleManager:SetParticleFoWProperties(nParticle, 0, 0, self.nSplashRadius)

-- 		for nOrder, hUnit in ipairs(qEnemies) do
-- 			ApplyDamage({
-- 				victim = hUnit,
-- 				attacker = t.attacker,
-- 				ability = hAbility,
-- 				damage = nDamage,
-- 				damage_type = DAMAGE_TYPE_MAGICAL,
-- 				damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
-- 			})

-- 			if nOrder <= 16 then
-- 				ParticleManager:SetParticleControlEnt(nParticle, nOrder, hUnit, PATTACH_ABSORIGIN_FOLLOW, nil, hUnit:GetOrigin(), false)
-- 			end
-- 		end
-- 	end
-- end

m_item_soul_wrapper_dash = ModifierClass{
    bPurgable = false,
	bHidden = true,
}

-- function m_item_soul_wrapper_dash:GetTexture()
--     return "item_soul_wrapper"
-- end

-- function m_item_soul_wrapper_dash:GetStatusEffectName()
--     return 'particles/items/soul_wrapper/status_effect.vpcf'
-- end

function m_item_soul_wrapper_dash:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

-- function m_item_soul_wrapper_dash:OnCreated()
-- 	if IsServer() then
-- 		local hParent = self:GetParent()

-- 		local sParticle1 = 'particles/econ/courier/courier_trail_divine/courier_divine_ambient.vpcf'
-- 		self.nParticle1 = ParticleManager:Create( sParticle1, hParent )

-- 		local sParticle2 = 'particles/items/soul_wrapper/trail.vpcf'
-- 		self.nParticle2 = ParticleManager:Create( sParticle2, PATTACH_CUSTOMORIGIN, nil )
-- 		ParticleManager:SetParticleControl( self.nParticle2, 0, hParent:GetAttachmentOrigin(hParent:ScriptLookupAttachment('attach_hitloc')) )
-- 		ParticleManager:SetParticleControl( self.nParticle2, 15, Vector( 110, 181, 203 ) )
-- 	end
-- end

function m_item_soul_wrapper_dash:Start( vTarget, nSpeed, nTreeBreak )
    self.vPos = self:GetParent():GetOrigin()
    self.vDir = vTarget - self.vPos
    self.vDir.z = 0
    self.nDistance = #self.vDir
    
    if self.nDistance < 1 then
        self:Destroy()
		return
    end
    
    self.vDir = self.vDir:Normalized()
    self.nSpeed = nSpeed
    self.nTreeBreak = nTreeBreak

	-- ParticleManager:SetParticleControl( self.nParticle2, 1, self.vPos )
	-- ParticleManager:SetParticleControl( self.nParticle2, 2, self.vPos + self.vDir * self.nDistance )
	-- ParticleManager:SetParticleFoWProperties( self.nParticle2, 1, 2, 128 )
    
    if not self:ApplyHorizontalMotionController() then
        self:Destroy()
    end
end

function m_item_soul_wrapper_dash:End()
    if IsServer() then
        self:GetParent():RemoveHorizontalMotionController( self )
        self:Destroy()
    end
end

function m_item_soul_wrapper_dash:OnHorizontalMotionInterrupted()
    self:End()
end

function m_item_soul_wrapper_dash:OnDestroy()
    if IsServer() then
        local hParent = self:GetParent()
        FindClearSpaceForUnit( hParent, hParent:GetOrigin(), false )

		-- ParticleManager:Fade( self.nParticle1, true )
		-- ParticleManager:Fade( self.nParticle2, true )
    end
end

function m_item_soul_wrapper_dash:UpdateHorizontalMotion( hUnit, nTimeDelta )
    local bEnd = false
    local hParent = self:GetParent()
    local nDelta = self.nSpeed * nTimeDelta
    
    if nDelta > self.nDistance then
        nDelta = self.nDistance
        bEnd = true
    end
    
    self.nDistance = self.nDistance - nDelta
    self.vPos = GetGroundPosition( self.vPos + self.vDir * nDelta, hParent )

    -- GridNav:DestroyTreesAroundPoint( self.vPos, self.nTreeBreak, false )
    
    hParent:SetAbsOrigin( self.vPos )

	-- ParticleManager:SetParticleControl( self.nParticle2, 0, hParent:GetAttachmentOrigin(hParent:ScriptLookupAttachment('attach_hitloc')) )
    
    if bEnd then
        self:End()
    end
end

m_item_soul_wrapper_buff = ModifierClass{
    bPurgable = false,
}

function m_item_soul_wrapper_buff:GetStatusEffectName()
    return 'particles/items/soul_wrapper/status_effect.vpcf'
end

function m_item_soul_wrapper_buff:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    }
end

-- function m_item_soul_wrapper_buff:DeclareFunctions()
--     return {
--         MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
--     }
-- end

function m_item_soul_wrapper_buff:OnCreated()
    -- ReadAbilityData( self, {
    --     nMoveSpeed = 'buff_movespeed',
    -- })

    if IsServer() then
        local hParent = self:GetParent()

        local sParticle1 = 'particles/econ/courier/courier_trail_divine/courier_divine_ambient.vpcf'
        self.nParticle1 = ParticleManager:Create( sParticle1, hParent )

        local sParticle2 = 'particles/items/soul_wrapper/trail.vpcf'
        self.nParticle2 = ParticleManager:Create( sParticle2, PATTACH_CUSTOMORIGIN, hParent )
        ParticleManager:SetParticleControlEnt( self.nParticle2, 0, hParent, PATTACH_POINT_FOLLOW, 'attach_hitloc', hParent:GetOrigin(), false )
        ParticleManager:SetParticleControl( self.nParticle2, 15, Vector( 110, 181, 203 ) )
    end
end

function m_item_soul_wrapper_buff:OnDestroy()
    if IsServer() then
        ParticleManager:Fade( self.nParticle1, true )
        ParticleManager:Fade( self.nParticle2, true )
    end
end

-- function m_item_soul_wrapper_buff:GetModifierMoveSpeedBonus_Constant()
--     return self.nMoveSpeed
-- end

m_item_soul_wrapper_charge = ModifierClass{
	bPurgable = true,
}

function m_item_soul_wrapper_charge:OnCreated()
	if IsServer() then
		local hParent = self:GetParent()

		self:RegisterSelfEvents()

		self.nParticle = ParticleManager:Create('particles/items5_fx/revenant_brooch.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, hParent:GetOrigin(), false)
	end
end

function m_item_soul_wrapper_charge:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()

		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_item_soul_wrapper_charge:OnParentAttack(t)
	if fFilterTarget(t.target, t.attacker) then
		local hMod = t.attacker:FindModifierByName('m_item_soul_wrapper')
		if hMod and hMod.RecordMagic then
			hMod:RecordMagic(t.record)
		end

		self:Destroy()
	end
end

function m_item_soul_wrapper_charge:CheckState()
	return {
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}
end

function m_item_soul_wrapper_charge:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROJECTILE_NAME,
	}
end

function m_item_soul_wrapper_charge:GetModifierProjectileName(t)
	if IsServer() then
		local hParent = self:GetParent()
		if fFilterTarget(hParent:GetAttackTarget(), hParent) then
			return 'particles/econ/events/diretide_2020/attack_modifier/attack_modifier_v1_fall20.vpcf'
		end
	end
end