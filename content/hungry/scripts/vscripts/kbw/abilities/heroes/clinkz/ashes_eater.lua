require 'lib/particle_manager'

LinkLuaModifier( 'm_clinkz_ashes_eater_kbw_counter', "kbw/abilities/heroes/clinkz/ashes_eater", 0 )
LinkLuaModifier( 'm_clinkz_ashes_eater_kbw_active', "kbw/abilities/heroes/clinkz/ashes_eater", 0 )

clinkz_ashes_eater_kbw = class{}

function clinkz_ashes_eater_kbw:OnSpellStart()
    local hCaster = self:GetCaster()

    local hMod = hCaster:FindModifierByName('m_clinkz_ashes_eater_kbw_counter')
    
    if hMod then
		self:Reapply( nil, self:GetSpecialValueFor('duration'), hMod:GetStackCount() )

		hMod:SetStackCount( 0 )
		self:SetActivated( false )
    else
        return
    end
    
    local sParticle = 'particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf'
    local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN, hCaster )
    ParticleManager:SetParticleControlEnt( nParticle, 0, hCaster, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hCaster:GetOrigin(), false )
    ParticleManager:SetParticleControlEnt( nParticle, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hCaster:GetOrigin(), false )

    hCaster:EmitSound('Hero_Clinkz.DeathPact')
    hCaster:EmitSound('Hero_Clinkz.DeathPact.Cast')
end

function clinkz_ashes_eater_kbw:GetTalentPassive()
	local hTalent = self:GetCaster():FindAbilityByName('special_bonus_unique_clinkz_ashes_eater_passive')
	if hTalent and hTalent:IsTrained() then
		return hTalent
	end
end

function clinkz_ashes_eater_kbw:AddPassiveStacks( nStacks )
	local hTalent = self:GetTalentPassive()

	if hTalent then
		local nDuration = hTalent:GetSpecialValueFor('duration')
		local hCaster = self:GetCaster()

		self.hPassiveBuff = self:Reapply( self.hPassiveBuff, nDuration, nStacks )

		Timer( nDuration, function()
			if exist( self.hPassiveBuff ) then
				self.hPassiveBuff = self:Reapply( self.hPassiveBuff, self.hPassiveBuff:GetRemainingTime(), -nStacks )
			end
		end )
	end
end

function clinkz_ashes_eater_kbw:Reapply( hBuff, nDuration, nStacks )
	if exist( hBuff ) then
		nStacks = nStacks + hBuff:GetStackCount()
		hBuff:Destroy()
	end

	local hCaster = self:GetCaster()

	local hBuff = AddModifier( 'm_clinkz_ashes_eater_kbw_active', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		duration = nDuration,
		stacks = nStacks,
	})

	hBuff:UpdateHealth()

	return hBuff
end

function clinkz_ashes_eater_kbw:OnUpgrade()
	if exist( self.hPassiveBuff ) then
		self.hPassiveBuff = self:Reapply( self.hPassiveBuff, self.hPassiveBuff:GetRemainingTime(), 0 )
	end

    if self:GetLevel() == 1 then
        self:SetActivated( false )
    end
end

function clinkz_ashes_eater_kbw:GetIntrinsicModifierName()
    return 'm_clinkz_ashes_eater_kbw_counter'
end

m_clinkz_ashes_eater_kbw_counter = class{}

function m_clinkz_ashes_eater_kbw_counter:IsPurgable()
    return false
end

function m_clinkz_ashes_eater_kbw_counter:IsPurgeException()
    return false
end

function m_clinkz_ashes_eater_kbw_counter:RemoveOnDeath()
    return false
end

function m_clinkz_ashes_eater_kbw_counter:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
    }
end

function m_clinkz_ashes_eater_kbw_counter:OnDeath( kv )
    local hParent = self:GetParent()
    local hAbility = self:GetAbility()

    if IsStatBoss( kv.unit ) then
        if kv.attacker == hParent
        or ( hParent:GetOrigin() - kv.unit:GetOrigin() ):Length2D() <= hAbility:GetSpecialValueFor('boss_range') then
			local nStacks = hAbility:GetSpecialValueFor('max_stacks')
            self:SetStackCount( nStacks )
            hAbility:SetActivated( true )
			hAbility:AddPassiveStacks( nStacks )
        end

        return
    end

    if kv.attacker and kv.attacker:GetPlayerOwnerID() == hParent:GetPlayerOwnerID() then
        local nStacks = 1

        if kv.unit:IsConsideredHero() and not kv.unit:IsIllusion() then
            nStacks = hAbility:GetSpecialValueFor('hero_kill_stacks')
        end

        self:SetStackCount( math.min( hAbility:GetSpecialValueFor('max_stacks'), self:GetStackCount() + nStacks ) )
        hAbility:SetActivated( true )
		hAbility:AddPassiveStacks( nStacks )
    end
end

m_clinkz_ashes_eater_kbw_active = class{}

function m_clinkz_ashes_eater_kbw_active:IsPurgable()
    return false
end

function m_clinkz_ashes_eater_kbw_active:IsPurgeException()
    return false
end

function m_clinkz_ashes_eater_kbw_active:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function m_clinkz_ashes_eater_kbw_active:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    }
end

function m_clinkz_ashes_eater_kbw_active:OnCreated( t )
	local hParent = self:GetParent()

	if IsServer() then
		self.nHealthBonus = 0
		self.nCurrentHealth = hParent:GetHealth()

		self:StartIntervalThink( 1/30 )

		local sParticle = 'particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf'
		self.nParticle = ParticleManager:Create( sParticle, hParent )
	end

	ReadAbilityData( self, {
        nDamage = 'stack_damage',
        nHealth = 'stack_health',
    }, function( hAbility )
		if IsServer() then
			if t.stacks then
				self:SetStackCount( t.stacks )
				self.nHealthBonus = self:GetModifierExtraHealthBonus()
				self.nCurrentHealth = hParent:GetHealth() + self.nHealthBonus
			end
		end
	end )
end

function m_clinkz_ashes_eater_kbw_active:UpdateHealth()
	local hParent = self:GetParent()
	hParent:SetHealth( hParent:GetHealth() + self.nHealthBonus )
end

function m_clinkz_ashes_eater_kbw_active:OnIntervalThink()
	self.nCurrentHealth = self:GetParent():GetHealth()
end

function m_clinkz_ashes_eater_kbw_active:OnDestroy()
    if IsServer() then
		local hParent = self:GetParent()
		if hParent:IsAlive() then 
			hParent:SetHealth( math.max( 1, self.nCurrentHealth - self.nHealthBonus ) )
		end

        if self.nParticle then
            ParticleManager:Fade( self.nParticle, true )
        end
    end
end

function m_clinkz_ashes_eater_kbw_active:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self.nDamage
end

function m_clinkz_ashes_eater_kbw_active:GetModifierExtraHealthBonus()
    return self:GetStackCount() * self.nHealth
end