-- Cell class

local bit = require 'plugin.bit'
local bezier = require 'Bezier'
local physics = require 'physics'

local Util = require 'Util'

local PLACE_COIN_CHANCE = 0.3333 / 2
-- local SHOW_HEXAGON = false

local Cell = {
  -- prototype object
  grid = nil,      -- grid we belong to
  x = nil,        -- column 1 .. width
  y = nil,        -- row 1 .. height
  center = nil,   -- point table, screen coords

  ne, e, se, sw, w, nw = nil, nil, nil, nil, nil, nil,

  coins = 0,
  bitCount = 0,      -- hammingWeight
  color = nil,       -- e.g. {0,1,0}
  section = nil,     -- number of section (0 if locked)

  hexagon = nil,     -- ShapeObject for outline
  grp = nil,         -- display group to put shapes in

  touchCoords = nil,
  touchPos = nil,
}
Cell.__index = Cell

function Cell.new(grid, x, y)

  local o = {}
  setmetatable(o, Cell)

  o.grid = grid
  o.x = x
  o.y = y

  -- calculate where the screen coords center point will be
  -- odd-r horizontal layout shoves odd rows half a hexagon width to the right
  -- no '&' operator in Lua 5.1, hence math.fmod(y,2) == 1

  local dim = o.grid.dim

  -- o.center = {x=(x*grid.w) + (grid.w/2), y=(y * grid.h75) + (grid.h/2) - grid.h + 120}
  o.center = {x=(x*dim.W)-(dim.W), y=(y*dim.H75)}
  if math.fmod(y,2) == 1 then
    o.center.x = o.center.x + dim.W50
  end
  -- can't have the center being on the edge of the screen, it would clip left of first cell
  o.center.x = o.center.x + dim.W50 + 5

  -- "These coordinates will automatically be re-centered about the center of the polygon."
  o.hexagon = display.newPolygon(o.grid.gridGroup, o.center.x, o.center.y, dim.cellHex)
  o.hexagon:setFillColor(unpack(o.grid.backgroundColor))

  -- if SHOW_HEXAGON then
  if _G.gameState.level == 1 then
    o.hexagon:setStrokeColor(0.1)
    o.hexagon.strokeWidth = 2
  else
    o.hexagon:setStrokeColor(0)
    o.hexagon.strokeWidth = 0
  end

  o.hexagon:addEventListener('tap', o) -- table listener
  o.hexagon:addEventListener('touch', o) -- table listener

  return o
end

function Cell:reset()
  self.coins = 0
  self.color = nil
  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
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
  local dim = self.grid.dim

  num = num or 1
  while num > 0 do
    if bit.band(self.coins, 32) == 32 then
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

function Cell:unshiftBits(num)
  local function unshift(n)
    if bit.band(n, 1) == 1 then
      n = bit.rshift(n, 1)
      n = bit.bor(n , 32)
    else
      n = bit.rshift(n, 1)
    end
    return n
  end

  -- assert(unshift(1) == 32)
  -- assert(unshift(2) == 1)
  -- assert(unshift(4) == 2)
  -- assert(unshift(32) == 16)
  -- assert(unshift(63) == 63)

  num = num or 1
  while num > 0 do
    self.coins = unshift(self.coins)
    num = num - 1
  end
end

function Cell:isComplete(section)
  local dim = self.grid.dim

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
  local dim = self.grid.dim

  for _,cd in ipairs(dim.cellData) do
    if math.random() < PLACE_COIN_CHANCE then
      if self[cd.link] then
        self.coins = bit.bor(self.coins, cd.bit)
        self[cd.link].coins = bit.bor(self[cd.link].coins, cd.oppBit)

        if mirror then
          local m_cd = dim.cellData[cd.vsym]
          -- assert(m_cd)
          -- assert(m_cd.bit)
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
  local moves = 0

  if system.getInfo('environment') == 'simulator' then
    if self.bitCount == 1 then
      moves = 1
    end
  else
    moves = math.random(5)
  end

  self:unshiftBits(moves)

  return moves
end

function Cell:colorConnected(color, section)
  local dim = self.grid.dim

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

--[[
  When you modify a group's properties, all of its children are affected.
  For example, if you set the alpha property on a display group,
  each child's alpha value is multiplied by the new alpha of the group.
  Groups automatically detect when a child's properties have changed
  (position, rotation, etc.). Thus, on the next render pass, the child will re-render.
]]

--[[
function Cell:colorComplete()
  self.color = self.grid.completeColor
  if self.grp then
    -- local dim = self.grid.dim
    for i = 1, self.grp.numChildren do
      local o = self.grp[i]
      if o.setStrokeColor then
        -- lines
        o:setStrokeColor(unpack(self.color))
      end
      if o.setFillColor then
        -- end caps (radius dim.Q20/2) and circles (radius dim.Q33)
        if o.myceliumObjectType == 'endcap' then
          o:setFillColor(unpack(self.color))
        end
      end
    end
  end
end
]]

function Cell:rotate(dir)

  local function _afterRotate()
    self:createGraphics(1)
    if self.grid:isSectionComplete(self.section) then
      Util.sound('section')
      self.grid:hideSection(self.section)
    end
    if self.grid:isComplete() then
      Util.sound('complete')
      -- self.grid:colorComplete()
      _G.gameState:advanceLevel()
    end
  end

  dir = dir or 'clockwise'

  if self.section == 0 then
    Util.sound('locked')
  elseif self.grp then
    Util.sound('tap')
    -- shift bits now (rather than in _afterRotate) in case another tap happens while animating
    local degrees
    if dir == 'clockwise' then
      self:shiftBits()
      degrees = 45
    elseif dir == 'anticlockwise' then
      self:unshiftBits()
      degrees = -45
    end

    transition.to(self.grp, {
      time = 100,
      rotation = degrees,
      transition = easing.linear,
      onComplete = _afterRotate,
    })
  end
end

function Cell:tap(event)
  -- trace('tap', event.numTaps, self.x, self.y, self.coins, self.bitCount)
  if self.grid:isComplete() then
    -- print('completed', event.name, event.numTaps, self.x, self.y, self.coins, self.bitCount)
    self.grid:reset()
    self.grid:newLevel()
  else
    self:rotate('clockwise')
  end
  return true
end

function Cell:touch(event)
  local dim = self.grid.dim

  -- trace(event.phase, event.x, event.y)
  local target = event.target

  if event.phase == 'began' then
    -- tell corona that following touches come to this display object
    display.getCurrentStage():setFocus(target)
    -- remember that this object has the focus
    target.hasFocus = true

    -- building these as needed, the touched cell has these coords
    self.touchCoords = {}
    for i = 1, 6 do
      local src = dim.cellTriangles[i]
      local dst = {}
      dst[1] = self.center.x
      dst[2] = self.center.y
      dst[3] = src[3] + self.center.x
      dst[4] = src[4] + self.center.y
      dst[5] = src[5] + self.center.x
      dst[6] = src[6] + self.center.y
      table.insert(self.touchCoords, dst)
      -- assert(#dst==6)
    end

  end

  if self.touchCoords then
    for i = 1, 6 do
      if Util.isPointInTriangle(event.x, event.y, unpack(self.touchCoords[i])) then
        -- trace(event.phase, 'in triangle', i)
        -- local c = dim.cellTriangles[i]
        -- local tri1 = display.newLine(self.grp, 0,0, c[3], c[4])
        -- tri1.strokeWidth = 2
        -- local tri2 = display.newLine(self.grp, 0,0, c[5], c[6])
        -- tri2.strokeWidth = 2

        if event.phase == 'began' then
          self.touchPos = i
        elseif event.phase == 'moved' and self.touchPos then
          if (i == self.touchPos + 1) or (self.touchPos == 6 and i == 1) then
            self:rotate('clockwise')
            self.touchPos = i
          elseif (i == self.touchPos - 1) or (self.touchPos == 1 and i == 6) then
            self:rotate('anticlockwise')
            self.touchPos = i
          end
        end
        break
      end
    end
  end

  if event.phase == 'ended' then
    -- stop being responsible for touches
    display.getCurrentStage():setFocus(nil)
    -- remember this object no longer has the focus
    target.hasFocus = false

    self.touchCoords = nil
    self.touchPos = nil
  end

  return true -- we handled event
end

function Cell:createGraphics(scale)
  local dim = self.grid.dim

  scale = scale or 1.0

  -- gotcha the 4th argument to set color function ~= the .alpha property
  -- blue={0,0,1}
  -- trace(table.unpack(blue), 3)
  -- > 0 6
--[[
  local colora = {}
  for k,v in pairs(self.color) do colora[k] = v end
  assert(#colora==3)
  table.insert(colora, alpha)
  assert(#colora==4)
]]
  if self.grp then
    self.grp:removeSelf()
    self.grp = nil
  end

  if 0 == self.coins then
    return
  end

  self.grp = display.newGroup()
  -- center the group on the center of the hexagon, otherwise it's at 0,0
  self.grp.x = self.center.x
  self.grp.y = self.center.y
  self.grid.shapesGroup:insert(self.grp)

  local sWidth = dim.Q20
  local capRadius = sWidth/2

  if self.bitCount == 1 then

    local cd = table.find(dim.cellData, function(b) return self.coins == b.bit end)
    assert(cd)

    local line = display.newLine(self.grp,
      cd.c2eX / 2.5,
      cd.c2eY / 2.5,
      cd.c2eX,
      cd.c2eY)
    line.strokeWidth = sWidth
    line.alpha = 1
    line.xScale, line.yScale = scale, scale
    line:setStrokeColor(unpack(self.color))
    line.myceliumObjectType = 'line'

    local endcap = display.newCircle(self.grp, cd.c2eX, cd.c2eY, capRadius)
    endcap:setFillColor(unpack(self.color))
    endcap.alpha = 1
    endcap.xScale, endcap.yScale = scale, scale
    endcap.myceliumObjectType = 'endcap'

    local circle = display.newCircle(self.grp, 0, 0, dim.Q33)
    circle.strokeWidth = sWidth
    circle.alpha = 1
    circle.xScale, circle.yScale = scale, scale
    circle:setStrokeColor(unpack(self.color))
    circle:setFillColor(unpack(self.grid.backgroundColor))
    circle.myceliumObjectType = 'circle'

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

--[[
  with self.bitCount > 3
  three consective bits should produce same pattern (rotated) no matter where they occur in coins:
    000111
    001110
    011100
    111000
    110001 - ugly
    100011 - ugly
  hence self.bitCount > 2
]]
    local arr = {}
    for _,cd in ipairs(dim.cellData) do
      if bit.band(self.coins, cd.bit) == cd.bit then
        table.insert(arr, {x=cd.c2eX, y=cd.c2eY})
      end
    end
    -- close path for better aesthetics
    if self.bitCount > 2 then
      table.insert(arr, arr[1])
    end

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
      curveDisplayObject.alpha = 1
      curveDisplayObject.xScale, curveDisplayObject.yScale = scale, scale
      curveDisplayObject.myceliumObjectType = 'curve'
      self.grp:insert(curveDisplayObject)
    end

    for n = 1, #arr do
      local endcap = display.newCircle(self.grp, arr[n].x, arr[n].y, capRadius)
      endcap:setFillColor(unpack(self.color))
      endcap.alpha = 1
      endcap.xScale, endcap.yScale = scale, scale
      endcap.myceliumObjectType = 'endcap'
    end
  end
end

--[[
function Cell:dilateCircle()
  if self.grp and self.bitCount == 1 then
    local circle = self.grp[3]
    circle.path.radius = circle.path.radius * 0.5
  end
end
]]

function Cell:fadeIn()
  -- used to use fadeIn/Out, but couldn't figure out which blendMode to use
  -- to stop endcaps and shape overlaps becoming visible during fade
  if self.grp then
    for i=1, self.grp.numChildren do
      local o = self.grp[i]
      transition.scaleTo(o, {xScale=1, yScale=1, time=500})
    end
  end
end

function Cell:fadeOut()
  if self.grp then
    for i=1, self.grp.numChildren do
      local o = self.grp[i]
      transition.scaleTo(o, {xScale=0.1, yScale=0.1, time=500})
      physics.addBody(o, 'dynamic', { density=0.1, radius=10, bounce=0.9 } )
      -- move slowly so not so many go off screen
      o:setLinearVelocity( math.random( -10,10 ), math.random( -10,10 ) )
      o.angularVelocity = math.random(0, 100)
    end
  end
end

--[[
function Cell:destroy()
end
]]

return Cell