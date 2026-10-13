if isServer() then return end

-- PVI = require("ProperVehicleInjuries_Init")
PVIUtils = require("ProperVehicleInjuries_Utils")

-----     CLIENT COMMANDS     -----
local function playerEnteredVehicle()
	-- Send client command updating player entered vehicle
	sendClientCommand("ProperVehicleInjuries", "vehicleEntered", {})
	
end

local function playerExitedVehicle()
	-- Send client command updating player left vehicle
	sendClientCommand("ProperVehicleInjuries", "vehicleExited", {})
	
end

local function onPlayerDeath(player)
	sendClientCommand("ProperVehicleInjuries", "playerDeath", {})
	
end

-----     SERVER COMMANDS     -----
local function onPlayerDiedOnImpact(module, command, player, args)
	if module ~= "ProperVehicleInjuries" then return end
	
	if command == "playerDiedOnImpact" then
		getPlayer():Kill(getPlayer())
		
	end

end

Events.OnGameStart.Add(initMod)
Events.OnEnterVehicle.Add(playerEnteredVehicle)
Events.OnExitVehicle.Add(playerExitedVehicle)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnServerCommand.Add(onPlayerDiedOnImpact)