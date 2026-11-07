# rsg-playerinfo — Developer Docs

## Overview
`/info` opens a top-right menu showing the player's name, outlaw status, job/grade, cash, bloodmoney, bank balances, citizen ID and server ID. Each field is toggled in `Config.PlayerInfoSetup` (`shared/config.lua`).

## Flow
1. Server command `info` → `TriggerClientEvent('rsg-playerstats:client:openPlayerStats', src)`.
2. Client calls `RSGCore.Functions.TriggerCallback('rsg-playerstats:server:getPlayerData')`.
3. Server callback reads `Player.PlayerData` (validated, nil-safe) and returns it via `cb(data)`.
4. Client builds rows `{ label, value, icon }` from `FIELD_CONFIGS` and sends `SendNUIMessage({ action = 'open', title, subtitle, closeLabel, rows })`.
5. NUI (`html/`) renders the panel; closing posts the `close` NUI callback, which releases focus.

## NUI
- Files: `html/index.html`, `html/style.css`, `html/script.js` (Roboto + Font Awesome 6 icons; icon strings are FA classes in `FIELD_CONFIGS`).
- Messages: `open` / `close`. Callback: `close`.
- All values are HTML-escaped before rendering.

## Config
```lua
Config.AllowPushToTalkWhileOpen = true   -- keep push-to-talk while the panel has focus
Config.PushToTalkControls = { 0x4BC9DABB } -- INPUT_PUSH_TO_TALK
```
All focus changes go through `applyNuiFocus()`; while focused, every control is disabled except the push-to-talk list.

## Locales
Loaded by rsg-core: `shared_scripts { '@rsg-core/shared/locale.lua' }`, files in `locales/*.json`, called with `locale('key')`. Language comes from the `rsg:locale` convar (fallback `ox:locale`, then `en`).

## ox_lib migration status
Fully migrated — no ox_lib dependency.
| Usage | Replacement |
|---|---|
| `lib.locale()` | `@rsg-core/shared/locale.lua` |
| Callbacks | `RSGCore.Functions.CreateCallback` / `TriggerCallback` |
| `lib.registerContext` / `showContext` | resource's own NUI panel |
