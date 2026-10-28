local Config = {}

Config.Debug = false

Config.RemoteEventName = "addFilterEvent"
Config.PlayerMicInputName = "VehiclePA_MicInput"
Config.PlayerMicEmitterName = "VehiclePA_MicEmitter"
Config.PlayerEffectNames = {
	Echo = "VehiclePA_Echo",
	Distortion = "VehiclePA_Distortion",
	Reverb = "VehiclePA_Reverb",
	Fader = "VehiclePA_Fader",
}

Config.Vehicle = {
	BodyName = "Body",
	MicPartName = "PA_Mic",
	SpeakerPartName = "PA_Speaker",
	AudioGroupValueName = "AudioGroupName",
	SeatName = "PA_VehicleSeat", -- Optional. Falls back to first VehicleSeat if missing.
	ListenerName = "VehiclePA_Listener",
	SpeakerEmitterName = "VehiclePA_SpeakerEmitter",
	TogglePromptName = "VehiclePA_TogglePrompt",
	GroupPrefix = "VehiclePA_",
	RequiredTag = "VehiclePA", -- Optional CollectionService tag. Untagged models are still autodetected.
}

Config.AccessControl = {
	DriverOnly = true,
	RequiredGroupId = 0,
	MinimumGroupRank = 0,
	RequiredAttributeName = nil,
	RequiredAttributeValue = true,
}

Config.RateLimit = {
	WindowSeconds = 1,
	MaxRequestsPerWindow = 10,
}

Config.VehicleEffects = {
	Echo = { DelayTime = 0.08, DryLevel = 0.2, Feedback = 0.35 },
	Distortion = { Level = 0.12 },
	Reverb = { DecayTime = 0.15, DryLevel = 0.2 },
	Fader = { Volume = 0.9 },
}

Config.PlayerEffects = {
	Echo = { DelayTime = 0.06, DryLevel = 0.25, Feedback = 0.25 },
	Distortion = { Level = 0 },
	Reverb = { DecayTime = 0.05, DryLevel = 0.15 },
	Fader = { Volume = 1 },
}

Config.ClientFilterSchema = {
	Echo = {
		DelayTime = { min = 0, max = 1.5 },
		DryLevel = { min = 0, max = 1 },
		Feedback = { min = 0, max = 1 },
	},
	Distortion = {
		Level = { min = 0, max = 1 },
	},
	Reverb = {
		DecayTime = { min = 0, max = 3 },
		DryLevel = { min = 0, max = 1 },
	},
	Fader = {
		Volume = { min = 0, max = 1.5 },
	},
}

return Config
