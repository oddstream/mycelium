-- Mycelium.lua

local Grid = require 'Grid'

local physics = require 'physics'
physics.start()
physics.setGravity(0, 0)  -- 9.8
trace('physics.engineVersion', physics.engineVersion)

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

local sporesGroup, gridGroup, shapesGroup

local gameLoopTimer = nil
local sporesTable = {}

local grid = nil

--[[
local sheetOptions =
{
  frames =
  {
    { -- 1 autorenew
      x = 0,
      y = 0,
      width = 100,
      height = 100
    },
    { -- 2 autorenew rotated
      x = 0,
      y = 100,
      width = 100,
      height = 100
    },
  }
}

local imageSheet = graphics.newImageSheet('icons.png', sheetOptions)
]]

--[[
local function gpgsListener(event)
  Util.toast(event.name)
  trace(event.name, event.isError, event.errorCode, event.errorMessage)
end
]]

local function createSpore(x, y, color)
  local newSpore
  local r= math.random()
  if r < 0.333 then
    newSpore = display.newCircle(sporesGroup, x, y, 4)
    newSpore:setFillColor(unpack(color))
    newSpore:setStrokeColor(unpack(color))
    newSpore.strokeWidth = 2
  elseif r < 0.666 then
    newSpore = display.newCircle(sporesGroup, x, y, 2)
    newSpore:setFillColor(unpack(color))
    newSpore:setStrokeColor(unpack(color))
    newSpore.strokeWidth = 1
  else
    newSpore = display.newLine(sporesGroup, x, y, x + math.random(-10,10), y + math.random(-10,10))
    newSpore.strokeWidth = 2
    newSpore:setStrokeColor(unpack(color))
  end
  physics.addBody(newSpore, 'dynamic', { density=0.1, radius=10, bounce=0.9 } )
  newSpore:setLinearVelocity( math.random( -50,50 ), math.random( -50,50 ) )
  newSpore.angularVelocity = math.random(0, 100)
  table.insert(sporesTable, newSpore)
end

local function gameLoop()

  -- each loop shape spawns a spore
  grid:iterator(function(c)
    if c.bitCount == 1 then
      createSpore(c.center.x, c.center.y, c.color)
    end
  end)

  -- remove spores which have drifted off screen
  for i = #sporesTable, 1, -1 do
    local thisSpore = sporesTable[i]

    if ( thisSpore.x < 0 or
       thisSpore.x > display.contentWidth or
       thisSpore.y < 0 or
       thisSpore.y > display.contentHeight )
    then
      display.remove(thisSpore)
      table.remove(sporesTable, i)
    end
  end
end

function scene:create(event)
  local sceneGroup = self.view

  gridGroup = display.newGroup()
  sceneGroup:insert(gridGroup)

  sporesGroup = display.newGroup()
  sceneGroup:insert(sporesGroup)

  shapesGroup = display.newGroup()
  sceneGroup:insert(shapesGroup)

  grid = Grid.new(gridGroup, shapesGroup)

  grid:newLevel()

end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen

    -- tweak the density of spores by changing the frequency of the game loop
    -- 1000 is crowded, 5000 is sparse
    gameLoopTimer = timer.performWithDelay(2000, gameLoop, 0)
  end
end

function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
    if gameLoopTimer then timer.cancel(gameLoopTimer) end
  elseif phase == 'did' then
    -- Code here runs immediately after the scene goes entirely off screen
    composer.removeScene('Mycelium')
  end
end

function scene:destroy(event)
  local sceneGroup = self.view

  grid:destroy()

  -- Code here runs prior to the removal of scene's view
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener('create', scene)
scene:addEventListener('show', scene)
scene:addEventListener('hide', scene)
scene:addEventListener('destroy', scene)
-- -----------------------------------------------------------------------------------

return scene
