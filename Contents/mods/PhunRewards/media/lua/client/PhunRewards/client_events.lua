if isServer() then
    return
end
local Commands = require "PhunRewards/server_commands"
local PR = PhunRewards
local PZ = PhunZones

local function setup()
    Events.OnTick.Remove(setup)
    PR:ini()
    sendClientCommand(PR.name, PR.commands.requestData, {})
end

Events.OnTick.Add(setup)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PR.name and Commands[command] then
        Commands[command](arguments)
    end
end)

Events.OnZombieDead.Add(function(zed)
    PR:checkZedSpecialDrops(zed)
end);

if PZ then
    Events[PZ.events.OnPhunZonesPlayerLocationChanged].Add(function(playerObj, location, oldLocation)
        PR.zoneInfo[playerObj:getUsername()] = location
    end)
end
