local bridge <const>, HRLib <const> = {}, HRLib ---@diagnostic disable-line: undefined-global
local config <const> = HRLib.require(('@%s/config.lua'):format(GetCurrentResourceName()))

---@param resName string
---@return boolean
local isStarted = function(resName)
    return GetResourceState(resName):find('start') ~= nil
end

---@param settings { coords: vector3, size: vector3, options: table[] }
---@return string?
bridge.addBoxZone = function(settings)
    if config.target == 'ox_target' and isStarted(config.target) then
        return exports.ox_target:addBoxZone({
            coords = settings.coords,
            size = settings.size,
            options = settings.options
        })
    elseif config.target == 'qb-target' and isStarted(config.target) then
        local id = ('storages_zones_%s'):format(GetGameTimer() + math.random(1, 100))

        for i=1, #settings.options do
            settings.options[i].action = settings.options[i].onSelect
            settings.options[i].onSelect = nil
        end

        exports['qb-target']:AddBoxZone('whaatt?', settings.coords, settings.size.y, settings.size.x, {
            name = id,
            heading = 0.0,
            debugPoly = false,
            minZ = settings.size - settings.size * 2,
            maxZ = settings.size
        }, settings.options)

        return id
    end
end

---@param id string
bridge.removeZone = function(id)
    if config.target == 'ox_target' and isStarted(config.target) then
        exports.ox_target:removeZone(id)
    elseif config.target == 'qb-target' and isStarted(config.target) then
        exports['qb-target']:RemoveZone(id)
    end
end

return bridge --[[@as HRStoragesClientBridge]]