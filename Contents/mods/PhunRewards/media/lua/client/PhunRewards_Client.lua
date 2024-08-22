if not isClient() then
    return
end
local PhunRewards = PhunRewards
local PhunZones = PhunZones

local function CheckZedSpecialDrops(zombie)

    local zData = zombie:getModData()

    local wasSprinter = zData.PhunRunners and zData.PhunRunners.sprinting == true
    local wasBandit = zData.PhunRunners and zData.PhunRunners.isBandit == true

    local pr = PhunRewards
    local distribution = pr.distributions or {
        drops = {}
    }
    local drops = distribution.drops or {}
    local reward = nil
    if wasBandit then
        reward = drops.bandits
    elseif wasSprinter then
        reward = drops.sprinters
    else
        reward = drops.zeds
    end
    if reward == nil or not reward.items then
        return
    end
    local zoneDifficulty = 0
    local zoneName = nil

    local pz = PhunZones
    if pz and pz.getLocation then
        local zoneInfo = pz:getLocation(zombie)
        zoneDifficulty = zoneInfo.difficulty or 0
        zoneName = zoneInfo.key
    end

    for k, v in pairs(reward.items or {}) do
        if v.enabled == true then
            local roll = true
            if v.zones then
                if v.zones.difficulty then
                    roll = zoneDifficulty >= (v.zones.difficulty.min or 0) and zoneDifficulty <=
                               (v.zones.difficulty.max or 1000)
                end
                if roll and v.zones.names and #v.zones.names > 0 then
                    roll = PhunTools:inArray(zoneName, v.zones.names)
                end
            end
            if roll then
                local chance = ZombRand(1000) + 1
                if chance < v.chance then
                    zombie:getInventory():AddItems(v.item, ZombRand(v.qty.min, v.qty.max))
                end
            end
        end
    end
    -- zombie:getModData().PhunRunners = nil
end

local function setup()
    Events.EveryOneMinute.Remove(setup)
    PhunRewards:ini()
    sendClientCommand(PhunRewards.name, PhunRewards.commands.requestData, {})
end

Events.OnZombieDead.Add(CheckZedSpecialDrops);

local Commands = {}

Commands[PhunRewards.commands.addReward] = function(arguments)
    local player = getSpecificPlayer(arguments.playerIndex)
    if arguments.trait then
        local trait = TraitFactory.getTrait(arguments.trait)
        player:getTraits():add(trait:getType())
    else
        player:getInventory():AddItem(arguments.item, arguments.qty)
    end

end

Commands[PhunRewards.commands.requestData] = function(arguments)
    PhunRewards.distributions = {
        drops = arguments.data or {}
    }
    local history = PhunRewards:getPlayerData(getSpecificPlayer(arguments.playerIndex))
    history = arguments.history or {}
end

Events.EveryOneMinute.Add(setup)

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunRewards.name and Commands[command] then
        Commands[command](arguments)
    end
end)

if PhunZones then
    Events[PhunZones.events.OnPhunZonesPlayerLocationChanged].Add(
        function(playerObj, location, oldLocation)
            PhunRewards.zoneInfo[playerObj:getUsername()] = location
        end)
end
