LinkLuaModifier('m_item_kbw_tpscroll_fast', 'kbw/items/tpscroll', LUA_MODIFIER_MOTION_NONE)

m_item_kbw_tpscroll_fast = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

-----------------------------

item_kbw_tpscroll = class{}

function item_kbw_tpscroll:GetGenTableData(sField)
	local hCaster = self:GetCaster()
	if IsServer() then
		return GenTable:Get(math.max(0, hCaster:GetPlayerOwnerID()), sField..'.'..hCaster:entindex()) or 0
	else
		return GenTable:Get(sField..'.'..hCaster:entindex()) or 0
	end
end

function item_kbw_tpscroll:GetScrollLevel()
	return self:GetGenTableData('ScrollLevel')
end

-- function item_kbw_tpscroll:GetBehavior()
-- 	local nBase = self.BaseClass.GetBehavior(self)
-- 	if self:GetScrollLevel() > 0 then
-- 		nBase = bit.bor(nBase, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)
-- 	end
-- 	return nBase
-- end

-- function item_kbw_tpscroll:GetAbilityTargetType()
-- 	local nType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
-- 	if self:GetScrollLevel() > 3 then
-- 		nType = nType + DOTA_UNIT_TARGET_COURIER
-- 	end
-- 	return nType
-- end

function item_kbw_tpscroll:GetChannelTime()
	local hCaster = self:GetCaster()
	if hCaster:HasModifier('m_item_kbw_tpscroll_fast') then
		return hCaster:GetModifierStackCount('m_item_kbw_tpscroll_fast', hCaster) / 30
	end

	local nTime = self:GetGenTableData('ScrollDuration')
	if nTime and nTime > 0 then
		return nTime
	end

	return self.BaseClass.GetChannelTime(self)
end

function item_kbw_tpscroll:GetCooldown(nLevel)
	local nTime = self:GetGenTableData('ScrollCooldown')
	if nTime and nTime > 0 then
		return nTime
	end
	return self.BaseClass.GetCooldown(self, nLevel)
end

local function IsWard(unit)
	local name = unit:GetUnitName()
	if name == 'npc_dota_sentry_wards' or name == 'npc_dota_observer_wards' then
		return true
	end
	return false
end

function item_kbw_tpscroll:CastFilterResultTarget(hTarget)
	local hCaster = self:GetCaster()

	if hTarget == hCaster then
		return UF_SUCCESS
	end

	if hTarget:GetTeamNumber() ~= hCaster:GetTeamNumber() then
		return UF_FAIL_ENEMY
	end

	local level = self:GetScrollLevel()

	if level <= 0 then
		return UF_FAIL_OTHER
	end

	if hTarget:IsConsideredHero() or hTarget:IsCreep() then
		return UF_SUCCESS
	end

	if hTarget:IsCourier() then
		return level > 3 and UF_SUCCESS or UF_FAIL_COURIER
	end

	if IsWard(hTarget) then
		return level > 2 and UF_SUCCESS or UF_FAIL_OTHER
	end

	return UF_FAIL_OTHER
end

function item_kbw_tpscroll:IsNearTower(vPos)
	return #Find:UnitsInRadius({
		vCenter = vPos,
		nRadius = self:GetSpecialValueFor('maximum_distance'),
		nTeam = self:GetCaster():GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		nFilterType = DOTA_UNIT_TARGET_BUILDING,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
	}) > 0
end

function item_kbw_tpscroll:OnSpellStart()
	local hCaster = self:GetCaster()
	local nPlayer = hCaster:GetPlayerOwnerID()
	local nTeam = hCaster:GetTeam()
	local vPos = hCaster:GetOrigin()
	local hTarget = self:GetCursorTarget()
	local vTarget = self:GetCursorPosition()
	local nMaxDistance = self:GetSpecialValueFor('maximum_distance')
	local nChannelTime = self:GetChannelTime()
	self.bControlPoint = hCaster.bControlPoint

	if hTarget == hCaster then
		local hFountain = FOUNTAINS[nTeam]
		if exist(hFountain) then
			vTarget = hFountain:GetOrigin() + RandomVector(RandomFloat(100, 250))
		else
			vTarget = vPos
		end
		hTarget = nil
	end

	if not hTarget and not self.bControlPoint then
		hTarget = Find:UnitsInRadius({
			vCenter = vTarget,
			nRadius = FIND_UNITS_EVERYWHERE,
			nTeam = nTeam,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			nFilterType = DOTA_UNIT_TARGET_BUILDING,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
			nOrder = FIND_CLOSEST,
		})[1]

		local level = self:GetScrollLevel()

		local function distance(unit)
			return (vTarget - unit:GetOrigin()):Length2D()
		end

		if level > 0 and (not hTarget or distance(hTarget) > nMaxDistance) then
			local function closest(unit1, unit2)
				if not unit1 then
					return unit2
				elseif not unit2 then
					return unit1
				elseif distance(unit1) < distance(unit2) then
					return unit1
				else
					return unit2
				end
			end

			local hUnit = Find:UnitsInRadius({
				vCenter = vTarget,
				nRadius = FIND_UNITS_EVERYWHERE,
				nTeam = nTeam,
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				nFilterType = DOTA_UNIT_TARGET_ALL,
				nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
				nOrder = FIND_CLOSEST,
				fCondition = function(hUnit)
					if hUnit == hCaster then
						return false
					end
					return self:CastFilterResultTarget(hUnit) == UF_SUCCESS
				end
			})[1]

			hTarget = closest(hUnit, hTarget)

			if level > 2 then
				local drops = {}
				for i = 0, GameRules:NumDroppedItems() - 1 do
					local drop = GameRules:GetDroppedItem(i)
					if drop then
						local item = drop:GetContainedItem()
						if item:GetName() == 'item_gem_kbw' and item.nTeam == nTeam then
							table.insert(drops, drop)
						end
					end
				end

				table.sort(drops, function(drop1, drop2)
					return distance(drop1) < distance(drop2)
				end)

				hTarget = closest(hTarget, drops[1])
			end
		end

		if not hTarget then
			return
		end
	end

	if hTarget then
		if hTarget.IsBuilding and hTarget:IsBuilding() then
			local nMinDistance = self:GetSpecialValueFor('minimun_distance')

			local vStart = hTarget:GetOrigin()
			local vDelta = vTarget - vStart
			vDelta.z = 0
			local nDelta = #vDelta

			if nDelta < nMinDistance then
				if nDelta == 0 then
					vDelta = Vector(1,0,0)
				end
				vTarget = vStart + vDelta:Normalized()*nMinDistance
			elseif #vDelta > nMaxDistance then
				vTarget = vStart + vDelta:Normalized()*nMaxDistance
			end

			self.vTarget = GetGroundPosition(vTarget, nil)
		else
			self.hTarget = hTarget
			vTarget = GetGroundPosition(hTarget:GetOrigin(), nil)
		end
	else
		self.vTarget = vTarget
		self.bVisible = true
	end

	local hFastModifier = hCaster:FindModifierByName('m_item_flag_fast_tpscroll')
	if hFastModifier then
		local hFastAbility = hFastModifier:GetAbility()
		if hFastAbility then
			local vTarget = self.vTarget
			if self.hTarget then
				vTarget = self.hTarget:GetOrigin()
			end

			if (vPos - vTarget):Length2D() <= hFastAbility:GetSpecialValueFor('fast_tp_range') then
				local hMod = hCaster:AddNewModifier(hCaster, self, 'm_item_kbw_tpscroll_fast', {})
				if hMod then
					hMod:SetStackCount(math.floor(hFastAbility:GetSpecialValueFor('fast_tp_duration') * 30 + 0.5))
				end

				self:EndCooldown()
				self:StartCooldown(hFastAbility:GetSpecialValueFor('fast_tp_cooldown') * hCaster:GetCooldownReduction())
			end
		end
	end

	hCaster:StartGesture(ACT_DOTA_TELEPORT)

	EmitSoundOn('Portal.Loop_Disappear', hCaster)

	if self.hTarget then
		EmitSoundOn('Portal.Loop_Appear', self.hTarget)
	else
		self.hMarker = CreateMarker(self.vTarget, nTeam)
		EmitSoundOn('Portal.Loop_Appear', self.hMarker)
	end

	local GM = GetGameMode('GameModeKBW')
	local nTeamIndex = GM:GetPlayerTeamIndex( nPlayer )
	local tColor = GM.tPlayerColors[ nTeam ] or {}
	tColor = tColor[ nTeamIndex ] or {}
	local vColor = Vector(table.unpack(tColor)) / 255
	for i = 1, 3 do
		vColor[i] = math.sqrt(vColor[i])
	end

	self.qParticles = {}

	local nParticle = ParticleManager:Create('particles/items2_fx/teleport_start.vpcf', PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(nParticle, 0, hCaster, PATTACH_ABSORIGIN_FOLLOW, nil, vPos, false)
	ParticleManager:SetParticleControl(nParticle, 2, vColor)
	table.insert(self.qParticles, nParticle)

	local nParticle = ParticleManager:Create('particles/items2_fx/teleport_end.vpcf', PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(nParticle, 2, vColor)
	ParticleManager:SetParticleControl(nParticle, 4, Vector(1,0,0))
	ParticleManager:SetParticleControlEnt(nParticle, 3, hCaster, PATTACH_ABSORIGIN, nil, Vector(0,0,0), false)
	if self.vTarget then
		ParticleManager:SetParticleControl(nParticle, 0, self.vTarget)
		ParticleManager:SetParticleControl(nParticle, 1, self.vTarget)
		ParticleManager:SetParticleControl(nParticle, 5, self.vTarget)
	else
		ParticleManager:SetParticleControlEnt(nParticle, 0, self.hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, vTarget, false)
		ParticleManager:SetParticleControlEnt(nParticle, 1, self.hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, vTarget, false)
		if self.hTarget.GetBaseHealthBarOffset then
			ParticleManager:SetParticleControlEnt(nParticle, 5, self.hTarget, PATTACH_OVERHEAD_FOLLOW, nil, vTarget+Vector(0,0,self.hTarget:GetBaseHealthBarOffset()), false)
		else
			ParticleManager:SetParticleControlEnt(nParticle, 5, self.hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, vTarget, false)
		end
	end
	table.insert(self.qParticles, nParticle)

	MinimapEvent(nTeam, hCaster, vTarget.x, vTarget.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, nChannelTime)

	self.nSoundTime = GameRules:GetGameTime() + nChannelTime - 0.5
end

function item_kbw_tpscroll:OnChannelThink(flInterval)
	local hCaster = self:GetCaster()

	if hCaster:IsRooted() or hCaster:IsLeashed() or (not self.vTarget and not self.hTarget) or
	(self.hTarget and (not exist(self.hTarget) or not self.hTarget:IsAlive())) then
		hCaster:InterruptChannel()
		return
	end

	local vTarget = self.vTarget or self.hTarget:GetOrigin()
	if not vTarget then
		return
	end

	local nRadius = self:GetSpecialValueFor('vision_radius')
	
	AddFOWViewer(hCaster:GetTeam(), vTarget, nRadius, 0.1, false)
	if self.bVisible then
		AddFOWViewer(hCaster:GetOpposingTeamNumber(), vTarget, nRadius, 0.1, false)
	end

	if self.nSoundTime and GameRules:GetGameTime() >= self.nSoundTime then
		local nTeam = hCaster:GetTeam()
		PlaySound('Portal.Hero_Disappear', hCaster:GetOrigin(), nTeam)
		PlaySound('Portal.Hero_Appear', vTarget, nTeam)
		self.nSoundTime = nil
	end
end

function item_kbw_tpscroll:OnChannelFinish(bInterrupted)
	if not self.vTarget and not self.hTarget then
		return
	end

	local hCaster = self:GetCaster()
	local vTarget = self.vTarget or (exist(self.hTarget) and self.hTarget:GetOrigin())

	hCaster:RemoveModifierByName('m_item_kbw_tpscroll_fast')

	hCaster:RemoveGesture(ACT_DOTA_TELEPORT)

	StopSoundOn('Portal.Loop_Disappear', hCaster)

	if self.hTarget then
		if exist(self.hTarget) then
			StopSoundOn('Portal.Loop_Appear', self.hTarget)
		else
			StopGlobalSound('Portal.Loop_Appear')
		end
	end

	if exist(self.hMarker) then
		StopSoundOn('Portal.Loop_Appear', self.hMarker)
		self.hMarker:Destroy()
		self.hMarker = nil
	end

	if self.qParticles then
		for _, nParticle in ipairs(self.qParticles) do
			ParticleManager:Fade(nParticle, true)
		end

		self.qParticles = nil
	end

	if bInterrupted then
		if not vTarget then
			vTarget = Vector(0,0,0)
		end
		MinimapEvent(hCaster:GetTeam(), hCaster, vTarget.x, vTarget.y, DOTA_MINIMAP_EVENT_CANCEL_TELEPORTING, 0)
	else
		ProjectileManager:ProjectileDodge(hCaster)
		FindClearSpaceForUnit(hCaster, vTarget, true)

		hCaster:StartGesture(ACT_DOTA_TELEPORT_END)
	end

	self.vTarget = nil
	self.hTarget = nil
	self.bVisible = nil
end