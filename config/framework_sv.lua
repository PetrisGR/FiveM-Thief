Framework = {
    Object = (GetResourceState("es_extended") == "started" and exports['es_extended']:getSharedObject()) or (GetResourceState("qb-core") == "started" and exports['qb-core']:GetCoreObject()) or nil,

    Functions = {
        IsPlayerAllowedToSteal = function(playerId)
           -- You can add anything here. 
        end,

        CanPlayerBeStolen = function(playerId)
            -- Example: Do not allow players to steal staff. (You can change this function according to your needs)

            -- -- ESX
            -- if GetResourceState("es_extended") == "started" then
            --     local xPlayer = Framework.Object.GetPlayerFromId(playerId)

            --     if xPlayer.getGroup() ~= 'user' then
            --         return false
            --     end
            -- -- QBCore
            -- elseif GetResourceState("qb-core") == "started" then
            --     local xPlayer = Framework.Object.GetPlayer(playerId)
            --     local permissions = Framework.Object.Functions.GetPermission(source)
            --     local isStaff = false

            --     for group, hasPerms in pairs(permissions) do
            --         if hasPerms == true then
            --             isStaff = true                        
            --         end
            --     end

            --     if isStaff then
            --         return false
            --     end
            -- end

            return true
        end,

        GetTargetItems = function(playerId)
            -- OX Inventory
            if GetResourceState("ox_inventory") == "started" then
                local items = {}

                local inventory = exports.ox_inventory:GetInventory(playerId)
                local moneyAccounts = {"cash", "money", "black_money", "crypto"}

                for k,v in pairs(inventory.items) do
                    local isMoney = false

                    for _, account in pairs(moneyAccounts) do
                        if v.name == account then
                            if not IsItemBlacklisted(v.name, "Money") and v.count >= 1 then
                                items[#items + 1] = {type = "money", item = v.name, label = v.label, amount = v.count}
                                isMoney = true
                            end
                        end
                    end

                    if not isMoney then
                        if string.sub(v.name, 1, 7) == "WEAPON_" then
                            if not IsItemBlacklisted(v.name, "Weapons") and v.count >= 1 then
                                items[#items + 1] = {type = "weapon", item = v.name, label = v.label, amount = v.count, data = v.info}
                            end
                        else
                            if not IsItemBlacklisted(v.name, "Items") and v.count >= 1 then
                                items[#items + 1] = {type = "item", item = v.name, label = v.label, amount = v.count, data = v.metadata}
                            end
                        end
                    end
                end

                return items
            -- ESX
            elseif GetResourceState("es_extended") == "started" then
                local xPlayer = Framework.Object.GetPlayerFromId(playerId)
                local items = {}

                for k,v in pairs(xPlayer.getAccounts()) do
                    if not IsItemBlacklisted(v.name, "Money") and v.money >= 1 then
                        items[#items + 1] = {type = "money", item = v.name, label = v.label, amount = v.money}
                    end
                end

                for k,v in ipairs(xPlayer.getLoadout()) do
                    if not IsItemBlacklisted(v.name, "Weapons") then
                        items[#items + 1] = {type = "weapon", item = v.name, label = v.label, amount = v.ammo, data = v.components}
                    end
                end

                for k,v in pairs(xPlayer.getInventory()) do
                    if not IsItemBlacklisted(v.name, "Items") and v.count >= 1 then
                        items[#items + 1] = {type = "item", item = v.name, label = v.label, amount = v.count, data = v.weight}
                    end
                end

                return items
            -- QBCore
            elseif GetResourceState("qb-core") == "started" then
                local Player = Framework.Object.Functions.GetPlayer(playerId)
                local items = {}

                for k,v in pairs(Framework.Object.Config.Money.MoneyTypes) do
                    local money = Player.Functions.GetMoney(k)
                    if not IsItemBlacklisted(k, "Money") and money >= 1 then
                        items[#items + 1] = {type = "money", item = k, label = k, amount = money}
                    end
                end

                for k,v in pairs(Player.PlayerData.items) do
                    local itemData = Framework.Object.Shared.Items[v.name:lower()]

                    if itemData['type'] == 'item' then
                        if not IsItemBlacklisted(v.name, "Items") and v.amount >= 1 then
                            items[#items + 1] = {type = "item", item = v.name, label = v.label, amount = v.amount, data = v.info}
                        end
                    end
                    if itemData['type'] == 'weapon' then
                        if not IsItemBlacklisted(v.name, "Weapons") and v.amount >=1 then
                            items[#items + 1] = {type = "weapon", item = v.name, label = v.label, amount = v.amount, data = v.info}
                        end
                    end
                end

                return items
            end
        end,

        StealItem = function(thiefId, targetId, itemType, itemName, itemAmount, itemData)
            local stolen = false

            -- OX Inventory
            if GetResourceState("ox_inventory") == "started" then
                local stolen = false

                local xThief = exports.ox_inventory:GetInventory(thiefId)
                local xTarget = exports.ox_inventory:GetInventory(targetId)

                if itemType == "item" or itemType == "weapon" then
                    local targetItem = exports.ox_inventory:GetItemCount(targetId, itemName) >= itemAmount

                    if targetItem then
                        if exports.ox_inventory:CanCarryItem(thiefId, itemName, itemAmount, itemData) then
                            exports.ox_inventory:RemoveItem(targetId, itemName, itemAmount)
                            exports.ox_inventory:AddItem(thiefId, itemName, itemAmount, itemData)

                            stolen = true
                        end
                    end
                elseif itemType == "money" then
                    local targetAccount = exports.ox_inventory:GetItemCount(targetId, itemName) >= itemAmount

                    if targetAccount then
                        exports.ox_inventory:RemoveItem(targetId, itemName, itemAmount)
                        exports.ox_inventory:AddItem(thiefId, itemName, itemAmount)
                        
                        stolen = true
                    end
                end

                return stolen
            -- ESX
            elseif GetResourceState("es_extended") == "started" then
                local xThief = Framework.Object.GetPlayerFromId(thiefId)
                local xTarget = Framework.Object.GetPlayerFromId(targetId)

                if itemType == "item" then
                    local targetItem = xTarget.hasItem(itemName)

                    if targetItem then
                        if (targetItem.count >= itemAmount) and xThief.canCarryItem(itemName, itemAmount) then
                            xTarget.removeInventoryItem(itemName, itemAmount)
                            xThief.addInventoryItem(itemName, itemAmount)

                            stolen = true
                        end
                    end
                elseif itemType == "weapon" then
                    if xTarget.hasWeapon(itemName) then
                        xTarget.removeWeapon(itemName, itemAmount)
                        xThief.addWeapon(itemName, itemAmount)
                        
                        for _, component in pairs(itemData) do
                            xThief.addWeaponComponent(itemName, component)
                        end
                        
                        stolen = true
                    end
                elseif itemType == "money" then
                    local targetAccount = xTarget.getAccount(itemName)

                    if targetAccount and targetAccount.money >= itemAmount then
                        xTarget.removeAccountMoney(itemName, itemAmount)
                        xThief.addAccountMoney(itemName, itemAmount)
                        
                        stolen = true
                    end
                end

                return stolen
            -- QBCore
            elseif GetResourceState("qb-core") == "started" then
                local xThief = Framework.Object.Functions.GetPlayer(thiefId)
                local xTarget = Framework.Object.Functions.GetPlayer(targetId)

                if itemType == "item" then
                    for k,v in pairs(xTarget.PlayerData.items) do
                        if v.name == itemName then
                            if (v.amount >= itemAmount) then
                                xTarget.Functions.RemoveItem(itemName, itemAmount)
                                xThief.Functions.AddItem(itemName, itemAmount, nil, itemData)
            
                                stolen = true
                            end
                        end
                    end
                elseif itemType == "weapon" then
                    for k,v in pairs(xTarget.PlayerData.items) do
                        if v.name == itemName then
                            xTarget.Functions.RemoveItem(itemName, itemAmount)
                            xThief.Functions.AddItem(itemName, itemAmount, nil, itemData)
                            
                            stolen = true
                        end
                    end
                elseif itemType == "money" then
                    local targetAccount = xTarget.PlayerData.money[itemName]
        
                    if targetAccount and targetAccount >= itemAmount then
                        xTarget.Functions.RemoveMoney(itemName, itemAmount)
                        xThief.Functions.AddMoney(itemName, itemAmount)
                        
                        stolen = true
                    end
                end

                return stolen
            end
        end,

        ShowNotification = function(playerId, message)
            -- ESX
            if GetResourceState("es_extended") == "started" then
                TriggerClientEvent('esx:showNotification', playerId, text)
            -- QBCore
            elseif GetResourceState("qb-core") == "started" then
                TriggerClientEvent('QBCore:Notify', playerId, text)
            end
        end,

        GetIdentifier = function(playerId)
            -- ESX
            if GetResourceState("es_extended") == "started" then
                local xPlayer = Framework.Object.GetPlayerFromId(playerId)
                return xPlayer.identifier
            -- QBCore
            elseif GetResourceState("qb-core") == "started" then
                local xPlayer = Framework.Object.Functions.GetPlayer(playerId)
                return xPlayer.PlayerData.citizenid
            end
        end,

        BanPlayer = function(playerId)
            -- Player attempted to steal player while his ped was not robbing him. (Cheating / Triggering Events) 
            DropPlayer(playerId, 'Stop Cheating!')
        end
    }
}