local fMake = function( sName, bBuff, sTexture )
	local cClass = ModifierClass{
		bPermanent = true,
		bIgnoreInvuln = true,
	}

	_G[ sName ] = cClass

	function cClass:IsDebuff()
		return not bBuff
	end

	function cClass:GetTexture()
		return sTexture
	end

	function cClass:DeclareFunctions()
		return {
			MODIFIER_PROPERTY_TOOLTIP,
		}
	end

	function cClass:OnTooltip()
		return self:GetStackCount()
	end
end

fMake( 'm_balance_gold_buff', true, 'alchemist_goblins_greed' )
fMake( 'm_balance_gold_debuff', false, 'alchemist_goblins_greed' )
-- fMake( 'm_balance_xp_buff', true, 'kbw_xp' )
-- fMake( 'm_balance_xp_debuff', false, 'kbw_xp' )