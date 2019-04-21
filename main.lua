-- main.lua

-- require 'Strict'

local composer = require 'composer'

print(_VERSION)
print('origin', display.screenOriginX, display.screenOriginY)
print('content', display.contentWidth, display.contentHeight)
print('pixels', display.pixelWidth, display.pixelHeight)
print('actual content', display.actualContentWidth, display.actualContentHeight)
print('viewable content', display.viewableContentWidth, display.viewableContentHeight)

print('maxTextureSize', system.getInfo('maxTextureSize'))

print('model', system.getInfo('model'))
print('environment', system.getInfo('environment'))

native.setProperty('windowTitleText', 'FILIGREE') -- Win32

math.randomseed(os.time())

-- for k,v in pairs( _G ) do
--   print( k , v )
-- end

if not table.contains then
  function table.contains(tab, val)
    for index, value in ipairs(tab) do
      if value == val then
        return true, index
      end
    end
    return false, 0
  end
end
print('table contains', type(table.contains))

if not table.shuffle then
  function table.shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end
end
print('table shuffle', type(table.shuffle))

composer.gotoScene('Splash')
