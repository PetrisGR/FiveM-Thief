local TargetPed = nil

local InputCooldowns = {
    ["Thief"] = 0,
    ["HandsUp"] = 0
}

local PlayerState = {
    ["IsStealing"] = false,
    ["IsBeingRobbed"] = false,
    ["HasHandsUp"] = false
}

local function StopHandsUpState()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    PlayerState["HasHandsUp"] = false
    TriggerServerEvent('Thief:Server:SetState', false)
end

local function LoadAnimDict(animDict)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end
end

local function MakeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

CreateThread(function()
	while true do
		Wait(100)
		if NetworkIsPlayerActive(PlayerId()) then
			TriggerServerEvent('Thief:Server:RegisterPlayer')
			break
		end
	end
    LoadAnimDict('anim@mugging@victim@toss_ped@')
end)

exports("IsPlayerStealing", function()
    return PlayerState["IsStealing"]
end)

exports("IsPlayerBeingRobbed", function()
    return PlayerState["IsBeingRobbed"]
end)

exports("HasPlayerHandsUp", function()
    return PlayerState["HasHandsUp"]
end)

RegisterNetEvent('Thief:Client:ResetThiefState')
AddEventHandler('Thief:Client:ResetThiefState', function()
    PlayerState["IsStealing"] = false
    TargetPed = nil
    ClearPedTasks(PlayerPedId())
    lib.hideContext(false)
    lib.closeInputDialog()
end)

RegisterNetEvent('Thief:Client:SetRobberyMenu')
AddEventHandler('Thief:Client:SetRobberyMenu', function(targetPedNetId, targetInventory)
    TargetPed = NetworkGetEntityFromNetworkId(targetPedNetId)

    if not PlayerState["IsStealing"] then
        PlayerState["IsStealing"] = true
        TaskAimGunAtEntity(PlayerPedId(), TargetPed, -1)
    end

    local serverId = GetPlayerServerId(PlayerId())

    if lib.getOpenContextMenu() then
        if lib.getOpenContextMenu() == 'thief_'..serverId..'' then
            lib.hideContext(false)
        end
    end

    local TargetStealableItems = {} 

    for k,v in pairs(targetInventory) do
        local itemIcon = Config.Menu.Icons[v.type]["default"]
        if Config.Menu.Icons[v.type].Specific then
            if Config.Menu.Icons[v.type].Specific[v.item] then
                itemIcon = Config.Menu.Icons[v.type].Specific[v.item]
            end
        end
        local itemLabel = v.label
        if not itemLabel then itemLabel = v.item end
        local itemTitle = v.amount.. "x " ..itemLabel
        local hasAmountSelection = true

        if v.type == "money" then hasAmountSelection = false itemTitle = v.amount.. ""..Config.Menu["Currency"].." " ..itemLabel end
        if v.type == "weapon" then hasAmountSelection = false itemTitle = itemLabel.. " ("..v.amount..")" end

        TargetStealableItems[#TargetStealableItems + 1] = {
            title = itemTitle,
            icon = itemIcon.icon,
            iconColor = itemIcon.iconColor,
            arrow = hasAmountSelection,
            onSelect = function()
                if v.type == "item" or v.type == "money" then
                    local input = lib.inputDialog(Config.Menu["DialogTitle"], {
                        {type = 'input', label = Config.Menu["InputItemTitle"], default = v.label, disabled = true},
                        {type = 'number', label = Config.Menu["InputAmountTitle"], description = Config.Menu["InputAmountDescription"], required = true, min = 1, max = v.amount}
                    })

                    if not input then 
                        lib.registerContext({
                            id = 'thief_'..serverId..'',
                            title = Config.Menu["Title"],
                            options = TargetStealableItems,
                            onExit = function()
                                TriggerServerEvent('Thief:Server:StopRobbery')
                                lib.closeInputDialog()
                            end
                        })
                        
                        lib.showContext('thief_'..serverId..'')
                        return 
                    end

                    TriggerServerEvent('Thief:Server:StealItem', v.type, v.item, input[2], v.data)
                elseif v.type == "weapon" then
                    TriggerServerEvent('Thief:Server:StealItem', v.type, v.item, v.amount, v.data)
                end
            end
        }
    end
    
    lib.registerContext({
        id = 'thief_'..serverId..'',
        title = Config.Menu["Title"],
        options = TargetStealableItems,
        onExit = function()
            TriggerServerEvent('Thief:Server:StopRobbery')
            lib.closeInputDialog()
        end
    })
    
    lib.showContext('thief_'..serverId..'')
end)

RegisterNetEvent('Thief:Client:ConfirmState')
AddEventHandler('Thief:Client:ConfirmState', function(state)
    local clientState = PlayerState["HasHandsUp"]

    if state ~= clientState then
        TriggerServerEvent('Thief:Server:SetState', clientState)
    end
end)

RegisterNetEvent('Thief:Client:ChangeRobbedState')
AddEventHandler('Thief:Client:ChangeRobbedState', function(isBeingRobbed, thiefPed)
    PlayerState["IsBeingRobbed"] = isBeingRobbed
    if isBeingRobbed then 
        MakeEntityFaceEntity(PlayerPedId(), NetworkGetEntityFromNetworkId(thiefPed))
    else
        StopHandsUpState()
    end
    Config.Functions.IsBeingRobbed(isBeingRobbed)
end)

RegisterNetEvent('Thief:Client:SetHandsUp')
AddEventHandler('Thief:Client:SetHandsUp', function()
    TaskPlayAnim(PlayerPedId(), Config.Animation["Dictionary"], Config.Animation["Name"], Config.Animation["BlendInSpeed"], Config.Animation["BlendOutSpeed"], -1, 50, 0, false, false, false)
    PlayerState["HasHandsUp"] = true
    TriggerServerEvent('Thief:Server:SetState', true)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local ped = PlayerPedId()

        if IsEntityDead(ped) then
            if PlayerState["IsStealing"] then
                TriggerServerEvent('Thief:Server:RobberyCancelled')
                lib.hideContext(false)
                lib.closeInputDialog()
            elseif PlayerState["HasHandsUp"] then
                StopHandsUpState()
            elseif PlayerState["IsBeingRobbed"] then
                TriggerServerEvent('Thief:Server:RobberyCancelled')
            else
                Citizen.Wait(2500)
            end
        else
            Citizen.Wait(1500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if PlayerState["HandsUp"] then
            if not IsEntityPlayingAnim(PlayerPedId(), Config.Animation["Dictionary"], Config.Animation["Name"], 3) then
                StopHandsUpState()
                if PlayerState["IsBeingRobbed"] then
                    TriggerServerEvent('Thief:Server:RobberyCancelled')
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    while PlayerState["IsStealing"] do
        Citizen.Wait(500)

        local myCoords = GetEntityCoords(PlayerPedId())
        local targetPed = NetwworkGetEntityFromNetworkId(TargetPed)

        if not DoesEntityExist(targetPed) then TriggerServerEvent('Thief:Server:RobberyCancelled') lib.hideContext(false) lib.closeInputDialog() end

        local targetCoords = GetEntityCoords(targetPed)

        if (#(myCoords - targetCoords) > Config.Settings["MaxDistance"]) then TriggerServerEvent('Thief:Server:RobberyCancelled') lib.hideContext(false) lib.closeInputDialog() end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if PlayerState["IsBeingRobbed"] then
            DisableAllControlActions(0)
            DisablePlayerFiring(PlayerId(), true)
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if InputCooldowns["Thief"] >= 1 then
            InputCooldowns["Thief"] = InputCooldowns["Thief"] - 1
        end
        if InputCooldowns["HandsUp"] >= 1 then
            InputCooldowns["HandsUp"] = InputCooldowns["HandsUp"] - 1
        end
    end
end)

RegisterCommand('$handsup', function()
    local ped = PlayerPedId()

    if InputCooldowns["HandsUp"] >= 1 then return end

    if IsPedInAnyVehicle(ped, true) then return end

    if PlayerState["IsBeingRobbed"] then return end

    if not PlayerState["HasHandsUp"] then

        if IsEntityDead(ped) then return end

        if IsPedRunning(ped) then return end

        InputCooldowns["HandsUp"] = Config.InputCooldowns["HandsUp"]

        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"))

        LoadAnimDict(Config.Animation["Dictionary"])
        TaskPlayAnim(ped, Config.Animation["Dictionary"], Config.Animation["Name"], Config.Animation["BlendInSpeed"], Config.Animation["BlendOutSpeed"], -1, 50, 0, false, false, false)
        PlayerState["HasHandsUp"] = true
        TriggerServerEvent('Thief:Server:SetState', true)
    else
        StopHandsUpState()
    end
end, false)

RegisterCommand('$thief', function()
    local ped = PlayerPedId()

    if InputCooldowns["Thief"] >= 1 then return end

    if IsPedInAnyVehicle(ped, true) then return end

    if not PlayerState["IsStealing"] then
        
        if IsEntityDead(ped) then return end

        InputCooldowns["Thief"] = Config.InputCooldowns["Thief"]

        if Config.Functions.CanPlayerSteal(ped) then
            TriggerServerEvent('Thief:Server:ThiefRequest')
        end
    else
        lib.hideContext(true)
    end
end, false)

RegisterKeyMapping('$handsup', 'Hands Up', 'keyboard', Config.Keybinds["HandsUp"])
RegisterKeyMapping('$thief', 'Thief', 'keyboard', Config.Keybinds["Thief"])
