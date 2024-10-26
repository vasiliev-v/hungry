towerM = class({})

require 'lib/modifier_self_events'

function towerM:IsPurgable()
	return false
end

function towerM:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE}
end

function towerM:OnTooltip()
	return self:GetStackCount()
end

function towerM:GetTexture()
	return "granite_golem_bash"
end

function towerM:OnCreated()
	if IsServer() then
		self:StartIntervalThink( 1 )
		self:RegisterSelfEvents()
	end
end

function towerM:OnDestroy()
	if IsServer() then
		if exist( self.timer ) then
			self.timer:Destroy()
		end
	
		self:UnregisterSelfEvents()
	end
end

function towerM:OnIntervalThink()
	if IsServer() then
		if (self:GetCaster():GetTeam() ~= 4) then
			for i = 0, PlayerResource:GetPlayerCount() - 1 do
				local seconds = GameRules:GetDOTATime( false, false )
				local gold = 4 + (seconds / 120)
				local player = PlayerResource:GetSelectedHeroEntity(i)
				if (player) then
					if player:GetTeam() == self:GetCaster():GetTeam() then
						player:ModifyGold( gold, true, 0 )
					end
				end
			end		
		end
	end
end

function towerM:OnParentTakeAttackLanded(tData)
	self.CanRegen = false
	self.timeLastDamage = GameRules:GetDOTATime( false, false )
	local timeLastDamage = GameRules:GetDOTATime( false, false )

	self.timer = Timer( 15, function()
		if (self.timeLastDamage == timeLastDamage) then
			self.CanRegen = true
		end
	end )	
end

function towerM:GetModifierHealthRegenPercentage(tData)
	if self.CanRegen then 
		return 0.8
	end
end