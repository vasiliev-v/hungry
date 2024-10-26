function GetModifiedAbilityValue( hAbility, sValue, nLevel )
    if not nLevel or nLevel < 0 then
        nLevel = hAbility:GetLevel() - 1
    end

    if IsServer() then
        if hAbility.tServerValues then
			local tValues = hAbility.tServerValues[ sValue ]
			if tValues then
				return tValues[ nLevel ]
			end
		end
		return
    end

    local sGenTableKey = 'ModifiedValues.' .. hAbility:entindex() .. '.'  .. sValue .. '.' .. nLevel
    return GenTable:Get( sGenTableKey, true )
end

if IsClient() then
    return
end

cAbilityValueModifier = class{}

local qOperationOrder = { 4, 1, 2, 3 }

cAbilityValueModifier.tOperationToOrder = {}
for nOrder, nOperation in pairs( qOperationOrder ) do
    cAbilityValueModifier.tOperationToOrder[ nOperation ] = nOrder
end

function GetAbilityValueModifiers(hAbility)
	local a = {}
	if hAbility.tValueModifiers then
		for sIndex, qModifiers in pairs(hAbility.tValueModifiers) do
			for _, hMod in ipairs(qModifiers) do
				table.insert(a, hMod)
			end
		end
	end
	return a
end

function cAbilityValueModifier:GetModifiers()
    if not self.hAbility.tValueModifiers then
        self.hAbility.tValueModifiers = {}
    end

    local qModifiers = self.hAbility.tValueModifiers[ self.sIndex ]
    if not qModifiers then
        qModifiers = {}
        self.hAbility.tValueModifiers[ self.sIndex ] = qModifiers
    end

    return qModifiers
end

function cAbilityValueModifier:constructor( hAbility, t )
    self.hAbility = hAbility
    self.nAbility = hAbility:entindex()

	t = t or {}
    self.sValue = t.sValue
	self.sIndex = ( t.bDota and 'Dota' or '' ) .. t.sValue
    self.nOperation = t.nOperation or 1
    self.nValue = t.nValue or ( self.nOperation > 1 and 1 or 0 )
	self.bClientOnly = t.bClientOnly or false
	self.bServerOnly = t.bServerOnly or false
	self.bDota = t.bDota or false

    local qModifiers = self:GetModifiers()
    local nIndex = 1
    local nOrder = cAbilityValueModifier.tOperationToOrder[ self.nOperation ]

    for nOtherModifierIndex, hOtherModifier in ipairs( qModifiers ) do
        local nOtherModifierOrder = cAbilityValueModifier.tOperationToOrder[ hOtherModifier.nOperation ]
        if nOrder <= nOtherModifierOrder then
            nIndex = nOtherModifierIndex
            break
        end
    end

    table.insert( qModifiers, nIndex, self )

    self:Update()
end

function cAbilityValueModifier:GetValue()
    return self.nValue
end

function cAbilityValueModifier:Modify( nBase )
    local nValue = self:GetValue()
    
    if self.nOperation == 1 then
        return nBase + nValue
    end
    
    if self.nOperation == 2 then
        return nBase * nValue
    end
    
    if self.nOperation == 3 then
        return nBase * ( 100 + nValue ) / 100
    end

    if self.nOperation == 4 then
        return nValue
    end

    return nBase
end

function cAbilityValueModifier:Update()
    local qModifiers = self:GetModifiers()

    if self:IsNull() then
        for i, hModifier in ipairs( qModifiers ) do
            if hModifier == self then
                table.remove( qModifiers, i )
                break
            end
        end
    end

    local tClient
	local tValues

    if exist( self.hAbility ) and #qModifiers > 0 then
        tClient = {}
		tValues = {}

        for nLevel = 1, self.hAbility:GetMaxLevel() do
            local nValue = GetAbilityAnyValue( self.hAbility, self.sValue, nLevel - 1, self.bDota )
            local nClient = nValue

            for _, hModifier in ipairs( qModifiers ) do
				if not hModifier.bServerOnly then
               		nClient = hModifier:Modify( nClient )
				end

				if not hModifier.bClientOnly then
					nValue = hModifier:Modify( nValue )
				end
            end

            tClient[ nLevel - 1 ] = nClient
			tValues[ nLevel - 1 ] = nValue
        end
    else
        self.hAbility.tValueModifiers[ self.sIndex ] = nil
    end

	if tValues then
		if not self.hAbility.tServerValues then
			self.hAbility.tServerValues = {}
		end

		self.hAbility.tServerValues[ self.sIndex ] = tValues
	
	elseif self.hAbility.tServerValues then
		self.hAbility.tServerValues[ self.sIndex ] = nil

		if table.size( self.hAbility.tServerValues ) == 0 then
			self.hAbility.tServerValues = nil
		end
	end

    GenTable:SetAll( 'ModifiedValues.' .. self.nAbility .. '.'  .. self.sIndex, tClient, true )
end

function cAbilityValueModifier:Destroy()
	if self.bNull then
		return
	end

	if self.qOnDestroy then
		for _, fCallback in ipairs( self.qOnDestroy ) do
			fCallback( self )
		end
	end

    self.bNull = true
    self:Update()
end

function cAbilityValueModifier:AddOnDestroy( fCallback )
	if not self.qOnDestroy then
		self.qOnDestroy = {}
	end

	table.insert( self.qOnDestroy, fCallback )
end

function cAbilityValueModifier:IsNull()
    return self.bNull or false
end