# Vehicle PA System Architecture

## Core Components

- `VehiclePA.server.lua` (server orchestration)
  - Initializes player microphone sessions.
  - Installs PA controllers for vehicle models.
  - Handles and validates `addFilterEvent` requests.
- `VehiclePA` module folder
  - `Config.lua`: names, defaults, access control, rate limits.
  - `SessionManager.lua`: idempotent per-player microphone chain lifecycle.
  - `VehicleController.lua`: per-vehicle PA graph, prompt toggle, seat routing.
  - `AccessControl.lua`: driver/group/attribute access checks.
  - `AudioUtil.lua`: safe instance/wire/property helpers.
- `VoiceListener.client.lua` (client playback)
  - Creates camera `AudioListener` and local `AudioDeviceOutput`.

## Audio Routing Overview

Player microphone route (server):

`AudioDeviceInput -> Echo -> Distortion -> Reverb -> Fader -> AudioEmitter (character)`

Vehicle PA route (server):

`AudioListener (PA_Mic, interaction group) -> Echo -> Distortion -> Reverb -> Fader -> AudioEmitter (PA_Speaker)`

Client playback route (client):

`CurrentCamera AudioListener -> AudioDeviceOutput(LocalPlayer)`

## Occupant Handling

VehicleSeat occupancy uses a captured previous occupant reference to correctly restore the old driver's prior audio interaction group when exiting.

## Security

- Remote event filter updates are validated against a schema.
- Numeric values are clamped.
- Unsupported filters/properties are ignored.
- Requests are rate-limited per player.
