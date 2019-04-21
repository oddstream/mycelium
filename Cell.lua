-- Cell class

Cell = {
  -- prototype object
  grid = nil,      -- grid we belong to
  x = nil,        -- column 1 .. width
  y = nil,        -- row 1 .. height
  center = nil,   -- point table, screen coords
  edges = nil,    -- array of Edge objects
  hexagon = nil,     -- ShapeObject
}

function Cell:new(grid, x, y)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.grid = grid
  o.x = x
  o.y = y

  -- calculate where the screen coords center point will be
  -- odd-r horizontal layout shoves odd rows half a hexagon width to the right
  -- no '&'' operator in Lua 5.1, hence math.fmod(y,2) == 1

  o.center = {x=(x*grid.w) + (grid.w/2), y=(y * grid.h75) + (grid.h/2) - grid.h + 120}
  if math.fmod(y,2) == 1 then
    o.center.x = o.center.x + grid.w/2
  end

  o.edges = {}
  for dir = 1, 6 do
    o.edges[dir] = Edge:new(dir)
  end

  return o
end

function Cell:neighbour(dir)
  if dir == nil or dir == 0 then
    return self
  else
    return self.edges[dir].cell
  end
end

function Cell:id()
  return self.x .. ',' .. self.y
end

function Cell:neighbourId(dir)
  local d = {'NE','E','SE','SW','W','NW'}
  if self:neighbour(dir) then
    return d[dir] .. '=' .. self:neighbour(dir):id()
  else
    return d[dir] .. '=nil'
  end
end

function Cell:setNeighbour(dir, cell)
  assert(dir)
  assert(cell)
  assert(self)
  assert(self.edges)
  assert(self.edges[dir])
  self.edges[dir].cell = cell
end

function Cell:tap(event)
  -- implement table listener for tap events
  puck:setDestination(self)
end

function Cell:markHexagon()
  self.hexagon:setFillColor(0,0,0.3)
end

function Cell:unmarkHexagon()
  self.hexagon:setFillColor(0,0,0.2)
end

function Cell:createGraphics()

  local w = self.grid.w
  local h = self.grid.h

  -- "These coordinates will automatically be re-centered about the center of the polygon."
  local v = { -- vertices
    0,-(h/2),  -- N 1,2
    w/2,-(h/4), -- NE 3,4
    w/2,h/4,    -- SE 5,6
    0,h/2,    -- S 7,8
    -(w/2),h/4, -- SW 9,10
    -(w/2),-(h/4),  -- NW 11,12
  }
  self.hexagon = display.newPolygon(self.grid.mazeGroup, self.center.x, self.center.y, v)
  self.hexagon:setFillColor(0,0,0.2)
  self.hexagon:addEventListener('tap', self) -- table listener

  local lines = {
    {v[1],v[2], v[3],v[4]},
    {v[3],v[4], v[5],v[6]},
    {v[5],v[6], v[7],v[8]},
    {v[7],v[8], v[9],v[10]},
    {v[9],v[10], v[11],v[12]},
    {v[11],v[12], v[1],v[2]}
  }
  for dir = 1, 6 do
    local ed = self.edges[dir]
    local doLine = ed.wall

    for dir2 = 1, 3 do
      if dir == dir2 and self:neighbour(dir2) then
        doLine = false
      end
    end

    if doLine then
      local x1,y1,  x2,y2 = unpack(lines[dir])
      x1 = x1 + self.center.x
      y1 = y1 + self.center.y
      x2 = x2 + self.center.x
      y2 = y2 + self.center.y
      ed.line = display.newLine(self.grid.mazeGroup, x1, y1, x2, y2)
      ed.line.strokeWidth = 2
      ed.line:setStrokeColor(0,0,1)
    end
  end
end

function Cell:getNeighbours1()
  local arr = {}
  for dir = 1, 6 do
    if not self:isWall(dir) then
      table.insert(arr, self:neighbour(dir))
    end
  end
  return arr
end

function Cell:getNeighbours2()
  local arr1 = self:getNeighbours1()
  local arr2 = {}
  for _,t in ipairs(arr1) do
    for dir = 1, 6 do
      if not t:isWall(dir) then
        local n = t:neighbour(dir)
        if not table.contains(arr2, n) then
          table.insert(arr2, n)
        end
      end
    end
  end
  return arr2
end

--[[
function Cell:destroy()
  self.grid = nil
  -- self.edges = nil
  self.parent = nil
  -- for dir = 1, 6 do
  --   self.edges[dir]:destroy()
  -- end
  -- if self.rect then
  --   self.rect:removeSelf()
  --   self.rect = nil
  -- end
  if self.dot then
    self.dot:removeSelf()
    self.dot = nil
  end
end
]]

return Cell