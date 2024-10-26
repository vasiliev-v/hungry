require 'lib/m_mult'

LinkLuaModifier('m_kbw_trident_buff', 'kbw/items/syk/m_kbw_syk', 0)

local tItems = {
	item_kbw_kaya = 1,
	item_kbw_sange = 1,
	item_kbw_yasha = 1,
	item_kbw_sange_yasha = 1,
	item_kbw_sange_yasha_2 = 1,
	item_kbw_sange_yasha_3 = 1,
	item_kbw_yasha_kaya = 1,
	item_kbw_yasha_kaya_2 = 1,
	item_kbw_yasha_kaya_3 = 1,
	item_kbw_kaya_sange = 1,
	item_kbw_kaya_sange_2 = 1,
	item_kbw_kaya_sange_3 = 1,
	item_kbw_trident = 1,
	item_kbw_trident_2 = 1,
	item_kbw_trident_3 = 1,
}

local tMatchBuffs = {
	m_item_generic_status_absorb = { 'sange', 'trident' },
	m_item_generic_regen = { 'sange', 'kaya' },
	m_item_generic_armor = { 'sange' },
	m_item_generic_base_damage = { 'yasha', 'trident' },
	m_item_generic_attack = { 'yasha' },
	m_item_generic_spell_damage = { 'kaya', 'trident' },
	m_item_generic_spell_cleave = { 'kaya' },
	m_item_generic_prime = { 'trident' },
}

for sItem in pairs(tItems) do
	local cItem = class{}

	local tMult = {
		m_item_generic_stats = -1,
	}

	for sBuff, qMatch in pairs(tMatchBuffs) do
		for _, sMatch in ipairs(qMatch) do
			if sItem:match(sMatch) then
				tMult[sBuff] = 0
				break
			end
		end
	end

	function cItem:GetIntrinsicModifierName()
		return 'm_mult'
	end

	function cItem:GetMultModifiers()
		return tMult
	end
	
	if sItem:match('trident') then
		function cItem:OnSpellStart()
			local caster = self:GetCaster()
			local duration = self:GetSpecialValueFor('active_duration')
			
			AddModifier('m_kbw_trident_buff', {
				hTarget = caster,
				hCaster = caster,
				hAbility = self,
				duration = duration,
			})
			
			local particle = ParticleManager:Create('particles/units/heroes/hero_sven/sven_spell_warcry.vpcf', PATTACH_CUSTOMORIGIN, caster, 2)
			ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
			ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_POINT_FOLLOW, 'attach_head', Vector(0,0,0), false)
			
			caster:EmitSound('KBW.Item.Trident.Cast')
		end
	end

	_G[sItem] = cItem
end