-- Grid (of cells) class

Grid = {
  -- prototype object
  mazeGroup = nil,
  dotGroup = nil,
  actorGroup = nil,
  bubbleGroup = nil,
  cells = nil,
  width = nil,      -- number of columns
  height = nil,      -- number of rows
  w = nil,          -- width of a cell
  h = nil,          -- height of a cell
}

function Grid:new(mazeGroup, dotGroup, actorGroup, bubbleGroup, width, height)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.mazeGroup = mazeGroup
  o.dotGroup = dotGroup
  o.actorGroup = actorGroup
  o.bubbleGroup = bubbleGroup

  o.cells = {}
  o.width = width
  o.height = height

  o.w = math.floor(math.sqrt(3) * Q)
  o.h = 2 * Q
  o.h75 = math.floor(o.h * 0.75)
  print('w h h75', o.w, o.h, o.h75)

  for y = 1, height do
    for x = 1, width do
      local c = Cell:new(o, x, y)
      table.insert(o.cells, c) -- push
    end
  end

  return o
end

function Grid:reset()
  self:iterator(function(t)
    t:reset()
    t:addDot()
  end)
end

function Grid:linkCells()
  for _,c in ipairs(self.cells) do
    local fc -- found cell
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x - self.width) and (c.center.y == d.center.y) end)
    if fc then
      c:setNeighbour(E, fc)
      fc:setNeighbour(W, c)
    end
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x-(self.w/2)) and (c.center.y == d.center.y-self.h75) end)
    if fc then
      c:setNeighbour(SE, fc)
      fc:setNeighbour(NW, c)
    end
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x+(self.w/2)) and (c.center.y == d.center.y-self.h75) end)
    if fc then
      c:setNeighbour(SW, fc)
      fc:setNeighbour(NE, c)
    end
  end
end

function Grid:carvePassages()
  self:randomCell():recursiveBacktracker()
end

function Grid:tunnel(y)

  local cWest = self:findCell(1, y)
  local cEast = self:findCell(self.width, y)

  cWest:removeWall(W)
  cEast:removeWall(E)

  -- you can tell if a tile is a westerly tunnel, because it's x will be num cols + 1
  local cTunnelE = Cell:new(self, cEast.x+1, cEast.y)
  assert(cTunnelE.x==self.width+1)
  cTunnelE:removeWall(E)
  cTunnelE:removeWall(W)

  -- you can tell if a tile is an easterly tunnel, because it's x will be 0
  local cTunnelW = Cell:new(self, cWest.x-1, cWest.y)
  assert(cTunnelW.x==0)
  cTunnelW:removeWall(E)
  cTunnelW:removeWall(W)

  cTunnelE:setNeighbour(W, cEast)
  cTunnelE:setNeighbour(E, cTunnelW)
  cEast:setNeighbour(E, cTunnelE)

  cTunnelW:setNeighbour(E, cWest)
  cTunnelW:setNeighbour(W, cTunnelE)
  cWest:setNeighbour(W, cTunnelW)

  self.cells[#self.cells + 1] = cTunnelE
  self.cells[#self.cells + 1] = cTunnelW
end

function Grid:iterator(fn)
  for _,c in ipairs(self.cells) do
    fn(c)
  end
end

function Grid:hasDots()
  local n = 0
  self:iterator(function(c) if c:hasDot() then n = n + 1 end end)
  return n > 0
end

function Grid:findCell(x,y)
  local c = table.find(self.cells, function(d) return d.x == x and d.y == y end)
  if not c then print('cannot find', x, y) end
  return c
  -- return self.cells[(y*self.width) + x]
end

function Grid:randomCell()
  return self.cells[math.random(#self.cells)]
end

function Grid:findCulDeSacs()
  local arr = {}
  self:iterator(function(c)
    if c:countWalls() == 5 then
      arr[#arr+1] = c
    end
  end)
  -- print(#arr, 'cul-de-sacs found')
  return arr
end

function Grid:createGraphics()
  self:iterator(function(c) c:createGraphics() end)
end

--[[
--hypotenuse function: computes sqrt(a^2 + b^2) without underflow / overflow problems.
local function hypot(a, b)
	if a == 0 and b == 0 then return 0 end
	a, b = math.abs(a), math.abs(b)
	a, b = math.max(a,b), math.min(a,b)
	return a * math.sqrt(1 + (b / a)^2)
end

function Grid:applyAlpha()
  local scale = hypot(self.width, self.height)
  self:iterator(function(c)
    local dist = hypot(c.x - puck.cell.x, c.y - puck.cell.y)
    local alpha = 1 - dist/scale
    for dir = 1,4 do
      local l = c.edges[dir].line
      if l then
        l:setStrokeColor(0,0,0.75, alpha)
      end
      local d = c.dot
      if d then
        d:setFillColor(1,1,1, alpha)
      end
    end
  end)
end
]]

--[[
function Grid:destroy()
  self:iterator(function(c) c:destroy() end)
  self.mazeGroup = nil
  self.dotGroup = nil
  self.actorGroup = nil
  self.bubbleGroup = nil
  self.cells = nil
end
]]

return Grid