require 'lib/lua/base'
require 'lib/m_mult'
require 'lib/modifier_self_events'
require 'lib/particle_manager'

local sPath = "kbw/items/levels/octarine"
LinkLuaModifier( 'm_item_kbw_octarine_stats', sPath, 0 )
LinkLuaModifier( 'm_item_kbw_octarine', sPath, 0 )

local RAW_CAST = {
	puck_phase_shift = 1,
	item_blink = 1,
	item_swift_blink = 1,
	item_swift_blink2 = 1,
	item_swift_blink3 = 1,
	item_arcane_blink = 1,
	item_arcane_blink2 = 1,
	item_arcane_blink3 = 1,
	item_overwhelming_blink = 1,
	item_overwhelming_blink2 = 1,
	item_overwhelming_blink3 = 1,
}

local EXCEPT = {
	monkey_king_tree_dance = 1,
}

local levels = {
	'item_kbw_octarine',
	'item_kbw_octarine_2',
	'item_kbw_octarine_3',
}

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_kbw_octarine_stats = 0,
		m_item_kbw_octarine = self.nLevel,
	}
end

----------------------------------------------------------
-- toggle

function base:OnToggle()
	if not self:GetCaster():IsAlive() then
		return
	end

	self.toggle = self:GetToggleState()

	ToggleItems(self, levels, false)
end

function base:GetAbilityTextureName()
	local base = self.BaseClass.GetAbilityTextureName(self)
	if self:GetToggleState() then
		return base .. '_active'
	end
	return base
end

----------------------------------------------------------
-- levels

CreateLevels(levels, base)

----------------------------------------------------------
-- passive stackable

m_item_kbw_octarine_stats = ModifierClass{
	bMultiple = true,
	bPermanent = true,
	bHidden = true,
}

function m_item_kbw_octarine_stats:OnCreated()
	ReadAbilityData( self, {
		'hp',
		'mp',
		'mp_regen',
	})

	if IsServer() then
		local ability = self:GetAbility()
		if ability then
			ToggleItems(ability, levels, true, ability.toggle == nil and true or ability.toggle)
		end
	end
end

function m_item_kbw_octarine_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
end

function m_item_kbw_octarine_stats:GetModifierHealthBonus()
	return self.hp
end

function m_item_kbw_octarine_stats:GetModifierManaBonus()
	return self.mp
end

function m_item_kbw_octarine_stats:GetModifierConstantManaRegen()
	return self.mp_regen
end

----------------------------------------------------------
-- passive unique

m_item_kbw_octarine = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_item_kbw_octarine:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
end

function m_item_kbw_octarine:GetModifierPercentageCooldown()
	return self.cdr
end

function m_item_kbw_octarine:OnCreated()
	ReadAbilityData( self, {
		'cdr',
		'single_cdr',
		'own_cd_pct',
	})

	if IsServer() then
		self.check = {}
		self.ability = self:GetAbility()
		self.parent = self:GetParent()

		self:StartIntervalThink(FrameTime())
		self:RegisterSelfEvents()
	end
end

function m_item_kbw_octarine:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

-- single cdr

function m_item_kbw_octarine:OnIntervalThink()
	if not IsServer() then
		return
	end

	if not self.ability then
		return
	end

	-- gaben dolbaeb + clown
	if self.ability.toggle ~= self.ability:GetToggleState() then
		self.ability:ToggleAbility()
	end

	local check = {}
	local cd_ready = (self.ability:GetCooldownTimeRemaining() == 0)

	if cd_ready then
		local skip = self.ability.toggle
		local skiped = false

		local function check_cooldown(spell)
			if not spell then
				return
			end

			local name = spell:GetName()
			if RAW_CAST[name] or EXCEPT[name] then
				return
			end

			local cooldown = spell:GetCooldownTimeRemaining()

			if self.check[spell] and cooldown > self.check[spell] and skip and not skiped then
				skiped = true
				self:SkipCooldown(spell)
			end

			check[spell] = cooldown
		end

		for i = 0, self.parent:GetAbilityCount() - 1 do
			check_cooldown(self.parent:GetAbilityByIndex(i))
		end

		IterateInventory(self.parent, 'INVENTORY', function(slot, item)
			check_cooldown(item)
		end)
	end

	self.check = check
end

function m_item_kbw_octarine:OnParentAbilityFullyCast(t)
	if not exist(t.ability) then
		return
	end

	local name = t.ability:GetName()
	if not RAW_CAST[name] or EXCEPT[name] then
		return
	end

	if self.ability.toggle and self.ability:GetCooldownTimeRemaining() == 0 then
		self:SkipCooldown(t.ability)
	end
end

function m_item_kbw_octarine:SkipCooldown(spell)
	local name = spell:GetName()
	local delay = (name == 'void_spirit_resonant_pulse') and FrameTime() or 0
	local cooldown = spell:GetCooldownTimeRemaining()

	self.ability:StartCooldown(cooldown * self.own_cd_pct / 100)

	Timer(delay, function()
		if not exist(spell) then
			return
		end

		if delay > 0 then
			cooldown = spell:GetCooldownTimeRemaining()

			self.ability:EndCooldown()
			self.ability:StartCooldown(cooldown * self.own_cd_pct / 100 - delay)
		end

		spell:EndCooldown()
		spell:StartCooldown(cooldown * (100 - self.single_cdr) / 100 - delay)
	end)
end