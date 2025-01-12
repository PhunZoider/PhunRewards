PhunRewards = {
    inied = false,
    name = "PhunRewards",
    commands = {
        dataLoaded = "PhunRewardsDataLoaded",
        reload = "PhunReqardsReload",
        requestData = "PhunRewardsRequestData",
        addReward = "PhunRewardsAddReward"
    },
    players = {},
    playersModified = 0,
    playersSaved = 0,
    zoneInfo = {},
    distributions = {},
    events = {
        OnPhunRewardsInied = "OnPhunRewardsInied"
    }
}

local Core = PhunRewards
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            self:printTable(v)
        else
            print(tostring(v))
        end
    end

end

function Core:onlinePlayers(all)

    local onlinePlayers;

    if not isClient() and not isServer() and not isCoopHost() then
        onlinePlayers = ArrayList.new();
        local p = getPlayer()
        onlinePlayers:add(p);
    elseif all then
        onlinePlayers = getOnlinePlayers();

    else
        onlinePlayers = ArrayList.new();
        for i = 0, getOnlinePlayers():size() - 1 do
            local player = getOnlinePlayers():get(i);
            if player:isLocalPlayer() then
                onlinePlayers:add(player);
            end
        end
    end

    return onlinePlayers;
end

local climateManager
function Core:setNightTime()
    if not climateManager then
        climateManager = getClimateManager()
    end
    -- Get the current season to calculate when is day time or night time
    if climateManager and climateManager.getSeason then
        local season = climateManager:getSeason()
        if season and season.getDawn then
            local time = getGameTime():getTimeOfDay()
            local dawn = season:getDawn()
            local dusk = season:getDusk() + 2
            self.isNight = time < dawn or time > dusk
        end
    end
end

function Core:printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core:printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:ini()
    if not self.inied then
        print("PhunRewards: Inied")
        self.inied = true
        self.players = ModData.getOrCreate(self.name .. "_Players")
        if isServer() then
            self:reload()
        else
            self:setNightTime()
        end
        triggerEvent(self.events.OnPhunRewardsInied)
    end

end

function Core:getPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    else
        key = playerObj:getUsername()
    end
    if key and string.len(key) > 0 then
        if not self.players then
            self.players = {}
        end
        if not self.players[key] then
            self.players[key] = {}
        end
        return self.players[key]
    end
end

