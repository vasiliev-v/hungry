local UpdateKV = {}

local function IsValueName(key)
	if key == 'var_type' then
		return false
	end
	if key:match('^special_bonus_') then
		return false
	end
	if key:match('^%l') then
		return true
	end
	return false
end

local comments = {}

local function ClearComments()
	comments = {}
end

local function GetCommentTarget(...)
	local target = comments
	for _, key in ipairs({...}) do
		local nt = target[key]
		if not nt then
			nt = {}
			target[key] = nt
		end
		target = nt
	end
	return target
end

local function Comment(text, ...)
	local target = GetCommentTarget(...)
	if not target.COMMENTS then
		target.COMMENTS = {}
	end
	table.insert(target.COMMENTS, text)
end

local function GetComment(...)
	local target = GetCommentTarget(...)
	if target then
		return target.COMMENTS
	end
end

function UpdateKV:Abilities()
	local origin = LoadKeyValues('scripts/npc/npc_abilities.txt')
	local target = LoadKeyValues('scripts/npc/npc_abilities_override.txt')

	ClearComments()

	for spell, data in pairs(target) do
		if type(data) == 'table' and data.AbilitySpecial then
			local src = origin[spell]
			if type(src) == 'table' and src.AbilityValues then
				data.AbilityValues = table.deepcopy(src.AbilityValues)

				for _, t in pairs(data.AbilitySpecial) do
					local newt = {}
					local name
					local value
					for k, v in pairs(t) do
						if IsValueName(k) then
							name = k
							value = v
						elseif k ~= 'var_type' then
							newt[k] = v
						end
					end

					local function optimise()
						if table.size(newt) == 0 then
							return value
						else
							newt.value = value
							return newt
						end
					end

					if name and value then
						local srct = data.AbilityValues[name]
						if srct == nil then
							Comment('#EXTRA', spell, 'AbilityValues', name)
							data.AbilityValues[name] = optimise()
						elseif type(srct) == 'table' then
							srct.value = value
							for k, v in pairs(newt) do
								if srct[k] == nil then
									if tostring(v):match('special_bonus_') and srct[v] then
										goto c1
									end
									Comment('#EXTRA', spell, 'AbilityValues', name, k)
								end
								srct[k] = v
								::c1::
							end
						else
							data.AbilityValues[name] = optimise()
						end
					end
				end

				for name, newt in pairs(data.AbilityValues) do
					data[name] = nil
				end

				data.AbilitySpecial = nil
			end
		end
	end

	self:Print(target)
end

function UpdateKV:Print(t, _comkey, _indent)
	_indent = _indent or ''

	local function fprint(s)
		print(_indent .. s)
	end

	local keys = {}
	for k, v in pairs(t) do
		table.insert(keys, k)
	end

	local function getorder(key)
		if key == 'var_type' then
			return -100
		end
		if IsValueName(key) then
			return -1
		end
		if key == 'value' then
			return -0.5
		end
		if key == 'AbilityValues' then
			return 1
		end
		if key == 'AbilitySpecial' then
			return 2
		end
		return 0
	end

	table.sort(keys, function(a, b)
		local na, nb = getorder(a), getorder(b)
		if na == nb then
			return a < b
		end
		return na < nb
	end)

	for _, k in ipairs(keys) do
		local v = t[k]

		local comkey = table.copy(_comkey or {})
		table.insert(comkey, k)
		local lcomments = GetComment(unpack(comkey))

		if lcomments then
			for _, comment in ipairs(lcomments) do
				fprint('// ' .. comment)
			end
		end

		if type(v) == 'table' then
			fprint('"' .. k .. '"{')
			self:Print(v, comkey, _indent .. '    ')
			fprint('}')
		else
			if type(v) == 'number' then
				v = math.floor(v * 1000 + 0.5) / 1000
			end
			fprint('"' .. k .. '"\t"' .. tostring(v) .. '"')
		end
	end
end

return UpdateKV