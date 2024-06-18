if not isServer() then
    return
end
local PhunRewards = PhunRewards
local PhunStats = PhunStats
local PhunWallet = PhunWallet
local gameTime = getGameTime()

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
    return result
end

function PhunRewards:reload()

    local data = PhunTools:loadTable("PhunRewards.lua")
    local distributions = buildDistributions(data)
    if distributions then
        self.distributions = distributions
    end

end

function PhunRewards:export()
    if PhunTools then
        PhunTools:saveTable("PhunRewards.lua", self.currencies)
    end
end

function PhunRewards:doHourly()
    local stats = PhunStats.players

    local rewards = {"current", "total"}

    for i = 1, getOnlinePlayers():size() do

        local p = getOnlinePlayers():get(i - 1)
        local pstats = PhunStats:getPlayerData(p)

        local rewarded = self:getPlayerData(p)
        for _, rv in pairs(rewards) do
            for _, v in pairs(self.distributions[rv] or {}) do
                local lastHour = (rewarded[v.key] or {}).hours or 0
                if lastHour == 0 or v.repeating then
                    if ((pstats[rv].hours or 0) - lastHour) >= v.hours and (pstats[rv].kills or 0) >= v.kills then
                        rewarded[v.key] = {
                            hours = pstats[rv].hours,
                            kills = pstats[rv].kills,
                            age = getGameTime():getWorldAgeHours(),
                            when = getTimestamp(),
                            method = "item"
                        }

                        local qty = ZombRand(v.qty.min, v.qty.max)
                        PhunTools:addLogEntry("PhunRewards", p:getUsername(), v.key, v.item, qty)
                        self.playersModified = getTimestamp()

                        if PhunWallet.currencies and PhunWallet.currencies[v.item] then
                            rewarded[v.key].method = "currency"
                            -- this is a currency item
                            PhunWallet:adjustWallet(p, {
                                [v.item] = qty
                            })
                        else
                            sendServerCommand(p, self.name, self.commands.addReward, {
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

function PhunRewards:savePlayers()
    if self.playersModified > self.playersSaved then
        PhunTools:saveTable(self.name .. "_Players.lua", self.players)
        self.playersSaved = getTimestamp()
    end

end

local Commands = {}

Commands[PhunRewards.commands.requestData] = function(playerObj)
    sendServerCommand(playerObj, PhunRewards.name, PhunRewards.commands.requestData, {
        playerIndex = playerObj:getPlayerNum(),
        data = PhunRewards.distributions.drops,
        history = PhunRewards:getPlayerData(playerObj)
    })
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunRewards.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
Events.OnGameStart.Add(function()
    PhunRewards:ini()
end)

Events.OnInitGlobalModData.Add(function()
    PhunRewards:ini()
end)

if PhunStats then
    Events[PhunStats.events.OnPhunStatsInied].Add(function()

        Events.EveryHours.Add(function()
            PhunRewards:doHourly()
        end)

    end)
end

Events.EveryTenMinutes.Add(function()
    PhunRewards:savePlayers()
end)

Events[PhunRewards.events.OnPhunRewardsInied].Add(function()
    local playerData = PhunTools:loadTable(PhunRewards.name .. "_Players.lua") or {}
    PhunRewards.players = playerData
    PhunRewards:reload()
end)

-- Add a hook to save player data when the server goes empty
PhunTools:RunOnceWhenServerEmpties(PhunRewards.name, function()
    PhunRewards:savePlayers()
end)
