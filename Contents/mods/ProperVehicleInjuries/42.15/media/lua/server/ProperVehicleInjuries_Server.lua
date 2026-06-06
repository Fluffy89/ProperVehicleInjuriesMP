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

Events.OnGameBoot.Add(initProperVehicleInjuriesServer)