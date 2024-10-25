local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        optionsArray = {}
        index = 1
        if Config.PlayerInfoSetup.show_outlawstatus == true then
            table.insert(optionsArray, index, {
                title = locale('cl_outlawstatus')..': '..data.outlawstatus,
                icon = 'fa-solid fa-mask',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_job == true then
            table.insert(optionsArray, index, {
                title = locale('cl_job')..': '..data.job,
                icon = 'user',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_job_grade == true then
            table.insert(optionsArray, index, {
                title = locale('cl_job_grade')..': '..tostring(data.grade),
                icon = 'user',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_cash == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_cash')..': '..tostring(data.cash)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_bloodmoney == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_bloodmoney')..': '..tostring(data.bloodmoney)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_bank == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_bank')..': '..tostring(data.bank)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_rhobank == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_rhobank')..': '..tostring(data.rhobank)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_valbank == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_valbank')..': '..tostring(data.valbank)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_blkbank == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_blkbank')..': '..tostring(data.blkbank)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_armbank == true then
            table.insert(optionsArray, index, {
                title = locale('cl_funds_in_armbank')..': '..tostring(data.armbank)..' $',
                icon = 'fa-solid fa-money-bill',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_citizenid == true then
            table.insert(optionsArray, index, {
                title = locale('cl_citizenid')..': '..data.citizenid,
                icon = 'fa-solid fa-id-card',
            })
            index = index + 1
        end
        if Config.PlayerInfoSetup.show_serverid == true then
            table.insert(optionsArray, index, {
                title = locale('cl_serverid')..': '..tonumber(GetPlayerServerId(PlayerId())),
                icon = 'fa-solid fa-server',
            })
            index = index + 1
        end
        if next(optionsArray) == nil then
            table.insert(optionsArray, 1, {
                title = locale('cl_no_data'),
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
