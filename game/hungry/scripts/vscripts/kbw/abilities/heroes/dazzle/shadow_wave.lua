dazzle_shadow_wave_kbw = class{}

function dazzle_shadow_wave_kbw:GetAssociatedSecondaryAbilities()
	return 'dazzle_invalid_grave'
end

function dazzle_shadow_wave_kbw:OnSpellStart()
	local hTarget = self:GetCursorTarget()
	if hTarget:TriggerSpellAbsorb(self) then
		return
	end

	local hCaster = self:GetCaster()
	local nTeam = hCaster:GetTeam()
	local nHeal = self:GetSpecialValueFor('heal')
	local nDamage = self:GetSpecialValueFor('damage')
	local nDamageType = self:GetAbilityDamageType()
	local bScepter = hCaster:HasScepter()
	
	if bScepter then
		nHeal = nHeal + hCaster:GetAverageTrueAttackDamage(nil) * self:GetSpecialValueFor('attack_heal') / 100
	end

	DoChain({
		hSource = hCaster,
		hTarget = hTarget,
		nCount = self:GetSpecialValueFor('max_targets'),
		nRadius = self:GetSpecialValueFor('bounce_radius'),
		nFilterTeam = self:GetAbilityTargetTeam(),
		nFilterType = self:GetAbilityTargetType(),
		nFilterFlag = self:GetAbilityTargetFlags(),
		nOrder = FIND_CLOSEST,
		bAffectSource = true,

		tParticleData = {
			sParticle = 'particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf',
		},
		tStartParticleData = {
			nAttach1 = 'attach_attack1',
		},

		fPriority = function(hCurrent, hNext)
			if not hCurrent:IsConsideredHero() and hNext:IsConsideredHero() then
				return hNext
			end
			return hCurrent
		end,

		fCallback = function(hTarget)
			local applier = hCaster:FindAbilityByName('dazzle_invalid_grave')
			if applier then
				if not applier:IsTrained() then
					applier:SetLevel(1)
				end
				SpellCaster:Cast(applier, hTarget)
				
				local grave = hTarget:FindModifierByName('modifier_dazzle_shallow_grave')
				if grave and grave:GetRemainingTime() <= 0 then
					grave:Destroy()
				end
			end
		
			if hTarget:GetTeam() == nTeam then
				hTarget:Heal(nHeal, self)
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, hTarget, nHeal, nil)
			else
				if bScepter then
					AddFlag(hCaster, 'perform_attack', 1)
					hCaster:PerformAttack(hTarget, true, true, true, true, false, false, true)
					AddFlag(hCaster, 'perform_attack', -1)
				end
			
				ApplyDamage({
					victim = hTarget,
					attacker = hCaster,
					ability = self,
					damage = nDamage,
					damage_type = nDamageType,
					damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
				})
			end
		end,
	})

	hCaster:EmitSound('Hero_Dazzle.Shadow_Wave')
end

LinkLuaModifier('m_dazzle_shadow_wave_kbw_counter', "kbw/abilities/heroes/dazzle/shadow_wave", LUA_MODIFIER_MOTION_NONE)
m_dazzle_shadow_wave_kbw_counter = ModifierClass{
	bPermanent = true,
}

function m_dazzle_shadow_wave_kbw_counter:GetTexture()
	return 'dazzle_shadow_wave'
end

function m_dazzle_shadow_wave_kbw_counter:OnCreated(t)
	if IsServer() then
		self.proc_attacks = t.proc_attacks
		
		self:RegisterSelfEvents()
	end
end

function m_dazzle_shadow_wave_kbw_counter:OnParentAttackLanded(t)
	local parent = self:GetParent()
	if not HasFlag(parent, 'perform_attack') and t.target:IsAlive() then
		local ability = parent:FindAbilityByName('dazzle_shadow_wave_kbw')
		if ability and ability:IsTrained() then
			local stacks = self:GetStackCount() + 1
			if stacks >= self.proc_attacks then
				SpellCaster:Cast(ability, t.target)
				self:SetStackCount(0)
			else
				self:SetStackCount(stacks)
			end
		end
	end
end