PVIUtils = {}

PVIUtils.log = function (msg)
	print("[PVI Util] " .. msg)

end

PVIUtils.modInstalled = function (ModID)
	return getActivatedMods():contains(ModID)
	
end