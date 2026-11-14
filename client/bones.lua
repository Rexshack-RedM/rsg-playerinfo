local RSGCore = exports['rsg-core']:GetCoreObject()

---------------------------------------------
-- Bone health tracker
-- Condition per bone: 100 = healthy ... 0 = broken
---------------------------------------------
BoneTracker = {}

local cfg = Config.Bones or {}
local state = {}
local splints = {}      -- key -> true while a bone is splinted
local loaded = false
local dirty = false

local function clamp(v)
    return math.max(0, math.min(100, v))
end

local function resetState()
    for _, key in ipairs(Bones.Keys) do state[key] = 100.0 end
    splints = {}
    dirty = true
end

for _, key in ipairs(Bones.Keys) do state[key] = 100.0 end

-- 0 healthy, 1 bruised, 2 cracked, 3 fractured, 4 broken
function BoneTracker.severity(value)
    local t = cfg.Thresholds
    if value >= t.healthy then return 0 end
    if value >= t.bruised then return 1 end
    if value >= t.cracked then return 2 end
    if value > 0 then return 3 end
    return 4
end

local STATUS = { [0] = 'healthy', 'bruised', 'cracked', 'fractured', 'broken' }
function BoneTracker.status(value) return STATUS[BoneTracker.severity(value)] end

local function damageBone(key, amount)
    if not state[key] or amount <= 0 then return end
    local before = BoneTracker.severity(state[key])
    state[key] = clamp(state[key] - amount)
    splints[key] = nil -- a fresh hit knocks the splint off
    dirty = true
    local after = BoneTracker.severity(state[key])
    if after > before then
        TriggerEvent('rsg-playerinfo:client:boneWorsened', key, after)
    end
end

-- Rounded copy of the current bone conditions
function BoneTracker.get()
    local out = {}
    for _, key in ipairs(Bones.Keys) do
        out[key] = math.floor(state[key] + 0.5)
    end
    return out
end

-- Copy of the splinted bones (key -> true)
function BoneTracker.getSplints()
    local out = {}
    for key in pairs(splints) do out[key] = true end
    return out
end

function BoneTracker.heal(key)
    if key then
        if state[key] then state[key] = 100.0 splints[key] = nil end
    else
        for _, k in ipairs(Bones.Keys) do state[k] = 100.0 end
        splints = {}
    end
    dirty = true
end

-- Bandage: instantly mends bruised bones. Returns how many were mended.
function BoneTracker.bandage()
    local n = 0
    for _, key in ipairs(Bones.Keys) do
        if BoneTracker.severity(state[key]) == 1 then
            state[key] = 100.0
            n = n + 1
        end
    end
    if n > 0 then dirty = true end
    return n
end

-- Splint: cracked/fractured/broken bones start mending slowly. Returns how many were splinted.
function BoneTracker.splint()
    local n = 0
    for _, key in ipairs(Bones.Keys) do
        if BoneTracker.severity(state[key]) >= 2 and not splints[key] then
            splints[key] = true
            n = n + 1
        end
    end
    if n > 0 then dirty = true end
    return n
end

function BoneTracker.canBandage()
    for _, key in ipairs(Bones.Keys) do
        if BoneTracker.severity(state[key]) == 1 then return true end
    end
    return false
end

function BoneTracker.canSplint()
    for _, key in ipairs(Bones.Keys) do
        if BoneTracker.severity(state[key]) >= 2 and not splints[key] then return true end
    end
    return false
end

function BoneTracker.damage(key, amount)
    damageBone(key, tonumber(amount) or 0)
end

---------------------------------------------
-- Load / save (player metadata)
---------------------------------------------
local function loadFromMetadata()
    local pd = RSGCore.Functions.GetPlayerData()
    local saved = pd and pd.metadata and pd.metadata.bones
    for _, key in ipairs(Bones.Keys) do
        local v = type(saved) == 'table' and tonumber(saved[key]) or nil
        state[key] = v and clamp(v) + 0.0 or 100.0
    end
    splints = {}
    local savedSplints = pd and pd.metadata and pd.metadata.bonesplints
    if type(savedSplints) == 'table' then
        for _, key in ipairs(Bones.Keys) do
            if savedSplints[key] and state[key] < 90 then splints[key] = true end
        end
    end
    dirty = false
    loaded = true
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    loadFromMetadata()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    loaded = false
    resetState()
    dirty = false
end)

CreateThread(function()
    Wait(1500)
    local pd = RSGCore.Functions.GetPlayerData()
    if pd and pd.citizenid then loadFromMetadata() end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if loaded and dirty then
            dirty = false
            TriggerServerEvent('rsg-playerinfo:server:saveBones', BoneTracker.get(), BoneTracker.getSplints())
        end
    end
end)

---------------------------------------------
-- Damage detection (health drops + last damage bone)
---------------------------------------------
local MODELS = {
    mp_male = GetHashKey('mp_male'),
    mp_female = GetHashKey('mp_female'),
    player_zero = GetHashKey('player_zero'),
}

local function resolveBone(ped, bone)
    local key = Bones.ByBoneId[bone]
    if key then return key end
    -- fallback: the native returned a bone index, which differs per skeleton
    if bone < 1000 then
        local model = GetEntityModel(ped)
        for name, hash in pairs(MODELS) do
            if hash == model and Bones.ByIndex[name] then
                return Bones.ByIndex[name][bone]
            end
        end
    end
    return nil
end

local function applyFall(amount)
    local w = cfg.FallWeights or {}
    for _, side in ipairs({ '_l', '_r' }) do
        damageBone('foot' .. side, amount * (w.foot or 0))
        damageBone('shin' .. side, amount * (w.shin or 0))
        damageBone('thigh' .. side, amount * (w.thigh or 0))
    end
    damageBone('pelvis', amount * (w.pelvis or 0))
end

local function registerHit(ped, pct, fall)
    local amount = pct * (cfg.DamageScale or 1.0)

    if fall then
        if cfg.Debug then print(('[rsg-playerinfo] fall damage %.1f%%'):format(pct)) end
        applyFall(amount)
        return
    end

    local found, bone = GetPedLastDamageBone(ped)
    if not found or not bone or bone == 0 then return end

    local key = resolveBone(ped, bone)
    if cfg.Debug then
        print(('[rsg-playerinfo] hit %.1f%% | raw bone %s -> %s'):format(pct, tostring(bone), tostring(key)))
    end
    if key then damageBone(key, amount) end
end

CreateThread(function()
    local lastHealth, fallingUntil = nil, 0

    while true do
        Wait(cfg.PollInterval or 150)

        if cfg.Enabled and loaded then
            local ped = PlayerPedId()
            local dead = IsEntityDead(ped)
            local health = GetEntityHealth(ped)
            local now = GetGameTimer()

            if IsPedFalling(ped) then fallingUntil = now + 1500 end

            if lastHealth and health < lastHealth then
                local maxHealth = math.max(1, GetEntityMaxHealth(ped))
                local pct = (lastHealth - health) / maxHealth * 100.0
                if pct >= (cfg.MinDamagePercent or 4) then
                    registerHit(ped, pct, now < fallingUntil)
                end
            end

            lastHealth = (not dead) and health or nil
        else
            lastHealth = nil
        end
    end
end)

-- Natural recovery: bruises mend on their own, splinted bones mend slowly
CreateThread(function()
    while true do
        Wait(60000)
        if loaded then
            local rec = cfg.RecoveryPerMinute or 0
            local splintRec = cfg.SplintRecoveryPerMinute or 0
            for _, key in ipairs(Bones.Keys) do
                local c = state[key]
                if c < 100 then
                    if splints[key] and splintRec > 0 then
                        c = c + splintRec
                        if c >= cfg.Thresholds.healthy then c = 100.0 splints[key] = nil end
                        state[key] = c
                        dirty = true
                    elseif rec > 0 and c >= cfg.Thresholds.bruised then
                        state[key] = math.min(100.0, c + rec)
                        dirty = true
                    end
                end
            end
        end
    end
end)

---------------------------------------------
-- Treatment hooks
---------------------------------------------
RegisterNetEvent('rsg-medic:client:revive', function()
    if cfg.RestoreOnMedic then BoneTracker.heal() end
end)

RegisterNetEvent('rsg-medic:client:heal', function(amount)
    if cfg.RestoreOnMedic and amount == -1 then BoneTracker.heal() end
end)

-- Server-triggered damage (used by the server export DamageBone)
RegisterNetEvent('rsg-playerinfo:client:damageBone', function(key, amount)
    if type(key) == 'string' then BoneTracker.damage(key, amount) end
end)

-- Fresh bone state for a doctor's examination (asked by the server)
RSGCore.Functions.CreateClientCallback('rsg-playerinfo:client:getBones', function(cb)
    cb({ bones = BoneTracker.get(), splints = BoneTracker.getSplints() })
end)

RegisterNetEvent('rsg-playerinfo:client:healBones', function(key)
    BoneTracker.heal(type(key) == 'string' and key or nil)
    RSGCore.Functions.Notify({
        title = locale('cl_sec_medical'),
        description = locale('cl_bones_healed'),
        type = 'success',
    })
end)

---------------------------------------------
-- Exports
---------------------------------------------
exports('GetBoneHealth', function() return BoneTracker.get() end)
exports('HealBones', function(key) BoneTracker.heal(key) end)
exports('DamageBone', function(key, amount) BoneTracker.damage(key, amount) end)
exports('GetBoneStatus', function(key)
    local v = BoneTracker.get()[key]
    return v and BoneTracker.status(v) or nil
end)
exports('GetSplints', function() return BoneTracker.getSplints() end)
exports('BandageBones', function() return BoneTracker.bandage() end)
exports('SplintBones', function() return BoneTracker.splint() end)
-- true when any bone (or the given bone / group of keys) is below the healthy threshold
exports('HasInjury', function(what)
    local bones = BoneTracker.get()
    local keys = Bones.Keys
    if type(what) == 'string' then
        keys = { what }
        for _, g in ipairs(Bones.Groups) do
            if g.id == what then keys = g.bones break end
        end
    end
    for _, k in ipairs(keys) do
        if bones[k] and bones[k] < cfg.Thresholds.healthy then return true end
    end
    return false
end)
