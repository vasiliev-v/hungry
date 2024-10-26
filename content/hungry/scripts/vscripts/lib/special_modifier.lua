require 'lib/lua/base'

if IsServer() then

	SpecialModifier = SpecialModifier or class{}

	OPERATION_ADD = 1
	OPERATION_MULT = 2
	OPERATION_PCT = 3
	OPERATION_SET = 4
	OPERATION_ASYMPTOTE = 5

	SpecialModifier.qOperationOrder = {
		OPERATION_SET,
		OPERATION_ADD,
		OPERATION_MULT,
		OPERATION_PCT,
		OPERATION_ASYMPTOTE,
	}

	SpecialModifier.tClient = {
		nStatusAbsorb = true,
	}

	SpecialModifier.tOperations = {
		[OPERATION_SET] = function( nBase, nValue, nNext )
			return nNext
		end,
		[OPERATION_ADD] = function( nBase, nValue, nNext )
			return nValue + nNext
		end,
		[OPERATION_MULT] = function( nBase, nValue, nNext )
			return nValue * nNext
		end,
		[OPERATION_PCT] = function( nBase, nValue, nNext )
			return nValue + nBase * nNext / 100
		end,
		[OPERATION_ASYMPTOTE] = function( nBase, nValue, nNext )
			return nValue + nNext - nValue * nNext
		end,
	}

	local function fGetModifiers( hUnit, sModifier, bDontCreate )
		if not hUnit.tSpecialModifiers then
			if bDontCreate then
				return
			end

			hUnit.tSpecialModifiers = {}
		end

		local tModifiers = hUnit.tSpecialModifiers[ sModifier ]
		if not tModifiers then
			if bDontCreate then
				return
			end

			tModifiers = {
				qListeners = {},
			}
			hUnit.tSpecialModifiers[ sModifier ] = tModifiers
		end

		return tModifiers
	end

	local function fShrinkModifiers( hUnit, sModifier, fCallback )
		if not hUnit.tSpecialModifiers then
			return
		end
		
		local tModifiers = hUnit.tSpecialModifiers[ sModifier ]
		if not tModifiers then
			return
		end
		
		local qClear = fCallback( tModifiers )

		if type( qClear ) == 'table' then
			for _, xKey in ipairs( qClear ) do
				tModifiers[ xKey ] = nil
			end
		end

		if table.size( tModifiers ) < 1 and table.size( tModifiers.qListeners ) < 1 then
			hUnit.tSpecialModifiers = nil
		end
	end

	function SpecialModifier:constructor( hUnit, sModifier, nValue, nOperation )
		if sModifier == nil or type( nValue ) ~= 'number' or not SpecialModifier.tOperations[ nOperation ] then
			printstack('[SpecialModifier]: Wrong arguments.')
			return
		end

		self.bNull = false
		self.hUnit = hUnit
		self.sModifier = sModifier
		self.nValue = nValue
		self.nOperation = nOperation

		local tModifiers = fGetModifiers( hUnit, sModifier )
		local qOperationModifiers = tModifiers[ nOperation ]
		
		if not qOperationModifiers then
			qOperationModifiers = {}
			tModifiers[ nOperation ] = qOperationModifiers
		end

		table.insert( qOperationModifiers, self )

		CalcSpecialModifierValue( self.hUnit, self.sModifier )
	end

	function SpecialModifier:IsNull()
		return self.bNull
	end

	function SpecialModifier:GetValue()
		return self.nValue
	end

	function SpecialModifier:Destroy()
		if self.bNull then
			return
		end

		self.bNull = true
		
		fShrinkModifiers( self.hUnit, self.sModifier, function( tModifiers )
			local qOperationModifiers = tModifiers[ self.nOperation ]
			if not qOperationModifiers then
				return
			end
		
			for nIndex, tiModifier in ipairs( qOperationModifiers ) do
				if tiModifier == self then
					table.remove( qOperationModifiers, nIndex )
					break
				end
			end
		
			if #qOperationModifiers < 1 then
				return { self.nOperation }
			end
		end )

		CalcSpecialModifierValue( self.hUnit, self.sModifier )
	end

	-- function SpecialModifier:Client()
	-- 	GenTable
	-- end

	function AddSpecialModifier( hUnit, sModifier, nValue, nOperation )
		nOperation = nOperation or OPERATION_ADD
		
		local hModifier = SpecialModifier( hUnit, sModifier, nValue, nOperation )

		return hModifier
	end

	function CalcSpecialModifierValue( hUnit, sModifier )
		local fGetValue = function()
			if not hUnit.tSpecialModifiers then
				return
			end

			local tModifiers = hUnit.tSpecialModifiers[ sModifier ]
			if not tModifiers then
				return
			end

			local nValue

			for _, nOperation in ipairs( SpecialModifier.qOperationOrder ) do
				local qOperationModifiers = tModifiers[ nOperation ]

				if qOperationModifiers then
					nValue = nValue or 0
					local nBase = nValue
					local fOperation = SpecialModifier.tOperations[ nOperation ]
					
					for _, tModifier in ipairs( qOperationModifiers ) do
						if exist( tModifier ) then
							local nModifierValue = tModifier:GetValue()

							if nModifierValue then
								nValue = fOperation( nBase, nValue, nModifierValue )
							end
						end
					end
				end
			end

			return nValue
		end
		
		local nOld = hUnit[ sModifier ]
		local nValue = fGetValue()

		if nValue ~= nOld then
			hUnit[ sModifier ] = nValue

			local tModifiers = fGetModifiers( hUnit, sModifier, true )
			if tModifiers then
				for _, hListener in ipairs( tModifiers.qListeners ) do
					hListener:Call( nValue, nOld )
				end
			end

			if SpecialModifier.tClient[sModifier] then
				GenTable:SetAll('SpecialModifier.' .. hUnit:entindex() .. '.' .. sModifier, nValue, true)
			end
		end

		return nValue
	end

	SpecialModifierListener = SpecialModifierListener or class{}

	function SpecialModifierListener:constructor( hUnit, sModifier, fCallback )
		self.bNull = false
		self.sModifier = sModifier
		self.fCallback = fCallback

		local tModifiers = fGetModifiers( hUnit, sModifier )
		table.insert( tModifiers.qListeners, self )
	end

	function SpecialModifierListener:Call( nNew, nOld )
		if self.bNull then
			return
		end

		self.fCallback( nNew, nOld )
	end

	function SpecialModifierListener:IsNull()
		return self.bNull
	end

	function SpecialModifierListener:Destroy()
		if self.bNull then
			return
		end

		self.bNull = true

		fShrinkModifiers( self.hUnit, self.sModifier, function( tModifiers )
			for nIndex, hListener in ipairs( tModifiers.qListeners ) do
				if hListener == self then
					table.remove( tModifiers.qListeners, nIndex )
					break
				end
			end
		end )
	end

	function AddSpecialModifierListener( hUnit, sModifier, fCallback )
		return SpecialModifierListener( hUnit, sModifier, fCallback )
	end

else

	GenTable:Listen('SpecialModifier', function(path, value)
		local _, ent, mod = table.unpack(string.qmatch(path, '[%a%d_]+'))
		ent = tonumber(ent)
		if not ent or not mod then
			return
		end
		
		local unit = EntIndexToHScript(ent)
		if not unit then
			return
		end
		
		unit[mod] = value
	end)

end