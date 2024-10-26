tinker_rearm_kbw = class{}

tinker_rearm_kbw.tExceptions = {
	item_potion_immune = 1,
    black_king_bar = 1,
    seer_stone = 1,
    hand_of_midas = 1,
    jungle_totem = 1,
    refresher = 1,
}

tinker_rearm_kbw.qAnimations = { 1, 2, 3, 3 }
tinker_rearm_kbw.qAnimationDurations = { 3.5, 2.0, 1.25 }

function tinker_rearm_kbw:GetManaCost(nLevel)
	return self:GetCaster():GetMaxMana() * self:GetSpecialValueFor('manacost') / 100
end

function tinker_rearm_kbw:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()

    local nLevel = self:GetLevel()
    local nAnim = self.qAnimations[ nLevel ]
    local nGesture

    if nAnim then
        nGesture = _G[ 'ACT_DOTA_TINKER_REARM' .. nAnim ]
    end

    self.nGesture = nGesture

    if nGesture then
        local nGestureDuration = self.qAnimationDurations[ nAnim ]
        local nDuration = self:GetCastPoint() + self:GetChannelTime()
        local nRate = nGestureDuration / nDuration

        hCaster:StartGestureWithPlaybackRate( nGesture, nRate )
    end

    return true
end

function tinker_rearm_kbw:OnAbilityPhaseInterrupted()
    self:StopGesture()
end

function tinker_rearm_kbw:OnSpellStart()
    local hCaster = self:GetCaster()

    local sParticle = 'particles/units/heroes/hero_tinker/tinker_rearm.vpcf'
    self.nParticle = ParticleManager:Create( sParticle, hCaster )
    ParticleManager:SetParticleControlEnt( self.nParticle, 0, hCaster, PATTACH_POINT_FOLLOW, 'attach_attack2', hCaster:GetOrigin(), true )

    hCaster:EmitSound('Hero_Tinker.Rearm')

	local nCharges = self:GetCurrentAbilityCharges()
	self:RefreshCharges()
	self:SetCurrentAbilityCharges(nCharges)

	if exist(self.hChargesTimer) then
		self.hChargesTimer:Destroy()
	end

	self.hChargesTimer = Timer(function()
		if exist(self) then
			local nCurrentCharges = self:GetCurrentAbilityCharges()
			if nCurrentCharges > nCharges then
				self:RefreshCharges()
				self.hChargesTimer = nil
			else
				nCharges = nCurrentCharges
				return 1/30
			end
		end
	end)
end

function tinker_rearm_kbw:OnChannelFinish( bInterrupted )
    if bInterrupted then
        self:StopGesture()
    else
        local hCaster = self:GetCaster()

        local fRefresh = function( hAbility )
            local sName = hAbility:GetName()

            for sMatch in pairs( self.tExceptions ) do
                if sName:match( sMatch ) then
                    return
                end
            end

            hAbility:FullRefresh()
        end

        for nIndex = 0, hCaster:GetAbilityCount() - 1 do
            local hAbility = hCaster:GetAbilityByIndex( nIndex )
            if hAbility and hAbility ~= self then
                fRefresh( hAbility )
            end
        end

        local qRefreshSlots = {
            DOTA_ITEM_SLOT_1,
            DOTA_ITEM_SLOT_2,
            DOTA_ITEM_SLOT_3,
            DOTA_ITEM_SLOT_4,
            DOTA_ITEM_SLOT_5,
            DOTA_ITEM_SLOT_6,
            DOTA_ITEM_TP_SCROLL,
            DOTA_ITEM_NEUTRAL_SLOT,
        }

        for _, nSlot in ipairs( qRefreshSlots ) do
            local hItem = hCaster:GetItemInSlot( nSlot )
            if hItem then
                fRefresh( hItem )
            end
        end

        self.nGesture = nil
    end

    self:StopParticle()
end

function tinker_rearm_kbw:StopGesture()
    if self.nGesture then
        self:GetCaster():RemoveGesture( self.nGesture )
        self.nGesture = nil
    end
end

function tinker_rearm_kbw:StopParticle()
    if self.nParticle then
        ParticleManager:Fade( self.nParticle, true )
        self.nParticle = nil
    end
end