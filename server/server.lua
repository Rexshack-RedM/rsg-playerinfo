local RSGCore = exports['rsg-core']:GetCoreObject()

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