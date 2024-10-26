require('internal/spell_caster')
require('internal/table')
require('kbw/util_spell')
require('kbw/util_c')
require('kbw/modifier_self_events')
require('kbw/filters')
require('kbw/special_fixes')
require('kbw/init')
require('kbw/special_modifier')
require('kbw/gentable')
require('kbw/api_fix')
require('lib/gameplay_event_tracker/init')

require('kbw/value_modifier')
m_kbw_multishot = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_kbw_multishot:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'chance',
			'targets',
		})

		
	end
end

function m_kbw_multishot:OnDestroy()
	if IsServer() then
		
	end
end

function m_kbw_multishot:DeclareFunctions()
	local func = {
		MODIFIER_EVENT_ON_ATTACK,

	}
	return func
end

function m_kbw_multishot:OnAttack(t)
	if not exist(t.target) or not t.target:IsBaseNPC() or not self.targets or t.attacker.bOnParentAttack then
		return
	end
	
	if self.chance and RandomFloat(0, 100) > self.chance then
		return
	end
	
	local pos = t.attacker:GetOrigin()
	local range = t.attacker:GetAttackRange() + t.attacker:GetPaddedCollisionRadius()
	
	local targets = table.filter(
		FindUnitsInRadius(
			t.attacker:GetTeam(),
			t.target:GetOrigin(),
			t.target,
			range * 2,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
				+ DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE
				+ DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
			FIND_CLOSEST,
			false
		),
		function(u)
			return u ~= t.target and (u:GetOrigin() - pos):Length2D() <= range + u:GetPaddedCollisionRadius()
		end
	)
	
	for i = 1, self.targets do
		local target = targets[i]
		if not target then
			break
		end

		t.attacker.bOnParentAttack = true
		t.attacker:PerformAttack(target, true, true, true, false, true, false, false)
		t.attacker.bOnParentAttack = nil
	end
end