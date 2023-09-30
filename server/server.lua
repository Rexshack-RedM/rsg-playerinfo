local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-playerinfo/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

RSGCore.Commands.Add('info', 'View Stats', {}, true, function(source, args)
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', source)
end)

RSGCore.Functions.CreateCallback('rsg-playerstats:server:getPlayerData', function(source, cb)
    local src = source
    local Player    = RSGCore.Functions.GetPlayer(src)
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname  = Player.PlayerData.charinfo.lastname
    local job       = Player.PlayerData.job.label
    local grade     = Player.PlayerData.job.grade.level
    local cash      = Player.PlayerData.money["cash"]
    local bank      = Player.PlayerData.money["bank"]
    local citizenid = Player.PlayerData.citizenid

    cb({
        firstname = firstname,
        lastname  = lastname,
        job       = job, 
        grade     = grade,
        cash      = cash,
        bank      = bank,
        citizenid = citizenid,
        
    })

end)

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
