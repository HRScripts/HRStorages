---@class HRStoragesConfig
---@field language string
---@field target 'ox_target'|'qb-target'
---@field storageProp string
---@field storageRobbery { cooldown: { enable: boolean?, cooldown: number? }, itemRequired: string, minigameFunc: fun(): boolean }
---@field signal { enableOwnerSignal: boolean?, blipRadius: number?, color: integer, alpha: number }
---@field stashSettings { maxSlots: integer, maxWeight: integer }
---@field store { ped: { models: string[], coords: vector4 }, price: integer, getMoneyFrom: 'cash'|'bank'|'both', commandName: string }

---@class HRStoragesClientBridge
---@field addBoxZone fun(settigs: { coords: vector3, size: vector3, options: table[] }): string?
---@field removeZone fun(id: string)

---@class HRStoragesServerBridge
---@field get fun(playerId: integer, type: 'job'|'money'|'name', ...): integer|string?
---@field removeMoney fun(playerId: integer, account: 'cash'|'bank', amount: integer)

---@class HRStoragesTranslation
---@field invalid_inventory string
---@field cooldown_msg string
---@field robbery_itemRequiredNotFound string
---@field purchase_successful_1 string
---@field purchase_successful_2 string
---@field command_access_denied string
---@field not_enoughMoney string
---@field robberyInProgress string
---@field blipTitle string