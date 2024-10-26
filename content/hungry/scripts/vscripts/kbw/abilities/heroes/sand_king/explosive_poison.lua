local sPath = "kbw/abilities/heroes/sand_king/explosive_poison"
LinkLuaModifier('m_sand_king_explosive_poison', sPath, 0)
LinkLuaModifier('m_sand_king_explosive_poison_debuff', sPath, 0)

sand_king_explosive_poison = class{}

function sand_king_explosive_poison:GetIntrinsicModifierName()
	return 'm_sand_king_explosive_poison'
end

m_sand_king_explosive_poison = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_sand_king_explosive_poison:OnCreated(t)
	if IsServer() then
		self:OnRefresh(t)

		self:RegisterSelfEvents()
	end
end

function m_sand_king_explosive_poison:OnRefresh(t)
	ReadAbilityData(self, {'duration'})
end

function m_sand_king_explosive_poison:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_sand_king_explosive_poison:OnParentAttackLanded(t)
	if exist(t.target) and t.target:IsBaseNPC() and UnitFilter(t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
		0, t.attacker:GetTeam()
	) == UF_SUCCESS then
		AddModifier('m_sand_king_explosive_poison_debuff', {
			hTarget = t.target,
			hCaster = t.attacker,
			hAbility = self:GetAbility(),
			duration = self.duration,
		})
	end
end

m_sand_king_explosive_poison_debuff = ModifierClass{
	bPurgable = true,
}

function m_sand_king_explosive_poison_debuff:DestroyOnExpire()
	return false
end

function m_sand_king_explosive_poison_debuff:OnCreated(t)
	self.hParent = self:GetParent()
	self.hCaster = self:GetCaster()
	self:OnRefresh(t)

	if IsServer() then
		self.nDamage = 0

		self:StartIntervalThink(self.damage_interval)

		self.nParticle = ParticleManager:Create('particles/units/heroes/hero_sandking/sandking_caustic_finale_debuff.vpcf', PATTACH_ABSORIGIN_FOLLOW, self.hParent)
	end
end

function m_sand_king_explosive_poison_debuff:OnRefresh(t)
	ReadAbilityData(self, {
		'duration',
		'damage',
		'max_hp_damage',
		'slow',
		'radius',
		'damage_interval',
	}, function(hAbility)
		if IsServer() then
			self.hAbility = hAbility
			self.nDamageType = hAbility:GetAbilityDamageType()

			if IsBoss(self.hParent) then
				self.max_hp_damage = hAbility:GetSpecialValueFor('boss_max_hp_damage')
			end

			if self.bExpireNext then
				self.bExpireNext = nil
				self:StartIntervalThink(self.damage_interval)
			end
		end
	end)
end

function m_sand_king_explosive_poison_debuff:OnIntervalThink()
	if IsServer() then
		if self.bExpireNext then
			self.bExploeded = true
			self:Explode()
			self:Destroy()
		else
			if exist(self.hCaster) then
				local nDamage = self.damage + self.hParent:GetMaxHealth() * self.max_hp_damage / 100
				nDamage = nDamage * self.damage_interval
				self.nDamage = self.nDamage + nDamage

				ApplyDamage({
					victim = self.hParent,
					attacker = self.hCaster,
					ability = self.hAbility,
					damage = nDamage,
					damage_type = self.nDamageType,
				})
			end

			local nTime = math.max(1/30, self:GetRemainingTime())
			if nTime < self.damage_interval then
				self.bExpireNext = true
				self:StartIntervalThink(nTime)
			end
		end
	end
end

function m_sand_king_explosive_poison_debuff:Explode()
	if not exist(self.hCaster) then
		return
	end

	if not self.hParent:IsMagicImmune() then
		ApplyDamage({
			victim = self.hParent,
			attacker = self.hCaster,
			ability = self.hAbility,
			damage = self.nDamage,
			damage_type = self.nDamageType,
		})
	end

	local bInflict = not self.hParent:IsAlive()

	local qUnits = Find:UnitsInRadius({
		vCenter = self.hParent,
		nRadius = self.radius,
		nTeam = self.hCaster:GetTeam(),
		nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		nFilterType = DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
		nFilterFlag = 0,
	})

	for _, hUnit in ipairs(qUnits) do
		if hUnit ~= self.hParent then
			ApplyDamage({
				victim = hUnit,
				attacker = self.hCaster,
				ability = self.hAbility,
				damage = self.nDamage,
				damage_type = self.nDamageType,
			})

			if bInflict and hUnit:IsAlive() then
				AddModifier('m_sand_king_explosive_poison_debuff', {
					hTarget = hUnit,
					hCaster = self.hCaster,
					hAbility = self.hAbility,
					duration = self.duration,
				})
			end
		end
	end

	local nParticle = ParticleManager:Create('particles/units/heroes/hero_sandking/explosive_poison/explosion.vpcf', PATTACH_WORLDORIGIN, 2)
	ParticleManager:SetParticleControl(nParticle, 0, self.hParent:GetOrigin())
	ParticleManager:SetParticleControl(nParticle, 1, Vector(self.radius, 0, 0))
	ParticleManager:SetParticleControl(nParticle, 17, Vector(0.2, 0, 0))

	self.hParent:EmitSound('Ability.SandKing_CausticFinale')
end

function m_sand_king_explosive_poison_debuff:OnDestroy()
	if IsServer() then
		if not self.bExploeded and not self.hParent:IsAlive() then
			self:Explode()
		end

		ParticleManager:Fade(self.nParticle, true)
	end
end

function m_sand_king_explosive_poison_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function m_sand_king_explosive_poison_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end