require('kbw/util_spell')
require('kbw/util_c')
m_kbw_bash_cd = ModifierClass{
	bPermanent = true,
	bHidden = true,
}

function m_kbw_bash_cd:OnCreated(t)
	if IsServer() then
		self.stun = t.stun
		self.cooldown = t.cooldown
		self.nNextTime = 0
		
	end
end

function m_kbw_bash_cd:OnDestroy()
	if IsServer() then
		
	end
end

function m_kbw_bash_cd:OnParentAttackLanded(t)
	local nTime = GameRules:GetGameTime()

	if exist(t.target) and t.target:IsBaseNPC() and nTime >= self.nNextTime
	and UnitFilter(
		t.target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		t.attacker:GetTeam()
	) == UF_SUCCESS then
		self.nNextTime = nTime + self.cooldown

		AddModifier('modifier_bashed', {
			hTarget = t.target,
			hCaster = t.attacker,
			hAbility = self:GetAbility(),
			duration = self.stun,
		})

		t.target:EmitSound('DOTA_Item.SkullBasher')
	end
end
