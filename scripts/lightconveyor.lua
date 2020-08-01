function init(args)
	entity.setInteractive(false)
end

function main()
	if storage.init then
		pos = entity.position()
		if entity.direction() == 1 then
			entity.setForceRegion({pos[1], pos[2] + 1, pos[1] + storage.forceLength, entity.position()[2] + 1},
			storage.force)
		else
			entity.setForceRegion({pos[1] - storage.forceLength, pos[2] + 1, pos[1], entity.position()[2] + 1},
			storage.force)
		end
		world.logInfo(storage.force[1])
	else
		storage.forceLength = 0
		storage.force = 0
	end
	if world.material({entity.position()[1], entity.position()[2] - 1}, "foreground") ~= "energyblock" then
		entity.smash()
	end
end

function die()
	entity.smash()
end

function setForceLength(forceLength)
	storage.forceLength = forceLength
end

function setForce(force)
	storage.force = force
	storage.direction = entity.direction()
	storage.init = true
end
