local sPath = "kbw/items/levels/bloodstone"
LinkLuaModifier('m_item_item_kbw_bloodstone_stats', sPath, 0)
LinkLuaModifier('m_item_item_kbw_bloodstone', sPath, 0)
LinkLuaModifier('m_item_item_kbw_bloodstone_active', sPath, 0)

local base = {}

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_item_kbw_bloodstone_stats = 0,
        m_item_item_kbw_bloodstone = self.nLevel
    }
end

function base:OnSpellStart()
    local hCaster = self:GetCaster()

    AddModifier('m_item_item_kbw_bloodstone_active', {
        hTarget = hCaster,
        hCaster = hCaster,
        hAbility = self,
        duration = self:GetSpecialValueFor('buff_duration')
    })

	hCaster:EmitSound('DOTA_Item.Bloodstone.Cast')
end

CreateLevels({'item_kbw_bloodstone', 'item_kbw_bloodstone_2', 'item_kbw_bloodstone_3'}, base)

m_item_item_kbw_bloodstone_active = ModifierClass {}

function m_item_item_kbw_bloodstone_active:OnCreated()
    if IsServer() then

        local hParent = self:GetParent()

        local particle = ParticleManager:CreateParticle("particles/items_fx/bloodstone_heal.vpcf",
            PATTACH_OVERHEAD_FOLLOW, hParent)
        ParticleManager:SetParticleControlEnt(particle, 2, hParent, PATTACH_POINT_FOLLOW, "attach_hitloc",
            hParent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 1, hParent, PATTACH_POINT_FOLLOW, "attach_hitloc",
            hParent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 6, hParent, PATTACH_POINT_FOLLOW, "attach_hitloc",
            hParent:GetAbsOrigin(), true)
        self:AddParticle(particle, false, false, -1, false, false)
    end
end

function m_item_item_kbw_bloodstone_active:OnDestroy()

end

function m_item_item_kbw_bloodstone_active:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOOLTIP}
end

m_item_item_kbw_bloodstone_stats = ModifierClass {
    bMultiple = true,
    bPermanent = true,
    bHidden = true
}

function m_item_item_kbw_bloodstone_stats:OnCreated()
    ReadAbilityData(self, {'bonus_health', 'bonus_mana'})
end

function m_item_item_kbw_bloodstone_stats:DeclareFunctions()
    return {MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_MANA_BONUS}
end

function m_item_item_kbw_bloodstone_stats:GetModifierHealthBonus()
    return self.bonus_health
end

function m_item_item_kbw_bloodstone_stats:GetModifierManaBonus()
    return self.bonus_mana
end

m_item_item_kbw_bloodstone = ModifierClass {
    bHidden = true,
    bPermanent = true
}

function m_item_item_kbw_bloodstone:OnCreated()
    ReadAbilityData(self, {
        nLifesteal = 'hero_lifesteal',
        nLifestealCreeps = 'creep_lifesteal',
        nActiveMult = 'lifesteal_multiplier',
        nManaLifestealPct = 'mana_lifesteal'
    })

    if IsServer() then
        self:RegisterSelfEvents()
    end
end

function m_item_item_kbw_bloodstone:OnDestroy()
    if IsServer() then
        self:UnregisterSelfEvents()
    end
end

function m_item_item_kbw_bloodstone:OnParentDealDamage(tEvent)
    if tEvent.inflictor and tEvent.unit:GetTeam() ~= tEvent.attacker:GetTeam() and
        not binhas(tEvent.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_HPLOSS,
            DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) then

        local nMultiplier = self.nLifestealCreeps
        if tEvent.unit:IsConsideredHero() and not tEvent.unit:IsIllusion() then
            nMultiplier = self.nLifesteal
        end

        local hParent = self:GetParent()
        local bActive = hParent:HasModifier("m_item_item_kbw_bloodstone_active")

        if bActive then
            nMultiplier = nMultiplier * self.nActiveMult
        end

        local nHeal = tEvent.damage * nMultiplier / 100
        hParent:Heal(nHeal, self:GetAbility())

        if bActive then
            hParent:GiveMana(nHeal * self.nManaLifestealPct / 100)
        end

        local nCurTime = GameRules:GetGameTime()
        if not self.nLastParticleTime or self.nLastParticleTime + 0.5 <= nCurTime then
            local sParticle = 'particles/items3_fx/octarine_core_lifesteal.vpcf'
            ParticleManager:Create(sParticle, hParent, 2)

			if bActive then
				ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle(
					"particles/items_fx/arcane_boots_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, hParent))
			end

            self.nLastParticleTime = nCurTime
        end
    end
end
