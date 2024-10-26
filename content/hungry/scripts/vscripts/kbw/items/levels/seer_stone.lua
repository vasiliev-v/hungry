require 'lib/m_mult'
require 'lib/particle_manager'

local sPath = "kbw/items/levels/seer_stone"
LinkLuaModifier( 'm_item_kbw_seer_stone', sPath, 0 )

local base = {}

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_generic_stats = 0,
        m_item_generic_base = 0,
        m_item_generic_regen = 0,
        m_item_generic_spell_damage = 0,
        m_item_generic_cast_range_fix = 0,
        m_item_kbw_seer_stone = self.nLevel,
    }
end

--------------------------------------------------------------
-- close cooldown

function base:CastFilterResultLocation(target)
	if IsServer() then
		self.close_cast = (
			(target - self:GetCaster():GetOrigin()):Length2D() <=
			self:GetSpecialValueFor('close_vision_range')
		)
	end
end

function base:GetCooldown(level)
	if IsServer() and self.close_cast then
		return self:GetLevelSpecialValueFor('close_vision_cooldown', level)
	end

	return self.BaseClass.GetCooldown(self, level)
end

--------------------------------------------------------------
-- indicator

function base:GetCastRange(...)
	if IsClient() then
		return self:GetSpecialValueFor('close_vision_range')
	end
end

function base:GetAOERadius()
    return self:GetSpecialValueFor('active_radius')
end

--------------------------------------------------------------
-- active

function base:OnSpellStart()
    local nDuration = self:GetSpecialValueFor('active_duration')
    local nRadius = self:GetAOERadius()
    local vTarget = self:GetCursorPosition()
    local hCaster = self:GetCaster()
    local nTeam = hCaster:GetTeam()

	-- vision

    AddFOWViewer( nTeam, vTarget, nRadius, nDuration, false )

	-- true sight

    local hThinker = CreateModifierThinker( hCaster, self, 'modifier_truesight_aura', {
        duration = nDuration,
        radius = nRadius,
    }, vTarget, nTeam, false )

    Timer( nDuration, function()
        if exist( hThinker ) and hThinker:IsAlive() then
            hThinker:Destroy()
        end
    end )

	-- decoration

    local nParticle = ParticleManager:Create( 'particles/items4_fx/seer_stone.vpcf', PATTACH_WORLDORIGIN, nDuration + 3 )
    ParticleManager:SetParticleControl( nParticle, 0, vTarget )
    ParticleManager:SetParticleControl( nParticle, 1, Vector( nDuration, nRadius, 0 ) )

    EmitSoundOnLocationWithCaster( vTarget, 'Item.SeerStone', hCaster )
end

--------------------------------------------------------------
-- levels

CreateLevels({
    'item_kbw_lens',
    'item_kbw_seer_stone',
    'item_kbw_seer_stone_2',
    'item_kbw_seer_stone_3',
}, base )

--------------------------------------------------------------
-- passive unique

m_item_kbw_seer_stone = ModifierClass{
    bMultiple = true,
    bPermanent = true,
    bHidden = true,
}

function m_item_kbw_seer_stone:OnCreated()
    ReadAbilityData( self, {
        nCastRange = 'cast_range',
        nVision = 'vision',
    })
end

function m_item_kbw_seer_stone:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,
        MODIFIER_PROPERTY_BONUS_DAY_VISION,
        MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    }
end

function m_item_kbw_seer_stone:GetModifierCastRangeBonus()
    return self.nCastRange
end

function m_item_kbw_seer_stone:GetBonusDayVision()
    return self.nVision
end

function m_item_kbw_seer_stone:GetBonusNightVision()
    return self.nVision
end