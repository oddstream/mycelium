-- GameState.lua

local json = require('json')

local GameState = {
  level = 0,
}
GameState.__index = GameState

local filePath = system.pathForFile('gameState.json', system.DocumentsDirectory)

function GameState.new()
  local o = {}
  setmetatable(o, GameState)

  o.level = 1
  o:read()

  return o
end

function GameState:read()
  local file = io.open(filePath, 'r')
  if file then
    local contents = file:read('*a')
    io.close(file)
    print('state loaded from file', filePath, contents)
    local state = json.decode(contents)
    if state and state.level then
      self.level = state.level
    end
  end
end

function GameState:write()
  local file = io.open(filePath, 'w')
  if file then
    file:write(json.encode(self))
    print('state written to', filePath)
    io.close(file )
  end
end

function GameState:advanceLevel()
  self.level = self.level + 1
  self:write()
end


return GameState
