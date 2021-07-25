local aoi = require "aoi"

local function callback(self, watcher, marker, op)
    local OBJ = self.objects
    print(string.format("%d (%d,%d) see %d (%d,%d) %s\n",
		watcher, OBJ[watcher].position[1], OBJ[watcher].position[2],
		marker, OBJ[marker].position[1], OBJ[marker].position[2],
        op
	))
end

local aoi_space = aoi.new(30, 25, 6, 5, callback)
local id = 1
local x = 2
local y = 2
aoi_space:enter(id, x, y)

local id = 2
local x = 15
local y = 20
aoi_space:enter(id, x, y)

local id = 3
local x = 10
local y = 5
aoi_space:enter(id, x, y)

x=5
y=5
aoi_space:move(id, x, y)

--local id = 4
--local x = 2
--local y = 2
--aoi_space:enter(id, x, y)
--
--aoi_space:leave(id, x, y)

