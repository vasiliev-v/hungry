local sPath = "kbw/abilities/heroes/weaver/geminate_attack"
LinkLuaModifier( 'm_weaver_geminate_attack_kbw', sPath, 0 )

weaver_geminate_attack_kbw = class{}

function weaver_geminate_attack_kbw:GetIntrinsicModifierName()
	return 'm_weaver_geminate_attack_kbw'
end

m_weaver_geminate_attack_kbw = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_weaver_geminate_attack_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function m_weaver_geminate_attack_kbw:GetModifierPreAttack_BonusDamage()
	if self.bProc then
		return self.hAbility:GetSpecialValueFor('damage')
	end
end

function m_weaver_geminate_attack_kbw:OnRefresh()
	if IsServer() then
		ReadAbilityData( self, {
			nDelay = 'delay',
		}, function( hAbility )
			self.hAbility = hAbility
		end )
	end
end

function m_weaver_geminate_attack_kbw:OnCreated( t )
	if IsServer() then
		self:OnRefresh( t )
		self:RegisterSelfEvents()
	end
end

function m_weaver_geminate_attack_kbw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_weaver_geminate_attack_kbw:OnParentAttack( t )
	local hParent = self:GetParent()

	if self.bProc or not exist( self.hAbility ) or not self.hAbility:IsCooldownReady() or not hParent:IsAlive() then
		return
	end

	if IsNPC( t.target ) then
		local nCount = self.hAbility:GetSpecialValueFor('attack_count')
		local nRadius = self.hAbility:GetSpecialValueFor('swarm_search_radius')
		local nTeam = hParent:GetTeam()

		Timer( self.nDelay, function()
			if not exist( t.target ) then
				return
			end

			self:PerformAttack( t.target )

			if nRadius > 0 then
				local qUnits = Find:UnitsInRadius({
					vCenter = t.target,
					nRadius = nRadius,
					nTeam = nTeam,
					nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
					nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
					nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
					fCondition = function( hUnit )
						return hUnit:HasModifier('modifier_weaver_swarm_debuff') and hUnit ~= t.target
					end
				})

				for _, hUnit in ipairs( qUnits ) do
					self:PerformAttack( hUnit )
				end
			end

			nCount = nCount - 1
			if nCount > 0 then
				return self.nDelay
			end
		end )

		-- local nBaseCooldown = self.hAbility:GetCooldown( self.hAbility:GetLevel() - 1 )
		-- local nCooldownReduction = self.hAbility:GetCaster():GetCooldownReduction()
		-- local nCooldown = nBaseCooldown * nCooldownReduction
		self.hAbility:StartCooldown( self.hAbility:GetEffectiveCooldown(self.hAbility:GetLevel()-1) )
	end
end

function m_weaver_geminate_attack_kbw:PerformAttack( hTarget )
	local hParent = self:GetParent()

	self.bProc = true
	AddTag( hParent, 'bTriggeredAttack', 1 )

	hParent:PerformAttack( hTarget, true, true, true, false, true, false, false )

	self.bProc = nil
	AddTag( hParent, 'bTriggeredAttack', -1 )
end