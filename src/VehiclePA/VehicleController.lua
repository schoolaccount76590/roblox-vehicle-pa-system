local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local AccessControl = require(script.Parent.AccessControl)
local AudioUtil = require(script.Parent.AudioUtil)
local Config = require(script.Parent.Config)

local VehicleController = {}
VehicleController.__index = VehicleController

local function findSeat(model: Model): VehicleSeat?
	local namedSeat = model:FindFirstChild(Config.Vehicle.SeatName, true)
	if namedSeat and namedSeat:IsA("VehicleSeat") then
		return namedSeat
	end
	return model:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function makeGroupName(model: Model)
	return Config.Vehicle.GroupPrefix .. string.gsub(HttpService:GenerateGUID(false), "-", "")
end

function VehicleController.new(model: Model, sessionManager)
	local body = model:FindFirstChild(Config.Vehicle.BodyName)
	if not (body and body:IsA("BasePart")) then
		return nil, "Missing Body part"
	end

	local micPart = body:FindFirstChild(Config.Vehicle.MicPartName)
	local speakerPart = body:FindFirstChild(Config.Vehicle.SpeakerPartName)
	local seat = findSeat(model)
	if not (micPart and micPart:IsA("BasePart") and speakerPart and speakerPart:IsA("BasePart") and seat) then
		return nil, "Missing PA parts or seat"
	end

	local groupValue = model:FindFirstChild(Config.Vehicle.AudioGroupValueName)
	if not groupValue then
		groupValue = Instance.new("StringValue")
		groupValue.Name = Config.Vehicle.AudioGroupValueName
		groupValue.Parent = model
	end
	if groupValue.Value == "" then
		groupValue.Value = makeGroupName(model)
	end

	local self = setmetatable({
		Model = model,
		Body = body,
		MicPart = micPart,
		SpeakerPart = speakerPart,
		Seat = seat,
		AudioGroupName = groupValue,
		SessionManager = sessionManager,
		Enabled = false,
		PreviousGroups = {},
		Connections = {},
		CurrentOccupant = seat.Occupant,
	}, VehicleController)

	self:_setupAudioGraph()
	self:_setupPrompt()
	self:_setupSeatMonitoring()
	self:_setEnabled(false)
	return self
end

function VehicleController:_setupAudioGraph()
	local listener = AudioUtil.ensureInstance(self.MicPart, "AudioListener", Config.Vehicle.ListenerName)
	listener.AudioInteractionGroup = self.AudioGroupName.Value

	local echo = AudioUtil.ensureInstance(listener, "AudioEcho", "VehiclePA_Echo")
	local distortion = AudioUtil.ensureInstance(listener, "AudioDistortion", "VehiclePA_Distortion")
	local reverb = AudioUtil.ensureInstance(listener, "AudioReverb", "VehiclePA_Reverb")
	local fader = AudioUtil.ensureInstance(listener, "AudioFader", "VehiclePA_Fader")
	local speakerEmitter = AudioUtil.ensureInstance(self.SpeakerPart, "AudioEmitter", Config.Vehicle.SpeakerEmitterName)

	AudioUtil.applyProperties(echo, Config.VehicleEffects.Echo)
	AudioUtil.applyProperties(distortion, Config.VehicleEffects.Distortion)
	AudioUtil.applyProperties(reverb, Config.VehicleEffects.Reverb)
	AudioUtil.applyProperties(fader, Config.VehicleEffects.Fader)

	AudioUtil.ensureWire(listener, "VehiclePA_Wire_ListenerToEcho", listener, echo)
	AudioUtil.ensureWire(echo, "VehiclePA_Wire_EchoToDistortion", echo, distortion)
	AudioUtil.ensureWire(distortion, "VehiclePA_Wire_DistortionToReverb", distortion, reverb)
	AudioUtil.ensureWire(reverb, "VehiclePA_Wire_ReverbToFader", reverb, fader)
	AudioUtil.ensureWire(fader, "VehiclePA_Wire_FaderToSpeaker", fader, speakerEmitter)

	self.Listener = listener
	self.Fader = fader
end

function VehicleController:_setupPrompt()
	local prompt = AudioUtil.ensureInstance(self.MicPart, "ProximityPrompt", Config.Vehicle.TogglePromptName)
	prompt.ActionText = "Enable PA"
	prompt.ObjectText = "Vehicle PA"
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false

	self.Prompt = prompt
	self.Connections[#self.Connections + 1] = prompt.Triggered:Connect(function(player)
		local allowed = AccessControl.canToggle(player, self.Seat, Config.AccessControl)
		if not allowed then
			return
		end
		self:_setEnabled(not self.Enabled)
	end)
end

function VehicleController:_setEnabled(enabled: boolean)
	self.Enabled = enabled
	self.Prompt.ActionText = enabled and "Disable PA" or "Enable PA"
	self.Model:SetAttribute("VehiclePAEnabled", enabled)
	self.MicPart:SetAttribute("VehiclePAEnabled", enabled)
	if self.Fader then
		self.Fader.Volume = enabled and Config.VehicleEffects.Fader.Volume or 0
	end

	local occupant = self.Seat.Occupant
	if not occupant then
		return
	end
	local player = Players:GetPlayerFromCharacter(occupant.Parent)
	if not player then
		return
	end
	if enabled then
		self:_assignPlayer(player)
	else
		self:_restorePlayer(player)
	end
end

function VehicleController:_assignPlayer(player: Player)
	local currentGroup = self.SessionManager:GetEmitterInteractionGroup(player)
	if currentGroup == nil then
		return
	end
	if self.PreviousGroups[player] == nil then
		self.PreviousGroups[player] = currentGroup
	end
	self.SessionManager:SetEmitterInteractionGroup(player, self.AudioGroupName.Value)
end

function VehicleController:_restorePlayer(player: Player)
	local previousGroup = self.PreviousGroups[player]
	if previousGroup == nil then
		previousGroup = ""
	end
	self.SessionManager:SetEmitterInteractionGroup(player, previousGroup)
	self.PreviousGroups[player] = nil
end

function VehicleController:_setupSeatMonitoring()
	self.Connections[#self.Connections + 1] = self.Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local previousOccupant = self.CurrentOccupant
		local currentOccupant = self.Seat.Occupant
		self.CurrentOccupant = currentOccupant

		if previousOccupant and previousOccupant ~= currentOccupant then
			local previousPlayer = Players:GetPlayerFromCharacter(previousOccupant.Parent)
			if previousPlayer then
				self:_restorePlayer(previousPlayer)
			end
		end

		if self.Enabled and currentOccupant then
			local currentPlayer = Players:GetPlayerFromCharacter(currentOccupant.Parent)
			if currentPlayer then
				self:_assignPlayer(currentPlayer)
			end
		end
	end)

	self.Connections[#self.Connections + 1] = self.Model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy()
		end
	end)
end

function VehicleController:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end

	for player in pairs(self.PreviousGroups) do
		self:_restorePlayer(player)
	end

	self.Connections = {}
	self.PreviousGroups = {}
end

return VehicleController
