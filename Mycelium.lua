-- MyNet.lua

local Dim = require 'Dim'
local Grid = require 'Grid'

local physics = require 'physics'
physics.start()
physics.setGravity(0, 0)  -- 9.8
print(physics.engineVersion)

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

local asteroidsTable = {}

local backGroup, gridGroup, shapesGroup

local gameLoopTimer = nil

local grid = nil

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
    { -- 2 blank
      x = 0,
      y = 100,
      width = 100,
      height = 100
    },
  }
}

local imageSheet = graphics.newImageSheet('icons.png', sheetOptions)

local function createAsteroid2(x, y, color)
  local newAsteroid = display.newCircle(backGroup, x, y, math.random(10))
  table.insert(asteroidsTable, newAsteroid)
  physics.addBody(newAsteroid, 'dynamic', { density=0.3, radius=10, bounce=0.9 } )
  if grid.complete then
    newAsteroid:setLinearVelocity( math.random( -100,100 ), math.random( -100,100 ) )
  else
    newAsteroid:setLinearVelocity( math.random( -25,25 ), math.random( -25,25 ) )
  end
  newAsteroid:setFillColor(unpack(color))
end

local function gameLoop()

  if not grid.complete and math.random() < 0.9 then
    return
  end

  grid:iterator(function(c)
    if c.bitCount == 1 then
      createAsteroid2(c.center.x, c.center.y, c.color)
    end
  end)

  -- Remove asteroids which have drifted off screen
  for i = #asteroidsTable, 1, -1 do
    local thisAsteroid = asteroidsTable[i]

    if ( thisAsteroid.x < 0 or
       thisAsteroid.x > display.contentWidth or
       thisAsteroid.y < 0 or
       thisAsteroid.y > display.contentHeight )
    then
      display.remove( thisAsteroid )
      table.remove( asteroidsTable, i )
    end
  end
end

function scene:create(event)
  local sceneGroup = self.view

  gridGroup = display.newGroup()
  sceneGroup:insert(gridGroup)

  backGroup = display.newGroup()
  sceneGroup:insert(backGroup)

  shapesGroup = display.newGroup()
  sceneGroup:insert(shapesGroup)

  local numX = 5
  local numY = (numX*2) - 1  -- odd number for mirror

  -- each cell is Q * math.sqrt(3) wide
  -- we need space for numX + a half
  dimensions = Dim:new( math.floor(display.viewableContentWidth/(numX+0.5)/math.sqrt(3)) )
  -- get 2 vertical cells in cell height * 1.75
  -- numY = math.floor(display.viewableContentHeight / dim.H * (1.75/2) )

  -- for debugging the gaps between hexagons problem
  -- display.setDefault('background', 0.5,0.5,0.5)

  grid = Grid:new(gridGroup, shapesGroup, numX, numY)

  grid:newLevel()

  local function gridReset()
    grid:reset() -- calls fadeIn()
  end

  local newButton = widget.newButton({
    id = 'new',
    x = display.contentCenterX,
    y = display.contentHeight - 100,
    onRelease = function()
      grid:fadeOut() 
      timer.performWithDelay(1000, gridReset, 1)
    end,

    sheet = imageSheet,
    defaultFrame = 1,
    overFrame = 2,
  })
  sceneGroup:insert(newButton)
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
    gameLoopTimer = timer.performWithDelay(1000, gameLoop, 0)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
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
    composer.removeScene('MyNet')
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
