PhunRewards = {
    inied = false,
    name = "PhunRewards",
    commands = {
        dataLoaded = "dataLoaded",
        reload = "reload",
        requestData = "requestData",
        addReward = "addReward"
    },
    players = {},
    playersModified = 0,
    playersSaved = 0,
    zoneInfo = {},
    distributions = {},
    events = {
        OnPhunRewardsChanged = "OnPhunRewardsChanged",
        OnPhunRewardsCurrenciesUpdated = "OnPhunRewardsCurrenciesUpdated",
        OnPhunRewardsInied = "OnPhunRewardsInied"
    }
}

for _, event in pairs(PhunRewards.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunRewards:getPlayerData(playerObj)
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

function PhunRewards:ini()
    if not self.inied then
        self.inied = true
        triggerEvent(self.events.OnPhunRewardsInied)
    end

end
