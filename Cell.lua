-- Cell class

local composer = require('composer')

local bit = require('plugin.bit')
local bezier = require('Bezier')

local PLACE_COIN_CHANCE = 0.3333 / 2
local SHOW_HEXAGON = true

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
  section = nil,

  grp = nil,  -- group to put shapes in
  grpObjects = nil,
}

function Cell:new(grid, x, y)
  local dim = dimensions

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
  -- can't have the center being on the edge of the screen, it would clip left of first cell
  o.center.x = o.center.x + dim.W50

  -- "These coordinates will automatically be re-centered about the center of the polygon."
  o.hexagon = display.newPolygon(o.grid.gridGroup, o.center.x, o.center.y, dim.vertices)
  o.hexagon:setFillColor(0,0,0)
  if SHOW_HEXAGON then
    o.hexagon:setStrokeColor(0.05)
    o.hexagon.strokeWidth = 2
  end

  o.hexagon:addEventListener('tap', o) -- table listener

  return o
end

function Cell:reset()
  self.coins = 0
  self.color = nil
  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
  end
  if self.grpObjects then
    self.grpObjects = nil
  end
end

function Cell:shiftBits(num)
  local dim = dimensions

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

function Cell:isComplete(section)
  local dim = dimensions

  if section and self.section ~= section then
    return false
  end
  for _, cd in ipairs(dim.cellData) do
    if bit.band(self.coins, cd.bit) == cd.bit then
      local cn = self[cd.link]
      if not cn then
        return false
      end
      if section and cn.section ~= section then
        return false
      end
      if bit.band(cn.coins, cd.oppBit) == 0 then
        return false
      end
    end
  end
  return true
end

function Cell:placeCoin(mirror)
  local dim = dimensions

  for _,cd in ipairs(dim.cellData) do
    if math.random() < PLACE_COIN_CHANCE then
      if self[cd.link] then
        self.coins = bit.bor(self.coins, cd.bit)
        self[cd.link].coins = bit.bor(self[cd.link].coins, cd.oppBit)

        if mirror then
          local m_cd = dim.cellData[cd.vsym]
          assert(m_cd)
          assert(m_cd.bit)
          if mirror[m_cd.link] then
            mirror.coins = bit.bor(mirror.coins, m_cd.bit)
            mirror[m_cd.link].coins = bit.bor(mirror[m_cd.link].coins, m_cd.oppBit)
          end
        end

      end
    end
  end
end

function Cell:jumbleCoin()
  self:shiftBits(math.random(5))
end

function Cell:colorConnected(color, section)
  local dim = dimensions

  self.color = color
  self.section = section

  for _, cd in ipairs(dim.cellData) do
    if bit.band(self.coins, cd.bit) == cd.bit then
      local cn = self[cd.link]
      if cn and cn.coins ~= 0 and cn.color == nil then
        cn:colorConnected(color, section)
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
      if o.setStrokeColor then
        o:setStrokeColor(unpack(color))
      end
      if o.setFillColor then
        o:setFillColor(unpack(color))
      end
    end
  end
end

function Cell:tap(event)
  local dim = dimensions
  -- implement table listener for tap events
  -- print('tap', self.x, self.y, self.coins, hammingWeight(self.coins))

  local function afterRotate()
    self:shiftBits()
    self:createGraphics()
    if self.grid:isSectionComplete(self.section) then
      print('section complete')
    end
    if self.grid:isComplete() then
      self.grid:ding()
      self.grid:colorComplete()
    end
  end
--[[
  for _,cd in ipairs(dim.cellData) do
    if not self[cd.link] then print(self.x, self.y, 'no link to', cd.link) end
  end
]]
  if self.grid:isComplete() then
    self.grid:reset()
  elseif self.section == 0 then
    print('locked') -- TODO play a locked sound, or shake screen/section
  elseif self.grp then
    -- self.grp.anchorChildren = true
    -- self.grp.anchorX = 0
    -- self.grp.anchorY = 0
    transition.to(self.grp, {
      time = 100,
      rotation = 45,  -- enough to give illusion, no need for full 60 degrees
      onComplete = afterRotate,
    })
  end
end

function Cell:createGraphics()
  local dim = dimensions

  if 0 == self.coins then
    return
  end

  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
    self.grpObjects = nil
  end

  self.grp = display.newGroup()
  -- center the group on the center of the hexagon, otherwise it's at 0,0
  self.grp.x = self.center.x
  self.grp.y = self.center.y
  self.grid.shapesGroup:insert(self.grp)

  self.grpObjects = {}

  local bitCount = hammingWeight(self.coins)
  if bitCount == 1 then
    local cd = table.find(dim.cellData, function(b) return self.coins == b.bit end)
    assert(cd)
    local line = display.newLine(self.grp,
      0,
      0, 
      cd.c2eX,
      cd.c2eY)
    line.strokeWidth = dim.Q20
    line:setStrokeColor(unpack(self.color))
    table.insert(self.grpObjects, line)

    local endcap = display.newCircle(self.grp, cd.c2eX, cd.c2eY, dim.Q10)
    endcap:setFillColor(unpack(self.color))
    table.insert(self.grpObjects, endcap)

    local circle = display.newCircle(self.grp, 0, 0, dim.Q33)
    circle.strokeWidth = dim.Q20
    circle:setStrokeColor(unpack(self.color))
    circle:setFillColor(0,0,0)
    table.insert(self.grpObjects, circle)
  else
    -- until Bezier curves, just draw a line from coin-bit-edge to center
    --[[
    for _,cd in ipairs(dim.cellData) do
      if bit.band(cd.bit, self.coins) == cd.bit then
        local line = display.newLine(self.grp,
        0,
        0, 
        cd.c2eX,
        cd.c2eY)
        line.strokeWidth = dim.Q10
      end
    end
    ]]
    -- make a list of edge coords we need to visit
    local arr = {}
    for _,cd in ipairs(dim.cellData) do
      if bit.band(self.coins, cd.bit) == cd.bit then
        table.insert(arr, {x=cd.c2eX, y=cd.c2eY})
      end
    end
    -- close path for better aesthetics
    if bitCount > 3 then
      table.insert(arr, arr[1])
    end
    assert(#arr > 1)
    -- print(
    --   arr[1].x, arr[1].y, 
    --   arr[2].x, arr[2].y)
    for n = 1, #arr-1 do
    -- use (off-)center and (off-)center as control points
      local av = 1.8  -- make the three-edges circles round
      local cp1 = {x=(arr[n].x)/av, y=(arr[n].y)/av}
      local cp2 = {x=(arr[n+1].x)/av, y=(arr[n+1].y)/av}
      local curve = bezier.new(
        arr[n].x, arr[n].y, 
        cp1.x, cp1.y,
        cp2.x, cp2.y,
        arr[n+1].x, arr[n+1].y)
      local curveDisplayObject = curve:get()
      curveDisplayObject.strokeWidth = dim.Q20
      curveDisplayObject:setStrokeColor(unpack(self.color))
      self.grp:insert(curveDisplayObject)
      table.insert(self.grpObjects, curveDisplayObject)
    end
    for n = 1, #arr do
      local endcap = display.newCircle(self.grp, arr[n].x, arr[n].y, dim.Q10)
      endcap:setFillColor(unpack(self.color))
      table.insert(self.grpObjects, endcap)
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