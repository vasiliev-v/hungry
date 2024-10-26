item_gem_kbw = class{}

function item_gem_kbw:GetIntrinsicModifierName()
	return 'm_mult'
end

function item_gem_kbw:GetMultModifiers()
	if self:GetParent():NotRealHero() then
		return
	end

	return {
		m_custom_truesight = -1,
	}
end

function item_gem_kbw:GetCastRange()
	return self:GetSpecialValueFor('radius')
end

function item_gem_kbw:OnAddMultModifier(hModifier, sModifier)
	if sModifier == 'm_custom_truesight' then
		hModifier.radius = self:GetSpecialValueFor('radius')
	end
end

function item_gem_kbw:Spawn()
	if IsServer() then
		local bSpawned = true
		local genkey = 'GemTeams.' .. self:entindex()

		Timer(0.1, function()
			if not exist(self) then
				GenTable:SetAll(genkey, nil)
				return
			end

			if self:GetContainer() then
				if not self.bDrop and self.nTeam then
					self:CheckDrop(self.nTeam)
				end
			else
				local hCaster = self:GetCaster()
				if hCaster and not hCaster:IsIllusion() and not hCaster:NotRealHero() then
					local bAlive = hCaster:IsAlive() or hCaster:IsReincarnating()

					local nTeam = hCaster:GetTeam()
					if self.nTeam ~= nTeam then
						self.nTeam = nTeam
						GenTable:SetAll(genkey, self.nTeam)
					end

					if bAlive or bSpawned then
						self.nLastSlot = self:GetItemSlot()
						self:SetPurchaser(hCaster)
						if bAlive then
							bSpawned = false
						end
					elseif self.nLastSlot and not IsStash(self.nLastSlot) then
						hCaster:DropItemAtPositionImmediate(self, hCaster:GetOrigin())
					end
				end
			end

			return 0.1
		end)
	end
end

function item_gem_kbw:CheckDrop(nTeam)
	local hContainer = self:GetContainer()
	if hContainer then
		self.bDrop = true

		local vPos = hContainer:GetOrigin()
		local nRadius = self:GetSpecialValueFor('radius')

		local hFountain = FOUNTAINS[nTeam]
		local hThinker
		local hAura
		if hFountain then
			hThinker = CreateModifierThinker(
				hFountain,
				self,
				'm_custom_truesight',
				{radius = nRadius},
				vPos,
				nTeam,
				false
			)

			hAura = CreateAura{
				sModifier = 'm_dropped_gem_display',
				bNoStack = true,
				hUnit = hFountain,
				vCenter = vPos,
				nRadius = nRadius,
				nTeam = nTeam,
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				nFilterType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				nFilterFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			}
		end

		local nParticle = ParticleManager:CreateParticleForTeam(
			'particles/items_fx/gem_truesight_aura_edge.vpcf',
			PATTACH_WORLDORIGIN,
			nil,
			nTeam
		)
		ParticleManager:SetParticleControl(nParticle, 0, vPos)
		ParticleManager:SetParticleControl(nParticle, 1, Vector(nRadius, 0, 0))
		ParticleManager:SetParticleFoWProperties(nParticle, 0, 0, nRadius)

		self:SetPurchaser(nil)

		Timer(function()
			if exist(hContainer) then
				AddFOWViewer(nTeam, hContainer:GetOrigin(), nRadius, 0.6, false)
				return 0.5
			end

			if exist(hThinker) then
				hThinker:Destroy()
			end

			if exist(hAura) then
				hAura:Destroy()
			end

			ParticleManager:Fade(nParticle, true)

			self.bDrop = false
		end)
	end
end



LinkLuaModifier('m_dropped_gem_display', "kbw/items/shard_of_true_sight.lua", LUA_MODIFIER_MOTION_NONE)
m_dropped_gem_display = ModifierClass{}

function m_dropped_gem_display:IsDebuff()
	return true
end

function m_dropped_gem_display:GetTexture()
	return 'item_gem'
end



item_shard_of_true_sight = item_shard_of_true_sight or class({}) 
LinkLuaModifier("m_shard_of_true_sight", "kbw/items/shard_of_true_sight.lua", LUA_MODIFIER_MOTION_NONE)

function item_shard_of_true_sight:OnSpellStart()
	if not IsServer() then return end
    local caster = self:GetCaster()
    if not caster:IsRealHero() then return end
	if caster:HasModifier('m_shard_of_true_sight') then return end
    
    local radius = self:GetSpecialValueFor('radius')
    
    caster:AddNewModifier(caster, nil, "m_shard_of_true_sight", { radius = radius });
    
    EmitSoundOnClient("Item.MoonShard.Consume", PlayerResource:GetPlayer(caster:GetPlayerID()))
    caster:RemoveItem(self)
end

m_shard_of_true_sight = ModifierClass{
	bPermanent = true,
}

function m_shard_of_true_sight:GetTexture()
    return "item_shard_of_true_sight"
end

function m_shard_of_true_sight:OnCreated(t)
    if IsServer() then
        self.hTruesight = self:GetParent():AddNewModifier(self:GetParent(), nil, "m_custom_truesight", {radius = t.radius})    
    
		self:RegisterSelfEvents()
	end
end

function m_shard_of_true_sight:OnDestroy()
    if IsServer() then
		if exist(self.hTruesight) then
			self.hTruesight:Destroy()
		end

		local hParent = self:GetParent()
        local hItem = CreateItem('item_gem_kbw', nil, nil)
		hItem.nTeam = hParent:GetTeam()
		CreateItemOnPositionSync(hParent:GetOrigin(), hItem)

		self:UnregisterSelfEvents()
    end
end

function m_shard_of_true_sight:OnParentDead()
	if not self:GetParent():IsReincarnating() then
		self:Destroy()
	end
end