LinkLuaModifier( 'm_lifestealer_feast_kbw', "kbw/abilities/heroes/lifestealer/feast", 0 )

local nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
local nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
local nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

lifestealer_feast_kbw = class{}

function lifestealer_feast_kbw:GetIntrinsicModifierName()
	return 'm_lifestealer_feast_kbw'
end

m_lifestealer_feast_kbw = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_lifestealer_feast_kbw:OnCreated( t )
	if IsServer() then
		self:OnRefresh( t )
		self:RegisterSelfEvents()
	end
end

function m_lifestealer_feast_kbw:OnRefresh()
	if IsServer() then
		ReadAbilityData( self, {
			nDamagePct = 'hp_damage_pct',
			nHeal = 'heal',
			nBossDeamp = 'boss_deamp',
		})
	end
end

function m_lifestealer_feast_kbw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_lifestealer_feast_kbw:OnParentAttackLanded(t)
	if not exist(t.target) or not t.target:IsAlive()
	or UnitFilter(t.target, nFilterTeam, nFilterType, nFilterFlag, t.attacker:GetTeam()) ~= UF_SUCCESS then
		return
	end

	local hParent = self:GetParent()
	if not hParent:PassivesDisabled() then
		hParent:Heal( self.nHeal, self:GetAbility() )
	end
end

function m_lifestealer_feast_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function m_lifestealer_feast_kbw:GetModifierPreAttack_BonusDamage( t )
	if IsServer() and exist(t.target) and t.target:IsAlive() and not self:GetParent():PassivesDisabled() 
	and UnitFilter(t.target, nFilterTeam, nFilterType, nFilterFlag, t.attacker:GetTeam()) == UF_SUCCESS then
		local nDamage = t.target:GetHealth() * self.nDamagePct / 100
		if IsBoss( t.target ) then
			nDamage = nDamage * ( 100 - self.nBossDeamp ) / 100
		end
		return nDamage
	end
end