if isServer() then
    return
end
local PR = PhunRewards
local PZ = PhunZones

function PR:checkZedSpecialDrops(zombie)

    local zData = zombie:getModData()

    local wasSprinter = zData.PhunRunners and zData.PhunRunners.sprinting == true
    local wasBandit = zData.brain ~= nil

    local distribution = PR.distributions or {
        drops = {}
    }
    local drops = distribution.drops or {}
    local reward = nil
    if wasBandit then
        reward = drops.bandits
    elseif wasSprinter then
        reward = drops.sprinters
    else
        reward = drops.zeds
    end
    if reward == nil or not reward.items then
        return
    end
    local zoneDifficulty = 0
    local zoneName = nil

    if PZ and PZ.getLocation then
        local zoneInfo = PZ:getLocation(zombie)
        zoneDifficulty = zoneInfo.difficulty or 0
        zoneName = zoneInfo.key
    end

    for k, v in pairs(reward.items or {}) do
        if v.enabled == true then
            local roll = true
            if v.zones then
                if v.zones.difficulty then
                    roll = zoneDifficulty >= (v.zones.difficulty.min or 0) and zoneDifficulty <=
                               (v.zones.difficulty.max or 1000)
                end
                if roll and v.zones.names and #v.zones.names > 0 then
                    roll = luautils.indexOf(v.zones.names, zoneName) ~= -1
                end
            end
            if roll then
                local chance = ZombRand(10000) + 1
                if chance < v.chance then
                    zombie:getInventory():AddItems(v.item, ZombRand(v.qty.min, v.qty.max))
                end
            end
        end
    end
end
