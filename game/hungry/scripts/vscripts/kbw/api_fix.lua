local bServer = IsServer()
local BaseNpc = bServer and CDOTA_BaseNPC or C_DOTA_BaseNPC
local BaseAbility = bServer and CDOTABaseAbility or C_DOTABaseAbility
local LuaAbility = bServer and CDOTA_Ability_Lua or C_DOTA_Ability_Lua

-- function LuaAbility:GetCastRangeBonus(hTarget)
-- 	if self:IsNull() then
-- 		return 0
-- 	end
-- 	return self:GetCaster():GetCastRangeBonus()
-- end

if IsServer() then
	BaseNpc.__Kill = BaseNpc.Kill
	function BaseNpc:Kill(ability, attacker)
		ApplyDamage({
			victim = self,
			attacker = attacker or GameplayEventTracker:GetTrackerUnit(),
			ability = ability,
			damage = self:GetMaxHealth() + 1,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_HPLOSS
				+ DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
				+ DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
				+ DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT
				+ DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
				+ DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
				+ DOTA_DAMAGE_FLAG_DONT_DISPLAY_DAMAGE_IF_SOURCE_HIDDEN
				+ DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL,
		})
	end

	BaseNpc.__GetStatusResistance = BaseNpc.GetStatusResistance
	function BaseNpc:GetStatusResistance()
		local resist = self:__GetStatusResistance()
		for _, mod in ipairs(self:FindAllModifiers()) do
			if mod.GetModifierStatusResistanceStacking then
				resist = 1 - (1 - resist) * (1 - (mod:GetModifierStatusResistanceStacking() or 0)/100)
			end
		end
		return resist
	end

	CDOTA_BaseNPC_Hero.__AddExperience = CDOTA_BaseNPC_Hero.AddExperience
	function CDOTA_BaseNPC_Hero:AddExperience(n, reason, bot, total, nofilter)
		if nofilter then
			self:__AddExperience(n, reason, bot, total)
		else
			ModifyExperienceFiltered(self, n, reason)
		end
	end

	function CDOTA_BaseNPC:ModifyGoldFiltered(nGold, bRel, nReason)
		if not self.ModifyGold then
			return
		end

		local t = {
			player_id_const = self:GetPlayerOwnerID(),
			reason_const = nReason,
			reliable = bRel and 1 or 0,
			gold = nGold
		}

		Filters:Trigger('ModifyGold', t)

		self:ModifyGold(t.gold, t.reliable ~= 0, t.reason_const)

		return t.gold
	end

    local _CalculateStatBonus = CDOTA_BaseNPC_Hero.CalculateStatBonus
    function CDOTA_BaseNPC_Hero:CalculateStatBonus( bForce )
        if bForce == nil then
            bForce = true
        end
        _CalculateStatBonus( self, bForce )
    end

	local _GetStatusResistance = CDOTA_BaseNPC_Hero.GetStatusResistance
	function CDOTA_BaseNPC:GetStatusResistance()
		local nValue = _GetStatusResistance( self )
		if self:HasAbility('ability_demotion') then
			nValue = nValue + ( 1 - nValue ) * 0.6
		end
		return nValue
	end

else
	local _GetLocalPlayerTeam = GetLocalPlayerTeam
	function GetLocalPlayerTeam()
		return _GetLocalPlayerTeam(GetLocalPlayerID())
	end
end

function BaseAbility:GetBehaviorInt()
	return tonumber(tostring(self:GetBehavior()))
end

function BaseNpc:GetAttackRange()
	return self:Script_GetAttackRange()
end

function BaseNpc:IsMonkeyKingShit()
	return self:HasModifier('modifier_monkey_king_fur_army_soldier')
	or self:HasModifier('modifier_monkey_king_fur_army_soldier_hidden')
	or self:HasModifier('modifier_obliterate_soldier')
end

function BaseNpc:NotRealHero()
	return self:IsIllusion() or self:IsMonkeyKingShit() or self:HasModifier('m_antimage_fragment_clone')
end

function BaseNpc:HasShard()
    return self:HasModifier('modifier_item_aghanims_shard')
end

function BaseNpc:IsHeroBlyat()
	return self:IsRealHero() and not self:IsMonkeyKingShit()
end

function BaseNpc:IsLeashed()
	local leashed = false
	for _, mod in ipairs(self:FindAllModifiers()) do
		local state = {}
		mod:CheckStateToTable(state)
		local hasleashed = state[tostring(MODIFIER_STATE_TETHERED)]
		if hasleashed then
			leashed = true
		elseif hasleashed == false then
			return false
		end
	end
	return leashed
end