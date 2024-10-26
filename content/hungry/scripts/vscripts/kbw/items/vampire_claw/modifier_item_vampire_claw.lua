modifier_item_vampire_claw = class({})
--------------------------------------------------------------------------------
function modifier_item_vampire_claw:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_item_vampire_claw:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_item_vampire_claw:DestroyOnExpire()
    return false
end

--------------------------------------------------------------------------------
function modifier_item_vampire_claw:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_item_vampire_claw:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE
end

-----------------------------------------------------------------------------
function modifier_item_vampire_claw:OnCreated(kv)
	if IsServer() then
		self:RegisterSelfEvents()
	end
end

-----------------------------------------------------------------------------

function modifier_item_vampire_claw:OnDestroy()
	if IsServer() then
		self:UnregisterSelfEvents()
	end	
end

-------------------------------------------------------------------------------
function modifier_item_vampire_claw:OnParentAttackLanded(kv)
	if not IsNPC( kv.target ) then
		return
	end

    local ability = self:GetAbility()

    local maxCharges = ability:GetSpecialValueFor("max_charges")
    local currentCharges = ability:GetCurrentCharges()
    local additionalCharges = 0

    if kv.target:IsHero() then
        additionalCharges = ability:GetSpecialValueFor("charges_for_attack_hero")
    elseif kv.target:IsCreep() then
        additionalCharges = ability:GetSpecialValueFor("charges_for_attack_creep")
	else
		return
    end

    local newChargesCount = currentCharges + additionalCharges

    if newChargesCount > maxCharges then newChargesCount = maxCharges end

    ability:SetCurrentCharges(newChargesCount)
end