local bridge <const>, HRLib <const> = {}, HRLib ---@diagnostic disable-line: undefined-global
local config <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName()))

---@param resName string
---@return boolean
local isStarted = function(resName)
    return GetResourceState(resName):find('start') ~= nil
end

---@param settings { entity: integer, options: table[] }
bridge.addZone = function(settings)
    if config.target == 'ox_target' and isStarted(config.target) then
        return exports.ox_target:addLocalEntity(settings.entity, settings.options)
    elseif config.target == 'qb-target' and isStarted(config.target) then
        for i=1, #settings.options do
            settings.options[i].action = settings.options[i].onSelect
            settings.options[i].onSelect = nil
            settings.options[i].distance = nil
        end

        exports['qb-target']:AddTargetEntity(settings.entity, {
            options = settings.options,
            distance = 1.5
        })
    end
end

---@param entity integer
bridge.removeZone = function(entity)
    if config.target == 'ox_target' and isStarted(config.target) then
        exports.ox_target:removeLocalEntity(entity)
    elseif config.target == 'qb-target' and isStarted(config.target) then
        exports['qb-target']:RemoveTargetEntity(entity)
    end
end

return bridge --[[@as HRStoragesClientBridge]]