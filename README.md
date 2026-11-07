<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# 🧾 rsg-playerinfo
**Player information / quick stats display for RedM (RSG Core).**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

> Shows a small context menu with the player's name and configurable stats (outlaw status, job, cash, banks, IDs, etc.).  
> Triggered via the `/info` command and shown in a custom NUI panel (RDR2 leather & gold style).

---

## 🛠️ Dependencies
- **rsg-core** (framework & player data)  

**Locales included:** `en`, `fr`, `es`, `it`, `de`, `el`, `ro`  
**License:** GPL‑3.0

---

## ✨ Features
- 🔎 **/info command** opens a context menu showing player details.  
- 📋 Configurable fields: outlaw status, job, job grade, cash, bloodmoney, multiple bank balances, Citizen ID and Server ID.  
- 🧭 Custom NUI panel in the top-right (close with the ✕ button, Close, ESC or Backspace).
- 🎙️ Push-to-talk keeps working while the panel is open (`Config.AllowPushToTalkWhileOpen`).  
- 🔁 Server callback (`rsg-playerstats:server:getPlayerData`) provides data to the client.  
- 🌍 Multi-language support via rsg-core locales (`@rsg-core/shared/locale.lua`, set language with `setr rsg:locale <lang>`).

---

## ⚙️ Configuration (`config.lua`)
The `config.lua` exposes `Config.PlayerInfoSetup` with the following boolean flags:

```lua
Config = {}

Config.PlayerInfoSetup = {
    show_outlawstatus = true,
    show_job = true,
    show_job_grade = true,
    show_cash = true,
    show_bloodmoney = true,
    show_bank = true,
    show_valbank = true,
    show_blkbank = true,
    show_armbank = true,
    show_rhobank = true,
    show_citizenid = true,
    show_serverid = true,
}
```

Toggle any of these to show/hide the corresponding row in the `/info` context menu.

---

## 🔁 How it works
- `RSGCore.Commands.Add('info', ...)` registers the `/info` command which triggers the client event `rsg-playerstats:client:openPlayerStats`.  
- The client calls the server callback `rsg-playerstats:server:getPlayerData` to receive a table with fields such as `outlawstatus`, `job`, `grade`, `cash`, `bloodmoney`, `bank`, `valbank`, `rhobank`, `blkbank`, `armbank`, and `citizenid`.  
- The client builds `optionsArray` depending on `Config.PlayerInfoSetup` flags and displays the result through `lib.showContext('player_info')`.

---

## 📂 Installation
1. Place `rsg-playerinfo` in your `resources/[rsg]` folder.  
2. Ensure `rsg-core` is installed (ox_lib is no longer required).  
3. Add to your `server.cfg`:
```cfg
ensure rsg-core
ensure rsg-playerinfo
```
4. Restart your server.

---

## 🌍 Locales
English keys:
```json
{
  "sv_view_stats" : "View stats",
  "sv_outlawstatus_a" : "Law Abiding Citizen",
  "sv_outlawstatus_b" : "Petty Criminal",
  "sv_outlawstatus_c" : "OutLaw",
  "cl_outlawstatus" : "Outlaw Status",
  "cl_job" : "Job",
  "cl_job_grade" : "Job Grade",
  "cl_funds_in_cash" : "Funds in cash",
  "cl_funds_in_bloodmoney" : "Funds in bloodmoney",
  "cl_funds_in_bank" : "Funds in St.Denis bank",
  "cl_funds_in_rhobank" : "Funds in Rhodes bank",
  "cl_funds_in_valbank" : "Funds in Valentine bank",
  "cl_funds_in_blkbank" : "Funds in Blackwater bank",
  "cl_funds_in_armbank" : "Funds in Armadillo bank",
  "cl_citizenid" : "Citizen ID",
  "cl_serverid": "Server ID",
  "cl_no_data" : "No data"
}
```

---

## 💎 Credits
- **RexshackGaming** — Original author  
  🔗 https://github.com/Rexshack-RedM  
- **RSG / Rexshack-RedM** — adaptation & maintenance  
- **Community contributors & translators**  
- License: GPL‑3.0
