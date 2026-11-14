-- Gameplay effects of injured bones: limp / slowdown for legs, aim sway for arms.
local cfg = Config.Effects
local limping = false
local enabled = cfg and cfg.Enabled or false
local swayApplied = { h = 0.0, p = 0.0 }

local cap = (Config.Treatment and Config.Treatment.SplintEffectCap) or 2

-- worst severity of a list of bones; a splinted bone counts as at most `cap`
local function worst(list, bones, splints)
    local sev = 0
    for i = 1, #list do
        local key = list[i]
        local v = bones[key]
        if v then
            local s = BoneTracker.severity(v)
            if splints[key] and s > cap then s = cap end
            if s > sev then sev = s end
        end
    end
    return sev
end

local published = { legs = -1, arms = -1 }
local function publish(legs, arms)
    if legs == published.legs and arms == published.arms then return end
    published.legs, published.arms = legs, arms
    if cfg.PublishState then
        LocalPlayer.state:set('boneLegs', legs, true)
        LocalPlayer.state:set('boneArms', arms, true)
    end
    TriggerEvent('rsg-playerinfo:client:severityChanged', legs, arms)
end

local function atLevel(tbl, sev)
    return tbl and tbl[sev] or 0
end

local function setLimp(ped, on)
    if limping == on then return end
    limping = on
    Citizen.InvokeNative(0x8B3CB08158E98481, ped, on)
end

local function clearEffects()
    local ped = PlayerPedId()
    SetPedMoveRateOverride(ped, 1.0)
    setLimp(ped, false)
    swayApplied.h, swayApplied.p = 0.0, 0.0
end

CreateThread(function()
    if not (cfg and Config.Bones.Enabled) then return end
    local wasActive = false
    local legSev, armSev, legActive, armActive = 0, 0, false, false
    local nextEval = 0
    while true do
        local ped = PlayerPedId()
        local now = GetGameTimer()

        -- bone severities only change on hits/heals: re-evaluate 4x a second instead of every frame
        if now >= nextEval then
            nextEval = now + 250
            local bones, splints = BoneTracker.get(), BoneTracker.getSplints()
            local legs, arms = cfg.Legs, cfg.Arms
            legSev = worst(legs.Bones, bones, splints)
            armSev = worst(arms.Bones, bones, splints)
            publish(legSev, armSev)
            if not enabled or IsEntityDead(ped) then
                legActive, armActive = false, false
            else
                local legHasEffect = atLevel(legs.MoveRate, legSev) > 0
                    or (legs.BlockSprintFrom ~= 0 and legSev >= legs.BlockSprintFrom)
                    or (legs.BlockJumpFrom ~= 0 and legSev >= legs.BlockJumpFrom)
                    or (legs.LimpNative and legs.LimpFrom ~= 0 and legSev >= legs.LimpFrom)
                legActive = legHasEffect and not (legs.SkipWhenMounted and IsPedOnMount(ped))
                armActive = atLevel(arms.AimSway, armSev) > 0
                    or (arms.BlockReloadFrom ~= 0 and armSev >= arms.BlockReloadFrom)
            end
        end

        if not (legActive or armActive) then
            if wasActive then clearEffects() wasActive = false end
            Wait(250)
        else
            wasActive = true
            Wait(0)
            local legs, arms = cfg.Legs, cfg.Arms
            if legActive then
                local rate = atLevel(legs.MoveRate, legSev)
                if rate > 0 then SetPedMoveRateOverride(ped, math.min(rate, 1.15)) end
                if legs.BlockSprintFrom ~= 0 and legSev >= legs.BlockSprintFrom then
                    DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT
                end
                if legs.BlockJumpFrom ~= 0 and legSev >= legs.BlockJumpFrom then
                    DisableControlAction(0, 0xD9D0E1C0, true) -- INPUT_JUMP
                end
                setLimp(ped, legs.LimpNative and legs.LimpFrom ~= 0 and legSev >= legs.LimpFrom)
            else
                SetPedMoveRateOverride(ped, 1.0)
                setLimp(ped, false)
            end

            if armActive and arms.BlockReloadFrom ~= 0 and armSev >= arms.BlockReloadFrom then
                DisableControlAction(0, 0xE30CD707, true) -- INPUT_RELOAD
            end

            -- Aim sway: apply only the change in offset each frame so the player can still aim freely
            local h, p = 0.0, 0.0
            if armActive and (IsPlayerFreeAiming(PlayerId()) or IsAimCamActive()) then
                local amp = atLevel(arms.AimSway, armSev)
                if amp > 0 then
                    local t = now / 1000.0 * (arms.SwaySpeed or 1.7)
                    h = math.sin(t) * amp * 0.6 + math.sin(t * 2.3 + 1.0) * amp * 0.4
                    p = math.cos(t * 1.3) * amp * 0.5 + math.sin(t * 3.1) * amp * 0.3
                end
            end
            local dh, dp = h - swayApplied.h, p - swayApplied.p
            if dh ~= 0.0 or dp ~= 0.0 then
                SetGameplayCamRelativeHeading(GetGameplayCamRelativeHeading() + dh)
                SetGameplayCamRelativePitch(GetGameplayCamRelativePitch() + dp, 1.0)
                swayApplied.h, swayApplied.p = h, p
            end
        end
    end
end)

AddEventHandler('RSGCore:Client:OnPlayerUnload', clearEffects)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearEffects() end
end)

---------------------------------------------
-- Exports
---------------------------------------------
-- Effective severity (splint-adjusted) of a group ('legs' | 'arms') or a single bone key: 0 healthy, 1 bruised, 2 cracked, 3 fractured, 4 broken
exports('GetSeverity', function(what)
    local bones, splints = BoneTracker.get(), BoneTracker.getSplints()
    if not what then return 0 end
    if bones[what] then return worst({ what }, bones, splints) end
    local group = cfg and cfg[what == 'legs' and 'Legs' or what == 'arms' and 'Arms' or '']
    if group then return worst(group.Bones, bones, splints) end
    return 0
end)

-- Turn the gameplay effects on/off at runtime (e.g. while a cutscene or minigame runs)
exports('SetEffectsEnabled', function(state)
    enabled = state and true or false
    if not enabled then clearEffects() end
end)
exports('AreEffectsEnabled', function() return enabled end)
