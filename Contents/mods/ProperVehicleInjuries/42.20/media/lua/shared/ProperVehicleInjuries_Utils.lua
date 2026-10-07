PVIUtils = {}

PVIUtils.log = function (msg)
	print("[PVI Util] " .. msg)

end

PVIUtils.modInstalled = function (ModID)
	return getActivatedMods():contains(ModID)
	
end

-- Takes in a variable length array of java.Long objects and sums them.
-- Used to avoid chaining a billion java.lang.Long.sum()'s together
-- because that would look awful when syncing injury packets.
PVIUtils.sumLongs = function (...)
	local sum = 0
	
	for i = 1, select("#", ...) do
		local value = select(i, ...):longValue()
		sum = java.lang.Long.sum(sum, value)
		
	end
	
	return sum

end

PVIUtils.modInstalled = function (ModID)
	return getActivatedMods():contains(ModID)
end


return PVIUtils