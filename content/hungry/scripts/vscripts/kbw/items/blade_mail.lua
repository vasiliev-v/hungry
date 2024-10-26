local PATH = "kbw/items/blade_mail"

----------------------------------------------
-- item

item_kbw_blade_mail = class{}

function item_kbw_blade_mail:GetIntrinsicModifierName()
	return 'm_item_generic_base'
end

function item_kbw_blade_mail:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor('return_duration')
	
	AddModifier('m_item_kbw_blade_mail_return', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = duration,
	})
	
	caster:EmitSound('DOTA_Item.BladeMail.Activate')
end

----------------------------------------------
-- modifier: return

LinkLuaModifier('m_item_kbw_blade_mail_return', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_blade_mail_return = ModifierClass{
	bPurgable = true,
}

function m_item_kbw_blade_mail_return:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local parent = self:GetParent()
		
		self:RegisterSelfEvents()
		
		if self.return_block > 0 then
			self.resist = AddSpecialModifier(parent, 'nDamageResist', self.return_block / 100, OPERATION_ASYMPTOTE)
			
			self.particle = ParticleManager:Create('particles/items5_fx/force_field.vpcf', PATTACH_OVERHEAD_FOLLOW, parent)
		else
			self.particle = ParticleManager:Create('particles/items_fx/blademail.vpcf', PATTACH_ABSORIGIN_FOLLOW, parent)
		end
	end
end

function m_item_kbw_blade_mail_return:OnRefresh(t)
	ReadAbilityData(self, {
		'return_pct',
		'return_block',
		maximal = true,
	})
end

function m_item_kbw_blade_mail_return:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		
		self:UnregisterSelfEvents()
		
		if exist(self.resist) then
			self.resist:Destroy()
		end
		
		ParticleManager:Fade(self.particle, true)
		
		-- parent:EmitSound('DOTA_Item.BladeMail.Deactivate')
	end
end

function m_item_kbw_blade_mail_return:OnParentTakeDamage(t)
	if t.damage_type == DAMAGE_TYPE_MAGICAL and t.attacker:IsMagicImmune() then
		return
	end
	
	if bit.band(t.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then
		return
	end
	
	local damage_flags = bit.bor(
		DOTA_DAMAGE_FLAG_REFLECTION
		-- + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS
		+ DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		t.damage_flags
	)
	
	ApplyDamage({
		victim = t.attacker,
		attacker = t.unit,
		ability = self:GetAbility(),
		damage = t.original_damage * self.return_pct / 100,
		damage_type = t.damage_type,
		damage_flags = damage_flags,
	})
end