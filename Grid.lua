-- Grid (of cells) class

local Util = require 'Util'
local Cell = require 'Cell'
local Dim = require 'Dim'

local Grid = {
  -- prototype object
  gridGroup = nil,
  shapesGroup = nil,

  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows

  complete = nil,

  newButton = nil,
}
Grid.__index = Grid

function Grid.new(gridGroup, shapesGroup)
  local o = {}
  setmetatable(o, Grid)

  o.gridGroup = gridGroup
  o.shapesGroup = shapesGroup

  return o
end

function Grid:reset()

  -- clear out gridGroup, shapeGroup objects
  while self.shapesGroup.numChildren > 0 do
    display.remove(self.shapesGroup[self.shapesGroup.numChildren])
  end

  while self.gridGroup.numChildren > 0 do
    display.remove(self.gridGroup[self.gridGroup.numChildren])
  end

  do
    -- local last_using = composer.getVariable('last_using')
    -- if not last_using then
    --   last_using = 0
    -- end
    local before = collectgarbage('count')
    collectgarbage('collect')
    local after = collectgarbage('count')
    print('collected', math.floor(before - after), 'KBytes, now using', math.floor(after), 'KBytes')
    -- composer.setVariable('last_using', after)
  end

end

function Grid:newLevel()

  -- assume gridGroup, shapeGroup are created but empty

  math.randomseed(_G.gameState.level + 2) -- make the first level easier and prettier

  -- width runs from 4 to 7
  -- (0 % 4) + 4 == 4
  -- (1 % 4) + 4 == 5
  -- (2 % 4) + 4 == 6
  -- (3 % 4) + 4 == 7
  -- (4 % 4) + 4 == 4
  -- (5 % 4) + 4 == 5
  self.width = ((_G.gameState.level - 1) % 3) + 3
  self.height = (self.width*2) - 1  -- odd number for mirror
  trace('dimensions', self.width, self.height)

  -- each cell is Q * math.sqrt(3) wide
  -- we need space for numX + a half
  self.dim = Dim.new( display.viewableContentWidth/(self.width+0.5)/math.sqrt(3) )

  self.colors, self.backgroundColor, self.completeColor = Util.chooseColors()
  display.setDefault("background", unpack(self.backgroundColor))

  self:createCells()
  self:linkCells()

  self:placeCoins()
  self:colorCoins()
  self:jumbleCoins()
  self:createGraphics(0)

  self.complete = false

  self:fadeIn()

  self.newButton:setLabel(tostring(_G.gameState.level))
  -- self.newButton:setFillColor(0.2,0.2,0.2)

end

function Grid:createCells()

  self.cells = {}

  for y = 1, self.height do
    for x = 1, self.width do
      local c = Cell.new(self, x, y)
      table.insert(self.cells, c) -- push
    end
  end

end

function Grid:linkCells()

  for _,c in ipairs(self.cells) do
    -- local fc -- found cell

    -- matters if x is odd or even
    -- even x: cells to ne or se will be == x
    -- even x cells to sw or nw will be x - 1
    -- odd x: cells to se or ne will be x + 1
    -- odd x: cells to sw or nw will be == x

    local oddRow = math.fmod(c.y,2) == 1
    local xdiffE, xdiffW

    if oddRow then xdiffE = 1 else xdiffE = 0 end -- easterly
    if oddRow then xdiffW = 0 else xdiffW = -1 end -- westerly

    c.ne = self:findCell(c.x + xdiffE, c.y - 1)
    c.e = self:findCell(c.x + 1, c.y)
    c.se = self:findCell(c.x + xdiffE, c.y + 1)
    c.sw = self:findCell(c.x + xdiffW, c.y + 1)
    c.w = self:findCell(c.x - 1, c.y)
    c.nw = self:findCell(c.x + xdiffW, c.y - 1)

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
  return nil
end

function Grid:randomCell()
  return self.cells[math.random(#self.cells)]
end

function Grid:createGraphics()
  self:iterator(function(c) c:createGraphics(0) end)
end

function Grid:placeCoins()
  if math.random() < 0.5 then
    self:iterator(function(c) c:placeCoin() end)
  else
    local yS = self.height
    for yN = 1, self.height/2 do
      for x = 1, self.width do
        local cN = self:findCell(x,yN)
        local cS = self:findCell(x,yS)
        cN:placeCoin(cS)
      end
      yS = yS - 1
    end
  end

  self:iterator(function(c) c:calcHammingWeight() end)
end

function Grid:colorCoins()
  assert(self.colors)
  local nColor = 1
  local section = 1
  local c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  while c do
    c:colorConnected(self.colors[nColor], section)
    nColor = nColor + 1
    if nColor > #self.colors then
      nColor = 1
    end
    section = section + 1
    c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  end
end

function Grid:jumbleCoins()
  self:iterator(function(c) c:jumbleCoin() end)
end

function Grid:isComplete()
  for n = 1, #self.cells do
    if not self.cells[n]:isComplete() then
      return false
    end
  end
  self.complete = true
  return true
end

function Grid:isSectionComplete(section)
  local arr = table.filter(self.cells, function(c) return c.section == section end)
  for n = 1, #arr do
    if not arr[n]:isComplete(section) then
      return false
    end
  end
  for n = 1, #arr do
    arr[n].section = 0  -- lock cell from moving
  end
  return true
end

function Grid:colorComplete()
  self:iterator( function(c)
    c:colorComplete()
  end )
  self.newButton:setLabel('NEXT') --'»')
end

function Grid:fadeIn()
  self:iterator( function(c) c:fadeIn() end )
end

function Grid:fadeOut()
  self:iterator( function(c) c:fadeOut() end )
end

function Grid:destroy()
  audio.stop()  -- stop all channels
end

return Grid