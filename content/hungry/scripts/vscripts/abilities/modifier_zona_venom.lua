modifier_zona_venom_debuff = class({})

------------------------------------------------------------------------------------

function modifier_zona_venom_debuff:IsPurgable()
	return false
end
function modifier_zona_venom_debuff:IsDebuff() return true end
------------------------------------------------------------------------------------

function modifier_zona_venom_debuff:GetEffectName()
	return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf"
end

function modifier_zona_venom_debuff:GetTexture()
	return "custom/treant_sharp_thorns"
end

function modifier_zona_venom_debuff:IsPurgeException()
	return false
end
------------------------------------------------------------------------------------

function modifier_zona_venom_debuff:OnCreated( kv )
	self.movement_slow = -15
	self.attack_slow = -20

	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(1)
	end
end

--------------------------------------------------------------------------------

function modifier_zona_venom_debuff:OnIntervalThink()
	if IsServer() then
		
		for index, shopTrigger in ipairs(Entities:FindAllByName("venom")) do
			if shopTrigger:IsTouching(self:GetParent()) and not self:GetParent():HasModifier("modifier_venom")  then
				self:SetStackCount(self:GetStackCount() + 1)
				self:GetParent():AddNewModifier(self:GetParent(), self:GetParent(), "modifier_zona_venom_debuff", {Duration = 2 * self:GetStackCount()})	
			end
		end
		local flDamage = 2 * self:GetStackCount()
	
		

		local damage = {
			victim = self:GetParent(),
			attacker = self:GetParent(),
			damage = flDamage,
			damage_type = DAMAGE_TYPE_PURE
		}
	--	if not self:GetParent():HasItemInInventory("item_lia_health_stone_potion") then
			ApplyDamage( damage )
	--	end
		
	end
end

------------------------------------------------------------------------------------

function modifier_zona_venom_debuff:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
	return funcs
end

------------------------------------------------------------------------------------

function modifier_zona_venom_debuff:GetModifierMoveSpeedBonus_Percentage( params )
	return self.movement_slow
end

--------------------------------------------------------------------------------

function modifier_zona_venom_debuff:GetModifierAttackSpeedBonus_Constant( params )
	return self.attack_slow
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

