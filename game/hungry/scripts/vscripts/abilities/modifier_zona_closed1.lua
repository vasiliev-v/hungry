modifier_zona_closed_debuff1 = class({})

------------------------------------------------------------------------------------

function modifier_zona_closed_debuff1:IsPurgable()
	return false
end
function modifier_zona_closed_debuff1:IsDebuff() return true end

function modifier_zona_closed_debuff1:IsPurgeException()
	return false
end
------------------------------------------------------------------------------------

function modifier_zona_closed_debuff1:OnCreated( kv )

	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(1)
	end
end

function modifier_zona_closed_debuff1:GetTexture()
	return "custom/vampire_life_drain"
end

function modifier_zona_closed_debuff1:IsPurgeException()
	return false
end

--------------------------------------------------------------------------------

function modifier_zona_closed_debuff1:OnIntervalThink()
	if IsServer() then
		
		local flDamage = 1 
		if GameRules:GetGameTime() > ZONA_START_TIME1 and GameRules:GetGameTime() <= ZONA_START_TIME2 then
			flDamage = 1 
		elseif GameRules:GetGameTime() > ZONA_START_TIME2 and GameRules:GetGameTime() <= ZONA_START_TIME3 then
			flDamage = 200
		elseif GameRules:GetGameTime() > ZONA_START_TIME3 and GameRules:GetGameTime() <= ZONA_START_TIME4 then
			flDamage = 500
		elseif GameRules:GetGameTime() > ZONA_START_TIME4 then
			flDamage = 999999
		else
			return 1
		end
		

		local damage = {
			victim = self:GetParent(),
			attacker = self:GetParent(),
			damage = flDamage,
			damage_type = DAMAGE_TYPE_PURE
		}
		ApplyDamage( damage )
	end
end

------------------------------------------------------------------------------------