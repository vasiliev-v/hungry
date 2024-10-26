shrine_passive = class({})
LinkLuaModifier( "modifier_fountain_aura_lua","kbw/abilities/buildings/shrine/shrine_passive", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_fountain_aura_effect_lua","kbw/abilities/buildings/shrine/shrine_passive", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "m_fountain_enemy_debuff","kbw/abilities/buildings/shrine/shrine_passive", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function shrine_passive:GetIntrinsicModifierName()
	return "modifier_fountain_aura_lua"
end
--------------------------------------------------------------------------------











modifier_fountain_aura_lua = class({})



function modifier_fountain_aura_lua:IsHidden()
	return true
end

function modifier_fountain_aura_lua:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_fountain_aura_lua:OnCreated()
	if IsServer() then
		self.nRadius = 900
		self:RegisterSelfEvents()
		self:StartIntervalThink(1/30)
	end
end

function modifier_fountain_aura_lua:OnIntervalThink()
	-- local qEnemies = Find:UnitsInRadius({
	-- 	vCenter = self:GetParent(),
	-- 	nRadius = self.nRadius,
	-- 	nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	-- 	nFilterType = DOTA_UNIT_TARGET_ALL,
	-- 	nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	-- })

	-- for _, hEnemy in ipairs(qEnemies) do
	-- 	hEnemy:Purge(true, false, false, false, false)
	-- end
end

function modifier_fountain_aura_lua:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function modifier_fountain_aura_lua:OnParentAttackLanded( t )
	if exist( t.target ) and IsNPC( t.target ) and t.target:IsAlive() then
		t.target:Kill( nil, t.attacker )
	end
end

function modifier_fountain_aura_lua:CheckState()
	local state =
	{
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:IsAura()
	return true
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetModifierAura()
	return "modifier_fountain_aura_effect_lua"
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetAuraDuration()
	return 0
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

--------------------------------------------------------------------------------

function modifier_fountain_aura_lua:GetAuraRadius()
	return self.nRadius
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------




modifier_fountain_aura_effect_lua = class({})

function modifier_fountain_aura_effect_lua:IsDebuff()
    return false
end
--------------------------------------------------------------------------------

function modifier_fountain_aura_effect_lua:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function modifier_fountain_aura_effect_lua:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
	return funcs
end

function modifier_fountain_aura_effect_lua:GetTexture()
	return "rune_regen"
end


function modifier_fountain_aura_effect_lua:GetModifierHealthRegenPercentage( params )

	if self and self:GetAbility() then
	  return self:GetAbility():GetSpecialValueFor( "heal_percent" )
    else
      return 0
    end

end

function modifier_fountain_aura_effect_lua:GetModifierTotalPercentageManaRegen( params )

	if self and self:GetAbility() then
	  return self:GetAbility():GetSpecialValueFor( "mana_percent" )
	else
      return 0
    end

end

function modifier_fountain_aura_effect_lua:GetModifierIncomingDamage_Percentage(kv)
	return -672183496
end

function modifier_fountain_aura_effect_lua:OnCreated()
	if not IsServer() then return end
	self.nParticleIndex = ParticleManager:CreateParticle("particles/items_fx/bottle.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:StartIntervalThink( 1/30 )
end

function modifier_fountain_aura_effect_lua:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.nParticleIndex, false)
	ParticleManager:ReleaseParticleIndex(self.nParticleIndex)
end

function modifier_fountain_aura_effect_lua:OnIntervalThink()
	local hParent = self:GetParent()
	SuperPurge(hParent, false, true)
end

--------------------------------------------------------

-- m_fountain_enemy_debuff = ModifierClass{
-- }

-- function m_fountain_enemy_debuff:GetTexture()
-- 	return "rune_regen"
-- end

-- function m_fountain_enemy_debuff:OnCreated()
-- 	if IsServer() then
-- 		self:StartIntervalThink(1/30)
-- 	end
-- end

-- function m_fountain_enemy_debuff
-- function m_fountain_enemy_debuff:CheckState()
-- 	return {
-- 		[MODIFIER_STATE_SILENCED] = true,
-- 	}
-- end