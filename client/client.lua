local RSGCore = exports['rsg-core']:GetCoreObject()
local uiFocus = false
local openToken = 0

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
    openToken = openToken + 1
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

---------------------------------------------
-- Payload
---------------------------------------------
local function buildLabels()
    local labels = {
        no_data = locale('cl_no_data'), none = locale('cl_none'),
        sec_identity = locale('cl_sec_identity'), sec_employment = locale('cl_sec_employment'),
        sec_accounts = locale('cl_sec_accounts'), sec_medical = locale('cl_sec_medical'),
        sec_standing = locale('cl_sec_standing'),
        cash = locale('cl_cash'), bloodmoney = locale('cl_bloodmoney'), gold = locale('cl_gold'),
        bank = locale('cl_bank_total'),
        rhobank = locale('cl_funds_in_rhobank'), valbank = locale('cl_funds_in_valbank'),
        blkbank = locale('cl_funds_in_blkbank'), armbank = locale('cl_funds_in_armbank'),
        birthdate = locale('cl_birthdate'), gender = locale('cl_gender'),
        male = locale('cl_gender_male'), female = locale('cl_gender_female'),
        nationality = locale('cl_nationality'), bloodtype = locale('cl_bloodtype'),
        citizenid = locale('cl_citizenid'), serverid = locale('cl_serverid'),
        fingerprint = locale('cl_fingerprint'), walletid = locale('cl_walletid'),
        callsign = locale('cl_callsign'),
        job = locale('cl_job'), job_grade = locale('cl_job_grade'), duty = locale('cl_duty'),
        on_duty = locale('cl_on_duty'), off_duty = locale('cl_off_duty'),
        gang = locale('cl_gang'), other_jobs = locale('cl_other_jobs'),
        outlawstatus = locale('cl_outlawstatus'), reputation = locale('cl_reputation'),
        med_integrity = locale('cl_med_integrity'), med_fractures = locale('cl_med_fractures'),
        med_cracks = locale('cl_med_cracks'), med_bruises = locale('cl_med_bruises'),
        verdict_ok = locale('cl_med_verdict_ok'), verdict_minor = locale('cl_med_verdict_minor'),
        verdict_cracks = locale('cl_med_verdict_cracks'), verdict_fracture = locale('cl_med_verdict_fracture'),
        verdict_critical = locale('cl_med_verdict_critical'),
        status_healthy = locale('cl_bone_status_healthy'), status_bruised = locale('cl_bone_status_bruised'),
        status_cracked = locale('cl_bone_status_cracked'), status_fractured = locale('cl_bone_status_fractured'),
        status_broken = locale('cl_bone_status_broken'),
        group_core = locale('cl_med_group_core'), group_arms = locale('cl_med_group_arms'),
        group_legs = locale('cl_med_group_legs'),
        splinted = locale('cl_bone_splinted'),
    }
    for _, key in ipairs(Bones.Keys) do
        labels['bone_' .. key] = locale('cl_bone_' .. key)
    end
    return labels
end

local function buildPayload(action, data, exam)
    data.serverid = GetPlayerServerId(PlayerId())
    if not exam then
        data.bones = BoneTracker and BoneTracker.get() or data.bones
        data.splints = BoneTracker and BoneTracker.getSplints() or data.splints
    end

    local payload = { action = action, data = data }

    if action == 'open' then
        local name = ((data.firstname or '') .. ' ' .. (data.lastname or '')):match('^%s*(.-)%s*$')
        if name == '' then name = locale('cl_no_data') end
        payload.title = name
        payload.subtitle = locale(exam and 'cl_exam_subtitle' or 'cl_ui_subtitle')
        payload.exam = exam and true or false
        payload.closeLabel = locale('cl_ui_close')
        payload.percent = math.max(50, math.min(100, tonumber(Config.ScreenPercent) or 80))
        payload.show = exam and { show_bones = true } or Config.PlayerInfoSetup
        payload.labels = buildLabels()
        payload.thresholds = (Config.Bones and Config.Bones.Thresholds) or { healthy = 90, bruised = 60, cracked = 30 }
    end

    return payload
end

local function startRefresh(token)
    local interval = tonumber(Config.RefreshInterval) or 0
    if interval < 1000 then return end

    CreateThread(function()
        while uiFocus and token == openToken do
            Wait(interval)
            if not (uiFocus and token == openToken) then break end
            RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
                if data and uiFocus and token == openToken then
                    SendNUIMessage(buildPayload('update', data))
                end
            end)
        end
    end)
end

RegisterNetEvent('rsg-playerstats:client:openPlayerStats', function()
    if uiFocus then return end

    RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData', function(data)
        if not data or uiFocus then return end

        openToken = openToken + 1
        local token = openToken

        uiFocus = true
        applyNuiFocus(true)
        SendNUIMessage(buildPayload('open', data))
        startRefresh(token)
    end)
end)

-- A doctor examines a patient: bone map only, no refresh
RegisterNetEvent('rsg-playerinfo:client:openExam', function(info)
    if uiFocus or type(info) ~= 'table' then return end
    openToken = openToken + 1
    uiFocus = true
    applyNuiFocus(true)
    SendNUIMessage(buildPayload('open', {
        firstname = info.name or '', lastname = '',
        bones = info.bones or {}, splints = info.splints or {},
    }, true))
end)

---------------------------------------------
-- Exports
---------------------------------------------
exports('OpenPlayerInfo', function() TriggerEvent('rsg-playerstats:client:openPlayerStats') end)
exports('ClosePlayerInfo', function() if uiFocus then closeUI() end end)
exports('IsPlayerInfoOpen', function() return uiFocus end)
