alchemist_melting = class{}

alchemist_melting.bScepterGranted = true

function alchemist_melting:GetGoldCost()
	return self:GetSpecialValueFor('cost')
end

function alchemist_melting:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function alchemist_melting:OnSpellStart()
	local hItem = AddItem(self:GetCaster(), 'item_upgrade_core')
	if exist(hItem) then
		hItem:SetPurchaseTime(0)
	end
end