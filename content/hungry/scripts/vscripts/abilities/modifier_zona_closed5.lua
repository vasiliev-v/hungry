modifier_zona_closed_debuff5 = class({})

------------------------------------------------------------------------------------

function modifier_zona_closed_debuff5:IsPurgable()
	return false
end
function modifier_zona_closed_debuff5:IsDebuff() return true end
------------------------------------------------------------------------------------

function modifier_zona_closed_debuff5:OnCreated( kv )

	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(1)
	end
end

function modifier_zona_closed_debuff5:GetTexture()
	return "custom/vampire_life_drain"
end

function modifier_zona_closed_debuff5:IsPurgeException()
	return false
end
--------------------------------------------------------------------------------

function modifier_zona_closed_debuff5:OnIntervalThink()
	if IsServer() then
		
		local flDamage = 1 
		if GameRules:GetDOTATime(false, false)  > ZONA_START_TIME5 then
			flDamage = 500
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