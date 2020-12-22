-- Mycelium.lua

local Grid = require 'Grid'

local physics = require 'physics'
physics.start()
physics.setGravity(0, 0.01)  -- 9.8
trace('physics.engineVersion', physics.engineVersion)

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

local sporesTable = {}

local sporesGroup, gridGroup, shapesGroup

local gameLoopTimer = nil

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
  local radius = math.random(6)
  local newSpore = display.newCircle(sporesGroup, x, y, radius)
  physics.addBody(newSpore, 'dynamic', { density=0.1, radius=radius, bounce=0.9 } )
  if grid.complete then
    newSpore:setLinearVelocity( math.random( -100,100 ), math.random( -100,100 ) )
  else
    newSpore:setLinearVelocity( math.random( -20,20 ), math.random( -20,20 ) )
  end
  newSpore.angularVelocity = 90
  newSpore:setFillColor(unpack(color))
  table.insert(sporesTable, newSpore)
end

local function gameLoop()

  if not grid.complete and math.random() < 0.9 then
    return
  end

  grid:iterator(function(c)
    if c.bitCount == 1 then
      createSpore(c.center.x, c.center.y, c.color)
    end
  end)

  -- Remove spores which have drifted off screen
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

  grid.newButton = widget.newButton({
    id = 'new',
    x = display.contentCenterX,
    y = display.contentHeight - 100,
    onRelease = function()
      grid:fadeOut()
      timer.performWithDelay(1000, function()
        grid:reset()
        grid:newLevel()
      end, 1)
    end,

    label = '»',
    labelColor = { default={ 1, 1, 1 }, over={ 0.2, 0.2, 0.2 } },
    font = native.systemFontBold,
    fontSize = 100,
    textOnly = true,

    -- sheet = imageSheet,
    -- defaultFrame = 1,
    -- overFrame = 2,
  })
  grid.newButton:setFillColor(0.2,0.2,0.2)
  sceneGroup:insert(grid.newButton)

  grid:newLevel()

end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
    gameLoopTimer = timer.performWithDelay(1000, gameLoop, 0)
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
