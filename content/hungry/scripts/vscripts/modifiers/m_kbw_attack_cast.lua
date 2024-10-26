require('kbw/util_spell')
require('kbw/util_c')
m_kbw_attack_cast = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_attack_cast:OnCreated(t)
	if IsServer() then
		self.chance = t.chance
		self.cooldown = t.cooldown
		self.ability = t.ability

		
	end
end

function m_kbw_attack_cast:OnDestroy(t)
	if IsServer() then
		
	end
end

function m_kbw_attack_cast:OnParentAttackLanded(t)
	if not exist(t.target) or not t.target:IsBaseNPC() then
		return
	end

	local ability

	if self.ability then
		ability = t.attacker:FindAbilityByName(self.ability)
	end

	if not (ability and ability:IsTrained() and SpellCaster:IsCorrectTarget(ability, t.target)) then
		return
	end

	if not self:CanProc() then
		return
	end

	SpellCaster:Cast(ability, t.target)
end

function m_kbw_attack_cast:CanProc()
	if self.cooldown and self.cooldown > 0 then
		local time = GameRules:GetGameTime()
		if not self.next_proc or time >= self.next_proc then
			self.next_proc = time + self.cooldown
			return true
		end
	end

	if self.chance and RandomFloat(0, 100) <= self.chance then
		return true
	end

	return false
end