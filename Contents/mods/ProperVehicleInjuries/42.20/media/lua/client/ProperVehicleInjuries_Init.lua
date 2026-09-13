PVI = {}


----- Lists to init -----
PVI.options = {}
PVI.lowSpd = {}
PVI.medSpd = {}
PVI.highSpd = {}
PVI.fatalSpd = {}
PVI.bodyParts = {}
PVI.bodyPartsByName = {}
-------------------------


-------------- Get Functions --------------
PVI.getOptions = function()
	return PVI.options
	
end

PVI.getLowSpeedTable = function()
	return PVI.lowSpd

end

PVI.getMedSpeedTable = function()
	return PVI.medSpd

end

PVI.getHighSpeedTable = function()
	return PVI.highSpd

end

PVI.getFatalSpeedTable = function()
	return PVI.fatalSpd

end
-------------------------------------------


-------------- Initialization --------------
local function initRealKnockoutCompatibility(sBO)
	PVI.options.seatbeltPreventKnockout = sBO:getOptionByName("Knockout.seatbeltPreventKnockout"):getValue() -- True/False if players cannot be knocked out while wearing a seatbelt
	PVI.options.knockoutsEnabled = sBO:getOptionByName("ProperVehicleInjuries.knockoutsEnabled"):getValue() -- True/False whether knockouts are enabled or not
	
	print("PVI x Real Knockout Compatibility Initialized!")
end

local function initWorkingSeatbeltCompatibility(sBO)
	PVI.options.workingSeatbeltInstalled = true
	PVI.options.seatbeltDamageReduction = sBO:getOptionByName("workingSeatbelt.seatbeltDamageReduction"):getValue() / 100
	PVI.options.seatbeltFractureReduction = sBO:getOptionByName("workingSeatbelt.seatbeltFractureReduction"):getValue() / 100
	
	PVI.options.airbagsEnabled = sBO:getOptionByName("workingSeatbelt.airbagModule"):getValue()
	PVI.options.airbagsAffectedByCondition = sBO:getOptionByName("workingSeatbelt.airbagsAffectedByCondition"):getValue()
	PVI.options.airbagMinimumCrashStrength = sBO:getOptionByName("workingSeatbelt.airbagMinimumCrashStrength"):getValue()
	PVI.options.airbagDamageReduction = sBO:getOptionByName("workingSeatbelt.airbagDamageReduction"):getValue() / 100
	PVI.options.airbagFractureReduction = sBO:getOptionByName("workingSeatbelt.airbagFractureReduction"):getValue() / 100
	
	PVI.options.ejectionsEnabled = sBO:getOptionByName("workingSeatbelt.canPlayerBeEjected"):getValue()
	
	print("PVI x Working Seatbelts Compatibility Initialized!")
end

local function initMod ()
	local sBO = getSandboxOptions()
	
	-- Should vanilla crash damage be forced to false?
	if (sBO:getOptionByName("ProperVehicleInjuries.disableVanillaCrashDamage"):getValue() == true) then
		sBO:set("PlayerDamageFromCrash", false)
		
	end
	
	PVI.options.interval = sBO:getOptionByName("ProperVehicleInjuries.interval"):getValue()
	PVI.options.threshold = sBO:getOptionByName("ProperVehicleInjuries.threshold"):getValue()
	PVI.options.minSpeedForInjury = sBO:getOptionByName("ProperVehicleInjuries.minSpeedForInjury"):getValue()
	PVI.options.flatDamagePercent = sBO:getOptionByName("ProperVehicleInjuries.flatDamagePercent"):getValue() / 100
	PVI.options.maxDamageReduction = sBO:getOptionByName("ProperVehicleInjuries.maxDamageReduction"):getValue() / 100
	PVI.options.deathFromCrash = sBO:getOptionByName("ProperVehicleInjuries.deathFromCrash"):getValue()
	
	PVI.options.traitsAffectInjuries = sBO:getOptionByName("ProperVehicleInjuries.traitsAffectInjuries"):getValue()
	
	PVI.options.helmetsGiveProtection = sBO:getOptionByName("ProperVehicleInjuries.helmetsGiveProtection"):getValue()
	PVI.options.fullHelmetModifier = sBO:getOptionByName("ProperVehicleInjuries.fullHelmetModifier"):getValue() / 100
	PVI.options.halfHelmetModifier = sBO:getOptionByName("ProperVehicleInjuries.halfHelmetModifier"):getValue() / 100
	
	PVI.options.forceAlignVehicleDir = sBO:getOptionByName("ProperVehicleInjuries.forceAlignVehicleDir"):getValue()
	
	
	-- scratchTime is roughly 1 time unit every 1.07 hours (desired time in hours * 0.934 = time in game units)
	-- cutTime is roughly 1 time unit every 2.94 hours (desired time in hours * 0.34 = time in game units)
	-- fractureTime is roughly 1 time unit every 0.515 hours (desired time in hours * 1.943 = time in game units)
	
	-- Low speed collision sandbox settings
	PVI.lowSpd = {
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
	PVI.medSpd = {
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
	PVI.highSpd = {
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
	PVI.fatalSpd = {
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
	
	
	local p = getPlayer()
	PVI.bodyParts = {
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

	PVI.bodyPartsByName = {
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
	
	print("PVI Core Initialized!")

end

---------------------------------------------

print("Initializing ProperVehicleInjuriesMP...")
Events.OnGameStart.Add(initMod)