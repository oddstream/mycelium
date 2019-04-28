-- Cell class

local composer = require('composer')

local bit = require('plugin.bit')
local bezier = require('Bezier')

local PLACE_COIN_CHANCE = 0.3333 / 2
local SHOW_HEXAGON = true

Cell = {
  -- prototype object
  grid = nil,      -- grid we belong to
  x = nil,        -- column 1 .. width
  y = nil,        -- row 1 .. height
  center = nil,   -- point table, screen coords

  ne, e, se, sw, w, nw = nil, nil, nil, nil, nil, nil,
  coins = 0,
  hw = 0,     -- hammingWeight

  color = nil,       -- e.g. {0,1,0}
  hexagon = nil,     -- ShapeObject for outline
  section = nil,     -- number of section (0 if locked)

  grp = nil,        -- display group to put shapes in
  grpObjects = nil, -- list of ShapeObject for coloring

  touchCoords = nil,
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
  o.center.x = o.center.x + dim.W50 + 5

  -- "These coordinates will automatically be re-centered about the center of the polygon."
  o.hexagon = display.newPolygon(o.grid.gridGroup, o.center.x, o.center.y, dim.cellHex)
  o.hexagon:setFillColor(0,0,0)
  if SHOW_HEXAGON then
    o.hexagon:setStrokeColor(0.1)
    o.hexagon.strokeWidth = 2
  end

  o.hexagon:addEventListener('tap', o) -- table listener
  -- o.hexagon:addEventListener('touch', o) -- table listener

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

function Cell:calcHammingWeight()
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
  
  self.bitCount = hammingWeight(self.coins)
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

function Cell:colorComplete()
--[[
  When you modify a group's properties, all of its children are affected. 
  For example, if you set the alpha property on a display group, 
  each child's alpha value is multiplied by the new alpha of the group. 
  Groups automatically detect when a child's properties have changed 
  (position, rotation, etc.). Thus, on the next render pass, the child will re-render.
]]
  self.color = {0.8,0.8,0.8}
  if self.grpObjects then
    for _, o in ipairs(self.grpObjects) do
      if o.setStrokeColor then
        o:setStrokeColor(unpack(self.color))
      end
      if o.setFillColor then
        o:setFillColor(unpack(self.color))
      end
    end
  end
end

function Cell:tap(event)
  local dim = dimensions

  -- implement table listener for tap events
  -- print('tap', event.numTaps, self.x, self.y, self.coins, self.bitCount)

  local function afterRotate()
    self:createGraphics()
    if self.grid:isComplete() then
      self.grid:sound('complete')
      self.grid:colorComplete()
    elseif self.grid:isSectionComplete(self.section) then
      self.grid:sound('section')
    end
  end
--[[
  for _,cd in ipairs(dim.cellData) do
    if not self[cd.link] then print(self.x, self.y, 'no link to', cd.link) end
  end
]]
  if self.section == 0 then
    self.grid:sound('locked')
  elseif self.grp then
    self.grid:sound('tap')
    -- shift bits now (rather than in afterRotate) in case another tap happens while animating
    self:shiftBits()
    -- self.grp.anchorChildren = true
    -- self.grp.anchorX = 0
    -- self.grp.anchorY = 0
    transition.to(self.grp, {
      time = 100,
      rotation = 45,  -- enough to give illusion, no need for full 60 degrees
      onComplete = afterRotate,
    })
  end
  return true
end

local function isPointInTriangle(px,py,ax,ay,bx,by,cx,cy)
  assert(type(ax)=='number')
  assert(type(ay)=='number')
  assert(type(bx)=='number')
  assert(type(by)=='number')
  assert(type(cx)=='number')
  assert(type(cy)=='number')
  local v0 = {cx-ax,cy-ay}
  local v1 = {bx-ax,by-ay}
  local v2 = {px-ax,py-ay}

  local dot00 = (v0[1]*v0[1]) + (v0[2]*v0[2]);
  local dot01 = (v0[1]*v1[1]) + (v0[2]*v1[2]);
  local dot02 = (v0[1]*v2[1]) + (v0[2]*v2[2]);
  local dot11 = (v1[1]*v1[1]) + (v1[2]*v1[2]);
  local dot12 = (v1[1]*v2[1]) + (v1[2]*v2[2]);

  local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)

  local u = (dot11 * dot02 - dot01 * dot12) * invDenom
  local v = (dot00 * dot12 - dot01 * dot02) * invDenom

  return ((u >= 0) and (v >= 0) and (u + v < 1))
end

--[[
function Cell:touch(event)
  local dim = dimensions

  print(event.phase, event.x, event.y)

  if event.phase == 'began' and not self.touchCoords then
    -- building these as needed, and keeping them because they won't change
    self.touchCoords = {}
    for i = 1, 6 do
      local src = dim.cellTriangles[i]
      local dst = {}
      dst[1] = self.center.x
      dst[2] = self.center.y
      dst[3] = src[3] * 3 + self.center.x
      dst[4] = src[4] * 3 + self.center.y
      dst[5] = src[5] * 3 + self.center.x
      dst[6] = src[6] * 3 + self.center.y
      table.insert(self.touchCoords, dst)
    end
  end

  if not self.touchCoords then
    -- we began in a different cell
    return false
  end

  for i = 1, 6 do
    if isPointInTriangle(event.x, event.y, unpack(self.touchCoords[i])) then
      print(event.phase, 'in triangle', i)
    end
  end

end
]]
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

  local sWidth = dim.Q16
  local capRadius = math.floor(sWidth/2)

  if self.bitCount == 1 then
    local cd = table.find(dim.cellData, function(b) return self.coins == b.bit end)
    assert(cd)
    local line = display.newLine(self.grp,
      0,
      0, 
      cd.c2eX,
      cd.c2eY)
    line.strokeWidth = sWidth
    line:setStrokeColor(unpack(self.color))
    table.insert(self.grpObjects, line)

    local endcap = display.newCircle(self.grp, cd.c2eX, cd.c2eY, capRadius)
    endcap:setFillColor(unpack(self.color))
    table.insert(self.grpObjects, endcap)

    -- if math.fmod(self.section,3) == 1 then 
      local circle = display.newCircle(self.grp, 0, 0, dim.Q33)
      circle.strokeWidth = sWidth
      circle:setStrokeColor(unpack(self.color))
      circle:setFillColor(0,0,0)
      table.insert(self.grpObjects, circle)

    -- elseif math.fmod(self.section,3) == 2 then
    --   for _,sd in ipairs(dim.snowflakeLines) do
    --     local line = display.newLine(self.grp, 0, 0, sd.x, sd.y)
    --     line.strokeWidth = sWidth
    --     line:setStrokeColor(unpack(self.color))
    --     table.insert(self.grpObjects, line)

    --     local endcap = display.newCircle(self.grp, sd.x, sd.y, capRadius)
    --     endcap:setFillColor(unpack(self.color))
    --     table.insert(self.grpObjects, endcap)
    --   end
    -- else
    --   local hexagon = display.newPolygon(self.grp, 0, 0, dim.snowflakeHex)
    --   hexagon:setFillColor(0,0,0)
    --   hexagon:setStrokeColor(unpack(self.color))
    --   hexagon.strokeWidth = sWidth
    --   table.insert(self.grpObjects, hexagon)
    -- end
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
    if self.bitCount > 3 then
      table.insert(arr, arr[1])
    end
    assert(#arr > 1)
    -- print(
    --   arr[1].x, arr[1].y, 
    --   arr[2].x, arr[2].y)
    for n = 1, #arr-1 do
    -- use (off-)center and (off-)center as control points
      -- local av = 1.8  -- make the three-edges circles round
      local av = 3  -- make the three-edges circles triangular
      local cp1 = {x=(arr[n].x)/av, y=(arr[n].y)/av}
      local cp2 = {x=(arr[n+1].x)/av, y=(arr[n+1].y)/av}
      local curve = bezier.new(
        arr[n].x, arr[n].y, 
        cp1.x, cp1.y,
        cp2.x, cp2.y,
        arr[n+1].x, arr[n+1].y)
      local curveDisplayObject = curve:get()
      curveDisplayObject.strokeWidth = sWidth
      curveDisplayObject:setStrokeColor(unpack(self.color))
      self.grp:insert(curveDisplayObject)
      table.insert(self.grpObjects, curveDisplayObject)
    end
    for n = 1, #arr do
      local endcap = display.newCircle(self.grp, arr[n].x, arr[n].y, capRadius)
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