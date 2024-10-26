LinkLuaModifier('m_heal_reduction', 'kbw/modifiers/m_attack_heal_reduction', LUA_MODIFIER_MOTION_NONE)
require('kbw/util_spell')
require('kbw/util_c')
m_attack_heal_reduction = ModifierClass{
	bHidden = true,
}

function m_attack_heal_reduction:OnCreated(t)
	if IsServer() then
		self.debuff_duration = t.debuff_duration
		self.value = t.value
		
	end
end

function m_attack_heal_reduction:OnDestroy()
	if IsServer() then
		
	end
end

function m_attack_heal_reduction:OnParentAttackLanded(t)
	if t.target:IsBaseNPC() then
		AddModifier('m_heal_reduction', {
			hTarget = t.target,
			hCaster = t.attacker,
			duration = self.debuff_duration or 1,
			value = self.value,
		})
	end
end

m_heal_reduction = ModifierClass{}

function m_heal_reduction:IsDebuff()
	return true
end

function m_heal_reduction:GetTexture()
	return 'ancient_apparition_chilling_touch'
end

function m_heal_reduction:OnCreated(t)
	if IsServer() and t.value then
		self.hHealAmp = AddSpecialModifier(self:GetParent(), 'nHealAmp', -t.value)
	end
end

function m_heal_reduction:OnDestroy()
	if IsServer() and self.hHealAmp then
		self.hHealAmp:Destroy()
	end
end