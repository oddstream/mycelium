-- Filigree.lua

local Dim = require 'Dim'
local Cell = require 'Cell'
local Grid = require 'Grid'

local composer = require('composer')
local scene = composer.newScene()

function scene:create(event)
  local sceneGroup = self.view

  local gridGroup = display.newGroup()
  sceneGroup:insert(gridGroup)

  local shapesGroup = display.newGroup()
  sceneGroup:insert(shapesGroup)

  local numX = 5
  local numY = 8

  dim = Dim:new( math.floor(display.viewableContentWidth/numX/1.5) )
  assert(dim)
  
  local grid = Grid:new(gridGroup, shapesGroup, numX, numY)
  grid:linkCells()
  grid:placeCoins()
  grid:createGraphics()
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
  end
end

function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
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
