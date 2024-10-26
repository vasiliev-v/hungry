require 'lib/m_mult'
require 'lib/particle_manager'
require 'lib/modifier_self_events'

local sPath = "kbw/items/levels/jungle_totem"
LinkLuaModifier( 'm_item_jungle_totem_stats', sPath, 0 )
LinkLuaModifier( 'm_item_jungle_totem', sPath, 0 )
LinkLuaModifier( 'm_item_jungle_totem_counter', sPath, 0 )

local TEXTURES = {
	'item_jungle_totem',
	'item_jungle_totem2',
	'item_jungle_totem3',
}

local function UseCounter(hSpell, nGold)
	local nEarned = 0
	local hUnit = hSpell:GetCaster()
	local nDuration = hSpell:GetSpecialValueFor('time_limit')
	local hCounter = hUnit:FindModifierByName('m_item_jungle_totem_counter')
	local hAbility = hCounter and hCounter:GetAbility()

	if not hCounter or not hAbility or (hAbility.nLevel or 0) < (hSpell.nLevel or 0) then
		hCounter = hUnit:AddNewModifier(hUnit, hSpell, 'm_item_jungle_totem_counter', {
			duration = nDuration,
		})
	end

	if not hCounter then
		return nGold
	end

	nEarned = (hCounter.nEarned or 0)
	nGold = nGold + (hCounter.nPart or 0)

	local nGoldPart = nGold
	nGold = math.floor(nGold)
	nGoldPart = nGoldPart - nGold
	
	nEarned = nEarned + nGold
	local nOver = nEarned - hCounter.gold_limit
	if nOver > 0 then
		nGold = nGold - nOver
		nEarned = hCounter.gold_limit
	end

	if nGold > 0 then
		hCounter.nEarned = nEarned
		hCounter.nPart = nGoldPart
		hCounter:UpdateStacks()
		hCounter:SetDuration(nDuration, true)

		Timer(nDuration, function()
			if exist(hCounter) then
				hCounter.nEarned = hCounter.nEarned - nGold
				hCounter:UpdateStacks()
			end
		end)
	
		return nGold
	end

	return 0
end

base = {}

function base:CastFilterResultTarget( hTarget )
	if IsStatBoss(hTarget) then
		return UF_FAIL_OTHER
	end

    return UnitFilter( hTarget,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        self:GetCaster():GetTeamNumber()
    )
end

function base:GetCooldown( nLevel )
    if self.bTree then
        local nCd = self:GetSpecialValueFor('tree_cooldown')
        self.bTree = nil
        return nCd
    end

    return self.BaseClass.GetCooldown( self, nLevel )
end

function base:OnAbilityPhaseStart()
    if not self:GetCursorTarget().AddAbility then
        self.bTree = true
    end

    return true
end

function base:OnSpellStart()
    local hTarget = self:GetCursorTarget()
    local hCaster = self:GetCaster()
    local nPlayer = hCaster:GetPlayerOwnerID()
    local hPlayer = PlayerResource:GetPlayer( nPlayer )

    if hTarget.AddAbility then
        -- if hTarget:TriggerSpellAbsorb( self ) then
        --     return
        -- end

        hTarget:EmitSound('DOTA_Item.Hand_Of_Midas')

        local sParticle = 'particles/items2_fx/hand_of_midas.vpcf'
        local nParticle = ParticleManager:Create( sParticle, hTarget )
        ParticleManager:SetParticleControlEnt( nParticle, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false )
        ParticleManager:SetParticleControlEnt( nParticle, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hCaster:GetOrigin(), false )
        ParticleManager:Fade( nParticle, 3 )

        if hTarget:IsConsideredHero() then
            local nGold = 0

            if hTarget.GetGold and not hTarget:IsIllusion() then
                nGold = math.floor( hTarget:GetGold() * self:GetSpecialValueFor('active_gold_steal_pct') / 100 + 0.5 )
            end

            if nGold > 0 then
                PlayerResource:ModifyGold( nPlayer, nGold, true, 0 )
                PlayerResource:SpendGold( hTarget:GetPlayerOwnerID(), nGold, 0 )

                if hPlayer then
                    SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, hTarget, nGold, hPlayer )
                end
            end
        else
            local nGold = self:GetSpecialValueFor('active_base_gold')
            local nExpPct = self:GetSpecialValueFor('active_xp_pct')
			local nHealthGold = hTarget:GetMaxHealth() * self:GetSpecialValueFor('active_health_gold') / 100
            nGold = nGold + UseCounter(self, nHealthGold)

            local nDisplay = GameRules:ModifyGoldFiltered( nPlayer, nGold, true, 0 )

            if hPlayer then
                SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, hTarget, nDisplay, hPlayer )
            end

            hTarget:SetDeathXP( math.floor( hTarget:GetDeathXP() * nExpPct / 100 + 0.5 ) ) 
            hTarget:Kill( self, hCaster )
        end
    else
        if hTarget.CutDown then
            hTarget:CutDown( hCaster:GetTeam() )
        else
            hTarget:Kill()
        end

        local nGold = self:GetSpecialValueFor('tree_gold')
        local nDisplay = GameRules:ModifyGoldFiltered( nPlayer, nGold, true, 0 )

        if hPlayer then
            SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, hCaster, nDisplay, hPlayer )
        end
    end
end

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_jungle_totem_stats = 0,
        m_item_jungle_totem = self.nLevel,
    }
end

CreateLevels({
    'item_jungle_totem',
    'item_jungle_totem_2',
    'item_jungle_totem_3',
}, base )

m_item_jungle_totem_stats = ModifierClass{
    bMultiple = true,
    bHidden = true,
    bPermanent = true,
}

function m_item_jungle_totem_stats:OnCreated()
    ReadAbilityData( self, {
        nDamage = 'damage',
        nAttackSpeed = 'attack_speed',
        nAgility = 'agility',
    })
end

function m_item_jungle_totem_stats:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }
end

function m_item_jungle_totem_stats:GetModifierPreAttack_BonusDamage()
    return self.nDamage
end
function m_item_jungle_totem_stats:GetModifierAttackSpeedBonus_Constant()
    return self.nAttackSpeed
end
function m_item_jungle_totem_stats:GetModifierBonusStats_Agility()
    return self.nAgility
end

m_item_jungle_totem = ModifierClass{
    bHidden = true,
    bPermanent = true,
}

function m_item_jungle_totem:OnCreated()
    ReadAbilityData( self, {
        nDamgeGoldPct = 'damage_gold_pct',
        nCreepDamagePct = 'creep_damage_pct',
        nCreepReduction = 'creep_block_pct',
        nKillGold = 'kill_gold',
        nKillXp = 'kill_xp',
        nSpeedPct = 'move_speed_pct', 
        time_limit = 'time_limit', 
        gold_limit = 'gold_limit', 
    })

    if IsServer() then
        self:RegisterSelfEvents()
    end
end

function m_item_jungle_totem:OnDestroy()
    if IsServer() then
        self:UnregisterSelfEvents()
    end
end

function m_item_jungle_totem:OnParentDealDamage( t )
    if t.attacker:GetTeam() ~= t.unit:GetTeam() then
		local nGoldFull = t.damage * self.nDamgeGoldPct / 100
		local nGold = UseCounter(self:GetAbility(), nGoldFull)
		GameRules:ModifyGoldFiltered(t.attacker:GetPlayerOwnerID(), nGold, false, 0)
    end
end

function m_item_jungle_totem:OnParentKill( t )
    local nPlayer = t.attacker:GetPlayerOwnerID()
    local hPlayer = PlayerResource:GetPlayer( nPlayer )

    if exist( t.unit ) then
		ModifyExperienceFiltered(t.attacker, self.nKillXp, DOTA_ModifyXP_CreepKill)
        local nDisplay = GameRules:ModifyGoldFiltered( nPlayer, self.nKillGold, true, DOTA_ModifyGold_CreepKill)
        if hPlayer then
            SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, t.unit, nDisplay, hPlayer )
        end
    end
end

function m_item_jungle_totem:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function m_item_jungle_totem:GetModifierMoveSpeedBonus_Percentage()
    return self.nSpeedPct
end

function m_item_jungle_totem:GetModifierIncomingDamage_Percentage( t )
    if exist( t.attacker ) and ( t.attacker:IsCreep() or t.attacker.boss ) then
        return -self.nCreepReduction
    end
end

function m_item_jungle_totem:GetModifierTotalDamageOutgoing_Percentage( t )
    if exist( t.target ) and ( t.target:IsCreep() or t.target.boss ) then
        return self.nCreepDamagePct
    end
end

m_item_jungle_totem_counter = ModifierClass{
	bIgnoreDeath = true,
}

function m_item_jungle_totem_counter:OnCreated()
	ReadAbilityData(self, {
		'gold_limit',
	}, function(spell)
		self.texture = TEXTURES[spell.nLevel] or ''
	end)
end

function m_item_jungle_totem_counter:OnRefresh()
	self:OnCreated()
end

function m_item_jungle_totem_counter:GetTexture()
	return self.texture
end

function m_item_jungle_totem_counter:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function m_item_jungle_totem_counter:OnTooltip()
	return math.floor(self.gold_limit / 10)
end

function m_item_jungle_totem_counter:UpdateStacks()
	self:SetStackCount(math.floor(self.nEarned / 10))
end