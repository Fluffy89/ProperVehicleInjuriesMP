-- NOTES --
-- bodyPart:AddDamage(value) deals damage to the specified body part, where the body part has a health pool of 100
-- scratchTime is roughly 1 time unit every 1.07 hours (desired time in hours * 0.934 = time in game units)
-- cutTime is roughly 1 time unit every 2.94 hours (desired time in hours * 0.34 = time in game units)
-- fractureTime is roughly 1 time unit every 0.515 hours (desired time in hours * 1.943 = time in game units)

-- FOR IMPLEMENTING TRAITS AFFECTING INJURY TIMES --
-- getPlayer():getTraits():contains("traitName") - returns boolean, might be whether trait is there or not?
-- should be able to use get() and size() on it according to the javadoc

-- Sandbox option 'SandboxOptions.PlayerDamageFromCrash' might be the one to disable vanilla crash damage, found in SandboxOptions.class

-- GLOBAL CONSTANTS --
local ticks = 0
local interval = getSandboxOptions():getOptionByName("ProperVehicleInjuries.interval"):getValue() --20
local prevSpeed = 0
local injuryLockout = 40

-- GLOBAL BODYPART TABLES --
local bodyParts
local bodyPartsByName

-- SANDBOX OPTIONS HERE | DEFAULT VALUES SET HERE --
local threshold = 30
local minSpeedForInjury = 35

local options = {}

local lowSpd = {}
local medSpd = {}
local highSpd = {}
local fatalSpd = {}

if isServer() then return end

function modInstalled(ModID)
	return getActivatedMods():contains(ModID)
end

-- setBodyParts() sets the bodyParts/bodyPartsByName tables to contain the body parts
-- of the current character. This is called every time checkCollision would injure the character
-- and refreshes it to ensure the bodyParts are for the current character.
local function setBodyParts()
	local p = getPlayer()

	bodyParts = 
	{
		p:getBodyDamage():getBodyPart(BodyPartType.Head),
		p:getBodyDamage():getBodyPart(BodyPartType.Neck),
		p:getBodyDamage():getBodyPart(BodyPartType.Torso_Upper),
		p:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower),
		p:getBodyDamage():getBodyPart(BodyPartType.UpperArm_R),
		p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_R),
		p:getBodyDamage():getBodyPart(BodyPartType.Hand_R),
		p:getBodyDamage():getBodyPart(BodyPartType.UpperArm_L),
		p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L),
		p:getBodyDamage():getBodyPart(BodyPartType.Hand_L),
		p:getBodyDamage():getBodyPart(BodyPartType.Groin),
		p:getBodyDamage():getBodyPart(BodyPartType.UpperLeg_R),
		p:getBodyDamage():getBodyPart(BodyPartType.LowerLeg_R),
		p:getBodyDamage():getBodyPart(BodyPartType.Foot_R),
		p:getBodyDamage():getBodyPart(BodyPartType.UpperLeg_L),
		p:getBodyDamage():getBodyPart(BodyPartType.LowerLeg_L),
		p:getBodyDamage():getBodyPart(BodyPartType.Foot_L)
	}

	bodyPartsByName = 
	{
		head = p:getBodyDamage():getBodyPart(BodyPartType.Head),
		neck = p:getBodyDamage():getBodyPart(BodyPartType.Neck),
		upperTorso = p:getBodyDamage():getBodyPart(BodyPartType.Torso_Upper),
		lowerTorso = p:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower),
		upperRightArm = p:getBodyDamage():getBodyPart(BodyPartType.UpperArm_R),
		rightForearm = p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_R),
		rightHand = p:getBodyDamage():getBodyPart(BodyPartType.Hand_R),
		upperLeftArm = p:getBodyDamage():getBodyPart(BodyPartType.UpperArm_L),
		leftForearm = p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L),
		leftHand = p:getBodyDamage():getBodyPart(BodyPartType.Hand_L),
		groin = p:getBodyDamage():getBodyPart(BodyPartType.Groin),
		upperRightLeg = p:getBodyDamage():getBodyPart(BodyPartType.UpperLeg_R),
		lowerRightLeg = p:getBodyDamage():getBodyPart(BodyPartType.LowerLeg_R),
		rightFoot = p:getBodyDamage():getBodyPart(BodyPartType.Foot_R),
		upperLeftLeg = p:getBodyDamage():getBodyPart(BodyPartType.UpperLeg_L),
		lowerLeftLeg = p:getBodyDamage():getBodyPart(BodyPartType.LowerLeg_L),
		leftFoot = p:getBodyDamage():getBodyPart(BodyPartType.Foot_L)
	}
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
local function fractureFullLimb(fullLimbName, injuryTime)
	if fullLimbName == "leftArm" then
		bodyPartsByName.upperLeftArm:setFractureTime(injuryTime)
		bodyPartsByName.leftForearm:setFractureTime(injuryTime)
		bodyPartsByName.leftHand:setFractureTime(injuryTime)

	elseif fullLimbName == "rightArm" then
		bodyPartsByName.upperRightArm:setFractureTime(injuryTime)
		bodyPartsByName.rightForearm:setFractureTime(injuryTime)
		bodyPartsByName.rightHand:setFractureTime(injuryTime)

	elseif fullLimbName == "leftLeg" then
		bodyPartsByName.upperLeftLeg:setFractureTime(injuryTime)
		bodyPartsByName.lowerLeftLeg:setFractureTime(injuryTime)
		bodyPartsByName.leftFoot:setFractureTime(injuryTime)

	elseif fullLimbName == "rightLeg" then
		bodyPartsByName.upperRightLeg:setFractureTime(injuryTime)
		bodyPartsByName.lowerRightLeg:setFractureTime(injuryTime)
		bodyPartsByName.rightFoot:setFractureTime(injuryTime)

	end
end

-- fractures the specified bone with its respective time
local function doFracture(boneToBreak, injuryTime)
	boneToBreak:setFractureTime(injuryTime)
end

-- sets specified body part to be scratched with the respective injury time
local function doScratch(bodyPartToInjure, injuryTime)
	bodyPartToInjure:setScratched(true, true)
	bodyPartToInjure:setScratchTime(injuryTime)
end

-- sets specified body part to be lacerated with respective injury time
local function doCut(bodyPartToInjure, injuryTime)
	bodyPartToInjure:setCut(true)
	bodyPartToInjure:setCutTime(injuryTime)
end

-- sets the specified body part to have a deep wound plus a scratch
local function doDeepWound(bodyPartToInjure, injuryTime)
	bodyPartToInjure:generateDeepWound()
	bodyPartToInjure:setScratched(true, true)
	bodyPartToInjure:setScratchTime(injuryTime)
end

-- sets the specified body part to have a deep wound with glass in it plus a laceration
local function doDeepGlass(bodyPartToInjure, injuryTime)
	bodyPartToInjure:generateDeepShardWound()
	bodyPartToInjure:setCut(true)
	bodyPartToInjure:setCutTime(injuryTime)
end

-- Rolls a random number to determine if player should die
local function rollDeath(sevSpd, p)
	local chanceRolled = ZombRand(1, 101)
	if (chanceRolled <= sevSpd.deathChance) and (options.deathFromCrash) then 
		if p ~= nil then p:Kill(p) end
	end
end

-- Rolls a random number and checks if the player should be knocked out on collision
local function rollKnockout(p, sevSpd, seatbeltIsBuckled)
	if (p:isAlive()) and (options.knockoutsEnabled) then -- If player is alive and knockouts are enabled (only enabled initRealKnockoutCompatibility())	
		
		--Return early if seatbelts prevent knockouts AND seatbelt is buckled
		if (options.seatbeltPreventKnockout) and (seatbeltIsBuckled) then return end
		
		local chanceRolled = ZombRand(1, 101) -- get randon int
		
		--If the chance rolled is less than the knockoutChance for that severity table
		if (chanceRolled <= sevSpd.knockoutChance) then
			Knockout.setUnconscious(p) -- Knock the mf out
		end
	end
end

-- Master function that calls the above helper functions to handle injuries
local function handleInjury(bodyPartToInjure, injuryType, injuryTime)
	if injuryType == "scratch" then doScratch(bodyPartToInjure, injuryTime)
	elseif injuryType == "cut" then doCut(bodyPartToInjure, injuryTime)
	elseif injuryType == "deepWound" then doDeepWound(bodyPartToInjure, injuryTime)
	elseif injuryType == "deepGlass" then doDeepGlass(bodyPartToInjure, injuryTime)
	elseif injuryType == "fracture" then doFracture(bodyPartToInjure, injuryTime)
	elseif injuryType == "fullFracture" then fractureFullLimb(getRandFullLimb(), injuryTime) end
end

local function helmetWorn()
	local p = getPlayer()
	local wornItems = p:getWornItems()
	
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
local function getDamageReductionType(spdDiff, seatbeltIsBuckled)
	local p = getPlayer()
	local v = p:getVehicle()
	
	-- If the vehicle or player are nil, then immediately leave function
	if (p == nil) or (v == nil) then return "None" end
	
	if (options.airbagsEnabled) then
		local airbagPart = WorkingSeatbelt.getAirbagPart(v:getSeat(p), v) -- Get airbag part
		local airbagIsUninstalled = nil
		
		-- Check if airbag is valid
		if (airbagPart) then
			airbagIsUninstalled = airbagPart:isInventoryItemUninstalled() -- Get airbag uninstalled status
			
		end
		
		if (airbagPart) and (airbagIsUninstalled == false) and (seatbeltIsBuckled) and (spdDiff >= options.airbagMinimumCrashStrength) then -- Is the airbag valid, installed, and the seatbelt is buckled?
			return "Both"
		
		elseif (seatbeltIsBuckled) then -- Is just the seatbelt buckled?
			return "Seatbelt"
			
		elseif (airbagPart) and (airbagIsUninstalled == false) and (spdDiff >= options.airbagMinimumCrashStrength) then -- Is just the airbag valid and installed?
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
	
	if (options.workingSeatbeltInstalled) then	
	
		--Get condition of airbag
		if (options.airbagsAffectedByCondition) and (WorkingSeatbelt.getAirbagPart(v:getSeat(p), v) ~= nil) then		
			airbagCondition = WorkingSeatbelt.getAirbagPart(v:getSeat(p), v):getCondition() / 100
		
		end
	
		-- Set reduction percentage
		if (reductionType == "Both") then
			WorkingSeatbelt.deployAirbag(p, v:getId(), v:getSeat(p)) -- Deploy the airbag
			damageReductionPercent = (options.seatbeltDamageReduction + (options.airbagDamageReduction * airbagCondition))
			fractureReductionPercent = (options.seatbeltFractureReduction + (options.airbagFractureReduction * airbagCondition))
		
		elseif (reductionType == "Seatbelt") then
			damageReductionPercent = options.seatbeltDamageReduction
			fractureReductionPercent = options.seatbeltFractureReduction
		
		elseif (reductionType == "Airbag") then
			WorkingSeatbelt.deployAirbag(p, v:getId(), v:getSeat(p)) -- Deploy the airbag
			damageReductionPercent = (options.airbagDamageReduction * airbagCondition)
			fractureReductionPercent = (options.airbagFractureReduction * airbagCondition)
			
		end
		
		-- Check if damage reduction and/or fracture reduction is higher than maximum
		if (damageReductionPercent >= options.maxDamageReduction) then damageReductionPercent = options.maxDamageReduction end
		if (fractureReductionPercent >= options.maxDamageReduction) then fractureReductionPercent = options.maxDamageReduction end
	end
	
	-- Invert reduction values for multiplication later. If damage reduction is 30%, then (1 - 0.3 = 0.7) 70% of the injury still applies
	damageReductionPercent = 1 - damageReductionPercent
	fractureReductionPercent = 1 - fractureReductionPercent
	
	------------------------------------- AIRBAG END
	
	-- Deal flat damage to player
	local flatDamage = spdDiff * options.flatDamagePercent * damageReductionPercent
	p:getBodyDamage():ReduceGeneralHealth(flatDamage)
	
	------------------------------------- EJECTION TEST START
	--See WorkingSeatbelt_DamageEvent.lua for additional ejection criteria
	--p:Say(string.format("%.2f", spdDiff) .. ", pDir= " .. tostring(p:getDir()) .. ", vDir: " .. tostring(v:getDir()))
	if (options.workingSeatbeltInstalled) and (options.ejectionsEnabled) then
		if (WorkingSeatbelt.shouldBeEjected(p, v, spdDiff)) then
			Events.OnTick.Add(WorkingSeatbelt.ejectPlayer)
		end
	end
	------------------------------------- EJECTION TEST END
	
	-- Main loop, iterate up to maxInjuries times, and for each one, calculate the injury type, time, and body location.
	for i=1, sevSpd.maxInjuries do
		local injureChance = ZombRand(1, 101)

		if injureChance <= sevSpd.injuryChance then
			local injuryType = getInjury(sevSpd.scratchChance, sevSpd.cutChance, sevSpd.deepWoundChance, sevSpd.deepGlassChance, sevSpd.fractureChance, sevSpd.fullLimbFractureChance)
			local bodyPartToInjure = bodyParts[ZombRand(1, 18)]

			local injuryTime = 10 -- Fallback injury duration
			if (injuryType == "scratch") or (injuryType == "deepWound") then injuryTime = ZombRand(sevSpd.scratchTimeMin, sevSpd.scratchTimeMax)
			elseif (injuryType == "cut") or (injuryType == "deepGlass") then injuryTime = ZombRand(sevSpd.cutTimeMin, sevSpd.cutTimeMax)
			elseif (injuryType == "fracture") or (injuryType == "fullFracture") then injuryTime = ZombRand(sevSpd.fractureTimeMin, sevSpd.fractureTimeMax) end
			
			-- Should traits be taken into account?
			if (options.traitsAffectInjuries) then
				if pTraits:get(CharacterTrait.SLOW_HEALER) then
					injuryTime = injuryTime * 1.3 -- Increase healing time by 30% if p has SlowHealer
				
				elseif pTraits:get(CharacterTrait.FAST_HEALER) then
					injuryTime = injuryTime * 0.7 -- Decrease healing time by 30% if p has FastHealer
					
				end
			end
			
			local helmetType = helmetWorn()
			--Check if a helmet is worn, head is being injured, and helmets give protection, then reduce injury time
			if (helmetType ~= "None") and (bodyPartToInjure == bodyPartsByName.head) and (options.helmetsGiveProtection) then
				if (helmetWorn() == "Full") then injuryTime = injuryTime * (1 - options.fullHelmetModifier) -- FullHat should reduce the full amount
				elseif (helmetWorn() == "Partial") then injuryTime = injuryTime * (1 - options.halfHelmetModifier) end -- While partial helmets should reduce by percentage of full, as specified in sandbox options
			
			-- If head not the target, then reduce the injury if WorkingSeatbelt is installed
			elseif (options.workingSeatbeltInstalled) then
				
				-- Reduce injury time for fractures
				if (injuryType == "fracture") or (injuryType == "fullFracture") then
					injuryTime = injuryTime * fractureReductionPercent
					
				-- Reduce injury time for all other injuries
				else
					injuryTime = injuryTime * damageReductionPercent
				
				end
			end
			
			-- If neither of the above are true, don't modify injury time and just pass in the injury time specified in sandbox options
			handleInjury(bodyPartToInjure, injuryType, injuryTime)
		end
	end
end

-- Returns severity table for collision based on the difference in speed pre/post collision.
local function getSeverityTable(spdDiff)
	if (spdDiff <= lowSpd.upperBound) then return lowSpd
	elseif (spdDiff <= medSpd.upperBound) then return medSpd
	elseif (spdDiff <= highSpd.upperBound) then return highSpd
	elseif (spdDiff > highSpd.upperBound) then return fatalSpd end
end

-- The bread and butter
-- checkCollision gets the player and the vehicle they're in, if the vehicle is an instance of BaseVehicle
-- then get it's speed and use that speed to calculate the difference between the vehicles current speed and the speed 
-- previously recorded by checkCollision. If the speed difference is higher than the minSpeedForInjury, then injuries 
-- are caused based on the difference
local function checkCollision()
	local p = getPlayer()
	local v = p:getVehicle()
	
	-- ticks increases per tick, interval is a ratelimit for how often this is called
	if (ticks >= interval) and (v ~= nil) then
	
		local vehicleSpeed = v:getSpeed2D() * 3.6 -- Converting m/s to km/h
		local spdDiff = math.abs((vehicleSpeed - prevSpeed))
		
		---------------- TRANSMISSION TEST START
		-- This is here to force PVI to update the vehicles direction while driving so that the vehicles direction
		-- is updated as the direction it's traveling changes. Without this, the vehicles direction remains static
		-- and causes windshield ejection from Working Seatbelts to only work in one direction.
		if (options.forceAlignVehicleDir) then
			local transmissionGear = v:getTransmissionNumberLetter() -- Get vehicle gear
		
			if (transmissionGear ~= "R") then -- Force vehicle dir to match player if NOT in reverse
				v:setDir(p:getDir())
			
			else
				v:setDir(IsoDirections.reverse(p:getDir())) -- Otherwise force vehicle dir to the opposite of player
				
			end
		end
		---------------- TRANSMISSION TEST END
		
		-- Check if at the current speed is severe enough to cause an injury
		if (spdDiff >= threshold) and (prevSpeed > minSpeedForInjury) and (injuryLockout <= 0) then
			injuryLockout = 40 -- Prevents checkCollision from tripping multiple times in one collision
			setBodyParts() -- resets bodyParts tables to ensure they are for the current player object, there has to be a better way?
			
			-- Get collision severity table
			local sevSpd = getSeverityTable(spdDiff)
			
			local seatbeltIsBuckled = false
			if (options.workingSeatbeltInstalled) then seatbeltIsBuckled = p:getModData().Seatbelt_sbStatus end
			
			-- Call core functions
			doMultiInjury(p, v, sevSpd, spdDiff, seatbeltIsBuckled) -- Main injury handler
			rollDeath(sevSpd, p) -- Roll for death
			rollKnockout(p, sevSpd, seatbeltIsBuckled) -- Roll for knockout

		end

		-- sets prevSpeed to current speed to track the difference in speeds between checks
		prevSpeed = vehicleSpeed
		ticks = 0
		
	else 
		ticks = ticks + 1
		if injuryLockout > 0 then injuryLockout = injuryLockout - 1 end
	end
end

--Initialization
local function initRealKnockoutCompatibility(sBO)
	options.seatbeltPreventKnockout = sBO:getOptionByName("Knockout.seatbeltPreventKnockout"):getValue() -- True/False if players cannot be knocked out while wearing a seatbelt
	options.knockoutsEnabled = sBO:getOptionByName("ProperVehicleInjuries.knockoutsEnabled"):getValue() -- True/False whether knockouts are enabled or not
	
	print("PVI x Real Knockout Compatibility Initialized!")
end

local function initWorkingSeatbeltCompatibility(sBO)
	options.workingSeatbeltInstalled = true
	options.seatbeltDamageReduction = sBO:getOptionByName("workingSeatbelt.seatbeltDamageReduction"):getValue() / 100
	options.seatbeltFractureReduction = sBO:getOptionByName("workingSeatbelt.seatbeltFractureReduction"):getValue() / 100
	
	options.airbagsEnabled = sBO:getOptionByName("workingSeatbelt.airbagModule"):getValue()
	options.airbagsAffectedByCondition = sBO:getOptionByName("workingSeatbelt.airbagsAffectedByCondition"):getValue()
	options.airbagMinimumCrashStrength = sBO:getOptionByName("workingSeatbelt.airbagMinimumCrashStrength"):getValue()
	options.airbagDamageReduction = sBO:getOptionByName("workingSeatbelt.airbagDamageReduction"):getValue() / 100
	options.airbagFractureReduction = sBO:getOptionByName("workingSeatbelt.airbagFractureReduction"):getValue() / 100
	
	options.ejectionsEnabled = sBO:getOptionByName("workingSeatbelt.canPlayerBeEjected"):getValue()
	
	print("PVI x Working Seatbelts Compatibility Initialized!")
end

local function initMod()
	local sBO = getSandboxOptions()
	
	-- Should vanilla crash damage be forced to false?
	if (sBO:getOptionByName("ProperVehicleInjuries.disableVanillaCrashDamage"):getValue() == true) then
		sBO:set("PlayerDamageFromCrash", false)
		
	end
	
	interval = sBO:getOptionByName("ProperVehicleInjuries.interval"):getValue()
	threshold = sBO:getOptionByName("ProperVehicleInjuries.threshold"):getValue()
	minSpeedForInjury = sBO:getOptionByName("ProperVehicleInjuries.minSpeedForInjury"):getValue()
	options.flatDamagePercent = sBO:getOptionByName("ProperVehicleInjuries.flatDamagePercent"):getValue() / 100
	options.maxDamageReduction = sBO:getOptionByName("ProperVehicleInjuries.maxDamageReduction"):getValue() / 100
	options.deathFromCrash = sBO:getOptionByName("ProperVehicleInjuries.deathFromCrash"):getValue()
	
	options.traitsAffectInjuries = sBO:getOptionByName("ProperVehicleInjuries.traitsAffectInjuries"):getValue()
	
	options.helmetsGiveProtection = sBO:getOptionByName("ProperVehicleInjuries.helmetsGiveProtection"):getValue()
	options.fullHelmetModifier = sBO:getOptionByName("ProperVehicleInjuries.fullHelmetModifier"):getValue() / 100
	options.halfHelmetModifier = sBO:getOptionByName("ProperVehicleInjuries.halfHelmetModifier"):getValue() / 100
	
	options.forceAlignVehicleDir = sBO:getOptionByName("ProperVehicleInjuries.forceAlignVehicleDir"):getValue()
	
	
	-- scratchTime is roughly 1 time unit every 1.07 hours (desired time in hours * 0.934 = time in game units)
	-- cutTime is roughly 1 time unit every 2.94 hours (desired time in hours * 0.34 = time in game units)
	-- fractureTime is roughly 1 time unit every 0.515 hours (desired time in hours * 1.943 = time in game units)
	
	-- Low speed collision sandbox settings
	lowSpd = {
		upperBound = sBO:getOptionByName("ProperVehicleInjuries.lowupperBound"):getValue(),
		scratchTimeMin = sBO:getOptionByName("ProperVehicleInjuries.lowscratchTimeMin"):getValue() * 0.934,
		scratchTimeMax = sBO:getOptionByName("ProperVehicleInjuries.lowscratchTimeMax"):getValue() * 0.934,
		cutTimeMin = sBO:getOptionByName("ProperVehicleInjuries.lowcutTimeMin"):getValue() * 0.34,
		cutTimeMax = sBO:getOptionByName("ProperVehicleInjuries.lowcutTimeMax"):getValue() * 0.34,
		fractureTimeMin = sBO:getOptionByName("ProperVehicleInjuries.lowfractureTimeMin"):getValue() * 1.943,
		fractureTimeMax = sBO:getOptionByName("ProperVehicleInjuries.lowfractureTimeMax"):getValue() * 1.943,
		injuryChance = sBO:getOptionByName("ProperVehicleInjuries.lowinjuryChance"):getValue(),
		maxInjuries = sBO:getOptionByName("ProperVehicleInjuries.lowmaxInjuries"):getValue(),
		scratchChance = sBO:getOptionByName("ProperVehicleInjuries.lowscratchChance"):getValue(),
		cutChance = sBO:getOptionByName("ProperVehicleInjuries.lowcutChance"):getValue(),
		deepWoundChance = sBO:getOptionByName("ProperVehicleInjuries.lowdeepWoundChance"):getValue(),
		deepGlassChance = sBO:getOptionByName("ProperVehicleInjuries.lowdeepGlassChance"):getValue(),
		fractureChance = sBO:getOptionByName("ProperVehicleInjuries.lowfractureChance"):getValue(),
		fullLimbFractureChance = sBO:getOptionByName("ProperVehicleInjuries.lowfullFractureChance"):getValue(),
		deathChance = sBO:getOptionByName("ProperVehicleInjuries.lowdeathChance"):getValue(),
		knockoutChance = sBO:getOptionByName("ProperVehicleInjuries.lowknockoutChance"):getValue()
	}

	-- Med speed collision sandbox settings
	medSpd = {
		upperBound = sBO:getOptionByName("ProperVehicleInjuries.medupperBound"):getValue(),
		scratchTimeMin = sBO:getOptionByName("ProperVehicleInjuries.medscratchTimeMin"):getValue() * 0.934,
		scratchTimeMax = sBO:getOptionByName("ProperVehicleInjuries.medscratchTimeMax"):getValue() * 0.934,
		cutTimeMin = sBO:getOptionByName("ProperVehicleInjuries.medcutTimeMin"):getValue() * 0.34,
		cutTimeMax = sBO:getOptionByName("ProperVehicleInjuries.medcutTimeMax"):getValue() * 0.34,
		fractureTimeMin = sBO:getOptionByName("ProperVehicleInjuries.medfractureTimeMin"):getValue() * 1.943,
		fractureTimeMax = sBO:getOptionByName("ProperVehicleInjuries.medfractureTimeMax"):getValue() * 1.943,
		injuryChance = sBO:getOptionByName("ProperVehicleInjuries.medinjuryChance"):getValue(),
		maxInjuries = sBO:getOptionByName("ProperVehicleInjuries.medmaxInjuries"):getValue(),
		scratchChance = sBO:getOptionByName("ProperVehicleInjuries.medscratchChance"):getValue(),
		cutChance = sBO:getOptionByName("ProperVehicleInjuries.medcutChance"):getValue(),
		deepWoundChance = sBO:getOptionByName("ProperVehicleInjuries.meddeepWoundChance"):getValue(),
		deepGlassChance = sBO:getOptionByName("ProperVehicleInjuries.meddeepGlassChance"):getValue(),
		fractureChance = sBO:getOptionByName("ProperVehicleInjuries.medfractureChance"):getValue(),
		fullLimbFractureChance = sBO:getOptionByName("ProperVehicleInjuries.medfullFractureChance"):getValue(),
		deathChance = sBO:getOptionByName("ProperVehicleInjuries.meddeathChance"):getValue(),
		knockoutChance = sBO:getOptionByName("ProperVehicleInjuries.medknockoutChance"):getValue()
	}

	-- High speed collision sandbox settings
	highSpd = {
		upperBound = sBO:getOptionByName("ProperVehicleInjuries.highupperBound"):getValue(),
		scratchTimeMin = sBO:getOptionByName("ProperVehicleInjuries.highscratchTimeMin"):getValue() * 0.934,
		scratchTimeMax = sBO:getOptionByName("ProperVehicleInjuries.highscratchTimeMax"):getValue() * 0.934,
		cutTimeMin = sBO:getOptionByName("ProperVehicleInjuries.highcutTimeMin"):getValue() * 0.34,
		cutTimeMax = sBO:getOptionByName("ProperVehicleInjuries.highcutTimeMax"):getValue() * 0.34,
		fractureTimeMin = sBO:getOptionByName("ProperVehicleInjuries.highfractureTimeMin"):getValue() * 1.943,
		fractureTimeMax = sBO:getOptionByName("ProperVehicleInjuries.highfractureTimeMax"):getValue() * 1.943,
		injuryChance = sBO:getOptionByName("ProperVehicleInjuries.highinjuryChance"):getValue(),
		maxInjuries = sBO:getOptionByName("ProperVehicleInjuries.highmaxInjuries"):getValue(),
		scratchChance = sBO:getOptionByName("ProperVehicleInjuries.highscratchChance"):getValue(),
		cutChance = sBO:getOptionByName("ProperVehicleInjuries.highcutChance"):getValue(),
		deepWoundChance = sBO:getOptionByName("ProperVehicleInjuries.highdeepWoundChance"):getValue(),
		deepGlassChance = sBO:getOptionByName("ProperVehicleInjuries.highdeepGlassChance"):getValue(),
		fractureChance = sBO:getOptionByName("ProperVehicleInjuries.highfractureChance"):getValue(),
		fullLimbFractureChance = sBO:getOptionByName("ProperVehicleInjuries.highfullFractureChance"):getValue(),
		deathChance = sBO:getOptionByName("ProperVehicleInjuries.highdeathChance"):getValue(),
		knockoutChance = sBO:getOptionByName("ProperVehicleInjuries.highknockoutChance"):getValue()
	}

	-- Fatal speed collision sandbox settings - Keep in mind that the lower bound for Fatal severity is > highSpd.upperBound
	fatalSpd = {
		scratchTimeMin = sBO:getOptionByName("ProperVehicleInjuries.fatalscratchTimeMin"):getValue() * 0.934,
		scratchTimeMax = sBO:getOptionByName("ProperVehicleInjuries.fatalscratchTimeMax"):getValue() * 0.934,
		cutTimeMin = sBO:getOptionByName("ProperVehicleInjuries.fatalcutTimeMin"):getValue() * 0.34,
		cutTimeMax = sBO:getOptionByName("ProperVehicleInjuries.fatalcutTimeMax"):getValue() * 0.34,
		fractureTimeMin = sBO:getOptionByName("ProperVehicleInjuries.fatalfractureTimeMin"):getValue() * 1.943,
		fractureTimeMax = sBO:getOptionByName("ProperVehicleInjuries.fatalfractureTimeMax"):getValue() * 1.943,
		injuryChance = sBO:getOptionByName("ProperVehicleInjuries.fatalinjuryChance"):getValue(),
		maxInjuries = sBO:getOptionByName("ProperVehicleInjuries.fatalmaxInjuries"):getValue(),
		scratchChance = sBO:getOptionByName("ProperVehicleInjuries.fatalscratchChance"):getValue(),
		cutChance = sBO:getOptionByName("ProperVehicleInjuries.fatalcutChance"):getValue(),
		deepWoundChance = sBO:getOptionByName("ProperVehicleInjuries.fataldeepWoundChance"):getValue(),
		deepGlassChance = sBO:getOptionByName("ProperVehicleInjuries.fataldeepGlassChance"):getValue(),
		fractureChance = sBO:getOptionByName("ProperVehicleInjuries.fatalfractureChance"):getValue(),
		fullLimbFractureChance = sBO:getOptionByName("ProperVehicleInjuries.fatalfullFractureChance"):getValue(),
		deathChance = sBO:getOptionByName("ProperVehicleInjuries.fataldeathChance"):getValue(),
		knockoutChance = sBO:getOptionByName("ProperVehicleInjuries.fatalknockoutChance"):getValue()
	}


	setBodyParts()
	Events.OnTick.Add(checkCollision)
	print("ProperVehicleInjuriesMP Core Initialized!")
	
	if modInstalled("WorkingSeatbelt") then initWorkingSeatbeltCompatibility(sBO) end
	if modInstalled("RealKnockouts") then initRealKnockoutCompatibility(sBO) end
end

Events.OnGameStart.Add(initMod)
print("Initializing ProperVehicleInjuriesMP...")