if not isServer() then return end

local function initProperVehicleInjuriesServer()
	local sBO = getSandboxOptions()
	
	print("\n\n\n")
	print("-----------------------------------------------------")
	print("[PVI] Forcing 'PlayerDamageFromCrash' to false...")
	
	if (sBO:getOptionByName("PlayerDamageFromCrash"):getValue() == false) then
		print("[PVI] 'PlayerDamageFromCrash' already disabled, skipping rest of initialization. I hope you enjoy PVI :)")
	
	else 
		print("[PVI] Disabled 'PlayerDamageFromCrash', PVI now solely handles crash injuries. I hope you enjoy PVI :)")
		sBO:set("PlayerDamageFromCrash", false)
		print("[PVI] PlayerDamageFromCrash state: " .. tostring(sBO:getOptionByName("PlayerDamageFromCrash"):getValue()))
	
	end
	
	print("-----------------------------------------------------\n\n\n")
end


local function onClientCommand(module, command, player, args)
	if module ~= "ProperVehicleInjuries" then
		return
	
	end
	
	if command == "PVICrash" then
		print("[PVI] Player: " .. player:getFullName() .. " was involved in a crash!")
		
		local leftHand = player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)
		leftHand:setScratched(true, true)
		leftHand:setScratchTime(10)
		
		local flags = java.lang.Long.sum(
			BodyPartSyncPacket.BD_scratched, BodyPartSyncPacket.BD_scratchTime
		)
		
		syncBodyPart(leftHand, flags)
		
		
	end

end

Events.OnGameBoot.Add(initProperVehicleInjuriesServer)
Events.OnClientCommand.Add(onClientCommand)