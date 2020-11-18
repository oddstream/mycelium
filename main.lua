-- main.lua

-- require 'Strict'

local pprint = require 'pprint'
local composer = require 'composer'

local GameState = require 'GameState'

function _G.trace(...)
  if system.getInfo('environment') == 'simulator' then
    local lst = {...}
    if #lst == 1 and type(lst[1]) == 'table' then
      pprint(lst[1])  -- doesn't take varargs
    else
      print(...)
    end
  end
end

if system.getInfo('platform') == 'win32' or system.getInfo('environment') == 'simulator' then
  print('_VERSION', _VERSION)
  print('screenOrigin', display.screenOriginX, display.screenOriginY)
  print('safeAreaInsets', display.getSafeAreaInsets())
  print('content', display.contentWidth, display.contentHeight)
  print('actualContent', display.actualContentWidth, display.actualContentHeight)
  print('safeActualContent', display.safeActualContentWidth, display.safeActualContentHeight)
  print('viewableContent', display.viewableContentWidth, display.viewableContentHeight)
  print('pixelWidth/Height', display.pixelWidth, display.pixelHeight)

  -- print('maxTextureSize', system.getInfo('maxTextureSize'))

  print('platformName', system.getInfo('platformName'))
  print('architectureInfo', system.getInfo('architectureInfo'))
  print('model', system.getInfo('model'))

  -- print('androidDisplayApproximateDpi', system.getInfo('androidDisplayApproximateDpi'))
end

_G.onTablet = system.getInfo('model') == 'iPad'
if not _G.onTablet then
  local approximateDpi = system.getInfo('androidDisplayApproximateDpi')
  if approximateDpi then
    local width = display.pixelWidth / approximateDpi
    local height = display.pixelHeight / approximateDpi
    if width > 4.5 and height > 7 then
      _G.onTablet = true
    end
  end
end

native.setProperty('windowTitleText', 'Mycelium Loops') -- Win32

-- math.randomseed(os.time())

-- our one global, an object containing useful precalculated _G.DIMENSIONS
_G.DIMENSIONS = {}

_G.MYCELIUM_SOUNDS = {
  tap = audio.loadSound('assets/sound56.wav'),
  section = audio.loadSound('assets/sound63.wav'),
  complete = audio.loadSound('assets/complete.wav'),
  locked = audio.loadSound('assets/sound61.wav'),
}

-- for k,v in pairs( _G ) do
--   print( k , v )
-- end

if not _G.table.find then
  function _G.table.find(tbl, fn)
    for _,v in ipairs(tbl) do
      if fn(v) then
        return v
      end
    end
    return nil
  end
end
-- print('table find', type(table.find))

if not _G.table.filter then
  _G.table.filter = function(t, filterIter)
    local out = {}

    for k, v in pairs(t) do
      if filterIter(v, k, t) then table.insert(out, v) end
    end

    return out
  end
end
-- print('table filter', type(table.filter))

_G.gameState = GameState:new()

composer.gotoScene('Splash', {effect='fade', params={scene='Mycelium'}})
