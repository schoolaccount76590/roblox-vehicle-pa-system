local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local moduleRoot = ServerScriptService:FindFirstChild("VehiclePA") or script.Parent:FindFirstChild("VehiclePA")
if not moduleRoot then
	error("[VehiclePA] Missing VehiclePA module folder under ServerScriptService")
end

local Config = require(moduleRoot.Config)
local SessionManager = require(moduleRoot.SessionManager)
local VehicleController = require(moduleRoot.VehicleController)

local addFilterEvent = ReplicatedStorage:FindFirstChild(Config.RemoteEventName)
if addFilterEvent and not addFilterEvent:IsA("RemoteEvent") then
	warn(string.format("[VehiclePA] ReplicatedStorage.%s is not a RemoteEvent", Config.RemoteEventName))
	addFilterEvent = nil
end

local controllers: {[Model]: any} = {}
local requestWindows: {[Player]: {windowStart: number, count: number}} = {}

local function debugLog(...)
	if Config.Debug then
		print("[VehiclePA]", ...)
	end
end

local function clampNumber(value: any, min: number, max: number): number?
	if typeof(value) ~= "number" then
		return nil
	end
	if value ~= value then
		return nil
	end
	return math.clamp(value, min, max)
end

local function underRateLimit(player: Player): boolean
	local now = os.clock()
	local existing = requestWindows[player]
	if not existing or (now - existing.windowStart) > Config.RateLimit.WindowSeconds then
		requestWindows[player] = { windowStart = now, count = 1 }
		return true
	end

	if existing.count >= Config.RateLimit.MaxRequestsPerWindow then
		return false
	end

	existing.count += 1
	return true
end

local function parseRequest(filterOrPayload: any, maybePayload: any)
	if typeof(filterOrPayload) == "string" then
		return filterOrPayload, maybePayload
	end
	if typeof(filterOrPayload) == "table" then
		local payload = filterOrPayload
		local filterName = payload.filterName or payload.filter
		if typeof(filterName) == "string" then
			return filterName, payload
		end
	end
	return nil, nil
end

local function sanitizeFilterPayload(filterName: string, payload: any)
	local schema = Config.ClientFilterSchema[filterName]
	if not schema then
		return nil
	end

	local enabled = true
	local cleanProperties = {}
	if typeof(payload) == "table" then
		if payload.enabled ~= nil then
			enabled = payload.enabled == true
		end
		for propertyName, limits in pairs(schema) do
			local value = clampNumber(payload[propertyName], limits.min, limits.max)
			if value ~= nil then
				cleanProperties[propertyName] = value
			end
		end
	end

	return enabled, cleanProperties
end

local function onFilterEvent(player: Player, filterOrPayload: any, maybePayload: any)
	if not underRateLimit(player) then
		warn(string.format("[VehiclePA] Rate limit exceeded for %s", player.Name))
		return
	end

	local filterName, payload = parseRequest(filterOrPayload, maybePayload)
	if not filterName then
		return
	end

	local enabled, cleanProperties = sanitizeFilterPayload(filterName, payload)
	if enabled == nil then
		warn(string.format("[VehiclePA] Rejected unknown filter request '%s' from %s", tostring(filterName), player.Name))
		return
	end

	SessionManager:SetFilterState(player, filterName, enabled, cleanProperties)
end

local function installVehicle(model: Model)
	if controllers[model] then
		return
	end
	local controller, err = VehicleController.new(model, SessionManager)
	if not controller then
		if Config.Debug and err then
			debugLog("Skipped model", model:GetFullName(), err)
		end
		return
	end
	controllers[model] = controller
	debugLog("Installed vehicle", model:GetFullName())
end

local function maybeInstallFromInstance(instance: Instance)
	if not instance:IsA("Model") then
		return
	end

	if CollectionService:HasTag(instance, Config.Vehicle.RequiredTag) then
		installVehicle(instance)
		return
	end

	local body = instance:FindFirstChild(Config.Vehicle.BodyName)
	if not body then
		return
	end
	if body:FindFirstChild(Config.Vehicle.MicPartName) and body:FindFirstChild(Config.Vehicle.SpeakerPartName) and instance:FindFirstChildWhichIsA("VehicleSeat", true) then
		installVehicle(instance)
	end
end

Players.PlayerAdded:Connect(function(player)
	SessionManager:InitializePlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	requestWindows[player] = nil
	SessionManager:DestroyPlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	SessionManager:InitializePlayer(player)
end

for _, instance in ipairs(Workspace:GetDescendants()) do
	maybeInstallFromInstance(instance)
end

Workspace.DescendantAdded:Connect(maybeInstallFromInstance)
CollectionService:GetInstanceAddedSignal(Config.Vehicle.RequiredTag):Connect(function(instance)
	if instance:IsA("Model") then
		installVehicle(instance)
	end
end)

if addFilterEvent then
	addFilterEvent.OnServerEvent:Connect(onFilterEvent)
else
	warn(string.format("[VehiclePA] RemoteEvent '%s' not found; client filter updates disabled", Config.RemoteEventName))
end
