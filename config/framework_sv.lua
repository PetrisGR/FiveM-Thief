Framework = {
    Object = exports['es_extended']:getSharedObject(), -- You can change it to your own framework object.

    Functions = {
        IsPlayerAllowedToSteal = function(playerId)
            -- ESX Example
            -- local xPlayer = Framework.Object.GetPlayerFromId(playerId)

            -- if xPlayer.getGroup() ~= 'user' then -- Example: If the player has different group than user (proabably only server staff), he won't be allowed to steal anyone.
            --     return false
            -- end

            return true
        end,

        CanPlayerBeStolen = function(playerId)
            -- ESX Example
            -- local xPlayer = Framework.Object.GetPlayerFromId(playerId)

            -- if xPlayer.getGroup() ~= 'user' then -- Example: If the player has different group than user (proabably only server staff), theifs won't be able to steal him.
            --     return false
            -- end

            return true
        end,

        GetTargetItems = function(playerId)
            -- ESX Example
            local xPlayer = Framework.Object.GetPlayerFromId(playerId)
            local items = {}

            for k,v in pairs(xPlayer.getAccounts()) do
                if not IsItemBlacklisted(v.name) and v.money >= 1 then
                    items[#items + 1] = {type = "money", item = v.name, label = v.label, amount = v.money}
                end
            end

            for k,v in ipairs(xPlayer.getLoadout()) do
                if not IsItemBlacklisted(v.name) then
                    items[#items + 1] = {type = "weapon", item = v.name, label = v.label, amount = v.ammo, data = v.components}
                end
            end

            for k,v in pairs(xPlayer.getInventory()) do
                if not IsItemBlacklisted(v.name) and v.count >= 1 then
                    items[#items + 1] = {type = "item", item = v.name, label = v.label, amount = v.count, data = v.weight}
                end
            end
            return items
        end,

        StealItem = function(thiefId, targetId, itemType, itemName, itemAmount, itemData)
            -- ESX Example
            local stolen = false
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
        end,

        ShowNotification = function(playerId, message)
            -- ESX Example
            local xPlayer = Framework.Object.GetPlayerFromId(playerId)
            xPlayer.showNotification(message)
        end,

        GetIdentifier = function(playerId)
            -- ESX Example
            local xPlayer = Framework.Object.GetPlayerFromId(playerId)
            return xPlayer.identifier
        end,

        BanPlayer = function(playerId)
            -- Player attempted to steal player while his ped was not robbing him. (Cheating / Triggering Events) 
            DropPlayer(playerId, 'Stop Cheating!')
        end
    }
}