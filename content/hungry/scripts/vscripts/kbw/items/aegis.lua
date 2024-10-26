LinkLuaModifier('m_item_aegis_essence', "kbw/items/aegis", 0)
LinkLuaModifier('m_item_aegis_essence_reborn', "kbw/items/aegis", 0)

item_aegis_essence = class{}

function item_aegis_essence:OnPickupCustom(hUnit)
	AddModifier('m_item_aegis_essence', {
		hTarget = hUnit,
		hCaster = hUnit,
		duration = self:GetSpecialValueFor('essence_duration'),
		invuln_duration = self:GetSpecialValueFor('invuln_duration'),
		reincarnation_time = self:GetSpecialValueFor('reincarnation_time'),
		vision_radius = self:GetSpecialValueFor('vision_radius'),
	})

	RemoveWithContainer(self)

	return true
end

--------------------------------------

m_item_aegis_essence = ModifierClass{}

function m_item_aegis_essence:RemoveOnDuel() -- custom
	return false
end

function m_item_aegis_essence:RemoveOnDeath()
	return false
end

function m_item_aegis_essence:GetTexture()
	return 'item_aegis'
end

function m_item_aegis_essence:IsHidden()
	return self:GetStackCount() > 0
end

function m_item_aegis_essence:IsReincarnation()
	return self:GetStackCount() == 1
end

function m_item_aegis_essence:OnCreated(t)
	self:OnRefresh(t)

	if IsServer() then
		self:RegisterSelfEvents()

		self.aListeners = {
			Events:Register('KbwDuelStart', function()
				if not self:IsReincarnation() then
					self.nRemTime = self:GetRemainingTime()
					self:SetDuration(-1, true)
					self:SetStackCount(2)
				end
			end),

			Events:Register('KbwDuelEnd', function()
				if not self:IsReincarnation() then
					self:SetDuration(self.nRemTime, true)
					self:SetStackCount(0)
				end
			end)
		}
	end
end

function m_item_aegis_essence:OnRefresh(t)
	if IsServer() then
		self.nRemTime = self:GetRemainingTime()
		self.invuln_duration = t.invuln_duration
		self.reincarnation_time = t.reincarnation_time
		self.vision_radius = t.vision_radius
	end
end

function m_item_aegis_essence:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()

		for _, hListener in ipairs(self.aListeners) do
			if exist(hListener) then
				hListener:Destroy()
			end
		end
		self.aListeners = {}
	end
end

function m_item_aegis_essence:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_REINCARNATION,
	}
end

function m_item_aegis_essence:ReincarnateTime()
	if IsClient() or _G.DUEL or self.getting_ReincarnateTime then
		return
	end

	self.getting_ReincarnateTime = true
	local other_reinc = self:GetParent():WillReincarnate()
	self.getting_ReincarnateTime = nil

	if other_reinc then
		return
	end

	self.last_check = GameRules:GetGameTime()

	return self.reincarnation_time
end

function m_item_aegis_essence:OnParentDead(t)
	if GameRules:GetGameTime() ~= self.last_check then
		return
	end

	local hParent = self:GetParent()
	local vPos = hParent:GetOrigin()

	hParent:SetTimeUntilRespawn(self.reincarnation_time)

	self:SetStackCount(1)
	self:SetDuration(-1, true)

	AddFOWViewer(hParent:GetTeam(), vPos, self.vision_radius, self.reincarnation_time, false)

	Timer(self.reincarnation_time - 0.35, function()
		local sParticle = 'particles/items_fx/aegis_respawn.vpcf'
		local nParticle = ParticleManager:Create(sParticle, hParent, PATTACH_ABSORIGIN_FOLLOW, 3)
		ParticleManager:SetParticleControlEnt(nParticle, 0, hParent, PATTACH_ABSORIGIN_FOLLOW, nil, vPos, false)
	end)

	local nParticle = ParticleManager:Create('particles/items_fx/aegis_timer.vpcf')
	ParticleManager:SetParticleControl(nParticle, 0, vPos)
	ParticleManager:SetParticleControl(nParticle, 1, Vector(self.reincarnation_time, 0, 0))

	EmitSoundOnLocationWithCaster(vPos, 'Aegis.Timer', hParent)
end

function m_item_aegis_essence:OnParentRespawn(t)
	if self:IsReincarnation() then
		local hParent = t.unit

		self:Destroy()

		AddModifier('m_item_aegis_essence_reborn', {
			hTarget = hParent,
			hCaster = hParent,
			duration = self.invuln_duration,
		})

		hParent:EmitSoundParams('Hero_Phoenix.SuperNova.Explode', 1.5, 1, 0)
	end
end

--------------------------------------

m_item_aegis_essence_reborn = ModifierClass{}

function m_item_aegis_essence_reborn:GetTexture()
	return 'item_aegis'
end

function m_item_aegis_essence_reborn:GetStatusEffectName()
	return 'particles/items/angel_wings/status.vpcf'
end

function m_item_aegis_essence_reborn:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end