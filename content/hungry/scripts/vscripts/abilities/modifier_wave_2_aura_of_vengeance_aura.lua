modifier_wave_2_aura_of_vengeance_aura = class({})

function modifier_wave_2_aura_of_vengeance_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
 
	return funcs
end

function modifier_wave_2_aura_of_vengeance_aura:OnAttackLanded(params) 
	if params.target == self:GetParent() and not params.ranged_attack and not self:GetParent():IsIllusion() then 
		self.attack_record = params.record 
	end 
end


function modifier_wave_2_aura_of_vengeance_aura:OnTakeDamage(params)

	if self:GetParent():PassivesDisabled() then
		return
	end

	if self.attack_record == params.record then

		if params.unit:HasModifier("modifier_brain_storm_decrepify") 
		or params.unit:HasModifier("modifier_hermit_decrepify") 
		or params.unit:HasModifier("modifier_illusionist_mastery_of_illusions") then
			return
		end
		
		local return_damage = self.returnPercent*0.01*params.original_damage
		
		ApplyDamage(
		{
			victim = params.attacker, 
			attacker = params.unit, 
			damage = return_damage, 
			damage_type = DAMAGE_TYPE_MAGICAL,
			damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
			ability = self:GetAbility()
		})
	end

end

function modifier_wave_2_aura_of_vengeance_aura:OnCreated()
	if self:GetAbility() then
		self.returnPercent = self:GetAbility():GetSpecialValueFor("damage_return")
	end
	
end