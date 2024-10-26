LinkLuaModifier( 'm_slardar_bash',  "kbw/abilities/heroes/slardar/bash", 0 )

slardar_bash_kbw = class({})

function slardar_bash_kbw:GetIntrinsicModifierName()
	return 'm_slardar_bash'
end

m_slardar_bash = class({
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
	} end
})

function m_slardar_bash:IsHidden()
	if self:GetStackCount() == 0 then
		return true
	end
	return false
end

function m_slardar_bash:OnCreated()
	self.bash_duration = self:GetAbility():GetSpecialValueFor("duration")
	self.attack_count = self:GetAbility():GetSpecialValueFor("attack_count")

	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_slardar_bash:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_slardar_bash:OnRefresh()
	self:OnCreated()
end

function m_slardar_bash:OnParentAttackLanded(params)
	DebugPrint("OnParentAttackLanded  OnParentAttackLanded")
	local target = params.target
	if params.attacker:PassivesDisabled() == false and (target:IsHero() or target:IsCreep()) and target:GetTeam() ~= params.attacker:GetTeam() then
		if self:GetStackCount() < self.attack_count then
			self:IncrementStackCount()
		else
			local ability = self:GetAbility()
			if ability and ability:IsCooldownReady() then
				self:SetStackCount(0)
				target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self.bash_duration})
				
				ability:StartCooldown( ability:GetEffectiveCooldown(ability:GetLevel() - 1) )
				
				self:GetParent():EmitSound("Hero_Slardar.Bash")
			end
		end
	end
end

function m_slardar_bash:GetModifierProcAttack_BonusDamage_Physical( params )
	if self:GetStackCount() == self.attack_count then
		local target = params.target
		local ability = self:GetAbility()
		if not ability or not ability:IsCooldownReady() then
			return
		end

		local damage = ability:GetSpecialValueFor("bonus_damage")
		
		if target:IsCreep() or IsStatBoss(target) then
			return damage * 2
		end
	
		return damage
	end
end