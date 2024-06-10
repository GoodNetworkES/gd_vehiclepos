-- client.lua

local lastVehiclePos = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SaveInterval)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if DoesEntityExist(vehicle) then
            lastVehiclePos = GetEntityCoords(vehicle)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    TriggerServerEvent('playerConnected')
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('playerConnected')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        TriggerServerEvent('playerDropped')
    end
end)
