local sPath = "kbw/items/talisman_of_mastery"
LinkLuaModifier('m_item_kbw_magic_stick', 'kbw/items/magic_stick', LUA_MODIFIER_MOTION_NONE)

item_talisman_of_mastery = class{}

function item_talisman_of_mastery:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_talisman_of_mastery:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_kbw_magic_stick = 0,
	}
end

function item_talisman_of_mastery:OnSpellStart()
	local caster = self:GetCaster()
	local cost = self:GetSpecialValueFor('learning_hp_cost')
	local duration = self:GetSpecialValueFor('learning_duration')
	
	AddModifier('m_item_talisman_of_mastery_buff', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:ModifyHealth(caster:GetHealth() - cost, nil, false, 0)
	
	local particle = ParticleManager:Create('particles/items/mastery.vpcf', PATTACH_ABSORIGIN_FOLLOW, caster, duration + 1)
	ParticleManager:SetParticleControl(particle, 1, Vector(duration * 5, 0, 0))
	
	caster:EmitSound('KBW.Item.TalismanOfMastery.Cast')
end

LinkLuaModifier( 'm_item_talisman_of_mastery_buff', sPath, 0 )
m_item_talisman_of_mastery_buff = ModifierClass{
}

function m_item_talisman_of_mastery_buff:OnCreated( kv )
    if IsServer() then
		ReadAbilityData( self, {
			'learning_pct',
			'learning_pct_creep',
			'learning_limit',
		})

		self:RegisterSelfEvents()
    end 
end 

function m_item_talisman_of_mastery_buff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end	
end

function m_item_talisman_of_mastery_buff:OnParentDealDamage(t)
	if t.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		local mult = t.unit:IsRealHero() and self.learning_pct or self.learning_pct_creep
		local exp = t.damage * mult / 100
		exp = math.min(self.learning_limit, exp)
		self.learning_limit = self.learning_limit - exp

		t.attacker:AddExperience(exp, 0, false, true)
		
		if self.learning_limit <= 0 then
			self:Destroy()
		end
	end
end