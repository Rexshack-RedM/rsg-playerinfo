local RSGCore = exports['rsg-core']:GetCoreObject()
local lastRequest = {}
local lastBoneSave = {}
local treating = {}
local lastDoctor = {}

local function asNumber(v)
    v = tonumber(v)
    if v and v == v and v > -math.huge and v < math.huge then return v end
    return nil
end

RSGCore.Commands.Add('info', locale('sv_view_stats'), {}, true, function(source)
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', source)
end)

AddEventHandler('playerDropped', function()
    lastRequest[source] = nil
    lastBoneSave[source] = nil
    treating[source] = nil
    lastDoctor[source] = nil
end)

local function notify(src, key, kind, ...)
    TriggerClientEvent('RSGCore:Client:Notify', src, {
        title = locale('cl_sec_medical'),
        description = locale(key, ...),
        type = kind or 'inform',
    })
end

local function charName(Player)
    local ci = Player.PlayerData.charinfo or {}
    return ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):match('^%s*(.-)%s*$')
end

-- 0 healthy, 1 bruised, 2 cracked, 3 fractured, 4 broken
local SEVERITY_NAME = { 'bruised', 'cracked', 'fractured', 'broken' }
local function severityOf(v)
    local t = Config.Bones.Thresholds
    if v >= t.healthy then return 0 end
    if v >= t.bruised then return 1 end
    if v >= t.cracked then return 2 end
    if v > 0 then return 3 end
    return 4
end

-- Validate bone data coming from a client
local function cleanBones(bones)
    local clean = {}
    bones = type(bones) == 'table' and bones or {}
    for _, key in ipairs(Bones.Keys) do
        local v = asNumber(bones[key]) or 100
        clean[key] = math.floor(math.max(0, math.min(100, v)) + 0.5)
    end
    return clean
end

local function cleanSplints(splints, bones)
    local clean = {}
    if type(splints) ~= 'table' then return clean end
    for _, key in ipairs(Bones.Keys) do
        if splints[key] == true and bones[key] < Config.Bones.Thresholds.bruised then clean[key] = true end
    end
    return clean
end

-- /healbones [id] (admin): restore every bone
RSGCore.Commands.Add('healbones', locale('sv_healbones_help'), {
    { name = 'id', help = locale('sv_healbones_arg') },
}, false, function(source, args)
    local target = tonumber(args[1]) or source
    if not RSGCore.Functions.GetPlayer(target) then return end
    TriggerClientEvent('rsg-playerinfo:client:healBones', target)
end, 'admin')

-- Log newly fractured / broken bones to rsg-log
local function logInjuries(Player, src, old, new)
    local cfg = Config.Logging
    if not (cfg and cfg.Enabled) or GetResourceState('rsg-log') ~= 'started' then return end
    local minSev = cfg.MinSeverity or 3
    for _, key in ipairs(Bones.Keys) do
        local sev = severityOf(new[key])
        local oldSev = severityOf(type(old) == 'table' and asNumber(old[key]) or 100)
        if sev >= minSev and oldSev < minSev then
            TriggerEvent('rsg-log:server:CreateLog', cfg.Channel or 'playerinfo', 'Bone injury', cfg.Color or 'orange',
                ('%s (%s, id %d): %s is now %s'):format(charName(Player), Player.PlayerData.citizenid or '?', src, key, SEVERITY_NAME[sev]))
        end
    end
end

-- Bone health is tracked on the client; the server validates the shape and stores it in metadata
RegisterNetEvent('rsg-playerinfo:server:saveBones', function(bones, splints)
    local src = source
    local now = GetGameTimer()
    if lastBoneSave[src] and (now - lastBoneSave[src]) < 1000 then return end
    lastBoneSave[src] = now

    if type(bones) ~= 'table' then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local clean = cleanBones(bones)
    logInjuries(Player, src, Player.PlayerData.metadata and Player.PlayerData.metadata.bones, clean)
    Player.Functions.SetMetaData('bones', clean)
    Player.Functions.SetMetaData('bonesplints', cleanSplints(splints, clean))
end)

-- Total across all banks (rsg-banking v3). nil when rsg-banking is not running.
local function getBankTotal(citizenid)
    if GetResourceState('rsg-banking') ~= 'started' then return nil end
    local ok, total = pcall(function()
        return exports['rsg-banking']:GetTotalBalance(citizenid)
    end)
    if ok then return asNumber(total) end
    return nil
end

-- Jobs held in addition to the active one (multi-job lives in rsg-core)
local function getOtherJobs(src, currentJob)
    local ok, jobs = pcall(function()
        return exports['rsg-core']:GetPlayerJobs(src)
    end)
    local list = {}
    if not ok or type(jobs) ~= 'table' then return list end
    for _, j in ipairs(jobs) do
        if j.job ~= currentJob then
            list[#list + 1] = {
                label = j.jobLabel or j.job or '',
                grade = j.gradeLabel or tostring(j.grade or ''),
            }
        end
    end
    return list
end

local function getOutlaw(citizenid)
    local value, text, band = 0, locale('cl_no_data'), 'good'
    if citizenid and citizenid ~= '' then
        local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid = ?', { citizenid })
        if result and result[1] and result[1].outlawstatus ~= nil then
            value = tonumber(result[1].outlawstatus) or 0
            if value <= 0 then
                text, band = locale('sv_outlawstatus_a'), 'good'
            elseif value < 100 then
                text, band = locale('sv_outlawstatus_b'), 'warn'
            else
                text, band = locale('sv_outlawstatus_c') .. ' ($' .. value .. ')', 'bad'
            end
        end
    end
    return { value = value, text = text, band = band }
end

local function getGender(raw)
    if raw == nil then return nil end
    local s = tostring(raw):lower()
    if s == '0' or s == 'male' or s == 'm' then return 'male' end
    if s == '1' or s == 'female' or s == 'f' then return 'female' end
    return tostring(raw)
end

RSGCore.Functions.CreateCallback('rsg-playerstats:server:getPlayerData', function(source, cb)
    local src = source

    -- simple per-player cooldown (read-only, but it hits the database)
    local now = GetGameTimer()
    if lastRequest[src] and (now - lastRequest[src]) < 750 then
        cb(nil)
        return
    end
    lastRequest[src] = now

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not Player.PlayerData then
        cb(nil)
        return
    end

    local pd = Player.PlayerData
    local charinfo = pd.charinfo or {}
    local job = pd.job or {}
    local jobGrade = job.grade or {}
    local gang = pd.gang or {}
    local money = pd.money or {}
    local meta = pd.metadata or {}
    local citizenid = pd.citizenid or ''

    -- Reputation (name -> amount)
    local rep = {}
    if type(meta.rep) == 'table' then
        for name, amount in pairs(meta.rep) do
            if type(amount) == 'number' then
                rep[#rep + 1] = { name = tostring(name), value = amount }
            end
        end
        table.sort(rep, function(a, b) return a.name < b.name end)
    end

    -- Regional bank accounts, only when a balance exists
    local branches = {}
    for _, k in ipairs({ 'rhobank', 'valbank', 'blkbank', 'armbank' }) do
        local v = asNumber(money[k])
        if v then branches[k] = v end
    end

    local show = Config.PlayerInfoSetup or {}
    local bank = asNumber(money.bank) or 0
    if show.show_bank then
        local total = getBankTotal(citizenid)
        if total ~= nil then bank = total end
    end

    cb({
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
        citizenid = citizenid,
        birthdate = charinfo.birthdate,
        gender = getGender(charinfo.gender),
        nationality = charinfo.nationality,
        bloodtype = meta.bloodtype,
        fingerprint = meta.fingerprint,
        walletid = meta.walletid,
        callsign = meta.callsign,
        job = {
            label = job.label,
            gradeName = jobGrade.name,
            grade = asNumber(jobGrade.level),
            onduty = job.onduty and true or false,
        },
        gang = (gang.name and gang.name ~= 'none') and (gang.label or gang.name) or nil,
        otherJobs = show.show_other_jobs and getOtherJobs(src, job.name) or {},
        money = {
            cash = asNumber(money.cash) or 0,
            bloodmoney = asNumber(money.bloodmoney) or 0,
            gold = asNumber(money.gold) or 0,
            bank = bank,
        },
        branches = branches,
        outlaw = show.show_outlawstatus and getOutlaw(citizenid) or { value = 0, text = locale('cl_no_data'), band = 'good' },
        rep = rep,
    })
end)

---------------------------------------------
-- Treatment items (bone bandage / splint)
---------------------------------------------
local function removeItem(src, item, reason)
    if not exports['rsg-inventory']:RemoveItem(src, item, 1, nil, reason) then return false end
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', 1)
    return true
end

CreateThread(function()
    local cfg = Config.Treatment
    if not (cfg and cfg.Enabled) then return end

    if cfg.RegisterItems then
        for _, def in ipairs({ cfg.Bandage, cfg.Splint }) do
            if not RSGCore.Shared.Items[def.item] then
                exports['rsg-core']:AddItem(def.item, {
                    name = def.item, label = def.label, weight = def.weight, type = 'item',
                    image = def.image, unique = false, useable = true, shouldClose = true,
                    description = def.description,
                })
            end
        end
    end

    for kind, def in pairs({ bandage = cfg.Bandage, splint = cfg.Splint }) do
        RSGCore.Functions.CreateUseableItem(def.item, function(source)
            local src = source
            local Player = RSGCore.Functions.GetPlayer(src)
            if not Player or Player.PlayerData.metadata.isdead then return end
            local t = treating[src]
            if t and GetGameTimer() - t.started < t.duration + 10000 then return end
            treating[src] = { kind = kind, started = GetGameTimer(), duration = def.duration }
            TriggerClientEvent('rsg-playerinfo:client:useTreatment', src, kind)
        end)
    end
end)

RegisterNetEvent('rsg-playerinfo:server:treatCancel', function()
    treating[source] = nil
end)

-- The client finished the progress bar: consume the item and let the client apply the treatment
RegisterNetEvent('rsg-playerinfo:server:treatDone', function(kind)
    local src = source
    local t = treating[src]
    treating[src] = nil
    if not t or t.kind ~= kind then return end
    if not RSGCore.Functions.GetPlayer(src) then return end
    if GetGameTimer() - t.started < t.duration - 500 then return end -- progress bar skipped

    local def = kind == 'bandage' and Config.Treatment.Bandage or Config.Treatment.Splint
    if not removeItem(src, def.item, 'rsg-playerinfo-' .. kind) then return end
    TriggerClientEvent('rsg-playerinfo:client:applyTreatment', src, kind)
end)

---------------------------------------------
-- Doctor tools
---------------------------------------------
local function isDoctor(Player)
    local cfg = Config.Doctor
    if not (cfg and cfg.Enabled) or not Player then return false end
    local job = Player.PlayerData.job
    if not job then return false end
    local listed = false
    for _, name in ipairs(cfg.Jobs) do
        if name == job.name then listed = true break end
    end
    return listed and (not cfg.RequireDuty or job.onduty == true)
end

local function distanceBetween(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b)))
end

local function nearestPatient(src, maxDist)
    local best, bestDist
    for id in pairs(RSGCore.Functions.GetRSGPlayers()) do
        if id ~= src then
            local d = distanceBetween(src, id)
            if d <= maxDist and (not bestDist or d < bestDist) then best, bestDist = id, d end
        end
    end
    return best
end

-- Validates the doctor and finds the patient. Returns the patient's source or nil (the doctor is notified).
local function resolvePatient(src, args)
    if src == 0 then return nil end
    local cfg = Config.Doctor
    if not isDoctor(RSGCore.Functions.GetPlayer(src)) then notify(src, 'sv_not_doctor', 'error') return nil end

    local now = GetGameTimer()
    if lastDoctor[src] and now - lastDoctor[src] < 2000 then return nil end
    lastDoctor[src] = now

    local target = tonumber(args[1])
    if target then
        if not RSGCore.Functions.GetPlayer(target) then notify(src, 'sv_no_patient', 'error') return nil end
    else
        target = nearestPatient(src, cfg.Distance)
        if not target then notify(src, 'sv_no_patient', 'error') return nil end
    end
    if target ~= src and distanceBetween(src, target) > cfg.Distance then
        notify(src, 'sv_patient_far', 'error')
        return nil
    end
    return target
end

-- Ask the patient's client for fresh bone data (metadata can lag by a couple of seconds)
local function fetchBones(target, cb)
    local done = false
    local function finish(res)
        if done then return end
        done = true
        if type(res) ~= 'table' then return cb(nil) end
        local bones = cleanBones(res.bones)
        cb({ bones = bones, splints = cleanSplints(res.splints, bones) })
    end
    RSGCore.Functions.TriggerClientCallback('rsg-playerinfo:client:getBones', target, finish)
    SetTimeout(3000, function() finish(nil) end)
end

local doctorArgs = { { name = 'id', help = locale('sv_patient_arg'), optional = true } }

RSGCore.Commands.Add(Config.Doctor.ExamCommand, locale('sv_examine_help'), doctorArgs, false, function(source, args)
    local src = source
    local target = resolvePatient(src, args)
    if not target then return end
    fetchBones(target, function(res)
        if not res then notify(src, 'sv_no_patient', 'error') return end
        local Patient = RSGCore.Functions.GetPlayer(target)
        TriggerClientEvent('rsg-playerinfo:client:openExam', src, {
            name = Patient and charName(Patient) or '',
            bones = res.bones,
            splints = res.splints,
        })
    end)
end)

RSGCore.Commands.Add(Config.Doctor.TreatCommand, locale('sv_treatbones_help'), doctorArgs, false, function(source, args)
    local src = source
    local target = resolvePatient(src, args)
    if not target then return end
    fetchBones(target, function(res)
        if not res then notify(src, 'sv_no_patient', 'error') return end

        local needBandage, needSplint = false, false
        for _, key in ipairs(Bones.Keys) do
            local sev = severityOf(res.bones[key])
            if sev == 1 then needBandage = true end
            if sev >= 2 and not res.splints[key] then needSplint = true end
        end
        if not needBandage and not needSplint then notify(src, 'sv_nothing_to_treat', 'inform') return end

        local items = {}
        if Config.Doctor.UseItems and Config.Treatment.Enabled then
            if needBandage then items[#items + 1] = Config.Treatment.Bandage end
            if needSplint then items[#items + 1] = Config.Treatment.Splint end
            for _, def in ipairs(items) do
                if not exports['rsg-inventory']:HasItem(src, def.item, 1) then
                    notify(src, 'sv_missing_item', 'error', def.label)
                    return
                end
            end
            for _, def in ipairs(items) do removeItem(src, def.item, 'rsg-playerinfo-doctor') end
        end

        TriggerClientEvent('rsg-playerinfo:client:applyTreatment', target, 'doctor')
        notify(src, 'sv_patient_treated', 'success')
    end)
end)

---------------------------------------------
-- Exports (server)
---------------------------------------------
-- Last saved bone conditions of a player (0-100 per bone, nil when offline). Can lag the client by ~2 s.
exports('GetBones', function(src)
    local Player = RSGCore.Functions.GetPlayer(tonumber(src))
    return Player and Player.PlayerData.metadata and Player.PlayerData.metadata.bones or nil
end)

-- Restore every bone (or one bone key) of an online player
exports('HealBones', function(src, key)
    src = tonumber(src)
    if not src or not RSGCore.Functions.GetPlayer(src) then return false end
    TriggerClientEvent('rsg-playerinfo:client:healBones', src, key)
    return true
end)

-- Remove condition from one bone of an online player (e.g. a trap, a horse kick, a scripted injury)
exports('DamageBone', function(src, key, amount)
    src = tonumber(src)
    amount = asNumber(amount)
    if not src or not amount or amount <= 0 or not RSGCore.Functions.GetPlayer(src) then return false end
    for _, k in ipairs(Bones.Keys) do
        if k == key then
            TriggerClientEvent('rsg-playerinfo:client:damageBone', src, key, amount)
            return true
        end
    end
    return false
end)

-- Open / close the info screen for a player
exports('OpenPlayerInfo', function(src)
    src = tonumber(src)
    if not src or not RSGCore.Functions.GetPlayer(src) then return false end
    TriggerClientEvent('rsg-playerstats:client:openPlayerStats', src)
    return true
end)

-- Effective severity of 'legs' / 'arms' (0 healthy ... 4 broken) from the replicated state bag
exports('GetSeverity', function(src, what)
    src = tonumber(src)
    if not src or not RSGCore.Functions.GetPlayer(src) then return 0 end
    local state = Player(src).state
    return (what == 'arms' and state.boneArms or what == 'legs' and state.boneLegs or 0) or 0
end)
