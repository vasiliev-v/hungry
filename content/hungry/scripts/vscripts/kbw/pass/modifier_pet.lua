m_pet = ModifierClass{
	bHidden = true,
	bPermanent = true
}

function m_pet:CheckState()
	return {
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_FLYING] = self.Flying,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = self.Pathing
	}
end

function m_pet:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_VISUAL_Z_DELTA
	}
end

function m_pet:GetModifierModelChange()
	return self.Model or ''
end

function m_pet:OnCreated( kv )
	self.Model = kv.model
end

function m_pet:GetVisualZDelta()
	return self:GetStackCount()
end