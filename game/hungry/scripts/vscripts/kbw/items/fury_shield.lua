local sPath = "kbw/items/fury_shield"
LinkLuaModifier('m_item_fury_shield_buff', sPath, LUA_MODIFIER_MOTION_NONE)

item_fury_shield = class{}

function item_fury_shield:Precache(c)
	PrecacheResource('particle', 'particles/items/fury_shield/buff.vpcf', c)
end

function item_fury_shield:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_fury_shield:GetMultModifiers()
	return {
		m_item_generic_stats = 1,
		m_item_generic_base = 1,
	}
end

function item_fury_shield:OnSpellStart()
	local hCaster = self:GetCaster()

	AddModifier('m_item_fury_shield_buff', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		duration = self:GetSpecialValueFor('duration'),
	})

	hCaster:EmitSound('DOTA_Item.Buckler.Activate')
end

m_item_fury_shield = ModifierClass{
	bPermanent = true,
	bHidden = true,
	bMultiple = true,
}

function m_item_fury_shield:OnCreated()
	ReadAbilityData(self, {
		'all',
		'armor',
	})
end

function m_item_fury_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_item_fury_shield:GetModifierBonusStats_Strength()
	return self.all
end
function m_item_fury_shield:GetModifierBonusStats_Agility()
	return self.all
end
function m_item_fury_shield:GetModifierBonusStats_Intellect()
	return self.all
end
function m_item_fury_shield:GetModifierPhysicalArmorBonus()
	return self.armor
end

m_item_fury_shield_buff = ModifierClass{
	bPurgable = true,
}

function m_item_fury_shield_buff:GetTexture()
	return 'item_fury_shield'
end

function m_item_fury_shield_buff:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		local hParent = self:GetParent()
		self.nParticle = ParticleManager:Create('particles/items/fury_shield/buff.vpcf', PATTACH_ABSORIGIN_FOLLOW, hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
	end
end

function m_item_fury_shield_buff:OnRefresh(t)
	ReadAbilityData(self, {
		'active_damage',
		'active_block',
		maximal = true,
	})
end

function m_item_fury_shield_buff:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_item_fury_shield_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
	}
end

function m_item_fury_shield_buff:GetModifierBaseAttack_BonusDamage()
	return self.active_damage
end
function m_item_fury_shield_buff:GetModifierTotal_ConstantBlock(t)
	if t.damage_type == DAMAGE_TYPE_PHYSICAL and t.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		return self.active_block
	end
end