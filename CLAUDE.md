# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

DyzCarSystem is a FiveM resource (GTA V multiplayer mod) — a vehicle HUD rendered via NUI. No build system, no package manager, no tests. Files are loaded directly by the FiveM runtime per `fxmanifest.lua`.

## Running / iterating

- Place repo as a folder inside the FiveM server's `resources/` directory and add `ensure DyzCarSystem` to `server.cfg`.
- No build step. Edits to `.lua` / `.html` / `.css` / `.js` take effect after `restart DyzCarSystem` (or `refresh; ensure ...`) in the server console.
- NUI debugging: `nui_devtools DyzCarSystem` in the F8 client console opens Chromium devtools on the HUD page.
- There is no lint or test harness — verify changes by running in a FiveM dev server and entering a vehicle.

## Architecture

Two sides communicate via NUI messages only — there is no server script.

**Client (Lua, `client/`)** runs three independent `Citizen.CreateThread` loops in `main.lua`:
1. **Info loop (~100ms in vehicle)** — reads `GetEntityHealth`, `GetVehicleFuelLevel`, `GetEntitySpeed`, `GetVehicleCurrentGear`, builds heading + street + zone label using `Config['Directions']` and `Config['Zones']` lookup tables, sends `updateInfo` NUI event.
2. **Input/physics loop (~5ms in vehicle)** — handles seatbelt toggle (`Config['seatbeltInput']`), eject-on-crash logic (compares per-frame acceleration against `seatbeltEjectAccel * 9.81`), cruise control toggle (`Config['cruiseInput']`), and the cruise speed PID-ish ramp via `SetVehicleForwardSpeed`. Also drives engine status events.
3. **Vehicle-enter/exit loop (500ms)** — polls `GetVehiclePedIsIn`, resets state on exit, queries `GetVehicleClass` and uses `Config['BeltClass']` to decide whether the seatbelt UI should appear.

Speed-vs-engine-health coupling: when `vehicleHealth <= 30`, top speed is clamped via `SetVehicleMaxSpeed` proportional to engine health; at health 0 the engine is force-killed.

**NUI (`html/`)** — `js/index.js` exposes a single `_messageBomb` dispatch table keyed by event name. Lua → JS contract is exactly: `placeNameEnabled`, `toggleUI`, `updateInfo`, `toggleBelt`, `toggleCruise`, `toggleEngine`. All Lua sends go through `triggerNUI(eventName, payload)` in `client/function.lua` which wraps `SendNUIMessage`. When adding a new HUD signal, add a handler in `_messageBomb` and call `triggerNUI` from Lua — do not bypass this wrapper.

**Config (`config_c.lua`)** is a global `Config` table loaded before `client/*.lua` per `fxmanifest.lua` ordering. `BeltClass` is keyed by GTA vehicle class id (0–22); `Zones` and `Directions` are static lookup tables consumed by the info loop. `useKM` flips speed math between `* 3.6` (km/h) and `* 2.236936` (mph).

## Things to know before changing code

- `fxmanifest.lua` lists every loaded file explicitly — new images, JS, CSS, or Lua files must be added there or FiveM will not serve them.
- Load order matters: `config_c.lua` → `client/function.lua` → `client/main.lua`. `function.lua` defines `triggerNUI` and `isVehicleClassHasBelt` used as globals by `main.lua`.
- The cruise control logic in `main.lua` uses `inair` as a debounce counter against `IsEntityInAir`, and `cruiseSpeeding` as a ramped target — touching one without the other will desync cruise behavior (see commits `75602a7`, `5e074e7`).
- License is GPL-3.0; per README, derivative work must remain open-source.
