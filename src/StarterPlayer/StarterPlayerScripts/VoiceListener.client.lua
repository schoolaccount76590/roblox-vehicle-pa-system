local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local LISTENER_NAME = "VehiclePA_ClientListener"
local OUTPUT_NAME = "VehiclePA_DeviceOutput"

local activeConnections = {}

local function disconnectAll()
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end
	table.clear(activeConnections)
end

local function cleanupCameraAudio(camera: Camera)
	local listener = camera:FindFirstChild(LISTENER_NAME)
	if listener then
		listener:Destroy()
	end
end

local function setupCameraAudio(camera: Camera)
	cleanupCameraAudio(camera)

	-- Audio route for each client:
	--   world/vehicle emitters -> listener on CurrentCamera -> AudioDeviceOutput owned by LocalPlayer.
	local listener = Instance.new("AudioListener")
	listener.Name = LISTENER_NAME
	listener.Parent = camera

	local output = Instance.new("AudioDeviceOutput")
	output.Name = OUTPUT_NAME
	output.Player = localPlayer
	output.Parent = listener

	local wire = Instance.new("Wire")
	wire.Name = "VehiclePA_Wire_ListenerToOutput"
	wire.SourceInstance = listener
	wire.TargetInstance = output
	wire.Parent = listener
end

local function bindCamera()
	disconnectAll()

	local function onCameraChanged()
		local camera = Workspace.CurrentCamera
		if camera then
			setupCameraAudio(camera)
		end
	end

	activeConnections[#activeConnections + 1] = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(onCameraChanged)
	onCameraChanged()
end

bindCamera()
