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

  Q33 = nil,
  Q10 = nil,
  Q20 = nil,

  X60 = nil,
  Y60 = nil,

  NORTHEAST = 1,
  EAST = 2,
  SOUTHEAST = 4,
  SOUTHWEST = 8,
  WEST = 16,
  NORTHWEST = 32,
  
  MASK = 63,

  cellData = nil,
  vertices = nil,
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
  
  o.Q33 = math.floor(Q/3.333333)
  o.Q10 = math.floor(Q/10)
  o.Q20 = math.floor(Q/5)

  -- https://gamedev.stackexchange.com/questions/18340/get-position-of-point-on-circumference-of-circle-given-an-angle
  local apothem = Q * math.cos(30 * math.pi / 180)  --  0.86602529158357
  o.X60 = math.floor(math.cos(60 * math.pi / 180) * apothem)
  o.Y60 = math.floor(math.sin(60 * math.pi / 180) * apothem)
  
  o.cellData = {
    { bit=o.NORTHEAST,  oppBit=o.SOUTHWEST, link='ne',  vsym=3,  c2eX=o.X60,    c2eY=-o.Y60, },
    { bit=o.EAST,       oppBit=o.WEST,      link='e',   vsym=2,  c2eX=o.W50,    c2eY=0,      },
    { bit=o.SOUTHEAST,  oppBit=o.NORTHWEST, link='se',  vsym=1,  c2eX=o.X60,    c2eY=o.Y60,  },
    { bit=o.SOUTHWEST,  oppBit=o.NORTHEAST, link='sw',  vsym=6,  c2eX=-o.X60,   c2eY=o.Y60,  },
    { bit=o.WEST,       oppBit=o.EAST,      link='w',   vsym=5,  c2eX=-o.W50,   c2eY=0,      },
    { bit=o.NORTHWEST,  oppBit=o.SOUTHEAST, link='nw',  vsym=4,  c2eX=-o.X60,   c2eY=-o.Y60, }
  }

  o.vertices = {
    0,-(o.H50),  -- N 1,2
    o.W50,-(o.H25), -- NE 3,4
    o.W50,o.H25,    -- SE 5,6
    0,o.H50,    -- S 7,8
    -(o.W50),o.H25, -- SW 9,10
    -(o.W50),-(o.H25),  -- NW 11,12
  }

  return o
end

return Dim