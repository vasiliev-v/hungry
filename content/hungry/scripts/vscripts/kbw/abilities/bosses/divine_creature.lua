local sPath = "kbw/abilities/bosses/divine_creature"

boss_divine_creature = class{}

function boss_divine_creature:Precache(c)
	PrecacheResource('particle', 'particles/gameplay/effects/ascetic_cap.vpcf', c)
end

function boss_divine_creature:GetCastRange(v, h)
	return self:GetSpecialValueFor('kill_radius')
end

function boss_divine_creature:GetIntrinsicModifierName()
	return 'm_boss_divine_creature'
end

LinkLuaModifier('m_boss_divine_creature', sPath, LUA_MODIFIER_MOTION_NONE)

m_boss_divine_creature = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_boss_divine_creature:IsDeathPreventor()
	return true
end

function m_boss_divine_creature:OnCreated()
	ReadAbilityData(self, {
		'status_resist',
		'kill_radius',
		'activation_pct',
		'activation_raw',
		'self_duration',
		'attacker_duration',
		'damage_count_duration',
	})

	if IsServer() then
		local hParent = self:GetParent()
		self.tTeams = {}
		self.tCooldowns = {}

		self:StartIntervalThink(0.1)

		self.hFilter = AddPersonalFilter(hParent, 'DamageTaker', function(t)
			local hAttacker = EntIndexToHScript( t.entindex_attacker_const or -1 )
			if hAttacker then
				if not CanDamageByBossRange(hParent, hAttacker) then
					if hAttacker:IsAlive() then
						local player = hAttacker:GetPlayerOwner()
						if player then
							CustomGameEventManager:Send_ServerToPlayer(player, 'cl_show_message', {
								sText = '#KbwMsg_BossRangeDamage',
								nDuration = 2.5,
							})
						end
					end
					return false
				end

				local nOtherTeam = hAttacker:GetOpposingTeamNumber()
				if self.tTeams[nOtherTeam] then
					local nMaxDamage = hParent:GetHealth() - 100
					if t.damage >= nMaxDamage then
						local nTeam = hAttacker:GetTeam()
						local nTime = GameRules:GetGameTime()

						if not self.tCooldowns[nTeam] or nTime > self.tCooldowns[nTeam] then
							self.tCooldowns[nTeam] = nTime + 2

							CustomGameEventManager:Send_ServerToTeam(nTeam, 'cl_show_message', {
								sText = '#KbwMsg_BossBothTeams',
								nDuration = 2.5,
							})
						end

						local abi = EntIndexToHScript(t.entindex_inflictor_const or -1)

						if nMaxDamage >= 100 then
							t.damage = nMaxDamage

							
						else
							return false
						end
					end
				end

				local nTime = GameRules:GetGameTime()
				self:IncDamage(hAttacker, t.damage, nTime)
				self:IncDamage(hParent, t.damage, nTime)
			end

			return true
		end)
	end
end

function m_boss_divine_creature:OnDestroy()
	if IsServer() then
		self.hFilter:Destroy()
	end
end

function m_boss_divine_creature:OnIntervalThink()
    if IsServer() then
        local hParent = self:GetParent()

		local qEnemies = Find:UnitsInRadius{
			vCenter = hParent:GetOrigin(),
			nRadius = self.kill_radius,
			nTeam = hParent:GetTeam(),
			nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			nFilterType = DOTA_UNIT_TARGET_HERO,
			nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
						+ DOTA_UNIT_TARGET_FLAG_INVULNERABLE
						+ DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		}

		self.tTeams = {}

		for _, hEnemy in ipairs( qEnemies ) do
			if hEnemy:IsRealHero() then
				local nTeam = hEnemy:GetTeam()
				self.tTeams[nTeam] = true
			end
		end

		if self.tDamages then
			for hSource, t in pairs(self.tDamages) do
				if not exist(hSource) then
					self.tDamages[hSource] = nil
				end
			end
		end
    end
end

function m_boss_divine_creature:CheckState()
	return {
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
	}
end

function m_boss_divine_creature:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

function m_boss_divine_creature:GetModifierStatusResistanceStacking()
	return self.status_resist
end

function m_boss_divine_creature:IncDamage(hSource, nDamage, nTime)
	if hSource:HasModifier('m_boss_divine_creature_purge') then
		return
	end

	if not self.tDamages then
		self.tDamages = {}
	end

	local t = self.tDamages[hSource]
	if not t then
		t = {
			nDamage = 0,
			nExpire = 0,
		}
		self.tDamages[hSource] = t
	end

	if nTime > t.nExpire then
		t.nDamage = 0
	end

	local hParent = self:GetParent()
	t.nDamage = t.nDamage + nDamage
	t.nExpire = nTime + self.damage_count_duration

	if t.nDamage >= self.activation_raw + hParent:GetMaxHealth() * self.activation_pct / 100 then
		t.nDamage = 0
		if hSource ~= hParent then
			hSource:RemoveModifierByName('modifier_tusk_snowball_movement')
			hSource:RemoveModifierByName('modifier_tusk_snowball_movement_friendly')
		end
		hSource:AddNewModifier(hParent, self:GetAbility(), 'm_boss_divine_creature_purge', {
			duration = (hSource == hParent) and self.self_duration or self.attacker_duration,
		})
	end
end

LinkLuaModifier('m_boss_divine_creature_purge', sPath, LUA_MODIFIER_MOTION_NONE)

m_boss_divine_creature_purge = ModifierClass{
}

function m_boss_divine_creature_purge:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function m_boss_divine_creature_purge:GetModifierMagicalResistanceBonus()
	return self.mag_resist
end

function m_boss_divine_creature_purge:OnCreated()
	ReadAbilityData(self, {
		'mag_resist',
	})

	if IsServer() then
		self.hParent = self:GetParent()
		self.bDebuff = (self.hParent ~= self:GetCaster())

		self:OnIntervalThink()
		self:StartIntervalThink(1/30)

		self.nParticle = ParticleManager:Create('particles/gameplay/effects/ascetic_cap.vpcf', PATTACH_ABSORIGIN_FOLLOW, self.hParent)
		ParticleManager:SetParticleControlEnt(self.nParticle, 0, self.hParent, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), false)
		ParticleManager:SetParticleControl(self.nParticle, 17, self.bDebuff and Vector(-0.3,0.6,0) or Vector(0.5,0,0))

		self.hParent:EmitSound('DOTA_Item.Nullifier.Cast')
	end
end

function m_boss_divine_creature_purge:OnDestroy()
	if IsServer() then
		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_boss_divine_creature_purge:OnIntervalThink()
	if self.bDebuff then
		for _, hMod in ipairs(self.hParent:FindAllModifiers()) do
			if hMod:GetDuration() > 0 then
				local tState = {}
				hMod:CheckStateToTable(tState)
				if tState[tostring(MODIFIER_STATE_ATTACK_IMMUNE)]
				and not tState[tostring(MODIFIER_STATE_INVULNERABLE)]
				and not tState[tostring(MODIFIER_STATE_OUT_OF_GAME)] then
					hMod:Destroy()
				end
			end
		end
		self.hParent:RemoveModifierByName('modifier_dazzle_shallow_grave')
		self.hParent:RemoveModifierByName('modifier_oracle_false_promise')
		self.hParent:RemoveModifierByName('modifier_death_prophet_spirit_siphon')
		self.hParent:RemoveModifierByName('modifier_tusk_snowball_movement')
		self.hParent:RemoveModifierByName('modifier_tusk_snowball_movement_friendly')
	else
		self.hParent:Purge(false, true, false, true, true)
		self.hParent:RemoveModifierByName('modifier_ursa_fury_swipes_damage_increase')
		self.hParent:RemoveModifierByName('modifier_huskar_burning_spear_debuff')
		self.hParent:RemoveModifierByName('modifier_tusk_walrus_kick_air_time')
		self.hParent:RemoveModifierByName('m_halberd_disarm')
	end
end