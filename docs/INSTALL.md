# Installation Guide

## 1) Studio Requirements

Enable Roblox voice/audio features needed for `AudioDeviceInput`, `AudioListener`, and audio effects.

## 2) Place Scripts

- `src/ServerScriptService/VehiclePA.server.lua` -> `ServerScriptService`
- `src/ServerScriptService/EnsureAddFilterEvent.server.lua` -> `ServerScriptService`
- `src/VehiclePA/*` -> `ServerScriptService/VehiclePA` (ModuleScripts)
- `src/StarterPlayer/StarterPlayerScripts/VoiceListener.client.lua` -> `StarterPlayer/StarterPlayerScripts`

## 3) Vehicle Hierarchy

Each vehicle model should include:

```text
VehicleModel
├─ Body (BasePart)
│  ├─ PA_Mic (BasePart)
│  └─ PA_Speaker (BasePart)
├─ PA_VehicleSeat (VehicleSeat)   -- optional name; any VehicleSeat works
└─ AudioGroupName (StringValue)   -- optional, auto-generated if empty/missing
```

Optional: add CollectionService tag `VehiclePA` to explicitly mark PA-enabled vehicles.

## 4) A-Chassis Integration

Place `PA_VehicleSeat` on the seat that represents the active driver seat used by A-Chassis.
If your pickup/seat logic swaps seats dynamically, keep one stable `VehicleSeat` under the car model and route occupants through it.

## 5) Access Control Defaults

By default, only the current driver can toggle the PA prompt.
You can also set group/rank/attribute rules in `VehiclePA/Config.lua`.
