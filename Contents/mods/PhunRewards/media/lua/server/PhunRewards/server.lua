if isClient() then
    return
end
local files = require "PhunRewards/files"
local PR = PhunRewards
local PS = PhunStats
local PW = PhunWallet

local function formatOption(data)

    local result = {}

    local hours = 0
    local kills = 0

    result.key = data.key
    result.hours = data.hours or 0
    result.kills = data.kills or 0
    result.item = data.item
    result.chance = (data.chance or 1) * 100
    result.qty = {
        min = 1,
        max = 1
    }
    result.repeating = data.repeating == true
    if type(data.qty) == "table" then
        result.qty.min = data.qty.min or result.qty.min or 1
        result.qty.max = data.qty.max or result.qty.max or 1
    elseif type(data.qty) == "number" then
        result.qty.min = data.qty
        result.qty.max = data.qty
    end
    result.enabled = data.enabled ~= false
    if data.zones then
        result.zones = {}
        if data.zones.difficulty then
            if type(data.zones.difficulty) == "number" then
                result.difficulty = {
                    min = data.zones.difficulty,
                    max = data.zones.difficulty
                }
            elseif type(data.zones.difficulty) == "table" then
                result.zones.difficulty = {
                    min = data.zones.difficulty.min or 0,
                    max = data.zones.difficulty.max or 1000
                }
            end
        end
        if data.zones.keys then
            result.zones.keys = {}
            for _, v in ipairs(data.zones.keys) do
                table.insert(result.zones.keys, v)
            end
        end
    end
    return result

end

local function formatDrop(data)

    local result = {}
    result.item = data.item
    result.chance = (data.chance or 1) * 100
    result.qty = {
        min = 1,
        max = 1
    }
    if type(data.qty) == "table" then
        result.qty.min = data.qty.min or result.qty.min or 1
        result.qty.max = data.qty.max or result.qty.max or 1
    elseif type(data.qty) == "number" then
        result.qty.min = data.qty
        result.qty.max = data.qty
    end
    result.enabled = data.enabled ~= false
    if data.zones then
        result.zones = {}
        if data.zones.difficulty then
            if type(data.zones.difficulty) == "number" then
                result.difficulty = {
                    min = data.zones.difficulty,
                    max = data.zones.difficulty
                }
            elseif type(data.zones.difficulty) == "table" then
                result.zones.difficulty = {
                    min = data.zones.difficulty.min or 0,
                    max = data.zones.difficulty.max or 1000
                }
            end
        end
        if data.zones.keys then
            result.zones.keys = {}
            for _, v in ipairs(data.zones.keys) do
                table.insert(result.zones.keys, v)
            end
        end
    end
    return result
end

local function buildDistributions(data)
    local result = {
        characterHours = {},
        charStats = {},
        hours = {},
        drops = {
            zeds = {
                items = {}
            },
            sprinters = {
                items = {}
            }
        }
    }

    local timely = {"current", "total"}

    for _, k in ipairs(timely) do
        for i, v in ipairs(data[k] or {}) do
            v.key = v.key or ("TIME:" .. tostring(i))
            local formatted = formatOption(v)
            if not result[k] then
                result[k] = {}
            end
            result[k][v.key] = formatted
        end
    end

    timely = {"zeds", "sprinters"}
    for _, k in ipairs(timely) do
        if data.drops and data.drops[k] and data.drops[k].items then
            for i, v in ipairs(data.drops[k].items or {}) do
                v.key = v.key or ("DROP:" .. tostring(i))
                local formatted = formatDrop(v)
                if not result.drops[k] then
                    result.drops[k] = {
                        items = {}
                    }
                end
                result.drops[k].items[v.key] = formatted
            end
        end
    end

    for i, v in ipairs(data.charStats or {}) do
        v.key = v.key or "CHARSTAT:" .. tostring(i)
        v.type = v.type or "CHARSTAT"
        result.charStats[v.key] = v
    end

    return result
end

function PR:reload()
    print("PhunRewards: Reloading")
    local data = files:loadTable("PhunRewards.lua")
    local distributions = buildDistributions(data)
    if distributions then
        PR.distributions = distributions
    end
end

function PR:export()
    files:saveTable("PhunRewards.lua", PR.currencies)
end

function PR:doHourly()

    local rewards = {"current", "total", "charStats"}

    for i = 1, getOnlinePlayers():size() do

        local p = getOnlinePlayers():get(i - 1)
        local pstats = PS:getData(p)

        local rewarded = PR:getPlayerData(p)

        for _, rv in pairs(rewards) do
            for _, v in pairs(PR.distributions[rv] or {}) do

                if not rewarded[v.key] or v.repeating then

                    if rv == "charStats" then
                        local currentValue = pstats.current[v.stat] or 0
                        if currentValue > v.value then

                            if v.trait then
                                rewarded[v.key] = {
                                    stat = v.stat,
                                    trait = v.trait,
                                    value = currentValue,
                                    age = getGameTime():getWorldAgeHours(),
                                    when = getTimestamp(),
                                    method = "trait"
                                }
                                PR.playersModified = getTimestamp()
                                files:addLogEntry("Phun.log", "PhunRewards:" .. v.key, p:getUsername(), v.trait, 1)
                                sendServerCommand(p, PR.name, PR.commands.addReward, {
                                    playerIndex = p:getPlayerNum(),
                                    trait = v.trait
                                })
                            end
                        end
                    else
                        if (pstats[rv].hours or 0) >= v.hours and (pstats[rv].kills or 0) >= (v.kills or 0) then

                            rewarded[v.key] = {
                                hours = pstats[rv].hours,
                                kills = pstats[rv].kills,
                                age = getGameTime():getWorldAgeHours(),
                                when = getTimestamp(),
                                method = "item"
                            }

                            local qty = ZombRand(v.qty.min, v.qty.max)
                            files:addLogEntry("Phun.log", "PhunRewards:" .. v.key, p:getUsername(), v.item, qty)
                            PR.playersModified = getTimestamp()

                            if PW and PW.currencies and PW.currencies[v.item] then
                                rewarded[v.key].method = "currency"
                                -- this is a currency item
                                PW:adjustWallet(p, {
                                    [v.item] = qty
                                })
                            else
                                sendServerCommand(p, PR.name, PR.commands.addReward, {
                                    playerIndex = p:getPlayerNum(),
                                    item = v.item,
                                    qty = qty
                                })
                            end

                        end
                    end
                end
            end
        end
    end
end

function PR:savePlayers()
    if PR.playersModified > PR.playersSaved then
        files:saveTable(PR.name .. "_Players.lua", {
            data = PR.players
        })
        PR.playersSaved = getTimestamp()
    end

end

