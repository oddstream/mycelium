-- Cell class

local bit = require('plugin.bit')

local Dim = require 'Dim'

local PLACE_COIN_CHANCE = 0.5

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
  local v = { -- vertices
    0,-(dim.H50),  -- N 1,2
    dim.W50,-(dim.H25), -- NE 3,4
    dim.W50,dim.H25,    -- SE 5,6
    0,dim.H50,    -- S 7,8
    -(dim.W50),dim.H25, -- SW 9,10
    -(dim.W50),-(dim.H25),  -- NW 11,12
  }
  o.hexagon = display.newPolygon(o.grid.gridGroup, o.center.x, o.center.y, v)
  o.hexagon:setFillColor(0,0,0)
  o.hexagon:setStrokeColor(0.2)
  o.hexagon.strokeWidth = 2

  o.hexagon:addEventListener('tap', o) -- table listener

  return o
end

function Cell:shiftBits()
  if bit.band(self.coins, dim.NORTHWEST) == dim.NORTHWEST then
    -- high bit is set
    self.coins = bit.lshift(self.coins, 1)
    self.coins = bit.band(self.coins, dim.MASK)
    self.coins = bit.bor(self.coins, 1)
  else
    self.coins = bit.lshift(self.coins, 1)
  end
end

function Cell:unshiftBits()
end

function Cell:isComplete()
  return false
end

function Cell:placeCoin()
  assert(dim)
  assert(dim.EAST)
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

function Cell:colorComplete()
end

function Cell:setGraphic()
end

function Cell:tap(event)
  -- implement table listener for tap events
  print('tap', self.x, self.y, self.coins, hammingWeight(self.coins))
  if self.grp then
    self:shiftBits()
    self:createGraphics()
  end
end

function Cell:createGraphics()

  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
  end

  self.grp = display.newGroup()
  self.grid.shapesGroup:insert(self.grp)

  if hammingWeight(self.coins) == 1 then
    local cd = table.find(dim.cellData, function(b) return self.coins == b.bit end)
    assert(cd)
    local line = display.newLine(self.grp,
      self.center.x,
      self.center.y, 
      self.center.x + cd.c2eX,
      self.center.y + cd.c2eY)
    line.strokeWidth = dim.Q10

    local circle = display.newCircle(self.grp, self.center.x, self.center.y, dim.Q33)
    circle.strokeWidth = dim.Q10
    circle:setFillColor(0,0,0)
  else
    -- until Bezier curves, just draw a line from coin-bit-edge to center
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
  end
end

--[[
function Cell:destroy()
  self.grid = nil
  -- TODO
end
]]

return Cell