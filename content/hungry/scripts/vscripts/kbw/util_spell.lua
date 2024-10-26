function CreateLevels( t, base )
	local tLevels = {}

    for nLevel, sItem in pairs( t ) do
        local cItem = class{}

		tLevels[ sItem ] = nLevel
        cItem.nLevel = nLevel
		cItem.tLevels = tLevels

		function cItem:IsSameItem( hItem )
			return self.tLevels[ hItem:GetAbilityName() ] and true or false
		end

        for k, v in pairs( base ) do
            cItem[ k ] = v
        end

        _G[ sItem ] = cItem
    end
end

function ModifierClass( tData, tBase )
    local cMod = class{}
    local bHidden = tData.bHidden or false
    local bPurge = tData.bPurgable or false
	local bPermanent = tData.bPermanent or false
    local bRemoveOnDeath = not tData.bIgnoreDeath and not bPermanent
    local nAttr = 0

    if tData.bMultiple then
        nAttr = nAttr + MODIFIER_ATTRIBUTE_MULTIPLE
    end

	if tData.bFountain then
		function cMod:RemoveOnDuel()
			return false
		end
	end

    if bPermanent then
        nAttr = nAttr + MODIFIER_ATTRIBUTE_PERMANENT
    end

    if tData.bIgnoreInvuln then
        nAttr = nAttr + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
    end

    function cMod:GetAttributes()
        return nAttr
    end

	function cMod:IsPermanent()
		return bPermanent
	end

    function cMod:IsHidden()
        return bHidden
    end

    function cMod:RemoveOnDeath()
        return bRemoveOnDeath
    end

    function cMod:IsPurgable()
        return bPurge
    end

    function cMod:IsPurgeException()
        return bPurge
    end

	if type(tData.bDebuff) == 'boolean' then
		local bDebuff = tData.bDebuff
		function cMod:IsDebuff()
			return bDebuff
		end
	end

	if tData.bJump then
		function cMod:Jump( t )
			local vStart = self:GetParent():GetOrigin()
			local vDelta = t.vTarget - vStart
			local nHeight = vDelta.z

			vDelta.z = 0
			self.vDir = vDelta:Normalized()
			self.nDistance = #vDelta
			self.nSpeed = self.nDistance / t.nDuration
			self.nGravity = t.nGravity or 0
			self.nVerticalSpeed = nHeight / t.nDuration + self.nGravity * t.nDuration / 2

			self.bHitGround = t.bHitGround
			self.bIgnoreDistance = t.bIgnoreDistance

			if self.nDistance < 1 then
				self.bIgnoreDistance = true
			end

			self:ApplyHorizontalMotionController()
			self:ApplyVerticalMotionController()
		end

		function cMod:UpdateHorizontalMotion( hUnit, nTime )
			if not exist( hUnit ) then
				return
			end

			local nDistance = math.min(self.nDistance, self.nSpeed * nTime)
			local vPos = hUnit:GetOrigin() + self.vDir * nDistance

			hUnit:SetAbsOrigin( vPos )

			self.nDistance = self.nDistance - nDistance
			if not self.bIgnoreDistance and self.nDistance <= 0 then
				hUnit:InterruptMotionControllers( false )
			end
		end

		function cMod:UpdateVerticalMotion( hUnit, nTime )
			local vPos = hUnit:GetOrigin()
			self.nVerticalSpeed = self.nVerticalSpeed - self.nGravity * nTime
			vPos.z = vPos.z + self.nVerticalSpeed * nTime

			hUnit:SetAbsOrigin( vPos )

			if self.bHitGround and vPos.z <= GetGroundHeight( vPos, nil ) then
				hUnit:InterruptMotionControllers( false )
			end
		end
	end

	if tBase then
		for k, v in pairs(tBase) do
			cMod[k] = v
		end
	end

    return cMod
end

function SetModifierData( hMod, tData, bTriggerGet )
	if IsServer() then
		if hMod.tModifierData then
			tData = table.overlay( hMod.tModifierData, tData )
		else
			hMod.tModifierData = table.deepcopy( tData )
		end

		if bTriggerGet then
			GetModifierData( hMod, true )
		end

		local hParent = hMod:GetParent()
		local nParent = hParent:entindex()
		local sModName = hMod:GetName()
		local sTime = tostring( math.floor( hMod:GetCreationTime() * 1000 ) )
		local sParentKey = 'ModifiersData.' .. nParent
		local sBuffNameKey = sParentKey .. '.' .. sModName
		local sModifierKey = sBuffNameKey .. '.' .. sTime

		GenTable:SetAll( sModifierKey, tData, true )

		-- destroy

		if not hParent.tModifierDataRegister then
			hParent.tModifierDataRegister = {}
		end

		local tBuffClass = hParent.tModifierDataRegister[ sModName ]
		if not tBuffClass then
			tBuffClass = {}
			hParent.tModifierDataRegister[ sModName ] = tBuffClass
		end

		tBuffClass[ sTime ] = 1

		local fDestroy = function()
			tBuffClass[ sTime ] = nil
			if table.size( tBuffClass ) == 0 then
				hParent.tModifierDataRegister[ sModName ] = nil
				if table.size( hParent.tModifierDataRegister ) == 0 then
					hParent.tModifierDataRegister = nil
					GenTable:SetAll( sParentKey, nil, true )
				else
					GenTable:SetAll( sBuffNameKey, nil, true )
				end
			else
				GenTable:SetAll( sModifierKey, nil, true )
			end
		end

		if hMod.OnDestroy then
			local fOldDestroy = hMod.OnDestroy
			function hMod:OnDestroy()
				fOldDestroy( self )
				fDestroy()
			end
		else
			hMod.OnDestroy = fDestroy
		end
	end
end

function GetModifierData( hMod, fCallback )
	local fGet = function()
		if IsServer() then
			return hMod.tModifierData
		end
		local sKey = 'ModifiersData.' .. hMod:GetParent():entindex() .. '.' .. hMod:GetName() .. '.' .. math.floor( hMod:GetCreationTime() * 1000 )
		return GenTable:Get( sKey, false, 1 )
	end

	if fCallback then
		if hMod.bDataRequest then
			pcall( error, 'GetModifierData called twice' )
			return
		end
		hMod.bDataRequest = true

		local fOldThink = hMod.OnIntervalThink

		function hMod:OnIntervalThink()
			local tData = fGet()

			if tData then
				self.OnIntervalThink = fOldThink
				self:StartIntervalThink( -1 )
				hMod.bDataRequest = nil

				if type( Callback ) == 'function' then
					fCallback( tData )
				elseif self.OnGetModifierData then
					self:OnGetModifierData( tData )
				end
			end
		end

		hMod:StartIntervalThink( 1/30 )
		hMod:OnIntervalThink()
	else
		return fGet()
	end
end

-- local CUSTOM_PROPERTY_ADD = 1
-- local custom_property = {
-- 	SpellCleave = CUSTOM_PROPERTY_ADD,
-- }

-- function GetCustomProperty(unit, property, data)
-- 	if IsServer() then
-- 		local typ = custom_property[property] or CUSTOM_PROPERTY_ADD
-- 		local summ = 0
		
-- 		for _, mod in ipairs(unit:FindAllModifiers()) do
-- 			if type(mod.CustomProperties) == 'table' then
-- 				local func = mod.CustomProperties[property]
-- 				if type(func) == 'function' then
-- 					local value = func(data)

-- 					if typ == CUSTOM_PROPERTY_ADD then
-- 						summ = summ + value
-- 					end
-- 				end
-- 			end
-- 		end

-- 		return summ
-- 	end
-- end

function ReadAbilityData( hMod, tData, fCallback )
    local fRead = function()
        local hAbility = hMod:GetAbility()
        if hAbility then
            for sFieldName, sValueName in pairs( tData ) do
				if type(sValueName) == 'string' then
					local nValue = hAbility:GetSpecialValueFor( sValueName )
					if type( sFieldName ) ~= 'number' then
						sValueName = sFieldName
					end
					local nOld = hMod[sValueName] or nValue
					if tData.maximal then
						nValue = math.max(nValue, nOld)
					end
					hMod[sValueName] = nValue
				end
            end
            return hAbility
        end
    end

    local hAbility = fRead()

    if hAbility then
        if fCallback then
            fCallback( hAbility )
        end

        return
    end

    local fOldThink = hMod.OnIntervalThink
    function hMod:OnIntervalThink()
        local hAbility = fRead()

        if hAbility then
            self.OnIntervalThink = fOldThink
            self:StartIntervalThink( -1 )

            if fCallback then
                fCallback( hAbility )
            end
        end
    end
    hMod:StartIntervalThink( 0.1 )
end

function CreateAura( t )
	t = t or {}

	local hAura = {
		tModifiers = {},
		bActive = true,
		nLevel = t.nLevel or 0,
		hSource = t.hSource,
		hUnit = t.hUnit,
		hAbility = t.hAbility,
		hCenter = t.hCenter,
		vCenter = t.vCenter,
		aLine = t.aLine,
		bLineDiscrete = t.bLineDiscrete,
		sModifier = t.sModifier,
		nTeam = t.nTeam,
		nRadius = t.nRadius or 0,
		bDead = t.bDead,
		bNoStack = t.bNoStack,
		nFilterTeam = t.nFilterTeam or DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		nFilterType = t.nFilterType or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		nFilterFlag = t.nFilterFlag or 0,
		fCondition = t.fCondition,
	}

	function hAura:Check()
		if self:IsNull() then
			return
		end

		if self.hSource and not exist( self.hSource )
		or self.hAbility and not exist( self.hAbility ) then
			self:Destroy()
			return
		end

		local tNewModifiers = {}
		local hParent = self.hUnit
		local vCenter = self.vCenter
		local hAbility = self.hAbility
		local nTeam = self.nTeam

		if exist( self.hCenter ) then
			vCenter = self.hCenter:GetOrigin()
		end

		if self.hSource then
			if not hParent then
				hParent = self.hSource:GetParent()
			end

			if not hAbility then
				hAbility = self.hSource:GetAbility()
			end
		end

		if not hParent then
			if hAbility then
				hParent = hAbility:GetCaster()
			else
				pcall( error, 'Failed to find aura parent.')
				return
			end
		end

		if not vCenter then
			vCenter = hParent:GetOrigin()
		end

		if not nTeam then
			nTeam = hParent:GetTeam()
		end

		self._hParent = hParent
		self._hAbility = hAbility

		if self.bActive and self.sModifier and self.sModifier ~= ''
		and ( self.bDead or hParent:IsAlive() ) then
			local qUnits = {}

			if self.aLine then
				local prev = self.aLine[1]
				local added = {}
				for _, point in ipairs(self.aLine) do
					local units =
						self.bLineDiscrete
						and Find:UnitsInRadius({
							vCenter = point.pos,
							nRadius = self.nRadius,
							nTeam = nTeam,
							nFilterTeam = self.nFilterTeam,
							nFilterType = self.nFilterType,
							nFilterFlag = self.nFilterFlag,
							fCondition = self.fCondition,
						})
						or Find:UnitsInLine({
							vStart = prev.pos,
							vEnd = point.pos,
							nWidth = self.nRadius,
							nTeam = nTeam,
							nFilterTeam = self.nFilterTeam,
							nFilterType = self.nFilterType,
							nFilterFlag = self.nFilterFlag,
							fCondition = self.fCondition,
						})

					for _, unit in ipairs(units) do
						if not added[unit] then
							added[unit] = true
							table.insert(qUnits, unit)
						end
					end
				end
			else
				qUnits = Find:UnitsInRadius({
					vCenter = vCenter,
					nRadius = self.nRadius,
					nTeam = nTeam,
					nFilterTeam = self.nFilterTeam,
					nFilterType = self.nFilterType,
					nFilterFlag = self.nFilterFlag,
					fCondition = self.fCondition,
				})
			end

			for _, hUnit in ipairs( qUnits ) do
				tNewModifiers[ hUnit ] = self:AddEffect(hUnit)
			end
		end

		for hUnit, hModifier in pairs( self.tModifiers ) do
			if not tNewModifiers[ hUnit ] and exist( hModifier ) then
				self:RemoveEffect(hModifier)
			end
		end

		self.tModifiers = tNewModifiers
	end

	function hAura:IsNull()
		return self.bNull or false
	end

	function hAura:Destroy()
		if self.bNull then
			return
		end

		for hUnit, hModifier in pairs( self.tModifiers ) do
			self:RemoveEffect(hModifier)
		end

		if exist( self.hTimer ) then
			self.hTimer:Destroy()
			self.hTimer = nil
		end

		self.bNull = true
	end

	function hAura:AddLinePoint(pos)
		if not self.aLine then
			self.aLine = {}
		end
		local point = {
			pos = pos,
		}
		table.insert(self.aLine, point)
		return point
	end

	function hAura:RemoveLinePoint(i)
		if not self.aLine then
			return
		end
		if type(i) ~= 'number' then
			i = table.key(self.aLine, i)
			if not i then
				return
			end
		end
		table.remove(self.aLine, i)
		if #self.aLine == 0 then
			self:Destroy()
		end
	end

	function hAura:AddEffect(hUnit)
		local hModifier = self.tModifiers[ hUnit ]
		local bReapply = false

		if not exist(hModifier) then
			hModifier = nil

			if self.bNoStack then
				hModifier = self:GetModifier(hUnit)

				if hModifier then
					if hModifier.tAuraProviders then
						local nMaxLevel = hModifier.hAuraMainProvider.nLevel
						if self.nLevel > nMaxLevel then
							bReapply = true
						end
					else
						bReapply = true
					end
				end
			end

			if bReapply then
				if exist(hModifier) then
					hModifier:Destroy()
				end
				hModifier = nil
			end

			if not hModifier then
				hModifier = hUnit:AddNewModifier( self:GetParent(), self:GetAbility(), self.sModifier, {} )
			end

			if hModifier then
				if not hModifier.tAuraProviders then
					hModifier.tAuraProviders = {}
					hModifier.hAuraMainProvider = self
				end

				hModifier.tAuraProviders[self] = true
			end
		end

		return hModifier
	end

	function hAura:RemoveEffect(hModifier)
		if not exist(hModifier) then
			return
		end

		hModifier.tAuraProviders[self] = nil

		if hModifier.hAuraMainProvider == self then
			hModifier:Destroy()
		end
	end

	function hAura:GetModifier(hUnit)
		for _, hModifier in ipairs(hUnit:FindAllModifiersByName(self.sModifier)) do
			if hModifier:IsDebuff() == (hUnit:GetTeam() ~= self:GetParent():GetTeam()) then
				return hModifier
			end
		end
	end

	function hAura:GetAbility()
		return self._hAbility
	end

	function hAura:GetParent()
		return self._hParent
	end

	hAura.hTimer = Timer( function()
		hAura:Check()
		return 0.1
	end )

	return hAura
end

function UnderlayAbilityValues( hAbility, tTarget, tValues )
    for sName, sValueName in pairs( tValues ) do
        if not tTarget[ sName ] then
            tTarget[ sName ] = hAbility:GetSpecialValueFor( sValueName )
        end
    end
end

function GetAbilityBaseValue( hAbility, sValue, nLevel, bNoDota )
	if not bNoDota then
		local nDotaValue = GetModifiedAbilityValue( hAbility, 'Dota' .. sValue, nLevel - 1 )
		if nDotaValue then
			return nDotaValue
		end
	end

    local sAbility = hAbility:GetName()
    local tAbility = KV.SPELLS[ sAbility ]

    if not tAbility then
        printstack( '[GetAbilityBaseValue]: not found ability ' .. sAbility )
        return 0
    end

    local xValue = tAbility[ sValue ]
    if not xValue then
        return 0
    end

	local nValue = 0

    if type( xValue ) == 'number' then
        return xValue
	elseif type( xValue ) == 'string' then
        local qValues = string.qmatch( xValue, '[%d%.-]+', tonumber )

        if nLevel < 1 then
            nLevel = 1
        end

        if nLevel > #qValues then
            nLevel = #qValues
        end

        return qValues[ nLevel ]
	end

	return 0
end

local tBaseValues = {
	AbilityCooldown = true,
	AbilityCastRange = true,
}

function GetAbilityAnyValue( hAbility, sValue, nLevel, bNoDota )
	nLevel = nLevel or hAbility:GetLevel()

	if tBaseValues[ sValue ] then
		return GetAbilityBaseValue( hAbility, sValue, nLevel + 1, bNoDota )
	end

	return hAbility:GetLevelSpecialValueFor( sValue, nLevel )
end

function GetCastDirection( t )
	local vStart = t.hCaster:GetOrigin()
	local vDir = t.vTarget - vStart

	vDir.z = 0
	local nDistance = #vDir

	if nDistance < 1 then
		vDir = t.hCaster:GetForwardVector()
		vDir.z = 0
	end

	if t.bAllowExtention then
		nRange = math.max( t.nRange, nDistance )
	end

	vDir = vDir:Normalized()
	local vEnd  = vStart + vDir * t.nRange

	if t.nMinHeight then
		vEnd.z = math.max( vEnd.z, vStart.z + t.nMinHeight )
	end

	return vStart, vEnd
end

-- hSource
-- hTarget
-- nCount
-- nRadius
-- nFilterTeam
-- nFilterType
-- nFilterFlag
-- nOrder
-- fCallback
-- fPriority
-- bAffectSource
-- tParticleData: ParticleData
	-- sParticle
	-- nDuration
	-- nPoint1
	-- nAttach1
	-- ...
-- tStartParticleData: ParticleData
function DoChain(t)
	local vPos = t.hTarget:GetOrigin()
	local bFirst = not t.hLast
	local hLast = t.hLast or t.hSource
	local nCount = t.nCount

	local tParticleData = table.overlay(t.tParticleData or {}, t.tStartParticleData or {})

	if tParticleData.sParticle then
		local tp = tParticleData
		local nParticle = ParticleManager:Create(tp.sParticle, PATTACH_CUSTOMORIGIN, nil, tp.nDuration or 5)
		ParticleManager:SetParticleControlEnt(nParticle, tp.nPoint1 or 0, hLast, PATTACH_POINT_FOLLOW, tp.nAttach1 or 'attach_hitloc', hLast:GetOrigin(), false)
		ParticleManager:SetParticleControlEnt(nParticle, tp.nPoint2 or 1, t.hTarget, PATTACH_POINT_FOLLOW, tp.nAttach2 or 'attach_hitloc', vPos, false)
	end

	if t.fCallback then
		if t.bAffectSource then
			t.fCallback(t.hSource)
		end

		if t.hTarget == t.hSource and t.bAffectSource then
			nCount = nCount + 1
		else
			t.fCallback(t.hTarget)
		end
	end

	if nCount <= 1 then
		return
	end

	local tIgnore = t.tIgnore or {
		[t.hSource] = true,
	}
	tIgnore[t.hTarget] = true

	local qUnits = Find:UnitsInRadius({
		nTeam = t.hSource:GetTeam(),
		vCenter = vPos,
		nRadius = t.nRadius,
		nFilterTeam = t.nFilterTeam,
		nFilterType = t.nFilterType,
		nFilterFlag = t.nFilterFlag,
		nOrder = t.nOrder,
	})

	local hNext
	for _, hUnit in ipairs(qUnits) do
		if not tIgnore[hUnit] then
			if hNext and t.fPriority then
				hNext = t.fPriority(hNext, hUnit)
			else
				hNext = hUnit
			end
		end
	end

	if hNext then
		DoChain({
			hSource = t.hSource,
			hLast = t.hTarget,
			hTarget = hNext,
			nCount = nCount - 1,
			nRadius = t.nRadius,
			nFilterTeam = t.nFilterTeam,
			nFilterType = t.nFilterType,
			nFilterFlag = t.nFilterFlag,
			nOrder = t.nOrder,
			fCallback = t.fCallback,
			fPriority = t.fPriority,
			tParticleData = t.tParticleData,
			tStartParticleData = t.tParticleData,
			tIgnore = tIgnore,
		})
	end
end