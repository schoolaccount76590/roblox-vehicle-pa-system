# ReplicatedStorage Setup

`ReplicatedStorage` must contain a `RemoteEvent` named `addFilterEvent`.

- The included server script `EnsureAddFilterEvent.server.lua` creates it only when missing.
- If an instance with that name already exists and is not a `RemoteEvent`, the system logs a warning and will not overwrite it.

Client scripts can request safe microphone filter updates with:

```lua
addFilterEvent:FireServer("Echo", {
	enabled = true,
	DelayTime = 0.08,
	DryLevel = 0.2,
	Feedback = 0.35,
})
```

Only whitelisted filter names and numeric properties are accepted.
