-- aoi: area of interest

local M = {}
local mt = { __index = M }

-- op: enter
-- op: leave
-- op: move
-- aoi_callback(self, watcher, marker, op)

local function init_grids(width, height, cntx, cnty)
    local grids = {}
    local cnt = cntx * cnty
    for i = 0, cnt - 1 do
        grids[i] = {}
    end
    return grids
end

function M.new(width, height, cntx, cnty, callback)
    local grids = init_grids(width, height, cntx, cnty)
    local dw = width // cntx
    local dh = height // cnty
    local aoi_space = {
        w = width,
        h = height,
        cntx = cntx,
        cnty = cnty,
        dw = dw,
        dh = dh,
        grids = grids,
        objects = {},
        cb = callback,
    }
    return setmetatable(aoi_space, mt)
end

function M.delete(self)
    setmetatable(self, nil)
end

-- 根据坐标计算格子id
local function calc_gid(dw, dh , cntx, cnty, x, y)
    local idx = x // dw
    local idy = y // dh
    local gid = idy * cntx + idx
    return gid
end

local grid9 = {
    {-1,-1}, {0,-1}, {1,-1},
    {-1,0},  {0,0},  {1,0},
    {-1,1},  {0,1},  {1,1},
}

-- 计算九宫格
local function calc9grid(cntx, cnty, gid)
    local idx = gid % cntx
    local idy = gid % cnty
    local grid_ids = {}
    for _, pos in pairs(grid9) do
        local diffx = pos[1]
        local diffy = pos[2]
        local nidx = idx + diffx
        local nidy = idy + diffy
        if (nidx >= 0 and nidx < cntx)
            and (nidy >= 0 and nidy < cnty) then
            local ngid = nidy * cntx + nidx
            grid_ids[ngid] = true
        end
    end
    return grid_ids
end

function M.enter(self, id, x, y)
    assert(not self.objects[id], "Object id already exist. id:" .. id)
    local object = {
        id = id,
        position = { x, y },
    }
    local gid = calc_gid(self.dw, self.dh, self.cntx, self.cnty, x, y)
    assert(self.grids[gid], "Grid not exist. gid:" .. gid)
    assert(not self.grids[gid][id], "Object id already in grid. id:" .. id)
    self.objects[id] = object
    self.grids[gid][id] = object
    local grid_ids = calc9grid(self.cntx, self.cnty, gid)
    for gid9, _ in pairs(grid_ids) do
        for oid, _ in pairs(self.grids[gid9]) do
            self:cb(oid, id, 'enter')
            if oid ~= id then
                self:cb(id, oid, 'enter')
            end
        end
    end
end

function M.leave(self, id)
    local object = self.objects[id]
    assert(self.objects[id], "Object id not exist. id:" .. id)
    local x = object.position[1]
    local y = object.position[2]
    local gid = calc_gid(self.dw, self.dh, self.cntx, self.cnty, x, y)
    assert(self.grids[gid], "Grid not exist. gid:" .. gid)
    assert(self.grids[gid][id], "Object id not in grid. id:" .. id)
    local grid_ids = calc9grid(self.cntx, self.cnty, gid)
    self.grids[gid][id] = nil
    for gid9, _ in pairs(grid_ids) do
        for oid, _ in pairs(self.grids[gid9]) do
            self:cb(oid, id, 'leave')
        end
    end
    self.objects[id] = nil
end

-- 计算交集
local function calc_intersection_set(set1, set2)
    local set = {}
    for k, _ in pairs(set1) do
        if set2[k] then
            set[k] = true
        end
    end
    return set
end

-- 计算差集
local function calc_difference_set(set1, set2)
    local set = {}
    for k, _ in pairs(set1) do
        if not set2[k] then
            set[k] = true
        end
    end
    return set
end

function M.move(self, id, x, y)
    local object = self.objects[id]
    assert(self.objects[id], "Object id not exist. id:" .. id)
    local ox = object.position[1]
    local oy = object.position[2]
    local ogid = calc_gid(self.dw, self.dh, self.cntx, self.cnty, ox, oy)
    assert(self.grids[ogid], "Grid not exist. gid:" .. ogid)
    assert(self.grids[ogid][id], "Object id not in grid. id:" .. id)
    local gid = calc_gid(self.dw, self.dh, self.cntx, self.cnty, x, y)
    assert(self.grids[gid], "Grid not exist. gid:" .. gid)
    if gid == ogid then
        local grid_ids = calc9grid(self.cntx, self.cnty, gid)
        for gid9, _ in pairs(grid_ids) do
            for oid, _ in pairs(self.grids[gid9]) do
                self:cb(oid, id, 'move')
            end
        end
    else
        local ogrid_ids = calc9grid(self.cntx, self.cnty, ogid)
        local grid_ids = calc9grid(self.cntx, self.cnty, gid)
       
        -- oldgrid - newgrid leave
        local oldgrid_newgrid = calc_difference_set(ogrid_ids, grid_ids)
        for gid9, _ in pairs(oldgrid_newgrid) do
            for oid, _ in pairs(self.grids[gid9]) do
                self:cb(oid, id, 'leave')
            end
        end
        
        -- newgrid - oldgrid enter
        local newgrid_oldgrid = calc_difference_set(grid_ids, ogrid_ids)
        for gid9, _ in pairs(newgrid_oldgrid) do
            for oid, _ in pairs(self.grids[gid9]) do
                self:cb(oid, id, 'enter')
            end
        end

        -- newgrid * oldgrid move
        local newgrid_x_oldgrid = calc_intersection_set(grid_ids, ogrid_ids)
        for gid9, _ in pairs(newgrid_x_oldgrid) do
            for oid, _ in pairs(self.grids[gid9]) do
                self:cb(oid, id, 'move')
            end
        end
    end
end

return M
