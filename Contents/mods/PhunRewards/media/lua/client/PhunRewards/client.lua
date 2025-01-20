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
    local rads = 0

    if PZ and PZ.getLocation then
        local zoneInfo = PZ:getLocation(zombie) or {}
        zoneDifficulty = zoneInfo.difficulty or 0
        zoneName = zoneInfo.region or nil
        rads = zoneInfo.rads or 0
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
                    local radIncrease = 0
                    local min = v.qty.min
                    local max = v.qty.max
                    if rads and rads > 0 then
                        radIncrease = math.floor((v.qty.min + (rads / 100) * v.qty.min) + .5)
                        min = min + radIncrease
                        max = max + radIncrease
                    end
                    if self.isNight and v.night ~= 0 then
                        local increaseAmount = v.night or 1.3
                        local increase = math.floor((v.qty.min + (increaseAmount * v.qty.min)) + .5)
                        min = min + increase
                        max = max + increase
                    end
                    -- print("min=" .. min .. ", max = " .. max .. " radIncrease: " .. radIncrease)
                    local qty = ZombRand(min, (max + 1))
                    zombie:getInventory():AddItems(v.item, qty)
                end
            end
        end
    end
end
