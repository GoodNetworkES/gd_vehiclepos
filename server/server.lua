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

-- Eliminar vehículos sin jugadores
RegisterCommand(Config.ClearVehiclesCommand, function(source, args, rawCommand)
    local xPlayers = ESX.GetPlayers()
    local vehicles = GetAllVehicles()

    for _, vehicle in ipairs(vehicles) do
        local hasPlayer = false
        for _, playerId in ipairs(xPlayers) do
            local playerPed = GetPlayerPed(playerId)
            if IsPedInVehicle(playerPed, vehicle, false) then
                hasPlayer = true
                break
            end
        end
        if not hasPlayer then
            DeleteEntity(vehicle)
        end
    end
end, true)

function GetAllVehicles()
    local vehicles = {}
    for vehicle in EnumerateVehicles() do
        table.insert(vehicles, vehicle)
    end
    return vehicles
end

function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        if not handle or handle == -1 then
            EndFindVehicle(handle)
            return
        end
        local enum = {handle = handle, destructor = EndFindVehicle}
        setmetatable(enum, {__gc = function(enum)
            if enum.destructor and enum.handle then
                enum.destructor(enum.handle)
            end
            enum.destructor = nil
            enum.handle = nil
        end})
        local next = true
        repeat
            coroutine.yield(vehicle)
            next, vehicle = FindNextVehicle(handle)
        until not next
        enum.destructor, enum.handle = nil, nil
        EndFindVehicle(handle)
    end)
end
