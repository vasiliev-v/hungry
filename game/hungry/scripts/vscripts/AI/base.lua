-- require 'lib/gameplay_event_tracker/init'
require 'lib/lua/base'
require 'lib/kv'

local fAiPath = function( sName )
    return 'ai/' .. sName
end

self.tAiClasses = self.tAiClasses or {}

for sName in pairs( self.tAiClasses ) do
    self.tAiClasses[ sName ] = self:Require( fAiPath( sName ) )
end

Events:Register( 'OnNpcSpawned', function( tEvent )
    local hUnit = EntIndexToHScript( tEvent.entindex or -1 )
    if exist( hUnit ) then
        local tKV = KV.UNITS[ hUnit:GetUnitName() ]
        if type( tKV ) == 'table' and tKV.KBW_AI then
            local cAi = self.tAiClasses[ tKV.KBW_AI ]
            
            if not cAi then
                cAi = self:Require( fAiPath( tKV.KBW_AI ) )
                self.tAiClasses[ tKV.KBW_AI ] = cAi
            end

            if not cAi then
                return
            end

            hUnit.hAi = cAi( hUnit )
        end
    end
end, { sName = 'KBW_AI' } )

Events:Register( 'OnTakeDamage', function( tEvent )
    if exist( tEvent.unit ) and tEvent.unit.hAi then
        tEvent.unit.hAi:OnDamaged( tEvent.attacker, tEvent.damage, tEvent.inflictor )
        tEvent.unit.hAi:OnHurt( tEvent.attacker )
    end
end, { sName = 'KBW_AI' } )

Events:Register( 'OnAttack', function( tEvent )
    if exist( tEvent.target ) and tEvent.target.hAi then
        tEvent.target.hAi:OnAttacked( tEvent.attacker )
        tEvent.target.hAi:OnHurt( tEvent.attacker )
    end
end, { sName = 'KBW_AI' } )

Events:Register( 'OnAbilityFullyCast', function( tEvent )
    if exist( tEvent.target ) and tEvent.target.hAi then
        tEvent.target.hAi:OnCasted( tEvent.unit )
        tEvent.target.hAi:OnHurt( tEvent.unit )
    end
end, { sName = 'KBW_AI' } )

cAiBase = cAiBase or class({})

cAiBase.nExciteRadius = 0
cAiBase.nAggroRadius = 1200

function cAiBase:Init()

end

function cAiBase:OnDestroy()

end

function cAiBase:OnAttacked( hAttacker )

end

function cAiBase:OnDamaged( hAttacker, nDamage, hAbility )

end

function cAiBase:OnCasted( hAttacker, hAbility )

end

function cAiBase:OnHurt( hAttacker )

end

function cAiBase:OnExcited( hAttacker, hExciter )
    return true
end

function cAiBase:OnTargetLost()

end

function cAiBase:CanExcite( hUnit )
    return true
end

function cAiBase:GetAggroRadius()
    return self.nAggroRadius
end

function cAiBase:constructor( hUnit )
    self.bNull = false
    self.hUnit = hUnit
    self.bExcited = false

    self:Init()
end

function cAiBase:Destroy()
    self:StopAggro()
    self:OnDestroy()

    self.bNull = true
    self.hUnit.hAi = nil
    self.hUnit = nil
end

function cAiBase:IsNull()
    return self.bNull
end

function cAiBase:CheckDestroy()
    if self.bNull then
        return true
    end

    if not exist( self.hUnit ) then
        self:Destroy()
        return true
    end

    return false
end

function cAiBase:Excite( hAttacker, nRadius )
    if self:CheckDestroy() then
        return
    end

    -- if not self.bExcited then
    --     self.bExcited = self:OnExcited( hAttacker, self.hUnit ) or false
    -- end

    local nRadius = nRadius or self.nExciteRadius
    local qAllies = FindUnitsInRadius( self.hUnit:GetTeam(), self.hUnit:GetOrigin(), nil, nRadius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false )

    for _, hAlly in pairs( qAllies ) do
        if exist( hAlly.hAi ) and not hAlly.hAi.bExcited and self:CanExcite( hAlly ) then
            hAlly.hAi.bExcited = hAlly.hAi:OnExcited( hAttacker, self.hUnit ) or false
        end
    end
end

function cAiBase:Order( tOrder )
    if self:CheckDestroy() then
        return
    end
    
    if not self.hUnit:IsAlive() then
        return
    end

    local tDotaOrder = {
        UnitIndex = self.hUnit:entindex(),
    }

    if tOrder.bQueue ~= nil then
        tDotaOrder.Queue = tOrder.bQueue
    else
        tDotaOrder.Queue = tOrder.Queue
    end

    tDotaOrder.OrderType = tOrder.nOrder or tOrder.OrderType
    tDotaOrder.Position = tOrder.vPos or tOrder.Position

    if exist( tOrder.hAbility ) then
        tDotaOrder.AbilityIndex = tOrder.hAbility:entindex()
    else
        tDotaOrder.AbilityIndex = tOrder.nAbility or tOrder.AbilityIndex
    end

    if exist( tOrder.hTarget ) then
        tDotaOrder.TargetIndex = tOrder.hTarget:entindex()
    else
        tDotaOrder.TargetIndex = tOrder.nTarget or tOrder.TargetIndex
    end
        
    ExecuteOrderFromTable( tDotaOrder )
end

function cAiBase:Stop()
    if self:CheckDestroy() then
        return
    end

    self:Order({
        nOrder = DOTA_UNIT_ORDER_HOLD_POSITION,
    })
end

function cAiBase:Attack( hUnit, bQueue )
    if self:CheckDestroy() then
        return
    end

    if not exist( hUnit ) then
        self:Stop()
        return
    end

    self:Order({
        bQueue = bQueue,
        nOrder = DOTA_UNIT_ORDER_ATTACK_TARGET,
        hTarget = hUnit,
    })
end

function cAiBase:Move( vPos, bQueue )
    if self:CheckDestroy() then
        return
    end

    self:Order({
        bQueue = bQueue,
        nOrder = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        vPos = vPos,
    })
end

function cAiBase:GetAggroPriority( hUnit )
    if hUnit:IsCourier() then
        return 2
    end

    return 1
end

function cAiBase:FindAggroTarget( nRadius )
    if self:CheckDestroy() then
        return
    end

    nRadius = nRadius or self:GetAggroRadius()

    local qUnits = FindUnitsInRadius( self.hUnit:GetTeam(), self.hUnit:GetOrigin(), nil, nRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, FIND_CLOSEST, false )
    local nBestPriority
    local hTarget

    for _, hUnit in ipairs( qUnits ) do
        local nPriority = self:GetAggroPriority( hUnit )
        if nPriority and ( not nBestPriority or nPriority < nBestPriority ) then
            hTarget = hUnit
            nBestPriority = nPriority
        end
    end

    return hTarget
end

function cAiBase:StartAggro( hTarget )
    self:StopAggro()
    
    if exist( hTarget ) then
        self.hDefaultTarget = hTarget
    end
    
    self.hAggroTimer = Timers:CreateTimer( function()
        if self:CheckDestroy() then
            return
        end

        local bSwitch = false
        local nTime = GameRules:GetGameTime()

        local fCheckAttackable = function( hTarget )
            return exist( hTarget ) and hTarget:IsAlive() and hTarget:GetTeam() ~= self.hUnit:GetTeam()
            and not hTarget:IsInvulnerable() and not hTarget:IsAttackImmune()
        end

        if not fCheckAttackable( self.hAggroTarget ) then
            self.hAggroTarget = nil
            bSwitch = true
        end

        if not bSwitch then
            if not self.nLastSwitchTime or nTime >= self.nLastSwitchTime + 1 then
                bSwitch = true
            end
        end

        if bSwitch then
            local hNewTarget = self:FindAggroTarget() or self.hDefaultTarget
            self.nLastSwitchTime = nTime
            
            if hNewTarget and not fCheckAttackable( hNewTarget ) then
                hNewTarget = nil
            end

            if self.hAggroTarget ~= hNewTarget then
                self.hAggroTarget = hNewTarget
            end
        end

        if not exist( self.hAggroTarget ) then
            self:OnTargetLost()
        elseif self.hUnit:GetAttackTarget() ~= self.hAggroTarget then
            self:Attack( self.hAggroTarget )
        end

        return 0.1
    end )
end

function cAiBase:StopAggro()
    if exist( self.hAggroTimer ) then
        self.hAggroTimer:Destroy()
        self.hAggroTimer = nil
        self.hAggroTarget = nil
        self.hDefaultTarget = nil
    end
end