-- Pain reaction when a bone gets worse: screen flash + pain sound.
local cfg = Config.Pain
if not (cfg and cfg.Enabled) then return end

local lastReact = 0

AddEventHandler('rsg-playerinfo:client:boneWorsened', function(_, severity)
    if severity < (cfg.MinSeverity or 2) then return end

    local now = GetGameTimer()
    if now - lastReact < (cfg.Cooldown or 4000) then return end
    lastReact = now

    local ped = PlayerPedId()
    if IsEntityDead(ped) then return end

    local fx = cfg.Flash
    if fx and fx ~= '' then
        AnimpostfxPlay(fx)
        CreateThread(function()
            Wait(cfg.FlashDuration or 1500)
            AnimpostfxStop(fx)
        end)
    end

    if cfg.Sound then
        -- PLAY_PAIN(ped, painId, p2, p3, isNetwork)
        Citizen.InvokeNative(0xBC9AE166038A5CEC, ped, cfg.PainId or 10, 0.0, true, true)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and cfg.Flash and cfg.Flash ~= '' then
        AnimpostfxStop(cfg.Flash)
    end
end)
