function init(args)
	entity.setInteractive(true)
end

function main()
	if not storage.initialized then
		if entity.direction() > 0 then storage.direction = 0 else storage.direction = -1 end
		if storage.bridgeLength == nil then storage.bridgeLength = 0 else storage.bridgeLength = storage.bridgeLength end
		storage.bridgeStart = {entity.position()[1] + storage.direction, entity.position()[2] - 1}
		storage.range = entity.configParameter("range", 20)
		storage.modsEnabled = true
		storage.rangeMods = 0
		storage.active = false
		storage.initialized = true
	end

	if storage.conveyorMods == nil then
		storage.force = entity.configParameter("conveyorForce", 50)
		storage.conveyorMods = 0
		storage.regionLength = 59.5
		storage.mobCount = 0
		storage.conveyorIds = {}
	end

	if storage.modsEnabled then
		updateMods()
	else
		storage.rangeMods = 0
		storage.conveyorMods = 0
	end

	if storage.bridgeLength < totalRange() and storage.active then
		placeBridge(storage.bridgeLength + 1, totalRange())
	elseif storage.bridgeLength > totalRange() and storage.active then
		destroyBridge(totalRange() + 1, storage.bridgeLength)
	end

end

function die()
	destroyBridge(1, storage.bridgeLength)
end

function onInboundNodeChange(args)
	if not args.level then
		storage.active = false
		entity.setAnimationState("switchState", "off")
		entity.playSound("offSounds")
		destroyBridge(1, storage.bridgeLength)
	else
		storage.active = true
		entity.setAnimationState("switchState", "on")
		entity.playSound("onSounds")
		placeBridge(1, totalRange())
	end
end

function onInteraction(args)
	if storage.active then
		storage.active = false
		entity.setAnimationState("switchState", "off")
		entity.playSound("offSounds")
		destroyBridge(1, storage.bridgeLength)
	else
		storage.active = true
		entity.setAnimationState("switchState", "on")
		entity.playSound("onSounds")
		placeBridge(1, totalRange())
	end
end

function placeBridge(start, range)

	local starting = start
	for position = starting, range do
		if world.placeMaterial(getPosition(position), "foreground", "energyblock") then
			storage.bridgeLength = storage.bridgeLength + 1
		else
			break
		end
	end

	local newRegions = storage.bridgeLength / storage.regionLength
	local addPoint = storage.mobCount
	local newMobs = storage.mobCount
	if newRegions > storage.mobCount then
		for position = storage.mobCount, newRegions + (newRegions - storage.mobCount) do
			local pos = {entity.position()[1] + (entity.direction()*position*storage.regionLength + (2*entity.direction())),
			entity.position()[2]}
			toDestroy = {}
			toDestroy[1] = pos
			toDestroy[2] = { pos[1] - 1, pos[2] }
			toDestroy[3] = { pos[1], pos[2] + 1 }
			toDestroy[4] = { pos[1] - 1, pos[2] + 1 }
			world.damageTiles(toDestroy, "foreground",  entity.position(), "blockish", 100000)
			world.placeObject("lightconveyor", pos, entity.direction())
			local toInsert = world.objectLineQuery(pos, pos)[1]
			if toInsert ~= nil then
				table.insert(storage.conveyorIds, toInsert)
				newMobs = newMobs + 1
			end
		end
	end
	storage.mobCount = newMobs
end

function destroyBridge(start, range)
	local removeTil = range
	for position = start, removeTil do
		if world.material(getPosition(position), "foreground") == "energyblock" then
			world.damageTiles({getPosition(position)}, "foreground",  entity.position(), "crushing", 100000)
			storage.bridgeLength = storage.bridgeLength - 1
		else
			break
		end
	end

	local newConveyors = storage.bridgeLength / storage.regionLength
	local split = splitArray(storage.conveyorIds, newConveyors, storage.mobCount)
	storage.conveyorIds = split[1]
	storage.mobCount = newConveyors
end

function updateMods()
	storage.rangeMods = 0
	storage.conveyorMods = 0
	for xPosition = 1, 4 do
		for yPosition = 0, 3 do
			local modBlock = world.material({entity.position()[1] + -entity.direction() +
			(xPosition*-entity.direction()), entity.position()[2] + yPosition}, "background")
			if modBlock == "rangemod" then storage.rangeMods = storage.rangeMods + 1 elseif
			modBlock == "conveyormod" then storage.conveyorMods = storage.conveyorMods + 1 end
		end
	end
	local lastRegion = storage.bridgeLength - storage.regionLength*(storage.mobCount - 1)
	for position = 1, storage.mobCount do
		if position < storage.mobCount then
			world.callScriptedEntity(storage.conveyorIds[position], "setForceLength", storage.regionLength)
			world.callScriptedEntity(storage.conveyorIds[position], "setForce", {entity.direction()*storage.force*storage.conveyorMods, 0})
		else
			world.callScriptedEntity(storage.conveyorIds[position], "setForceLength", lastRegion)
			world.callScriptedEntity(storage.conveyorIds[position], "setForce", {entity.direction()*storage.force*storage.conveyorMods, 0})
		end
	end
end

function splitArray(arg, indexToSplit, length)
	local newTable1 = { }
	local newTable2 = { }
	for position = 1, indexToSplit do
		newTable1[position] = arg[position]
	end
	for position = indexToSplit + 1, length do
		newTable2[position] = arg[position]
	end
	return { newTable1, newTable2 }
end

function getPosition(position)
	return {entity.position()[1] + storage.direction + (entity.direction()*position), entity.position()[2] - 1}
end

function regionStart(count, regionLength)
	return storage.bridgeStart[1] + (count - 1)*regionLength
end

function totalRange()
	return storage.range + (storage.rangeMods*20)
end
