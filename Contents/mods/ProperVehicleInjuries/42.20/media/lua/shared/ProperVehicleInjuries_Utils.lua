PVIUtils = {}

PVIUtils.log = function (msg)
	print("[PVI Util] " .. msg)

end

PVIUtils.modInstalled = function (ModID)
	return getActivatedMods():contains(ModID)
	
end

PVIUtils.sumLongs = function (...)
	local sum = 0
	
	for i = 1, select("#", ...) do
		local value = select(i, ...):longValue()
		sum = java.lang.Long.sum(sum, value)
		
	end
	
	return sum

end