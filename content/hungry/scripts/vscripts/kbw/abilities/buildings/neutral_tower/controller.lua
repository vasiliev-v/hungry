LinkLuaModifier('m_tower_controller', "kbw/abilities/buildings/neutral_tower/controller", 0)

tower_ability = class{}

function tower_ability:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function tower_ability:GetIntrinsicModifierName()
	return 'm_tower_controller'
end

m_tower_controller = class{}

function m_tower_controller:IsDebuff()
	return false
end

function m_tower_controller:OnCreated()
	if IsServer() then
		local hAbility = self:GetAbility()
		local hParent = self:GetParent()

		hParent:SetHullRadius(90)

		self:Upgrade()
		self:RegisterSelfEvents()
	end
end

function m_tower_controller:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_tower_controller:OnParentTakeDamage(t)
	if t.damage >= t.unit:GetHealth() then
		self:Upgrade()
		self:SetTeam(t.attacker:GetTeam())
	end
end

function m_tower_controller:Upgrade()
	local hAbility = self:GetAbility()
	local hParent = self:GetParent()
	local nStacks = self:GetStackCount() + 1
	local nHealth = hParent:GetMaxHealth()
	local nDamage = hParent:GetBaseDamageMin()

	self:SetStackCount(nStacks)

	if nStacks == 1 then
		nHealth = hAbility:GetSpecialValueFor('base_health')
		nDamage = hAbility:GetSpecialValueFor('base_damage')
	else
		nHealth = nHealth + hAbility:GetSpecialValueFor('health_inc') + (nStacks-2) * hAbility:GetSpecialValueFor('health_inc_inc')
		nDamage = nDamage + hAbility:GetSpecialValueFor('damage_inc') + (nStacks-2) * hAbility:GetSpecialValueFor('damage_inc_inc')
	end

	hParent:SetBaseMaxHealth(nHealth)
	hParent:SetMaxHealth(nHealth)
	hParent:SetHealth(nHealth)

	hParent:SetBaseDamageMin(nDamage)
	hParent:SetBaseDamageMax(nDamage)
end

function m_tower_controller:SetTeam(nTeam)
	local hParent = self:GetParent()

	hParent:SetTeam(nTeam)

	local sMaterial = ({
		[DOTA_TEAM_GOODGUYS] = 'radiant_level4',
		[DOTA_TEAM_BADGUYS] = 'dire_level6',
	})[nTeam] or 'dire_level1'
	hParent:SetMaterialGroup(sMaterial)
	
	local sProjectile = ({
		[DOTA_TEAM_GOODGUYS] = 'particles/world_tower/tower_upgrade/ti7_radiant_tower_proj.vpcf',
		[DOTA_TEAM_BADGUYS] = 'particles/world_tower/tower_upgrade/ti7_dire_tower_projectile.vpcf',
	})[nTeam] or "particles/units/heroes/hero_leshrac/leshrac_base_attack.vpcf"
	hParent:SetRangedProjectileName(sProjectile)
end

function m_tower_controller:CheckState()
	return {
		[MODIFIER_STATE_SPECIALLY_UNDENIABLE] = true,
	}
end

function m_tower_controller:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_MIN_HEALTH,
	}
end

function m_tower_controller:GetModifierTotal_ConstantBlock(t)
	local nTeam = t.attacker:GetTeam()
	if nTeam == t.target:GetTeam() or nTeam == DOTA_TEAM_NEUTRALS
	or (t.attacker:GetOrigin() - t.target:GetOrigin()):Length2D() > t.target:Script_GetAttackRange() + t.attacker:GetHullRadius() + t.target:GetHullRadius() then
		return t.damage
	end
end

function m_tower_controller:GetActivityTranslationModifiers()
	return 'level2'
end

function m_tower_controller:GetMinHealth()
	return 1
end