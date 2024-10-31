local config <const> = {}

config.language = 'en'

config.target = 'ox_target' -- 'ox_target' or 'qb-target'

config.storageProp = 'prop_container_05mb'

config.storageRobbery = {
    cooldown = {
        enable = true,
        cooldown = 120, -- In seconds
    },
    itemRequired = 'lockpick',
    minigameFunc = function() -- This minigame requires https://github.com/T3development/t3_lockpick resource! If not found, HRStorages will stop with an error in the output
        return exports.t3_lockpick:startLockpick('lockpick', 2, 4)
    end
}

config.signal = {
    enableOwnerSignal = true, -- If true the owner will accept a signal
    blipRadius = 150.0,
    color = 3,
    alpha = 200 -- Max 1000
}

config.stashSettings = {
    maxSlots = 50,
    maxWeight = 100 -- In kilograms !! WARNING !! This is using for registering the stash and cannot be changed onto every stash every signle time!!
}

config.store = {
    ped = {
        models = { -- We take a random model from this table here. Configure this from https://docs.fivem.net/docs/game-references/ped-models
            'a_m_y_business_02',
            'a_m_y_business_01',
            'a_m_y_hasjew_01'
        },
        coords = vector4(-230.5639, -916.2744, 31.3108, 340.3738)
    },
    price = 30000,
    getMoneyFrom = 'both', -- 'cash' or 'bank' or 'both'
    commandName = 'createStorage'
}

config.admins = {
    allowedPlayers = {
        'discord:.....'
    },
    removeStorageName = 'removeStorage',
    removeAllStoragesName = 'removeAllStorages'
}

return config --[[@as HRStoragesConfig]]
