-- Cell class

local composer = require('composer')

local bit = require('plugin.bit')
local bezier = require('Bezier')

local PLACE_COIN_CHANCE = 0.3333

local function hammingWeight(coin)
  local w = 0
  for dir = 1, 6 do
    if bit.band(coin, 1) == 1 then
      w = w + 1
    end
    coin = bit.rshift(coin, 1)
  end
  return w
end

Cell = {
  -- prototype object
  grid = nil,      -- grid we belong to
  x = nil,        -- column 1 .. width
  y = nil,        -- row 1 .. height
  center = nil,   -- point table, screen coords

  ne, e, se, sw, w, nw = nil, nil, nil, nil, nil, nil,
  coins = 0,

  color = nil,  -- e.g. {0,1,0}
  hexagon = nil,     -- ShapeObject for outline

  grp = nil,  -- group to put shapes in
  grpObjects = nil,
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

  -- o.center = {x=(x*grid.w) + (grid.w/2), y=(y * grid.h75) + (grid.h/2) - grid.h + 120}
  o.center = {x=(x*dim.W)-(dim.W), y=(y*dim.H75)}
  if math.fmod(y,2) == 1 then
    o.center.x = o.center.x + dim.W50
  end

  -- "These coordinates will automatically be re-centered about the center of the polygon."
  o.hexagon = display.newPolygon(o.grid.gridGroup, o.center.x, o.center.y, dim.vertices)
  o.hexagon:setFillColor(0,0,0)
  o.hexagon:setStrokeColor(0.2)
  o.hexagon.strokeWidth = 2

  o.hexagon:addEventListener('tap', o) -- table listener

  return o
end

function Cell:shiftBits(num)
  num = num or 1
  while num > 0 do
    if bit.band(self.coins, dim.NORTHWEST) == dim.NORTHWEST then
      -- high bit is set
      self.coins = bit.lshift(self.coins, 1)
      self.coins = bit.band(self.coins, dim.MASK)
      self.coins = bit.bor(self.coins, 1)
    else
      self.coins = bit.lshift(self.coins, 1)
    end
    num = num - 1
  end
end

function Cell:isComplete()
  for _, cd in ipairs(dim.cellData) do
    if bit.band(self.coins, cd.bit) == cd.bit then
      local cn = self[cd.link]
      if not cn then
        return false
      end
      if bit.band(cn.coins, cd.oppBit) == 0 then
        return false
      end
    end
  end
  return true
end

function Cell:placeCoin()
  if self.e then
    if math.random() < PLACE_COIN_CHANCE then
      self.coins = bit.bor(self.coins, dim.EAST)
      self.e.coins = bit.bor(self.e.coins, dim.WEST)
    end
  end
  if self.ne then
    if math.random() < PLACE_COIN_CHANCE then
      self.coins = bit.bor(self.coins, dim.NORTHEAST)
      self.ne.coins = bit.bor(self.ne.coins, dim.SOUTHWEST)
    end
  end
  if self.se then
    if math.random() < PLACE_COIN_CHANCE then
      self.coins = bit.bor(self.coins, dim.SOUTHEAST)
      self.se.coins = bit.bor(self.se.coins, dim.NORTHWEST)
    end
  end
end

function Cell:jumbleCoin()
end

function Cell:colorConnected(color)
  self.color = color
  for _, cd in ipairs(dim.cellData) do
    if bit.band(self.coins, cd.bit) == cd.bit then
      local cn = self[cd.link]
      if cn and cn.coins ~= 0 and cn.color == nil then
        cn:colorConnected(color)
      end
    end
  end
end

function Cell:setColor(color)
--[[
  When you modify a group's properties, all of its children are affected. 
  For example, if you set the alpha property on a display group, 
  each child's alpha value is multiplied by the new alpha of the group. 
  Groups automatically detect when a child's properties have changed 
  (position, rotation, etc.). Thus, on the next render pass, the child will re-render.
]]
  if self.grpObjects then
    for _, o in ipairs(self.grpObjects) do
      o:setStrokeColor(unpack(color))
    end
  end
end

function Cell:tap(event)
  -- implement table listener for tap events
  print('tap', self.x, self.y, self.coins, hammingWeight(self.coins))
  if self.grid:isComplete() then
    composer.removeScene('Filigree')
    composer.gotoScene('Filigree')
    return
  end

  if self.grp then
    self:shiftBits()
    self:createGraphics()

    if self.grid:isComplete() then
      self.grid:colorAll()
    end
  end
end

function Cell:createGraphics()

  if 0 == self.coins then
    return
  end

  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
    self.grpObjects = nil
  end

  self.grp = display.newGroup()
  self.grid.shapesGroup:insert(self.grp)

  self.grpObjects = {}

  local bitCount = hammingWeight(self.coins)
  if bitCount == 1 then
    local cd = table.find(dim.cellData, function(b) return self.coins == b.bit end)
    assert(cd)
    local line = display.newLine(self.grp,
      self.center.x,
      self.center.y, 
      self.center.x + cd.c2eX,
      self.center.y + cd.c2eY)
    line.strokeWidth = dim.Q10
    line:setStrokeColor(unpack(self.color))
    table.insert(self.grpObjects, line)

    local circle = display.newCircle(self.grp, self.center.x, self.center.y, dim.Q33)
    circle.strokeWidth = dim.Q10
    circle:setStrokeColor(unpack(self.color))
    circle:setFillColor(0,0,0)
    table.insert(self.grpObjects, circle)
  else
    -- until Bezier curves, just draw a line from coin-bit-edge to center
    --[[
    for _,cd in ipairs(dim.cellData) do
      if bit.band(cd.bit, self.coins) == cd.bit then
        local line = display.newLine(self.grp,
        self.center.x,
        self.center.y, 
        self.center.x + cd.c2eX,
        self.center.y + cd.c2eY)
        line.strokeWidth = dim.Q10
      end
    end
    ]]
    -- make a list of edge coords we need to visit
    -- use center and center as control points
    local arr = {}
    for _,cd in ipairs(dim.cellData) do
      if bit.band(self.coins, cd.bit) == cd.bit then
        table.insert(arr, {x=self.center.x + cd.c2eX, y=self.center.y + cd.c2eY})
      end
    end
    -- close path for better aesthetics
    if bitCount == 2 then
      table.insert(arr, arr[1])
    end
    assert(#arr > 1)
    -- print(
    --   arr[1].x, arr[1].y, 
    --   self.center.x, self.center.y,
    --   arr[2].x, arr[2].y)
    for n = 1, #arr-1 do
      local cp1 = {x=(self.center.x + arr[n].x)/2, y=(self.center.y + arr[n].y)/2}
      local cp2 = {x=(self.center.x + arr[n+1].x)/2, y=(self.center.y + arr[n+1].y)/2}
      local curve = bezier.new(
        arr[n].x, arr[n].y, 
        cp1.x, cp1.y,
        cp2.x, cp2.y,
        arr[n+1].x, arr[n+1].y)
      local curveDisplayObject = curve:get()
      curveDisplayObject.strokeWidth = dim.Q10
      curveDisplayObject:setStrokeColor(unpack(self.color))
      self.grp:insert(curveDisplayObject)
      table.insert(self.grpObjects, curveDisplayObject)
    end
  end
end

--[[
function Cell:destroy()
  self.grid = nil
  -- TODO
end
]]

return Cell