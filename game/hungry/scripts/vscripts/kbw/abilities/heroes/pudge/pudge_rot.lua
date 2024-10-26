pudge_rot_kbw = class{}
LinkLuaModifier( 'm_pudge_rot_kbw',  "kbw/abilities/heroes/pudge/pudge_rot", 0 )
LinkLuaModifier( 'm_pudge_rot_kbw_debuff',  "kbw/abilities/heroes/pudge/pudge_rot", 0 )

function pudge_rot_kbw:ProcsMagicStick()
	return false
end

function pudge_rot_kbw:OnToggle()
	if self:GetToggleState() then
		self:GetCaster():AddNewModifier( self:GetCaster(), self, "m_pudge_rot_kbw", nil )

		if not self:GetCaster():IsChanneling() then
			self:GetCaster():StartGesture( ACT_DOTA_CAST_ABILITY_ROT )
		end
	else
		local hRotBuff = self:GetCaster():FindModifierByName( "m_pudge_rot_kbw" )
		if hRotBuff ~= nil then
			hRotBuff:Destroy()
		end
	end
end

--function pudge_rot_kbw:OnUpgrade()
--	local hRotBuff = self:GetCaster():FindModifierByName( "m_pudge_rot_kbw" )
--	
--	if hRotBuff ~= nil then
--		hRotBuff.rot_radius = self:GetSpecialValueFor( "rot_radius" )
--		hRotBuff.rot_damage = self:GetSpecialValueFor( "rot_damage" )
--		hRotBuff.rot_tick = self:GetSpecialValueFor( "rot_tick" )
--		
--		hRotBuff.scepter_rot_radius_bonus = self:GetSpecialValueFor( "scepter_rot_radius_bonus" )
--		hRotBuff.scepter_rot_damage_bonus = self:GetSpecialValueFor( "scepter_rot_damage_bonus" )	
--
--		if hRotBuff:GetCaster():HasScepter() then
--			hRotBuff.rot_radius = hRotBuff.rot_radius + hRotBuff.scepter_rot_radius_bonus
--			hRotBuff.rot_damage = hRotBuff.rot_damage + hRotBuff.scepter_rot_damage_bonus
--		end
--		
--		hRotBuff.hAura.nRadius = hRotBuff.rot_radius
--	end
--end

m_pudge_rot_kbw = ModifierClass{}

function m_pudge_rot_kbw:IsDebuff()
	return true
end

function m_pudge_rot_kbw:OnCreated( kv )
	self.rot_radius = self:GetAbility():GetSpecialValueFor( "rot_radius" )
	self.rot_damage = self:GetAbility():GetSpecialValueFor( "rot_damage" )
	self.rot_tick = self:GetAbility():GetSpecialValueFor( "rot_tick" )
	
	self.scepter_rot_radius_bonus = self:GetAbility():GetSpecialValueFor( "scepter_rot_radius_bonus" )
	self.scepter_rot_damage_bonus = self:GetAbility():GetSpecialValueFor( "scepter_rot_damage_bonus" )	

	if self:GetCaster():HasScepter() then
		self.rot_radius = self.rot_radius + self.scepter_rot_radius_bonus
		self.rot_damage = self.rot_damage + self.scepter_rot_damage_bonus
	end

	if IsServer() then
		EmitSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.rot_radius, 1, self.rot_radius ) )
		self:AddParticle( nFXIndex, false, false, -1, false, false )

		self:StartIntervalThink( self.rot_tick )
		 
		Timer(0.5, function() 
			self.hAura = CreateAura({
				hSource = self,
				sModifier = 'm_pudge_rot_kbw_debuff',
				nRadius = self.rot_radius,
				nFilterTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			})	
		end )			
	end
end

function m_pudge_rot_kbw:OnDestroy()
	if IsServer() then
		StopSoundOn( "Hero_Pudge.Rot", self:GetCaster() )
	end
end

function m_pudge_rot_kbw:OnIntervalThink()
	if IsServer() then
		if self:GetParent():IsAlive() then
			local flDamagePerTick = self.rot_tick * self.rot_damage
		
			local health = self:GetParent():GetHealth()
			
			if (health - flDamagePerTick) < 1 then
				flDamagePerTick = health - 1
			end
		
			local damage = {
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = flDamagePerTick,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility()
			}

			ApplyDamage( damage )
		end
	end
end

m_pudge_rot_kbw_debuff = class{}

function m_pudge_rot_kbw_debuff:IsDebuff()
	return true
end

function m_pudge_rot_kbw_debuff:OnCreated( kv )
    ReadAbilityData( self, {
        rot_damage = 'rot_damage',
		rot_tick = 'rot_tick',
		rot_slow = 'rot_slow',
		scepter_rot_damage_bonus = 'scepter_rot_damage_bonus',
		scepter_aura_enemy_regen = 'scepter_aura_enemy_regen',
    })

	if self:GetCaster():HasScepter() then
		self.rot_damage = self.rot_damage + self.scepter_rot_damage_bonus
	end

	if IsServer() then
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		self:AddParticle( nFXIndex, false, false, -1, false, false )

		self:StartIntervalThink( self.rot_tick )
	end
end

function m_pudge_rot_kbw_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MP_RESTORE_AMPLIFY_PERCENTAGE,
	}

	return funcs
end

function m_pudge_rot_kbw_debuff:GetModifierMoveSpeedBonus_Percentage( params )
	return self.rot_slow
end

function m_pudge_rot_kbw_debuff:GetModifierMPRestoreAmplify_Percentage( params )
	if self:GetCaster():HasScepter() then
		return self.scepter_aura_enemy_regen
	end
	
	return 0
end

function m_pudge_rot_kbw_debuff:OnIntervalThink()
	if IsServer() then
		if self:GetParent():IsAlive() then
			local flDamagePerTick = self.rot_tick * self.rot_damage
			
			local damage = {
				victim = self:GetParent(),
				attacker = self:GetCaster(),
				damage = flDamagePerTick,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self:GetAbility()
			}

			ApplyDamage( damage )
		end
	end
end