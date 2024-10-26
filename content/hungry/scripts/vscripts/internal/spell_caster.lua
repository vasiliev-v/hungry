SpellCaster = SpellCaster or {}

function SpellCaster:IsCorrectTarget( hSpell, hTarget, bFilterResult )
    local hCaster = hSpell:GetCaster()
	local nBehavior = hSpell:GetBehaviorInt()
    local nFilterTeam = hSpell:GetAbilityTargetTeam()
    local nFilterType = hSpell:GetAbilityTargetType()
    local nFilterFlag = hSpell:GetAbilityTargetFlags()
    local nResult

	if binhas(nBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) or binhas(nBehavior, DOTA_ABILITY_BEHAVIOR_POINT)
	or binhas( nFilterTeam, DOTA_UNIT_TARGET_TEAM_CUSTOM ) or binhas( nFilterTeam, DOTA_UNIT_TARGET_CUSTOM ) then
        nResult = UF_SUCCESS
    else
        nResult = UnitFilter( hTarget, nFilterTeam, nFilterType, nFilterFlag, hCaster:GetTeam() )
    end

    if bFilterResult then
        return nResult
    end

    return nResult == UF_SUCCESS
end

function SpellCaster:IsActive(hSpell)
	local nBehavior = hSpell:GetBehaviorInt()
	return binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET )
		or binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET )
		or binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_POINT )
end

function SpellCaster:IsUnitTarget( hSpell )
	local nBehavior = hSpell:GetBehaviorInt()
	return binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET )
end

function SpellCaster:CanAct(hSpell)
	local hCaster = hSpell:GetCaster()
	if hCaster:IsStunned() then
		return false
	end
	if hSpell:IsItem() then
		if hCaster:IsMuted() then
			return false
		end
	else
		if hCaster:IsSilenced() then
			return false
		end
	end
	return true
end

function SpellCaster:IsChanneled(hSpell)
	local nBehavior = hSpell:GetBehaviorInt()
	return binhas( nBehavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED )
end

function SpellCaster:Cast( hSpell, xTarget, bUseResources )
    local hCaster = hSpell:GetCaster()
	local bChannel = self:IsChanneled(hSpell)
    local bNoTarget = true
    local hOldTarget = Vector( 0, 0, 0 )
    local vOldTarget

	if bChannel then
		local nLevel = hSpell:GetLevel()
		hSpell = hCaster:AddAbility(hSpell:GetName())
		if hSpell then
			hSpell:SetLevel(nLevel)
			hSpell:SetHidden(true)
		else
			return
		end
	end

    local function fSetTarget()
        bNoTarget = hCaster:GetCursorTargetingNothing()
        vOldTarget = hCaster:GetCursorPosition()
        hOldTarget = hCaster:GetCursorCastTarget()

        hCaster:SetCursorTargetingNothing( true )
        hCaster:SetCursorPosition( Vector( 0, 0, 0 ) )
        hCaster:SetCursorCastTarget( nil )

        if xTarget then
            hCaster:SetCursorTargetingNothing( false )

			if not IsVector( xTarget ) then
                if self:IsUnitTarget(hSpell) then
					hCaster:SetCursorCastTarget( xTarget )
					hCaster:SetCursorPosition( xTarget:GetOrigin() )
				else
					xTarget = xTarget:GetOrigin()
				end
            end

            if IsVector( xTarget ) then
                hCaster:SetCursorPosition( xTarget )
			end
        end
    end

    local function fResetTarget()
        hCaster:SetCursorTargetingNothing( bNoTarget )
        hCaster:SetCursorPosition( vOldTarget )
        hCaster:SetCursorCastTarget( hOldTarget )
           
        bNoTarget = true
        vOldTarget = Vector( 0, 0, 0 )
        hOldTarget = nil
    end

    fSetTarget()

	hSpell:OnSpellStart()
	if(bUseResources) then
		hSpell:UseResources(true, true, true, true)
	end

	if self:IsChanneled(hSpell) then
		local nEndTime = GameRules:GetGameTime() + hSpell:GetChannelTime()
		
		local function fFinish(bInterrupt)
			hSpell:OnChannelFinish(true)
			Timers:CreateTimer(5, function()
				if exist(hSpell) then
					hSpell:Destroy()
				end
			end)
		end

		Timers:CreateTimer(function(nTime)
			if not exist(hSpell) then
				return
			elseif not self:CanAct(hSpell) then
				fFinish(true)
			elseif GameRules:GetGameTime() >= nEndTime then
				fFinish(false)
			else
				hSpell:OnChannelThink(nTime)
				return FrameTime()
			end
		end)
	end

	fResetTarget()
end