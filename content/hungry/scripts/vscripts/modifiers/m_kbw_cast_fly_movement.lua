LinkLuaModifier('m_kbw_cast_fly_movement_buff', "kbw/modifiers/m_kbw_cast_fly_movement", 0)
require('kbw/util_spell')
require('kbw/util_c')
m_kbw_cast_fly_movement = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_cast_fly_movement:OnCreated(t)
	if IsServer() then
		self.duration = t.value
		
	end
end

function m_kbw_cast_fly_movement:OnDestroy()
	if IsServer() then
		
	end
end

function m_kbw_cast_fly_movement:OnParentAbilityExecuted(t)
	if exist(t.ability) and not t.ability:IsItem() then
		local hParent = self:GetParent()
		hParent:AddNewModifier(hParent, self:GetAbility(), 'm_kbw_cast_fly_movement_buff', {
			duration = self.duration,
		})
	end
end

m_kbw_cast_fly_movement_buff = ModifierClass{}

function m_kbw_cast_fly_movement_buff:GetTexture()
	return 'item_angel_wings'
end

function m_kbw_cast_fly_movement_buff:CheckState()
	return {
		[MODIFIER_STATE_FLYING] = true,
	}
end