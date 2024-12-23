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

for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    if self.settings.debug then
        local args = {...}
        for i, v in ipairs(args) do
            if type(v) == "table" then
                self:printTable(v)
            else
                print(tostring(v))
            end
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
        self.inied = true
        self.players = ModData.getOrCreate(self.name .. "_Players")
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

