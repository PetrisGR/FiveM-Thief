Config = {
    Keybinds = { -- You can select any keybinds from here: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
        ["Thief"] = "H",
        ["HandsUp"] = "X"
    },

    InputCooldowns = {
        ["Thief"] = 2, -- Second(s)
        ["HandsUp"] = 1, -- Second(s)
    },

    Settings = {
        ["MaxDistance"] = 2.0,
    },

    Blacklisted = {
        ["Areas"] = {
            {coords = vector3(0.0, 0.0, 0.0), range = 5.0},
        },
        ["Items"] = {"bank", "id_card", "WEAPON_RPG"}
    },

    Menu = {
        ["Title"] = "Target's Inventory",
        ["DialogTitle"] = "Choose Amount",
        ["InputItemTitle"] = "Item",
        ["InputAmountTitle"] = "Amount",
        ["InputAmountDescription"] = "Choose amount to steal.",
        ["Currency"] = "$",
        Icons = { -- Find some here: https://fontawesome.com/search?o=r&m=free
            ["money"] = {
                ["default"] = {icon = "dollar-sign", iconColor = "#289931"},
                Specific = {
                    ["money"] = {icon = "wallet", iconColor = "#289931"},
                    ["black_money"] = {icon = "sack-dollar", iconColor = "#e30707"},
                },
            },
            ["weapon"] = {
                ["default"] = {icon = "gun", iconColor = "#cf2b1f"}
            },
            ["item"] = {
                ["default"] = {icon = "box", iconColor = "#d5e30b"},
                Specific = {
                    ["water"] = {icon = "bottle-water", iconColor = "#1599e6"},
                    ["bread"] = {icon = "bread-slice", iconColor = "#b0580b"},
                },
            }
        }
    },
    
    Animation = {
        ["Dictionary"] = "missminuteman_1ig_2",
        ["Name"] = "handsup_enter",
        ["BlendInSpeed"] = 2.0,
        ["BlendOutSpeed"] = 4.0
    },

    Notifications = {
        ["Steal"] = true,
        ["NoPlayersNearby"] = true
    },

    Messages = {
        ["something_went_wrong"] = "Something went wrong.",
        ["you_stole"] = "You stole",
        ["thief_stole"] = "Thief stole",
        ["from_you"] = "from you",
        ["no_players_nearby"] = "No players with hands up nearby."
    },

    Functions = {
        CanPlayerSteal = function(ped)
            local BlacklistedMelees = {"WEAPON_UNARMED", "WEAPON_KNUCKLE", "WEAPON_FLASHLIGHT"}

            if IsPedArmed(ped, 4) then
                return true
            end

            if IsPedArmed(ped, 1) then
                local approvedMelee = false

                for _, melee in pairs(BlacklistedMelees) do
                    if GetHashKey(melee) == GetSelectedPedWeapon(ped) then
                        approvedMelee = true
                        break 
                    end
                end

                return approvedMelee
            end

            return false
        end,
        IsBeingRobbed = function(bool)
            local ped = PlayerPedId()
            if bool then
                -- If he's being robbed, disable some things that he shouldn't use.
                FreezeEntityPosition(ped, true)
                SetPedEnableWeaponBlocking(ped, true)
            else
                -- Once stopped being robbed, enable the things you disabled.
                FreezeEntityPosition(ped, false)
                SetPedEnableWeaponBlocking(ped, false)
            end
        end
    }
}