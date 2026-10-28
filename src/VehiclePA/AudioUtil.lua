local AudioUtil = {}

function AudioUtil.ensureInstance(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
end

function AudioUtil.ensureWire(parent: Instance, name: string, source: Instance, target: Instance): Wire
	local wire = AudioUtil.ensureInstance(parent, "Wire", name) :: Wire
	wire.SourceInstance = source
	wire.TargetInstance = target
	return wire
end

function AudioUtil.safeSet(instance: Instance, propertyName: string, value: any)
	local ok = pcall(function()
		(instance :: any)[propertyName] = value
	end)
	return ok
end

function AudioUtil.applyProperties(instance: Instance, properties: {[string]: any})
	for propertyName, value in pairs(properties) do
		AudioUtil.safeSet(instance, propertyName, value)
	end
end

return AudioUtil
