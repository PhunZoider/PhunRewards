if isServer() then
    return
end
local PhunRewards = PhunRewards

local function setup()
    Events.EveryOneMinute.Remove(setup)
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)

    end
end

local Commands = {}

Commands[PhunRewards.commands.addReward] = function(arguments)
    local player = getSpecificPlayer(arguments.playerIndex)
    player:getInventory():AddItem(arguments.item, arguments.qty)
end

Events.EveryOneMinute.Add(setup)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunRewards.name and Commands[command] then
        Commands[command](arguments)
    end
end)

