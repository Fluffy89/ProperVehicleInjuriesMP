if isServer() then return end

PVI = PVI or {}
PVIUtils = PVIUtils or {}

local function playerEnteredVehicle()
	-- Send client command updating player entered vehicle
	sendClientCommand(getPlayer(), "ProperVehicleInjuries", "vehicleEntered", {})
	
end

local function playerExitedVehicle()
	-- Send client command updating player left vehicle
	sendClientCommand(getPlayer(), "ProperVehicleInjuries", "vehicleExited", {})
	
end

local function initMod()
	local sBO = getSandboxOptions()

	--Events.OnEnterVehicle.Add(addCheckCollision)
	--Events.OnExitVehicle.Add(removeCheckCollision)
	print("PVI Client Initialized!")
	
	-- Requires PVI_Util
	-- setBodyParts(0, getPlayer()) -- Core function that actually sets body part tables
	-- Events.OnCreatePlayer.Add(setBodyParts) -- Register resetBodyParts to event so the tables reflect the current character to avoid old references
	-- if modInstalled("WorkingSeatbelt") then initWorkingSeatbeltCompatibility(sBO) end
	-- if modInstalled("RealKnockouts") then initRealKnockoutCompatibility(sBO) end
end

Events.OnGameStart.Add(initMod)
Events.OnEnterVehicle.Add(playerEnteredVehicle)
Events.OnExitVehicle.Add(playerExitedVehicle)