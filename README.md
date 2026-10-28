# Roblox Vehicle PA System

Production-ready, open-source Roblox vehicle public-address (PA) system for law-enforcement and emergency-service roleplay vehicles.

## Features

- Secure player microphone initialization (`AudioDeviceInput` + character `AudioEmitter`).
- Vehicle PA audio graph with configurable echo/distortion/reverb/fader effects.
- Per-vehicle PA toggle prompt (no global shared toggle state).
- Driver seat routing with proper previous-occupant restore logic.
- Multi-vehicle support with isolated interaction groups (no cross-talk).
- Hardened `addFilterEvent` RemoteEvent validation and rate-limiting.
- Idempotent setup to avoid duplicate listeners/effects/wires on respawn/reload.

## Repository Layout

```text
src/
├─ ServerScriptService/
│  ├─ EnsureAddFilterEvent.server.lua
│  └─ VehiclePA.server.lua
├─ StarterPlayer/
│  └─ StarterPlayerScripts/
│     └─ VoiceListener.client.lua
├─ VehiclePA/
│  ├─ AccessControl.lua
│  ├─ AudioUtil.lua
│  ├─ Config.lua
│  ├─ SessionManager.lua
│  └─ VehicleController.lua
└─ ReplicatedStorage/
   └─ README.md

docs/
├─ ARCHITECTURE.md
└─ INSTALL.md
```

## Quick Setup

1. Follow `docs/INSTALL.md`.
2. Ensure vehicles contain `Body`, `PA_Mic`, `PA_Speaker`, and a driver `VehicleSeat`.
3. Confirm `ReplicatedStorage.addFilterEvent` exists (auto-created if missing).
4. Start a test server with multiple players and verify:
   - driver can toggle PA,
   - PA audio plays through `PA_Speaker`,
   - leaving seat restores prior player interaction group.

## Required Voice/Audio Notes

- This system depends on Roblox voice/audio objects (`AudioDeviceInput`, `AudioListener`, `AudioEmitter`, audio effects).
- Studio/game voice permissions and account eligibility must allow microphone input.

## RemoteEvent API (`addFilterEvent`)

Server accepts only whitelisted filters and safe numeric values:

```lua
addFilterEvent:FireServer("Echo", {
	enabled = true,
	DelayTime = 0.08,
	DryLevel = 0.2,
	Feedback = 0.35,
})
```

## Troubleshooting

- **No PA output:** verify local `VoiceListener.client.lua` is running and camera listener exists.
- **Driver cannot toggle:** check seat mapping and access control in `Config.lua`.
- **Cross-talk:** ensure each vehicle has unique `AudioGroupName` (auto-generated when empty).
- **Filter requests ignored:** request may exceed rate limit or fail schema validation.

## Contributing

Contributions are welcome via pull requests.

- Keep changes focused and documented.
- Prefer safe server validation for all client-driven behavior.
- Update docs when changing installation or architecture behavior.

## License

MIT (see `LICENSE`).
