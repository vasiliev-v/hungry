local sPath = "kbw/items/moon_shard"

item_kbw_moon_shard = class({})

function item_kbw_moon_shard:CastFilterResultTarget(hTarget)
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

	if hTarget:HasModifier('m_item_kbw_moon_shard') then
		return UF_FAIL_OTHER
	end

	if IsServer() and PlayerResource:GetSelectedHeroEntity(hTarget:GetPlayerOwnerID()) ~= hTarget then
		return UF_FAIL_OTHER
	end

	return UF_SUCCESS
end

function item_kbw_moon_shard:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()



	AddModifier('m_item_kbw_moon_shard', {
		hTarget = hTarget,
		hCaster = hCaster,
		hAbility = self,
	})

	hTarget:EmitSound('Item.MoonShard.Consume')

	hCaster:RemoveItem(self)
end

LinkLuaModifier('m_item_kbw_moon_shard', sPath, LUA_MODIFIER_MOTION_NONE)

m_item_kbw_moon_shard = ModifierClass{
	bPermanent = true,
}

function m_item_kbw_moon_shard:AllowIllusionDuplicate()
	return true
end

function m_item_kbw_moon_shard:GetTexture()
	return 'item_moon_shard'
end

function m_item_kbw_moon_shard:OnCreated()
	self.attack = KV:GetSpellValue('item_kbw_moon_shard', 'attack')
	self.attack_per_level_min = KV:GetSpellValue('item_kbw_moon_shard', 'attack_per_level_min')
	self.hParent = self:GetParent()
	self.nBaseAttackSpeed = GetUnitKeyValuesByName(self.hParent:GetUnitName()).BaseAttackSpeed or 100
end

function m_item_kbw_moon_shard:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end

function m_item_kbw_moon_shard:OnTooltip()
	return self.hParent:GetLevel() * self.attack_per_level_min
end

function m_item_kbw_moon_shard:OnTooltip2()
	return self.attack
end

function m_item_kbw_moon_shard:GetModifierAttackSpeedBonus_Constant()
	if not exist(self.hParent) or self.hParent.GetModifierAttackSpeedBonus_Constant then
		return 0
	end

	self.hParent.GetModifierAttackSpeedBonus_Constant = true
	local nAttackSpeed = self.hParent:GetIncreasedAttackSpeed() * 100 + self.nBaseAttackSpeed
	self.hParent.GetModifierAttackSpeedBonus_Constant = nil

	return math.max(self.attack, self:OnTooltip() - nAttackSpeed)
end