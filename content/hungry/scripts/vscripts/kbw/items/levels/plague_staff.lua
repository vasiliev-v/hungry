LinkLuaModifier( 'm_item_plague_staff', "kbw/items/levels/plague_staff", 0 )
LinkLuaModifier( 'm_item_plague_staff_stats', "kbw/items/levels/plague_staff", 0 )

local tExceptions = {
	zuus_static_field = true,
	doom_bringer_infernal_blade = true,
	huskar_life_break = true,
	huskar_burning_spear = true,
	necrolyte_reapers_scythe = true,
	winter_wyvern_arctic_burn = true,
	phantom_assassin_fan_of_knives = true,
	enigma_midnight_pulse = true,
	obsidian_destroyer_arcane_orb = true,
	silencer_glaives_of_wisdom = true,
	item_kbw_giant_ring = true,
	item_kbw_giant_ring_2 = true,
	item_kbw_giant_ring_3 = true,
	item_kbw_blade_of_discord = true,
	storm_spirit_ball_lightning = true,
	bloodseeker_bloodrage_kbw = true,
	phoenix_sun_ray = true,
	omniknight_hammer_of_purity = true,
	item_soul_wrapper = true,
	item_soul_wrapper_2 = true,
	item_soul_wrapper_3 = true,
	item_overwhelming_blink = true,
	item_overwhelming_blink2 = true,
	item_overwhelming_blink3 = true,
	drow_ranger_multishot = true,
	enchantress_impetus = true,
	sand_king_explosive_poison = true,
	juggernaut_omni_slash = true,
	juggernaut_swift_slash = true,
	nyx_assassin_mana_burn = true,
	special_bonus_mag_attack_10 = true,
	special_bonus_mag_attack_12 = true,
	special_bonus_mag_attack_15 = true,
	hoodwink_acorn_shot = true,
	centaur_return = true,
	centaur_stampede = true,
	bloodseeker_blood_mist = true,
}

local tDamageBases = {
	enigma_black_hole = 'damage',
	morphling_adaptive_strike_agi = 'damage_base',
	silencer_last_word = 'damage',
	item_ethereal_blade = 'blast_damage_base',
	item_ethereal_blade2 = 'blast_damage_base',
	item_ethereal_blade3 = 'blast_damage_base',
	item_kbw_radiance = 'aura_damage',
	item_kbw_radiance_2 = 'aura_damage',
	item_kbw_radiance_3 = 'aura_damage',
	pudge_dismember = 'dismember_damage',
	skywrath_mage_arcane_bolt = 'bolt_damage',
	obsidian_destroyer_sanity_eclipse = 'base_damage',
	lion_finger_of_death = 'damage',
	abyssal_underlord_firestorm = 'wave_damage',
	centaur_double_edge = 'edge_damage',
	venomancer_poison_nova = 'base_damage',
	jakiro_liquid_ice = 'base_damage',
}

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_plague_staff_stats = 0,
        m_item_plague_staff = self.nLevel,
    }
end

CreateLevels({
    'item_plague_staff',
    'item_plague_staff_2',
    'item_plague_staff_3',
}, base )

m_item_plague_staff_stats = ModifierClass{
	bHidden = true,
    bMultiple = true,
    bPermanent = true,
}

function m_item_plague_staff_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function m_item_plague_staff_stats:GetModifierBonusStats_Intellect()
	return self.nInt
end

function m_item_plague_staff_stats:OnCreated()
	ReadAbilityData( self, {
		nInt = 'int',
		nThreshold = 'threshold',
		nLowAmp = 'low_spell_amp',
		nChance = 'chance',
		nCrit = 'crit',
	})

	if IsServer() then
		local hParent = self:GetParent()
		local nTeam = hParent:GetTeam()

		if hParent.DAMAGE_DEAL_EVENT then
			self.hDamageListener = Events:Register( hParent.DAMAGE_DEAL_EVENT, function( t )
				if exist( t.hTarget ) and t.hTarget:GetTeam() == nTeam then
					return
				end
				if not exist( t.hAbility ) then
					return
				end
				if binhas( t.nDamageFlags,
					DOTA_DAMAGE_FLAG_REFLECTION,
					DOTA_DAMAGE_FLAG_HPLOSS,
					DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
					DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION
				) then
					return
				end

				local sAbility =  t.hAbility:GetAbilityName()
				if tExceptions[sAbility] then
					return
				end

				local nBase = tDamageBases[sAbility]
				if nBase then
					nBase = t.hAbility:GetSpecialValueFor(nBase)
					_G.EXTRA_DAMAGE_DATA = {
						nCritBase = nBase,
					}
				else
					nBase = t.nDamage
				end

				if nBase < self.nThreshold then
					t.nMultiplier = t.nMultiplier + self.nLowAmp / 100
				elseif t.nCrit < self.nCrit and RandomFloat( 0, 100 ) <= self.nChance then
					t.nCrit = self.nCrit
				end

				t.bChange = true
			end )
		end
	end
end

function m_item_plague_staff_stats:OnDestroy()
	if IsServer() then
		if exist( self.hDamageListener ) then
			self.hDamageListener:Destroy()
		end
	end
end

m_item_plague_staff = ModifierClass({
	bHidden = true,
    bPermanent = true,
})

function m_item_plague_staff:OnCreated()
    ReadAbilityData( self, {
        nMpRegenAmp = 'mp_regen_amp',
    })
end

function m_item_plague_staff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MP_RESTORE_AMPLIFY_PERCENTAGE,
    }
end

function m_item_plague_staff:GetModifierMPRegenAmplify_Percentage()
    return self.nMpRegenAmp
end
function m_item_plague_staff:GetModifierMPRestoreAmplify_Percentage()
    return self.nMpRegenAmp
end
