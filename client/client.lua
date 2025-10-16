local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

-- Field definitions for dynamic menu generation
local FIELD_CONFIGS = {
    { key = 'show_outlawstatus', dataKey = 'outlawstatus', localeKey = 'cl_outlawstatus', icon = 'fa-solid fa-mask' },
    { key = 'show_job', dataKey = 'job', localeKey = 'cl_job', icon = 'user' },
    { key = 'show_job_grade', dataKey = 'grade', localeKey = 'cl_job_grade', icon = 'user', isNumber = true },
    { key = 'show_cash', dataKey = 'cash', localeKey = 'cl_funds_in_cash', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_bloodmoney', dataKey = 'bloodmoney', localeKey = 'cl_funds_in_bloodmoney', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_bank', dataKey = 'bank', localeKey = 'cl_funds_in_bank', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_rhobank', dataKey = 'rhobank', localeKey = 'cl_funds_in_rhobank', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_valbank', dataKey = 'valbank', localeKey = 'cl_funds_in_valbank', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_blkbank', dataKey = 'blkbank', localeKey = 'cl_funds_in_blkbank', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_armbank', dataKey = 'armbank', localeKey = 'cl_funds_in_armbank', icon = 'fa-solid fa-money-bill', isMoney = true },
    { key = 'show_citizenid', dataKey = 'citizenid', localeKey = 'cl_citizenid', icon = 'fa-solid fa-id-card' },
    { key = 'show_serverid', dataKey = 'serverid', localeKey = 'cl_serverid', icon = 'fa-solid fa-server' }
}

local function buildOptionsArray(data)
    local optionsArray = {}
    
    for _, field in ipairs(FIELD_CONFIGS) do
        if Config.PlayerInfoSetup[field.key] then
            local value = data[field.dataKey]
            
            -- Handle nil values
            if not value then
                value = locale('cl_no_data')
            else
                if field.isNumber then
                    value = tostring(value)
                elseif field.isMoney then
                    value = tostring(value) .. ' $'
                end
            end
            
            optionsArray[#optionsArray + 1] = {
                title = locale(field.localeKey) .. ': ' .. value,
                icon = field.icon
            }
        end
    end
    
    return optionsArray
end

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        if not data then
            return
        end
        
        -- Add server ID to data for consistency
        data.serverid = GetPlayerServerId(PlayerId())
        
        local optionsArray = buildOptionsArray(data)
        
        -- Fallback if no options were added
        if #optionsArray == 0 then
            optionsArray[1] = {
                title = locale('cl_no_data'),
                icon = 'fa-solid fa-exclamation-circle'
            }
        end
        
        -- Build player name safely
        local playerName = (data.firstname or '') .. ' ' .. (data.lastname or '')
        if playerName == ' ' then
            playerName = locale('cl_no_data')
        end
        
        lib.registerContext({
            id = 'player_info',
            title = playerName,
            position = 'top-right',
            options = optionsArray
        })
        
        lib.showContext('player_info')
    end)
end)
