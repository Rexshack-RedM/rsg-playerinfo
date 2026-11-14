-- Self treatment with bone bandages / splints (the item use is started by the server).
local RSGCore = exports['rsg-core']:GetCoreObject()
local busy = false

local function notify(key, kind)
    RSGCore.Functions.Notify({
        title = locale('cl_sec_medical'),
        description = locale(key),
        type = kind or 'inform',
    })
end

-- Server asks us to start using an item: check there is something to treat, show the progress bar, report back
RegisterNetEvent('rsg-playerinfo:client:useTreatment', function(kind)
    if busy then return end
    local cfg = Config.Treatment
    local def = kind == 'bandage' and cfg.Bandage or kind == 'splint' and cfg.Splint or nil
    if not def then return end

    if kind == 'bandage' and not BoneTracker.canBandage() then
        notify('cl_treat_nothing_bruised')
        TriggerServerEvent('rsg-playerinfo:server:treatCancel')
        return
    end
    if kind == 'splint' and not BoneTracker.canSplint() then
        notify('cl_treat_nothing_splint')
        TriggerServerEvent('rsg-playerinfo:server:treatCancel')
        return
    end

    busy = true
    local done = RSGCore.Functions.ProgressBar({
        duration = def.duration,
        label = locale(kind == 'bandage' and 'cl_treat_bandage_progress' or 'cl_treat_splint_progress'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = false, mount = true, combat = true },
    })
    TriggerServerEvent(done and 'rsg-playerinfo:server:treatDone' or 'rsg-playerinfo:server:treatCancel', kind)
    busy = false
end)

-- The server confirmed (item consumed / doctor treatment): apply it
RegisterNetEvent('rsg-playerinfo:client:applyTreatment', function(kind)
    local quiet = kind == 'doctor'
    if kind == 'bandage' or quiet then
        if BoneTracker.bandage() > 0 and not quiet then notify('cl_treat_bandaged', 'success') end
    end
    if kind == 'splint' or quiet then
        if BoneTracker.splint() > 0 and not quiet then notify('cl_treat_splinted', 'success') end
    end
    if quiet then notify('sv_you_were_treated', 'success') end
end)
