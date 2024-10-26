item_kbw_tome_of_knowledge = item_kbw_tome_of_knowledge or class({}) 

function item_kbw_tome_of_knowledge:OnSpellStart()
	local caster = self:GetCaster()
	if not caster:IsRealHero() or caster:IsTempestDouble() then return end
	
	local nTeam = caster:GetTeamNumber()
	local nPlayer = caster:GetPlayerID()
	local nExp = self:GetSpecialValueFor('xp_bonus') + self:GetSpecialValueFor('xp_per_min') * GameRules:GetDOTATime(false, false) / 60
	
	local nMaxExp = -1
	
	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(i) then
			local hero = PlayerResource:GetSelectedHeroEntity(i)
			if hero then
				local nHeroExp = PlayerResource:GetTotalEarnedXP(i)
				if nHeroExp > nMaxExp then
					nMaxExp = nHeroExp
				end
			end
		end
	end

	nExp = nExp + (nMaxExp - PlayerResource:GetTotalEarnedXP(nPlayer)) * self:GetSpecialValueFor('lag_percent') / 100
	nExp = math.ceil(nExp)
	
	caster:AddExperience( nExp, DOTA_ModifyXP_TomeOfKnowledge, false, true, true )
	
	EmitSoundOnClient("Item.TomeOfKnowledge", PlayerResource:GetPlayer(nPlayer))

	self:SpendCharge()
end
