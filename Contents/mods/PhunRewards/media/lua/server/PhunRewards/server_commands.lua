if isClient() then
    return
end
local PR = PhunRewards
local Commands = {}

Commands[PR.commands.requestData] = function(playerObj)
    sendServerCommand(playerObj, PR.name, PR.commands.requestData, {
        playerIndex = playerObj:getPlayerNum(),
        data = PR.distributions,
        history = PR:getPlayerData(playerObj)
    })
end

return Commands
