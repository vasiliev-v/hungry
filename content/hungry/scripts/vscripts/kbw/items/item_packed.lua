local item_packed = class{}

local tItems = {
	item_gift_pudge_mom = 1,
}

function item_packed:OnSpellStart()
	local hCaster = self:GetCaster()
	if not hCaster then
		return
	end

	local tKV = self:GetAbilityKeyValues()
	hCaster:RemoveItem(self)

	local hItem = hCaster:AddItemByName(tKV.PackedItem)
	if hItem then
		hItem:SetSellable(false)
		hItem.bDisassemblable = false
	end
end


local tEnv = getfenv(1)
for sItem, b in pairs(tItems) do
	if b then
		tEnv[sItem] = class(item_packed)
	end
end