local sPath = "kbw/items/levels/bullwhip"
LinkLuaModifier( 'm_item_kbw_bullwhip_stats', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_kbw_bullwhip_buff', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_kbw_bullwhip_debuff', sPath, LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( 'm_item_kbw_bullwhip_dash', sPath, LUA_MODIFIER_MOTION_BOTH )

base = {}

function base:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	local bAlly = ( hCaster:GetTeam() == hTarget:GetTeam() )
	local nDelay = self:GetSpecialValueFor('delay')
	local nDuration = self:GetSpecialValueFor('duration')
	local nGrabDuration = self:GetSpecialValueFor('grab_duration')
	local nGrabRange = self:GetSpecialValueFor('grab_range')
	local nGrabGravity = self:GetSpecialValueFor('grab_gravity')
	local nSpeed = self:GetSpecialValueFor('active_speed')
	local nSlow = self:GetSpecialValueFor('active_slow')

	local vCaster = hCaster:GetOrigin()
	local vTarget = hTarget:GetOrigin()
	local nDelta = (vCaster - vTarget):Length2D()
	nGrabRange = math.max(0, math.min(nGrabRange, nDelta - 128))

	local sParticle = 'particles/items4_fx/bull_whip_enemy.vpcf'
	local sSound = 'KBW.Item.Bullwhip'
	local hOwner

	if bAlly then
		sSound = "Item.Bullwhip.Ally"
		if hCaster == hTarget then
			nDelay = 0
			hOwner = hCaster
			sParticle = 'particles/items4_fx/bull_whip_self.vpcf'
		else
			sParticle = 'particles/items4_fx/bull_whip.vpcf'
		end
	end

	local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN, hOwner, 3 )
	ParticleManager:SetParticleControlEnt( nParticle, 0, hCaster, PATTACH_ABSORIGIN_FOLLOW, 'attach_hitloc', vCaster, false )
	ParticleManager:SetParticleControlEnt( nParticle, 1, hTarget, PATTACH_POINT_FOLLOW, 'attach_hitloc', vTarget, false )
	
	hCaster:EmitSound("Item.Bullwhip.Cast")

	Timer( 0, function()
		hTarget:EmitSound( sSound )
	end )

	Timer( nDelay, function()
		if hTarget:TriggerSpellAbsorb(self) then
			return
		end

		local sModifier = 'm_item_kbw_bullwhip_buff'

		if not bAlly then
			sModifier = 'm_item_kbw_bullwhip_debuff'

			AddModifier( 'm_item_kbw_bullwhip_dash', {
				hCaster = hCaster,
				hTarget = hTarget,
				hAbility = self,
				bReapply = true,
				bIgnoreStatusResist = true,
				duration = nGrabDuration,
				grab_range = nGrabRange,
				grab_gravity = nGrabGravity,
			})
		end

		AddModifier( sModifier, {
			hCaster = hCaster,
			hTarget = hTarget,
			hAbility = self,
			bStacks = true,
			duration = nDuration,
			speed = bAlly and nSpeed or nSlow,
		})
	end )
end

function base:GetIntrinsicModifierName()
    return 'm_mult'
end

function base:GetMultModifiers()
    return {
        m_item_kbw_bullwhip_stats = -1,
    }
end

CreateLevels({
    'item_kbw_bullwhip',
    'item_kbw_bullwhip_2',
    'item_kbw_bullwhip_3',
}, base )

m_item_kbw_bullwhip_stats = ModifierClass{
    bHidden = true,
    bMultiple = true,
    bPermanent = true,
}

function m_item_kbw_bullwhip_stats:OnCreated()
    ReadAbilityData( self, {
        'speed',
		'damage',
		'attack_speed',
		'armor',
    })
end

function m_item_kbw_bullwhip_stats:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function m_item_kbw_bullwhip_stats:GetModifierMoveSpeedBonus_Percentage()
    return self.speed
end

function m_item_kbw_bullwhip_stats:GetModifierPreAttack_BonusDamage()
    return self.damage
end

function m_item_kbw_bullwhip_stats:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

function m_item_kbw_bullwhip_stats:GetModifierPhysicalArmorBonus()
    return self.armor
end

m_item_kbw_bullwhip_buff = ModifierClass{
    bMultiple = true,
	bPurgable = true,
}

function m_item_kbw_bullwhip_buff:GetTexture()
	return self.sTexture
end

function m_item_kbw_bullwhip_buff:OnCreated( tData )
	self.speed = tData.speed
	
	local hAbility = self:GetAbility()
	if exist(hAbility) then
		self.sTexture = hAbility:GetName():gsub('kbw_','')
		self.speed = self.speed or hAbility:GetSpecialValueFor('active_speed')
	end

	self.speed = self.speed or 0
	
	if IsServer() and not self.nParticleIndex then
		self.nParticleIndex = ParticleManager:CreateParticle("particles/items4_fx/bull_whip_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())	
	end
end

function m_item_kbw_bullwhip_buff:OnDestroy()
	if not IsServer() then return end
	if self.nParticleIndex then
		ParticleManager:DestroyParticle(self.nParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(self.nParticleIndex)
	end
end

function m_item_kbw_bullwhip_buff:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function m_item_kbw_bullwhip_buff:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function m_item_kbw_bullwhip_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * self.speed
end

m_item_kbw_bullwhip_debuff = ModifierClass{
    bMultiple = true,
	bPurgable = true,
}

function m_item_kbw_bullwhip_debuff:GetTexture()
	return self.sTexture
end

function m_item_kbw_bullwhip_debuff:OnCreated( tData )
	self.speed = tData.speed
	
	local hAbility = self:GetAbility()
	if exist(hAbility) then
		self.sTexture = hAbility:GetName():gsub('kbw_','')
		self.speed = self.speed or hAbility:GetSpecialValueFor('active_slow')
	end

	self.speed = -(self.speed or 0)
	
	if IsServer() and not self.nParticleIndex then
		self.nParticleIndex = ParticleManager:CreateParticle("particles/items4_fx/bull_whip_enemy_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())	
	end	
end

function m_item_kbw_bullwhip_debuff:OnDestroy()
	if not IsServer() then return end
	if self.nParticleIndex then
		ParticleManager:DestroyParticle(self.nParticleIndex, false)
		ParticleManager:ReleaseParticleIndex(self.nParticleIndex)
	end
end

function m_item_kbw_bullwhip_debuff:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function m_item_kbw_bullwhip_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * self.speed
end

m_item_kbw_bullwhip_dash = ModifierClass{
	bHidden = true,
	bJump = true,
}

function m_item_kbw_bullwhip_dash:GetTexture()
	return self.sTexture
end

function m_item_kbw_bullwhip_dash:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end

function m_item_kbw_bullwhip_dash:OnCreated( t )
	local hAbility = self:GetAbility()
	if exist(hAbility) then
		self.sTexture = hAbility:GetName():gsub('kbw_','')
	end

	if IsServer() then
		local hCaster = self:GetCaster()
		local hParent = self:GetParent()
		local vStart = hParent:GetOrigin()
		local vDir = hCaster:GetOrigin() - vStart
		vDir.z = 0

		if #vDir < 1 then
			vDir = -hCaster:GetForwardVector()
			vDir.z = 0
		end

		self:Jump({
			vTarget = GetGroundPosition( vStart + vDir:Normalized() * t.grab_range, nil ),
			nDuration = self:GetRemainingTime(),
			nGravity = t.grab_gravity,
		})
	end
end

function m_item_kbw_bullwhip_dash:OnHorizontalMotionInterrupted()
    self:Destroy()
end

function m_item_kbw_bullwhip_dash:OnVerticalMotionInterrupted()
    self:Destroy()
end

function m_item_kbw_bullwhip_dash:OnDestroy()
    if IsServer() then
        local hParent = self:GetParent()
		hParent:RemoveVerticalMotionController( self )
		hParent:RemoveHorizontalMotionController( self )
        FindClearSpaceForUnit( hParent, hParent:GetOrigin(), false )
    end
end