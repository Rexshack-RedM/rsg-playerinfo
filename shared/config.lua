Config = {}

-- Size of the info screen as a percentage of the game screen (50-100).
Config.ScreenPercent = 80

-- While the screen is open, refresh the data every X milliseconds (0 = off, minimum 1000).
Config.RefreshInterval = 5000

-- Show / hide individual fields and sections.
Config.PlayerInfoSetup = {
    -- Money tiles
    show_cash = true,
    show_bloodmoney = true,
    show_gold = true,
    show_bank = true,            -- total across banks (rsg-banking) or the core bank balance
    -- Regional bank accounts (only listed when the server actually has a balance for them)
    show_rhobank = true,
    show_valbank = true,
    show_blkbank = true,
    show_armbank = true,
    -- Identity
    show_birthdate = true,
    show_gender = true,
    show_nationality = true,
    show_bloodtype = true,
    show_citizenid = true,
    show_serverid = true,
    show_fingerprint = true,
    show_walletid = true,
    show_callsign = true,
    -- Employment
    show_job = true,
    show_job_grade = true,
    show_duty = true,
    show_gang = true,
    show_other_jobs = true,
    -- Medical check
    show_bones = true,           -- skeletal examination (bone health map)
    -- Standing
    show_outlawstatus = true,
    show_reputation = true,
}

-- Bone health tracking (feeds the Medical Check card).
-- Each bone has a condition from 100 (healthy) down to 0 (broken). A hit lowers the condition of the bone that was hit.
Config.Bones = {
    Enabled = true,
    PollInterval = 150,          -- ms between health checks
    MinDamagePercent = 4,        -- ignore health losses smaller than this % of max health (bleeding, hunger, ...)
    DamageScale = 1.0,           -- bone condition lost per 1% of max health lost in a hit
    RecoveryPerMinute = 2.0,     -- natural recovery for bruised bones only (cracked/fractured/broken need a splint or a doctor)
    SplintRecoveryPerMinute = 0.5, -- splinted bones mend slowly while the player is online (0.5 = about 3 h from broken to healed)
    -- Condition thresholds: >= healthy = healthy, >= bruised = bruised, >= cracked = cracked, > 0 = fractured, 0 = broken
    Thresholds = { healthy = 90, bruised = 60, cracked = 30 },
    -- A fall damages the legs instead of the "last damage bone" (share of the damage each bone takes, both sides)
    FallWeights = { foot = 1.0, shin = 0.7, thigh = 0.4, pelvis = 0.2 },
    -- Doctors / revives restore all bones: rsg-medic:client:revive and rsg-medic:client:heal (-1 = full heal)
    RestoreOnMedic = true,
    Debug = false,               -- print the raw bone id of every hit in the F8 console
}

-- Gameplay effects of injured bones (needs Config.Bones.Enabled). Severity: 1 bruised, 2 cracked, 3 fractured, 4 broken.
-- Tables are indexed by severity; a missing/0 entry means no effect at that level. The worst bone of each group counts.
Config.Effects = {
    Enabled = true,
    PublishState = true,         -- expose severities as player state bags (boneLegs / boneArms, 0-4) for other scripts
    Legs = {
        Bones = { 'pelvis', 'thigh_l', 'thigh_r', 'shin_l', 'shin_r', 'foot_l', 'foot_r' },
        MoveRate = { [2] = 0.92, [3] = 0.8, [4] = 0.65 },   -- walk/run speed multiplier (game cap is 1.15)
        BlockSprintFrom = 3,         -- fractured or worse cannot sprint (0 = never)
        BlockJumpFrom = 2,           -- cracked or worse cannot jump (0 = never)
        LimpNative = false,          -- also set the undocumented injured-locomotion flag from this severity (0 = off, e.g. 3). Not verified in-game
        LimpFrom = 3,
        SkipWhenMounted = true,      -- no leg effects while riding
    },
    Arms = {
        Bones = { 'collarbone_l', 'collarbone_r', 'upperarm_l', 'upperarm_r', 'forearm_l', 'forearm_r', 'hand_l', 'hand_r' },
        AimSway = { [1] = 0.0, [2] = 0.25, [3] = 0.6, [4] = 1.0 }, -- sway amplitude in degrees while aiming
        SwaySpeed = 1.7,             -- how fast the aim drifts
        BlockReloadFrom = 4,         -- broken arm cannot reload (0 = never)
    },
}

-- Treatment: bandages mend bruises instantly, splints let cracked/fractured/broken bones heal slowly on their own.
-- A splinted bone loses its splint when it is hit again. Doctors (rsg-medic) can treat others, see Config.Doctor.
Config.Treatment = {
    Enabled = true,
    RegisterItems = true,        -- register the two items with rsg-core at start. Set false if you add them to rsg-core/shared/items.lua yourself
    Bandage = { item = 'bone_bandage', label = 'Bone Bandage', weight = 100, image = 'bandage.png', description = 'Wraps bruised bones.', duration = 4000 },
    Splint  = { item = 'bone_splint',  label = 'Splint',       weight = 300, image = 'bone_splint.png', description = 'Immobilises a cracked or broken bone so it can heal.', duration = 8000 },
    SplintEffectCap = 2,         -- a splinted bone counts as at most this severity for the gameplay effects (2 = cracked)
}

-- Doctor tools: /examinebones shows a patient's bone map, /treatbones bandages and splints them.
Config.Doctor = {
    Enabled = true,
    Jobs = { 'medic' },          -- same job names as rsg-medic Config.MedicJobs
    RequireDuty = true,
    Distance = 3.0,              -- metres between doctor and patient
    ExamCommand = 'examinebones',
    TreatCommand = 'treatbones',
    UseItems = true,             -- /treatbones consumes the doctor's bandage / splint items (false = free)
}

-- Screen flash and pain sound when a bone gets worse. Severity: 1 bruised, 2 cracked, 3 fractured, 4 broken.
Config.Pain = {
    Enabled = true,
    MinSeverity = 2,             -- only react from this severity up
    Cooldown = 4000,             -- ms between reactions
    Flash = 'MP_HealthDrop',     -- anim post FX name ('' = off)
    FlashDuration = 1500,
    Sound = true,                -- play a pain sound on the ped
    PainId = 10,                 -- PLAY_PAIN id (10 = fall hurt, unverified in-game; 0..12 are valid)
}

-- Log new fractures/breaks to rsg-log (when running)
Config.Logging = {
    Enabled = true,
    Channel = 'playerinfo',
    Color = 'orange',
    MinSeverity = 3,             -- 3 = log fractures and breaks, 4 = breaks only
}

-- While NUI is open, block game controls but allow push-to-talk.
Config.AllowPushToTalkWhileOpen = true
Config.PushToTalkControls = {
    0x4BC9DABB, -- INPUT_PUSH_TO_TALK
}
