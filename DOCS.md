# rsg-playerinfo — Developer Docs

## Contents
1. [Overview](#overview)
2. [Files](#files)
3. [Flow](#flow)
4. [Data returned by the callback](#data-returned-by-the-callback)
5. [NUI](#nui)
6. [Configuration](#configuration)
7. [Events, callbacks and commands](#events-callbacks-and-commands)
8. [Integrations](#integrations)
9. [Security](#security)
10. [Locales](#locales)
11. [Troubleshooting](#troubleshooting)

## Overview
`/info` opens a dashboard covering `Config.ScreenPercent`% (default 80) of the screen. It shows money tiles, identity, employment, a medical check of the player's bones and standing (outlaw status and reputation). Every field is toggled in `Config.PlayerInfoSetup` (`shared/config.lua`). No database tables or items are added; bone health is stored in player metadata (`metadata.bones`).

## Files
| File | Purpose |
|---|---|
| `shared/config.lua` | Size, refresh interval, field toggles, push-to-talk |
| `shared/bones.lua` | Tracked bones, UI groups and the bone id / index lookup tables (generated from the rdr3_discoveries boneNames data) |
| `server/server.lua` | `/info` and `/healbones` commands, the `getPlayerData` callback and the bone save event |
| `client/client.lua` | NUI focus (push-to-talk safe), payload builder, live refresh |
| `client/bones.lua` | Bone damage tracker, recovery, medic hooks and exports |
| `html/index.html`, `style.css`, `script.js` | Dashboard UI |
| `locales/*.json` | Translations (en, de, el, es, fr, it, ja, nl, pl, pt-br, ro) |

## Flow
1. `/info` → server sends `rsg-playerstats:client:openPlayerStats` to the caller.
2. Client calls the `rsg-playerstats:server:getPlayerData` callback.
3. Server reads `Player.PlayerData` (nil-safe) and returns the table below.
4. Client adds the live bone conditions from the bone tracker, then sends `SendNUIMessage({ action = 'open', ... })` with the labels, the `show_*` flags, the size percentage and the data.
5. While open, the client repeats the callback every `Config.RefreshInterval` ms and sends `action = 'update'`. The NUI only re-renders when the data changed.
6. Closing (button, ESC, Backspace) posts the `close` NUI callback, which releases focus.

## Data returned by the callback
```lua
{
  firstname, lastname, citizenid,
  birthdate, gender = 'male' | 'female' | raw, nationality,
  bloodtype, fingerprint, walletid, callsign,           -- from metadata
  job = { label, gradeName, grade, onduty },
  gang = 'Label' | nil,                                  -- nil when gang is 'none'
  otherJobs = { { label, grade }, ... },                 -- rsg-core GetPlayerJobs, active job removed
  money = { cash, bloodmoney, gold, bank },              -- bank = rsg-banking GetTotalBalance, else core bank
  branches = { rhobank?, valbank?, blkbank?, armbank? }, -- only keys that exist in PlayerData.money
  outlaw = { value, text, band = 'good' | 'warn' | 'bad' },
  rep = { { name, value }, ... },                        -- from metadata.rep
}
```
Bone conditions are not part of the callback: the client adds its live values (`BoneTracker.get()`).

The callback returns `nil` when the player is not loaded or asks again within 750 ms.

## Medical check (bones)
**Bones:** `skull`, `neck`, `ribcage`, `lowerspine`, `pelvis`, `collarbone_l/_r`, `upperarm_l/_r`, `forearm_l/_r`, `hand_l/_r`, `thigh_l/_r`, `shin_l/_r`, `foot_l/_r`. Each has a condition from 100 (healthy) to 0 (broken). `_l` is the player's left.

**Illustration:** the skeleton is an original front-view SVG drawn in `html/script.js` (`SKELETON`, plus a faint body silhouette). Every bone key is its own `<g data-bone="...">`; the player's left is on the viewer's right and the `_l` limbs are mirrored copies of the `_r` ones. Status classes (`st-healthy` ... `st-broken`) in `html/style.css` colour the bone and show its crack mark.

**Status** (from `Config.Bones.Thresholds`): `>= 90` healthy, `>= 60` bruised, `>= 30` cracked, `> 0` fractured, `0` broken. The verdict shown is the worst status found; skeletal integrity is the average of all bones.

**Detection** (`client/bones.lua`):
1. Every `PollInterval` ms the client compares `GetEntityHealth` with the previous value.
2. A loss of at least `MinDamagePercent` of max health counts as a hit (smaller losses such as bleeding are ignored).
3. If the ped was falling in the last 1.5 s (`IsPedFalling`), the damage is spread over feet, shins, thighs and pelvis using `Config.Bones.FallWeights`.
4. Otherwise `GetPedLastDamageBone` is read. The bone id is looked up in `Bones.ByBoneId` (ids are identical on mp_male, mp_female and player_zero). A value below 1000 is treated as a bone index and looked up per skeleton in `Bones.ByIndex`. Unknown bones are ignored.
5. The bone loses `damage% x DamageScale` condition.

`GetPedLastDamageBone` is not perfect (it can return the previous hit's bone for non-weapon damage). Set `Config.Bones.Debug = true` to print the raw bone id of every hit in F8 and check it against `shared/bones.lua`.

**Recovery:** bruised bones (condition at or above the bruised threshold) regain `RecoveryPerMinute` per minute. Cracked, fractured and broken bones only heal through treatment.

**Treatment hooks** (client events from rsg-medic, when `RestoreOnMedic = true`): `rsg-medic:client:revive` and `rsg-medic:client:heal` with `-1` (full heal) restore every bone. A normal bandage heal does not. `/healbones [id]` (admin) triggers `rsg-playerinfo:client:healBones`.

**Persistence:** the client sends its bone table to `rsg-playerinfo:server:saveBones` (at most every 2 s, only when something changed). The server checks the shape, clamps every value to 0-100, and stores it with `Player.Functions.SetMetaData('bones', ...)`. It is loaded again on `RSGCore:Client:OnPlayerLoaded`.

### Gameplay effects (`client/effects.lua`)
Reads `BoneTracker.get()` and the worst bone of each group in `Config.Effects.Legs.Bones` / `Arms.Bones`, converts it to a severity (1 bruised, 2 cracked, 3 fractured, 4 broken, from `Config.Bones.Thresholds`) and applies:
- Legs: `SetPedMoveRateOverride` (cap 1.15), `INPUT_SPRINT` / `INPUT_JUMP` disabled from the configured severity, optional `0x8B3CB08158E98481` limp flag (`LimpNative`, undocumented and unverified). Skipped on horseback when `SkipWhenMounted`.
- Arms: while free aiming, a smooth sine-based offset is added to the gameplay camera heading/pitch (only the per-frame change is applied, so normal aiming still works); `INPUT_RELOAD` is disabled from `BlockReloadFrom`.
The loop idles at 500 ms when no effect is active. Everything is reset on heal, unload, death and resource stop. Effects are client-side and cosmetic like the bone state itself.

### Treatment, doctors, pain and logging
- **Items** (`client/treatment.lua`, `server/server.lua`): using `bone_bandage` / `bone_splint` makes the server start the action (`rsg-playerinfo:client:useTreatment`), the client checks there is something to treat and shows the progress bar, then `rsg-playerinfo:server:treatDone` makes the server verify the elapsed time, consume the item and send `rsg-playerinfo:client:applyTreatment`. Cancelling keeps the item.
- **Splints**: stored per bone in `metadata.bonesplints` next to `metadata.bones`. A splinted bone regains `SplintRecoveryPerMinute` per minute online and is released at the healthy threshold. A new hit removes the splint, a full heal clears all splints. For the gameplay effects a splinted bone counts as at most `Treatment.SplintEffectCap`.
- **Doctors**: `/examinebones` and `/treatbones` (names in `Config.Doctor`) check the job (and duty), the distance on the server, then ask the patient's client for fresh bone data (`rsg-playerinfo:client:getBones` client callback). The exam opens the NUI in exam mode (medical card only). Treatment consumes the doctor's items when `UseItems` is true and sends `applyTreatment('doctor')` to the patient.
- **Pain** (`client/pain.lua`): reacts to the local event `rsg-playerinfo:client:boneWorsened (key, severity)` with an anim post FX flash and `PLAY_PAIN` (pain id unverified in-game).
- **Logging**: when a saved bone table crosses `Logging.MinSeverity`, `rsg-log:server:CreateLog` is called (only while rsg-log is started).
- **State for other scripts**: client state bags `boneLegs` / `boneArms` (effective severity 0-4, set with replication) and the client event `rsg-playerinfo:client:severityChanged (legs, arms)`. Server: `exports['rsg-playerinfo']:GetSeverity(src, 'legs'|'arms')`. Example: block climbing when `exports['rsg-playerinfo']:GetSeverity('legs') >= 3` (client) or `Player(src).state.boneLegs >= 3`.

Items to add manually (when `RegisterItems = false`) in `rsg-core/shared/items.lua`:
```lua
bone_bandage = { name = 'bone_bandage', label = 'Bone Bandage', weight = 100, type = 'item', image = 'bandage.png', unique = false, useable = true, shouldClose = true, description = 'Wraps bruised bones.' },
bone_splint  = { name = 'bone_splint',  label = 'Splint',       weight = 300, type = 'item', image = 'bone_splint.png', unique = false, useable = true, shouldClose = true, description = 'Immobilises a cracked or broken bone so it can heal.' },
```

### Exports (client)
| Export | Returns / does |
|---|---|
| `GetBoneHealth()` | Table of bone key to condition (0-100) |
| `GetBoneStatus(key)` | `'healthy'`, `'bruised'`, `'cracked'`, `'fractured'` or `'broken'` (nil for an unknown key) |
| `HasInjury(what?)` | true if any bone, a group (`'core'`, `'arms'`, `'legs'`) or a single bone key is below healthy |
| `GetSeverity(what)` | 0-4 for a bone key or `'legs'` / `'arms'` (0 healthy, 1 bruised, 2 cracked, 3 fractured, 4 broken) |
| `GetSplints()` | Table of splinted bone keys |
| `BandageBones()` / `SplintBones()` | Apply a bandage / splint to the local player (returns how many bones changed, no item is used) |
| `HealBones(key?)` | Restore one bone, or all when `key` is nil |
| `DamageBone(key, amount)` | Remove `amount` condition from a bone |
| `SetEffectsEnabled(bool)` / `AreEffectsEnabled()` | Turn the gameplay effects on/off at runtime (cutscenes, minigames) |
| `OpenPlayerInfo()` / `ClosePlayerInfo()` / `IsPlayerInfoOpen()` | Control the info screen |

### Exports (server)
| Export | Returns / does |
|---|---|
| `GetBones(src)` | Last saved bone table of an online player (can lag ~2 s), or nil |
| `HealBones(src, key?)` | Restore all bones (or one) of an online player; returns true/false |
| `DamageBone(src, key, amount)` | Damage a bone of an online player; returns true/false |
| `GetSeverity(src, what)` | Effective severity 0-4 of `'legs'` or `'arms'` (from the player's state bag) |
| `OpenPlayerInfo(src)` | Open the info screen for a player |

Example: `exports['rsg-playerinfo']:DamageBone(src, 'shin_l', 40)` from a trap script, or `exports['rsg-playerinfo']:HealBones(src)` from a doctor script. The client event `rsg-playerinfo:client:damageBone (key, amount)` and `rsg-playerinfo:client:healBones (key?)` are what the server exports trigger. Prefer the server exports from other scripts so the target is validated.

## NUI
- Messages (Lua → NUI): `open`, `update`, `close`. Callback (NUI → Lua): `close`.
- The panel size is `--size` (percent), set from `Config.ScreenPercent` (clamped 50–100). Sizes use `rem` derived from the screen height so it scales with resolution.
- All values are HTML-escaped; icon classes are validated before use.
- Style follows the house standard (Roboto, monochrome palette, no vignette, no native form elements).

## Configuration
See the table in [README.md](README.md#️-configuration-sharedconfiglua).

Push-to-talk: all focus changes go through `applyNuiFocus()`. While the UI has focus, every control is disabled except `Config.PushToTalkControls`.

## Events, callbacks and commands
| Name | Side | Description |
|---|---|---|
| `/info` | server | Opens the dashboard (no permission required) |
| `/healbones [id]` | server | Restores all bones of a player (admin) |
| `rsg-playerinfo:client:healBones` | client event | Restores all bones and notifies the player |
| `rsg-playerinfo:server:saveBones` | server event | Stores the client's bone table in metadata (validated, 1 s cooldown) |
| `rsg-playerstats:client:openPlayerStats` | client event | Opens the dashboard for the local player |
| `rsg-playerstats:server:getPlayerData` | callback | Returns the data table above |

The `rsg-playerstats` prefix is kept from earlier versions so existing triggers (radial menu, keybinds) keep working. To open the dashboard from another resource: `TriggerEvent('rsg-playerstats:client:openPlayerStats')`.

## Integrations
- **rsg-banking** (optional): `exports['rsg-banking']:GetTotalBalance(citizenid)` supplies the bank tile. Without it the core `money.bank` value is shown.
- **rsg-core multi-job**: `exports['rsg-core']:GetPlayerJobs(src)` supplies "Other Jobs".
- **rsg-medic**: its client events `rsg-medic:client:revive` and `rsg-medic:client:heal` (-1) restore all bones.

## Security
- The callback only returns the requesting player's own data; the license identifier is never sent.
- Per-player 750 ms cooldown on the callback (it queries `players.outlawstatus` with a `?` parameter).
- The NUI has no actions other than `close`.
- Bone health is client-reported (cosmetic): a modified client can report healthy bones. The server validates the shape and range only. If you later tie gameplay penalties to bones, apply them with the same trust level or add server checks.

## Locales
Loaded by rsg-core (`@rsg-core/shared/locale.lua`, `locales/*.json`, `locale('key')`). Language comes from the `rsg:locale` convar. Every file has the same keys as `en.json`.

## Performance notes
The info callback only queries the database / rsg-banking / multi-job when the matching `show_*` option is enabled. The effects loop re-reads the bones 4 times a second and only runs per frame while an effect is actually active.

## Known limitations
Bone state is client-reported (the server validates range and shape but cannot tell a legitimate recovery from a spoofed one), so treat it as roleplay state, not as anything that gates money or items. The last 2 seconds of bone changes can be lost on a hard disconnect.

## Troubleshooting
| Problem | Fix |
|---|---|
| Fields show "No data" | The server's PlayerData has no value for it (e.g. blank callsign); hide it with its `show_*` flag |
| Bank tile shows only the core balance | `rsg-banking` is not started or `GetTotalBalance` did not return a number |
| Regional bank card missing | Only shown when `PlayerData.money` has `rhobank` / `valbank` / `blkbank` / `armbank` |
| Items are missing / have no image | Items are registered at start (`RegisterItems`); add `bone_splint.png` to rsg-inventory's images or point `image` at an existing one |
| `/examinebones` says not a doctor | Check `Config.Doctor.Jobs`, that the player is on duty and that the job name matches rsg-medic |
| No limp animation | `LimpNative` uses an undocumented native; the slowdown and sprint/jump block work without it |
| Bones never change | Set `Config.Bones.Debug = true`, take a hit and read the F8 console: it prints the raw bone id and the bone it mapped to |
| Wrong bone hit | Add or fix the id in `Bones.ByBoneId` (`shared/bones.lua`) |
| Fractures never heal | Only bruises mend on their own; use rsg-medic treatment or `/healbones` |
| Icons missing | The UI loads Font Awesome and Roboto from a CDN; the player needs internet access |
| Screen too big / small | Change `Config.ScreenPercent` |

Support: https://rexshack.tebex.store
