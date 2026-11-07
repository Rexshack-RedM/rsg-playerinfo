local RSGCore = exports['rsg-core']:GetCoreObject()
local uiFocus = false

---------------------------------------------
-- NUI focus (push-to-talk stays usable)
---------------------------------------------
local function applyNuiFocus(enable)
    if enable then
        SetNuiFocus(true, true)
        if Config.AllowPushToTalkWhileOpen then
            SetNuiFocusKeepInput(true)
        end
    else
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
end

local function runPttWhitelist()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    local list = Config.PushToTalkControls
    if list then
        for i = 1, #list do
            local c = list[i]
            EnableControlAction(0, c, true)
            EnableControlAction(1, c, true)
            EnableControlAction(2, c, true)
        end
    end
end

CreateThread(function()
    while true do
        if uiFocus and Config.AllowPushToTalkWhileOpen then
            Wait(0)
            runPttWhitelist()
        else
            Wait(250)
        end
    end
end)

local function closeUI()
    uiFocus = false
    applyNuiFocus(false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb('ok')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and uiFocus then
        applyNuiFocus(false)
    end
end)

-- Field definitions for dynamic menu generation
local FIELD_CONFIGS = {
    { key = 'show_outlawstatus', dataKey = 'outlawstatus', localeKey = 'cl_outlawstatus', icon = 'fa-solid fa-mask' },
    { key = 'show_job', dataKey = 'job', localeKey = 'cl_job', icon = 'fa-solid fa-user' },
    { key = 'show_job_grade', dataKey = 'grade', localeKey = 'cl_job_grade', icon = 'fa-solid fa-user', isNumber = true },
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
                label = locale(field.localeKey),
                value = value,
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
                label = locale('cl_no_data'),
                value = '',
                icon = 'fa-solid fa-circle-exclamation'
            }
        end
        
        -- Build player name safely
        local playerName = (data.firstname or '') .. ' ' .. (data.lastname or '')
        if playerName == ' ' then
            playerName = locale('cl_no_data')
        end
        
        uiFocus = true
        applyNuiFocus(true)
        SendNUIMessage({
            action = 'open',
            title = playerName,
            subtitle = locale('cl_ui_subtitle'),
            closeLabel = locale('cl_ui_close'),
            rows = optionsArray
        })
    end)
end)
