if isClient() then
    return
end

local PR = PhunRewards
local PS = PhunStats
local Commands = require "PhunRewards/server_commands"
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.OnTickEvenPaused.Add(function()

    if emptyServerCalculate == true and emptyServerTickCount > 100 then
        if PR:onlinePlayers():size() == 0 then
            emptyServerCalculate = false
            PR:savePlayers()
        end
    elseif emptyServerTickCount > 100 then
        emptyServerTickCount = 0
    else
        emptyServerTickCount = emptyServerTickCount + 1
    end
end)

Events.EveryTenMinutes.Add(function()
    emptyServerCalculate = PR:onlinePlayers():size() > 0
end)

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)

Events.OnServerStarted.Add(function()
    PR:setNightTime()
end)

Events.OnInitGlobalModData.Add(function()
    PR:ini()
end)

if PS then
    Events[PS.events.OnReady].Add(function()
        print("PhunRewards: PhunStats ready")
        Events.EveryHours.Add(function()
            PR:doHourly()
        end)

    end)
else
    print("PhunRewards Error: PhunStats not found")
end

Events.EveryTenMinutes.Add(function()
    PR:savePlayers()
end)

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        -- a player died
        local rewarded = PS:getData(playerObj)
        for key in pairs(rewarded) do
            if key:sub(1, 9) == "CHARSTAT:" then
                rewarded[key] = nil
            elseif string.upper(rewarded[key].type or "") == "CHARSTAT" then
                rewarded[key] = nil
            end
        end
    end
end)
