require 'lib/lua/base'

LinkLuaModifier( 'm_mult', 'lib/m_mult', LUA_MODIFIER_MOTION_NONE )

m_mult = class{}

function m_mult:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function m_mult:IsHidden()
    return true
end

function m_mult:OnCreated()
    if IsServer() then
        local hAbility = self:GetAbility()
        if hAbility and type( hAbility.GetMultModifiers ) == 'function' then
            self:ApplyModifiers( hAbility:GetMultModifiers() )
        end
    end
end

function m_mult:ApplyModifiers( tModifiers )
    self:OnDestroy()

    if type( tModifiers ) ~= 'table' then
        return
    end

    self.tModifiers = table.deepcopy( tModifiers )

    for sModifier, nLevel in pairs( tModifiers ) do
        self:ProvideModifier( sModifier, nLevel )
    end
end

function m_mult:ProvideModifier( sModifier, nLevel )
    local hParent = self:GetParent()
    local hCaster = self:GetCaster()
    local hAbility = self:GetAbility()
    local bApply = false
        
    if nLevel < 1 then
        bApply = true
    end

    if not bApply then
        bApply = true
        qConcurents = hParent:FindAllModifiersByName( sModifier )

        if qConcurents then
            for _, hConcurent in pairs( qConcurents ) do
                if hConcurent.nMultLevel then
                    if hConcurent.nMultLevel >= nLevel then
                        bApply = false
                    else
                        hConcurent:Destroy()
                    end
                end
            end
        end
    end

    if bApply then
        self.tProvided = self.tProvided or {}
        local hMod = hParent:AddNewModifier( hCaster, hAbility, sModifier, {duration = -1} )

        if hMod then
            hMod.nMultLevel = nLevel
            self.tProvided[ sModifier ] = hMod

			if type(hAbility.OnAddMultModifier) == 'function' then
				hAbility:OnAddMultModifier(hMod, sModifier)
			end
        else
            Timer( 1, function()
				if exist( self ) then
                	self:ProvideModifier( sModifier, nLevel )
				end
            end )
        end
    end
end

function m_mult:OnDestroy()
    if self.tProvided then
        local hParent = self:GetParent()
        local qMults = hParent:FindAllModifiersByName('m_mult')

        for sModifier, hModifier in pairs( self.tProvided ) do
            if exist( hModifier ) then
                hModifier:Destroy()

                if type( hModifier.nMultLevel ) == 'number' and hModifier.nMultLevel > 0 then
                    for _, hMult in pairs( qMults ) do
                        if hMult.tModifiers and hMult.tModifiers[ sModifier ] then
                            hMult:ProvideModifier( sModifier, hMult.tModifiers[ sModifier ] )
                        end
                    end
                end
            end
        end

        self.tProvided = nil
    end

    self.tModifiers = nil
end