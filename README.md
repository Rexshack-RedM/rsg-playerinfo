<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# 🧾 rsg-playerinfo
**Full-screen player information dashboard for RedM (RSG Core).**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

> `/info` opens a dashboard that fills 80% of the screen (configurable) showing everything about your character: money, identity, job, condition and reputation. RDR2 "leather & gold" house style.

Version 3.1.0 · Full technical details in [DOCS.md](DOCS.md)

---

## 🛠️ Dependencies
- **rsg-core** (framework, player data, locales, multi-job)
- **rsg-inventory** (treatment items), **rsg-medic** (doctor job, optional)
- Optional: **rsg-banking** (shows your total across all banks), **rsg-log** (bone injury logs)

**Locales included:** `en`, `de`, `el`, `es`, `fr`, `it`, `ja`, `nl`, `pl`, `pt-br`, `ro`
**License:** GPL‑3.0

---

## ✨ Features
- 🖥️ **Full dashboard** instead of a small menu: size is set with `Config.ScreenPercent` (default 80% of the screen).
- 💰 Money strip: cash, bloodmoney, gold and bank total.
- 🪪 Identity: date of birth, gender, nationality, blood type, citizen ID, server ID, fingerprint, wallet ID, callsign.
- 💼 Employment: job, grade, duty status, gang and every other job you hold.
- 🦴 **Medical check:** a skeletal examination on an anatomical skeleton illustration (ribs, vertebrae, long bones, hands, feet) with a condition for 19 bones (skull, neck, ribcage, lower spine, pelvis, collarbones, upper arms, forearms, hands, thighs, shins, feet). Healthy bones are plain; injured bones glow amber (bruised, cracked) or red (fractured, broken) and show a crack mark.
- ⚖️ Standing: outlaw status gauge and reputation list.
- 🩺 Bone damage is tracked from the bone that was hit (falls hurt the legs) and saved with your character.
- 🏥 rsg-medic treatment (full heal / revive) restores all bones; bruises also mend slowly on their own.
- 🔄 Live refresh while open (`Config.RefreshInterval`).
- 🎙️ Push-to-talk keeps working while the screen is open (`Config.AllowPushToTalkWhileOpen`).
- 🌍 Multi-language via rsg-core locales (`setr rsg:locale <lang>`).

---

## 📂 Installation
1. Place `rsg-playerinfo` in your `resources/[rsg]` folder.
2. Add to your `server.cfg`:
```cfg
ensure rsg-core
ensure rsg-playerinfo
```
3. Restart your server. No database tables or items are needed.

---

## ⚙️ Configuration (`shared/config.lua`)
| Option | Default | Description |
|---|---|---|
| `Config.ScreenPercent` | `80` | Size of the screen as a percentage (50–100) |
| `Config.RefreshInterval` | `5000` | Live refresh in ms while open (0 = off, minimum 1000) |
| `Config.AllowPushToTalkWhileOpen` | `true` | Keep push-to-talk usable while the UI has focus |
| `Config.PushToTalkControls` | `{ 0x4BC9DABB }` | Controls left enabled while the UI is open |
| `Config.Bones.Enabled` | `true` | Track bone damage |
| `Config.Bones.MinDamagePercent` | `4` | Ignore health losses smaller than this % of max health (bleeding, hunger) |
| `Config.Bones.DamageScale` | `1.0` | Bone condition lost per 1% of max health lost in a hit |
| `Config.Bones.RecoveryPerMinute` | `2.0` | Natural recovery for bruised bones only |
| `Config.Bones.Thresholds` | `90 / 60 / 30` | Condition limits for healthy / bruised / cracked (above 0 = fractured, 0 = broken) |
| `Config.Bones.FallWeights` | see config | Share of fall damage taken by feet, shins, thighs and pelvis |
| `Config.Bones.RestoreOnMedic` | `true` | rsg-medic full heal / revive restores all bones |
| `Config.Bones.Debug` | `false` | Print the raw bone id of every hit to the F8 console |
| `Config.Bones.SplintRecoveryPerMinute` | `0.5` | Condition a splinted bone regains per minute while online |
| `Config.Treatment` | see config | Bandage / splint items (`bone_bandage`, `bone_splint`), durations, `RegisterItems`, `SplintEffectCap` |
| `Config.Doctor` | see config | Doctor jobs, duty, distance, `/examinebones` and `/treatbones` names, `UseItems` |
| `Config.Pain` | see config | Screen flash / pain sound when a bone gets worse |
| `Config.Logging` | see config | rsg-log entry when a bone becomes fractured / broken |
| `Config.Effects.PublishState` | `true` | Publish `boneLegs` / `boneArms` (0-4) as player state bags |
| `Config.Effects.Enabled` | `true` | Gameplay effects of injured bones |
| `Config.Effects.Legs.MoveRate` | `{[2]=0.92,[3]=0.8,[4]=0.65}` | Walk/run speed multiplier by severity (1 bruised, 2 cracked, 3 fractured, 4 broken) |
| `Config.Effects.Legs.BlockSprintFrom` / `BlockJumpFrom` | `3` / `2` | Severity from which sprint / jump is blocked (0 = never) |
| `Config.Effects.Legs.LimpNative` | `false` | Also set the undocumented injured-locomotion flag (not verified in-game) |
| `Config.Effects.Arms.AimSway` | `{0, 0.25, 0.6, 1.0}` | Aim sway in degrees by severity while aiming |
| `Config.Effects.Arms.BlockReloadFrom` | `4` | Broken arm cannot reload (0 = never) |
| `Config.PlayerInfoSetup.show_*` | `true` | Show / hide each field (see list below) |

`show_` flags: `cash`, `bloodmoney`, `gold`, `bank`, `rhobank`, `valbank`, `blkbank`, `armbank`, `birthdate`, `gender`, `nationality`, `bloodtype`, `citizenid`, `serverid`, `fingerprint`, `walletid`, `callsign`, `job`, `job_grade`, `duty`, `gang`, `other_jobs`, `bones`, `outlawstatus`, `reputation`.

---

## 🦴 Gameplay effects
Injured bones now matter: cracked or worse legs slow you down, fractured legs stop sprinting, cracked legs stop jumping; injured arms make your aim sway while aiming, and a broken arm cannot reload. Effects clear when bones are healed (doctor, `/healbones`). Everything is tunable in `Config.Effects`.

## 🩹 Treatment
- **Bone Bandage** (`bone_bandage`): instantly mends bruised bones.
- **Splint** (`bone_splint`): cracked, fractured and broken bones start healing slowly (`SplintRecoveryPerMinute`) and cause weaker effects (`SplintEffectCap`). A new hit to that bone knocks the splint off.
- **Doctors** (`Config.Doctor.Jobs`, on duty): `/examinebones [id]` opens the patient's bone map, `/treatbones [id]` bandages and splints them (uses the doctor's items when `UseItems` is on). With no id the nearest patient is used.
- Items are registered with rsg-core at start (`Config.Treatment.RegisterItems`). Add `bone_splint.png` (and `bandage.png` is reused) to your rsg-inventory images, or set `RegisterItems = false` and add the items to `rsg-core/shared/items.lua` yourself.
- A bone that becomes worse shows a short screen flash and plays a pain sound (`Config.Pain`). New fractures and breaks are sent to rsg-log (`Config.Logging`).

## 🎮 How to use
- Type `/info` to open the dashboard.
- Close with the ✕ button, the Close button, `ESC` or `Backspace`.
- Hover a bone on the map (or a row in the list) to highlight it in both places.
- `/healbones [id]` (admin) restores every bone of yourself or another player.
- Hold your push-to-talk key to keep talking while it is open.

---

## 🔌 Exports
Client: `GetSplints`, `BandageBones`, `SplintBones`, `GetBoneHealth`, `GetBoneStatus`, `HasInjury`, `GetSeverity`, `HealBones`, `DamageBone`, `SetEffectsEnabled`, `AreEffectsEnabled`, `OpenPlayerInfo`, `ClosePlayerInfo`, `IsPlayerInfoOpen`.
Server: `GetSeverity`, `GetBones`, `HealBones`, `DamageBone`, `OpenPlayerInfo`. Other scripts can also read the player state bags `boneLegs` and `boneArms` (0-4) or listen to the client event `rsg-playerinfo:client:severityChanged`. See DOCS.md for details.

## 🌍 Locales
All text lives in `locales/*.json` (`en` is the master file, every other file has the same keys). Add a language by copying `en.json`.

---

## 💎 Credits
- **RexshackGaming** — Original author  
  🔗 https://github.com/Rexshack-RedM  
- **RSG / Rexshack-RedM** — adaptation & maintenance  
- **Community contributors & translators**  
- License: GPL‑3.0


Support: https://rexshack.tebex.store
