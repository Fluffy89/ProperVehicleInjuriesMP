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

local function onCreatePlayer(player)
	if player == nil then 
		PVIUtils.log("Nil player received in onCreatePlayer, returning.")
		return
		
	end

	sendClientCommand("ProperVehicleInjuries", "initPlayer", {})
	Events.OnPlayerUpdate.Remove(onCreatePlayer)
	
end

local function onPlayerDeath(player)
	sendClientCommand("ProperVehicleInjuries", "playerDeath", {})
	
end

Events.OnGameStart.Add(initMod)
Events.OnEnterVehicle.Add(playerEnteredVehicle)
Events.OnExitVehicle.Add(playerExitedVehicle)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)