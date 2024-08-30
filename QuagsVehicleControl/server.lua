RegisterNetEvent('QuagsVehicleControl:canUnlockVeh')
AddEventHandler('QuagsVehicleControl:canUnlockVeh', function(id, ent)
    local license  = false
    for _, i in pairs(GetPlayerIdentifiers(id)) do
        if string.sub(i, 1, string.len("steam:")) == "steam:" then
            license = i
        end
    end
    TriggerClientEvent("QuagsVehicleControl:canUnlockVeh-C", id, license, ent)
end)
RegisterNetEvent('QuagsVehicleControl:rollDownWindow:S')
AddEventHandler('QuagsVehicleControl:rollDownWindow:S', function(window, coords)
    TriggerClientEvent("QuagsVehicleControl:rollDownWindow", -1, window, coords)
end)
RegisterNetEvent('QuagsVehicleControl:interiorLight:S')
AddEventHandler('QuagsVehicleControl:interiorLight:S', function(coords)
    TriggerClientEvent("QuagsVehicleControl:interiorLight", -1, coords)
end)

RegisterNetEvent('QuagsVehicleControl:globalSet-S')
AddEventHandler('QuagsVehicleControl:globalSet-S', function(coords, id, name)
    TriggerClientEvent("QuagsVehicleControl:globalSet", -1, coords, id, name)
end)
RegisterNetEvent('QuagsVehicleControl:lockstat-S')
AddEventHandler('QuagsVehicleControl:lockstat-S', function(coords, stat)
    TriggerClientEvent("QuagsVehicleControl:lockstat", -1, coords, stat)
end)