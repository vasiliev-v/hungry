CORE_PATH = 'kbw/core/'

local SYSTEMS = {
	'armor_reduction',
}

for _, system in ipairs(SYSTEMS) do
	local path = CORE_PATH .. system .. '/'
	local env = {
		PATH = path,
	}
	setmetatable(env, {__index = _G})
	envrunfile(path .. 'init', env)
end