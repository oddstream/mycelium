-- Grid (of cells) class

Grid = {
  -- prototype object
  gridGroup = nil,
  shapeGroup = nil,
  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows
}

function Grid:new(gridGroup, shapesGroup, width, height)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.gridGroup = gridGroup
  o.shapesGroup = shapesGroup

  o.cells = {}
  o.width = width
  o.height = height

  for y = 1, height do
    for x = 1, width do
      local c = Cell:new(o, x, y)
      table.insert(o.cells, c) -- push
    end
  end

  return o
end

function Grid:reset()
  self:iterator(function(c)
    c:reset()
  end)
end

function Grid:linkCells()
  -- print('linking', #self.cells, 'cells')
  local links = 0
  for _,c in ipairs(self.cells) do
    local fc -- found cell
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x - dim.W) and (c.center.y == d.center.y) end)
    if fc then
      -- print('linking e-w', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.e = fc
      fc.w = c
    end
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x-(dim.W50)) and (c.center.y == d.center.y-dim.H75) end)
    if fc then
      -- print('linking se-nw', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.se = fc
      fc.nw = c
    end
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x+(dim.W50)) and (c.center.y == d.center.y-dim.H75) end)
    if fc then
      -- print('linking sw-ne', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.sw = fc
      fc.ne = c
    end
  end
  print(links, 'links made')
end

function Grid:iterator(fn)
  for _,c in ipairs(self.cells) do
    fn(c)
  end
end

function Grid:findCell(x,y)
  local c = table.find(self.cells, function(d) return d.x == x and d.y == y end)
  if not c then print('cannot find', x, y) end
  return c
end

function Grid:randomCell()
  return self.cells[math.random(#self.cells)]
end

function Grid:createGraphics()
  self:iterator(function(c) c:createGraphics() end)
end

function Grid:placeCoins()
  self:iterator(function(c) c:placeCoin() end)
end

function Grid:colorCoins()
  local colors = {
    {0,0.2,0},
    {0,0.4,0},
    {0,0.6,0},
    {0.5,0.5,0},
    {0.5,0.5,0.5},
  }
  local nColor = 1
  local c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  while c do
    c:colorConnected(colors[nColor])
    nColor = nColor + 1
    if nColor > #colors then
      nColor = 1
    end
    c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  end
end

function Grid:jumbleCoins()
  self:iterator( function(c) c:jumbleCoin() end )
end

function Grid:setGraphics()
  self:iterator( function(c) c:setGraphic() end )
end

function Grid:isComplete()
  for n = 1, #self.cells do
    if not self.cells[n]:isComplete() then
      return false
    end
  end
  return true
end

function Grid:colorAll()
  self:iterator( function(c) c:setColor({1,1,1}) end )
end

--[[
function Grid:destroy()
  self:iterator(function(c) c:destroy() end)
  self.gridGroup = nil
  self.shapesGroup = nil
  self.cells = nil
end
]]

return Grid