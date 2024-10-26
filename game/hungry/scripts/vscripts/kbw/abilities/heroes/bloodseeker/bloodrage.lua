require 'lib/modifier'
require 'lib/particle_manager'

LinkLuaModifier( 'm_bloodseeker_bloodrage_kbw', "kbw/abilities/heroes/bloodseeker/bloodrage", 0 )
LinkLuaModifier( 'm_bloodseeker_bloodrage_kbw_shard', "kbw/abilities/heroes/bloodseeker/bloodrage", 0 )
LinkLuaModifier( 'm_bloodseeker_bloodrage_kbw_shard_enemy', "kbw/abilities/heroes/bloodseeker/bloodrage", 0 )

bloodseeker_bloodrage_kbw = class{}

function bloodseeker_bloodrage_kbw:OnSpellStart()
    local hCaster = self:GetCaster()
    local hTarget = self:GetCursorTarget()
    local nDuration = self:GetSpecialValueFor('duration')

    AddModifier( 'm_bloodseeker_bloodrage_kbw', {
        hTarget = hTarget,
        hCaster = hCaster,
        hAbility = self,
        bStacks = true,
        duration = nDuration,
    })

    if hCaster:HasShard() then
        local sShardBuff = 'm_bloodseeker_bloodrage_kbw_shard'
        if hCaster:GetTeam() ~= hTarget:GetTeam() then
            sShardBuff = 'm_bloodseeker_bloodrage_kbw_shard_enemy'
        end

        AddModifier( sShardBuff, {
            hTarget = hTarget,
            hCaster = hCaster,
            hAbility = self,
            bStacks = true,
            duration = nDuration,
        })
    end

    hCaster:EmitSound("hero_bloodseeker.bloodRage")
end

m_bloodseeker_bloodrage_kbw = class{}

function m_bloodseeker_bloodrage_kbw:OnCreated( t )
    self:OnRefresh( t )

    if IsServer() then
        local sParticle = 'particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf'
        self.nParticle = ParticleManager:Create( sParticle, self:GetParent() )
    end
end

function m_bloodseeker_bloodrage_kbw:OnRefresh( t )
    ReadAbilityData( self, {
        nDamageAmp = 'damage_amp',
    })
end

function m_bloodseeker_bloodrage_kbw:OnDestroy()
    if IsServer() then
        if self.nParticle then
            ParticleManager:Fade( self.nParticle, true )
        end
    end
end

function m_bloodseeker_bloodrage_kbw:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function m_bloodseeker_bloodrage_kbw:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetStackCount() * self.nDamageAmp
end

function m_bloodseeker_bloodrage_kbw:GetModifierIncomingDamage_Percentage()
    return self:GetStackCount() * self.nDamageAmp
end

local m_shard_tmp = {}

function m_shard_tmp:OnCreated( t )
    self:OnRefresh( t )

    if IsServer() then
        self:RegisterSelfEvents()
    end
end

function m_shard_tmp:OnRefresh( t )
    ReadAbilityData( self, {
        nDamagePct = 'shard_damage_pct',
        nBossDeAmp = 'shard_boss_deamp',
    }, function( hAbility )
        self.hAbility = hAbility
    end )
end

function m_shard_tmp:OnDestroy()
    if IsServer() then
        self:UnregisterSelfEvents()
    end
end

function m_shard_tmp:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP,
    }
end

function m_shard_tmp:OnTooltip()
    return self:GetStackCount() * self.nDamagePct
end

local function fAttackLanded( self, t )
	if not t.target:IsBaseNPC() or UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		t.attacker:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

    local nDamage = self:GetStackCount() * t.target:GetMaxHealth() * self.nDamagePct / 100
    if IsBoss( t.target ) then
        nDamage = nDamage * ( 100 - self.nBossDeAmp ) / 100
    end

    ApplyDamage{
        victim = t.target,
        attacker = t.attacker,
        ability = self.hAbility,
        damage = nDamage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
    }

    t.attacker:Heal( nDamage, self.hAbility )
end

m_bloodseeker_bloodrage_kbw_shard = class{}
m_bloodseeker_bloodrage_kbw_shard_enemy = class{}

for k, v in pairs( m_shard_tmp ) do
    m_bloodseeker_bloodrage_kbw_shard[ k ] = v
    m_bloodseeker_bloodrage_kbw_shard_enemy[ k ] = v
end

m_bloodseeker_bloodrage_kbw_shard.OnParentAttackLanded = fAttackLanded
m_bloodseeker_bloodrage_kbw_shard_enemy.OnParentTakeAttackLanded = fAttackLanded