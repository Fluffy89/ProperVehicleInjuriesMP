--if not isServer() then return end
if isClient() then return end -- SHOULD load server in SP, but NOT in MP


PVI = require("ProperVehicleInjuries_Init")
PVIUtils = require("ProperVehicleInjuries_Utils")


-- GLOBAL CONSTANTS --
-- local ticks = 0


-- GLOBAL FLAGS --
local monitoringCollisions = false


-- MONITORED PLAYERS --
local playerCount = 0
local bodyPartCount = 0
local monitoredPlayers = {} -- Holds table for each player, that holds that player's previous speed and speed difference
local playerBodyParts = {}


-----    PLAYER MONITORING     -----
local function startMonitoringPlayer(player)
	if monitoredPlayers[player] ~= nil then return end
	
	PVIUtils.log("Monitoring 1 new player: " .. player:getFullName())
	monitoredPlayers[player] = {prevSpeed = 0, injuryLockout = 0}
	playerCount = playerCount + 1
	PVIUtils.log("New player count: " .. playerCount)
	PVIUtils.log("monitoringCollisions = " .. tostring(monitoringCollisions))
	
	-- Should only start monitoring checkCollisions when we:
		-- Have at least 1 player in a vehicle
		-- Aren't already monitoring collisions
	if (playerCount > 0) and (not monitoringCollisions) then
		PVIUtils.log("Starting checkCollision loop...")
		Events.OnTick.Add(checkCollision)
		monitoringCollisions = true
				
	end
	
end

local function stopMonitoringPlayer(player)
	if monitoredPlayers[player] == nil then return end

	PVIUtils.log("No longer monitoring player: " .. player:getFullName())
	monitoredPlayers[player] = nil
	playerCount = playerCount - 1
	PVIUtils.log("New player count: " .. playerCount)
	PVIUtils.log("monitoringCollisions = " .. tostring(monitoringCollisions))
	
	-- Should only stop monitoring when we:
		-- Have nobody in a vehicle
		-- Are currently monitoring players
	if (playerCount == 0) and (monitoringCollisions) then
		PVIUtils.log("No players in vehicles, stopping checkCollision...")
		Events.OnTick.Remove(checkCollision)
		monitoringCollisions = false
		
	end
	
end

local function updatePlayerBodyParts(player)
	local bodyDamage = player:getBodyDamage()
	
	playerBodyParts[player] = {
		bodyParts = {
			bodyDamage:getBodyPart(BodyPartType.Head),
			bodyDamage:getBodyPart(BodyPartType.Neck),
			bodyDamage:getBodyPart(BodyPartType.Torso_Upper),
			bodyDamage:getBodyPart(BodyPartType.Torso_Lower),
			bodyDamage:getBodyPart(BodyPartType.UpperArm_R),
			bodyDamage:getBodyPart(BodyPartType.ForeArm_R),
			bodyDamage:getBodyPart(BodyPartType.Hand_R),
			bodyDamage:getBodyPart(BodyPartType.UpperArm_L),
			bodyDamage:getBodyPart(BodyPartType.ForeArm_L),
			bodyDamage:getBodyPart(BodyPartType.Hand_L),
			bodyDamage:getBodyPart(BodyPartType.Groin),
			bodyDamage:getBodyPart(BodyPartType.UpperLeg_R),
			bodyDamage:getBodyPart(BodyPartType.LowerLeg_R),
			bodyDamage:getBodyPart(BodyPartType.Foot_R),
			bodyDamage:getBodyPart(BodyPartType.UpperLeg_L),
			bodyDamage:getBodyPart(BodyPartType.LowerLeg_L),
			bodyDamage:getBodyPart(BodyPartType.Foot_L)
		},
		bodyPartsByName = {
			head = bodyDamage:getBodyPart(BodyPartType.Head),
			neck = bodyDamage:getBodyPart(BodyPartType.Neck),
			upperTorso = bodyDamage:getBodyPart(BodyPartType.Torso_Upper),
			lowerTorso = bodyDamage:getBodyPart(BodyPartType.Torso_Lower),
			upperRightArm = bodyDamage:getBodyPart(BodyPartType.UpperArm_R),
			rightForearm = bodyDamage:getBodyPart(BodyPartType.ForeArm_R),
			rightHand = bodyDamage:getBodyPart(BodyPartType.Hand_R),
			upperLeftArm = bodyDamage:getBodyPart(BodyPartType.UpperArm_L),
			leftForearm = bodyDamage:getBodyPart(BodyPartType.ForeArm_L),
			leftHand = bodyDamage:getBodyPart(BodyPartType.Hand_L),
			groin = bodyDamage:getBodyPart(BodyPartType.Groin),
			upperRightLeg = bodyDamage:getBodyPart(BodyPartType.UpperLeg_R),
			lowerRightLeg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_R),
			rightFoot = bodyDamage:getBodyPart(BodyPartType.Foot_R),
			upperLeftLeg = bodyDamage:getBodyPart(BodyPartType.UpperLeg_L),
			lowerLeftLeg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_L),
			leftFoot = bodyDamage:getBodyPart(BodyPartType.Foot_L)
		}
		
	}
	
	PVIUtils.log(player:getFullName() .. " initialized: " .. tostring(playerBodyParts[player]))
	bodyPartCount = bodyPartCount + 1
	
end

local function removePlayerBodyParts(player)
	playerBodyParts[player] = nil
	bodyPartCount = bodyPartCount - 1
	
end


-----     COMMAND HANDLING     -----
local function onClientCommand(module, command, player, args)
	if module ~= "ProperVehicleInjuries" then
		return
	
	end
	-- Example of applying and syncing an injury:
	-- local leftHand = player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)
	-- leftHand:setScratched(true, true)
	-- leftHand:setScratchTime(10)
	
	-- local flags = java.lang.Long.sum(
		-- BodyPartSyncPacket.BD_scratched, BodyPartSyncPacket.BD_scratchTime
	-- )
	
	-- syncBodyPart(leftHand, flags)
	if command == "vehicleEntered" then
		startMonitoringPlayer(player)
		
	elseif command == "vehicleExited" then
		stopMonitoringPlayer(player)
		
	elseif command == "initPlayer" then
		PVIUtils.log("Initializing bodyPart tables for: " .. player:getFullName() .. "(" .. tostring(player) .. ")")
		updatePlayerBodyParts(player)
	
	elseif command == "playerDeath" then
		PVIUtils.log("Player " .. player:getFullName() .. " died, wiping from playerBodyParts and monitoredPlayers...")
		removePlayerBodyParts(player)
		stopMonitoringPlayer(player) -- Death from injuries may not invoke the OnExitVehicle event
	
	elseif command == "playerDisconnected" then
		PVIUtils.log("Player " .. player:getFullName() .. " has disconnected, wiping from playerBodyParts and monitoredPlayers...")
		removePlayerBodyParts(player)
		stopMonitoringPlayer(player)
		
		PVIUtils.log("Sanity: playerCount = " .. tostring(playerCount) .. ", bodyPartCount = " .. tostring(bodyPartCount))
	
	end

end


-----    INJURY HELPER FUNCTIONS     -----
-- getInjury() takes in the chances of each different injury, then rolls a random number
-- and checks if it is below the injuries probability. If the injury's chance is below the 
-- total probability, then the injury should occur.
local function getInjury(scratchChance, cutChance, deepWoundChance, deepGlassChance, fractureChance, fullLimbFractureChance)
    
	-- injuries put into table to iterate through
	local injuries = {
		scratch = scratchChance,
		cut = cutChance,
		deepWound = deepWoundChance,
		deepGlass = deepGlassChance,
		fracture = fractureChance,
		fullFracture = fullLimbFractureChance
	}

	local sumOfWeights = (scratchChance + cutChance + deepWoundChance + deepGlassChance + fractureChance + fullLimbFractureChance)
	
    local randomNum = ZombRand(1, sumOfWeights)
    
    -- Iterate through injuries, if the rolled number is below the total probability
	-- then return that injury
    local accumulatedProb = 0
    for injury, probability in pairs(injuries) do
        accumulatedProb = accumulatedProb + probability
        
        -- 
        if randomNum <= accumulatedProb then -- Check if injury is the one to happen
            return injury -- Return the selected injury
        end
    end
end

-- Rolls a random number and returns the name of a full limb for breaking
-- a full limb
local function getRandFullLimb()
	local randNum = ZombRand(1, 101)
	if randNum <= 25 then return "leftArm"
	elseif randNum <= 50 then return "rightArm"
	elseif randNum <= 75 then return "leftLeg"
	elseif randNum <= 100 then return "rightLeg" end
end

-- fractureFullLimb() does what it says, takes in the name of a full limb from
-- getRandFullLimb() and breaks all 3 corresponding body parts
local function fractureFullLimb(player, fullLimbName, injuryTime)
	
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_fractureTime)
	
	if fullLimbName == "leftArm" then
		playerBodyParts[player].bodyPartsByName.upperLeftArm:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.leftForearm:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.leftHand:setFractureTime(injuryTime)
		
		-- Sync the injury so the client sees it
		syncBodyPart(playerBodyParts[player].bodyPartsByName.upperLeftArm, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.leftForearm, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.leftHand, flags)

	elseif fullLimbName == "rightArm" then
		playerBodyParts[player].bodyPartsByName.upperRightArm:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.rightForearm:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.rightHand:setFractureTime(injuryTime)
		
		syncBodyPart(playerBodyParts[player].bodyPartsByName.upperRightArm, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.rightForearm, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.rightHand, flags)

	elseif fullLimbName == "leftLeg" then
		playerBodyParts[player].bodyPartsByName.upperLeftLeg:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.lowerLeftLeg:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.leftFoot:setFractureTime(injuryTime)
		
		syncBodyPart(playerBodyParts[player].bodyPartsByName.upperLeftLeg, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.lowerLeftLeg, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.leftFoot, flags)

	elseif fullLimbName == "rightLeg" then
		playerBodyParts[player].bodyPartsByName.upperRightLeg:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.lowerRightLeg:setFractureTime(injuryTime)
		playerBodyParts[player].bodyPartsByName.rightFoot:setFractureTime(injuryTime)
		
		syncBodyPart(playerBodyParts[player].bodyPartsByName.upperRightLeg, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.lowerRightLeg, flags)
		syncBodyPart(playerBodyParts[player].bodyPartsByName.rightFoot, flags)

	end
	
end

-- fractures the specified bone with its respective time
local function doFracture(boneToBreak, injuryTime)
	boneToBreak:setFractureTime(injuryTime)
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_fractureTime)
	syncBodyPart(boneToBreak, flags)
end

-- sets specified body part to be scratched with the respective injury time
local function doScratch(bodyPartToInjure, injuryTime)
	bodyPartToInjure:setScratched(true, true)
	bodyPartToInjure:setScratchTime(injuryTime)
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_scratched, BodyPartSyncPacket.BD_scratchTime, BodyPartSyncPacket.BD_bleeding, BodyPartSyncPacket.BD_bleedingTime)
	syncBodyPart(bodyPartToInjure, flags)
end

-- sets specified body part to be lacerated with respective injury time
local function doCut(bodyPartToInjure, injuryTime)
	bodyPartToInjure:setCut(true)
	bodyPartToInjure:setCutTime(injuryTime)
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_scratched,BodyPartSyncPacket.BD_scratchTime,BodyPartSyncPacket.BD_bleeding,BodyPartSyncPacket.BD_bleedingTime)
	syncBodyPart(bodyPartToInjure, flags)
end

-- sets the specified body part to have a deep wound plus a scratch
local function doDeepWound(bodyPartToInjure, injuryTime)
	bodyPartToInjure:generateDeepWound()
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_deepWounded,BodyPartSyncPacket.BD_deepWoundTime,BodyPartSyncPacket.BD_bleeding,BodyPartSyncPacket.BD_bleedingTime)
	syncBodyPart(bodyPartToInjure, flags)
end

-- sets the specified body part to have a deep wound with glass in it plus a laceration
local function doDeepGlass(bodyPartToInjure, injuryTime)
	bodyPartToInjure:generateDeepShardWound()
	
	local flags = PVIUtils.sumLongs(BodyPartSyncPacket.BD_deepWounded,BodyPartSyncPacket.BD_deepWoundTime,BodyPartSyncPacket.BD_haveGlass,BodyPartSyncPacket.BD_bleeding,BodyPartSyncPacket.BD_bleedingTime)
	syncBodyPart(bodyPartToInjure, flags)
end

-- Rolls a random number to determine if player should die
local function rollDeath(sevSpd, p)
	local chanceRolled = ZombRand(1, 101)
	if (chanceRolled <= sevSpd.deathChance) and (PVI.options.deathFromCrash) then 
		if p ~= nil then p:Kill(p) end
	end
end

-- Rolls a random number and checks if the player should be knocked out on collision
local function rollKnockout(p, sevSpd, seatbeltIsBuckled)
	if (p:isAlive()) and (PVI.options.knockoutsEnabled) then -- If player is alive and knockouts are enabled (only enabled initRealKnockoutCompatibility())	
		
		--Return early if seatbelts prevent knockouts AND seatbelt is buckled
		if (PVI.options.seatbeltPreventKnockout) and (seatbeltIsBuckled) then return end
		
		local chanceRolled = ZombRand(1, 101) -- get randon int
		
		--If the chance rolled is less than the knockoutChance for that severity table
		if (chanceRolled <= sevSpd.knockoutChance) then
			Knockout.setUnconscious(p) -- Knock the mf out
		end
	end
end

-- Master function that calls the above helper functions to handle injuries
local function handleInjury(player, bodyPartToInjure, injuryType, injuryTime)
	if injuryType == "scratch" then doScratch(bodyPartToInjure, injuryTime)
	elseif injuryType == "cut" then doCut(bodyPartToInjure, injuryTime)
	elseif injuryType == "deepWound" then doDeepWound(bodyPartToInjure, injuryTime)
	elseif injuryType == "deepGlass" then doDeepGlass(bodyPartToInjure, injuryTime)
	elseif injuryType == "fracture" then doFracture(bodyPartToInjure, injuryTime)
	elseif injuryType == "fullFracture" then fractureFullLimb(player, getRandFullLimb(), injuryTime) end
end

local function helmetWorn(player)
	local wornItems = player:getWornItems()
	
	for i=0, wornItems:size() - 1 do
		local item = wornItems:get(i):getItem()
		local itemName = getItemNameFromFullType(item:getFullType())
		
		-- Does clothing name contain 'helmet' and is it a FullHat clothing item?
		if (string.lower(itemName):find(string.lower("helmet"))) and (item:getBodyLocation() == "FullHat") then
			return "Full"
			
		-- Or is the item a helmet that doesn't cover the whole head?
		elseif ((string.lower(itemName):find(string.lower("helmet"))) and (item:getBodyLocation() == "Hat")) then
			return "Partial"
			
		end
	end
	
	return "None"
end

-- Returns "Both", "Seatbelt", or "None" depending on if airbags are enabled & installed, seatbelts
-- are buckled, or if neither are true. Used to calculate the damage reduction in doMultiInjury().
local function getDamageReductionType(player, vehicle, spdDiff, seatbeltIsBuckled)
	-- local p = getPlayer()
	-- local v = p:getVehicle()
	
	-- If the vehicle or player are nil, then immediately leave function
	-- if (p == nil) or (v == nil) then return "None" end
	
	if (PVI.options.airbagsEnabled) then
		local airbagPart = WorkingSeatbelt.getAirbagPart(v:getSeat(p), v) -- Get airbag part
		local airbagIsUninstalled = nil
		
		-- Check if airbag is valid
		if (airbagPart) then
			airbagIsUninstalled = airbagPart:isInventoryItemUninstalled() -- Get airbag uninstalled status
			
		end
		
		if (airbagPart) and (airbagIsUninstalled == false) and (seatbeltIsBuckled) and (spdDiff >= PVI.options.airbagMinimumCrashStrength) then -- Is the airbag valid, installed, and the seatbelt is buckled?
			return "Both"
		
		elseif (seatbeltIsBuckled) then -- Is just the seatbelt buckled?
			return "Seatbelt"
			
		elseif (airbagPart) and (airbagIsUninstalled == false) and (spdDiff >= PVI.options.airbagMinimumCrashStrength) then -- Is just the airbag valid and installed?
			return "Airbag"
			
		else
			return "None"
			
		end
	
	else
		if (seatbeltIsBuckled) then -- if seatbelt is buckled AND airbag module is disabled
			return "Seatbelt"
			
		else
			return "None"
			
		end
	end
end

-- Function handles calling handleInjury() with the injuries respective body part, injury type, and injury time. 
local function doMultiInjury(p, v, sevSpd, spdDiff, seatbeltIsBuckled)
	-- for loop iterates through the specified max injuries, and rolls if an injury should happen
	-- for each possible maxInjury	
	
	local pTraits = p:getCharacterTraits() -- get player traits
	
	------------------------------------- HANDLING AIRBAG
	local reductionType = getDamageReductionType(spdDiff, seatbeltIsBuckled)
	local damageReductionPercent = 0 -- Default damage and fracture values if no airbag or seatbelts are installed or worn
	local fractureReductionPercent = 0
	local airbagCondition = 1
	
	if (PVI.options.workingSeatbeltInstalled) then	
	
		--Get condition of airbag
		if (PVI.options.airbagsAffectedByCondition) and (WorkingSeatbelt.getAirbagPart(v:getSeat(p), v) ~= nil) then		
			airbagCondition = WorkingSeatbelt.getAirbagPart(v:getSeat(p), v):getCondition() / 100
		
		end
	
		-- Set reduction percentage
		if (reductionType == "Both") then
			WorkingSeatbelt.deployAirbag(p, v:getId(), v:getSeat(p)) -- Deploy the airbag
			damageReductionPercent = (PVI.options.seatbeltDamageReduction + (PVI.options.airbagDamageReduction * airbagCondition))
			fractureReductionPercent = (PVI.options.seatbeltFractureReduction + (PVI.options.airbagFractureReduction * airbagCondition))
		
		elseif (reductionType == "Seatbelt") then
			damageReductionPercent = PVI.options.seatbeltDamageReduction
			fractureReductionPercent = PVI.options.seatbeltFractureReduction
		
		elseif (reductionType == "Airbag") then
			WorkingSeatbelt.deployAirbag(p, v:getId(), v:getSeat(p)) -- Deploy the airbag
			damageReductionPercent = (PVI.options.airbagDamageReduction * airbagCondition)
			fractureReductionPercent = (PVI.options.airbagFractureReduction * airbagCondition)
			
		end
		
		-- Check if damage reduction and/or fracture reduction is higher than maximum
		if (damageReductionPercent >= PVI.options.maxDamageReduction) then damageReductionPercent = PVI.options.maxDamageReduction end
		if (fractureReductionPercent >= PVI.options.maxDamageReduction) then fractureReductionPercent = PVI.options.maxDamageReduction end
	end
	
	-- Invert reduction values for multiplication later. If damage reduction is 30%, then (1 - 0.3 = 0.7) 70% of the injury still applies
	damageReductionPercent = 1 - damageReductionPercent
	fractureReductionPercent = 1 - fractureReductionPercent
	
	------------------------------------- AIRBAG END
	
	-- Deal flat damage to player & sync the packet
	-- local flatDamage = spdDiff * PVI.options.flatDamagePercent * damageReductionPercent
	-- p:getBodyDamage():ReduceGeneralHealth(flatDamage)
	-- PVIUtils.log("General damage applied!")
	
	------------------------------------- EJECTION TEST START
	--See WorkingSeatbelt_DamageEvent.lua for additional ejection criteria
	--p:Say(string.format("%.2f", spdDiff) .. ", pDir= " .. tostring(p:getDir()) .. ", vDir: " .. tostring(v:getDir()))
	if (PVI.options.workingSeatbeltInstalled) and (PVI.options.ejectionsEnabled) then
		if (WorkingSeatbelt.shouldBeEjected(p, v, spdDiff)) then
			Events.OnTick.Add(WorkingSeatbelt.ejectPlayer)
		end
	end
	------------------------------------- EJECTION TEST END
	
	-- Main loop, iterate up to maxInjuries times, and for each one, calculate the injury type, time, and body location.
	for i=1, sevSpd.maxInjuries do
		if not p:isAlive() then return end -- Stop trying to apply injuries if player dies to their injuries
	
		local injureChance = ZombRand(1, 101)

		if injureChance <= sevSpd.injuryChance then
			local injuryType = getInjury(sevSpd.scratchChance, sevSpd.cutChance, sevSpd.deepWoundChance, sevSpd.deepGlassChance, sevSpd.fractureChance, sevSpd.fullLimbFractureChance)
			local bodyPartToInjure = playerBodyParts[p].bodyParts[ZombRand(1, 18)]

			local injuryTime = 10 -- Fallback injury duration
			if (injuryType == "scratch") or (injuryType == "deepWound") then injuryTime = ZombRand(sevSpd.scratchTimeMin, sevSpd.scratchTimeMax)
			elseif (injuryType == "cut") or (injuryType == "deepGlass") then injuryTime = ZombRand(sevSpd.cutTimeMin, sevSpd.cutTimeMax)
			elseif (injuryType == "fracture") or (injuryType == "fullFracture") then injuryTime = ZombRand(sevSpd.fractureTimeMin, sevSpd.fractureTimeMax) end
			
			-- Should traits be taken into account?
			if (PVI.options.traitsAffectInjuries) then
				if pTraits:get(CharacterTrait.SLOW_HEALER) then
					injuryTime = injuryTime * 1.3 -- Increase healing time by 30% if p has SlowHealer
				
				elseif pTraits:get(CharacterTrait.FAST_HEALER) then
					injuryTime = injuryTime * 0.7 -- Decrease healing time by 30% if p has FastHealer
					
				end
			end
			
			local helmetType = helmetWorn(p)
			--Check if a helmet is worn, head is being injured, and helmets give protection, then reduce injury time
			if (helmetType ~= "None") and (bodyPartToInjure == playerBodyParts[p].bodyPartsByName.head) and (PVI.options.helmetsGiveProtection) then
				if (helmetType == "Full") then injuryTime = injuryTime * (1 - PVI.options.fullHelmetModifier) -- FullHat should reduce the full amount
				elseif (helmetType == "Partial") then injuryTime = injuryTime * (1 - PVI.options.halfHelmetModifier) end -- While partial helmets should reduce by percentage of full, as specified in sandbox options
			
			-- If head not the target, then reduce the injury if WorkingSeatbelt is installed
			elseif (PVI.options.workingSeatbeltInstalled) then
				
				-- Reduce injury time for fractures
				if (injuryType == "fracture") or (injuryType == "fullFracture") then
					injuryTime = injuryTime * fractureReductionPercent
					
				-- Reduce injury time for all other injuries
				else
					injuryTime = injuryTime * damageReductionPercent
				
				end
			end
			
			-- If neither of the above are true, don't modify injury time and just pass in the injury time specified in sandbox options
			handleInjury(p, bodyPartToInjure, injuryType, injuryTime)
			
		end
	end
end

-- Returns severity table for collision based on the difference in speed pre/post collision.
local function getSeverityTable(spdDiff)
	if (spdDiff <= PVI.lowSpd.upperBound) then return PVI.lowSpd
	elseif (spdDiff <= PVI.medSpd.upperBound) then return PVI.medSpd
	elseif (spdDiff <= PVI.highSpd.upperBound) then return PVI.highSpd
	elseif (spdDiff > PVI.highSpd.upperBound) then return PVI.fatalSpd end
end

-- The bread and butter
-- checkCollision gets the player and the vehicle they're in, if the vehicle is an instance of BaseVehicle
-- then get it's speed and use that speed to calculate the difference between the vehicles current speed and the speed 
-- previously recorded by checkCollision. If the speed difference is higher than the minSpeedForInjury, then injuries 
-- are caused based on the difference
function checkCollision()
	for player, playerStats in pairs(monitoredPlayers) do
		local vehicle = player:getVehicle()
		
		if vehicle ~= nil then
			local vehicleSpeed = vehicle:getCurrentSpeedKmHour() * 1.7 -- Scaling speed to 120Mph dashboard
			local prevSpeed = playerStats.prevSpeed
			local spdDiff = math.abs((vehicleSpeed - playerStats.prevSpeed))
			local injuryLockout = monitoredPlayers[player].injuryLockout
			
			-- print("[PVI - Debug] " .. player:getFullName() .. " spd = " .. vehicleSpeed .. "km/h, spdDiff = " .. spdDiff)
			
			---------------- TRANSMISSION TEST START
			-- This is here to force PVI to update the vehicles direction while driving so that the vehicles direction
			-- is updated as the direction it's traveling changes. Without this, the vehicles direction remains static
			-- and causes windshield ejection from Working Seatbelts to only work in one direction.
			if (PVI.options.forceAlignVehicleDir) then
				local transmissionGear = vehicle:getTransmissionNumberLetter() -- Get vehicle gear

				if (transmissionGear ~= "R") then -- Force vehicle dir to match player if NOT in reverse
					vehicle:setDir(player:getDir())
				
				else
					vehicle:setDir(IsoDirections.valueOf(player:getDir():Rot180():name())) -- Otherwise force vehicle dir to the opposite of player
					
				end
			end
			-------------- TRANSMISSION TEST END

			-- Check if at the current speed is severe enough to cause an injury
			if (spdDiff >= PVI.options.threshold) and (prevSpeed > PVI.options.minSpeedForInjury) and (injuryLockout <= 0) then
				monitoredPlayers[player].injuryLockout = 40 -- Prevents checkCollision from tripping multiple times in one collision
				
				-- Get collision severity table
				local sevSpd = getSeverityTable(spdDiff)
				
				local seatbeltIsBuckled = false
				-- Working Seatbelt compatibility to be implemented & tested
				-- if (PVI.options.workingSeatbeltInstalled) then seatbeltIsBuckled = player:getModData().Seatbelt_sbStatus end
							
				-- Call core functions
				PVIUtils.log(player:getFullName() .. " was involved in a crash with spdDiff = " .. spdDiff)
				doMultiInjury(player, vehicle, sevSpd, spdDiff, seatbeltIsBuckled) -- Main injury handler
				rollDeath(sevSpd, player) -- Roll for death
				rollKnockout(player, sevSpd, seatbeltIsBuckled) -- Roll for knockout
				

			end

			-- sets prevSpeed to current speed to track the difference in speeds between checks
			monitoredPlayers[player].prevSpeed = vehicleSpeed
			monitoredPlayers[player].injuryLockout = monitoredPlayers[player].injuryLockout - 1
		
		end

	end
	
end

-----------     ALERTS     -------------
function detectNewPlayer(character, desc)
	if character:getClass():getName() ~= "zombie.characters.IsoPlayer" then return end
	
	PVIUtils.log("New player loaded in!")
	
	updatePlayerBodyParts(character)
	
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnCreateLivingCharacter.Add(detectNewPlayer)