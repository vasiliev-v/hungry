require('kbw/util_spell')
require('kbw/util_c')
m_kbw_respawn_reduction = ModifierClass{
	bPermanent = true,
	bMultiple = true,
	bHidden = true,
}

function m_kbw_respawn_reduction:OnCreated()
	if IsServer() then
		ReadAbilityData(self, {
			'respawn_reduction_pct',
		})
	end
end