m_kbw_lina_scepter = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_lina_scepter:OnCreated()
	if IsServer() then
		self:RegisterSelfEvents()
		self.nAttacks = 0
	end
end

function m_kbw_lina_scepter:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_kbw_lina_scepter:OnParentAttackLanded(t)
	if exist(t.attacker) and t.attacker:IsAlive() and exist(t.unit) and t.unit:IsAlive() then
		if t.attacker:HasModifier('modifier_lina_flame_cloak') then
			local hAbility = t.attacker:FindAbilityByName('lina_flame_cloak')
			self.nAttacks = self.nAttacks + 1
		else
			self.nAttacks = 0
		end
	end
end
-- function m_kbw_lina_scepter:OnParentDealDamage( t )
-- 	if exist( t.attacker ) and t.attacker:HasScepter() and t.attacker:IsAlive() and exist( t.unit ) and t.unit:IsAlive() then
-- 		if RandomFloat( 0, 100 ) <= 10 then
-- 			local nTime = GameRules:GetGameTime()
-- 			local nLastTime = self.tTriggers[ t.unit ] or 0
			
-- 			if nTime - nLastTime >= 1/30 then
-- 				self.tTriggers[ t.unit ] = nTime

-- 				local tAbilities = {}
-- 				for i = 0, 5 do
-- 					local hAbility = t.attacker:GetAbilityByIndex( i )
-- 					if binhas( hAbility:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET, DOTA_ABILITY_BEHAVIOR_POINT, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) then
-- 						tAbilities[ hAbility ] = 1
-- 					end
-- 				end

-- 				local hAbility = table.random( tAbilities )
-- 				if hAbility and hAbility:IsTrained() then
-- 					SpellCaster:Cast( hAbility, t.unit )
-- 				end
-- 			end
-- 		end
-- 	end
-- end