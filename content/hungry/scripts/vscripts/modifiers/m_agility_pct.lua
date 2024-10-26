
require('kbw/util_spell')
require('kbw/util_c')
m_agility_pct = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_agility_pct:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {'value'})
		if self.value then
			self.hAmp = AddSpecialModifier(self:GetParent(), 'nAgiAmp', self.value)
		end
	end
end

function m_agility_pct:OnDestroy()
	if IsServer() then
		if exist(self.hAmp) then
			self.hAmp:Destroy()
		end
	end
end