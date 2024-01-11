local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        optionsArray = {}
        if Config.PlayerInfoSetup.show_job == true then
            table.insert(optionsArray, 1, {
                title = Lang:t('menu.job')..': '..data.job,
                icon = 'user',
            })
        end
        if Config.PlayerInfoSetup.show_job_grade == true then
            table.insert(optionsArray, 2, {
                title = Lang:t('menu.job_grade')..': '..tostring(data.grade),
                icon = 'user',
            })
        end
        if Config.PlayerInfoSetup.show_cash == true then
            table.insert(optionsArray, 3, {
                title = Lang:t('menu.funds_in_cash')..': '..tostring(data.cash),
                icon = 'fa-solid fa-money-bill',
            })
        end
        if Config.PlayerInfoSetup.show_bank == true then
            table.insert(optionsArray, 4, {
                title = Lang:t('menu.funds_in_bank')..': '..tostring(data.bank),
                icon = 'fa-solid fa-building-columns',
            })
        end
        if Config.PlayerInfoSetup.show_citizenid == true then
            table.insert(optionsArray, 5, {
                title = Lang:t('menu.citizenid')..': '..data.citizenid,
                icon = 'fa-solid fa-id-card',
            })
        end
        if Config.PlayerInfoSetup.show_serverid == true then
            table.insert(optionsArray, 6, {
                title = Lang:t('menu.serverid')..': '..tonumber(GetPlayerServerId(PlayerId())),
                icon = 'fa-solid fa-server',
            })
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