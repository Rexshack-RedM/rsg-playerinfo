local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------

RSGCore.Commands.Add('info', Lang:t('menu.view_stats'), {}, true, function(source, args)
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', source)
end)

RSGCore.Functions.CreateCallback('rsg-playerstats:server:getPlayerData', function(source, cb)
    local src          = source
    local Player       = RSGCore.Functions.GetPlayer(src)
    local firstname    = Player.PlayerData.charinfo.firstname
    local lastname     = Player.PlayerData.charinfo.lastname
    local outlawstatus = Player.PlayerData.metadata["outlawstatus"]
    local job          = Player.PlayerData.job.label
    local grade        = Player.PlayerData.job.grade.level
    local cash         = Player.PlayerData.money["cash"]
    local citizenid    = Player.PlayerData.citizenid
    local bank = Player.PlayerData.money["bank"]
    local valbank = Player.PlayerData.money["valbank"]
    local rhobank = Player.PlayerData.money["rhobank"]
    local blkbank = Player.PlayerData.money["blkbank"]
    local armbank = Player.PlayerData.money["armbank"]

    if outlawstatus == 0 then
        newoutlawstatus = 'Law Abiding Citizen'
    elseif outlawstatus > 0 and outlawstatus < 100 then
        newoutlawstatus = 'Petty Criminal'
    elseif outlawstatus >= 100 then
        newoutlawstatus = 'OutLaw'
    end

    cb({
        firstname = firstname,
        lastname  = lastname,
        outlawstatus = newoutlawstatus,
        job       = job, 
        grade     = grade,
        cash      = cash,
        bank = bank,
        valbank = valbank,
        rhobank = rhobank,
        blkbank = blkbank,
        armbank = armbank,
        citizenid = citizenid,
        
    })

end)
