local sPath = "kbw/items/hand_of_midas"
LinkLuaModifier('m_item_kbw_hand_of_midas', sPath, LUA_MODIFIER_MOTION_NONE)

item_kbw_hand_of_midas = class{}

function item_kbw_hand_of_midas:GetIntrinsicModifierName()
	return 'm_item_kbw_hand_of_midas'
end

function item_kbw_hand_of_midas:OnSpellStart()
    local hTarget = self:GetCursorTarget()
    local hCaster = self:GetCaster()
    local nPlayer = hCaster:GetPlayerOwnerID()
    local hPlayer = PlayerResource:GetPlayer( nPlayer )
	local nGold = self:GetSpecialValueFor('bonus_gold')
	local nExpPct = self:GetSpecialValueFor('xp_pct')

	hTarget:EmitSound('DOTA_Item.Hand_Of_Midas')

	local sParticle = 'particles/items2_fx/hand_of_midas.vpcf'
	local nParticle = ParticleManager:Create( sParticle, hTarget )
	ParticleManager:SetParticleControlEnt( nParticle, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hTarget:GetOrigin(), false )
	ParticleManager:SetParticleControlEnt( nParticle, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', hCaster:GetOrigin(), false )
	ParticleManager:Fade( nParticle, 3 )

	local nDisplay = GameRules:ModifyGoldFiltered(nPlayer, nGold, true, DOTA_ModifyGold_CreepKill)

	if hPlayer then
		SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, hTarget, nDisplay, hPlayer )
	end

	hTarget:SetDeathXP( math.floor( hTarget:GetDeathXP() * nExpPct / 100 + 0.5 ) ) 
	hTarget:Kill( self, hCaster )
end

m_item_kbw_hand_of_midas = ModifierClass{
    bMultiple = true,
    bHidden = true,
    bPermanent = true,
}

function m_item_kbw_hand_of_midas:OnCreated()
    ReadAbilityData( self, {
       'attack_speed',
    })
end

function m_item_kbw_hand_of_midas:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function m_item_kbw_hand_of_midas:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end