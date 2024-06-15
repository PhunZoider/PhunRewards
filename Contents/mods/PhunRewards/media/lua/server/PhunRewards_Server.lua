if not isServer() then
    return
end
local PhunRewards = PhunRewards
local gameTime = getGameTime()
local function buildDistributions(data)
    local result = {}
    for _, v in ipairs(data) do
        local formatted = {
            key = v.key or (v.type .. v.value),
            type = v.type,
            value = v.value,
            repeating = v.repeating == true,
            item = v.item,
            qty = v.qty or 1
        }
        if not result[v.type] then
            result[v.type] = {}
        end
        table.insert(result[v.type], formatted)
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

function PhunRewards:updatePlayerTenMin(playerObj)
    local data = self:getPlayerData(playerObj)
    data.hours = (data.hours or 0) + 0.16666667
    data.kills = tonumber(string.gsub(gameTime:getZombieKilledText(playerObj), "[^%d]", "") or "0")
end

function PhunRewards:updatePlayersTenMin()
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        self:updatePlayerTenMin(p)
    end
end

local Commands = {}

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunRewards.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
Events.OnGameStart.Add(function()
    PhunRewards:ini()
end)

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        local data = PhunRewards:getPlayerData(playerObj)
        local kills = string.gsub(gameTime:getZombieKilledText(playerObj), "[^%d]", "") or 0
        data.totalKills = (data.totalKills or 0) + kills
        data.kills = 0
        data.totalHours = (data.totalHours or 0) + data.hours
        data.hours = 0
    end
end)

Events.OnInitGlobalModData.Add(function()
    PhunRewards:ini()
end)

Events.EveryTenMinutes.Add(function()
    PhunRewards:updatePlayersTenMin()
end)

Events.EveryHours.Add(function()

    local stats = PhunStats.players

    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        local pstats = stats[p:getUsername()] or {
            current = {},
            total = {}
        }
        local data = PhunRewards:getPlayerData(p)
        local rewards = data.rewards

        for k, v in pairs(PhunRewards.distributions) do
            if k == "HOUR" then
                -- based on how many character hours have passed
                for _, dist in ipairs(v) do
                    -- for each "hour" distribuition
                    if not rewards[k] then
                        -- if no rewards have every been given for this type, create an empty table
                        rewards[k] = {}
                    end
                    local lastValue = rewards[k][dist.key] or 0
                    if lastValue == 0 or dist.repeating then
                        local delta = p:getHoursSurvived() - lastValue
                        if delta >= dist.value then
                            -- if the player has survived more hours than the value of the distribution
                            rewards[k][dist.key] = p:getHoursSurvived()
                            -- issue reward
                            print("Issue reward for " .. dist.key .. " to " .. p:getUsername() .. " for " .. delta ..
                                      " hours survived")
                            if PhunWallet.currencies and PhunWallet.currencies[dist.item] then
                                -- this is a bound currency item
                                PhunWallet:adjustWallet(p, {
                                    [dist.item] = dist.qty
                                })
                            else
                                -- this is a free item
                                for i = 1, dist.qty do
                                    print("Adding item: " .. dist.item)
                                    p:getInventory():AddItem(dist.item)
                                end
                            end
                        end
                    end
                end
            elseif k == "TOTALHOURS" then
                -- based on how many total hours have passed
                for _, dist in ipairs(v) do
                    if not rewards[k] then
                        rewards[k] = {}
                    end
                    local lastValue = rewards[k][dist.key] or 0
                    if lastValue == 0 or dist.repeating then
                        local hours = pstats.total.hours or 0
                        local delta = hours - lastValue
                        if delta >= dist.value then
                            -- if the player has survived more hours than the value of the distribution
                            rewards[k][dist.key] = hours
                            -- issue reward
                            print("Issue reward for " .. dist.key .. " to " .. p:getUsername() .. " for " .. hours ..
                                      " hours survived")
                            if PhunWallet.currencies and PhunWallet.currencies[dist.item] then
                                -- this is a bound currency item
                                PhunWallet:adjustWallet(p, {
                                    [dist.item] = dist.qty
                                })
                            else
                                -- this is a free item
                                print("Adding item: " .. dist.item .. " x " .. dist.qty .. " to " .. p:getUsername() ..
                                          " for " .. hours .. " hours survived")
                                -- p:getInventory():AddItem(dist.item, dist.qty)
                                sendServerCommand(p, PhunRewards.name, PhunRewards.commands.addReward, {
                                    playerIndex = p:getPlayerNum(),
                                    item = dist.item,
                                    qty = dist.qty
                                })
                            end
                        else
                            print("Not enough hours for reward: " .. dist.key .. " " .. delta .. " < " .. dist.value)
                        end
                    else
                        print("Not eligible for reward: " .. dist.key)
                    end

                    -- if (not rewards[k][dist.key]) or (rewards[k][dist.key] and dist.repeating) then
                    --     -- add it
                    --     print("Eligible for reward: " .. dist.key)
                    --     if (p:getHoursSurvived() + (data.totalHours or 0)) >= dist.value then
                    --         print("Adding reward: " .. dist.key)
                    --         rewards[k][dist.key] = (rewards[k][dist.key] or 0) + 1
                    --     end
                    -- end
                end
            end
        end
    end

end)

Events[PhunRewards.events.OnPhunRewardsInied].Add(function()
    local playerData = ModData.getOrCreate(PhunRewards.name .. "_Players")
    PhunRewards.players = playerData
    PhunRewards:reload()
end)
