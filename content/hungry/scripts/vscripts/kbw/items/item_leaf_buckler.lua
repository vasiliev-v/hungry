local PATH = "kbw/items/item_leaf_buckler"

item_leaf_buckler = class({})

function item_leaf_buckler:GetIntrinsicModifierName(  )
	return "m_mult"
end

function item_leaf_buckler:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_speed = 0,
	}
end

function item_leaf_buckler:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('hungry_duration')
	
	AddModifier('m_leaf_buckler_buff', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:EmitSound('KBW.Item.LeafPlate.Cast')
end

LinkLuaModifier("m_leaf_buckler_buff", PATH, LUA_MODIFIER_MOTION_NONE)

m_leaf_buckler_buff = ModifierClass{
}

function m_leaf_buckler_buff:DestroyOnExpire()
	return false
end


function m_leaf_buckler_buff:IsHidden()
	return self:GetStackCount() == 0
end

function m_leaf_buckler_buff:OnCreated(t)
	ReadAbilityData(self, {
		'hungry_damage',
		'hungry_hits',
	})
	
	if IsServer() then
		self.records = self.records or {}
	
		self:SetStackCount(self.hungry_hits)
		self:RegisterSelfEvents()
		self:StartIntervalThink(self:GetRemainingTime())
	
		local parent = self:GetParent()
		self.particle = ParticleManager:Create('particles/items/leaf_plate/buff.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
	end
end

function m_leaf_buckler_buff:OnDestroy(t)
	if IsServer() then
		self:UnregisterSelfEvents()
		ParticleManager:Fade(self.particle, true)
	end
end

function m_leaf_buckler_buff:OnRefresh(t)
	self:OnDestroy()
	self:OnCreated(t)
end

function m_leaf_buckler_buff:OnIntervalThink()
	self:SetStackCount(0)
	self:CheckDestroy()
end

function m_leaf_buckler_buff:CheckDestroy()
	if self:IsHidden() and table.size(self.records) == 0 then
		self:Destroy()
	end
end

function m_leaf_buckler_buff:DeclareFunctions(t)
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
end

function m_leaf_buckler_buff:GetModifierPreAttack_CriticalStrike(t)
	if not self:IsHidden() then		
		self.records[t.record] = true
		return self.hungry_damage
	end
end

function m_leaf_buckler_buff:OnParentAttack(t)
	if self.records[t.record] then
		self:DecrementStackCount()
	end
end

function m_leaf_buckler_buff:OnParentAttackLanded(t)
	if self.records[t.record] then
		t.target:EmitSoundParams('DOTA_Item.Daedelus.Crit', 0.9, 1.7, 0)
	end
end

function m_leaf_buckler_buff:OnParentAttackRecordDestroy(t)
	if self.records[t.record] then
		self.records[t.record] = nil
		self:CheckDestroy()
	end
end