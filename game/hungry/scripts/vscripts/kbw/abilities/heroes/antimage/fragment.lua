local sPath = "kbw/abilities/heroes/antimage/fragment"

antimage_fragment_kbw = class{}

antimage_fragment_kbw.bScepterGranted = true

function antimage_fragment_kbw:Spawn()
	if IsServer() then
		self.tUnits = {}
		self:SetLevel(1)
	end
end

function antimage_fragment_kbw:GetIntrinsicModifierName()
	return 'm_antimage_fragment_kbw_tracker'
end

function antimage_fragment_kbw:OnStolen(hSource)
	self.hBlink = hSource:GetCaster():FindAbilityByName('antimage_blink')
end

function antimage_fragment_kbw:GetCastRange(v, h)
	local hBlink = self:GetCaster():FindAbilityByName('antimage_blink') or self.hBlink
	if hBlink then
		return math.max(500, hBlink:GetSpecialValueFor('blink_range'))
	end
	return 500
end

function antimage_fragment_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	local vTarget = self:GetCursorPosition()
	local vStart = hCaster:GetOrigin()
	local nPlayer = hCaster:GetPlayerOwnerID()
	local sUnit = hCaster:GetUnitName()
	local nLevel = hCaster:GetLevel()

	local t = GetUnitKeyValuesByName(sUnit)
	local hUnit = SpawnEntityFromTableSynchronous('npc_dota_hero', t)

	self.tUnits[hUnit] = true

	for _, hChild in ipairs(hUnit:GetChildren()) do
		if hChild:GetClassname() == 'dota_item_wearable' and hChild:GetModelName() == '' then
			hChild:Destroy()
		end
	end

	hUnit.bPreventCast = true
	hUnit.bClone = true
	hUnit:SetUnitName('npc_dota_hero_antimage')
	hUnit:SetTeam(hCaster:GetTeam())
	hUnit:SetOwner(hCaster:GetPlayerOwner())
	hUnit:SetPlayerID(nPlayer)
	hUnit:SetControllableByPlayer(nPlayer, false)

	for i = 2, nLevel do
		hUnit:HeroLevelUp(false)
	end
	hUnit:SetAbilityPoints(0)

	for i = 0, hUnit:GetAbilityCount() - 1 do
		local hAbility = hUnit:GetAbilityByIndex(i)
		if hAbility then
			hSource = hCaster:FindAbilityByName(hAbility:GetName())
			if hSource then
				hAbility:SetLevel(hSource:GetLevel())
			end
		end
	end

	IterateInventory(hCaster, 'INVENTORY', function(nSlot, hItem)
		if hItem and nSlot ~= DOTA_ITEM_TP_SCROLL then
			local bActive = IsActive(nSlot)
			if bActive then
				hUnit:SwapItems(DOTA_ITEM_SLOT_1, nSlot)
			end
			local hCopy = hUnit:AddItemByName(hItem:GetName())
			if hCopy then
				hCopy:SetCombineLocked(hItem:IsCombineLocked())
				hCopy:SetCurrentCharges(hItem:GetCurrentCharges())
				hCopy:SetSecondaryCharges(hItem:GetSecondaryCharges())
				if not bActive then
					hUnit:SwapItems(hCopy:GetItemSlot(), nSlot)
				end
			end
			if bActive then
				hUnit:SwapItems(DOTA_ITEM_SLOT_1, nSlot)
			end
		end
	end)

	for _, hMod in ipairs(hCaster:FindAllModifiers()) do
		if hMod.AllowIllusionDuplicate and hMod:AllowIllusionDuplicate() then
			hUnit:AddNewModifier(hMod:GetCaster(), hMod:GetAbility(), hMod:GetName(), {})
		end
	end

	hUnit:SetMana(hCaster:GetMana() * hUnit:GetMaxMana() / hCaster:GetMaxMana())
	hUnit:SetHealth(hCaster:GetHealth() * hUnit:GetMaxHealth() / hCaster:GetMaxHealth())

	hUnit:AddNewModifier(hUnit, self, 'm_antimage_fragment_clone', {
		duration = self:GetSpecialValueFor('duration'),
		damage_out = self:GetSpecialValueFor('damage_out'),
		damage_in = self:GetSpecialValueFor('damage_in'),
	})

	FindClearSpaceForUnit(hUnit, vTarget, true)

	local vForward = (vTarget - vStart):Normalized()

	local nParticle = ParticleManager:Create('particles/units/heroes/hero_antimage/antimage_blink_start.vpcf', PATTACH_WORLDORIGIN, 2)
	ParticleManager:SetParticleControl(nParticle, 0, vStart)
	ParticleManager:SetParticleControlForward(nParticle, 0, vForward)

	nParticle = ParticleManager:Create('particles/units/heroes/hero_antimage/antimage_blink_end.vpcf', PATTACH_WORLDORIGIN, 2)
	ParticleManager:SetParticleControl(nParticle, 0, vTarget)
	ParticleManager:SetParticleControlForward(nParticle, 0, vForward)

	EmitSoundOnLocationWithCaster(vStart, 'Hero_Antimage.Blink_out', hUnit)
	EmitSoundOnLocationWithCaster(vTarget, 'Hero_Antimage.Blink_in', hUnit)
end

LinkLuaModifier('m_antimage_fragment_clone', sPath, LUA_MODIFIER_MOTION_NONE)

m_antimage_fragment_clone = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_antimage_fragment_clone:DestroyOnExpire()
	return false
end

function m_antimage_fragment_clone:GetStatusEffectName()
	if self:GetCaster():GetTeamNumber() == GetLocalPlayerTeam() then
		return 'particles/status_fx/status_effect_arc_warden_tempest.vpcf'
	end
end

function m_antimage_fragment_clone:OnCreated(t)
	if IsServer() then
		self.damage_out = t.damage_out - 100
		self.damage_in = t.damage_in - 100

		self:RegisterSelfEvents()
		self:StartIntervalThink(self:GetRemainingTime())
	end
end

function m_antimage_fragment_clone:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_antimage_fragment_clone:OnIntervalThink()
	if IsServer() then
		local hParent = self:GetParent()
		MakeKillable(hParent, true)
		hParent:__Kill(self:GetAbility(), self:GetCaster())

		local hAbility = self:GetAbility()
		if hAbility and hAbility.tUnits then
			hAbility.tUnits[hParent] = nil
		end
	end
end

function m_antimage_fragment_clone:OnParentDead()
	local hParent = self:GetParent()
	local vPos = hParent:GetOrigin()

	hParent:SetRespawnsDisabled(true)

	EmitSoundOnLocationWithCaster(vPos, 'General.Illusion.Destroy', hParent)

	local nParticle = ParticleManager:Create('particles/generic_gameplay/illusion_killed.vpcf', PATTACH_WORLDORIGIN, 2)
	ParticleManager:SetParticleControl(nParticle, 0, vPos)

	hParent:AddEffects(EF_NODRAW)

	Timer(3, function()
		hParent:Destroy()
	end)
end

function m_antimage_fragment_clone:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function m_antimage_fragment_clone:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_LIFETIME_FRACTION,
		MODIFIER_PROPERTY_TEMPEST_DOUBLE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function m_antimage_fragment_clone:GetUnitLifetimeFraction()
	return self:GetRemainingTime() / self:GetDuration()
end
function m_antimage_fragment_clone:GetModifierTempestDouble()
	return 1
end
function m_antimage_fragment_clone:GetModifierTotalDamageOutgoing_Percentage()
	return self.damage_out
end
function m_antimage_fragment_clone:GetModifierIncomingDamage_Percentage()
	return self.damage_in
end

LinkLuaModifier('m_antimage_fragment_kbw_tracker', sPath, LUA_MODIFIER_MOTION_NONE)

m_antimage_fragment_kbw_tracker = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_antimage_fragment_kbw_tracker:OnCreated()
	if IsServer() then
		self.hAbility = self:GetAbility()
		if self.hAbility then
			self:RegisterSelfEvents()
		end
	end
end

function m_antimage_fragment_kbw_tracker:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_antimage_fragment_kbw_tracker:OnParentAbilityFullyCast(t)
	if t.ability:GetName() == 'antimage_counterspell' then
		for hUnit in pairs(self.hAbility.tUnits or {}) do
			if exist(hUnit) then
				hUnit:StartGesture(ACT_DOTA_CAST_ABILITY_3)
				hUnit:AddNewModifier(hUnit, t.ability, 'modifier_antimage_counterspell', {
					duration = t.ability:GetSpecialValueFor('duration'),
				})
			end
		end
	end
end