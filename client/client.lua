local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        optionsArray = {}
        index = 1
        if Config.PlayerInfoSetup.show_job == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.job')..': '..data.job,
                icon = 'user',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_job_grade == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.job_grade')..': '..tostring(data.grade),
                icon = 'user',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_cash == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.funds_in_cash')..': '..tostring(data.cash)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_bank == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.funds_in_bank')..': '..tostring(data.bank)..' $',
                icon = 'fa-solid fa-building-columns',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_citizenid == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.citizenid')..': '..data.citizenid,
                icon = 'fa-solid fa-id-card',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_serverid == true then
            table.insert(optionsArray, index, {
                title = Lang:t('menu.serverid')..': '..tonumber(GetPlayerServerId(PlayerId())),
                icon = 'fa-solid fa-server',
            })
            index = index + 1
        end
        if next(optionsArray) == nil then
            table.insert(optionsArray, 1, {
                title = Lang:t('menu.no_data'),
                icon = 'fa-solid fa-exclamation-circle',
            })
        end
        lib.registerContext(
            {
                id = 'player_info',
                title = data.firstname..' '..data.lastname,
                description = '',
                position = 'top-right',
                options = optionsArray,
            }
        )
        lib.showContext('player_info')
    end)
end)
