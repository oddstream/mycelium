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

--[[
local function createAsteroid()
  -- local newAsteroid = display.newCircle(backGroup, math.random(display.contentWidth), 0, math.random(10))
  local newAsteroid = display.newCircle(backGroup, math.random(display.contentWidth), math.random(display.contentHeight), math.random(10))
  if grid.complete then
    newAsteroid:setFillColor(1,1,1)
  else
    newAsteroid:setFillColor(0.2,0.2,0.2)
  end
  table.insert(asteroidsTable, newAsteroid)
  physics.addBody(newAsteroid, 'dynamic', { density=0.3, radius=10, bounce=0.9 } )
  -- newAsteroid:setLinearVelocity( math.random( -100,100 ), math.random( 0,100 ) )
  newAsteroid:setLinearVelocity( math.random( -100,100 ), math.random( -100,100 ) )
  -- newAsteroid:applyTorque( math.random( -10,10 ) )
end
]]
local function createAsteroid2(x, y, color)
  local newAsteroid = display.newCircle(backGroup, x, y, math.random(10))
  table.insert(asteroidsTable, newAsteroid)
  physics.addBody(newAsteroid, 'dynamic', { density=0.3, radius=10, bounce=0.9 } )
  if grid.complete then
    newAsteroid:setFillColor(unpack(color))
    newAsteroid:setLinearVelocity( math.random( -100,100 ), math.random( -100,100 ) )
  else
    newAsteroid:setFillColor(unpack(color))
    newAsteroid:setLinearVelocity( math.random( -25,25 ), math.random( -25,25 ) )
  end
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

  -- -- Create new asteroid
  -- if grid.complete then
  --   for a = 1, 3 do
  --     createAsteroid()
  --   end
  -- else
  --   createAsteroid()
  -- end

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
  grid:linkCells2()
  grid:placeCoins()
  grid:colorCoins()
  grid:jumbleCoins()
  grid:createGraphics()

  local resetButton = widget.newButton({
    id = 'reset',
    x = display.contentCenterX,
    y = display.contentHeight - 100,
    onRelease = function() grid:reset() end,
    label = 'reset',
    labelColor = { default={0,0,0}, over={0,0,0} },
    font = native.SystemFontBold,
    fontSize = 36,

    shape = 'circle',
    radius = 50,
    fillColor = { default={0.8,0.8,0.8}, over={0.5,0.5,0.5} }
  })
  sceneGroup:insert(resetButton)
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
