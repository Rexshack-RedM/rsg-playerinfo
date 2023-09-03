local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        lib.registerContext(
            {
                id = 'player_info',
                title = data.firstname..' '..data.lastname,
                description = '',
                position = 'top-right',
                options = {
                    {
                        title = 'Job : '..data.job,
                        icon = 'user',
                    },
                    {
                        title = 'Job Grade : '..tostring(data.grade),
                        icon = 'user',
                    },
                    {
                        title = 'Cash : '..tostring(data.cash),
                        icon = 'fa-solid fa-money-bill',
                    },
                    {
                        title = 'Bank : '..tostring(data.bank),
                        icon = 'fa-solid fa-building-columns',
                    },
                    {
                        title = 'CitizenID : '..data.citizenid,
                        icon = 'fa-solid fa-id-card',
                    },
                    {
                        title = 'ServerID : '..tonumber(GetPlayerServerId(PlayerId())),
                        icon = 'fa-solid fa-server',
                    },
                }
            }
        )
        lib.showContext('player_info')
    end)
end)
