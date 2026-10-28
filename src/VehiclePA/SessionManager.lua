local Config = require(script.Parent.Config)
local AudioUtil = require(script.Parent.AudioUtil)

local SessionManager = {}
SessionManager._sessions = {}

local function getOrCreateInput(player: Player): AudioDeviceInput
	local input = player:FindFirstChild(Config.PlayerMicInputName)
	if input and input:IsA("AudioDeviceInput") then
		input.Player = player
		return input
	end
	if input then
		input:Destroy()
	end
	input = Instance.new("AudioDeviceInput")
	input.Name = Config.PlayerMicInputName
	input.Player = player
	input.Parent = player
	return input
end

local function setEnabledProperty(effect: Instance, enabled: boolean)
	if not AudioUtil.safeSet(effect, "Bypass", not enabled) then
		if effect:IsA("AudioFader") then
			effect.Volume = enabled and effect.Volume or 1
		end
	end
end

local function setupCharacterChain(player: Player, character: Model)
	local session = SessionManager._sessions[player]
	if not session then
		session = {
			Player = player,
			Input = getOrCreateInput(player),
			Character = nil,
			Emitter = nil,
			Effects = {},
			Connections = {},
		}
		SessionManager._sessions[player] = session
	else
		session.Input = getOrCreateInput(player)
	end

	session.Character = character
	session.Emitter = AudioUtil.ensureInstance(character, "AudioEmitter", Config.PlayerMicEmitterName)

	local echo = AudioUtil.ensureInstance(character, "AudioEcho", Config.PlayerEffectNames.Echo)
	local distortion = AudioUtil.ensureInstance(character, "AudioDistortion", Config.PlayerEffectNames.Distortion)
	local reverb = AudioUtil.ensureInstance(character, "AudioReverb", Config.PlayerEffectNames.Reverb)
	local fader = AudioUtil.ensureInstance(character, "AudioFader", Config.PlayerEffectNames.Fader)

	AudioUtil.applyProperties(echo, Config.PlayerEffects.Echo)
	AudioUtil.applyProperties(distortion, Config.PlayerEffects.Distortion)
	AudioUtil.applyProperties(reverb, Config.PlayerEffects.Reverb)
	AudioUtil.applyProperties(fader, Config.PlayerEffects.Fader)

	session.Effects = {
		Echo = echo,
		Distortion = distortion,
		Reverb = reverb,
		Fader = fader,
	}

	AudioUtil.ensureWire(session.Input, "VehiclePA_Wire_InputToEcho", session.Input, echo)
	AudioUtil.ensureWire(echo, "VehiclePA_Wire_EchoToDistortion", echo, distortion)
	AudioUtil.ensureWire(distortion, "VehiclePA_Wire_DistortionToReverb", distortion, reverb)
	AudioUtil.ensureWire(reverb, "VehiclePA_Wire_ReverbToFader", reverb, fader)
	AudioUtil.ensureWire(fader, "VehiclePA_Wire_FaderToEmitter", fader, session.Emitter)

	return session
end

function SessionManager:InitializePlayer(player: Player)
	if self._sessions[player] and self._sessions[player].Character == player.Character and player.Character then
		return
	end

	local function onCharacterAdded(character: Model)
		setupCharacterChain(player, character)
	end

	local function onCharacterRemoving(character: Model)
		local session = self._sessions[player]
		if session and session.Character == character then
			session.Character = nil
			session.Emitter = nil
			session.Effects = {}
		end
	end

	local connections = {}
	connections[#connections + 1] = player.CharacterAdded:Connect(onCharacterAdded)
	connections[#connections + 1] = player.CharacterRemoving:Connect(onCharacterRemoving)

	local existing = self._sessions[player]
	if existing and existing.Connections then
		for _, connection in ipairs(existing.Connections) do
			connection:Disconnect()
		end
	end

	self._sessions[player] = self._sessions[player] or {}
	self._sessions[player].Connections = connections
	self._sessions[player].Input = getOrCreateInput(player)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function SessionManager:GetSession(player: Player)
	return self._sessions[player]
end

function SessionManager:SetFilterState(player: Player, filterName: string, enabled: boolean, properties: {[string]: number}?): boolean
	local session = self._sessions[player]
	if not session then
		return false
	end

	local effect = session.Effects[filterName]
	if not effect then
		return false
	end

	setEnabledProperty(effect, enabled)
	if properties then
		AudioUtil.applyProperties(effect, properties)
	end
	return true
end

function SessionManager:SetEmitterInteractionGroup(player: Player, groupName: string)
	local session = self._sessions[player]
	if not session or not session.Emitter then
		return false
	end
	session.Emitter.AudioInteractionGroup = groupName
	return true
end

function SessionManager:GetEmitterInteractionGroup(player: Player): string?
	local session = self._sessions[player]
	if not session or not session.Emitter then
		return nil
	end
	return session.Emitter.AudioInteractionGroup
end

function SessionManager:DestroyPlayer(player: Player)
	local session = self._sessions[player]
	if not session then
		return
	end
	for _, connection in ipairs(session.Connections or {}) do
		connection:Disconnect()
	end
	if session.Input and session.Input.Parent == player then
		session.Input:Destroy()
	end
	self._sessions[player] = nil
end

return SessionManager
