if isServer() then
    return
end
local Commands = require "PhunRewards/client_commands"
local PR = PhunRewards
local PZ = PhunZones

local function setup()
    Events.OnTick.Remove(setup)
    PR:ini()
    if isClient() then
        sendClientCommand(PR.name, PR.commands.requestData, {})
    end
end

Events.OnTick.Add(setup)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PR.name and Commands[command] then
        print("PhunRewards: Received command ", command)
        Commands[command](arguments)
    end
end)

Events.OnCreatePlayer.Add(function(player)
    if PR.isLocal then
        PR:setNightTime()
    end
end)

Events.EveryTenMinutes.Add(function()
    PR:setNightTime()
end)

Events.OnZombieDead.Add(function(zed)
    PR:checkZedSpecialDrops(zed)
end);

if PZ then
    Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, location, oldLocation)
        PR.zoneInfo[playerObj:getUsername()] = location
    end)
end
