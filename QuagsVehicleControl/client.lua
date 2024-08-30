local isInVehControl = false
local toggleNeon = false

Citizen.CreateThread(function()
	DecorRegister("VehicleOwner", 3)
	DecorRegister("MasterOwner", 3)
	DecorRegister("Window0", 2)
	DecorRegister("Window1", 2)
	DecorRegister("Window2", 2)
	DecorRegister("Window3", 2)
    while true do
		Citizen.Wait(10)
		local playerPed = GetPlayerPed(-1)
		if IsPedInAnyVehicle(playerPed) then
			if GetPedConfigFlag(GetPlayerPed(-1), 120) and isInVehControl then
				closeVehControl()
			end
		    local veh = GetVehiclePedIsIn(playerPed)
		    local playerId = GetPlayerServerId(PlayerId())
		    local vehOwner = GetResourceKvpInt(veh .. "VehicleOwner")

		    if vehOwner ~= playerId and GetIsVehicleEngineRunning(veh) and GetPedInVehicleSeat(veh, -1) == playerPed then
		        setDecor(GetEntityCoords(veh), "VehicleOwner", playerId)
		    end

		    if IsControlPressed(0, 75) then
		        local startTime = GetGameTimer()
		        local endTime = startTime + 500
		        local cancel = false

		        while not cancel do
		            Citizen.Wait(0)
		            local currentTime = GetGameTimer()
		            if currentTime > startTime + 100 then
		                if currentTime < endTime then
		                    if IsControlPressed(0, 75) then
		                        SetVehicleEngineOn(veh, true, true)
		                        cancel = true
		                    end
		                else
		                    cancel = true
		                end
		            end
		        end
		    end
		elseif IsPedOnFoot(playerPed) and IsControlPressed(0, 38) then
		    local startTime = GetGameTimer()
		    local endTime = startTime + 500
		    local cancel = false

		    while not cancel do
		        Citizen.Wait(0)
		        local currentTime = GetGameTimer()
		        if currentTime > startTime + 100 then
		            if currentTime < endTime then
		                if IsControlJustPressed(0, 38) then
		                    toggleLock()
		                    cancel = true
		                end
		            else
		                cancel = true
		            end
		        end
		    end
		end
    end
end)
function setDecor(coords, name, id)
	TriggerServerEvent("QuagsVehicleControl:globalSet-S", coords, id, name)
end
RegisterNetEvent('QuagsVehicleControl:globalSet')
AddEventHandler('QuagsVehicleControl:globalSet', function(coords, id, name)
	SetResourceKvpInt(getNearestVehicle(10.0, coords)..name, id)
end)
RegisterNetEvent('QuagsVehicleControl:lockstat')
AddEventHandler('QuagsVehicleControl:lockstat', function(coords, stat)
	local veh = getNearestVehicle(10.0, coords)
	SetVehicleDoorsLocked(veh, stat)
	if stat == 2 then
		if not GetIsVehicleEngineRunning(veh) then
			SetVehicleEngineOn(veh, true, true)
			SetVehicleFullbeam(veh, true)
			SoundVehicleHornThisFrame(veh)
			Citizen.Wait(200)
			SetVehicleEngineOn(veh, false, true)
			SetVehicleFullbeam(veh, false)
		else
			SetVehicleFullbeam(veh, true)
			SoundVehicleHornThisFrame(veh)
			Citizen.Wait(200)
			SetVehicleFullbeam(veh, false)
		end
	end
end)
function toggleLock()
	local coords = GetEntityCoords(GetPlayerPed(-1))
	local vehicle = getNearestVehicle(10.0, coords)
			if GetResourceKvpInt(vehicle.."VehicleOwner") == GetPlayerServerId(PlayerId()) or GetResourceKvpInt(vehicle.."MasterOwner") == GetPlayerServerId(PlayerId()) then
				if GetVehicleDoorLockStatus(vehicle) == 2 then
					keyFob(vehicle, 'Vehicle Unlocked.')
		        	TriggerServerEvent("QuagsVehicleControl:lockstat-S", GetEntityCoords(vehicle), 1)
		        else
		        	keyFob(vehicle, 'Vehicle Locked.')
		        	TriggerServerEvent("QuagsVehicleControl:lockstat-S", GetEntityCoords(vehicle), 2)
		        end		
			end
end
function keyFob(veh, msg)
	ClearPedTasks(GetPlayerPed(-1))
    SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("WEAPON_UNARMED"), true)
    loadAnimDict( 'anim@mp_player_intmenu@key_fob@')
	TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, 750, 51, 0, false, false, false)
    PlaySoundFromEntity(-1, "Remote_Control_Fob", GetPlayerPed(-1), "PI_Menu_Sounds", true, 0)
    lib.notify({
		title = 'GU Vehicle Lock',
		iconAnimation = "shake",
		description = msg,
		position = 'top',
		type = 'inform'
	})
    RemoveAnimDict("anim@mp_player_intmenu@key_fob@");
end
function getNearestVehicle(radius, entcoords)
	local vehs = surveyVehicles(radius, entcoords)
	local vehicle = 0
		if json.encode(vehs) ~= "[]" then
			for _, i in pairs(vehs) do
		        local dist1 = #(GetEntityCoords(i.ent) - entcoords)
		        local dist2 = #(GetEntityCoords(vehicle) - entcoords)
		        if dist1 < dist2 then
		        	vehicle = i.ent
		        end
			end
		end
		return vehicle
end
function surveyVehicles(radius, entcoords)
	local tbl = {}
	for i in EnumerateVehicles() do
        local c1 = GetEntityCoords(i)
        local c2 = entcoords
        local dist = #(c1 - c2)
        if dist <= radius then
        	table.insert(tbl, {ent=i, dist=dist})
        end
    end
	return tbl
end
local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end

        enum.destructor = nil
        enum.handle = nil
    end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end

        local enum = {handle = iter, destructor = disposeFunc}
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
        coroutine.yield(id)
        next, id = moveFunc(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end
function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end
-----------------------------------------------------------------------------
-- NUI OPEN EXPORT/EVENT
-----------------------------------------------------------------------------

RegisterCommand("vehcontrol", function(source, args, rawCommand)
	if IsPedInAnyVehicle(PlayerPedId(), false) and not IsPauseMenuActive() then
		openVehControl()
	end
end, false)

RegisterKeyMapping('vehcontrol', 'Open Vehicle Menu', 'keyboard', DefaultOpen)

function openExternal()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		openVehControl()
	end
end

RegisterNetEvent('vehcontrol:openExternal')
AddEventHandler('vehcontrol:openExternal', function()
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		openVehControl()
	end
end)

-----------------------------------------------------------------------------
-- NUI OPEN/CLOSE FUNCTIONS
-----------------------------------------------------------------------------

function openVehControl()
	if not GetPedConfigFlag(GetPlayerPed(-1), 120) then
		isInVehControl = true
		SetNuiFocus(true, true)
		SendNUIMessage({
			type = "openGeneral"
		})
	end
end

function closeVehControl()
	isInVehControl = false
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "closeAll"
	})
end

RegisterNUICallback('NUIFocusOff', function()
	isInVehControl = false
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "closeAll"
	})
end)

-----------------------------------------------------------------------------
-- NUI CALLBACKS
-----------------------------------------------------------------------------

RegisterNUICallback('ignition', function()
    EngineControl()
end)

RegisterNUICallback('interiorLight', function()
	InteriorLightControl()
end)

RegisterNUICallback('doors', function(data, cb)
	DoorControl(data.door)
end)

RegisterNUICallback('seatchange', function(data, cb)
	SeatControl(data.seat)
end)

RegisterNUICallback('windows', function(data, cb)
	WindowControl(data.window, data.door)
end)

RegisterNUICallback('neonToggle', function(data, cb)
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	if isDriver() then
		if GetResourceKvpInt(vehicle.."MasterOwner") == 0 or GetResourceKvpInt(vehicle.."MasterOwner") == GetPlayerServerId(PlayerId()) then
			setDecor(GetEntityCoords(vehicle), "MasterOwner", GetPlayerServerId(PlayerId()))
	    	lib.notify({
						title = 'GU Vehicle Manager',
						iconAnimation = "shake",
						description = 'You now own this vehicle.',
						position = 'top',
						type = 'inform'
			})
	    else
	    	lib.notify({
						title = 'GU Vehicle Manager',
						iconAnimation = "shake",
						description = 'A player already owns this vehicle.',
						position = 'top',
						type = 'inform'
			})
		end
	end
end)

RegisterNUICallback('lockVehicle', function(data, cb)
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if isDriver() then
    	if GetVehicleDoorLockStatus(vehicle) == 2 then
        	SetVehicleDoorsLocked(vehicle, 1)
        else
        	SetVehicleDoorsLocked(vehicle, 2)
        end
    end
end)
function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end 
-----------------------------------------------------------------------------
-- ACTION FUNCTIONS
-----------------------------------------------------------------------------


Citizen.CreateThread(function()
while true do
	Citizen.Wait(250)
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
		if GetIsVehicleEngineRunning(vehicle) then
        		SendNUIMessage({
				type = "engineOn"
				})
        else
        		SendNUIMessage({
				type = "engineOff"
				})
    	end
    	if GetVehicleDoorLockStatus(vehicle) == 2 then
        	SendNUIMessage({
			type = "lockOn"
			})
        else
        	SendNUIMessage({
			type = "lockOff"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 4) > 0 then
        	SendNUIMessage({
			type = "frontHoodOn"
			})
        else
        	SendNUIMessage({
			type = "frontHoodOff"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
        	SendNUIMessage({
			type = "rearHoodOn"
			})
        else
        	SendNUIMessage({
			type = "rearHoodOff"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 0) > 0 then
        	SendNUIMessage({
			type = "d0On"
			})
        else
        	SendNUIMessage({
			type = "d0Off"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 1) > 0 then
        	SendNUIMessage({
			type = "d1On"
			})
        else
        	SendNUIMessage({
			type = "d1Off"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 2) > 0 then
        	SendNUIMessage({
			type = "d2On"
			})
        else
        	SendNUIMessage({
			type = "d2Off"
			})
        end
        if GetVehicleDoorAngleRatio(vehicle, 3) > 0 then
        	SendNUIMessage({
			type = "d3On"
			})
        else
        	SendNUIMessage({
			type = "d3Off"
			})
        end
        if GetResourceKvpInt(vehicle.."MasterOwner") == GetPlayerServerId(PlayerId()) then
        	SendNUIMessage({
			type = "underglowOn"
			})
        else
        	SendNUIMessage({
			type = "underglowOff"
			})
        end
        if IsVehicleInteriorLightOn(vehicle) then
        	SendNUIMessage({
			type = "intlOn"
			})
        else
        	SendNUIMessage({
			type = "intlOff"
			})
        end
    end
end
end)

function EngineControl()
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if isDriver() then
        SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), true, true)
    end
end

function InteriorLightControl()
	if isPassenger() then
		TriggerServerEvent("QuagsVehicleControl:interiorLight:S", GetEntityCoords(GetPlayerPed(-1)))
	end
end

function DoorControl(door)
	local playerPed = getPed()
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	if isDriver() then
		if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
			SetVehicleDoorShut(vehicle, door, false)
		else
			SetVehicleDoorOpen(vehicle, door, false)
		end
	end
end

function SeatControl(seat)
	local playerPed = getPed()
	if (IsPedSittingInAnyVehicle(playerPed)) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		if IsVehicleSeatFree(vehicle, seat) then
			SetPedIntoVehicle(getPed(), vehicle, seat)
		else
			lib.notify({
				title = 'GU Vehicle Controls',
				iconAnimation = "shake",
				description = "Seat Taken",
				position = 'top',
				type = 'inform'
			})
		end
	end
end
RegisterNetEvent('QuagsVehicleControl:rollDownWindow')
AddEventHandler('QuagsVehicleControl:rollDownWindow', function(window, coords)
	local veh = getNearestVehicle(10.0, coords)
	if DecorGetBool(veh, "Window"..window) then
		RollUpWindow(veh, window)
		DecorSetBool(veh, "Window"..window, false)
	else
		RollDownWindow(veh, window)
		DecorSetBool(veh, "Window"..window, true)
	end
end)
RegisterNetEvent('QuagsVehicleControl:interiorLight')
AddEventHandler('QuagsVehicleControl:interiorLight', function(coords)
	local veh = getNearestVehicle(10.0, coords)
	if IsVehicleInteriorLightOn(veh) then
		SetVehicleInteriorlight(veh, false)
	else
		SetVehicleInteriorlight(veh, true)
	end
end)
function WindowControl(window, door)
	local playerPed = getPed()
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	if isDriver() then
		if GetIsDoorValid(vehicle, door) then
           TriggerServerEvent("QuagsVehicleControl:rollDownWindow:S", window, GetEntityCoords(GetPlayerPed(-1)))
		end
	end
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function getPed()
return GetPlayerPed(GetPlayerFromServerId(GetPlayerServerId(PlayerId())))
end

RegisterNetEvent('QuagsVehicleControl:canUnlockVeh-C')
AddEventHandler('QuagsVehicleControl:canUnlockVeh-C', function(lic, ent)
	if StringToHash(lic) == DecorGetFloat(ent, "GameLicenseOwner") then
		while not NetworkHasControlOfEntity(ent) do
            Citizen.Wait(50)
            NetworkRequestControlOfEntity(ent)
        end
        if GetVehicleDoorLockStatus(ent) == 2 then
        	SetVehicleDoorsLocked(ent, 1)
        	TriggerEvent("QuagsNotify:Icon", "Vehicle", "Vehicle unlocked.", 5000, "info", "mdi-lock-open-variant")
        else
        	SetVehicleDoorsLocked(ent, 2)
        	TriggerEvent("QuagsNotify:Icon", "Vehicle", "Vehicle locked.", 5000, "info", "mdi-lock")
        end
	else
		TriggerEvent("QuagsNotify:Icon", "Information", "You do not own this vehicle.", 5000, "negative", "mdi-car-key")
	end
end)

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function isDriver()
	if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1)), -1) == GetPlayerPed(-1) then
		return true
	end
	return false
end

function isPassenger()
	if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1)), -1) == GetPlayerPed(-1) or GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1)), 0) == GetPlayerPed(-1) then
		return true
	end
	return false
end