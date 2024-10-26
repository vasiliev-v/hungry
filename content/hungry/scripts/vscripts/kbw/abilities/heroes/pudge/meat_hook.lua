LinkLuaModifier( 'm_pudge_meat_hook_kbw', "kbw/abilities/heroes/pudge/meat_hook", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( 'm_pudge_meat_hook_kbw_backswing', "kbw/abilities/heroes/pudge/meat_hook", LUA_MODIFIER_MOTION_NONE )

pudge_meat_hook_kbw = class{}

function pudge_meat_hook_kbw:GetCastRange( vTarget, hTarget )
	return self:GetSpecialValueFor('range')
end

function pudge_meat_hook_kbw:SetProjectileData( nProjectile, tData )
	if not self.tProjectiles then
		self.tProjectiles = {}
	end

	self.tProjectiles[ nProjectile ] = tData
end

function pudge_meat_hook_kbw:GetProjectileData( nProjectile )
	if self.tProjectiles then
		return self.tProjectiles[ nProjectile ]
	end
end

function pudge_meat_hook_kbw:GetAttachment()
	local hCaster = self:GetCaster()
	local sAttach = 'attach_weapon_chain_rt'
	local nAttach = hCaster:ScriptLookupAttachment( sAttach )

	if nAttach < 1 then
		sAttach = 'attach_attack1'
		nAttach = hCaster:ScriptLookupAttachment( sAttach )
	end

	return sAttach, nAttach
end

function pudge_meat_hook_kbw:FindRune( vPos, nRadius )
	local vPos = GetGroundPosition( vPos, nil )
	local qDrops = Entities:FindAllByClassnameWithin( 'dota_item_drop', vPos, nRadius )

	for _, hDrop in ipairs( qDrops ) do
		local hItem = hDrop:GetContainedItem()
		if exist( hItem ) and exist( hItem.hRune ) then
			return hDrop
		end
	end
end

function pudge_meat_hook_kbw:OnAbilityPhaseStart()
	self:GetCaster():StartGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
	return true
end


function pudge_meat_hook_kbw:OnAbilityPhaseInterrupted()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
end

function pudge_meat_hook_kbw:OnSpellStart()
	local hCaster = self:GetCaster()
	local vStart = hCaster:GetOrigin()
	local vTarget = self:GetCursorPosition()
	local vDir = vTarget - vStart
	local nRange = self:GetEffectiveCastRange( vTarget, nil )
	local nLimit = self:GetSpecialValueFor('grab_range') + hCaster:GetCastRangeBonus()
	local nSpeed = self:GetSpecialValueFor('speed')
	local nWidth = self:GetSpecialValueFor('width')
	local nFilterTeam = self:GetAbilityTargetTeam()
	local nFilterType = self:GetAbilityTargetType()
	local nFilterFlag = self:GetAbilityTargetFlags()

	if vDir:Length2D() < 1 then
		vDir = hCaster:GetForwardVector()
	end

	vDir.z = 0
	vDir = vDir:Normalized()
	vTarget = vStart + vDir * nRange

	local hBackswing = AddModifier( 'm_pudge_meat_hook_kbw_backswing', {
		hTarget = hCaster,
		hCaster = hCaster,
		hAbility = self,
		bReapply = true,
		duration = self:GetSpecialValueFor('backswing'),
	})

	self.nThrown = ( self.nThrown or 0 ) + 1
	if self.nThrown	== 1 and hCaster.GetTogglableWearable then
		local hHook = hCaster:GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
		if hHook then
			hHook:AddEffects( EF_NODRAW )
		end
	end

	local sAttach = self:GetAttachment()
	local sParticle = ParticleManager:GetParticleReplacement( 'particles/units/heroes/hero_pudge/pudge_meathook.vpcf', hCaster )
	local nParticle = ParticleManager:Create( sParticle, PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleAlwaysSimulate( nParticle )
	ParticleManager:SetParticleControlEnt( nParticle, 0, hCaster, PATTACH_POINT_FOLLOW, sAttach, vStart, true )
	ParticleManager:SetParticleControl( nParticle, 1, vTarget )
	ParticleManager:SetParticleControl( nParticle, 2, Vector( nSpeed, 0, 0 ) )
	ParticleManager:SetParticleControl( nParticle, 3, Vector( 9999, 0, 0 ) )
	ParticleManager:SetParticleControl( nParticle, 4, Vector( 1, 0, 0 ) )
	ParticleManager:SetParticleControl( nParticle, 5, Vector( 0, 0, 0 ) )

	hCaster:EmitSound("Hero_Pudge.AttackHookExtend")

	local nProjectile = ProjectileManager:CreateLinearProjectile({
		Ability = self,
		Source = hCaster,
		vSpawnOrigin = vStart,
		vVelocity = vDir * nSpeed,
		fDistance = nRange,
		fStartRadius = nWidth,
		fEndRadius = nWidth,
		iUnitTargetTeam = nFilterTeam,
		iUnitTargetType = nFilterType,
		iUnitTargetFlags = nFilterFlag,
	})

	self:SetProjectileData( nProjectile, {
		bLaunched = true,
		nParticle = nParticle,
		nWidth = nWidth,
		nSpeed = nSpeed,
		nDamage = self:GetSpecialValueFor('damage'),
		nVision = self:GetSpecialValueFor('vision_radius'),
		nFilterTeam = nFilterTeam,
		nFilterType = nFilterType,
		nFilterFlag = nFilterFlag,
		nLimit = nLimit,
		hBackswing = hBackswing,
	})
end

function pudge_meat_hook_kbw:Return( nProjectile, vPos )
	local tData = self:GetProjectileData( nProjectile )
	if not tData then
		return
	end

	local hCaster = self:GetCaster()

	self:SetProjectileData( nProjectile, nil )

	if tData.bLaunched then
		ProjectileManager:DestroyLinearProjectile( nProjectile )
	else
		ProjectileManager:DestroyTrackingProjectile( nProjectile )
	end

	if hCaster:IsAlive() then
		hCaster:RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
		hCaster:StartGesture( ACT_DOTA_CHANNEL_ABILITY_1 )
	end

	if exist( tData.hBackswing ) then
		tData.hBackswing:Destroy()
	end

	hCaster:EmitSound("Hero_Pudge.AttackHookRetract")

	local nProjectile = ProjectileManager:CreateTrackingProjectile({
		Target = self:GetCaster(),
		vSourceLoc = vPos,
		Ability = self,
		iMoveSpeed = tData.nSpeed,
		bDodgeable = false,
	})

	tData.bLaunched = false

	self:SetProjectileData( nProjectile, tData )
	self:OnProjectileThinkHandle( nProjectile )
end

function pudge_meat_hook_kbw:SetTarget( nProjectile, hTarget )
	local tData = self:GetProjectileData( nProjectile )
	if not tData then
		return
	end

	local hCaster = self:GetCaster()

	if exist( tData.hGrabModifier ) then
		tData.hGrabModifier:Destroy()
		tData.hGrabModifier = nil
	end

	if exist( hTarget ) then
		if IsNPC( hTarget ) then

			if hTarget:GetTeam() ~= hCaster:GetTeam() then
				ApplyDamage({
					victim = hTarget,
					attacker = hCaster,
					ability = self,
					damage = tData.nDamage,
					damage_type = self:GetAbilityDamageType(),
				})

				local sParticle = "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf"
				ParticleManager:Create( sParticle, PATTACH_POINT, hTarget, 2 )
			end

			if hTarget:IsAlive() then
				tData.hGrabModifier = AddModifier( 'm_pudge_meat_hook_kbw', {
					hTarget = hTarget,
					hCaster = hCaster,
					hAbility = self,
				})
			else
				AddFOWViewer( hCaster:GetTeam(), hTarget:GetOrigin(), tData.nVision, 4, false )
			end
		end

		PlaySound('Hero_Pudge.AttackHookImpact', hTarget:GetOrigin(), hCaster:GetTeam())

		tData.bPulled = true
		tData.vOldPos = hTarget:GetOrigin()
	else
		tData.vOldPos = nil
	end

	if tData.nParticle then
		if exist( hTarget ) then
			ParticleManager:SetParticleControl( tData.nParticle, 4, Vector( 0, 0, 0 ) )
			ParticleManager:SetParticleControl( tData.nParticle, 5, Vector( 1, 0, 0 ) )
		else
			ParticleManager:SetParticleControl( tData.nParticle, 4, Vector( 1, 0, 0 ) )
			ParticleManager:SetParticleControl( tData.nParticle, 5, Vector( 0, 0, 0 ) )
		end
	end

	tData.hTarget = hTarget
	tData.nPassed = 0
end

function pudge_meat_hook_kbw:OnProjectileThinkHandle( nProjectile )
	local tData = self:GetProjectileData( nProjectile )
	if not tData then
		return
	end

	local hCaster = self:GetCaster()
	local bCasterTarget = false

	if tData.bLaunched then
		local vPos = ProjectileManager:GetLinearProjectileLocation( nProjectile )
		local hRune = self:FindRune( vPos, tData.nWidth )

		if hRune then
			self:SetTarget( nProjectile, hRune )
			self:Return( nProjectile, hRune:GetOrigin() )
		end
	else
		local vPos = ProjectileManager:GetTrackingProjectileLocation( nProjectile )

		if ( hCaster:GetOrigin() - vPos ):Length2D() <= tData.nWidth then
			self:SetTarget( nProjectile, nil )
			return
		end

		if tData.hTarget then
			if not exist( tData.hTarget ) then
				self:SetTarget( nProjectile, nil )
				return
			end

			if tData.vOldPos and tData.nPassed and tData.nLimit then
				tData.nPassed = tData.nPassed + ( vPos - tData.vOldPos ):Length2D()

				if tData.nPassed >= tData.nLimit then
					self:SetTarget( nProjectile, nil )
					return
				end

				tData.vOldPos = vPos
			end

			if IsNPC( tData.hTarget ) then
				if not exist( tData.hGrabModifier ) then
					self:SetTarget( nProjectile, nil )
					return
				end

				tData.hGrabModifier.vPos = vPos
			else
				tData.hTarget:SetAbsOrigin( GetGroundPosition( vPos, tData.hTarget ) )
			end

			if tData.nParticle then
				local sAttach = 'attach_hitloc'
				local vAttach = tData.hTarget:GetAttachmentOrigin( tData.hTarget:ScriptLookupAttachment( sAttach ) )
				ParticleManager:SetParticleControlEnt( tData.nParticle, 1, tData.hTarget, PATTACH_POINT_FOLLOW, sAttach, vAttach, false )
			end

			AddFOWViewer( hCaster:GetTeam(), vPos, tData.nVision, 0.1, false )
		else
			if not tData.bPulled then
				local hTarget = ( Find:UnitsInRadius{
					vCenter = vPos,
					nRadius = tData.nWidth,
					nTeam = hCaster:GetTeam(),
					nFilterTeam = tData.nFilterTeam,
					nFilterType = tData.nFilterType,
					nFilterFlag = tData.nFilterFlag,
					fCondition = function( hUnit )
						return hUnit ~= hCaster and CanAffect( hCaster, hUnit )
					end
				} )[1]

				if not hTarget then
					hTarget = self:FindRune( vPos, tData.nWidth )
				end

				if hTarget then
					self:SetTarget( nProjectile, hTarget )
					return
				end
			end

			bCasterTarget = true
		end
	end

	if tData.nParticle then
		local sAttach, nAttach = self:GetAttachment()
		local vPos = hCaster:GetAttachmentOrigin( nAttach )

		ParticleManager:SetParticleControlEnt( tData.nParticle, 0, hCaster, PATTACH_POINT_FOLLOW, sAttach, vPos, true )

		if bCasterTarget then
			ParticleManager:SetParticleControlEnt( tData.nParticle, 1, hCaster, PATTACH_POINT_FOLLOW, sAttach, vPos, false )
		end
	end
end

function pudge_meat_hook_kbw:OnProjectileHitHandle( hTarget, vPos, nProjectile )
	local tData = self:GetProjectileData( nProjectile )
	if not tData then
		return true
	end

	local hCaster = self:GetCaster()

	if tData.bLaunched then
		if hTarget == hCaster then
			return false
		end

		if exist( hTarget ) then
			if not CanAffect( hCaster, hTarget ) then
				return false
			end

			self:SetTarget( nProjectile, hTarget )
			self:Return( nProjectile, hTarget:GetOrigin() )
		else
			self:Return( nProjectile, vPos )
		end
	else
		self:SetTarget( nProjectile, nil )

		self.nThrown = self.nThrown - 1
		if self.nThrown == 0 and hCaster.GetTogglableWearable then
			local hHook = hCaster:GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
			if hHook then
				hHook:RemoveEffects( EF_NODRAW )
			end
		end

		if exist( tData.nParticle ) then
			ParticleManager:Fade( tData.nParticle )
		end

		hCaster:EmitSound("Hero_Pudge.AttackHookRetractStop")
	end
end

m_pudge_meat_hook_kbw = ModifierClass{}

function m_pudge_meat_hook_kbw:CheckState()
	local hParent = self:GetParent()
	local hCaster = self:GetCaster()

	if exist( hCaster ) and hParent:GetTeamNumber() ~= hCaster:GetTeamNumber() and not hParent:IsMagicImmune() then
		return {
			[MODIFIER_STATE_STUNNED] = true,
		}
	end

	return {}
end

function m_pudge_meat_hook_kbw:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function m_pudge_meat_hook_kbw:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function m_pudge_meat_hook_kbw:OnCreated()
	if IsServer() then
		if not self:ApplyHorizontalMotionController() then
			self:Destroy()
		end
	end
end

function m_pudge_meat_hook_kbw:OnDestroy()
	if IsServer() then
		local hParent = self:GetParent()
		hParent:RemoveHorizontalMotionController( self )
		FindClearSpaceForUnit( hParent, hParent:GetOrigin(), false )
	end
end

function m_pudge_meat_hook_kbw:UpdateHorizontalMotion( hUnit, nTime )
	if self.vPos and exist( hUnit ) then
		hUnit:SetAbsOrigin( self.vPos )
	end
end

function m_pudge_meat_hook_kbw:OnHorizontalMotionInterrupted()
	self:Destroy()
end

m_pudge_meat_hook_kbw_backswing = ModifierClass{
	bHidden = true,
}

function m_pudge_meat_hook_kbw_backswing:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end