LinkLuaModifier('m_monkey_king_circle_buff', "kbw/abilities/heroes/monkey_king/circle", 0)
LinkLuaModifier('m_monkey_king_circle_spell_immunity', "kbw/abilities/heroes/monkey_king/circle", 0)
LinkLuaModifier('m_monkey_king_circle_debuff', "kbw/abilities/heroes/monkey_king/circle", 0)

monkey_king_circle_kbw = class{}

function monkey_king_circle_kbw:GetAOERadius()
	return self:GetSpecialValueFor('radius')
end

function monkey_king_circle_kbw:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor('radius')
end

function monkey_king_circle_kbw:OnAbilityPhaseStart()
	local hCaster = self:GetCaster()

	local sParticle = 'particles/units/heroes/hero_monkey_king/monkey_king_fur_army_cast.vpcf'
	self.nCastParticle = ParticleManager:Create(sParticle, hCaster)
	ParticleManager:SetParticleControlEnt(self.nCastParticle, 0, hCaster, PATTACH_ABSORIGIN_FOLLOW, nil, hCaster:GetOrigin(), true)

	hCaster:EmitSound('Hero_MonkeyKing.FurArmy.Channel')

	return true
end

function monkey_king_circle_kbw:OnAbilityPhaseInterrupted()
	self:PhaseEnd(true)
end

function monkey_king_circle_kbw:PhaseEnd(bInterrupted)
	local hCaster = self:GetCaster()

	ParticleManager:Fade(self.nCastParticle, true)

	if bInterrupted then
		hCaster:StopSound('Hero_MonkeyKing.FurArmy.Channel')
	end
end

function monkey_king_circle_kbw:OnSpellStart()
	self:PhaseEnd()

	if not self.tAuras then
		self.tAuras = {}
	end

	local hCaster = self:GetCaster()
	local nTeam = hCaster:GetTeam()
	local vTarget = self:GetCursorPosition()
	local nDuration = self:GetSpecialValueFor('duration')
	local nRadius = self:GetSpecialValueFor('radius')
	local bSpellImmunity = self:GetSpecialValueFor('spell_immunity') ~= 0

	local hAura1 = CreateAura({
		sModifier = 'm_monkey_king_circle_buff',
		bNoStack = true,
		bDead = true,
		hAbility = self,
		vCenter = vTarget,
		nRadius = nRadius,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		nFilterType = DOTA_UNIT_TARGET_HERO,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		fCondition = function(hUnit)
			return hUnit == hCaster
		end,
	})

	local hAura2 = CreateAura({
		sModifier = 'm_monkey_king_circle_debuff',
		bNoStack = true,
		bDead = true,
		hAbility = self,
		vCenter = vTarget,
		nRadius = nRadius,
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
	})
	self.tAuras[hAura2] = true

	local hAura3
	if bSpellImmunity then
		hAura3 = CreateAura({
			sModifier = 'm_monkey_king_circle_spell_immunity',
			bNoStack = true,
			bDead = true,
			hAbility = self,
			vCenter = vTarget,
			nRadius = nRadius,
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			nFilterType = DOTA_UNIT_TARGET_HERO,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		})
	end

	local sParticle = 'particles/units/heroes/hero_monkey_king/circle.vpcf'
	local nParticle = ParticleManager:Create(sParticle)
	ParticleManager:SetParticleControl(nParticle, 0, vTarget)
	ParticleManager:SetParticleControl(nParticle, 1, Vector(nRadius, 0, 0))

	local hSoundMaker = CreateMarker(vTarget, nTeam)
	hSoundMaker:EmitSound('Hero_MonkeyKing.FurArmy')

	local bDuel = _G.DUEL

	Timer(function(nDT)
		nDuration = nDuration - nDT
		if nDuration > 0 and _G.DUEL == bDuel then
			return FrameTime()
		end

		hAura1:Destroy()
		hAura2:Destroy()
		self.tAuras[hAura2] = nil
		if hAura3 then
			hAura3:Destroy()
		end

		ParticleManager:Fade(nParticle, true)

		hSoundMaker:StopSound('Hero_MonkeyKing.FurArmy')
		hSoundMaker:EmitSound('Hero_MonkeyKing.FurArmy.End')
		hSoundMaker:Destroy()
	end)
end

----------------------------------------------

m_monkey_king_circle_buff = ModifierClass{
}

function m_monkey_king_circle_buff:OnCreated()
	ReadAbilityData(self, {
		'armor',
		'attributes',
	})

	if IsServer() then
		local hParent = self:GetParent()

		self.aMods = {}
		table.insert(self.aMods, AddSpecialModifier(hParent, 'nStrAmp', self.attributes))
		table.insert(self.aMods, AddSpecialModifier(hParent, 'nAgiAmp', self.attributes))
		table.insert(self.aMods, AddSpecialModifier(hParent, 'nIntAmp', self.attributes))
	end
end

function m_monkey_king_circle_buff:OnDestroy()
	if IsServer() then
		if self.aMods then
			for _, hAmp in ipairs(self.aMods) do
				hAmp:Destroy()
			end
			self.aMods = nil
		end
	end
end

function m_monkey_king_circle_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function m_monkey_king_circle_buff:GetMinHealth()
	return 1
end

function m_monkey_king_circle_buff:GetModifierPhysicalArmorBonus()
	return self.armor
end

----------------------------------------------

m_monkey_king_circle_spell_immunity = ModifierClass{
}

function m_monkey_king_circle_spell_immunity:GetStatusEffectName()
	return 'particles/status_fx/status_effect_avatar.vpcf'
end

function m_monkey_king_circle_spell_immunity:OnCreated()
	if IsServer() then
		self.nParticle = ParticleManager:Create('particles/items_fx/black_king_bar_avatar.vpcf', PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	end
end

function m_monkey_king_circle_spell_immunity:OnDestroy()
	if IsServer() then
		if self.nParticle then
			ParticleManager:Fade(self.nParticle, true)
		end
	end
end

function m_monkey_king_circle_spell_immunity:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	}
end

----------------------------------------------

m_monkey_king_circle_debuff = ModifierClass{
	bHidden = true,
}

function m_monkey_king_circle_debuff:OnCreated()
	if IsServer() then
		self:RegisterSelfEvents()
	end
end

function m_monkey_king_circle_debuff:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_monkey_king_circle_debuff:OnParentTakeDamage(t)
	if not self.bRec and t.attacker == self:GetCaster() then
		self.bRec = true

		local hAbility = self:GetAbility()
		if hAbility.tAuras then
			for hAura in pairs(hAbility.tAuras) do
				if exist(hAura) then
					for hUnit in pairs(hAura.tModifiers) do
						if exist(hUnit) and hUnit ~= t.unit then
							ApplyDamage({
								victim = hUnit,
								attacker = t.attacker,
								ability = t.inflictor,
								damage = t.original_damage,
								damage_type = t.damage_type,
							})
						end
					end
				end
			end
		end

		self.bRec = nil
	end
end