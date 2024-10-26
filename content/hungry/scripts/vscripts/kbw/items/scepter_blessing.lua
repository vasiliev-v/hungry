require 'lib/modifier'

LinkLuaModifier( 'm_item_kbw_scepter_blessing_stats', "kbw/items/scepter_blessing", 0 )
LinkLuaModifier( 'm_item_kbw_scepter_blessing', "kbw/items/scepter_blessing", 0 )

item_kbw_scepter_blessing = class{}

function item_kbw_scepter_blessing:GetBehavior()
	if self:GetCaster():HasModifier('modifier_arc_warden_tempest_double') then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end
	return self.BaseClass.GetBehavior(self)
end

function item_kbw_scepter_blessing:CastFilterResultTarget(hTarget)
	local nFilter = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
		self:GetCaster():GetTeamNumber()
	)

	if nFilter ~= UF_SUCCESS then
		return nFilter
	end

	if hTarget:HasModifier('modifier_item_ultimate_scepter_consumed') then
		return UF_FAIL_OTHER
	end

	if IsServer() and PlayerResource:GetSelectedHeroEntity(hTarget:GetPlayerOwnerID()) ~= hTarget then
		return UF_FAIL_OTHER
	end

	return UF_SUCCESS
end

function item_kbw_scepter_blessing:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	AddModifier('modifier_item_ultimate_scepter_consumed', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
	})



	hTarget:EmitSound('Item.MoonShard.Consume')

	hCaster:RemoveItem(self)
end

function item_kbw_scepter_blessing:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_kbw_scepter_blessing:GetMultModifiers()
	return {
		m_item_kbw_scepter_blessing_stats = 0,
		modifier_item_ultimate_scepter = 1,
	}
end

m_item_kbw_scepter_blessing_stats = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_kbw_scepter_blessing_stats:OnCreated()
	ReadAbilityData(self, {
		'all',
	})
end

function m_item_kbw_scepter_blessing_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		-- MODIFIER_PROPERTY_IS_SCEPTER,
	}
end

function m_item_kbw_scepter_blessing_stats:GetModifierBonusStats_Strength()
	return self.all
end
function m_item_kbw_scepter_blessing_stats:GetModifierBonusStats_Agility()
	return self.all
end
function m_item_kbw_scepter_blessing_stats:GetModifierBonusStats_Intellect()
	return self.all
end
-- function m_item_kbw_scepter_blessing_stats:GetModifierScepter()
--     return 1
-- end

m_item_kbw_scepter_blessing = ModifierClass{
    bPermanent = true,
    bHidden = true,
}

function m_item_kbw_scepter_blessing:GetTexture()
	return 'item_ultimate_scepter'
end

function m_item_kbw_scepter_blessing:AllowIllusionDuplicate()
	return true
end

function m_item_kbw_scepter_blessing:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_IS_SCEPTER,
    }
end

function m_item_kbw_scepter_blessing:GetModifierScepter()
    return 1
end