-- server.lua

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('playerConnected')
AddEventHandler('playerConnected', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.identifier
        local lastVehiclePos = LoadVehiclePosition(identifier)
        if lastVehiclePos then
            TriggerClientEvent('syncVehiclePosition', source, lastVehiclePos)
        end
    end
end)

RegisterServerEvent('playerDropped')
AddEventHandler('playerDropped', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.identifier
        local vehicle = GetPlayersLastVehicle(source)
        if vehicle then
            local pos = GetEntityCoords(vehicle)
            SaveVehiclePosition(identifier, pos)
        end
    end
end)

function LoadVehiclePosition(identifier)
    local result = MySQL.Sync.fetchScalar("SELECT position FROM user_vehicle_position WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    })
    if result then
        return json.decode(result)
    else
        return nil
    end
end

function SaveVehiclePosition(identifier, pos)
    MySQL.Async.execute("REPLACE INTO user_vehicle_position (identifier, position) VALUES (@identifier, @position)", {
        ['@identifier'] = identifier,
        ['@position'] = json.encode(pos)
    })
end

function GetPlayersLastVehicle(playerId)
    local result = MySQL.Sync.fetchScalar("SELECT last_vehicle FROM users WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    })
    if result then
        return json.decode(result)
    else
        return nil
    end
end
