local msgs = {
	["#donate1"] = {
		StartTime = 1,
		Interval = 120,
		MaxCount = 5,
	},
	["#donate2"] = {
		StartTime = 1,
		Interval = 213,
		MaxCount = 5,
	},
	["#donate3"] = {
		StartTime = 1,
		Interval = 275,
		MaxCount = 5
	},
	["#donate4"] = {
		StartTime = 1,
		Interval = 353,
		MaxCount = 3	
	},
	["#donate5"] = {
		StartTime = 1,
		Interval = 481,
		MaxCount = 3	
	},
	["#donate6"] = {
		StartTime = 1,
		Interval = 596,
		MaxCount = 3	
	},
	["#donate7"] = {
		StartTime = 1,
		Interval = 791,
		MaxCount = 5
	},
	--[[
	["#donate8"] = {
		StartTime = 1,
		Interval = 851,
		MaxCount = 5
	},
]]
}

function StartReklama()
	for msg, info in pairs( msgs ) do
		Timers:CreateTimer( function()
			if info.MaxCount then
				info.MaxCount = info.MaxCount - 1
				if info.MaxCount <= 0 then
					return
				end
			end
			-- fireLeftNotify(0, false, msg, {})
			GameRules:SendCustomMessage(msg, 0, 0)
			return info.Interval
		end, info.StartTime )
	end
end

