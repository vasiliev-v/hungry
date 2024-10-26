require('kbw/util_spell')
require('kbw/util_c')
m_kbw_multicast = ModifierClass{
	bHidden = true,
}

function m_kbw_multicast:OnCreated()
	if IsServer() then
		self.tAbilities = {}

		
	end
end

function m_kbw_multicast:OnDestroy()
	if IsServer() then
		
	end
end

function m_kbw_multicast:AddMulticast( sAbility, tData )
	local qMulticasts = self.tAbilities[ sAbility ]

	if not qMulticasts then
		qMulticasts = {}
		self.tAbilities[ sAbility ] = qMulticasts
	end

	table.insert( qMulticasts, table.copy( tData ) )
end

function m_kbw_multicast:OnParentAbilityFullyCast( t )
	local qMulticasts = self.tAbilities[ t.ability:GetName() ]

	if qMulticasts then
		local hCaster = self:GetParent()
		local vCaster = hCaster:GetOrigin()

		for _, tData in ipairs( qMulticasts ) do
			local nCount = tData.nCount

			if SpellCaster:IsUnitTarget( t.ability ) then
				local nRadius = t.ability:GetCastRange( vCaster, nil ) + hCaster:GetCastRangeBonus()
				nRadius = nRadius + ( tData.nBuffer or 0 )

				local qUnits = Find:UnitsInRadius({
					vCenter = vCaster,
					nRadius = nRadius,
					nTeam = hCaster:GetTeam(),
					nFilterTeam = t.ability:GetAbilityTargetTeam(),
					nFilterType = t.ability:GetAbilityTargetType(),
					nFilterFlag = binor( t.ability:GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE ),
				})

				local fSort
				print( tData.nOrder )
				if tData.nOrder == MULTICAST_ORDER_TARGET_CLOSEST then
					local vTarget = t.target:GetOrigin()
					local tDistance = {}
					local fGetDistance = function( hUnit )
						local nDistance = tDistance[ hUnit ]
						if not nDistance then
							nDistance = ( hUnit:GetOrigin() - vTarget ):Length2D()
							tDistance[ hUnit ] = nDistance
						end
						return nDistance
					end
					
					fSort = function( hUnit1, hUnit2 )
						return fGetDistance( hUnit1 ) < fGetDistance( hUnit2 )
					end
				end

				if fSort then
					print'yo'
					table.sort( qUnits, fSort )
				end

				for _, hUnit in ipairs( qUnits ) do
					if hUnit ~= t.target then
						nCount = nCount - 1
						if nCount < 1 then
							break
						end

						SpellCaster:Cast( t.ability, hUnit )
					end
				end
			end
		end
	end
end