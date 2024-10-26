LinkLuaModifier("modifier_item_skull_of_midas", "kbw/items/skull_of_midas", LUA_MODIFIER_MOTION_NONE)

item_skull_of_midas = class({
	GetIntrinsicModifierName = function() return "modifier_item_skull_of_midas" end,
})

modifier_item_skull_of_midas = class({
	IsHidden      = function() return true end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	IsPurgable    = function() return false end,
})

function modifier_item_skull_of_midas:OnCreated()
	ReadAbilityData(self, {
		'bonus_damage',
		'kill_gold',
		'kill_xp',
	})

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function modifier_item_skull_of_midas:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function modifier_item_skull_of_midas:OnParentKill( t )
    local nPlayer = t.attacker:GetPlayerOwnerID()
    local hPlayer = PlayerResource:GetPlayer( nPlayer )

    if exist( t.unit ) then
		ModifyExperienceFiltered(t.attacker, self.kill_xp, DOTA_ModifyXP_CreepKill)
        local nDisplay = GameRules:ModifyGoldFiltered( nPlayer, self.kill_gold, true, DOTA_ModifyGold_CreepKill)
        if hPlayer then
            SendOverheadEventMessage( hPlayer, OVERHEAD_ALERT_GOLD, t.unit, nDisplay, hPlayer )
        end
    end
end

function modifier_item_skull_of_midas:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_item_skull_of_midas:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end
