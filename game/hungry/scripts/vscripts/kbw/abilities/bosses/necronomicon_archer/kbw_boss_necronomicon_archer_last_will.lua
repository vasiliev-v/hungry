kbw_boss_necronomicon_archer_last_will = class{}

function kbw_boss_necronomicon_archer_last_will:OnOwnerDied()
	self.damage = self:GetSpecialValueFor('damage')
	self.radius = self:GetSpecialValueFor('radius')

	local nTypeFilter = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	
	local qTargets = FindUnitsInRadius( self:GetCaster():GetTeam(), self:GetCaster():GetOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, nTypeFilter, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false )
	
	for _, hTarget in ipairs( qTargets ) do
		if exist( hTarget ) and hTarget:IsAlive() then	
			local damageTable = {
				victim = hTarget,
				attacker = self:GetCaster(),
				damage = self.damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self,
			}

			ApplyDamage( damageTable )	
		end
	end		
	
	self:GetCaster():EmitSound("Hero_Techies.Suicide")
	
	local sParticle = 'particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf'
	local nParticle = ParticleManager:Create( sParticle, PATTACH_WORLDORIGIN, 2  )
	ParticleManager:SetParticleControl( nParticle, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControl( nParticle, 1, Vector( self.radius, self.radius, self.radius ) )	
end