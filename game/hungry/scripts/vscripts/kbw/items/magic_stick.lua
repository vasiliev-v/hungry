local PATH = 'kbw/items/magic_stick'

item_kbw_magic_stick = class{}

function item_kbw_magic_stick:GetIntrinsicModifierName()
	return 'm_item_kbw_magic_stick'
end

LinkLuaModifier('m_item_kbw_magic_stick', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_magic_stick = ModifierClass{
	bHidden = true,
	bMultiple = true,
	bPermanent = true,
}

function m_item_kbw_magic_stick:OnCreated(t)
	self:OnRefresh(t)
	
	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_magic_stick:OnRefresh(t)
	ReadAbilityData(self, {
		'mp_restore',
		'hp_restore',
	})
end

function m_item_kbw_magic_stick:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_magic_stick:OnParentAbilityFullyCast(t)
	if t.ability:IsItem() or t.ability:GetCooldown(t.ability:GetLevel() - 1) == 0 then
		return
	end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	parent:Heal(self.hp_restore, ability)
	parent:GiveMana(self.mp_restore)
end