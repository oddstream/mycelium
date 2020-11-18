-- Util.lua

local Util = {}
Util.__index = Util

--[[
  Linear interpolation. The idea is very simple, you have 2 values, and you want to “walk” between those values by a factor.
  If you pass a factor of 0, you are pointing to the beginning of the walk so the value is equal to start.
  If you pass a factor of 1, you are pointing to the end of the walk so the value is equal to end.
  Any factor between 0 and 1 will add a (1-factor) of start argument and a factor of end argument.
  (e.g with start 0 and end 10 with a factor 0.5 you will have a 5, so the half of the path)
]]
function Util.lerp(start, finish, factor)
  -- return start*(1-factor) + finish*factor
  -- Precise method, which guarantees v = v1 when t = 1.
  -- https://en.wikipedia.org/wiki/Linear_interpolation
  return (1 - factor) * start + factor * finish;
end

--[[
  The opposite of lerp. Instead of a range and a factor, we give a range and a value to find out the factor.
]]
function Util.normalize(start, finish, value)
  return (value - start) / (finish - start)
end

--[[
  converts a value from the scale [fromMin, fromMax] to a value from the scale[toMin, toMax].
  It’s just the normalize and lerp functions working together.
]]
function Util.mapValue(value, fromMin, fromMax, toMin, toMax)
  return Util.lerp(toMin, toMax, Util.normalize(fromMin, fromMax, value))
end

function Util.clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

function Util.isPointInTriangle(px,py,ax,ay,bx,by,cx,cy)
  -- assert(type(ax)=='number')
  -- assert(type(ay)=='number')
  -- assert(type(bx)=='number')
  -- assert(type(by)=='number')
  -- assert(type(cx)=='number')
  -- assert(type(cy)=='number')
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

function Util.sound(name)
  -- build for Win32 to test the sound, because playing sounds in the simulator crashes the sound driver
  if system.getInfo('environment') == 'simulator' then
    -- trace('SOUND', name)
  else
    -- trace('SOUND', name, type(_G.TWITTY_SOUNDS[name]))
    local handle
    if type(_G.MYCELIUM_SOUNDS[name]) == 'table' then
      handle = _G.MYCELIUM_SOUNDS[name][math.random(1, #_G.MYCELIUM_SOUNDS[name])]
    elseif type(_G.MYCELIUM_SOUNDS[name]) == 'userdata' then
      handle = _G.MYCELIUM_SOUNDS[name]
    end
    if handle then
      audio.play(handle)
    end
  end
end

return Util
