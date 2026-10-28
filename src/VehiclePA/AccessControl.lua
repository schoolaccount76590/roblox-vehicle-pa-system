local Players = game:GetService("Players")

type AccessConfig = {
	DriverOnly: boolean,
	RequiredGroupId: number,
	MinimumGroupRank: number,
	RequiredAttributeName: string?,
	RequiredAttributeValue: any,
}

local AccessControl = {}

function AccessControl.canToggle(player: Player, seat: VehicleSeat?, config: AccessConfig): (boolean, string?)
	if config.DriverOnly then
		if not seat or not seat.Occupant then
			return false, "Vehicle has no driver"
		end
		local driver = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
		if driver ~= player then
			return false, "Driver-only control"
		end
	end

	if config.RequiredGroupId > 0 then
		if not player:IsInGroup(config.RequiredGroupId) then
			return false, "Group membership required"
		end
		if player:GetRankInGroup(config.RequiredGroupId) < config.MinimumGroupRank then
			return false, "Insufficient group rank"
		end
	end

	if config.RequiredAttributeName then
		if player:GetAttribute(config.RequiredAttributeName) ~= config.RequiredAttributeValue then
			return false, "Missing required access attribute"
		end
	end

	return true
end

return AccessControl
