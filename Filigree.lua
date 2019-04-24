-- Filigree.lua

local Dim = require 'Dim'
local Grid = require 'Grid'

local physics = require 'physics'
physics.start()
physics.setGravity(0, 0.98)

local composer = require('composer')
local scene = composer.newScene()

local asteroidsTable = {}

local backGroup, gridGroup, shapesGroup

local gameLoopTimer = nil

local function createAsteroid()
  local newAsteroid = display.newCircle(backGroup, math.random(display.contentWidth), 0, math.random(10))
  newAsteroid:setFillColor(0.1,0.1,0.1)
  table.insert(asteroidsTable, newAsteroid)
  physics.addBody(newAsteroid, 'dynamic', { radius=40, bounce=0.8 } )
  newAsteroid:setLinearVelocity( math.random( 4,12 ), math.random( 2,6 ) )
  newAsteroid:applyTorque( math.random( -2,2 ) )
end

local function gameLoop()
 
  -- Create new asteroid
  createAsteroid()
-- Remove asteroids which have drifted off screen
  for i = #asteroidsTable, 1, -1 do
    local thisAsteroid = asteroidsTable[i]

    if ( thisAsteroid.x < -100 or
       thisAsteroid.x > display.contentWidth + 100 or
       thisAsteroid.y < -100 or
       thisAsteroid.y > display.contentHeight + 100 )
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
  local numY = 10

  -- each cell is Q * math.sqrt(3) wide
  -- we need space for numX + a half
  dimensions = Dim:new( math.floor(display.viewableContentWidth/(numX+0.5)/math.sqrt(3)) )
  -- get 2 vertical cells in cell height * 1.75
  -- numY = math.floor(display.viewableContentHeight / dim.H * (1.75/2) )

  -- for debugging the gaps between hexagons problem
  -- display.setDefault('background', 0.5,0.5,0.5)

  local grid = Grid:new(gridGroup, shapesGroup, numX, numY)
  grid:linkCells2()
  grid:placeCoins()
  grid:colorCoins()
  grid:jumbleCoins()
  grid:createGraphics()
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
    gameLoopTimer = timer.performWithDelay(500, gameLoop, 0)
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
    composer.removeScene('Filigree')
  end
end

function scene:destroy(event)
  local sceneGroup = self.view
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
