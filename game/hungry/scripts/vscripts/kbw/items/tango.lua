local sPath = "kbw/items/tango"
LinkLuaModifier( 'm_item_kbw_tango', sPath, 0 )

item_kbw_tango = class{}

function item_kbw_tango:GetAOERadius()
	return self:GetSpecialValueFor('radius')
end

function item_kbw_tango:OnSpellStart()
	local caster = self:GetCaster()
	local team = caster:GetTeam()
	local point = self:GetCursorPosition()
	
	local radius = self:GetSpecialValueFor('radius')
	local duration = self:GetSpecialValueFor('duration')
	local regrow_time = self:GetSpecialValueFor('regrow_time')
	local instant_heal = self:GetSpecialValueFor('instant_heal')
	
	local trees = GridNav:GetAllTreesAroundPoint( point, radius, false )
	local count = #trees

	for _,v in ipairs( trees ) do
		v:EmitSound("DOTA_Item.Tango.Activate")
		v:CutDownRegrowAfter( regrow_time, team )
	end

	local heal = count * instant_heal
	caster:Heal(heal, self)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal, nil)
	
	if count > 0 then
		caster:AddNewModifier( caster, self, 'm_item_kbw_tango', {
			duration = duration,
			stacks = count,
		})
	end	
	
	local sParticle = 'particles/items/tango_cast.vpcf'
	local nParticle = ParticleManager:Create( sParticle, PATTACH_WORLDORIGIN, 2 )
	ParticleManager:SetParticleControl( nParticle, 0, point )
	ParticleManager:SetParticleControl( nParticle, 1, Vector( radius, 0, 0 ) )
	
	self:SpendCharge()
end

m_item_kbw_tango = ModifierClass{
    bMultiple = true,
}

function m_item_kbw_tango:GetTexture()
	return "item_tango"
end

function m_item_kbw_tango:OnCreated( t )
	if IsServer() then
		if t.stacks and t.stacks > 0 then
			self:SetStackCount( t.stacks )
		else
			self:Destroy()
			return
		end

		self.nParticle = ParticleManager:Create( "particles/items_fx/healing_tango.vpcf", self:GetParent())
	end	

    ReadAbilityData( self, {
        hp_regen = 'hp_regen',
        mp_regen = 'mp_regen',
        speed = 'speed',
    })
end

function m_item_kbw_tango:OnDestroy()
	if IsServer() and self.nParticle then
		ParticleManager:Fade( self.nParticle, true )
	end
end

function m_item_kbw_tango:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
end

function m_item_kbw_tango:GetModifierMoveSpeedBonus_Constant()
    return self.speed * self:GetStackCount()
end

function m_item_kbw_tango:GetModifierConstantHealthRegen()
    return self.hp_regen * self:GetStackCount()
end

function m_item_kbw_tango:GetModifierConstantManaRegen()
    return self.mp_regen * self:GetStackCount()
end