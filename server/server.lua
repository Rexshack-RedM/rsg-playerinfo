local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()
-----------------------------------------------------------------------

RSGCore.Commands.Add('info', locale('sv_view_stats'), {}, true, function(source, args)
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', source)
end)

RSGCore.Functions.CreateCallback('rsg-playerstats:server:getPlayerData', function(source, cb)
    local src          = source
    local Player       = RSGCore.Functions.GetPlayer(src)
    local firstname    = Player.PlayerData.charinfo.firstname
    local lastname     = Player.PlayerData.charinfo.lastname
    local job          = Player.PlayerData.job.label
    local grade        = Player.PlayerData.job.grade.level
    local cash         = Player.PlayerData.money['cash']
    local bloodmoney   = Player.PlayerData.money['bloodmoney']
    local citizenid    = Player.PlayerData.citizenid
    local bank         = Player.PlayerData.money['bank']
    local valbank      = Player.PlayerData.money['valbank']
    local rhobank      = Player.PlayerData.money['rhobank']
    local blkbank      = Player.PlayerData.money['blkbank']
    local armbank      = Player.PlayerData.money['armbank']

    local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid=@citizenid', { ['@citizenid'] = Player.PlayerData.citizenid } )
    local outlawstatus = tonumber(result[1].outlawstatus)
    local newoutlawstatus = nil
    if outlawstatus == 0 then
        newoutlawstatus = locale('sv_outlawstatus_a')
    elseif outlawstatus > 0 and outlawstatus < 100 then
        newoutlawstatus = locale('sv_outlawstatus_b')
    elseif outlawstatus >= 100 then
        newoutlawstatus = locale('sv_outlawstatus_c')..' ($'..outlawstatus..')'
    end

    cb({
        firstname    = firstname,
        lastname     = lastname,
        outlawstatus = newoutlawstatus,
        job          = job,
        grade        = grade,
        cash         = cash,
        bloodmoney   = bloodmoney,
        bank         = bank,
        valbank      = valbank,
        rhobank      = rhobank,
        blkbank      = blkbank,
        armbank      = armbank,
        citizenid    = citizenid,
    })

end)
