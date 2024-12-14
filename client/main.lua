local HRLib <const>, Translation <const> = HRLib --[[@as HRLibClientFunctions]], Translation --[[@as HRStoragesTranslation]]
local config <const>, bridge <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRStoragesConfig]], HRLib.require(('@%s/client/bridge.lua'):format(GetCurrentResourceName())) --[[@as HRStoragesClientBridge]]
local storageProp <const>, currZones <const>, spawnedProps <const> = joaat(config.storageProp), {}, {}
local sellerSpawned, firstSpawned = nil, true

if not bridge then return end

-- OnEvents

local createEverything = function()
    if sellerSpawned then DeleteEntity(sellerSpawned) end

    -- Store creation

    local pedModel <const> = joaat(config.store.ped.models[math.random(1, #config.store.ped.models)])

    HRLib.RequestModel({ pedModel, storageProp })
    HRLib.RequestAnimDict('mini@strip_club@idles@bouncer@base')

    local seller <const> = CreatePed(4, pedModel, config.store.ped.coords, false, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch

    SetModelAsNoLongerNeeded(pedModel)
    TaskPlayAnim(seller, 'mini@strip_club@idles@bouncer@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(seller, true)
    SetBlockingOfNonTemporaryEvents(seller, true)
    SetEntityInvincible(seller, true)

    local blip <const> = HRLib.CreateBlip({
        type = 'forCoord',
        label = config.store.blip.label,
        specificOptions = {
            coords = vector3(config.store.ped.coords.x, config.store.ped.coords.y, config.store.ped.coords.z)
        },
        options = {
            scale = config.store.blip.scale,
            sprite = config.store.blip.sprite,
            colour = config.store.blip.colour
        }
    })

    local cmdName <const> = ('blip_%s'):format(blip)
    BeginTextCommandSetBlipName(cmdName)
    AddTextEntry(cmdName, config.store.blip.label)
    EndTextCommandSetBlipName(blip --[[@as integer]])

    if not sellerSpawned then
        bridge.addZone({
            entity = seller,
            options = {
                {
                    label = ('Purchase a storage (%s$)'):format(config.store.price),
                    distance = 2,
                    icon = 'fa-solid fa-credit-card',
                    onSelect = function()
                        TriggerServerEvent('HRStorages:purchaseStorage')
                    end
                }
            }
        })

        -- Spawning the props of already existing storages

        local storages <const> = HRLib.ServerCallback('HRStorages:getAllStorages')
        for i=1, #storages do
            local curr <const> = storages[i]
            if curr.position then
                local object <const> = CreateObject(storageProp, curr.position.x, curr.position.y, curr.position.z, false, true, true)
                spawnedProps[#spawnedProps+1] = object

                SetEntityHeading(object, curr.position.w)
                FreezeEntityPosition(object, true)
                TriggerEvent('HRStorages:addZone', object, HRLib.ServerCallback('isOwner', curr.owner), curr.owner, curr.stashId)
            end
        end

        sellerSpawned = seller
    end
end

HRLib.OnStart(nil, createEverything)
HRLib.OnPlSpawn(function()
    Wait(1000)

    if firstSpawned then
        createEverything()

        firstSpawned = false
    end
end)
HRLib.OnStop(nil, function()
    for i=1, #currZones do
        bridge.removeZone(currZones[i])
    end

    for i=1, #spawnedProps do
        local curr <const> = spawnedProps[i]
        if DoesEntityExist(curr) then
            DeleteEntity(curr)
        end
    end
end)

-- Callbacks

HRLib.CreateCallback('startGizmo', true, function()
    HRLib.RequestModel(storageProp)

    local object <const> = CreateObject(storageProp, GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 3.0, 0.0), true, true, true) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    local result <const> = exports.object_gizmo:useGizmo(object)
    spawnedProps[#spawnedProps+1] = result.handle

    FreezeEntityPosition(object, true)

    return { netId = NetworkGetNetworkIdFromEntity(object), pos = vector4(result.position.x, result.position.y, result.position.z, GetEntityHeading(object)) }
end)

HRLib.CreateCallback('isObjectAStorage', true, function(netId)
    for i=1, #spawnedProps do
        if spawnedProps[i] == NetworkGetEntityFromNetworkId(netId) then
            return true
        end
    end

    return false
end)

HRLib.CreateCallback('getClosestObject', true, function()
    local closestObject <const> = HRLib.ClosestObject()
    if closestObject then
        return { netId = NetworkGetNetworkIdFromEntity(closestObject.entity), distance = closestObject.distance }
    end

    return false
end)

-- Events

local robStartedAt, cooldown = nil, config.storageRobbery.cooldown.enable and (HRLib.ServerCallback('getTime') + (config.storageRobbery.cooldown.cooldown or 60000))
RegisterNetEvent('HRStorages:addZone', function(netId, isOwner, owner, stashId)
    if not DoesEntityExist(netId) then netId = NetworkGetEntityFromNetworkId(netId) end
    local storagePos <const> = GetEntityCoords(netId)
    bridge.addZone({
        entity = netId,
        options = isOwner and {
            {
                label = 'Open your storage',
                distance = 2,
                icon = 'fa-solid fa-box-open',
                onSelect = function()
                    if not exports.ox_inventory:openInventory('stash', stashId) then
                        HRLib.Notify(Translation.invalid_inventory, 'error')
                    end
                end
            }
        } or {
            {
                label = 'Start robbing the storage',
                distance = 2,
                icon = 'fa-solid fa-hand',
                onSelect = function()
                    local plItems <const> = exports.ox_inventory:GetPlayerItems()
                    for i=1, #plItems do
                        local curr <const> = plItems[i]
                        if curr.name == config.storageRobbery.itemRequired then
                            TaskPlayAnim(PlayerPedId(), 'mini@safe_cracking', 'dial_turn_clock_normal', 8.0, 0.0, -1, 1, 0, true, true, true)

                            local result <const> = config.storageRobbery.minigameFunc()
                            if result then
                                if config.storageRobbery.cooldown.enable and not robStartedAt then
                                    if not exports.ox_inventory:openInventory('stash', stashId) then
                                        HRLib.Notify(Translation.invalid_inventory, 'error')
                                        return
                                    end

                                    TriggerServerEvent('HRStorages:signal', owner, storagePos)
                                elseif config.storageRobbery.cooldown.enable and robStartedAt then
                                    local robbedBefore <const> = HRLib.ServerCallback('getTime') - robStartedAt
                                    if robbedBefore >= cooldown then
                                        HRLib.Notify(Translation.cooldown_msg:format(robbedBefore, cooldown - robbedBefore), 'error')
                                    end
                                else
                                    if not exports.ox_inventory:openInventory('stash', stashId) then
                                        HRLib.Notify(Translation.invalid_inventory, 'error')
                                        return
                                    end

                                    TriggerServerEvent('HRStorages:signal', owner, storagePos)
                                end
                            end

                            TriggerServerEvent('HRStorages:removeItem')
                            ClearPedTasks(PlayerPedId())

                            return
                        end
                    end

                    HRLib.Notify(Translation.robbery_itemRequiredNotFound:format(config.storageRobbery.itemRequired))
                end
            }
        }
    })
end)

RegisterNetEvent('HRStorages:blipSignal', function(coords)
    local blip <const>, blip2 <const> = AddBlipForRadius(coords, config.signal.blipRadius or 150), AddBlipForCoord(coords) ---@diagnostic disable-line: missing-parameter, param-type-mismatch
    PulseBlip(blip)
    SetBlipColour(blip, config.signal.color)
    SetBlipAlpha(blip, config.signal.alpha)
    SetBlipSprite(blip2, 60)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Translation.blipTitle)
    EndTextCommandSetBlipName(blip2)
    SetTimeout(60000, function()
        RemoveBlip(blip)
        RemoveBlip(blip2)
    end)
end)

RegisterNetEvent('HRStorages:removeAllStorages', function()
    for i=1, #spawnedProps do
        if DoesEntityExist(spawnedProps[i]) then
            DeleteEntity(spawnedProps[i])

            spawnedProps[i] = nil
        end
    end

    for i=1, #currZones do
        bridge.removeZone(currZones[i].id)

        currZones[i] = nil
    end
end)

-- Exports

exports('getStorages', function()
    local storages <const> = HRLib.ServerCallback('HRStorages:getAllStorages')
    for i=1, #storages do
        if HRLib.ServerCallback('isOwner', storages[i].owner) then
            return storages[i]
        end
    end
end)