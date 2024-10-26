local PATH = "kbw/items/levels/monkey_king_bar"
local base = {}

-----------------------------------------------
-- passive stats

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_attack = 0,
		m_item_kbw_monkey_king_bar_passive = self.nLevel,
	}
end

-----------------------------------------------
-- active

function base:OnSpellStart()
	local caster = self:GetCaster()

	AddModifier('item_kbw_monkey_king_bar_active', {
		hTarget = caster,
		hCaster = caster,
		hAbility = self,
		duration = self:GetSpecialValueFor('active_duration')
	})

	caster:EmitSound('KBW.Item.MonkeyKingBar.Cast')
end

-----------------------------------------------
-- levels

CreateLevels({
	'item_kbw_monkey_king_bar',
	'item_kbw_monkey_king_bar_2',
	'item_kbw_monkey_king_bar_3',
}, base)

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-- passive unique

LinkLuaModifier('m_item_kbw_monkey_king_bar_passive', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_monkey_king_bar_passive = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_monkey_king_bar_passive:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self.records = {}
		self.next_proc = -1
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_monkey_king_bar_passive:OnRefresh()
	ReadAbilityData(self, {
		'proc_chance',
		'proc_damage',
		'active_chance',
		'active_stun',
		'active_interval',
	})
end

function m_item_kbw_monkey_king_bar_passive:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_item_kbw_monkey_king_bar_passive:OnParentAttackStart(t)
	if t.attacker:IsIllusion() then
		return
	end

	if not exist(t.target) or not t.target:IsBaseNPC() then
		return
	end

	if UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		t.attacker:GetTeam()
	) ~= UF_SUCCESS then
		return
	end

	local chance = self:IsActive() and self.active_chance or self.proc_chance

	if RandomFloat(0, 100) <= chance then
		self.mod_true_strike = t.attacker:AddNewModifier(t.attacker, nil, 'm_kbw_true_strike', {})
	end
end

function m_item_kbw_monkey_king_bar_passive:OnParentAttackRecord(t)
	if not exist(self.mod_true_strike) then
		return
	end

	self.mod_true_strike:Destroy()
	self.mod_true_strike = nil

	self.records[t.record] = true
end

function m_item_kbw_monkey_king_bar_passive:OnParentAttackRecordDestroy(t)
	self.records[t.record] = nil
end

function m_item_kbw_monkey_king_bar_passive:OnParentAttackLanded(t)
	if not exist(t.target) or not t.target:IsBaseNPC() then
		return
	end

	if not self.records[t.record] then
		return
	end

	local ability = self:GetAbility()

	if self:IsActive() and not t.target:IsMagicImmune() then
		local time = GameRules:GetGameTime()

		if self.next_proc <= time then
			self.next_proc = time + self.active_interval

			AddModifier('modifier_bashed', {
				hTarget = t.target,
				hCaster = t.attacker,
				hAbility = ability,
				duration = self.active_stun,
			})

			t.target:EmitSound('KBW.Item.MonkeyKingBar.Stun')
		end
	end

	local damage = ApplyDamage({
		victim = t.target,
		attacker = t.attacker,
		ability = ability,
		damage = self.proc_damage,
		damage_type = ability:GetAbilityDamageType(),
	})

	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, t.target, damage, nil)
end

function m_item_kbw_monkey_king_bar_passive:IsActive()
	return self:GetParent():HasModifier('item_kbw_monkey_king_bar_active')
end

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------
-- passive active (just a visual wrapper)

LinkLuaModifier('item_kbw_monkey_king_bar_active', PATH, MODIFIER_ATTRIBUTE_NONE)
item_kbw_monkey_king_bar_active = ModifierClass{
	bPurgable = true,
}

function item_kbw_monkey_king_bar_active:OnCreated()
	if IsServer() then
		self.particle = ParticleManager:Create('particles/items/monkey_king_bar/buff.vpcf', self:GetParent())
	end
end

function item_kbw_monkey_king_bar_active:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.particle, true)
	end
end