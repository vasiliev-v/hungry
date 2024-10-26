LinkLuaModifier('m_item_angel_wings', "kbw/items/levels/angel_wings", 0)
LinkLuaModifier('m_item_angel_wings_buff', "kbw/items/levels/angel_wings", 0)
LinkLuaModifier('m_item_angel_wings_buff_invis', "kbw/items/levels/angel_wings", 0)

local MAX_HEIGHT = 90

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_item_angel_wings'
end

function base:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	if hTarget then
		hTarget:RemoveModifierByName('m_item_angel_wings_buff')
		hTarget:AddNewModifier(self:GetCaster(), self, 'm_item_angel_wings_buff', {
			duration = self:GetSpecialValueFor('duration'),
		})
	end
end

CreateLevels({
	'item_angel_wings',
	'item_angel_wings_2',
	'item_angel_wings_3',
}, base)

m_item_angel_wings = ModifierClass {
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_item_angel_wings:OnCreated()
	ReadAbilityData(self, {
		'atr',
		'mag_resist',
		'evasion',
	})
end

function m_item_angel_wings:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
end

function m_item_angel_wings:GetModifierBonusStats_Strength()
	return self.atr
end

function m_item_angel_wings:GetModifierBonusStats_Agility()
	return self.atr
end

function m_item_angel_wings:GetModifierBonusStats_Intellect()
	return self.atr
end

function m_item_angel_wings:GetModifierMagicalResistanceBonus()
	return self.mag_resist
end

function m_item_angel_wings:GetModifierEvasion_Constant()
	return self.evasion
end

----------------------------------------

m_item_angel_wings_buff = ModifierClass {
	bPurgable = true,
}

function m_item_angel_wings_buff:OnCreated()
	ReadAbilityData(self, {
		'active_mag_resist',
		'active_status_resist',
		'active_fade_time',
		'active_evasion',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self:RegisterSelfEvents()

		self:RefreshInvis()

		self.nParticle = ParticleManager:Create('particles/items/angel_wings/buff.vpcf', hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, hParent:GetOrigin(), false)

		hParent:EmitSoundParams('Hero_Omniknight.Repel.TI8', 1, 2, 0)

		self:StartIntervalThink(FrameTime())
	end
end

function m_item_angel_wings_buff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()

		self:SetInvisible(false)

		ParticleManager:Fade(self.nParticle, true)

		self:GetParent():StopSound('Hero_Omniknight.Repel.TI8')
	end
end

function m_item_angel_wings_buff:OnIntervalThink()
	local hParent = self:GetParent()
	local vHitloc = hParent:GetAttachmentOrigin(hParent:ScriptLookupAttachment('attach_hitloc'))
	local vForward = hParent:GetForwardVector():Normalized()
	local vFixedForward = Vector(-vForward.y, vForward.x, vForward.z)
	local vPos = hParent:GetOrigin()

	if not self:IsInvisible() and GameRules:GetGameTime() >= self.nInvisTime then
		self:SetInvisible(true)
	end

	vPos.z = vHitloc.z + MAX_HEIGHT
	vPos = vPos - vForward * 20

	ParticleManager:SetParticleControl(self.nParticle, 5, vPos)
	ParticleManager:SetParticleControlForward(self.nParticle, 5, vFixedForward)
end

function m_item_angel_wings_buff:OnParentAttack()
	self:RefreshInvis()
end

function m_item_angel_wings_buff:SetModifier(sMod, b, nDuration)
	if b then
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), sMod, {
			duration = nDuration,
		})
	else
		self:GetParent():RemoveModifierByName(sMod)
	end
end

function m_item_angel_wings_buff:IsInvisible()
	return self:GetParent():HasModifier('m_item_angel_wings_buff_invis')
end

function m_item_angel_wings_buff:SetInvisible(bInvis)
	self:SetModifier('m_item_angel_wings_buff_invis', bInvis)
end

function m_item_angel_wings_buff:RefreshInvis()
	self:SetInvisible(false)

	self.nInvisTime = GameRules:GetGameTime() + self.active_fade_time
end

function m_item_angel_wings_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		-- MODIFIER_PROPERTY_VISUAL_Z_DELTA,
	}
end

function m_item_angel_wings_buff:GetModifierMagicalResistanceBonus()
	return self.active_mag_resist
end

function m_item_angel_wings_buff:GetModifierStatusResistanceStacking()
	return self.active_status_resist
end

function m_item_angel_wings_buff:GetModifierEvasion_Constant()
	return self.active_evasion
end

-- function m_item_angel_wings_buff:GetVisualZDelta()
-- 	return math.min(MAX_HEIGHT, self:GetElapsedTime() * 100)
-- end

----------------------------------------

m_item_angel_wings_buff_invis = ModifierClass {
	bPuragle = true,
	bHidden = true,
}

function m_item_angel_wings_buff_invis:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
	}
end

function m_item_angel_wings_buff_invis:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
	}
end

function m_item_angel_wings_buff_invis:GetModifierInvisibilityLevel()
	return 1
end
