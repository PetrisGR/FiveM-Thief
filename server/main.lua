local OnlinePlayers = {}
local StealablePlayers = {}
local ActiveRobberies = {}

local function GetClosestTarget(playerId)
	local result = {}
    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local playerBucket = GetPlayerRoutingBucket(playerId)

	for id, isOnline in pairs(OnlinePlayers) do
		if (Framework.Functions.CanPlayerBeStolen(id) and StealablePlayers[id] and isOnline and id ~= playerId) then
			local entity = GetPlayerPed(id)
			local coords = GetEntityCoords(entity)
            local dist = #(playerCoords - coords)
            local busy = false

            for k,v in pairs(ActiveRobberies) do
                if v == id then
                    busy = true 
                end
            end

            if not busy then
                if dist <= (result.dist or Config.Settings["MaxDistance"]) and (GetPlayerRoutingBucket(id) == playerBucket) then
                    result = {id = id, ped = NetworkGetNetworkIdFromEntity(entity), coords = coords, dist = dist}
                end
            end
		end
	end

	return result
end

function IsItemBlacklisted(item)
    local isBlacklisted = false

    for _, blacklistedItem in pairs(Config.Blacklisted["Items"]) do
        if item == blacklistedItem then
            isBlacklisted = true
            break
        end
    end

    return isBlacklisted
end

RegisterServerEvent('Thief:Server:SetState')
AddEventHandler('Thief:Server:SetState', function(hasHandsUp)
    local playerId = source
    
    if not StealablePlayers[playerId] and hasHandsUp then
        StealablePlayers[playerId] = true
    elseif StealablePlayers[playerId] and not hasHandsUp then
        StealablePlayers[playerId] = nil
    end
    
    TriggerClientEvent('Thief:Client:ConfirmState', playerId, hasHandsUp)
end)

RegisterServerEvent('Thief:Server:StealItem')
AddEventHandler('Thief:Server:StealItem', function(itemType, itemName, itemAmount, itemData)
    local playerId = source
    
    if not ActiveRobberies[playerId] then Framework.Functions.BanPlayer(playerId) return end

    if Framework.Functions.StealItem(playerId, ActiveRobberies[playerId], itemType, itemName, itemAmount, itemData) then
        local targetPed = GetPlayerPed(ActiveRobberies[playerId])
        TaskPlayAnim(targetPed, 'anim@mugging@victim@toss_ped@', 'throw_object_right_pocket_female', 1.0, 2.0, 4000, 50, false, false, false, false, false)
        Wait(4000)
        TriggerClientEvent('Thief:Client:SetHandsUp', ActiveRobberies[playerId])
        if Config.Notifications["Steal"] then
            if itemType ~= "weapon" then
                TriggerClientEvent('Thief:Client:SetHandsUp', ActiveRobberies[playerId])
                Framework.Functions.ShowNotification(playerId, Config["Messages"]["you_stole"].. " "..itemAmount.."x "..itemName.."")
                Framework.Functions.ShowNotification(ActiveRobberies[playerId], Config["Messages"]["thief_stole"].. " "..itemAmount.."x "..itemName.." " ..Config["Messages"]["from_you"])
            else
                Framework.Functions.ShowNotification(playerId, Config["Messages"]["you_stole"].. " "..itemName.."")
                Framework.Functions.ShowNotification(ActiveRobberies[playerId], Config["Messages"]["thief_stole"].. " "..itemName.." " ..Config["Messages"]["from_you"]) 
            end
        end
    else
        Framework.Functions.ShowNotification(playerId, Config["Messages"]["something_went_wrong"])
    end
    
    TriggerClientEvent('Thief:Client:SetRobberyMenu', playerId, NetworkGetNetworkIdFromEntity(GetPlayerPed(ActiveRobberies[playerId])), Framework.Functions.GetTargetItems(ActiveRobberies[playerId]))
end)

RegisterServerEvent('Thief:Server:ThiefRequest')
AddEventHandler('Thief:Server:ThiefRequest', function()
    local playerId = source
    local ped = GetPlayerPed(playerId)
    local closestTarget = GetClosestTarget(playerId)
    
    if not DoesEntityExist(ped) then return end

    if not closestTarget.id then 
        if Config.Notifications["NoPlayersNearby"] then
            Framework.Functions.ShowNotification(playerId, Config.Messages["no_players_nearby"])
        end
        return 
    end

    if not DoesEntityExist(NetworkGetEntityFromNetworkId(closestTarget.ped)) then 
        if Config.Notifications["NoPlayersNearby"] then
            Framework.Functions.ShowNotification(playerId, Config.Messages["no_players_nearby"])
        end
        return 
    end

    ActiveRobberies[playerId] = closestTarget.id
    
    TriggerClientEvent('Thief:Client:ChangeRobbedState', ActiveRobberies[playerId], true, NetworkGetNetworkIdFromEntity(GetPlayerPed(playerId)))
    TriggerClientEvent('Thief:Client:SetRobberyMenu', playerId, closestTarget.ped, Framework.Functions.GetTargetItems(ActiveRobberies[playerId]))
end)

RegisterServerEvent('Thief:Server:StopRobbery')
AddEventHandler('Thief:Server:StopRobbery', function()
    local playerId = source

    if ActiveRobberies[playerId] then
        TriggerClientEvent('Thief:Client:ResetThiefState', playerId)
        TriggerClientEvent('Thief:Client:ChangeRobbedState', ActiveRobberies[playerId], false)
        ActiveRobberies[playerId] = nil
    end
end)

RegisterServerEvent('Thief:Server:RobberyCancelled')
AddEventHandler('Thief:Server:RobberyCancelled', function()
    local playerId = source

    for thief,target in pairs(ActiveRobberies) do
        if playerId == thief or playerId == target then
            TriggerClientEvent('Thief:Client:ResetThiefState', thief)
            TriggerClientEvent('Thief:Client:ChangeRobbedState', target, false)
            ActiveRobberies[thief] = nil
            break
        end
    end
end)

RegisterServerEvent('Thief:Server:RegisterPlayer')
AddEventHandler('Thief:Server:RegisterPlayer', function()
    local playerId = source
    OnlinePlayers[playerId] = true
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    OnlinePlayers[playerId] = nil
end)
