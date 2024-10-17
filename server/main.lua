local HRLib <const>, Translation <const>, MySQL <const> = HRLib --[[@as HRLibServerFunctions]], Translation --[[@as HRStoragesTranslation]], MySQL
local config <const>, bridge <const>, storages = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRStoragesConfig]], HRLib.require(('@%s/server/bridge.lua'):format(GetCurrentResourceName())) --[[@as HRStoragesServerBridge]], json.decode(LoadResourceFile(GetCurrentResourceName(), 'storages.json') or 'null')
local ox_inventory <const> = exports.ox_inventory
config.stashSettings.maxWeight *= 1000

if not bridge then return end

-- OnEvents

HRLib.OnStart(nil, function()
    MySQL.rawExecute.await('CREATE TABLE IF NOT EXISTS `storages` (\n    `stashId` varchar(50) NOT NULL PRIMARY KEY,\n    `owner` varchar(48) NULL DEFAULT NULL,\n    `owner_name` text NULL DEFAULT NULL,\n    `creation_date` text NULL DEFAULT NULL,\n    `position` json NOT NULL DEFAULT \'{}\',\n    `loot` json NOT NULL DEFAULT \'{}\'\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;')

    storages = MySQL.query.await('SELECT * FROM `storages`;')

    for i=1, #storages do
        local curr <const> = storages[i]
        if not ox_inventory:GetInventory(curr.stashId, false) then
            ox_inventory:RegisterStash(curr.stashId, ('%s\'s storage'):format(curr.owner_name), config.stashSettings.maxSlots, config.stashSettings.maxWeight, nil, false)
        end
    end
end)

-- Callbacks

HRLib.CreateCallback('getTime', true, function()
    return os.time()
end)

HRLib.CreateCallback('isOwner', true, function(source, owner)
    return HRLib.PlayerIdentifier(source, 'license') == owner
end)

HRLib.CreateCallback('HRStorages:getAllStorages', false, function()
    local result <const> = MySQL.query.await('SELECT * FROM `storages`;')

    if result then
        for i=1, #result do
            local currPos <const> = json.decode(result[i].position)
            result[i].position = vector4(currPos.x, currPos.y, currPos.z, currPos.w)
        end
    end

    return result
end)

-- Events

RegisterNetEvent('HRStorages:purchaseStorage', function()
    local cash <const>, bank <const> = bridge.get(source, 'money', 'cash') --[[@as integer]], bridge.get(source, 'money', 'bank') --[[@as integer]]
    if config.store.getMoneyFrom == 'cash' and cash >= config.store.price or config.store.getMoneyFrom == 'bank' and bank >= config.store.price or config.store.getMoneyFrom == 'both' and cash + bank >= config.store.price then
        Player(source).state.canUseTheCommand = true

        if cash >= config.store.price or bank >= config.store.price then
            bridge.removeMoney(source, cash >= config.store.price and 'cash' or 'bank', config.store.price)
        elseif cash + bank >= config.store.price then
            bridge.removeMoney(source, 'bank', cash > bank and bank or cash)
            bridge.removeMoney(source, 'cash', config.store.price - cash > bank and bank or cash)
        end

        HRLib.Notify(source, Translation.purchase_successful_1, 'success', 6000)
        HRLib.Notify(source, Translation.purchase_successful_2:format(config.store.commandName), 'success', 6000)

        return true
    end

    HRLib.Notify(source, Translation.not_enoughMoney, 'error')

    return false
end)

RegisterNetEvent('HRStorages:signal', function(owner, coords)
    local pls <const> = GetPlayers()
    for i=1, #pls do
        local curr <const> = pls[i] --[[@as integer]]
        if bridge.get(curr, 'job') == 'police' then
            TriggerClientEvent('HRStorages:blipSignal', curr, coords)
            HRLib.Notify(curr, Translation.robberyInProgress, 'info')
        end

        if config.signal.enableOwnerSignal and HRLib.PlayerIdentifier(curr, 'license') == owner then
            TriggerClientEvent('HRStorages:blipSignal', curr, coords)
            HRLib.Notify(curr, Translation.robberyInProgress, 'info')
        end
    end
end)

RegisterNetEvent('HRStorages:removeItem', function()
    ox_inventory:RemoveItem(source, config.storageRobbery.itemRequired, 1)
end)

AddEventHandler('ox_inventory:closedInventory', function(_, invId)
    invId = HRLib.string.split(invId, ':', 'string', true)?[1]
    for i=1, #storages do
        if storages?[i].stashId == invId then
            MySQL.update.await('UPDATE `storages` SET `loot` = ? WHERE `stashId` = ?', { json.encode(ox_inventory:GetInventoryItems(invId, false)), invId })
        end
    end
end)

-- Commands

HRLib.RegCommand(config.store.commandName, false, true, function(_, _, IPlayer, FPlayer)
    if IPlayer.state.canUseTheCommand then
        local storagePos <const> = HRLib.ClientCallback('startGizmo', IPlayer.source)
        local stashId <const> = ('storages_stash_%s'):format(os.time() + math.random(1, 100))
        IPlayer.state.canUseTheCommand = false
        storages[#storages+1] = {
            stashId = stashId,
            owner = IPlayer.identifier.license,
            owner_name = bridge.get(IPlayer.source, 'name'),
            creation_date = os.date('%d/%m/%Y | %X'),
            position = { x = storagePos.x, y = storagePos.y, z = storagePos.z, w = storagePos.w }
        }

        local pls <const> = GetPlayers()
        for i=1, #pls do
            local curr <const> = tonumber(pls[i]) --[[@as integer]]
            TriggerClientEvent('HRStorages:addZone', curr, storagePos, HRLib.PlayerIdentifier(curr, 'license') == IPlayer.identifier.license, IPlayer.identifier.license, stashId)
        end

        MySQL.insert.await('INSERT INTO `storages` (`stashId`, `owner`, `owner_name`, `creation_date`, `position`) VALUES (?, ?, ?, ?, ?)', { stashId, IPlayer.identifier.license, bridge.get(IPlayer.source, 'name'), os.date('%d/%m/%Y | %X'), json.encode(storagePos) })
        ox_inventory:RegisterStash(stashId, ('%s\'s storage'):format(bridge.get(IPlayer.source, 'name')), config.stashSettings.maxSlots, config.stashSettings.maxWeight, nil, false)
    else
        FPlayer:Notify(Translation.command_access_denied, 'error')
    end
end, false, { help = 'Create a storage' })

-- Exports

exports('getAllStorages', function()
    return storages
end)