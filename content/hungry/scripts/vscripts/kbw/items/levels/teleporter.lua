LinkLuaModifier('m_item_teleporter', "kbw/items/levels/teleporter", 0)
LinkLuaModifier('m_item_force_boots_dash', "kbw/items/levels/teleporter", LUA_MODIFIER_MOTION_HORIZONTAL)

local base = {}

function base:GetIntrinsicModifierName()
	return 'm_mult'
end

function base:GetMultModifiers()
	return {
		m_item_teleporter = self.nLevel,
		m_item_generic_base = 0,
		m_item_generic_stats = 0,
		m_item_generic_speed = 0,
	}
end

function base:GetCastRange(vPos, hTarget)
	if IsClient() then
		return self:GetSpecialValueFor('blink_distance')
	end
	return 0
end

function base:CastFilterResultTarget(target)
	local result = self.BaseClass.CastFilterResultTarget(self, target)
	if result == UF_SUCCESS then
		return UF_SUCCESS
	end
	if target:GetUnitName() == 'npc_dota_gyrocopter_homing_missile' then
		return UF_SUCCESS
	end
	return result
end

function base:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local length = self:GetSpecialValueFor('push_length')
	local time = self:GetSpecialValueFor('push_time')
	local tree_radius = self:GetSpecialValueFor('push_tree_radius')
	local dir = target:GetForwardVector()
	dir.z = 0
	dir = dir:Normalized()
	
	if target:TriggerSpellAbsorb(self) then
		return
	end

	if target:GetUnitName() == 'npc_dota_gyrocopter_homing_missile' then
		local endtime = GameRules:GetGameTime() + time
		local tick = FrameTime()
		Timer(function()
			if not exist(target) or not target:IsAlive() or GameRules:GetGameTime() > endtime then
				return
			end
			local dir = target:GetForwardVector()
			dir.z = 0
			dir = dir:Normalized()
			target:SetAbsOrigin(target:GetOrigin() + dir * length / time * tick)
			return tick
		end)
	else
		local mod = target:AddNewModifier(caster, self, 'm_item_force_boots_dash', {
			duration = time,
		})
		if mod then
			mod:Start(target:GetOrigin() + dir * length, time, tree_radius)
		end
	end

	target:EmitSound('DOTA_Item.Force_Boots.Cast')
end

CreateLevels({
	'item_kbw_travel_boots',
	'item_kbw_force_boots',
	'item_kbw_force_boots_2',
	'item_kbw_force_boots_3',
}, base)

local function fUpdateScroll(hUnit)
	local qMods = hUnit:FindAllModifiersByName('m_item_teleporter')
	local nMinCD
	local nMinDuration
	local nMaxLevel

	for _, hMod in ipairs(qMods) do
		if hMod.tp_cooldown and (not nMinCD or hMod.tp_cooldown < nMinCD) then
			nMinCD = hMod.tp_cooldown
		end

		if hMod.tp_duration and hMod.tp_duration > 0 and (not nMinDuration or hMod.tp_duration < nMinDuration) then
			nMinDuration = hMod.tp_duration
		end

		if hMod.nMultLevel and (not nMaxLevel or hMod.nMultLevel > nMaxLevel) then
			nMaxLevel = hMod.nMultLevel
		end
	end

	local nIndex = hUnit:entindex()
	GenTable:SetAll('ScrollCooldown.'..nIndex, nMinCD, true)
	GenTable:SetAll('ScrollDuration.'..nIndex, nMinDuration, true)
	GenTable:SetAll('ScrollLevel.'..nIndex, nMaxLevel, true)
end

---------------------------------------------------------
-- travel boots passive

m_item_teleporter = ModifierClass{
	bHidden = true,
	bPermanent = true,
	bMultiple = true,
}

function m_item_teleporter:OnCreated()
	ReadAbilityData(self, {
		'blink_damage_cd',
		'tp_cooldown',
		'tp_duration',
	})

	if IsServer() then
		local hParent = self:GetParent()
		self.nTeam = hParent:GetTeam()

		Timer(1/30, function()
			if exist(hParent) then
				fUpdateScroll(hParent)
			end
		end)
	end
end

function m_item_teleporter:OnDestroy()
	if IsServer() then
		local hParent = self:GetParent()
		Timer(1/30, function()
			if exist(hParent) then
				fUpdateScroll(hParent)
			end
		end)
	end
end

---------------------------------------------------------
-- dash

m_item_force_boots_dash = ModifierClass{
	bPurgable = true,
}

function m_item_force_boots_dash:DestroyOnExpire()
	return false
end

function m_item_force_boots_dash:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function m_item_force_boots_dash:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function m_item_force_boots_dash:OnCreated()
	if IsServer() then
		local parent = self:GetParent()
		self.particle = ParticleManager:Create('particles/items_fx/force_staff.vpcf', parent)
		ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), false)
	end
end


function m_item_force_boots_dash:Start(vTarget, nDuration, nTreeRadius)
	self.vPos = self:GetParent():GetOrigin()
	self.vDir = vTarget - self.vPos
	self.vDir.z = 0
	self.nDistance = #self.vDir
	
	if self.nDistance < 1 then
		self:Destroy()
		return
	end
	
	self.vDir = self.vDir:Normalized()
	self.nSpeed = self.nDistance / nDuration
	self.nTreeRadius = nTreeRadius

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end

function m_item_force_boots_dash:OnHorizontalMotionInterrupted()
	self:Destroy()
end

function m_item_force_boots_dash:OnDestroy()
	if IsServer() then
		local hParent = self:GetParent()

		hParent:RemoveHorizontalMotionController( self )

		Timer(FrameTime(), function()
			FindClearSpaceForUnit( hParent, hParent:GetOrigin(), false )
		end)

		if IsServer() then
			ParticleManager:Fade(self.particle, true)
		end
	end
end

function m_item_force_boots_dash:UpdateHorizontalMotion( hUnit, nTimeDelta )
	local bEnd = false
	local hParent = self:GetParent()
	local nDelta = self.nSpeed * nTimeDelta
	
	if nDelta > self.nDistance then
		nDelta = self.nDistance
		bEnd = true
	end
	
	self.nDistance = self.nDistance - nDelta
	self.vPos = GetGroundPosition( self.vPos + self.vDir * nDelta, hParent )

	GridNav:DestroyTreesAroundPoint( self.vPos, self.nTreeRadius, false )
	
	hParent:SetAbsOrigin( self.vPos )
	
	if bEnd then
		self:Destroy()
	end
end