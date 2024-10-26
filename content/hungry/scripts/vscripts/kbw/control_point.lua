LinkLuaModifier('m_control_point_buff', 'kbw/modifiers/control_point/m_control_point_buff', 0)
LinkLuaModifier('m_control_point_debuff', 'kbw/modifiers/control_point/m_control_point_debuff', 0)

local vColorAlly = Vector( 0, 240, 0 )
local vColorEnemy = Vector( 255, 0, 0 )
local vColorNeutral = Vector( 200, 200, 200 )

local function fDestroyParitcles(tParticles)
	for nTeam, hParticle in pairs(tParticles) do
		hParticle:Destroy()
		tParticles[nTeam] = nil
	end
end

ControlPoint = ControlPoint or class{}

function ControlPoint:constructor( t )
	self.nMinLevel = t.nMinLevel or 1
	self.nRadius = t.nRadius or 128
	self.nCaptureTime = t.nCaptureTime or 1
	self.nDecaptureTime = t.nDecaptureTime or self.nCaptureTime
	self.nCaptureFallFactor = t.nCaptureFallFactor or 1
	self.vPos = t.vPos or Vector(0,0,0)
	self.nColorTeam = 0
	self.nCaptureTeam = 0
	self.nCaptureUnits = 0
	self.nCaptureProgress = 0
	self.bCapturePaused = false
	self.tOwnerParticles = {}
	self.tTimerParticles = {}
	self.tNextPing = {}
	self.tAllies = {}
	self.tEnemies = {}
	self.nTick = 0

	self:SetOwner(0)

	Timer( function( nDT )
		if not self:IsNull() then
			ppcall(function()
				self:Update( nDT )
			end)
			return 0.1
		end
	end )
end

function ControlPoint:Destroy()
	fDestroyParitcles(self.tTimerParticles)
	fDestroyParitcles(self.tOwnerParticles)

	self.bNull = true
end

function ControlPoint:IsNull()
	return self.bNull or false
end

function ControlPoint:SetOwner(nOwner, vColor)
	fDestroyParitcles(self.tOwnerParticles)

	for nTeam = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
		local vDisplayColor = vColor or (nOwner == 0 and vColorNeutral or ( nOwner == nTeam and vColorAlly or vColorEnemy ))

		local hParticle =  StaticParticle('particles/gameplay/control_point/owner.vpcf', function(nPlayer)
			return PlayerResource:GetTeam(nPlayer) == nTeam
		end)
		hParticle:SetParticleControl( 0, self.vPos )
		hParticle:SetParticleControl( 1, Vector( self.nRadius * 1.15, 0, 0 ) )
		hParticle:SetParticleControl( 4, vDisplayColor )
		self.tOwnerParticles[nTeam] = hParticle
	end

	if nOwner > 0 then
		StartSoundEventFromPosition( 'Outpost.Captured', self.vPos )
	else
		StartSoundEventFromPosition( 'Outpost.Captured.Notification', self.vPos)
	end

	if exist(self.hSightUnit) then
		self.hSightUnit:Kill(nil, nil)
	end

	if nOwner ~= 0 then
		local hFountain = FOUNTAINS[nOwner]
		if hFountain then
			self.hSightUnit = CreateModifierThinker(hFountain, nil, 'm_custom_truesight', {
				radius = self.nRadius,
			}, self.vPos, nOwner, false)
		end
	end

	self.nOwner = nOwner

	self:UpdateTimerParticle()
end

function ControlPoint:GetCaptureTimeRemaining()
	if self.bGrowCapture then
	else
		return 
	end
end

function ControlPoint:UpdateTimerParticle()
	fDestroyParitcles(self.tTimerParticles)

	if self.nCaptureProgress ~= 0 or self.nCaptureTeam > 0 then
		local bRise = true
		local nRiseDuration = 0

		if not self.bCapturePaused then
			if self.nCaptureTeam <= 0 then
				if self.nOwner == self.nColorTeam then
					bRise = true
					nRiseDuration = ( 1 - self.nCaptureProgress ) * self.nDecaptureTime / self.nCaptureFallFactor
				else
					bRise = false
					nRiseDuration = self.nCaptureProgress * self.nCaptureTime / self.nCaptureFallFactor
				end
			elseif self.nCaptureTeam == self.nColorTeam then
				bRise = true
				nRiseDuration = ( 1 - self.nCaptureProgress ) * self.nCaptureTime
			else
				bRise = false
				nRiseDuration = self.nCaptureProgress * self.nDecaptureTime
			end
		end

		local sParticle = bRise and 'particles/gameplay/control_point/timer_rise.vpcf' or 'particles/gameplay/control_point/timer_fall.vpcf'

		for nTeam = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
			hParticle = StaticParticle( sParticle, function( nPlayer )
				return PlayerResource:GetTeam(nPlayer) == nTeam
			end )
			self.tTimerParticles[ nTeam ] = hParticle
			hParticle:SetParticleControl( 0, self.vPos )
			hParticle:SetParticleControl( 1, Vector( self.nRadius * 0.9 - 10, 20, 0  ) )
			local vTimer = Vector( self.nCaptureProgress * 360, nRiseDuration, 0 )
			if bRise and nRiseDuration ~= 0 then
				vTimer.z = 360*(1-self.nCaptureProgress)/nRiseDuration
			end
			hParticle:SetParticleControl( 3, vTimer )
			hParticle:SetParticleControl( 4, nTeam == self.nColorTeam and vColorAlly or vColorEnemy )
		end
	end
end

function ControlPoint:Update( nDT )
	local qUnits = FindUnitsInRadius( 0, self.vPos, nil, self.nRadius,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		0, false
	)
	
	self.nTick = self.nTick + 1
	if self.nTick >= 10 then
		self.nTick = 0
	end

	local nColorTeam = self.nColorTeam
	local nCaptureTeam = 0
	local nCaptureUnits = 0
	local bCapturePaused = false
	local tAllies = {}
	local tEnemies = {}

	for _, hUnit in ipairs( qUnits ) do
		local nTeam = hUnit:GetTeam()
		local bAlly = (nTeam == self.nOwner)
		local bHero = hUnit:IsRealHero()

		if not hUnit:NotRealHero() and (bHero or not hUnit:IsOutOfGame()) then
			if ( nTeam == DOTA_TEAM_GOODGUYS or nTeam == DOTA_TEAM_BADGUYS ) then
				local bLevel = bHero and hUnit:GetLevel() >= self.nMinLevel

				if nCaptureTeam == nTeam then
					if bLevel then
						nCaptureUnits = nCaptureUnits + 1
					end
				elseif nCaptureTeam == 0 then
					nCaptureTeam = nTeam
					if bLevel then
						nCaptureUnits = 1
					end
				else
					nCaptureTeam = -1
					bCapturePaused = true
				end
			end

			if bAlly then
				if self.tAllies[hUnit] then
					self.tAllies[hUnit] = nil
				else
					GenTable:SetAll('ControlPoint.'..hUnit:entindex(), 1)
					hUnit.bControlPoint = true

					AddModifier('m_control_point_buff', {
						hTarget = hUnit,
						hCaster = hUnit,
					})
				end

				tAllies[hUnit] = true
			end
		end

		if not bAlly then
			if self.tEnemies[hUnit] then
				self.tEnemies[hUnit] = nil
			else
				AddModifier('m_control_point_debuff', {
					hTarget = hUnit,
					hCaster = hUnit,
				})
			end

			tEnemies[hUnit] = true
		end
	end

	for hUnit in pairs(self.tAllies) do
		hUnit.bControlPoint = nil
		if exist(hUnit) then
			GenTable:SetAll('ControlPoint.'..hUnit:entindex(), nil)
			hUnit:RemoveModifierByName('m_control_point_buff')
		end
	end

	for hUnit in pairs(self.tEnemies) do
		if exist(hUnit) then
			hUnit:RemoveModifierByName('m_control_point_debuff')
		end
	end

	self.tAllies = tAllies
	self.tEnemies = tEnemies

	if not bCapturePaused then
		if nCaptureUnits == 0 then
			nCaptureTeam = 0
		end

		if nCaptureTeam <= 0 then
			if nColorTeam == self.nOwner then
				if self.nCaptureProgress < 1 and self.nOwner ~= 0 then
					self.nCaptureProgress = math.min( 1, self.nCaptureProgress + nDT * self.nCaptureFallFactor / self.nDecaptureTime )
				end
			else
				if self.nCaptureProgress > 0 then
					self.nCaptureProgress = math.max( 0, self.nCaptureProgress - nDT * self.nCaptureFallFactor / self.nCaptureTime )
				end
			end
		else
			if nCaptureTeam == nColorTeam then
				local nDelta = nDT / self.nCaptureTime
				if self.nCaptureProgress < 1 then
					self.nCaptureProgress = self.nCaptureProgress + nDelta

					if self.nCaptureProgress >= 1 then
						self.nCaptureProgress = 1
						self:SetOwner( nCaptureTeam )

						if self.fCaptureCallback then
							self.fCaptureCallback()
						end
					end
				end
			else
				local nDelta = nDT / self.nDecaptureTime
				if self.nCaptureProgress == 0 then
					self:SetOwner(0)
					nColorTeam = nCaptureTeam
				else
					-- if self.nCaptureTeam ~= nCaptureTeam and self.nOwner ~= 0 then
					-- 	local nNextPing = self.tNextPing[ self.nOwner ] or 0
					-- 	local nTime = GameRules:GetGameTime()
					-- 	if nTime > nNextPing then
					-- 		self.tNextPing[ self.nOwner ] = nTime + 15

					-- 		CustomGameEventManager:Send_ServerToTeam( self.nOwner, 'cl_ping', {
					-- 			vPos = self.vPos,
					-- 			nCount = 3,
					-- 			nInterval = 0.2,
					-- 		})
					-- 	end
					-- end
					self.nCaptureProgress = math.max( 0, self.nCaptureProgress - nDelta )
				end
			end
		end
	end

	if self.nOwner ~= 0 then
		AddFOWViewer( self.nOwner, self.vPos, self.nRadius + 128, 0.2, false)
	end

	self.nCaptureUnits = nCaptureUnits
	
	if bCapturePaused ~= self.bCapturePaused or ( not bCapturePaused and (nColorTeam ~= self.nColorTeam or nCaptureTeam ~= self.nCaptureTeam) ) then
		self.nColorTeam = nColorTeam
		self.nCaptureTeam = nCaptureTeam
		self.bCapturePaused = bCapturePaused
		self:UpdateTimerParticle()
	end
end