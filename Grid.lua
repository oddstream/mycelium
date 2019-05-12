-- Grid (of cells) class

local composer = require('composer')

local Cell = require 'Cell'

local Grid = {
  -- prototype object
  gridGroup = nil,
  shapeGroup = nil,
  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows

  complete = nil,

  tapSound = nil,
  sectionSound = nil,
  dingSound = nil,
  lockedSound = nil,

  gameState = nil,

  levelText = nil,
  newButton = nil,
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

  o:linkCells2()

  o.complete = false

  o.tapSound = audio.loadSound('sound56.wav')
  o.sectionSound = audio.loadSound('sound63.wav')
  o.dingSound = audio.loadSound('complete.wav')
  o.lockedSound = audio.loadSound('sound61.wav')

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
    print('collected', math.floor(before - after), 'KBytes, using', math.floor(after), 'KBytes', 'leaked', after-last_using)
    composer.setVariable('last_using', after)
  end

  self:newLevel()
end

function Grid:newLevel()
  self:placeCoins()
  self:colorCoins()
  self:jumbleCoins()
  self:createGraphics(0)

  self:fadeIn()

  self.levelText.text = string.format('#%u', self.gameState.level)

  self.newButton:setFillColor(0.1,0.1,0.1)
  self.complete = false
end

function Grid:advanceLevel()
  assert(self.gameState)
  assert(self.gameState.level)
  self.gameState.level = self.gameState.level + 1
  self.gameState:write()
end

function Grid:sound(type)
  if type == 'tap' then
    if self.tapSound then audio.play(self.tapSound) end
  elseif type == 'section' then
    if self.sectionSound then audio.play(self.sectionSound) end
  elseif type == 'complete' then
    if self.dingSound then audio.play(self.dingSound) end
  elseif type == 'locked' then
    if self.lockedSound then audio.play(self.lockedSound) end
  end
end

function Grid:linkCells2()
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

--[[
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
]]
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
  -- print('*** cannot find cell', x, y)
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
  -- https://en.wikipedia.org/wiki/Web_colors
  local colorsGreen = {
    {0,100,0},  -- DarkGreen
    {85,107,47},  -- DarkOliveGreen
    {107,142,35},  -- OliveDrab
    {139,69,19},  -- SaddleBrown
    {80,80,0},  -- Olive
    {154,205,50},  -- YellowGreen
    {46,139,87}, -- SeaGreen
    {128,128,128},
  }
  local colorsPink = {
    {255,192,203}, -- Pink
    {255,105,180}, -- HotPink
    {219,112,147}, -- PaleVioletRed
    {255,20,147},  -- DeepPink
    {199,21,133},  -- MediumVioletRed

    {238,130,238}, -- Violet
  }
  local colorsBlue = {
    {25,25,112},
    {65,105,225},
    {30,144,255},
    {135,206,250},
    {176,196,222},
    {0,0,205},
  }
  local colorsOrange = {
    {255,165,0},
    {255,69,0},
    {255,127,80},
    {255,140,0},
    {255,99,71},
    {128,128,128},
  }
  local colorsGray = {
    {128,128,128},
    {192,192,192},
    {112,128,144},
    {220,220,220},
    {49,79,79},
  }

  local colorsAll = {
    colorsGreen,
    colorsBlue,
    -- colorsOrange,
    -- colorsPink,
    colorsGray,
  }

  local colors = colorsAll[math.random(#colorsAll)]

  for _,row in ipairs(colors) do
    for i = 1,3 do
      row[i] = row[i] * 4 / 1020
    end
  end

  local nColor = 1
  local section = 1
  local c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  while c do
    c:colorConnected(colors[nColor], section)
    nColor = nColor + 1
    if nColor > #colors then
      nColor = 1
    end
    section = section + 1
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
  self:iterator( function(c) c:colorComplete() end )
  self.newButton:setFillColor(1,1,1)
end

function Grid:fadeIn()
  self:iterator( function(c) c:fadeIn() end )
end

function Grid:fadeOut()
  self:iterator( function(c) c:fadeOut() end )
end

function Grid:destroy()
  audio.stop()  -- stop all channels
  if self.dingSound then
    audio.dispose(self.dingSound)
    self.dingSound = nil
  end
  if self.sectionSound then
    audio.dispose(self.sectionSound)
    self.sectionSound = nil
  end
  if self.tapSound then
    audio.dispose(self.tapSound)
    self.tapSound = nil
  end
  if self.lockedSound then
    audio.dispose(self.lockedSound)
    self.lockedSound = nil
  end
end

return Grid