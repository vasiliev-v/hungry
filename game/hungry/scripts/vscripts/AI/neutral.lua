cAiNeutral = cAiNeutral or class( {}, {}, cAiBase )

cAiNeutral.nExciteRadius = 99999
cAiNeutral.nFollowTime = 5
cAiNeutral.nHomeRadius = 250

cAiNeutral.tIgnoreUnits = {
    npc_dota_observer_wards = 1,
    npc_dota_sentry_wards = 1,
    npc_dota_techies_land_mine = 1,
    npc_dota_techies_stasis_trap = 1,
    npc_dota_techies_remote_mine = 1,
}

function cAiNeutral:CanExcite( hUnit )
    return self.hUnit.spawner and self.hUnit.spawner == hUnit.spawner
end

function cAiBase:GetAggroPriority( hUnit )
    if hUnit:IsCourier() or self.tIgnoreUnits[ hUnit:GetUnitName() ] then
        return
    end

    if hUnit:IsBuilding() then
        return 2
    end

    return 1
end

function cAiNeutral:Init()
    self.tIgnoreUnits = table.copy( self.tIgnoreUnits )

    Timers:CreateTimer( 1/30, function()
        self.vSpawn = self.hUnit:GetOrigin()
    end )
end

function cAiNeutral:OnHurt( hAttacker )
    self:Excite( hAttacker )
end

function cAiNeutral:IsInHome()
    if not self.vSpawn then
        return true
    end

    return ( ( self.hUnit:GetOrigin() - self.vSpawn ):Length2D() <= self.nHomeRadius )
end

function cAiNeutral:OnExcited( hAttacker, hExciter )
    if not self:IsInHome() then
        if not self.bExcited and not self.hUnit:IsMoving() then
            self:OnTargetLost()
        end

        return false
    end

    if hExciter.hAi and hExciter.hAi.IsInHome and not hExciter.hAi.bExcited and not hExciter.hAi:IsInHome() then
        return false
    end

    if ( self.hUnit:GetOrigin() - hAttacker:GetOrigin() ):Length2D() > 2000 then
        return false
    end

    self:StartAggro( hAttacker )

    self.hFollowTimer = Timers:CreateTimer( 1, function( nTimeDelta )
        if not self:CheckDestroy() then        
            if self:IsInHome() then
                self.nTimeOutOfHome = 0
            else
                self.nTimeOutOfHome = ( self.nTimeOutOfHome or 0 ) + nTimeDelta

                if self.nTimeOutOfHome >= self.nFollowTime then
                    self:OnTargetLost()
                    return
                end
            end

            return 0.5
        end
    end )

    return true
end

function cAiNeutral:OnTargetLost()
    self.bExcited = false
    self.nTimeOutOfHome = nil

    self:StopAggro()
    self:Move( self.vSpawn )

    if exist( self.hFollowTimer ) then
        self.hFollowTimer:Destroy()
        self.hFollowTimer = nil
    end
end

return cAiNeutral