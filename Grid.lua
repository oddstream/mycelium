-- Grid (of cells) class

local composer = require('composer')

local Cell = require 'Cell'

Grid = {
  -- prototype object
  gridGroup = nil,
  shapeGroup = nil,
  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows

  dingSound = nil,
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

  o.dingSound = audio.loadSound('complete.wav')

  return o
end

function Grid:reset()
  -- clear out the Cells
  self:iterator(function(c)
    c:reset()
  end)

  do
    local last_using = composer.getVariable('last_using')
    if not last_using then
      last_using = 0
    end
    local before = collectgarbage('count')
    collectgarbage('collect')
    local after = collectgarbage('count')
    print('collected', math.round(before - after), 'KBytes, using', math.round(after), 'KBytes', 'leaked', after-last_using)
    composer.setVariable('last_using', after)
  end

  self:placeCoins()
  self:colorCoins()
  self:jumbleCoins()
  self:createGraphics()
end

function Grid:ding()
  audio.play(self.dingSound)
end

--[[
function Grid:linkCells()
  local dim = dimensions

  -- print('linking', #self.cells, 'cells')
  local links = 0
  for _,c in ipairs(self.cells) do
    local fc -- found cell
    -- look to ne
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x - dim.W50) and (c.center.y == d.center.y + dim.H75) end)
    if fc then
      links = links + 1
      c.ne = fc
      -- fc.sw = c
    end
    -- look to e
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x - dim.W) and (c.center.y == d.center.y) end)
    if fc then
      -- print('linking e-w', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.e = fc
      -- fc.w = c
    end
    -- look se
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x - dim.W50) and (c.center.y == d.center.y - dim.H75) end)
    if fc then
      -- print('linking se-nw', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.se = fc
      -- fc.nw = c
    end
    -- look sw
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x + dim.W50) and (c.center.y == d.center.y - dim.H75) end)
    if fc then
      -- print('linking sw-ne', c.x, c.y, 'and', fc.x, fc.y)
      links = links + 1
      c.sw = fc
      -- fc.ne = c
    end
    -- look w
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x + dim.W) and (c.center.y == d.center.y) end)
    if fc then
      links = links + 1
      c.w = fc
      -- fc.e = c
    end
    -- look nw
    fc = table.find(self.cells, function(d) return (c.center.x == d.center.x + dim.W50) and (c.center.y == d.center.y + dim.H75) end)
    if fc then
      links = links + 1
      c.nw = fc
      -- fc.se = c
    end

  end
  -- print(links, 'links made')
end
]]

function Grid:linkCells2()
  for _,c in ipairs(self.cells) do
    local fc -- found cell

    -- matters if x is odd or even
    -- even x: cells to ne or se will be == x
    -- even x cells to sw or nw will be x - 1
    -- odd x: cells to se or ne will be x + 1
    -- odd x: cells to sw or nw will be == x

    local oddRow = math.fmod(c.y,2) == 1
    local xdiffE, xdiffW

    if oddRow then xdiffE = 1 else xdiffE = 0 end -- easterly
    if oddRow then xdiffW = 0 else xdiffW = -1 end -- westerly

    fc = self:findCell(c.x + xdiffE, c.y - 1)
    if fc then
      c.ne = fc
    end

    fc = self:findCell(c.x + 1, c.y)
    if fc then
      c.e = fc
    end

    fc = self:findCell(c.x + xdiffE, c.y + 1)
    if fc then
      c.se = fc
    end

    fc = self:findCell(c.x + xdiffW, c.y + 1)
    if fc then
      c.sw = fc
    end

    fc = self:findCell(c.x - 1, c.y)
    if fc then
      c.w = fc
    end

    fc = self:findCell(c.x + xdiffW, c.y - 1)
    if fc then
      c.nw = fc
    end

  end
end

function Grid:iterator(fn)
  for _,c in ipairs(self.cells) do
    fn(c)
  end
end

function Grid:findCell(x,y)
  for _,c in ipairs(self.cells) do
    if c.x == x and c.y == y then
      return c
    end
  end
  -- print('*** cannot find cell', x, y)
  return nil
end

function Grid:randomCell()
  return self.cells[math.random(#self.cells)]
end

function Grid:createGraphics()
  self:iterator(function(c) c:createGraphics() end)
end

function Grid:placeCoins()
  local dim = dimensions

  -- self:iterator(function(c) c:placeCoin() end)

  local yS = self.height
  for yN = 1, self.height/2 do
    for x = 1, self.width do
      local cN = self:findCell(x,yN)
      local cS = self:findCell(x,yS)
      cN:placeCoin(cS)
      -- cN:placeCoin()
    end
    yS = yS - 1
  end
end

function Grid:colorCoins()
  -- https://en.wikipedia.org/wiki/Web_colors
  local colorsGreen = {
    {0,100,0},  -- DarkGreen
    {107,142,35},  -- OliveDrab
    {139,69,19},  -- SaddleBrown
    {0,64,0},
    {80,80,0},  -- Olive
    {154,205,50},  -- YellowGreen
    {46,139,87} -- SeaGreen
  }
  --[[
  local colorsPink = {
    {199,21,133},
    {219,112,147},
    {255,20,147},
    {255,105,180},
    {255,192,203},
  }
  ]]
  local colorsBlue = {
    {25,25,112},
    {0,0,205},
    {65,105,225},
    {30,144,255},
    {135,206,250},
    {176,196,222},
  }
  local colorsAll = {
    colorsGreen,
    colorsBlue,
  }
  local colors = colorsAll[math.random(#colorsAll)]
  for _,row in ipairs(colors) do
    for i = 1,3 do
      row[i] = row[i] * 4 / 1020
    end
  end

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

function Grid:isComplete()
  for n = 1, #self.cells do
    if not self.cells[n]:isComplete() then
      return false
    end
  end
  return true
end

function Grid:colorComplete()
  self:iterator( function(c) c:setColor({1,1,1}) end )
end

return Grid