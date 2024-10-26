function table.contains(t, value)
	for _, v in pairs(t) do
		if v == value then
			return true
		end
	end

	return false
end

function table.clone(t)
	local result = {}
	for k, v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.shuffled(t)
	t = table.clone(t)
	for i = #t, 1, -1 do
		-- TODO: RandomInt
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end

	return t
end

function table.merge(input1, input2)
	for i,v in pairs(input2) do
		input1[i] = v
	end
	return input1
end


function table.count(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end

    return c
end

function table.has_element_fit(t, func)
    for k, v in pairs(t) do
        if func(t, k, v) then
            return k, v
        end
    end
end

function table.findkey(t, v)
    for k, _v in pairs(t) do
        if _v == v then
            return k
        end
    end

    return nil
end

function table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.random(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    local key = keys[RandomInt(1, # keys)]
    return t[key], key
end

function table.shuffle(tbl)
    -- Must be a hash table
    local t = table.shallowcopy(tbl)
    for i = # t, 2, - 1 do
        local j    = RandomInt(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function table.deepshuffle(tbl)
    -- Must be a hash table
    local t = table.deepcopy(tbl)
    for i = # t, 2, - 1 do
        local j    = RandomInt(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function table.random_some(t, count)
    local key_table = table.make_key_table(t)
    key_table       = table.shuffle(key_table)
    local r         = {}
    for i = 1, count do
        local key = key_table[i]
        table.insert(r, t[key])
    end
    return r
end

-- Randomly select an element, with conditions
function table.random_with_condition(t, func)
    local keys = {}
    for k, v in pairs(t) do
        if func(t, k, v) then
            table.insert(keys, k)
        end
    end

    local key = keys[RandomInt(1, # keys)]
    return t[key], key
end

-- Return all keys as a table
function table.make_key_table(t)
    local r = {}
    for k, _ in pairs(t) do
        table.insert(r, k)
    end
    return r
end

-- Return all values as a table
function table.make_value_table(t)
    local r = {}
    for _, v in pairs(t) do
        table.insert(r, v)
    end
    return r
end

function table.print(t, i)
	if not i then i = 0 end
	if not t then return end
    for k, v in pairs(t) do
    	if type(v) == "table" then
    		print(string.rep(" ", i) .. k .. " : ")
    		table.print(v, i+1)
    	else
        	print(string.rep(" ", i) .. k, v)
        end
    end
end

function table.join(...)
    local arg = {...}
    local r = {}
    for _, t in pairs(arg) do
        if type(t) == "table" then
            for _, v in pairs(t) do
                table.insert(r, v)
            end
        else
            -- If it is a value, insert it directly into the table
            table.insert(r, t)
        end
    end

    return r
end


function table.extend(t1, t2)
	for _, item in ipairs(t2) do
		table.insert(t1, item)
	end
end


-- remove item
function table.remove_item(tbl,item)
	if not tbl then return end
    local i,max=1,#tbl
    while i<=max do
        if tbl[i] == item then
            table.remove(tbl,i)
            i = i-1
            max = max-1
        end
        i= i+1
    end
    return tbl
end

function table.deepmerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                table.deepmerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end


function table.exclude_keys(t1, t2)
	for _, v in pairs(t2) do
		if t1[v] then
			t1[v] = nil
		end
	end
end

function table.filter(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
    if filterIter(v, k, t) then out[k] = v end
  end

  return out
end

function table.filter_array(t, filterIter)
  local out = {}

  for k, v in ipairs(t) do
    if filterIter(v, k, t) then table.insert(out, v) end
  end

  return out
end