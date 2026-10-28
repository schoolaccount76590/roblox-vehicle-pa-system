local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "addFilterEvent"

local existing = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if existing == nil then
	local remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage
elseif not existing:IsA("RemoteEvent") then
	warn(string.format("[VehiclePA] ReplicatedStorage.%s exists but is not a RemoteEvent", REMOTE_NAME))
end
