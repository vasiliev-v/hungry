local PATH = "kbw/items/levels/overlord"

local dominators = {
	'item_kbw_overlord',
	'item_kbw_overlord_2',
	'item_kbw_overlord_3',
}

local function skip(t, team)
	for i = #t, 1, -1 do
		if (not exist(t[i]) or not t[i]:IsAlive())
		or (team and t[i]:GetTeam() ~= team) then
			table.remove(t, i)
		end
	end
end

local function GetTeamBosses(team)
	local bosses = _G.tTeamDominated[team]
	if bosses then
		skip(bosses, team)
	else
		bosses = {}
		_G.tTeamDominated[team] = bosses
	end
	return bosses
end

if IsServer() then
	if not _G.tTeamDominated then
		_G.tTeamDominated = {}
	end

	local function GetDominatorLimit(hero)
		local max_count = 0

		IterateInventory(hero, 'ACTIVE', function(_, item)
			if item and IsDominator(item) then
				max_count = math.max(
					max_count,
					item:GetSpecialValueFor('creeps_limit'),
					item:GetSpecialValueFor('count_limit')
				)
			end
		end)

		return max_count
	end

	local function RegisterDominatorUnit(unit)
		if not exist(unit) or unit:GetTeam() == DOTA_TEAM_NEUTRALS then
			return
		end

		local player = unit:GetPlayerOwnerID()
		local hero = PlayerResource:GetSelectedHeroEntity(player)
		if not hero then
			return
		end

		local team = hero:GetTeam()

		if not hero.__aDominatedUnits then
			hero.__aDominatedUnits = {}
		else
			skip(hero.__aDominatedUnits, team)
		end

		table.insert(hero.__aDominatedUnits, unit)

		if IsStatBoss(unit) then
			table.insert(GetTeamBosses(team), unit)
		end

		if #hero.__aDominatedUnits > GetDominatorLimit(hero) then
			local tokill, i
			for _i, _tokill in ipairs(hero.__aDominatedUnits) do
				if _tokill ~= unit and not IsStatBoss(_tokill) then
					tokill = _tokill
					i = _i
					break
				end
			end

			if tokill then
				table.remove(hero.__aDominatedUnits, i)
				MakeKillable(tokill, true)
				tokill:Kill(nil, hero)
			end
		end
	end

	Events:Register('OnAbilityFullyCast', function(t)
		if IsDominator(t.ability) then
			RegisterDominatorUnit(t.target)
		end
	end, {
		sName = 'DominatorUnits'
	})
end

------------------------

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = -1,
		m_item_generic_armor = -1,
		m_item_generic_regen = -1,
	}
end

function base:CastFilterResultTarget(target)
	local team = self:GetCaster():GetTeamNumber()

	if target:GetTeamNumber() == team then
		return UF_FAIL_FRIENDLY
	end

	if IsMainBoss(target) then
		return UF_FAIL_ANCIENT
	elseif IsStatBoss(target) then
		local limit = self:GetSpecialValueFor('boss_limit')

		if limit <= 0 then
			return UF_FAIL_ANCIENT
		end

		if IsServer() then
			local bosses = GetTeamBosses(team)

			if #bosses >= limit then
				self.custom_error = 'limit'
				return UF_FAIL_CUSTOM
			end

			if bosses.next_time and bosses.next_time > GameRules:GetGameTime() then
				self.custom_error = 'cooldown'
				return UF_FAIL_CUSTOM
			end
		end
	elseif IsBoss(target) then
		if self:GetSpecialValueFor('allow_bears') == 0 then
			return UF_FAIL_ANCIENT
		end
	elseif target:IsConsideredHero() then
		return UF_FAIL_HERO
	elseif target:IsCreep() then
		return UF_SUCCESS
	end
	
	return UF_FAIL_OTHER
end

function base:GetCustomCastErrorTarget()
	if self.custom_error == 'limit' then
		return '#custom_hud_error_boss_limit'
	end
	return '#dota_hud_error_item_in_cooldown'
end

local function LaunchTeamCooldown(caster, min_cooldown, max_cooldown)
	max_cooldown = max_cooldown or min_cooldown
	local team = caster:GetTeam()
	local bosses = GetTeamBosses(team)
	local remaining = 0
	local time = GameRules:GetGameTime()

	if bosses.next_time then
		remaining = bosses.next_time - time
	end

	local cooldown = math.min(max_cooldown, math.max(min_cooldown, remaining))

	bosses.next_time = time + cooldown

	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		local hero = PlayerResource:GetSelectedHeroEntity(i)
		if hero and hero:GetTeam() == team then
			hero:RemoveModifierByName('m_item_kbw_overlord_boss_cooldown')

			AddModifier('m_item_kbw_overlord_boss_cooldown', {
				hTarget = hero,
				hCaster = caster,
				bAddToDead = true,
				bCalcDeadDuration = true,
				bIgnoreStatusResist = true,
				bIgnoreDebuffAmp = true,
				duration = cooldown,
			})
		end
	end
end

function base:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local player = caster:GetPlayerOwnerID()
	local team = caster:GetTeam()

	if not exist(target) or self:CastFilterResultTarget(target) ~= UF_SUCCESS then
		return
	end

	if IsStatBoss(target) then
		LaunchTeamCooldown(caster, self:GetSpecialValueFor('boss_cooldown_mins') * 60)
	end

	if target:TriggerSpellAbsorb(self) then
		return
	end

	if exist(target.hAi) then
		target.hAi:Destroy()
		target.hAi = nil
	end

	local old_team = target:GetTeam()
	local old_player = target:GetPlayerOwnerID()

	target:SetTeam(team)
	target:SetOwner(caster)
	target:SetControllableByPlayer(player, false)
	target:SetHealth(target:GetMaxHealth())

	if IsStatBoss(target) then
		AddModifier('m_item_kbw_overlord_broken_boss', {
			hTarget = target,
			hCaster = caster,
			hAbility = self,
		})

		target:RemoveAbility('boss_divine_creature')

		if old_team ~= DOTA_TEAM_NEUTRALS then
			local old_owner = PlayerResource:GetSelectedHeroEntity(old_player)
			if old_owner then
				LaunchTeamCooldown(old_owner, 0, self:GetSpecialValueFor('boss_steal_cooldown'))
			end
		end
	end

	AddModifier('m_item_kbw_overlord_creep', {
		hTarget = target,
		hCaster = caster,
		hAbility = self,
	})

	target:EmitSound('DOTA_Item.HotD.Activate')
end

CreateLevels(dominators, base)

------------------------

LinkLuaModifier('m_item_kbw_overlord_creep', PATH, LUA_MODIFIER_MOTION_NONE)

m_item_kbw_overlord_creep = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_overlord_creep:OnCreated(t)
	ReadAbilityData(self, {
		'creep_min_speed',
		'creep_health',
		'creep_damage',
		'creep_hp_regen',
		'creep_armor',
	})

	if IsServer() then
		local parent = self:GetParent()

		parent:SetBaseMoveSpeed(math.max(parent:GetBaseMoveSpeed(), self.creep_min_speed))

		self.particle = ParticleManager:Create('particles/items5_fx/helm_of_the_dominator_buff.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
	end
end

function m_item_kbw_overlord_creep:OnRefresh(t)
	self:OnCreated(t)
end

function m_item_kbw_overlord_creep:OnDestroy()
	if IsServer() then
		if self.particle then
			ParticleManager:Fade(self.particle, true)
		end
	end
end

function m_item_kbw_overlord_creep:CheckState()
	return {
		[MODIFIER_STATE_DOMINATED] = true,
	}
end

function m_item_kbw_overlord_creep:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_item_kbw_overlord_creep:GetModifierExtraHealthBonus()
	return self.creep_health
end
function m_item_kbw_overlord_creep:GetModifierPreAttack_BonusDamage()
	return self.creep_damage
end
function m_item_kbw_overlord_creep:GetModifierConstantHealthRegen()
	return self.creep_hp_regen
end
function m_item_kbw_overlord_creep:GetModifierPhysicalArmorBonus()
	return self.creep_armor
end

------------------------

LinkLuaModifier('m_item_kbw_overlord_broken_boss', PATH, LUA_MODIFIER_MOTION_NONE)

m_item_kbw_overlord_broken_boss = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_overlord_broken_boss:OnCreated()
	ReadAbilityData(self, {
		'broken_health_pct',
		'broken_damage_pct',
		'broken_model_reduction',
	}, function()
		local parent = self:GetParent()
		self.health_reduction = parent:GetMaxHealth() * (100 - self.broken_health_pct) / 100
		self.damage_reduction = 100 - self.broken_damage_pct
	end)
end

function m_item_kbw_overlord_broken_boss:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end

function m_item_kbw_overlord_broken_boss:GetModifierExtraHealthBonus()
	return -self.health_reduction
end
function m_item_kbw_overlord_broken_boss:GetModifierTotalDamageOutgoing_Percentage()
	return -self.damage_reduction
end
function m_item_kbw_overlord_broken_boss:GetModifierModelScale()
	return -self.broken_model_reduction
end

------------------------

LinkLuaModifier('m_item_kbw_overlord_boss_cooldown', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_overlord_boss_cooldown = ModifierClass{}

function m_item_kbw_overlord_boss_cooldown:GetTexture()
	return 'item_overlord3'
end

function m_item_kbw_overlord_boss_cooldown:RemoveOnDuel() -- custom
	return false
end

function m_item_kbw_overlord_boss_cooldown:RemoveOnDeath()
	return false
end

function m_item_kbw_overlord_boss_cooldown:IsDebuff()
	return true
end