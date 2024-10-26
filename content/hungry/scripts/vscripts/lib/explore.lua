Explore = {}

function Explore:PrintModifierNames( hUnit )
	local qMods = hUnit:FindAllModifiers()
	for _, hMod in ipairs( qMods ) do
		print( hMod:GetName() )
	end
end