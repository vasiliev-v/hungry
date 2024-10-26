m_faceless_void_time_walk_time_lock = ModifierClass{
	bHidden = true,
	bPermanent = true,
}

function m_faceless_void_time_walk_time_lock:OnCreated(t)
	if IsServer() then
		self.stun = t.stun
		self.radius = t.radius
		self:RegisterSelfEvents()
	end
end

function m_faceless_void_time_walk_time_lock:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end
end

function m_faceless_void_time_walk_time_lock:OnParentAbilityFullyCast(t)
	if exist(t.ability) and t.ability:GetName() == 'faceless_void_time_walk' then
		local hCaster = t.ability:GetCaster()
		local nDelay = (hCaster:GetOrigin() - t.target):Length2D() / t.ability:GetSpecialValueFor('speed')
		local hTimeLock = hCaster:FindAbilityByName('faceless_void_time_lock_kbw')
		
		if hTimeLock and hTimeLock:IsTrained() and hTimeLock.AffectPoint then
			local vStart = hCaster:GetOrigin()
			local vPos = hCaster:GetCursorPosition()
			local nRange = t.ability:GetSpecialValueFor('range')
			nRange = nRange + hCaster:GetCastRangeBonus()
			if hCaster:HasShard() then
				nRange = nRange + 400
			end

			local vDir = vPos - vStart
			vDir.z = 0
			if #vDir > nRange then
				vPos = vStart + vDir:Normalized()*nRange
			end

			hTimeLock:AffectPoint({
				vPos = vPos,
				nRadius = self.radius,
				nStun = self.stun,
			})
		end
	end
end