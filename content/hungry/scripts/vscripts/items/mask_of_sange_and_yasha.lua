--[[
	"AbilityValues"
	{
		"passive_attack_speed"			"25"
		"passive_attack_damage"			"60"
		"passive_lifesteal"				"25"
		"passive_agility"				"20"
		"passive_strength"				"20"
		"passive_status_resistance"		"25"
		"passive_movespeed"				"20"
		"passive_regen_lifesteal_amp"	"30"

		"active_duration"				"6"
		"active_armor_reduction"		"8"
		"active_attack_speed"			"125"
		"active_movespeed"				"50"
		"active_silences"				"1" // set to 0 to remove silence
	}
]]

item_mask_of_sange_and_yasha = item_mask_of_sange_and_yasha or class({})

function item_mask_of_sange_and_yasha:GetIntrinsicModifierName() return "modifier_item_mask_of_sange_and_yasha" end

function item_mask_of_sange_and_yasha:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_item_mask_of_sange_and_yasha_active", {duration = self:GetSpecialValueFor("active_duration")})

	caster:EmitSound("DOTA_Item.MaskOfMadness.Activate")
end

--=================================================================================================================--

LinkLuaModifier("modifier_item_mask_of_sange_and_yasha_active", "items/mask_of_sange_and_yasha", LUA_MODIFIER_MOTION_NONE)

modifier_item_mask_of_sange_and_yasha_active = modifier_item_mask_of_sange_and_yasha_active or class({})


function modifier_item_mask_of_sange_and_yasha_active:IsHidden() return false end
function modifier_item_mask_of_sange_and_yasha_active:IsPurgable() return true end
function modifier_item_mask_of_sange_and_yasha_active:IsDebuff() return false end

function modifier_item_mask_of_sange_and_yasha_active:OnCreated(keys)
	self.particle = ParticleManager:CreateParticle(
        "particles/items/mask_of_sange_and_yasha/mask_of_sange_and_yasha.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        self:GetParent()
    )
	local ability = self:GetAbility()
	
	self.armor_reduction = ability:GetSpecialValueFor("active_armor_reduction")
	self.attack_speed = ability:GetSpecialValueFor("active_attack_speed")
	self.movespeed = ability:GetSpecialValueFor("active_movespeed")
	self.silences = ability:GetSpecialValueFor("active_silences")

	if self.silences == 1 then
		self.state = {
			[MODIFIER_STATE_SILENCED] = true,
		}
	end
end

function modifier_item_mask_of_sange_and_yasha_active:OnRemoved()
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
end

function modifier_item_mask_of_sange_and_yasha_active:CheckState()
	return self.state
end

function modifier_item_mask_of_sange_and_yasha_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_item_mask_of_sange_and_yasha_active:GetModifierPhysicalArmorBonus() return self.armor_reduction * (-1) end
function modifier_item_mask_of_sange_and_yasha_active:GetModifierMoveSpeedBonus_Constant() return self.movespeed end
function modifier_item_mask_of_sange_and_yasha_active:GetModifierAttackSpeedBonus_Constant() return self.attack_speed end

--=================================================================================================================--

LinkLuaModifier("modifier_item_mask_of_sange_and_yasha", "items/mask_of_sange_and_yasha", LUA_MODIFIER_MOTION_NONE)

modifier_item_mask_of_sange_and_yasha = modifier_item_mask_of_sange_and_yasha or class({})

function modifier_item_mask_of_sange_and_yasha:IsHidden() return true end
function modifier_item_mask_of_sange_and_yasha:IsPurgable() return false end
function modifier_item_mask_of_sange_and_yasha:IsDebuff() return false end
function modifier_item_mask_of_sange_and_yasha:IsPermanent() return true end
function modifier_item_mask_of_sange_and_yasha:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mask_of_sange_and_yasha:OnCreated()
	local ability = self:GetAbility()
	self.attack_speed 			= ability:GetSpecialValueFor("passive_attack_speed")
	self.attack_damage 			= ability:GetSpecialValueFor("passive_attack_damage")
	self.agility 				= ability:GetSpecialValueFor("passive_agility")
	self.strength 				= ability:GetSpecialValueFor("passive_strength")
	self.status_resistance 		= ability:GetSpecialValueFor("passive_status_resistance")
	self.movespeed 				= ability:GetSpecialValueFor("passive_movespeed")
	self.regen_lifesteal_amp 	= ability:GetSpecialValueFor("passive_regen_lifesteal_amp")
	
	self.lifesteal 				= ability:GetSpecialValueFor("passive_lifesteal")
end

function modifier_item_mask_of_sange_and_yasha:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATUS_RESISTANCE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,

		MODIFIER_PROPERTY_ON_DEALDAMAGE_CUSTOM,
	}
end

function modifier_item_mask_of_sange_and_yasha:GetModifierAttackSpeedBonus_Constant() return self.attack_speed end
function modifier_item_mask_of_sange_and_yasha:GetModifierPreAttack_BonusDamage() return self.attack_damage end
function modifier_item_mask_of_sange_and_yasha:GetModifierBonusStats_Agility() return self.agility end
function modifier_item_mask_of_sange_and_yasha:GetModifierBonusStats_Strength() return self.strength end
function modifier_item_mask_of_sange_and_yasha:GetModifierStatusResistance() return self.status_resistance end
function modifier_item_mask_of_sange_and_yasha:GetModifierMoveSpeedBonus_Percentage_Unique() return self.movespeed end
function modifier_item_mask_of_sange_and_yasha:GetModifierHPRegenAmplify_Percentage() return self.regen_lifesteal_amp end

function modifier_item_mask_of_sange_and_yasha:OnDealDamage(keys)
	self:ProcessLifesteal(keys, self.lifesteal)
end
