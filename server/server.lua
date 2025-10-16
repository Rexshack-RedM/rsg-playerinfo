local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

RSGCore.Commands.Add('info', locale('sv_view_stats'), {}, true, function(source, args)
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', source)
end)

RSGCore.Functions.CreateCallback('rsg-playerstats:server:getPlayerData', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- Validate player exists
    if not Player or not Player.PlayerData then
        cb(nil)
        return
    end
    
    local playerData = Player.PlayerData
    
    -- Safely extract player information with fallbacks
    local firstname = playerData.charinfo and playerData.charinfo.firstname or ''
    local lastname = playerData.charinfo and playerData.charinfo.lastname or ''
    local job = playerData.job and playerData.job.label or locale('cl_no_data')
    local grade = playerData.job and playerData.job.grade and playerData.job.grade.level or 0
    local citizenid = playerData.citizenid or ''
    
    -- Safely extract money data
    local money = playerData.money or {}
    local cash = money.cash or 0
    local bloodmoney = money.bloodmoney or 0
    local bank = money.bank or 0
    local valbank = money.valbank or 0
    local rhobank = money.rhobank or 0
    local blkbank = money.blkbank or 0
    local armbank = money.armbank or 0
    
    -- Query database with proper error handling
    local outlawstatusText = locale('cl_no_data')
    
    if citizenid and citizenid ~= '' then
        local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid = ?', { citizenid })
        
        if result and result[1] and result[1].outlawstatus ~= nil then
            local outlawstatus = tonumber(result[1].outlawstatus) or 0
            
            if outlawstatus == 0 then
                outlawstatusText = locale('sv_outlawstatus_a')
            elseif outlawstatus > 0 and outlawstatus < 100 then
                outlawstatusText = locale('sv_outlawstatus_b')
            elseif outlawstatus >= 100 then
                outlawstatusText = locale('sv_outlawstatus_c') .. ' ($' .. outlawstatus .. ')'
            end
        end
    end
    
    cb({
        firstname = firstname,
        lastname = lastname,
        outlawstatus = outlawstatusText,
        job = job,
        grade = grade,
        cash = cash,
        bloodmoney = bloodmoney,
        bank = bank,
        valbank = valbank,
        rhobank = rhobank,
        blkbank = blkbank,
        armbank = armbank,
        citizenid = citizenid
    })
end)
