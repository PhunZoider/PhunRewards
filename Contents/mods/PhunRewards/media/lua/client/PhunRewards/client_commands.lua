if isServer() then
    return
end
local PR = PhunRewards
local Commands = {}

Commands[PR.commands.addReward] = function(arguments)
    local player = getSpecificPlayer(arguments.playerIndex)
    if arguments.trait then
        local trait = TraitFactory.getTrait(arguments.trait)
        player:getTraits():add(trait:getType())
    else
        player:getInventory():AddItem(arguments.item, arguments.qty)
    end

end

Commands[PR.commands.requestData] = function(arguments)
    PR.distributions = {
        drops = arguments.data or {}
    }
    local history = PR:getPlayerData(getSpecificPlayer(arguments.playerIndex))
    history = arguments.history or {}
end

return Commands
