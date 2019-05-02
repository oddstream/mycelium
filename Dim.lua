-- Dim.lua

Dim = {
  Q = nil,

  W = nil,
  W75 = nil,
  W50 = nil,
  W25 = nil,

  H = nil,
  H75 = nil,
  H50 = nil,
  H25 = nil,

  Q50 = nil,
  Q33 = nil,
  Q20 = nil,
  Q16 = nil,
  Q10 = nil,
  Q8 = nil,

  NE = 1,
  EAST = 2,
  SE = 4,
  SW = 8,
  WEST = 16,
  NW = 32,
  
  MASK = 63,

  cellData = nil,
  -- snowflakeLines = nil,
  -- snowflakeHex = nil,
  cellHex = nil,
}

-- https://www.redblobgames.com/grids/hexagons/
-- when packed, 2 hex occupy 1.5 wide, not 2
-- and in pointy top, 2 vertical occupy 1.75, not 2

function Dim:new(Q)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.Q = Q

  o.W = math.floor(math.sqrt(3)*Q)
  o.W75 = math.floor(o.W*0.75)
  o.W50 = math.floor(o.W*0.5)
  o.W25 = math.floor(o.W*0.25)
  
  o.H = 2 * Q
  o.H75 = math.floor(o.H*0.75)
  o.H50 = math.floor(o.H*0.5)
  o.H25 = math.floor(o.H*0.25)
  
  o.Q50 = math.floor(Q/2)
  o.Q33 = math.floor(Q/3.333333)
  o.Q20 = math.floor(Q/5)
  o.Q16 = math.floor(Q*0.16)
  o.Q10 = math.floor(Q/10)
  o.Q8 = math.floor(Q*0.08)

  -- https://gamedev.stackexchange.com/questions/18340/get-position-of-point-on-circumference-of-circle-given-an-angle
  local apothem = Q * math.cos(30 * math.pi / 180)  --  0.86602529158357
  local X60 = math.floor(math.cos(60 * math.pi / 180) * apothem)
  local Y60 = math.floor(math.sin(60 * math.pi / 180) * apothem)
  
  o.cellData = {
    { bit=o.NE,  oppBit=o.SW,   link='ne',  vsym=3,  c2eX=X60,    c2eY=-Y60, },
    { bit=o.EAST,oppBit=o.WEST, link='e',   vsym=2,  c2eX=o.W50,  c2eY=0,    },
    { bit=o.SE,  oppBit=o.NW,   link='se',  vsym=1,  c2eX=X60,    c2eY=Y60,  },
    { bit=o.SW,  oppBit=o.NE,   link='sw',  vsym=6,  c2eX=-X60,   c2eY=Y60,  },
    { bit=o.WEST,oppBit=o.EAST, link='w',   vsym=5,  c2eX=-o.W50, c2eY=0,    },
    { bit=o.NW,  oppBit=o.SE,   link='nw',  vsym=4,  c2eX=-X60,   c2eY=-Y60, }
  }

  local apothem50 = Q/2 * math.cos(30 * math.pi / 180)
  local sx = math.floor(math.cos(60 * math.pi / 180) * apothem50)
  local sy = math.floor(math.sin(60 * math.pi / 180) * apothem50)
--[[
  o.snowflakeLines = {
    {x=sx, y=-sy},
    {x=o.W25, y=0},
    {x=sx, y=sy},
    {x=-sx, y=sy},
    {x=-o.W25, y=0},
    {x=-sx, y=-sy},
  }

  o.snowflakeHex = {
    sx, -sy,
    o.W25, 0,
    sx, sy,
    -sx, sy,
    -o.W25, 0,
    -sx, -sy,
  }
]]
  o.cellHex = {
    0,-(o.H50),  -- N 1,2
    o.W50,-(o.H25), -- NE 3,4
    o.W50,o.H25,    -- SE 5,6
    0,o.H50,    -- S 7,8
    -(o.W50),o.H25, -- SW 9,10
    -(o.W50),-(o.H25),  -- NW 11,12
  }

  local x = o.cellHex
  o.cellTriangles = {
    {0,0, x[1],x[2], x[3],x[4]}, -- N to NE
    {0,0, x[3],x[4], x[5],x[6]}, -- NE to SE
    {0,0, x[5],x[6], x[7],x[8]},
    {0,0, x[7],x[8], x[9],x[10]},
    {0,0, x[9],x[10], x[11],x[12]},
    {0,0, x[11],x[12], x[1],x[2]}
  }

  assert(#o.cellTriangles==6)

  return o
end

return Dim