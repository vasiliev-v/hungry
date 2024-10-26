LinkLuaModifier("modifier_item_custom_dust_charges", "abilities/ui/dust", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_dust_cd", "abilities/ui/dust", LUA_MODIFIER_MOTION_NONE)

custom_ability_dust = class({})

function custom_ability_dust:Spawn()
    if not IsServer() then return end
    if self and not self:IsTrained() then
        self:SetLevel(1)
    end
end


function custom_ability_dust:GetIntrinsicModifierName()
    return "modifier_item_custom_dust_charges"
end

function custom_ability_dust:OnInventoryContentsChanged()
    if not IsServer() then return end
    for i=0, 8 do
        local item = self:GetCaster():GetItemInSlot(i)
        if item then
            if item:GetName() == "item_dust" and not item.use_ui then
                if self:GetCaster():IsRealHero() then
                    local modifier_sentry = self:GetCaster():FindModifierByName("modifier_item_custom_dust_charges")
                    if modifier_sentry then
                        modifier_sentry:SetStackCount(modifier_sentry:GetStackCount() + item:GetCurrentCharges())
                    end
                    item.use_ui = true
                    Timers:CreateTimer(0, function()
                        UTIL_Remove( item )
                    end)
                end
            end
        end
    end
end

function custom_ability_dust:OnSpellStart()
    if not IsServer() then return end
if self:GetCaster():HasModifier("modifier_item_custom_dust_cd") then return end
    local mod_stacks = self:GetCaster():GetModifierStackCount("modifier_item_custom_dust_charges", self:GetCaster())
    if mod_stacks and mod_stacks <= 0 then
        local player = PlayerResource:GetPlayer( self:GetCaster():GetPlayerOwnerID() )
        CustomGameEventManager:Send_ServerToPlayer(player, "CreateIngameErrorMessage", {message = "#dota_hud_error_no_charges"})
        self:EndCooldown()
        return
    end

    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_item_custom_dust_cd", {duration = 1})
    local radius = self:GetSpecialValueFor("radius")
    local duration = self:GetSpecialValueFor("duration")
    local damage = self:GetSpecialValueFor("damage")

    local particle = ParticleManager:CreateParticle( "particles/items_fx/dust_of_appearance.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
    ParticleManager:SetParticleControl( particle, 0, self:GetCaster():GetAbsOrigin() )
    ParticleManager:SetParticleControl( particle, 1, Vector(radius, 0, radius) )

    self:GetCaster():EmitSound("DOTA_Item.DustOfAppearance.Activate")

    local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
    for _, unit in pairs(units) do
        ApplyDamage({ victim = unit, attacker = self:GetCaster(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = self, }) 
        unit:AddNewModifier(self:GetCaster(), self, "modifier_item_dustofappearance", {duration = duration, movespeed = self:GetSpecialValueFor("movespeed")})
    end

    local mod = self:GetCaster():FindModifierByName("modifier_item_custom_dust_charges")
    if mod then
        mod:DecrementStackCount()
    end
end

modifier_item_custom_dust_charges = class({})
function modifier_item_custom_dust_charges:IsHidden() return true end
function modifier_item_custom_dust_charges:DestroyOnExpire() return false end
function modifier_item_custom_dust_charges:IsPurgable() return false end


modifier_item_custom_dust_cd = class({})
function modifier_item_custom_dust_cd:IsHidden() return true end
function modifier_item_custom_dust_cd:IsPurgable() return false end