local PATH = 'kbw/items/hollow_ring'

LinkLuaModifier('m_item_kbw_magic_stick', 'kbw/items/magic_stick', LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------
-- item

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_generic_stats = 0,
		m_item_generic_armor = 0,
		m_item_kbw_magic_stick = 0,
	}
end

function base:GetBehavior()
	if self:GetCaster():HasModifier('m_item_kbw_hollow_ring_charge') then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_DIRECTIONAL
	end
	return self.BaseClass.GetBehavior(self)
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local charge = caster:FindModifierByName('m_item_kbw_hollow_ring_charge')
	
	-- recast
	if charge then
		charge:Destroy()
		caster:RemoveModifierByName('m_item_kbw_hollow_ring_active')
		
		if not charge.damage or charge.damage < self:GetSpecialValueFor('overfill_min_damage')
		or not charge.damage_table or table.size(charge.damage_table) == 0 then
			return
		end
		
		local pos = self:GetCursorPosition()
		local dir = CasterDirection(caster, pos)
		local range = self:GetEffectiveCastRange(pos, nil)
		local speed = self:GetSpecialValueFor('overfill_wave_speed')
		local radius = self:GetSpecialValueFor('overfill_wave_radius')
		local vision = self:GetSpecialValueFor('overfill_wave_vision')
		local team = caster:GetTeam()
		
		-- projectile with data not supported for items. need to create manual
		
		local affected = {}
		local start = caster:GetOrigin()
		local pos = start
		local visionpos, viewer
		
		local particle = ParticleManager:Create('particles/items/hollow_ring/wave.vpcf')
		ParticleManager:SetParticleFoWProperties(particle, 0, 0, vision)
		ParticleManager:SetParticleControl(particle, 0, start)
		ParticleManager:SetParticleControlForward(particle, 0, dir)
		ParticleManager:SetParticleControl(particle, 1, dir * speed)
		ParticleManager:SetParticleControl(particle, 17, Vector(0.75, 0, 0))
		
		caster:EmitSound('Kbw.Items.HollowRing.Wave.Start')
		
		Timer(function(dt)
			local delta = math.min(range, speed * dt)
			local newpos = pos + dir * delta
			range = range - delta
			
			if not visionpos or (visionpos - newpos):Length2D() >= vision * 0.8 then
				if viewer then
					RemoveFOWViewer(team, viewer)
				end
				visionpos = newpos
				viewer = AddFOWViewer(team, newpos, vision, 99999, false)
			end
		
			local units = FindUnitsInLine(
				team,
				pos,
				newpos,
				nil,
				radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			)
			
			for _, unit in ipairs(units) do
				local unitpos = unit:GetOrigin()
				if #(unitpos - start):Cross(dir) > 0 then -- check unit is not behind
					if not affected[unit] then
						affected[unit] = true
						
						for damage_type, damage in pairs(charge.damage_table) do
							if damage_type ~= DAMAGE_TYPE_MAGICAL or not unit:IsMagicImmune() then
								ApplyDamage({
									victim = unit,
									attacker = caster,
									ability = self,
									damage = damage,
									damage_type = damage_type,
									damage_flags =
										DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS +
										DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
								})
							end
						end
						
						unit:EmitSound('Kbw.Items.HollowRing.Wave.Hit')
					end
				end
			end
			
			if range <= 0 then
				RemoveFOWViewer(team, viewer)
				ParticleManager:Fade(particle, true)
				return
			end
			
			pos = newpos
			return Timer.MIN
		end)
		
	-- initial cast
	else
		local hp_cost = self:GetSpecialValueFor('overfill_hp_cost')
		local mp_refill = self:GetSpecialValueFor('overfill_mp')
		local duration = self:GetSpecialValueFor('overfill_duration')
		
		caster:ModifyHealth(caster:GetHealth() * (100 - hp_cost) / 100, nil, false, 0)
		
		local mp_miss = caster:GetMaxMana() - caster:GetMana()
		caster:GiveMana(mp_miss * mp_refill / 100)
		
		AddModifier('m_item_kbw_hollow_ring_active', {
			hTarget = caster,
			hCaster = caster,
			hAbility = self,
			duration = duration,
		})
		
		caster:EmitSound('DOTA_Item.EssenceRing.Cast')
		
		self:EndCooldown()
		self:StartCooldown(0.5)
	end
end

function base:GetAbilityTextureName()
	local texture = self.BaseClass.GetAbilityTextureName(self)
	if self:GetCaster():HasModifier('m_item_kbw_hollow_ring_charge') then
		texture = texture .. '_active'
	end
	return texture
end

---------------------------------------------------
-- levels

CreateLevels({
	"item_kbw_hollow_ring",
	"item_kbw_hollow_ring_2",
	"item_kbw_hollow_ring_3",
}, base)

---------------------------------------------------
-- modifier: active charging

LinkLuaModifier('m_item_kbw_hollow_ring_active', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_hollow_ring_active = ModifierClass{
}

function m_item_kbw_hollow_ring_active:OnCreated()
	ReadAbilityData(self, {
		'overfill_damage_convert',
		'overfill_min_damage',
	})
	
	if IsServer() then
		local parent = self:GetParent()
		
		self.charge = parent:AddNewModifier(self:GetCaster(), self:GetAbility(), 'm_item_kbw_hollow_ring_charge', {})
		self.charge.damage_table = {}
		self.damage = 0
		
		self:RegisterSelfEvents()
		
		local particles = {}
		for i = 1, 2 do
			local particle = ParticleManager:Create('particles/items/hollow_ring/buff.vpcf', PATTACH_CUSTOMORIGIN, parent)
			table.insert(particles, particle)
		end
		local angle = RandomFloat(0, 360)
		local rotation = 400
		local offset = 100
		
		Timer(function(dt)
			if not exist(self) or not exist(parent) then
				for i, particle in ipairs(particles) do
					ParticleManager:Fade(particle, true)
				end
				return
			end
			
			angle = angle + rotation * dt
			for i, particle in ipairs(particles) do
				local a = (angle + i*180) * math.pi / 180
				local pos = GetAttachmentOrigin(parent, 'attach_hitloc') + Vector(math.cos(a), math.sin(a), 0) * offset
				ParticleManager:SetParticleControl(particle, 0, pos)
			end
			
			return Timer.MIN
		end)
	end
end

function m_item_kbw_hollow_ring_active:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
		
		if exist(self.charge) and self.damage < self.overfill_min_damage then
			self.charge:Destroy()
		end
	end
end

function m_item_kbw_hollow_ring_active:OnParentDealDamage(t)
	if t.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
		if not exist(self.charge) then
			self:Destroy()
			return
		end
		
		if t.inflictor and t.inflictor:GetName():match('item_kbw_hollow_ring') then
			return
		end
		
		local converted = t.original_damage * self.overfill_damage_convert / 100
		self.damage = self.damage + converted
		local stacks = math.floor(self.damage / 100)
		
		self:SetStackCount(stacks)
		self.charge:SetStackCount(stacks)
		self.charge.damage = self.damage
		
		self.charge.damage_table[t.damage_type] = (self.charge.damage_table[t.damage_type] or 0) + converted
	end
end

---------------------------------------------------
-- modifier: active chared

LinkLuaModifier('m_item_kbw_hollow_ring_charge', PATH, LUA_MODIFIER_MOTION_NONE)
m_item_kbw_hollow_ring_charge = ModifierClass{
}

function m_item_kbw_hollow_ring_charge:IsHidden()
	return self:GetParent():HasModifier('m_item_kbw_hollow_ring_active')
end