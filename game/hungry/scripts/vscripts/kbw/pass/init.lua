Pass = {}

Pass.DEFAULT_PET = {
	Model = 'models/pets/armadillo/armadillo.vmdl',
	ModelScale = 1,
	Material = '0',
	Particle = {},
	SpeedBonus = 50,
	MaxDistance = 350,
	Vision = 0,
	Flying = false,
	Pathing = false
}

LinkLuaModifier( "modifier_marker", self:Path('pass/modifier_marker'), LUA_MODIFIER_MOTION_NONE )

local bTest = false

Pass.PLAYERS = {}
Pass.PLAYERS_CODED = require('kbw/pass/players')
Pass.ServerKey = GetDedicatedServerKeyV2("IDI_NAXYU_BLYAT")
Pass.sURL = "https://dota-kbw.ru/game/donate.php"

local function add( id, bonus )
	local eff = Pass.PLAYERS[ id ] or {}
	Pass.PLAYERS[ id ] = eff
	for k, v in pairs( bonus ) do
		if type(eff[k]) ~= 'table' then
			eff[k] = {eff[k]}
		end
		if type(v) ~= 'table' then
			v = {v}
		end
		for _, name in pairs(v) do
			table.insert( eff[k], name )
		end
	end
end

local _MayBeVisible_checkers = {}
function CDOTA_BaseNPC:MayBeVisibleAA( team )
	if not self:IsInvisible() then
		return true
	end
	
	local unit_checker = _MayBeVisible_checkers[ team ]
	if not exist( unit_checker ) then
		unit_checker = CreateUnitByName( 'npc_dota_thinker', Vector(0,0,0), false, nil, nil, team )
		unit_checker:AddNewModifier( unit_checker, nil, 'modifier_marker', { no_collision = 1 } )
		_MayBeVisible_checkers[ team ] = unit_checker
	end
	
	return unit_checker:CanEntityBeSeenByMyTeam( self )
end

function CDOTA_BaseNPC:IsVisibleAA( team )
	local unit_checker = _MayBeVisible_checkers[ team ]
	if not exist( unit_checker ) then
		unit_checker = CreateUnitByName( 'npc_dota_thinker', Vector(0,0,0), false, nil, nil, team )
		unit_checker:AddNewModifier( unit_checker, nil, 'modifier_marker', { no_collision = 1 } )
		_MayBeVisible_checkers[ team ] = unit_checker
	end	
	return unit_checker:CanEntityBeSeenByMyTeam( self )
end

function Pass:GetPlayers()
	local tRequestData = {}
	
	for nPlayer = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		local nSteam = tostring(PlayerResource:GetSteamID( nPlayer ))
		if tonumber(nSteam) > 0 then
			tRequestData[ nPlayer ] = nSteam
		end
	end
	
	local sJsonData = json.encode( tRequestData )
	
	local request = CreateHTTPRequestScriptVM( "POST", self.sURL )
	if not request then
		return 1/30
	end

	request:SetHTTPRequestHeaderValue("Dedicated-Server-Key", self.ServerKey)
	request:SetHTTPRequestHeaderValue("Type-Request", "RequestData")
	request:SetHTTPRequestHeaderValue("Players", sJsonData)
	request:Send( function( response )
		if response.StatusCode == 200 then
			local sData = json.decode( response.Body )
			--print(response.Body)
			
			if sData then
				for id, t in pairs(sData) do
					local pets = {}
					local effects = {}
					
					if exist(t['pets']) then
						for value in string.gmatch(t['pets'], '([^, *]+)') do
							pets[#pets+1] = value 
						end		
					end
					
					if exist(t['effects']) then
						for value in string.gmatch(t['effects'], '([^, *]+)') do
							effects[#effects+1] = value 
						end		
					end
				
					add(tonumber(id), {
						Pet = pets,
						Effect = effects
					})
				end	
			end
		end
	end )
end

Pass.PETS = require 'kbw/pass/pets'
Pass.EFFECTS = require 'kbw/pass/effects'
LinkLuaModifier( 'm_pet', 'kbw/pass/modifier_pet', 0 )

function ParticleManager:DestroyAfter( particle, delay )
	delay = delay or 0
	Schedule( delay, function()
		ParticleManager:DestroyParticle( particle, true )
		ParticleManager:ReleaseParticleIndex( particle )
	end )
end


local function Rotate2D( v, angle )
	local v_angle = math.atan2( v.y, v.x )
	angle = angle + v_angle
	local len = v:Length2D()
	v = Vector( math.cos( angle ) * len, math.sin( angle ) * len, v.z )
	return v
end

local function IsVector( obj )
	return type(obj) == 'userdata' and obj.Length2D
end

local function ToVector( unit )
	if type(unit) == 'userdata' and unit.Length2D then
		return unit
	elseif type(unit) == 'table' then
		if unit.GetOrigin then
			return unit:GetOrigin()
		else
			local vResult
			pcall( function()
				vResult = Vector( 	tonumber(unit.x) or tonumber(unit[1])	,
									tonumber(unit.y) or tonumber(unit[2])	,
									tonumber(unit.z) or tonumber(unit[3])	)
			end )
			if vResult then
				return vResult
			end
		end
	elseif type(unit) == 'string' then
		local t = {}
		for coord in unit:gmatch('%d+') do
			table.insert( t, tonumber(coord) )
		end
		return ToVector( t )
	end
	Debug.print( 'ToVector', 'Cannot transform ' .. tostring(unit) )
end

local function VectorDelta( unit1, unit2 )
	return ToVector( unit2 ) - ToVector( unit1 )
end

local function Distance( unit1, unit2 )
	return #VectorDelta( unit1, unit2 )
end

local function Distance2D( unit1, unit2 )
	return VectorDelta( unit1, unit2 ):Length2D()
end

local function jsToVector( v )
	return Vector( v['0'], v['1'], v['2'] )
end

local function RandomVectorC( l )
	return RandomVector( l * math.sqrt( math.random() ) )
end

local function QuickSpawn( unit_name, info )
	info = table.overlay({
		vPos = nil,
		bClearSpace = true,
		team = nil,
		hOwner = nil
	}, info )
	if info.team == nil then
		if info.hOwner then
			info.team = info.hOwner:GetTeam()
		else
			info.team = DOTA_TEAM_NEUTRALS
		end
	end
	if info.vPos == nil then
		if info.hOwner then
			info.vPos = info.hOwner:GetOrigin()
		else
			info.vPos = Vector(0,0,0)
		end
	end
	local unit = CreateUnitByName( unit_name, info.vPos, info.bClearSpace, info.hOwner, info.hOwner, info.team )
	
	--local unit_kv = unit:GetKV()
	
	--if unit_kv.HullRadius then
	--	unit:SetHullRadius( tonumber( unit_kv.HullRadius ) )
	--end
	
	return unit
end

function Pass:RegisterHero( hero )
	local pid = hero:GetPlayerOwnerID()
	if pid == nil or pid < 0 then return end
	
	local steam = tonumber(tostring(PlayerResource:GetSteamID( pid )))
	local steam32 = PlayerResource:GetSteamAccountID(pid)
	
	local player_info = table.overlay(
		self.PLAYERS_CODED[ steam32 ] or {},
		self.PLAYERS[ steam ] or {}
	)
	
	if bTest then
		player_info = {Effect = {'DARK_WINGS', 'GRASS'}, Pet = 'PUDGE_DOG'}
	end
	if type(player_info) ~= 'table' then return end
	
	if player_info.Pet then
		if type(player_info.Pet) == 'table' then
			for _, pet_id in pairs( player_info.Pet ) do
				if type(pet_id) == 'string' then
					self:CreatePet( hero, pet_id )
				end
			end
		elseif type(player_info.Pet) == 'string' then
			self:CreatePet( hero, player_info.Pet )
		end
	end

	if player_info.Effect then
		if type(player_info.Effect) == 'table' then
			for _, effect_id in pairs( player_info.Effect ) do
				if type(effect_id) == 'string' then
					self:CreateEffect( hero, effect_id )
				end
			end
		elseif type(player_info.Effect) == 'string' then
			self:CreateEffect( hero, player_info.Effect )
		end
	end
end

function Pass:CreateParticle( unit, info )
	if type(info) == 'string' then
		ParticleManager:CreateParticle( info, PATTACH_ABSORIGIN_FOLLOW, unit )
	elseif type(info) == 'table' then
		if info.Name then
		
			if info.WorldAttach then
				local team = unit:GetTeam()
				local team_enemy = unit:GetOpposingTeamNumber()
				local particle = ParticleManager:CreateParticleForTeam( info.Name, PATTACH_WORLDORIGIN, unit, team )
				local particle_enemy
				local death_time
				
				if info.ControlPoints then
					unit:SetThink( function()					
						if not exist( unit ) and particle then
							ParticleManager:DestroyParticle( particle, true )
							ParticleManager:ReleaseParticleIndex( particle )									
							
							particle = nil
							if particle_enemy then
								ParticleManager:DestroyParticle( particle_enemy, true )
								ParticleManager:ReleaseParticleIndex( particle_enemy )									
								
								particle_enemy = nil							
							end
							return
						end
						
						if unit:IsOutOfGame() then
							if particle then
								ParticleManager:DestroyParticle( particle, true )
								ParticleManager:ReleaseParticleIndex( particle )										
								
								particle = nil
								if particle_enemy then
									ParticleManager:DestroyParticle( particle_enemy, true )
									ParticleManager:ReleaseParticleIndex( particle_enemy )											
									
									
									particle_enemy = nil							
								end
								death_time = -1								
							end
						else
							if unit:IsAlive() then
								if death_time then
									death_time = nil
									if particle == nil then
										particle = ParticleManager:CreateParticleForTeam( info.Name, PATTACH_WORLDORIGIN, unit, team )
									end
								end
									
								if particle_enemy then
									if not unit:IsVisibleAA( team_enemy ) then
										ParticleManager:DestroyParticle( particle_enemy, true )
										ParticleManager:ReleaseParticleIndex( particle_enemy )
										particle_enemy = nil
									end
								else
									if unit:IsVisibleAA( team_enemy ) then
										particle_enemy = ParticleManager:CreateParticleForTeam( info.Name, PATTACH_WORLDORIGIN, unit, team_enemy )
									end
								end
							else
								if death_time then
									if death_time > 0 then
										if GameRules:GetGameTime() > death_time then
											if particle then
												ParticleManager:DestroyParticle( particle, false )
												ParticleManager:ReleaseParticleIndex( particle )
												particle = nil
												if particle_enemy then
													ParticleManager:DestroyParticle( particle_enemy, false )
													ParticleManager:ReleaseParticleIndex( particle_enemy )
													particle_enemy = nil
												end
											end
											death_time = -1
										end
									end
								else
									death_time = GameRules:GetGameTime() + ( info.DeathTime or 0 )
								end
							end
						end
						
						if not particle then
							return 0.1
						end
						
						for i, attach_info in pairs( info.ControlPoints ) do
							local attach
							local vForward
							
							if IsVector( attach_info ) then
								ParticleManager:SetParticleControl( particle, i, attach_info )
							else
							
								if type(attach_info) == 'table' then
									attach = attach_info.Attach
									vForward = attach_info.Forward
								end
								
								if type(attach) ~= 'string' then
									attach = 'attach_hitloc'
								end
								attach = unit:ScriptLookupAttachment( attach )
								
								local vPos = unit:GetAttachmentOrigin( attach )
								ParticleManager:SetParticleControl( particle, i, vPos )
								if particle_enemy then
									ParticleManager:SetParticleControl( particle_enemy, i, vPos )
								end
								
								if vForward then
									local vForward_base = unit:GetForwardVector()
									if type(vForward) == 'number' then
										vForward = Rotate2D( vForward_base, vForward / 180 * math.pi )
									end
									if type(vForward) ~= 'userdata' then
										vForward = vForward_base
									end
									ParticleManager:SetParticleControlForward( particle, i, vForward )
									if particle_enemy then
										ParticleManager:SetParticleControlForward( particle_enemy, i, vForward )
									end
								end
								
							end
						end
						
						return 0.01
					end, 'ParticleUpd_' .. tostring(particle) )
				end
			else
				local particle = ParticleManager:CreateParticle( info.Name, PATTACH_ABSORIGIN_FOLLOW, unit )
				-- ParticleManager:SetParticleAlwaysSimulate( particle )
				for i, attach in pairs( info.ControlPoints or {} ) do
					local nAttachType = PATTACH_POINT_FOLLOW
					if IsVector( attach ) then
						ParticleManager:SetParticleControl( particle, i, attach )
					else
						if type(attach) == 'number' then
							nAttachType = attach
							attach = nil
						elseif type(attach) ~= 'string' then
							attach = 'attach_hitloc'
						end
						ParticleManager:SetParticleControlEnt( particle, i, unit, nAttachType, attach, unit:GetOrigin(), true )
					end
				end
				Timer( function()
					if exist( unit ) then
						return 1
					end
					ParticleManager:DestroyParticle( particle, true )
					ParticleManager:ReleaseParticleIndex( particle )
				end )
			end
			
		else
			for _, particle_info in ipairs( info ) do
				self:CreateParticle( unit, particle_info )
			end
		end
	end
end

function Pass:GetEffectInfo( effect_id )
	return self.EFFECTS[ effect_id ]
end

function Pass:CreateEffect( unit, effect_id )
	self:CreateParticle( unit, self:GetEffectInfo( effect_id ) )
end

function Pass:GetPetInfo( pet_id )
	local pet_info = self.PETS[ pet_id ]
	if type(pet_info) ~= 'table' then return end
	return table.overlay( self.DEFAULT_PET, pet_info )
end

function Pass:CreatePet( owner, pet_id )
	local pet_info = self:GetPetInfo( pet_id )
	if type(pet_info) ~= 'table' then return end

	local pet = QuickSpawn( 'unit_custom_pet', {
		vPos = owner:GetOrigin() + RandomVectorC( pet_info.MaxDistance ),
		team = owner:GetTeam(),
		owner = owner
	})
	pet.IsPet = true
	
	local mod = pet:AddNewModifier( pet, nil, 'm_pet', { model = pet_info.Model } )
	if pet_info.Flying then
		mod.Flying = true
		pet_info.Zoffset = pet_info.Zoffset or 228
	end
	if pet_info.Pathing then
		mod.Pathing = true
	end
	if pet_info.Zoffset then
		mod:SetStackCount( pet_info.Zoffset )
	end
	
	pet:SetModelScale( pet_info.ModelScale )
	pet:SetMaterialGroup( pet_info.Material )
	self:CreateParticle( pet, pet_info.Particle )
	
	pet:SetDayTimeVisionRange( pet_info.Vision )
	pet:SetNightTimeVisionRange( pet_info.Vision )
	
	local last_target
	Timer( function()
		if not ( exist( pet ) and pet:IsAlive() ) then
			return
		end
	
		if not exist(owner) then
			pet:Destroy()
			return
		end
		
		if not owner:IsAlive() then
			if owner:IsRealHero() then
				pet:ForceKill(false)
				Timer( function()
					if exist( pet ) then
						pet:Destroy()
					end
				end, 5 )
			
				Timer( function()
					if exist(owner) and owner:IsAlive() then
						Pass:CreatePet( owner, pet_id )
						return
					end
					return 1/30
				end )
			else
				pet:Destroy()
			end			
			return
		end
		
		local speed = owner:GetMoveSpeedModifier( owner:GetBaseMoveSpeed(), true )
		pet:SetBaseMoveSpeed( speed + pet_info.SpeedBonus )
		
		if owner:IsInvisible() then
			pet:AddNewModifier( pet, nil, 'modifier_invisible', {} )
		else
			pet:RemoveModifierByName('modifier_invisible')
		end
		
		local distance = Distance2D( pet, owner )
		if distance > pet_info.MaxDistance + 600 then
			FindClearSpaceForUnit( pet, owner:GetOrigin() + RandomVectorC( pet_info.MaxDistance ), false )
			pet:Stop()
		elseif distance > pet_info.MaxDistance + 200 then
			if RandomFloat(0,100) < 6 or
			   not last_target or Distance2D( last_target, pet ) < 10 then
				last_target = owner:GetOrigin() + RandomVectorC( pet_info.MaxDistance )
				pet:MoveToPosition( last_target )
			end
		else
			last_target = nil
			if RandomFloat(0,100) < 6 then
				pet:MoveToPosition( owner:GetOrigin() + RandomVectorC( pet_info.MaxDistance ) )
			end
		end
	
		return 0.1
	end )
end