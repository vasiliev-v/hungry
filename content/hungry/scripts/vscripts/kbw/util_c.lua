pnt = print

function IsBoss( hUnit )
	return hUnit:HasModifier('m_kbw_boss_flag')
end

function IsStatBoss(hUnit)
	return IsBoss(hUnit) and hUnit:GetModifierStackCount('m_kbw_boss_flag', hUnit) ~= 0
end

function IsMainBoss(hUnit)
	return hUnit:GetUnitName() == 'boss'
end

function IsDominator(item)
	local name = item:GetName()
	return name == 'item_helm_of_the_dominator' or name:match('^item_kbw_overlord')
end

function ParseKvFlags(s)
	if type(s) ~= 'string' then
		return 0
	end
	local flag = 0
	for sflag in s:gmatch('[%a%d_]+') do
		flag = bit.bor(flag, _G[sflag] or 0)
	end
	return flag
end

function GetAbilityKeyValues(ability)
	return GetAbilityKeyValuesByName(ability:GetName())
end

function GetAbilityTargetTeam(ability)
	return ParseKvFlags(GetAbilityKeyValues(ability).AbilityUnitTargetTeam)
end

function GetAbilityTargetType(ability)
	return ParseKvFlags(GetAbilityKeyValues(ability).AbilityUnitTargetType)
end

function GetAbilityTargetFlags(ability)
	return ParseKvFlags(GetAbilityKeyValues(ability).AbilityUnitTargetFlags)
end

function KbwBuildAutisticCommand(command, ...)
	return "@panorama_dispatch_event DOTACustomEvent('" ..
		json.encode({
			command = command,
			args = {...},
		}):gsub("'", "\\'")
	.. "')"
end