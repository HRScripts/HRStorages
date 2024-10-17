local bridge <const>, HRLib <const> = {}, HRLib ---@diagnostic disable-line: undefined-global
local config <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName())) --[[@as HRStoragesConfig]]
local GetResourceState = GetResourceState

bridge.framework = GetResourceState('ox_core'):find('start') and setmetatable({}, {
    __index = function(self, k)
        if not rawget(self, k) then
            self[k] = function(...)
                return exports.ox_core[k](...)
            end
        end

        return self[k]
    end
}) or GetResourceState('es_extended'):find('start') and exports.es_extended:getSharedObject() or GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject()

if not bridge.framework then
    return HRLib.StopMyself('warn', '\nFramework not found!\nThe resource HRStorages is stopped!')
end

bridge.type = bridge.framework.AddAcocountBalance and 'ox' or bridge.framework.GetPlayerFromId and 'esx' or bridge.framework.GetPlayerByPhone and 'qb'

---@param playerId integer
---@param type 'job'|'money'|'name'
---@vararg ...
---@return number|string?
bridge.get = function(playerId, type, ...)
    if HRLib.DoesIdExist(playerId) then
        if bridge.type == 'esx' then
            return (type == 'money' and bridge.framework.GetPlayerFromId(playerId).getAccount(... == 'cash' and 'money' or ...).money or type == 'job' and bridge.framework.GetPlayerFromId(playerId).getJob().name) or bridge.framework.GetPlayerFromId(playerId).getName()
        elseif bridge.type == 'qb' then
            local player <const> = bridge.framework.GetPlayer(playerId)
            return type == 'job' and player.PlayerData.job.name or type == 'money' and player.PlayerData.money[...] or ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname)
        elseif bridge.type == 'ox' then --TODO: make the getJob function in here while testing in ox server
            for k,v in pairs(bridge.framework.CallPlayer(playerId, 'getAccounts')) do
                print(k,v)
            end
            return type == 'money' and bridge.framework.CallPlayer(playerId, 'getAccount').balance or type == 'job' and 'test' or bridge.framework.CallPlayer(playerId, 'get', 'name')
        end
    end

    return nil
end

---@param playerId integer
---@param account 'cash'|'bank'
---@param amount integer
bridge.removeMoney = function(playerId, account, amount)
    if HRLib.DoesIdExist(playerId) then
        if bridge.type == 'esx' then
            exports.es_extended:getSharedObject().GetPlayerFromId(playerId).removeAccountMoney(account == 'cash' and 'money' or account, amount)
        elseif bridge.type == 'qb' then
            exports['qb-core']:GetCoreObject().Functions.GetPlayer(playerId).Functions.RemoveMoney(account, amount, 'purchasing storage')
        elseif bridge.type == 'ox' then
            if account == 'cash' then
                exports.ox_inventory:RemoveItem(playerId, account, amount)
            else
                bridge.framework.RemoveAccountBalance(playerId, account, amount)
            end
        end
    end
end

return bridge --[[@as HRStoragesServerBridge]]