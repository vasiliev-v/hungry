function DebugPrint(...) print(...) end

function DebugPrintTable(...) PrintTableV(...) end

function PrintTableV(t, indent, done)
    -- print ( string.format ('PrintTableV type %s', type(keys)) )
    if type(t) ~= "table" then return end

    done = done or {}
    done[t] = true
    indent = indent or 0

    local l = {}
    for k, v in pairs(t) do table.insert(l, k) end

    table.sort(l)
    for k, v in ipairs(l) do
        -- Ignore FDesc
        if v ~= 'FDesc' then
            local value = t[v]

            if type(value) == "table" and not done[value] then
                done[value] = true
                print(string.rep("\t", indent) .. tostring(v) .. ":")
                PrintTableV(value, indent + 2, done)
            elseif type(value) == "userdata" and not done[value] then
                done[value] = true
                print(string.rep("\t", indent) .. tostring(v) .. ": " ..
                          tostring(value))
                PrintTableV(
                    (getmetatable(value) and getmetatable(value).__index) or
                        getmetatable(value), indent + 2, done)
            else
                if t.FDesc and t.FDesc[v] then
                    print(string.rep("\t", indent) .. tostring(t.FDesc[v]))
                else
                    print(string.rep("\t", indent) .. tostring(v) .. ": " ..
                              tostring(value))
                end
            end
        end
    end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

--[[Author: Noya
  Date: 09.08.2015.
  Hides all dem hats
]]
function HideWearables(event)
    local hero = event.caster
    local ability = event.ability

    hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = hero:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(hero.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

function ShowWearables(event)
    local hero = event.caster

    for i, v in pairs(hero.hiddenWearables) do v:RemoveEffects(EF_NODRAW) end
end

function CDOTA_Item:Use()
    local caster = self:GetOwner()
    if caster ~= nil and (caster:IsHero() or caster:HasInventory()) then
        local newCharges = self:GetCurrentCharges() - 1
        if newCharges > 0 then
            self:SetCurrentCharges(newCharges)
        else
            caster:RemoveItem(self)
        end
    end
end

function isdotaobject(obj)
    local sType = type(obj)

    if sType == 'userdata' then return true end

    if sType == 'table' and type(obj.IsNull) == 'function' then return true end

    return false
end

function isobject(obj)
    if isdotaobject(obj) then return true end

    if type(obj) == 'table' then
        if getmetatable(obj) then return true end

        if isclass(obj) then return true end

        if getclass(obj) then return true end
    end

    return false
end

function istable(obj) return type(obj) == 'table' and not isobject(obj) end

function isitable(obj)
    if istable(obj) then return table.size(obj) == #obj end

    return false
end

function isindexable(obj)
    local sType = type(obj)

    if sType == 'table' then return true end

    if sType == 'userdata' then
        local bStatus = pcall(function() local test = obj.test end)
        return bStatus
    end
end

function exist(obj)
    if isindexable(obj) then
        if type(obj.IsNull) == 'function' then return not obj:IsNull() end
    end

    if type(obj) == 'table' then
        return table.size(obj) ~= 0 or getmetatable(obj) ~= nil
    end

    return obj ~= nil
end

function super(obj) return getbase(getclass(obj)) end

local tReserverdNames = {
    hTarget = true,
    hCaster = true,
    hAbility = true,
    bReapply = true,
    bStacks = true,
    bAddToDead = true,
    bCalcDeadDuration = true,
    bIgnoreStatusResist = true,
    nAttempts = true
}

local tDebuffAmps = {modifier_item_arcane_blink_buff = 'debuff_amp'}

function GetDebuffAmp(hUnit)
    local n = 1
    for _, hMod in ipairs(hUnit:FindAllModifiers()) do
        if hMod:HasFunction(MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER) then
            local sValName = tDebuffAmps[hMod:GetName()]
            if sValName then
                local hAbility = hMod:GetAbility()
                if hAbility then
                    n = n + hAbility:GetSpecialValueFor(sValName) / 100
                end
            elseif type(hMod.GetModifierStatusResistanceCaster) == 'function' then
                n = n - hMod:GetModifierStatusResistanceCaster() / 100
            end
        end
    end
    return n
end

function AddModifier(sModifier, tData, fCallback)
    if not exist(tData.hTarget) then
        printstack('[AddModifier]: No target specified')
        return
    end

    local tModifierData = {}
    local t = {}

    for k, v in pairs(tData) do
        if tReserverdNames[k] then
            t[k] = v
        else
            tModifierData[k] = v
        end
    end

    if tModifierData.duration and exist(t.hCaster) and t.hTarget:GetTeam() ~=
        t.hCaster:GetTeam() then
        if not t.bIgnoreStatusResist then
            tModifierData.duration = tModifierData.duration *
                                         (1 - t.hTarget:GetStatusResistance())
        end
        if not t.bIgnoreDebuffAmp then
            tModifierData.duration = tModifierData.duration *
                                         GetDebuffAmp(t.hCaster)
        end
    end

    local bDuration = (tModifierData.duration and tModifierData.duration > 0)

    local hMod
    local nStartTime = GameRules:GetGameTime()

    Timers:CreateTimer(function()
        if not exist(t.hTarget) then return end

        if not t.hTarget:IsAlive() then
            if not t.bAddToDead then return end

            return 1 / 30
        end

        if t.bCalcDeadDuration and bDuration then
            tModifierData.duration = tModifierData.duration + nStartTime -
                                         GameRules:GetGameTime()

            if tModifierData.duration <= 0 then return end
        end

        if t.bReapply then t.hTarget:RemoveModifierByName(sModifier) end

        if t.bStacks then
            hMod = t.hTarget:FindModifierByName(sModifier)

            if hMod and bDuration then
                hMod:SetDuration(tModifierData.duration, true)
                hMod:ForceRefresh()
            end
        end

        if not hMod then
            hMod = t.hTarget:AddNewModifier(t.hCaster, t.hAbility, sModifier,
                                            tModifierData)
        end

        if hMod then
            if t.bStacks then
                hMod:IncrementStackCount()

                if type(hMod.OnChangeStackCount) == 'function' then
                    hMod:OnChangeStackCount()
                end

                if bDuration then
                    Timers:CreateTimer(tModifierData.duration, function()
                        if exist(hMod) then
                            if hMod:GetStackCount() < 2 then
                                hMod:Destroy()
                            else
                                hMod:DecrementStackCount()

                                if type(hMod.OnChangeStackCount) == 'function' then
                                    hMod:OnChangeStackCount()
                                end
                            end
                        end
                    end)
                end
            end

            if type(fCallback) == 'function' then fCallback(hMod) end
        else
            if not t.nAttempts or t.nAttempts < 1 then
                -- local sMsg = '[AddModifier]: Failed to create modifier "' .. sModifier .. '" '
                -- if exist( t.hTarget ) then
                -- 	sMsg = sMsg .. 'on target ' .. t.hTarget:GetName()
                -- else
                -- 	sMsg = sMsg .. 'with no target'
                -- end

                printstack(sMsg)
                -- GameRules:SendCustomMessage( sMsg, 0, 0 )
            else
                t.nAttempts = t.nAttempts - 1
                return 1 / 30
            end
        end
    end)

    return hMod
end

function ParticleManager:Create(sParticle, ...)
    local qArgs = {...}

    if isdotaobject(qArgs[1]) then
        table.insert(qArgs, 1, PATTACH_ABSORIGIN_FOLLOW)
    elseif qArgs[1] == nil then
        qArgs[1] = PATTACH_WORLDORIGIN
    end

    if qArgs[2] ~= nil and not isdotaobject(qArgs[2]) then
        table.insert(qArgs, 2, nil)
    end

    local nParticle = self:CreateParticle(sParticle, qArgs[1], qArgs[2])

    if qArgs[3] then self:Fade(nParticle, qArgs[3], qArgs[4]) end

    return nParticle
end

function ParticleManager:Fade(nParticle, nDelay, bFaded)
    if type(nDelay) == 'boolean' then
        nDelay = 0
        bFaded = nDelay
    end

    Timers:CreateTimer(nDelay or 0, function()
        self:DestroyParticle(nParticle, not bFaded)
        self:ReleaseParticleIndex(nParticle)
    end)
end

function ParticleManager:Animate(nParticle, nPoint, vStart, vTarget, nDuration,
                                 bForceEnd)
    nDuration = nDuration or 0
    local vDelta

    if nDuration > 0 then vDelta = (vTarget - vStart) / nDuration end

    local hTimer = Timers:CreateTimer(function(nTime)
        if nDuration <= 0 then
            bForceEnd = true
            return
        end

        self:SetParticleControl(nParticle, nPoint, vStart)

        vStart = vStart + vDelta * nTime
        nDuration = nDuration - nTime

        return 1 / 30
    end)

    hTimer.OnDestroy = function()
        if bForceEnd then
            self:SetParticleControl(nParticle, nPoint, vTarget)
        end
    end

    return hTimer
end

StaticParticle = StaticParticle or class {}

function StaticParticle:constructor(sName, ...)
    self.bNull = false
    self.qCall = {}
    self.tParticles = {}
    self.sName = sName

    local tArgs = args({...}, {'number', isdotaobject, 'function'})

    self.hParent = tArgs[2]
    self.nAttach = tArgs[1] or
                       (self.hParent and PATTACH_ABSORIGIN_FOLLOW or
                           PATTACH_WORLDORIGIN)
    self.fCondition = tArgs[3] or function() return true end

    for nPlayer = 0, DOTA_MAX_PLAYERS - 1 do self:InitPlayer(nPlayer) end

    self.nInitListener = CustomGameEventManager:RegisterListenerInited(
                             'sv_client_init', function(tEvent)
            self:InitPlayer(tEvent.PlayerID)
        end)
end

function StaticParticle:InitPlayer(nPlayer)
    if self:IsNull() then return end

    if PlayerResource:IsValidPlayer(nPlayer) and self.fCondition(nPlayer) then
        local nOldParticle = self.tParticles[nPlayer]
        if nOldParticle then
            ParticleManager:Fade(nOldParticle)
            self.tParticles[nPlayer] = nil
        end

        local hPlayer = PlayerResource:GetPlayer(nPlayer)
        if hPlayer then
            local nParticle = ParticleManager:CreateParticleForPlayer(
                                  self.sName, self.nAttach, self.hParent,
                                  hPlayer)
            self.tParticles[nPlayer] = nParticle

            for _, qCall in ipairs(self.qCall) do
                local sFunctionName = qCall[1]
                local qArgs = {}
                for i = 2, #qCall do
                    table.insert(qArgs, qCall[i])
                end

                ParticleManager[sFunctionName](ParticleManager, nParticle,
                                               table.unpack(qArgs))
            end
        end
    end
end

function StaticParticle:Destroy(bFaded)
    if self.bNull then return end

    self.bNull = true

    for nPlayer, nParticle in pairs(self.tParticles) do
        ParticleManager:Fade(nParticle, bFaded)
    end

    CustomGameEventManager:UnregisterListener(self.nInitListener)

    self.tParticles = nil
    self.nInitListener = nil
end

function StaticParticle:IsNull() return self.bNull end

local fCopyFunctions = function(tSource)
    for sFunctionName, fCall in pairs(tSource) do
        if not StaticParticle[sFunctionName] and type(fCall) == 'function' and
            not sFunctionName:match('Create') then
            StaticParticle[sFunctionName] = function(self, ...)
                if self.bNull then return end

                table.insert(self.qCall, {sFunctionName, ...})

                for nPlayer, nParticle in pairs(self.tParticles) do
                    fCall(ParticleManager, nParticle, ...)
                end
            end
        end
    end
end

local tSource = ParticleManager
while type(tSource) == 'table' do
    fCopyFunctions(tSource)
    tSource = (getmetatable(tSource) or {}).__index
end

Find = {}

local function fParseTeam(nTeam, hSource)
    if nTeam then return nTeam end

    if not hSource or type(hSource.GetTeam) ~= 'function' then return 0 end

    return hSource:GetTeam()
end

local function fParseVector(vSource)
    if not vSource then return Vector(0, 0, 0) end

    if type(vSource.GetOrigin) == 'function' then return vSource:GetOrigin() end

    return vSource
end

function Find:UnitsInRadius(t)
    t = t or {}
    t.nTeam = fParseTeam(t.nTeam, t.vCenter)
    t.vCenter = fParseVector(t.vCenter)
    t.nRadius = t.nRadius or 99999
    t.nFilterTeam = t.nFilterTeam or DOTA_UNIT_TARGET_TEAM_BOTH
    t.nFilterType = t.nFilterType or DOTA_UNIT_TARGET_ALL
    t.nFilterFlag = t.nFilterFlag or
                        (DOTA_UNIT_TARGET_FLAG_INVULNERABLE +
                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES +
                            DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
    t.nOrder = t.nOrder or FIND_ANY_ORDER

    t.nFilterType = binor(t.nFilterType, t.nFilterType_ or 0)
    t.nFilterFlag = binor(t.nFilterFlag, t.nFilterFlag_ or 0)

    local qUnits = FindUnitsInRadius(t.nTeam, t.vCenter, nil, t.nRadius,
                                     t.nFilterTeam, t.nFilterType,
                                     t.nFilterFlag, t.nOrder, false)

    if t.bNoCollision then
        qUnits = table.filter(qUnits, function(unit)
            return (unit:GetOrigin() - t.vCenter):Length2D() <= t.nRadius
        end)
    end

    if type(t.fCondition) == 'function' then
        qUnits = table.filter(qUnits, t.fCondition)
    end

    return qUnits
end

function Find:UnitsInLine(t)
    t = t or {}
    t.nTeam = fParseTeam(t.nTeam, t.vStart)
    t.vStart = fParseVector(t.vStart)
    t.vEnd = fParseVector(t.vEnd)
    t.nWidth = t.nWidth or 0
    t.nFilterTeam = t.nFilterTeam or DOTA_UNIT_TARGET_TEAM_BOTH
    t.nFilterType = t.nFilterType or DOTA_UNIT_TARGET_ALL
    t.nFilterFlag = t.nFilterFlag or
                        (DOTA_UNIT_TARGET_FLAG_INVULNERABLE +
                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES +
                            DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)

    if t.bStartOffset then
        t.vStart = t.vStart + (t.vEnd - t.vStart):Normalized() * t.nWidth
    end

    local qUnits = FindUnitsInLine(t.nTeam, t.vStart, t.vEnd, nil, t.nWidth,
                                   t.nFilterTeam, t.nFilterType, t.nFilterFlag)

    if type(t.fCondition) == 'function' then
        qUnits = table.filter(qUnits, t.fCondition)
    end

    return qUnits
end

function OnLearn( hAbility, fCallback )
	if hAbility:IsTrained() then
		fCallback( hAbility )
	else
		if hAbility.qLearnCallbacks then
			table.insert( hAbility.qLearnCallbacks, fCallback )
		else
			hAbility.qLearnCallbacks = { fCallback }

			Timers:CreateTimer( function()
				if not exist( hAbility ) then
					return
				end

				if hAbility:IsTrained() then
					for _, fCallback in ipairs( hAbility.qLearnCallbacks ) do
						fCallback( hAbility )
					end

					hAbility.qLearnCallbacks = nil
					return
				end

				return 0.1
			end )
		end
	end
end

function PreventAttack(unit)
	if unit:GetAttackTarget() ~= nil then
		unit:Stop()
	else
		local target = unit:GetAggroTarget()
		if target ~= nil then
			unit:MoveToNPC(target)
		end
	end
end

function PlaySound(sSound, xTarget, nTeam, nDuration)
	nDuration = nDuration or GameRules:GetGameModeEntity():GetSoundDuration(sSound, '')
	local vTarget = xTarget
	local hTarget
	if xTarget.IsBaseNPC then
		hTarget = xTarget
		vTarget = hTarget:GetOrigin()
	end

	local hMarker = CreateMarker(vTarget, nTeam, 'npc_dota_base')

	hMarker:EmitSound(sSound)

	if hTarget then
		Timers:CreateTimer(function()
			if exist(hMarker) and exist(hTarget) then
				hMarker:SetAbsOrigin(hTarget:GetOrigin())
				return 0.1
			end
		end)
	end

	if nDuration > 0 then
		Timers:CreateTimer(nDuration, function()
			if exist(hMarker) then
				hMarker:Destroy()
			end
		end)
	end

	return function()
		Timers:CreateTimer(FrameTime(), function()
			if exist(hMarker) then
				hMarker:StopSound(sSound)
				hMarker:Destroy()
			end
		end)
	end
end

function CreateMarker(vPos, nTeam, name)
	nTeam = nTeam or DOTA_TEAM_NEUTRALS
	local hMarker = CreateUnitByName(name or 'npc_dota_thinker', vPos, false, nil, nil, nTeam)
	hMarker:AddNewModifier(hMarker, nil, 'ml_marker', {})
	hMarker:SetDayTimeVisionRange(0)
	hMarker:SetNightTimeVisionRange(0)
	return hMarker
end

function round( n, p )
	if not p then
		p = 1
	end

	return math.floor( n * p + 0.5 ) / p
end


function IterateInventory( hUnit, sType, fCallback )
	local qSlots = {}

	local bActive = ({
		ANY = true,
		INVENTORY = true,
		ACTIVE = true,
	})[sType]
	local bBackPack = ({
		ANY = true,
		INVENTORY = true,
		BACKPACK = true,
	})[sType]
	local bStash = ({
		ANY = true,
		STASH = true,
	})[sType]

	if bActive then
		for nSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
			table.insert(qSlots, nSlot)
		end
		table.insert(qSlots, DOTA_ITEM_NEUTRAL_SLOT)
		table.insert(qSlots, DOTA_ITEM_TP_SCROLL)
	end

	if bBackPack then
		for nSlot = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
			table.insert(qSlots, nSlot)
		end
	end

	if bStash then
		for nSlot = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
			table.insert(qSlots, nSlot)
		end
	end

	for _, nSlot in ipairs(qSlots) do
		if fCallback(nSlot, hUnit:GetItemInSlot( nSlot )) then
			return
		end
	end
end


local GenStats = {}
function UpdateGenStat( hUnit, sKey, nValue, nPreventUpdates )
	if not hUnit:IsRealHero() then
		return
	end

    nPreventUpdates = nPreventUpdates or 1/30
    local nIndex = hUnit:entindex()
    local tUnitStats = GenStats[ nIndex ]

    if not tUnitStats then
        tUnitStats = {}
        GenStats[ nIndex ] = tUnitStats
    end

    local tValueData = tUnitStats[ sKey ]
    if not tValueData then
        tValueData = {}
        tUnitStats[ sKey ] = tValueData
    end

    if nValue ~= tValueData.nValue then
        tValueData.nValue = nValue

        local fCallback = function()
            GenTable:SetAll( 'GenStats.'.. nIndex ..'.'.. sKey, nValue, true )
        end

        local fRemove = function()
            tValueData.hPreventTimer = nil

            if tValueData.nValue == nil then
                tUnitStats[ sKey ] = nil
            end
		end

        if exist( tValueData.hPreventTimer ) then
            tValueData.hPreventTimer.fCallback = function()
                fCallback()

                fRemove()
            end
        else
            fCallback()

            tValueData.hPreventTimer = Timers:CreateTimer( nPreventUpdates, function()
                fRemove()
            end )
        end
    end
end

function string.qmatch( sSource, sPattern, fConvert )
	fConvert = fConvert or function( ... ) return ... end
	local qMatches = {}

	for sMatch in string.gmatch( sSource, sPattern ) do
		table.insert( qMatches, fConvert( sMatch ) )
	end

	return qMatches
end

function binor( n1, n2, ... )
	if not n2 then
		return n1
	end
	
	local nNewFlags = n1
	local nFlag = 1
	
	while n2 > 0 do
		if n2 % 2 == 1 and n1 % 2 == 0 then
			nNewFlags = nNewFlags + nFlag
		end
		
		nFlag = nFlag * 2
		n2 = math.floor( n2 / 2 )
		n1 = math.floor( n1 / 2 )
	end
	
	return binor( nNewFlags, ... )
end

function GetArmorResist(armor)
	return (0.06 * armor) / (1 + 0.06 * math.abs(armor))
end

local function fGetArmorResist(target)
	return GetArmorResist(target:GetPhysicalArmorValue( false ))
end

function GetDamageWithArmor(damage, attacker, target)
	if not target then
		target = attacker
		attacker = nil
	end

	return damage * (1 - fGetArmorResist(target))
end

function GetOriginalDamageWithArmor(damage, target)
	return damage / (1 - fGetArmorResist(target))
end

function CanAffect( hUnit, hTarget )
	if hUnit:GetTeam() ~= hTarget:GetTeam() then
		if hTarget:HasModifier('modifier_fountain_aura_effect_lua') then
			return false
		end
	end
	return true
end

function IsNPC( obj )
	return isdotaobject( obj ) and exist( obj ) and type( obj.IsBaseNPC ) == 'function' and obj:IsBaseNPC()
end


function isdotaobject( obj )
	local sType = type( obj )
	
	if sType == 'userdata' then
		return true
	end
	
	if sType == 'table' and type( obj.IsNull ) == 'function' then
		return true
	end
	
	return false
end

function isobject( obj )
	if isdotaobject( obj ) then
		return true
	end
	
	if type( obj ) == 'table' then
		if getmetatable( obj ) then
			return true
		end

		if isclass( obj ) then
			return true
		end
		
		if getclass( obj ) then
			return true
		end
	end
	
	return false
end

function istable( obj )
	return type( obj ) == 'table' and not isobject( obj )
end

function isitable( obj )
	if istable( obj ) then
		return table.size( obj ) == #obj
	end
	
	return false
end

function isindexable( obj )
	local sType = type( obj )

	if sType == 'table' then
		return true
	end

	if sType == 'userdata' then
		local bStatus = pcall( function()
			local test = obj.test
		end )
		return bStatus
	end
end

function exist( obj )
	if isindexable( obj ) then
		if type( obj.IsNull ) == 'function' then
			return not obj:IsNull()
		end
	end

	if type(obj) == 'table' then
		return table.size(obj) ~= 0 or getmetatable(obj) ~= nil
	end
	
	return obj ~= nil
end

function super( obj )
	return getbase( getclass( obj ) )
end

function GetAttachmentOrigin(unit, attach)
	return unit:GetAttachmentOrigin(unit:ScriptLookupAttachment(attach))
end

function toboolean( obj )
	return ( obj and obj ~= 0 and obj ~= '' ) or false
end