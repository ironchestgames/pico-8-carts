pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- shipnickers 1.0
-- by ironchest games

--[[
 -- fix boss collision crash
 -- fix psets
 -- add boss weapon sfx channel
 -- add "new" blink to hangar
 -- unify game event code
 -- add game event sfx
 -- fix mines sfx
 -- add splash
--]]

cartdata'ironchestgames_shipnickers_v1-dev4'

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable btnp auto-repeat

pal(0,129,1)
pal(split'1,136,139,141,5,6,7,8,9,10,138,12,13,14,134',1)

local function unlock(_n)
 poke(0x5e00+_n,1)
end

local function isunlocked(_n)
 return peek(0x5e00+_n) == 1
end

local function getlocked()
 local _locked={}
 for _i=0,99 do
  if not isunlocked(_i) then
   add(_locked,_i)
  end
 end
 return _locked
end

-- utils
local function clone(_t)
 local _result={}
 for _k,_v in pairs(_t) do
  _result[_k]=_v
 end
 return _result
end

local function mycount(_t)
 local _c=0
 for _ in pairs(_t) do
  _c+=1
 end
 return _c
end

local function mr(_t1,_t2)
 for _k,_v in pairs(_t2) do
  _t1[_k]=_v
 end
 return _t1
end

local function dist(x1,y1,x2,y2)
 return sqrt(((x2-x1)^2)+((y2-y1)^2))
end

local function s2t(_t)
 local _result,_kvstrings={},split(_t)
 for _kvstring in all(_kvstrings) do
  local _kvpair=split(_kvstring,'=')
  local _value=_kvpair[2]
  for _i,_v in ipairs(split'true,false,nil') do
   if _value == _v then
    _value=({true,false})[_i]
   end
  end
  if type(_value) == 'string' then
   _value=sub(_value,2,#_value-1)
  end
  _result[_kvpair[1]]=_value
 end
 return _result
end

local function mrs2t(_s,_t)
 return mr(s2t(_s),_t)
end

local function ispointinsideaabb(_x,_y,_ax,_ay,_ahw,_ahh)
 return _x > _ax-_ahw and _x < _ax+_ahw and _y > _ay-_ahh and _y < _ay+_ahh
end

local function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh
end

-- globals
local ships,bullets,stars,ps,psfollow,bottomps,enemies,enemybullets,boss,cargos,lockedpercentage

local hangar={
 [0]=mrs2t's=0,bulletcolor=9,primary="missile",secondary="missile",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="7;14;8",exhausts="-1;3;0;3"',
 mrs2t's=1,bulletcolor=12,primary="missile",secondary="boost",secondaryshots=3,psets="3;5;2;3;3;8",guns="2;0;5;0",exhaustcolors="7;10;9",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=2,bulletcolor=10,primary="missile",secondary="mines",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4"',
 mrs2t's=3,bulletcolor=10,primary="missile",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="7;9;4",exhausts="-1;3;0;3"',
 mrs2t's=4,bulletcolor=15,primary="missile",secondary="cloak",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="10;11;15",exhausts="-1;3;0;3"',
 mrs2t's=5,bulletcolor=14,primary="missile",secondary="blink",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;0;6;0",exhaustcolors="14;8;2",exhausts="-1;3;0;3"',
 mrs2t's=6,bulletcolor=15,primary="missile",secondary="flak",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="10;9;5",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4"',
 mrs2t's=7,bulletcolor=12,primary="missile",secondary="beam",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=8,bulletcolor=12,primary="missile",secondary="burner",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=9,bulletcolor=12,primary="missile",secondary="bolt",secondaryshots=3,psets="3;6;11;3;4;10",guns="0;3;7;3",exhaustcolors="7;12;15",exhausts="-1;4;0;4"',

 mrs2t's=10,bulletcolor=11,primary="boost",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="2;2;5;2",exhaustcolors="7;6;13",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=11,bulletcolor=3,primary="boost",secondary="boost",secondaryshots=3,psets="0;0;9;0;0;9",guns="1;0;6;0",exhaustcolors="11;12;5",exhausts="-2;3;-1;3;0;3;1;3"',
 mrs2t's=12,bulletcolor=9,primary="boost",secondary="mines",secondaryshots=3,psets="3;4;9;3;2;10",guns="1;0;6;0",exhaustcolors="11;3;4",exhausts="-4;4;-3;4;2;4;3;4"',
 mrs2t's=13,bulletcolor=15,primary="boost",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="0;4;7;4",exhaustcolors="10;15;5",exhausts="-3;3;-1;4;0;4;2;3"',
 mrs2t's=14,bulletcolor=11,primary="boost",secondary="cloak",secondaryshots=3,psets="3;6;5;3;3;6",guns="2;2;5;2",exhaustcolors="11;3;5",exhausts="-1;4;0;4"',
 mrs2t's=15,bulletcolor=12,primary="boost",secondary="blink",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="7;14;8",exhausts="-4;4;-3;3;-2;2;1;2;2;3;3;4"',
 mrs2t's=16,bulletcolor=11,primary="boost",secondary="flak",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="14;8;2",exhausts="-4;4;-3;4;-2;4;1;4;2;4;3;4"',
 mrs2t's=17,bulletcolor=11,primary="boost",secondary="beam",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="11;11;5",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=18,bulletcolor=11,primary="boost",secondary="burner",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="10;11;5",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=19,bulletcolor=14,primary="boost",secondary="bolt",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;1;6;1",exhaustcolors="7;7;15",exhausts="-3;3;2;3"',
 
 mrs2t's=20,bulletcolor=14,primary="mines",secondary="missile",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="10;9;4",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=21,bulletcolor=5,primary="mines",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=22,bulletcolor=11,primary="mines",secondary="mines",secondaryshots=3,psets="3;4;1;3;3;12",guns="0;2;7;2",exhaustcolors="7;6;5",exhausts="-2;4;1;4"',
 mrs2t's=23,bulletcolor=15,primary="mines",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="10;14;13",exhausts="-1;3;0;3"',
 mrs2t's=24,bulletcolor=11,primary="mines",secondary="cloak",secondaryshots=3,psets="3;6;5;3;3;6",guns="2;2;5;2",exhaustcolors="10;11;5",exhausts="-1;4;0;4"',
 mrs2t's=25,bulletcolor=11,primary="mines",secondary="blink",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;3;2",exhaustcolors="10;11;5",exhausts="-3;4;-2;4;-1;4"',
 mrs2t's=26,bulletcolor=9,primary="mines",secondary="flak",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;0;6;0",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 mrs2t's=27,bulletcolor=14,primary="mines",secondary="beam",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;0;6;0",exhaustcolors="7;7;13",exhausts="-1;3;0;3"',
 mrs2t's=28,bulletcolor=9,primary="mines",secondary="burner",secondaryshots=3,psets="3;6;5;3;3;6",guns="2;1;5;1",exhaustcolors="14;8;5",exhausts="-2;4;1;4"',
 mrs2t's=29,bulletcolor=11,primary="mines",secondary="bolt",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="11;11;4",exhausts="-1;3;0;3"',

 mrs2t's=30,bulletcolor=5,primary="shield",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 mrs2t's=31,bulletcolor=12,primary="shield",secondary="boost",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="11;12;13",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=32,bulletcolor=9,primary="shield",secondary="mines",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 mrs2t's=33,bulletcolor=10,primary="shield",secondary="shield",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;10;5",exhausts="-1;4;0;4"',
 mrs2t's=34,bulletcolor=8,primary="shield",secondary="cloak",secondaryshots=3,psets="0;1;13;0;1;13",guns="2;0;5;0",exhaustcolors="14;8;2",exhausts="-2;4;1;4"',
 mrs2t's=35,bulletcolor=10,primary="shield",secondary="blink",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;2;6;2",exhaustcolors="10;11;15",exhausts="-1;3;0;3"',
 mrs2t's=36,bulletcolor=9,primary="shield",secondary="flak",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="10;14;8",exhausts="-1;4;0;4"',
 mrs2t's=37,bulletcolor=6,primary="shield",secondary="beam",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;1;6;1",exhaustcolors="10;14;15",exhausts="-1;4;0;4"',
 mrs2t's=38,bulletcolor=11,primary="shield",secondary="burner",secondaryshots=3,psets="3;6;3;3;4;11",guns="0;3;7;3",exhaustcolors="3;3;5",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=39,bulletcolor=3,primary="shield",secondary="bolt",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;2;6;2",exhaustcolors="10;10;3",exhausts="-3;3;-1;4;0;4;2;3"',
 
 mrs2t's=40,bulletcolor=14,primary="cloak",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-2;4;1;4"',
 mrs2t's=41,bulletcolor=15,primary="cloak",secondary="boost",secondaryshots=3,psets="3;6;11;3;4;10",guns="0;4;7;4",exhaustcolors="8;2;4",exhausts="-3;3;2;3"',
 mrs2t's=42,bulletcolor=5,primary="cloak",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 mrs2t's=43,bulletcolor=4,primary="cloak",secondary="shield",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;9;5",exhausts="-1;2;0;2"',
 mrs2t's=44,bulletcolor=7,primary="cloak",secondary="cloak",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;1;6;1",exhaustcolors="9;8;2",exhausts="-1;3;0;3"',
 mrs2t's=45,bulletcolor=7,primary="cloak",secondary="blink",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="12;3;15"',
 mrs2t's=46,bulletcolor=7,primary="cloak",secondary="flak",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;0;5;0",exhaustcolors="14;2;5",exhausts="-2;4;1;4"',
 mrs2t's=47,bulletcolor=14,primary="cloak",secondary="beam",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;0;6;0",exhaustcolors="10;11;3",exhausts="-3;4;2;4"',
 mrs2t's=48,bulletcolor=8,primary="cloak",secondary="burner",secondaryshots=3,psets="3;6;3;3;4;11",guns="0;4;7;4",exhaustcolors="7;8;5",exhausts="-1;4;0;4"',
 mrs2t's=49,bulletcolor=11,primary="cloak",secondary="bolt",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;1;6;1",exhaustcolors="9;9;2",exhausts="-1;4;0;4"',
 
 mrs2t's=50,bulletcolor=10,primary="blink",secondary="missile",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4"',
 mrs2t's=51,bulletcolor=9,primary="blink",secondary="boost",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="7;6;13",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=52,bulletcolor=11,primary="blink",secondary="mines",secondaryshots=3,psets="3;5;2;3;3;8",guns="2;1;5;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 mrs2t's=53,bulletcolor=14,primary="blink",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;9;15",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=54,bulletcolor=9,primary="blink",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;2;5;2",exhaustcolors="7;8;2",exhausts="-2;4;1;4"',
 mrs2t's=55,bulletcolor=6,primary="blink",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;2;7;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 mrs2t's=56,bulletcolor=2,primary="blink",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="10;11;5",exhausts="-3;3;-2;4;1;4;2;3"',
 mrs2t's=57,bulletcolor=10,primary="blink",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="7;14;15",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=58,bulletcolor=11,primary="blink",secondary="burner",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="11;11;3",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=59,bulletcolor=14,primary="blink",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="12;12;3",exhausts="-4;4;-3;4;2;4;3;4"',

 mrs2t's=60,bulletcolor=6,primary="flak",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;2;5;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 mrs2t's=61,bulletcolor=8,primary="flak",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;15;5",exhausts="-4;3;-3;3;-1;4;0;4;2;3;3;3"',
 mrs2t's=62,bulletcolor=2,primary="flak",secondary="mines",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="10;9;14",exhausts="-1;4;0;4"',
 mrs2t's=63,bulletcolor=15,primary="flak",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-1;4;0;4"',
 mrs2t's=64,bulletcolor=6,primary="flak",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 mrs2t's=65,bulletcolor=12,primary="flak",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;6;15",exhausts="-3;3;2;3"',
 mrs2t's=66,bulletcolor=9,primary="flak",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 mrs2t's=67,bulletcolor=14,primary="flak",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 mrs2t's=68,bulletcolor=9,primary="flak",secondary="burner",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 mrs2t's=69,bulletcolor=9,primary="flak",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;1;5;1",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',

 mrs2t's=70,bulletcolor=11,primary="beam",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 mrs2t's=71,bulletcolor=3,primary="beam",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;14;15",exhausts="-4;3;-3;4;2;4;3;3"',
 mrs2t's=72,bulletcolor=6,primary="beam",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;6;5",exhausts="-1;4;0;4"',
 mrs2t's=73,bulletcolor=6,primary="beam",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;1;5;1",exhaustcolors="10;11;12",exhausts="-1;4;0;4"',
 mrs2t's=74,bulletcolor=11,primary="beam",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="10;9;15",exhausts="-1;3;0;3"',
 mrs2t's=75,bulletcolor=12,primary="beam",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;7;14",exhausts="-1;3;0;3"',
 mrs2t's=76,bulletcolor=8,primary="beam",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;7;9",exhausts="-3;3;-2;3;1;3;2;3"',
 mrs2t's=77,bulletcolor=4,primary="beam",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-1;4;0;4"',
 mrs2t's=78,bulletcolor=12,primary="beam",secondary="burner",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="10;10;5",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=79,bulletcolor=12,primary="beam",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;12;4",exhausts="-4;3;-3;4;2;4;3;3"',

 mrs2t's=80,bulletcolor=10,primary="burner",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="11;11;15",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=81,bulletcolor=14,primary="burner",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;0;6;0",exhaustcolors="12;12;2",exhausts="-4;4;-3;4;2;4;3;4"',
 mrs2t's=82,bulletcolor=11,primary="burner",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;1;5;1",exhaustcolors="10;9;2",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=83,bulletcolor=2,primary="burner",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="4;0;6;0",exhaustcolors="10;9;2",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4"',
 mrs2t's=84,bulletcolor=10,primary="burner",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;3;7;3",exhaustcolors="11;11;4",exhausts="-1;4;0;4"',
 mrs2t's=85,bulletcolor=12,primary="burner",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;0;6;0",exhaustcolors="7;12;2",exhausts="-4;3;-3;4;2;4;3;3"',
 mrs2t's=86,bulletcolor=9,primary="burner",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;0;6;0",exhaustcolors="9;9;4",exhausts="-4;4;-3;4;2;4;3;4"',
 mrs2t's=87,bulletcolor=11,primary="burner",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="10;10;2",exhausts="-3;4;-1;4;0;4;2;4"',
 mrs2t's=88,bulletcolor=10,primary="burner",secondary="burner",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=89,bulletcolor=11,primary="burner",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;9;15",exhausts="-4;4;-3;4;2;4;3;4"',

 mrs2t's=90,bulletcolor=10,primary="bolt",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;3;7;3",exhaustcolors="7;2;5",exhausts="-1;3;0;3",flyduration=10',
 mrs2t's=91,bulletcolor=5,primary="bolt",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;1;6;1",exhaustcolors="7;7;5",exhausts="-3;3;-1;4;0;4;2;3",flyduration=10',
 mrs2t's=92,bulletcolor=14,primary="bolt",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;0;6;0",exhaustcolors="9;15;5",exhausts="-1;4;0;4",flyduration=10',
 mrs2t's=93,bulletcolor=10,primary="bolt",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;11;5",exhausts="-1;4;0;4",flyduration=10',
 mrs2t's=94,bulletcolor=12,primary="bolt",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="4;1;6;1",exhaustcolors="7;9;5",exhausts="-1;4;0;4;2;4;3;4",flyduration=10',
 mrs2t's=95,bulletcolor=12,primary="bolt",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="7;12;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=10',
 mrs2t's=96,bulletcolor=15,primary="bolt",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;3;7;3",exhaustcolors="9;8;5",exhausts="-1;4;0;4",flyduration=10',
 mrs2t's=97,bulletcolor=7,primary="bolt",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="1",exhausts="-3;3;-2;4;1;4;2;3",flyduration=10',
 mrs2t's=98,bulletcolor=10,primary="bolt",secondary="burner",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="11;15;5",exhausts="-1;4;0;4",flyduration=10',
 mrs2t's=99,bulletcolor=9,primary="bolt",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;0;6;0",exhaustcolors="14;14;4",exhausts="-1;4;0;4",flyduration=10',
}

-- helpers
local function drawblinktext(_str,_startcolor)
 print('\^w\^t'.._str,64-#_str*4,48,_startcolor+flr((t()*12)%3))
end

local function getship(_hangaridx)
 local _ship=mr(clone(hangar[_hangaridx]),s2t'y=110,hw=3,hh=3,spd=1,hp=3,repairc=0,firingc=0,primaryc=12,secondaryc=0')
 local _guns=split(_ship.guns,';')
 _ship.guns={{x=_guns[1],y=_guns[2]},{x=_guns[3],y=_guns[4]}}
 local _psets=split(_ship.psets,';')
 _ship.psets={{_psets[1],_psets[2],_psets[3]},{_psets[4],_psets[5],_psets[6]}}
 _ship.exhaustcolors=split(_ship.exhaustcolors,';')
 _ship.exhausts=_ship.exhausts and split(_ship.exhausts,';') or {}
 return _ship
end

local function createshipflashes()
 for _ship in all(ships) do
  local _shipsx,_shipsy=(_ship.s%16)*8,flr(_ship.s/16)*8
  for _x=0,7 do
   for _y=0,7 do
    local _col=0
    if sget(_shipsx+_x,_shipsy+_y) != 0 then
     _col=7
    end
    sset(112+8*_ship.plidx+_x,120+_y,_col)
   end
  end
 end
end

local function getdirs(_plidx)
 local _dx,_dy=0,0
 if btn(0,_plidx) then
  _dx=-1
 elseif btn(1,_plidx) then
  _dx=1
 end

 if btn(2,_plidx) then
  _dy=-1
 elseif btn(3,_plidx) then
  _dy=1
 end
 return _dx,_dy
end

local burningcolors=split'10,9,5'
local function newburning(_x,_y)
 local _life=8+rnd()*4
 add(ps,{
  x=_x,
  y=_y,
  r=0.5,
  spdx=(rnd()-0.5)*0.125,
  spdy=rnd()*0.25+1,
  spdr=0.25*rnd(),
  colors=burningcolors,
  life=_life,
  lifec=_life,
 })
end

local hitcolors=split'7,7,10'
local function newhit(_x,_y)
 sfx(11)
 for _i=1,7 do
  add(ps,{
   x=_x+(rnd()-0.5)*5,
   y=_y+(rnd()-0.5)*5,
   r=rnd()*5,
   spdx=(rnd()-0.5)*2,
   spdy=rnd()-0.5,
   spdr=-0.2,
   colors=hitcolors,
   life=4,
   lifec=4,
  })
 end
end

local smokecolors={5}
local function explosionsmoke(_x,_y)
 local _life=rnd()*10+25
 add(ps,{
  x=_x,y=_y,
  r=8,
  spdx=(rnd()-0.5),
  spdy=rnd()-1.22,
  spdr=-0.28,
  colors=smokecolors,
  life=_life,
  lifec=_life,
 })
end

local function newexhaustp(_xoff,_yoff,_ship,_colors,_life,_spdyfactor)
 add(psfollow,{
  x=0,y=0,
  follow=_ship,
  xoff=_xoff,
  yoff=_yoff,
  r=0,
  spdx=0,spdy=_spdyfactor+rnd(),spdr=0,
  colors=_colors,
  life=_life,
  lifec=_life,
 })
end

local function getclosest(_x,_y,_list)
 local _closest=_list[1]
 local _closestlen=300
 for _obj in all(_list) do
  local _dist=dist(_x,_y,_obj.x,_obj.y)
  if _dist < _closestlen then
   _closestlen=_dist
   _closest=_obj
  end
 end
 return _closest,_closestlen
end

local explosioncolors=split'7,7,10,9,8'
local function explode(_obj)
 del(bullets,_obj)
 sfx(10)
 for _i=1,7 do
  add(ps,{
   x=_obj.x,
   y=_obj.y,
   r=rnd()*5,
   spdx=(rnd()-0.5),
   spdy=rnd()-1,
   spdr=rnd()*0.2+0.5,
   colors=explosioncolors,
   life=11,
   lifec=11,
   ondeath=explosionsmoke,
  })
 end
end

local fizzlecolors=split'7,9,10,5,9,15,5'
local function fizzle(_obj)
 del(bullets,_obj)
 sfx(18)
 for _i=1,5 do
  local _life=4+rnd(10)
  add(ps,{
   x=_obj.x+(rnd(8)-4),
   y=_obj.y+(rnd(8)-4),
   r=0.9,
   spdx=0,
   spdy=-rnd(0.375),
   spdr=0,
   colors=fizzlecolors,
   life=_life,
   lifec=_life,
  })
 end
end

-- weapons
local function drawbullet(_bullet)
 sspr(31,124,1,4,_bullet.x,_bullet.y)
end

local function drawcloak(_x,_y)
 palt(0,false)
 fillp(rnd(32767))
 circfill(_x+rnd(2)-1,_y+rnd(2)-1,6,1)
 circfill(_x+rnd(2)-1,_y+rnd(2)-1,6,0)
 fillp()
 palt(0,true)
end

local function drawshield(_x,_y)
 circ(_x,_y,6,1)
 fillp(rnd(32767))
 circ(_x+rnd(2)-1,_y+rnd(2)-1,6,12)
 fillp()
end

local beampcolors={7,7,14}
local dirs={1,-1}
local function drawbeam(_x,_topy,_bottomy)
 rectfill(_x-3,_topy+2,_x+2,_bottomy-2,8)
 rectfill(_x-2,_topy+1,_x+1,_bottomy-1,14)
 rectfill(_x-1,_topy,_x,_bottomy,7)
 add(ps,{
  x=_x,y=_topy+rnd(_bottomy),
  r=0.9,
  spdx=rnd(dirs)*(rnd(0.125)+0.125),
  spdy=0,
  spdr=0,
  colors=beampcolors,
  life=20,
  lifec=20,
 })
end

local function drawmine(_bullet)
 _bullet.frame+=(t()*0.375)/_bullet.life
 if _bullet.frame > 2 then
  _bullet.frame=0
 end
 sspr(2*flr(_bullet.frame),124,2,2,_bullet.x,_bullet.y)
end
local function shootmine(_ship,_life,_angle)
 sfx(13)
 add(bullets,{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  spdx=cos(_angle+rnd(0.02)),spdy=sin(_angle+rnd(0.02)),accy=0,
  dmg=6,
  life=_life,
  draw=drawmine,
  ondeath=explode,
 })
end

local missilepcolors=split'7,10,9'
local function drawmissile(_bullet)
 sspr(4,123,3,5,_bullet.x,_bullet.y)
end
local function shootmissile(_ship,_life)
 sfx(12)
 add(bullets,{
  x=_ship.x,y=_ship.y,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=-rnd(0.175),accy=-0.05,spdfactor=1,
  dmg=12,
  life=_life,
  ondeath=explode,
  draw=drawmissile,
  p=mr(s2t'xoff=1,yoff=5,r=0.1,spdx=0,spdy=-0.1,spdr=0,life=3',{colors=missilepcolors}),
 })
end

local flakcolors=split'11,3,5'
local function drawflakbullet(_bullet)
 pset(_bullet.x,_bullet.y,flakcolors[flr((t()*12)%3)+1])
end
local function shootflak(_ship,_amount,_life)
 sfx(17)
 for _i=1,_amount do
  local _spdx,_spdy=1+rnd(2),rnd(1)-0.5
  add(bullets,{
   x=_ship.x,y=_ship.y,
   hw=1,hh=1,
   spdx=_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.9,
   dmg=1,
   life=_life+rnd(20)-40,
   draw=drawflakbullet,
   ondeath=fizzle,
  })
  add(bullets,{
   x=_ship.x,y=_ship.y,
   hw=1,hh=1,
   spdx=-_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.95,
   dmg=1,
   life=_life+rnd(20)-40,
   draw=drawflakbullet,
   ondeath=fizzle,
  })
 end
end

local blinkpcolors=split'7,11,11,3,5'
local function blinkaway(_ship,_dx,_dy,_h)
 sfx(21)
 local _newx,_newy=_ship.x+_dx*_h,_ship.y+_dy*_h
 for _i=1,6 do
  local _life=10+rnd(5)
  add(ps,{
   x=_ship.x+(rnd(8)-4),
   y=_ship.y+(rnd(8)-4),
   r=1+rnd(0.25),
   spdx=0,
   spdy=0,
   spdr=-0.05,
   colors=blinkpcolors,
   life=_life,
   lifec=_life,
  })
 end
 _ship.x=mid(4,_newx,124)
 _ship.y=mid(4,_newy,119)
end

local function shootbeam(_ship)
 add(bullets,{
  x=_ship.x,y=0,
  hw=3,hh=_ship.y,
  spdx=0,
  spdy=0,
  accy=0,
  spdfactor=0,
  dmg=0.25,
  life=1,
  draw=emptydraw,
 })
end

local function shootburner(_ship)
 add(bullets,{
  x=_ship.x,y=_ship.y+10,
  hw=3,hh=20,
  spdx=0,
  spdy=0,
  accy=0,
  spdfactor=0,
  dmg=0.5,
  life=1,
  draw=emptydraw,
 })
end

local function drawbolt(_bullet)
 line(_bullet.from.x,_bullet.from.y,_bullet.x,_bullet.y,7)
 circfill(_bullet.x,_bullet.y,8,7)
 del(bullets,_bullet)
end
local boltpcolors=split'7,7,10,6,15'
local function bolthitfx(_bullet)
 for _i=1,6 do
  local _life=10+rnd(20)
  add(ps,{
   y=_bullet.y+(rnd(12)-6),
   x=_bullet.x+(rnd(12)-6),
   r=1+rnd(1),
   spdx=rnd()-0.5,
   spdy=rnd()-0.5,
   spdr=-0.05,
   colors=boltpcolors,
   life=_life,
   lifec=_life,
  })
 end
end
local function boltdeath(_bullet)
 bolthitfx(_bullet)
 if _bullet.hits > 0 then
  local _enemiesnothit=clone(enemies)
  add(_enemiesnothit,boss)
  for _enemy in all(_bullet.enemiesalreadyhit) do
   del(_enemiesnothit,_enemy)
  end
  shootbolt(_bullet,_bullet.hits-1,_enemiesnothit,_bullet.enemiesalreadyhit,64)
 end
end
function shootbolt(_from,_hits,_enemiesnothit,_enemiesalreadyhit,_maxlen)
 local _closestenemy,_closestlen=getclosest(_from.x,_from.y,_enemiesnothit)
 if _closestenemy and _closestlen < _maxlen and _closestenemy.x > 0 and _closestenemy.x < 127 and _closestenemy.y > 0 and _closestenemy.y < 127 then
  add(_enemiesalreadyhit,_closestenemy)
  add(bullets,{
   x=_closestenemy.x,
   y=_closestenemy.y,
   hw=1,hh=1,
   spdx=0,spdy=0,accy=0,spdfactor=1,
   dmg=2,
   life=1,
   ondeath=boltdeath,
   draw=drawbolt,
   hits=_hits,
   from=_from,
   enemiesalreadyhit=_enemiesalreadyhit,
  })
 end
end

local function emptydraw()
end

local primary={
 missile=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   shootmissile(_ship,_ship.primaryc*2)
   shootmissile(_ship,_ship.primaryc*2)
   _ship.primaryc=0
  end
 end,
 boost=function(_btn4,_ship)
  _ship.isboosting=_ship.primaryc > 0 and not _btn4
 end,
 mines=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   shootmine(_ship,_ship.primaryc*3.5+15,0.375+rnd(0.1))
   shootmine(_ship,_ship.primaryc*3.5+15,0.125-rnd(0.1))
   _ship.primaryc=0
  end
 end,
 shield=function(_btn4,_ship)
  _ship.isshielding=_ship.primaryc > 0 and not _btn4
  if not _btn4 then
   _ship.primaryc-=0.5
  end
 end,
 cloak=function(_btn4,_ship)
  _ship.iscloaking=_ship.primaryc > 0 and not _btn4
 end,
 blink=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 then
   local _dx,_dy=getdirs(_ship.plidx)
   blinkaway(_ship,_dx,_dy,_ship.primaryc*2)
   _ship.primaryc=0
  end
 end,
 flak=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   shootflak(_ship,max(2,flr(_ship.primaryc/3)),_ship.primaryc*5)
   _ship.primaryc=0
  end
 end,
 beam=function(_btn4,_ship)
  _ship.isbeaming=_ship.primaryc > 0 and not _btn4
  if _ship.isbeaming then
   _ship.primaryc-=0.25
   shootbeam(_ship)
  end
 end,
 burner=function(_btn4,_ship)
  _ship.isburnering=_ship.primaryc > 0 and not _btn4
  if _ship.isburnering then
   shootburner(_ship)
  end
 end,
 bolt=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   local _allenemies=clone(enemies)
   add(_allenemies,boss)
   if #_allenemies > 0 then
    shootbolt(_ship,flr(_ship.primaryc*0.15),_allenemies,{},128)
   end
   _ship.primaryc=0
  end
 end,
}

local secondary={
 missile=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootmissile(_ship,75)
   shootmissile(_ship,75)
   shootmissile(_ship,75)
   _ship.secondaryshots-=1
  end
 end,
 boost=function(_ship)
  _ship.secondaryc-=1
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   _ship.secondaryc=60
  end
  if _ship.secondaryc > 0 then
   _ship.isboosting=true
  end
 end,
 mines=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   local _duration=_ship.primaryc*3+30
   shootmine(_ship,_duration,0.375)
   shootmine(_ship,_duration,0.125)
   _ship.secondaryshots-=1
  end
 end,
 shield=function(_ship)
  _ship.secondaryc-=1
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   _ship.secondaryc=60
  end
  if _ship.secondaryc > 0 then
   _ship.isshielding=true
  end
 end,
 cloak=function(_ship)
  _ship.secondaryc-=1
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   _ship.secondaryc=90
  end
  if _ship.secondaryc > 0 then
   _ship.iscloaking=true
  end
 end,
 blink=function(_ship)
  local _dx,_dy=getdirs(_ship.plidx)
  if _ship.secondaryshots > 0 and (
    (btnp(5,_ship.plidx) and (_dx != 0 or _dy != 0)) or
    (btn(5,_ship.plidx) and (btnp(0,_ship.plidx) or btnp(1,_ship.plidx) or btnp(2,_ship.plidx) or btnp(3,_ship.plidx)))
  ) then
   _ship.secondaryshots-=1
   blinkaway(_ship,_dx,_dy,22+flr(rnd(42)))
  end
 end,
 flak=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootflak(_ship,8,120)
   _ship.secondaryshots-=1
  end
 end,
 beam=function(_ship)
  _ship.secondaryc-=1
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   _ship.secondaryc=45
  end
  if _ship.secondaryc > 0 then
   _ship.isbeaming=true
   shootbeam(_ship)
  end
 end,
 burner=function(_ship)
  _ship.secondaryc-=1
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   _ship.secondaryc=110
  end
  if _ship.secondaryc > 0 then
   _ship.isburnering=true
   shootburner(_ship)
  end
 end,
 bolt=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   local _allenemies=clone(enemies)
   add(_allenemies,boss)
   if #_allenemies > 0 then
    shootbolt(_ship,4,_allenemies,{},128)
   end
   _ship.secondaryshots-=1
  end
 end,
}

local weaponcolors=s2t'missile=15,boost=9,mines=5,shield=12,cloak=4,blink=3,flak=11,beam=8,burner=14,bolt=6'

local boostcolors=split'7,10,9,8'
local burnercolors=split'7,7,7,14,14,12,4'

local secondarysprites={
 missile=split'4,123',
 boost=split'7,123',
 mines=split'2,124',
 shield=split'10,123',
 cloak=split'13,123',
 blink=split'16,123',
 flak=split'19,123',
 beam=split'22,123',
 burner=split'25,123',
 bolt=split'28,123'
}

local function newcargodrop(_x,_y)
 add(cargos,{
  x=_x,y=_y,
  hw=2,hh=2,
  spdx=rnd(0.025)-0.0125,
  spdy=0.0125+rnd(0.05),
 })
end

-- enemies

-- todo: meld with newexhaustp?
local function newbossexhaustp(_xoff,_yoff,_ship,_colors,_life,_spdyfactor)
 add(psfollow,{
  x=0,y=0,
  follow=_ship,
  xoff=_xoff,
  yoff=_yoff,
  r=0,
  spdx=0,
  spdy=-(_spdyfactor+rnd()),
  spdr=0,
  colors=_colors,
  life=_life,
  lifec=_life,
 })
end

local function newenemyexhaustp(_x,_y,_colors)
 add(bottomps,{
  x=_x,
  y=_y,
  r=0.1,
  spdx=0,
  spdy=-rnd(),
  spdr=0,
  colors=_colors,
  life=2,
  lifec=3,
 })
end

local function drawenemymissile(_bullet)
 sspr(33,123,3,5,_bullet.x,_bullet.y)
end
local enemymissilepcolors=split'7,10,11'
local function enemyshootmissile(_enemy)
 sfx(12)
 add(enemybullets,{
  x=_enemy.x,y=_enemy.y,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=0.1,accy=0.05,spdfactor=1,
  life=1000,
  draw=drawenemymissile,
  ondeath=explode,
  p={
   xoff=1,
   yoff=0,
   r=0.1,
   spdx=0,
   spdy=0.1,
   spdr=0,
   colors=enemymissilepcolors,
   life=4,
  },
 })
end

local function drawenemymine(_bullet)
 _bullet.frame+=(t()*0.375)/_bullet.life
 if _bullet.frame > 2 then
  _bullet.frame=0
 end
 sspr(2*flr(_bullet.frame),126,2,2,_bullet.x,_bullet.y)
end
local function enemyshootmine(_enemy)
 sfx(13)
 add(enemybullets,{
  x=_enemy.x,y=_enemy.y,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  spdx=rnd(0.5)-0.25,spdy=1.5,accy=0,
  life=110,
  draw=drawenemymine,
  ondeath=explode,
 })
end

local function drawenemybullet(_bullet)
 sspr(32,125,1,3,_bullet.x,_bullet.y)
end
local enemybulletpcolors=split'2,2,4'
local function enemyshootbullet(_enemy)
 sfx(8)
 add(enemybullets,{
  x=_enemy.x+3,y=_enemy.y,
  hw=1,hh=2,
  spdx=0,spdy=2,accy=0,spdfactor=1,
  life=1000,
  draw=drawenemybullet,
  ondeath=explode,
  p={
   xoff=0,
   yoff=0,
   r=0.1,
   spdx=0,
   spdy=0,
   spdr=0,
   colors=enemybulletpcolors,
   life=3,
  },
 })
 add(enemybullets,{
  x=_enemy.x-4,y=_enemy.y,
  hw=1,hh=2,
  spdx=0,spdy=2,accy=0,spdfactor=1,
  life=1000,
  draw=drawenemybullet,
  ondeath=explode,
  p={
   xoff=0,
   yoff=0,
   r=0.1,
   spdx=0,
   spdy=0,
   spdr=0,
   colors=enemybulletpcolors,
   life=3,
  },
 })
end

local bossflakcolors=split'14,8,5'
local function drawbossflakbullet(_bullet)
 pset(_bullet.x,_bullet.y,bossflakcolors[flr((t()*12)%3)+1])
end
local function shootbossflak()
 sfx(17)
 for _i=1,8 do
  local _spdx,_spdy=1+rnd(2),rnd(1)-0.5
  add(enemybullets,{
   x=boss.x,y=boss.y,
   hw=1,hh=1,
   spdx=_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.9,
   dmg=1,
   life=rnd(90)+60,
   draw=drawbossflakbullet,
   ondeath=fizzle,
  })
  add(enemybullets,{
   x=boss.x,y=boss.y,
   hw=1,hh=1,
   spdx=-_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.95,
   dmg=1,
   life=rnd(90)+60,
   draw=drawbossflakbullet,
   ondeath=fizzle,
  })
 end
end

local function drawenemybolt(_bullet)
 line(_bullet.from.x,_bullet.from.y,_bullet.x,_bullet.y,7)
 circfill(_bullet.x,_bullet.y,8,7)
end
local function bossboltondeath(_bullet)
 bolthitfx(_bullet)
 del(enemybullets,_bullet)
end
local function shootbossbolt()
 local _ship1,_ship2=ships[1],ships[2]
 if _ship1 then
  add(enemybullets,{
   x=_ship1.x,
   y=_ship1.y,
   hw=1,hh=1,
   spdx=0,
   spdy=0,
   accy=0,
   spdfactor=0,
   dmg=1,
   life=1,
   from=boss,
   ondeath=bossboltondeath,
   draw=drawenemybolt,
  })
 end
 if _ship2 then
  add(enemybullets,{
   x=_ship2.x,
   y=_ship2.y,
   hw=1,hh=1,
   spdx=0,
   spdy=0,
   accy=0,
   spdfactor=0,
   dmg=1,
   life=1,
   from=_ship1,
   ondeath=bolthitfx,
   draw=drawenemybolt,
  })
 end
end

local blinkdirs=split'-1,0,1'
local bossweapons={
 missile=enemyshootmissile,
 mines=enemyshootmine,
 boost=function()
  boss.boostts=t()
  boss.boost=0.5
  sfx(15,1)
 end,
 shield=function()
  boss.shieldts=t()
  sfx(19,1)
 end,
 cloak=function()
  boss.cloakts=t()
  sfx(20,1)
 end,
 blink=function()
  blinkaway(boss,rnd(blinkdirs),rnd(blinkdirs),48)
  boss.y=mid(4,boss.y,64)
 end,
 flak=function()
  shootbossflak()
 end,
 beam=function()
  boss.beamts=t()
  boss.boost=-0.25
  sfx(16,1)
 end,
 burner=function()
  boss.burnerts=t()
  sfx(15,1)
 end,
 bolt=function()
  shootbossbolt()
 end
}

local minelayerexhaustcolors={12}
local function newminelayer()
 add(enemies,{
  x=rnd(128),y=-12,
  hw=4,hh=4,
  spdx=0,spdy=0,
  s=103,
  hp=5,
  ts=t(),
  update=function(_enemy)
   local _x,_y=flr(_enemy.x),flr(_enemy.y)
   newenemyexhaustp(_x-1,_y-3,minelayerexhaustcolors)
   newenemyexhaustp(_x,_y-3,minelayerexhaustcolors)
   if _enemy.target then
    if t()-_enemy.ts > _enemy.duration or ispointinsideaabb(_enemy.target.x,_enemy.target.y,_enemy.x,_enemy.y,_enemy.hw,_enemy.hh) then
     _enemy.target=nil
    end
   else
    _enemy.spdx,_enemy.spdy=0,0
    if t()-_enemy.ts > 1.5 then
     enemyshootmine(_enemy)
     _enemy.ts=t()
     _enemy.duration=1+rnd(2)
     _enemy.target={x=4+rnd(120),y=rnd(92)}
     local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
     _enemy.spdx,_enemy.spdy=cos(_a)*0.75,sin(_a)*0.75
    end
   end
  end,
 })
end

local kamikazeexhaustcolors=split'10,9'
local function newkamikaze()
 add(enemies,{
  x=rnd(128),y=-12,
  hw=4,hh=4,
  spdx=0,spdy=0,
  s=101,
  hp=4,
  update=function(_enemy)
   local _x=flr(_enemy.x)
   local _y=flr(_enemy.y)
   newenemyexhaustp(_x-1,_y-3,kamikazeexhaustcolors)
   newenemyexhaustp(_x,_y-3,kamikazeexhaustcolors)
   if _enemy.target == nil then
    _enemy.target=getclosest(_enemy.x,_enemy.y,ships)
    _enemy.ifactor=rnd()
   end
   if _enemy.target then
    local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
    _enemy.spdx=cos(_a)*0.5
    _enemy.spdy+=0.011+(_enemy.ifactor*0.003)
   end
  end,
 })
end

local bomberexhaustcolors=split'11,3'
local function newbomber()
 local _spdy=rnd(0.25)+0.325
 add(enemies,{
  x=0,y=-12,
  hw=4,hh=4,
  spdx=0,spdy=_spdy,ogspdy=_spdy,
  accx=0,
  s=104,
  hp=9,
  ts=t(),
  update=function(_enemy)
   local _x=flr(_enemy.x)
   local _y=flr(_enemy.y)
   newenemyexhaustp(_x-3,_y-4,bomberexhaustcolors)
   newenemyexhaustp(_x-2,_y-4,bomberexhaustcolors)
   newenemyexhaustp(_x+1,_y-4,bomberexhaustcolors)
   newenemyexhaustp(_x+2,_y-4,bomberexhaustcolors)
   if not _enemy.target then
    _enemy.x=rnd(128)
    _enemy.target=true
   end
   if t()-_enemy.ts > 0.875 then
    _enemy.accx=rnd{0.0125,-0.0125}
    if rnd() > 0.375 then
     enemyshootmissile(_enemy)
    end
    _enemy.ts=t()
   end
   _enemy.spdx=mid(-0.5,_enemy.spdx+_enemy.accx,0.5)
   _enemy.spdy=_enemy.ogspdy
  end,
 })
end

local fighterexhaustcolors=split'14,2,4'
local function newfighter()
 add(enemies,{
  x=0,y=-12,
  hw=4,hh=4,
  spdx=0,spdy=0,
  accx=0,
  s=102,
  hp=5,
  ts=t(),
  update=function(_enemy)
   local _x,_y=flr(_enemy.x),flr(_enemy.y)
   newenemyexhaustp(_x-1,_y-4,fighterexhaustcolors)
   newenemyexhaustp(_x,_y-4,fighterexhaustcolors)
   if not _enemy.target then
    _enemy.x=flr(8+rnd(120))
    _enemy.target=true
    _enemy.spdy=rnd(0.5)+0.5
   end
   if t()-_enemy.ts > 0.875 then
     enemyshootbullet(_enemy)
     _enemy.ts=t()
   end
  end,
 })
end

local enemycargobulletpcolors=split'7,6,15'
local function drawenemycargobullet(_bullet)
 rectfill(_bullet.x,_bullet.y,_bullet.x+1,_bullet.y+1,7)
end
local function enemyshootcargobullet(_enemy)
 add(enemybullets,{
  x=_enemy.x,y=_enemy.y,
  hw=1,hh=1,
  spdx=_enemy.s == 109 and -1 or 1,spdy=1,accy=0,spdfactor=1,
  life=1000,
  draw=drawenemycargobullet,
  ondeath=explode,
  p={
   xoff=0,
   yoff=0,
   r=0.1,
   spdx=0,
   spdy=0,
   spdr=0,
   colors=enemycargobulletpcolors,
   life=3,
  },
 })
end

local cargoshipexhaustcolors=split'7,6,13'
local cargoshipsprites=split'106,107,108,109'
local function newcargoship()
 local _allparts,_x={},flr(16+rnd(100))
 for _i=1,flr(2+rnd(4)) do
  local _s=_i == 1 and 105 or rnd(cargoshipsprites)
  local _part={
   x=_x,y=-(12+_i*8),
   hw=4,hh=4,
   spdx=0,spdy=0,
   accx=0,
   s=_s,
   hp=14,
   ts=t(),
   update=function(_enemy)
    local _x=flr(_enemy.x)
    local _y=flr(_enemy.y)
    if _enemy == _allparts[#_allparts] then
     newenemyexhaustp(_x-1,_y-4,cargoshipexhaustcolors)
     newenemyexhaustp(_x,_y-4,cargoshipexhaustcolors)
    end
    if _y > 132 then
     del(enemies,_enemy)
    end
    _enemy.spdy=0.25
    if _enemy.s >= 108 and t()-_enemy.ts > 2+rnd(2) then
     enemyshootcargobullet(_enemy)
     _enemy.ts=t()
    end
   end,
  }
  add(_allparts,_part)
  add(enemies,_part)
 end
end


local lastframe,curt
function gameupdate()

 curt=t()
 if escapeelapsed then
  hasescaped=escapeelapsed > escapeduration
 end

 -- update ships
 for _ship in all(ships) do
  local _plidx,_newx,_newy=_ship.plidx,_ship.x,_ship.y

  -- set speed
  _ship.spd=1
  if _ship.isboosting then
   _ship.spd=2
  end

  if _ship.isbeaming then
   _ship.spd*=0.25
  end
  
  -- move
  if btn(0,_plidx) then
   _newx+=-_ship.spd
  end
  if btn(1,_plidx) then
   _newx+=_ship.spd
  end
  if btn(2,_plidx) then
   _newy+=-_ship.spd
  end
  if btn(3,_plidx) then
   _newy+=_ship.spd
  end
  
  _ship.x,_ship.y=mid(4,_newx,124),mid(4,_newy,119)
  local _urx,_ury=_ship.x-4,_ship.y-4

  -- repairing/firing
  _ship.isfiring=nil

  if _ship.secondaryc <= 0 then
   _ship.isshielding,_ship.iscloaking,_ship.isboosting,_ship.isbeaming,_ship.isburnering=nil
  end

  if _ship.hp < 3 then
   newburning(_ship.x,_ship.y)
   _ship.primaryc=max(0,_ship.primaryc-0.0875)
   if btnp(4,_plidx) then
    _ship.primaryc+=2.5
    if _ship.primaryc >= 37 then
     sfx(24,2)
     _ship.hp=3
     _ship.primaryc=0
    end
   end
  else
   local _btn4=btn(4,_plidx)
   if _btn4 then
    _ship.primaryc+=0.25
    _ship.firingc-=1
    if _ship.firingc <= 0 then
     _ship.firingc=10
     _ship.isfiring=true
     for _gun in all(_ship.guns) do
      sfx(8+_ship.plidx)
      add(bullets,{
       x=_urx+_gun.x,y=_ury+_gun.y,
       hw=1,hh=2,
       spdx=0,spdy=-3,accy=0,spdfactor=1,
       dmg=1,
       life=1000,
       draw=drawbullet,
       p={
        xoff=0,yoff=4,r=0.1,
        spdx=0,spdy=-0.1,spdr=0,
        colors={_ship.bulletcolor},
        life=2,
       },
      })
     end
    end
   else
    _ship.primaryc=max(0,_ship.primaryc-0.25)
    _ship.firingc=0
   end

   _ship.primaryc=mid(0,_ship.primaryc,38)
   primary[_ship.primary](_btn4,_ship)
   _ship.lastbtn4=_btn4
  end

  if _ship.hp >= 2 then
   secondary[_ship.secondary](_ship)
  else
   _ship.secondaryc=0
  end

  local _exhaustcolors,_exhaustlife,_exhaustspdyfactor=_ship.exhaustcolors,4,0.1
  if _ship.isburnering then
   _exhaustcolors,_exhaustlife,_exhaustspdyfactor=burnercolors,24,0.75
  elseif _ship.isboosting then
   _exhaustcolors,_exhaustlife=boostcolors,8
  end
  for _i=1,#_ship.exhausts,2 do
   newexhaustp(_ship.exhausts[_i],_ship.exhausts[_i+1],_ship,_exhaustcolors,_exhaustlife,_exhaustspdyfactor)
  end

  if _ship.loopingsfx and not (_ship.isboosting or _ship.isburnering or _ship.isbeaming or _ship.isshielding or _ship.iscloaking) then
   _ship.loopingsfx=nil
   sfx(-2,1)
  elseif not _ship.loopingsfx then
   if (_ship.isboosting or _ship.isburnering) then
    _ship.loopingsfx=true
    sfx(15,1)
   elseif _ship.isbeaming then
    _ship.loopingsfx=true
    sfx(16,1)
   elseif _ship.isshielding then
    _ship.loopingsfx=true
    sfx(19,1)
   elseif _ship.iscloaking then
    _ship.loopingsfx=true
    sfx(20,1)
   end
  end

  if _ship.hp == 0 then
   explode(_ship)
   del(ships,_ship)
  end

  for _cargo in all(cargos) do
   if isaabbscolliding(_ship,_cargo) then
    del(cargos,_cargo)
    _ship.secondaryshots=3
    -- sfx() -- todo
   end
  end

  if boss and isaabbscolliding(_ship,boss) then
   if nickitts then
    del(ships,_ship)
    add(ships,mr(getship(boss.s),{plidx=_plidx,x=_ship.x,y=_ship.y,hp=1}))
    createshipflashes()
    nickedts=curt
    escapeelapsed,nickitts,boss=0
   elseif not (_ship.iscloaking or boss.cloakts) then
    explode(_ship)
    explode(boss)
    boss,_ship.hp=0
   end
  end
 end

 -- update bullets (friendly)
 for _b in all(bullets) do
  _b.x+=_b.spdx
  _b.y+=_b.spdy

  _b.spdy+=_b.accy
  
  _b.life-=1

  _b.spdx*=_b.spdfactor
  _b.spdy*=_b.spdfactor

  if _b.update then
   _b.update(_b)
  end

  if _b.p then
   add(bottomps,mr(clone(_b.p),{
    x=_b.x+_b.p.xoff,
    y=_b.y+_b.p.yoff,
    life=rnd(_b.p.life)+_b.p.life,
    lifec=rnd(_b.p.life)+_b.p.life,
   }))
  end

  if boss and isaabbscolliding(_b,boss) then
   if not boss.shieldts then
    boss.hp-=_b.dmg
   end
   _b.life=0
   newhit(boss.x,boss.y)
  end

  for _enemy in all(enemies) do
   if isaabbscolliding(_b,_enemy) then
    _enemy.hp-=_b.dmg
    _b.life=0
    newhit(_enemy.x,_enemy.y)
   end
  end

  if _b.life <= 0 then
   if _b.ondeath then
    _b.ondeath(_b)
   else
    del(bullets,_b)
   end
  elseif _b.x<0 or _b.x>128 or _b.y<0 or _b.y>128 then
   del(bullets,_b)
  end
 end

 -- update enemy bullets
 for _b in all(enemybullets) do
  _b.x+=_b.spdx
  _b.y+=_b.spdy

  _b.spdy+=_b.accy

  _b.spdx*=_b.spdfactor
  _b.spdy*=_b.spdfactor
  
  _b.life-=1

  if _b.update then
   _b.update(_b)
  end

  if _b.p then
   add(bottomps,mr(clone(_b.p),{
    x=_b.x+_b.p.xoff,
    y=_b.y+_b.p.yoff,
    life=rnd(_b.p.life)+_b.p.life,
    lifec=rnd(_b.p.life)+_b.p.life,
   }))
  end

  for _ship in all(ships) do
   if isaabbscolliding(_b,_ship) then
    if not _ship.isshielding then
     _ship.hp-=1
     _ship.primaryc=0
     if _ship.hp > 0 then
      sfx(21+_ship.hp,2)
     end
    end
    _b.life=0
    newhit(_ship.x,_ship.y)
   end
  end

  if _b.life <= 0 then
   if _b.ondeath then
    _b.ondeath(_b)
   end
   del(enemybullets,_b)
  elseif _b.x<0 or _b.x>128 or _b.y<0 or _b.y>128 then
   del(enemybullets,_b)
  end
 end

 -- update boss
 if boss then
  if boss.hp > 0 then
   local _exhaustcolors,_exhaustlife,_exhaustspdyfactor=boss.exhaustcolors,4,0.1
   if boss.burnerts then
    _exhaustcolors,_exhaustlife,_exhaustspdyfactor=burnercolors,24,0.75
   elseif boss.boostts then
    _exhaustcolors,_exhaustlife=boostcolors,8
   end
   for _i=1,#boss.exhausts,2 do
    newbossexhaustp(boss.exhausts[_i],-(boss.exhausts[_i+1]+0.5),boss,_exhaustcolors,_exhaustlife,_exhaustspdyfactor)
   end
  else
   for _i=1,#boss.exhausts,2 do
    newexhaustp(boss.exhausts[_i],boss.exhausts[_i+1],boss,boss.exhaustcolors,4,0.1)
   end
  end

  local _bossdt=curt-boss.ts
  if boss.hp <= 0 then
   newburning(boss.x,boss.y)
   if not nickitts then
    nickitts=curt
   end
  else
   if _bossdt > boss.flydurationc then
    if _bossdt > boss.flydurationc+boss.waitdurationc then
     bossweapons[rnd{boss.primary,boss.primary,boss.secondary}](boss)
     boss.waitdurationc,boss.flydurationc,boss.ts=0.875+rnd(1.75),(boss.flyduration or 1)+rnd(5),curt
    end
   else
    if boss.targetx == nil or ispointinsideaabb(boss.targetx,boss.targety,boss.x,boss.y,boss.hw,boss.hh) then
     boss.targetx,boss.targety=4+rnd(120),8+rnd(36)
    end

    if boss.boostts and t()-boss.boostts > 2.25 then
     boss.boost,boss.boostts=0
     sfx(-2,1)
    end

    if boss.shieldts and t()-boss.shieldts > 2.25 then
     boss.shieldts=nil
     sfx(-2,1)
    end

    if boss.cloakts and t()-boss.cloakts > 2.25 then
     boss.cloakts=nil
     sfx(-2,1)
    end

    if boss.beamts then
     add(enemybullets,{
      x=boss.x,y=boss.y,
      hw=3,hh=128,
      spdx=0,
      spdy=0,
      accy=0,
      spdfactor=0,
      dmg=1,
      life=1,
      draw=emptydraw,
     })
     if t()-boss.beamts > 2 then
      boss.boost,boss.beamts=0
      sfx(-2,1)
     end
    end

    if boss.burnerts then
     add(enemybullets,{
      x=boss.x,y=boss.y-20,
      hw=3,hh=20,
      spdx=0,
      spdy=0,
      accy=0,
      spdfactor=0,
      dmg=1,
      life=1,
      draw=emptydraw,
     })
     if t()-boss.burnerts > 2 then
      boss.burnerts=nil
      sfx(-2,1)
     end
    end

    local _absx,_spd=abs(boss.targetx-boss.x),0.5+boss.boost
    if _absx > 1 and boss.targetx-boss.x < 0 then
     boss.x-=_spd
    elseif _absx > 1 and boss.targetx-boss.x > 0 then
     boss.x+=_spd
    end

    local _absy=abs(boss.targety-boss.y)
    if _absy > 1 and boss.targety-boss.y < 0 then
     boss.y-=_spd
    elseif _absy > 1 and boss.targety-boss.y > 0 then
     boss.y+=_spd
    end
   end
  end
 end

 -- update enemies
 if nickitts == nil and (not hasescaped) and (t()-enemyts > max(0.8,4*lockedpercentage) and #enemies < 20 or #enemies < 3) then
  enemyts=t()
  rnd{newkamikaze,newkamikaze,newbomber,newminelayer,newfighter,newcargoship}()
 end

 for _enemy in all(enemies) do
  if _enemy.hp <= 0 then
   explode(_enemy)
   if _enemy.s == 106 or _enemy.s == 107 then
    newcargodrop(_enemy.x,_enemy.y)
   end
   del(enemies,_enemy)
  else
   _enemy.x+=_enemy.spdx
   _enemy.y+=_enemy.spdy
   _enemy.update(_enemy)

   local _isoutside=_enemy.y > 140 or _enemy.x < -20 or _enemy.x > 148

   if _isoutside then
    if hasescaped then
     del(enemies,_enemy)
    else
     _enemy.spdx,_enemy.spdy,_enemy.target=0,0
     _enemy.y=-12
    end
   end
   for _ship in all(ships) do
    if isaabbscolliding(_enemy,_ship) and not _ship.iscloaking then
     explode(_enemy)
     del(enemies,_enemy)
     _ship.hp-=1
     _ship.primaryc=0
     if _ship.hp > 0 then
      sfx(21+_ship.hp,2)
     end
    end
   end
  end
 end

 if hasescaped and #enemies == 0 and not madeitts then
  madeitts=t()
  exit=s2t'x=64,y=0,hw=64,hh=8'
 end

 local _isshipinsideexit=nil
 if exit then
  for _ship in all(ships) do
   if isaabbscolliding(_ship,exit) then
    _isshipinsideexit=true
   end
  end
 end
 if hasescaped and madeitts and _isshipinsideexit then
  pickerinit()
  return
 end

 if #ships == 0 and not gameoverts then
  gameoverts=t()
 end

 if gameoverts and t()-gameoverts > 1 and btnp(4) then
  pickerinit()
 end

end

function gamedraw()
 cls()

 -- draw stars
 for _s in all(stars) do
  _s.y+=_s.spd
  if _s.y>130 then
   _s.y=-3
   _s.x=flr(rnd()*128)
  end
  pset(_s.x,_s.y,1)
 end

 -- draw particles below
 for _p in all(bottomps) do
  _p.x+=_p.spdx
  _p.y+=_p.spdy
  _p.r+=_p.spdr
  _p.lifec-=1
  _p.col=_p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
  circfill(_p.x,_p.y,_p.r,_p.col)
  if _p.lifec<0 then
   del(bottomps,_p)
  end
 end

 -- draw cargos
 for _c in all(cargos) do
  _c.x+=_c.spdx
  _c.y+=_c.spdy
  spr(119,_c.x-4,_c.y-4)
 end

 -- draw enemybullets
 for _b in all(enemybullets) do
  _b.draw(_b)
 end

 -- draw bullets
 for _b in all(bullets) do
  _b.draw(_b)
 end

 -- draw enemies
 for _enemy in all(enemies) do
  spr(_enemy.s,_enemy.x-4,_enemy.y-4)
 end

 -- draw beams
 for _ship in all(ships) do
  if _ship.isbeaming then
   drawbeam(_ship.x,-4,_ship.y-6)
  end
 end

 -- draw ships
 for _ship in all(ships) do
  local _urx,_ury=_ship.x-4,_ship.y-4
  spr(_ship.s,_urx,_ury)

  if _ship.isfiring then
   spr(254+_ship.plidx,_urx,_ury)
  end

  if _ship.isshielding then
   drawshield(_ship.x,_ship.y)
  end

  if _ship.iscloaking then
   drawcloak(_ship.x,_ship.y)
  end
 end

 -- draw exit
 if exit then
  local _frame=flr((t()*12)%3)
  print('to secret hangar',32,3,10+_frame)
  sspr(39+_frame*5,123,5,5,18,3)
  sspr(39+_frame*5,123,5,5,104,3)
 end

 -- draw boss
 if boss then
  local _urx,_ury=flr(boss.x)-4,flr(boss.y)-4
  if boss.hp > 0 then
   spr(boss.s,_urx,_ury,1,1,false,true)
   for _pset in all(boss.psets) do
    pset(_urx+_pset[1],_ury+_pset[2],_pset[3])
   end

   if boss.shieldts then
    drawshield(boss.x,boss.y)
   elseif boss.cloakts then
    drawcloak(boss.x,boss.y)
   end

   if boss.beamts then
    drawbeam(boss.x,boss.y+6,132)
   end
  else
   spr(boss.s,_urx,_ury)
  end
 end

 -- draw particles above
 for _p in all(psfollow) do
  _p.x+=_p.spdx
  _p.y+=_p.spdy
  _p.r+=_p.spdr
  _p.lifec-=1
  _p.col=_p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
  circfill(_p.x+_p.follow.x+_p.xoff,_p.follow.y+_p.yoff+_p.y,_p.r,_p.col)
  if _p.lifec<0 then
   del(psfollow,_p)
  end
 end

 for _p in all(ps) do
  _p.x+=_p.spdx
  _p.y+=_p.spdy
  _p.r+=_p.spdr
  _p.lifec-=1
  _p.col=_p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
  circfill(_p.x,_p.y,_p.r,_p.col)
  if _p.x<0 or _p.x>128 or _p.y<0 or _p.y>128 or _p.lifec<0 then
   del(ps,_p)
   if _p.ondeath then
    _p.ondeath(_p.x,_p.y)
   end
  end
 end

 -- draw top fx
 for _ship in all(ships) do
  if _ship.isshielding then
   drawshield(_ship.x,_ship.y)
  end

  if _ship.iscloaking then
   drawcloak(_ship.x,_ship.y)
  end
 end

 -- draw gui
 if boss then
  rectfill(0,127,boss.hp,127,2)
 end
 
 if escapeelapsed then
  if #ships > 0 then
   escapeelapsed+=t()-lastframe
  end
  rectfill(0,127,min(127*(escapeelapsed/escapeduration),128),127,13)
 end

 for _ship in all(ships) do
  local _xoff=1+_ship.plidx*65

  -- primary
  if _ship.hp < 3 then
   sspr(74,123,38,5,_xoff,121)
   if (t()*12)%6 >= 3 then
    print('repair',_xoff+13,121,14)
   end
   sspr(74,118,_ship.primaryc,5,_xoff,121)
  else
   rectfill(_xoff,121,_xoff+37,125,1)
   rect(_xoff+2,122,_xoff+4,124,13)
   print(_ship.primary,_xoff+37-#_ship.primary*4,121,13)
   clip(_xoff,121,_ship.primaryc,5)
   rectfill(_xoff,121,_xoff+37,125,weaponcolors[_ship.primary])
   rect(_xoff+2,122,_xoff+4,124,7)
   print(_ship.primary,_xoff+37-#_ship.primary*4,121,7)
   clip()
  end

  -- secondary
  if _ship.hp < 2 then
   sspr(54,123,20,5,_xoff+41,121)
  else
   color(weaponcolors[_ship.secondary])
   rectfill(_xoff+41,121,_xoff+45,125)
   rectfill(_xoff+46,122,_xoff+46,124)
   pset(_xoff+47,123)
   sspr(36,125,3,3,_xoff+42,122)

   for _i=1,_ship.secondaryshots do
    local _sx,_sy=unpack(secondarysprites[_ship.secondary])
    sspr(_sx,_sy,3,5,_xoff+47+_i*4,121)
   end
  end

 end

 if #ships == 0 then
  drawblinktext('bummer',8)
 end

 if t()-gamestartts < 1.5 and boss then
  drawblinktext('want it!',10)
  local _frame=flr((t()*12)%3)
  sspr(24+_frame*5,118,5,5,boss.x-2,boss.y+8)
 end

 if nickitts and t()-nickitts < 1.5 then
  drawblinktext('nick it!',6)
 end

 if nickedts and t()-nickedts < 1.5 then
  drawblinktext('escape!',9)
 end

 if madeitts then
  drawblinktext('made it!',10)
 end

 lastframe=curt

end

function gameinit()
 gamestartts,enemyts=t(),t()
 gameoverts,nickitts,nickedts,escapeelapsed,madeitts,hasescaped,exit=nil
 ps,psfollow,bottomps,bullets,enemies,enemybullets,cargos,stars={},{},{},{},{},{},{},{}
 escapeduration,lockedpercentage=30,100/(#getlocked())

 for i=1,24 do
  add(stars,{
   x=flr(rnd()*128),
   y=flr(rnd()*128),
   spd=0.5+rnd(0.5),
  })
 end

 createshipflashes()

 _update60,_draw=gameupdate,gamedraw
end

local picks={[0]=0}
function pickerupdate()
 for _i=0,1 do
  if picks[_i] then
   if btnp(0,_i) then
    picks[_i]-=1
   elseif btnp(1,_i) then
    picks[_i]+=1
   elseif btnp(2,_i) then
    picks[_i]-=10
   elseif btnp(3,_i) then
    picks[_i]+=10
   end
   picks[_i]=mid(0,picks[_i],99)

   if btnp(5,_i) and _i == 1 then
    picks[_i]=nil
   elseif btnp(4,_i) and isunlocked(picks[_i]) then
    local _ship=mr(getship(picks[_i]),{plidx=_i,x=32+_i*64})
    ships[_i+1]=_ship

    local _pickcount=mycount(picks)
    if _pickcount > 0 and _pickcount == mycount(ships) then
     boss=mr(getship(rnd(getlocked())),s2t'x=64,y=0,hp=127,ts=0,flydurationc=8,waitdurationc=2,boost=0')
     gameinit()
    end
   end
  else
   if btnp(4,_i) then
    picks[_i]=0
   end
  end
 end
end

function pickerdraw()
 cls()
 print('secret hangar',38,1,13)
 for _x=0,9 do
  for _y=0,9 do
   if isunlocked(_y*10+_x) then
    spr(_y*10+_x,10+_x*11,8+_y*11)
   else
    spr(120,10+_x*11,8+_y*11)
   end
  end
 end
 for _i=0,1 do
  local _pick=picks[_i]
  if _pick then
   local _x,_y=9+(_pick%10)*11,7+flr(_pick/10)*11
   rect(_x,_y,_x+9,_y+9,11+_i)
   local _s='(no ship)'
   if isunlocked(_pick) then
    local _ship=hangar[_pick]
    _s=_ship.primary..','.._ship.secondary
   end
   print(_s,1+_i*127-_i*#_s*4,122,11+_i)
  end
 end
end

function pickerinit()
 sfx(-2,1)
 for _ship in all(ships or {}) do
  unlock(_ship.s)
 end
 ships={}
 _update60,_draw=pickerupdate,pickerdraw
end


_init=function ()
 if #getlocked() == 100 then
  unlock(rnd(getlocked()))
  unlock(rnd(getlocked()))
 end
 pickerinit()
end

__gfx__
00044000000dd000000dd000000cc000000550000900009000022000000220000060060000088000000880000009900007000070000660000002200000033000
00db3d00005dd500040ab04000dabd00004b3400090000900057e500005225000600006000088000000650000097690078000087006dd6000007600000ba9b00
08d33d80005e2500046bb6400ddbbdd004d33d40690b3096005ee500005985006d0000d60007b00000855800086766807800008706dabd60005665000b3993b0
2dd33dd206522560d66bb66dddcbbcdd44d33d4469033096025ee520066886606d0820d600fbbf000825528082699628780a90870d4bb4d005266250b3b99b3b
28d44d826d5225d6d66dd66ddcdccdcd06d55d6069433496245225426ff88ff66d4224d6f0fbbf0f0028820082899828780990870d4bb4d052266225bdb33bdb
8dd44dd86d5dd5d6004dd400cdccccdc6dd55dd696d66d6924422442f652256f6d4664d6f2f88f2f022882209289982988599588d44dd44d52288225bd5335db
8d0550d866dddd660d6dd6d0dc0550cd6d0550d699466499224224226552255606d66d60f2f88f2f822882289289982968588586d46dd64d52288225b500005b
82000028044004400d0550d0c000000c6600006609055090dd0dd0dd0540045000d66d0002f88f20855005589000000966088066006446005005500530000003
000dd00000022000000ee00000422400000550000060060000d55d00000ff000000990000f0f0000000dd0000200002000066000000660000009900000088000
00d76d00002a9200006ee6000542245000555500006996000dd55dd000fbcf0000da8d000f0f0000040ab040e200002e000af000006826000009900000888800
0f6766f0029a992005782750554664550d59e5d000dbcd000dd11dd00f5cc5f000d88d004f4f40ab04dbbd40e20cd02e00dffd0006f22f60000bc000028a9820
ff6446ff2492294265282256446766440de9eed060dccd065d1c11d55d5cc5d50d6886d04ddd40bbdd5bb5dde20dd02e0fdffdf07f6226f7006cc600229a9922
00d44d0024422442762ee267426766244de44ed4694cc4965d1111d55d5dd5d56d6996d6ddddd544d55dd55de24dd42edfd66dfd76f77f67006cc60028988982
0d5445d022422422d7eeee7d422662244d5445d4d949949d5dd11dd5fd5dd5df6dc99cd6d545d545000dd000e242242e00d66d007ff77ff770699607d828828d
d554455d05500550d545545d05244250dd5445ddd949949d0d5dd5d0fd0550dfcdc99cdcd454d0450d5dd5d0220220220f6dd6f06f0550f679699697d828828d
d540045d04500540d404404d004444000220022005500550005dd500f000000fc0c44c0c055500000d5445d0e200002edf6446fd600000066969969605055050
060660600c0000c00070070000077000000330000062260000dffd0000d66d00000cc00000dffd000006600006000060000440000006600000f00f0004000040
600b30066c0000c607000070007d470000f33f000d6226d00dffffd00fd66df00006500005dffd50000dd00062000026004af4006007f0060f0000f0500dd005
60f33f066c0b30c67600006707c44c7000f7bf000d67c6d05dfbbfd5dfd92dfd00d55d0055d99d5500078000620bc026041ff140644ff446fd0000dfd00e200d
f046640f6c0330c6760b3067c6c44c6c03b7bb30d6c7cc6dfdb7bbdf6d2922d60d4554d0dd9a99dd00688600625cc526415ff514600ff006fd07b0dfd442244d
404664046c4334c676d33d67c6c77c6c3fb66bf326c22c62fdb7bbdf6d2442d6d44cc44ddf9a99fd06d88d60625225264514415460066006fd4bb4dfd002200d
400ff004c6d66d6c76d77d6776c77c673f3663f326222262fddbbddffdf44fdf00dccd00dff99ffd6dd44dd62202202241144114644664464d4ff4d45d4dd4d5
45466454cc4664cc07677670760cc067303663030d2222d005dffd5004f44f400dcddcd005fddf506dd44dd6f200002f410550146006600604dffd40550dd055
404664040c0550c000677600700000070004400000d55d000550055000d44d00d4cddc4d00dddd006dd44dd60f0000f0400000046000000600fddf00dd0000dd
000dd00000066000000bb00000088000000ff000000ff0000006600000edde000040040000d00d00000aa0000a0000a000033000050000500003300003000030
000dd0000d09f0d00607e06000276200000ff00000fbcf00000660000edddde00f4004f000d33d0000a7aa00a200002a0003300005076050000a9000c300003c
000760000d7ff7d0063ee36002266220006ab6000ffccff0000a50005edaade5fddffddf00da9d000fa7aaf0a200002a000a5000df0660df00599500cd0000dc
00d66d00677ff776b33ee33b02066020006bb60006fccf6000d55d00dea7aaedfdda9ddf00d99d000fa7aaf0a20b302a00f55f00fd4fd4dd04599540cd0a90dc
00c66c0067766776b33bb33b00088000096bb690f6f66f6f00f55f00dea7aaedfd9a99df0bd99db004aaaa40a203302a00f55f00dd4dd4fd54533545dd0990dd
30cddc0300066000000bb000080880809f6ff6f96f6ff6f60f6ff6f0deeaaeedfd9ff9dfbbd33dbb54faaf452253352260f33f06fd0df0df005335003d5995d3
3dcddcd3007667000b3bb3b0884884889f6ff6f9f66ff66f66f66f660dedded00fdffdf003d33d30f5f55f5f9252252963f33f36550dd05504355340dc5cc5cd
cdcddcdc000550000b3553b08505505890d55d0905500550f6d66d6f005dd500005ff500330330330545545099022099f3f33f3f0005500054355345dc0cc0cd
0005500000088000000ff000000770000004d000000dd00003000030000ee00004000040000ff000004dd40000022000000dd0000008800000033000000ff000
000550000006d0000d0ab0d00076c700000d4000000dd0000b3003b000eb3e0042000024009ff9000d4994d0002b320000dabd000007e00000333300c007e00c
000e2000000dd0000d4bb4d00bc6ccb0000e8000005bc50000be2b000023320042000024009ab9000d9a99d0028338200fbabbf0200ee00205376350cf0ee0fc
00f22f00008dd800454bb454b3c77c3b00f88f00005cc500000220000e2332e0420980240fbabbf00d9a99d0282332820fbabbf02f0ee0f205676650cf5ee5fc
00f22f000e8dd8e0545ff545b3b77b3b00f88f000f5cc5f00b3223b0e224422e42088024f9b99b9f0d9999d0828228280fbddbf02f2882f2d56dd65dcf0ff0fc
d0f55f0d2e8ee8e2000ff00073b77b3760fd4f06fd5dd5dfb33bb33b04d22d4022188122ff9999ff5d5995d5282222824fd44df40f2882f0d53dd35dcf5ff5fc
d5f55f5d2e8ee8e2045ff54073b77b3764f4dfd6fd5dd5dfb30bb03b5d0440d52412214200f44f005d5dd5d582055028455445540f2882f05d3dd3d5cf0ff0fc
f5f55f5f005ee500054dd45070044007fdf4df4ff0f44f0fb004400b05000050440220440005500050500505800000084000000400255200055005500f0000f0
0006600007000070000ff0000000d0d000022000070000700f0000f000d00d00000bb000000ff000000ff0000052250002000020000990000000060000066000
006e86007900009700d66d0000007670000220007e0000e76707b0760bd00db000c76c00060e806000f7bf000552255024000042000e20000000d6d000d66d00
0d8e88d0790000970d6766d0e2067676000a60007e0000e7670bb0763b3bb3b30c6766c0060880600f5bb5f0555bc5552409e04200f22f007906d6d600de2d00
d486684d790e8097dd6766dd2207676700d66d007e0bc0e7765775673b3ae3b3bc6bb6cb670880765d5bb5d525cbcc52240ee0420df22fd09906d6d607d22d70
d4d66d4d79088097fdd66ddf77476767d0d66d0d7e5cc5e7765775673beaeeb3bccbbccb764ff4675d5ff5d525c55c5224544542fdf99fdf6656d6d676d22d67
64d66d469958859904dffd4076476767d4d22d4dee5ee5ee76066067b3ebbe3bbbcbbcbb764ff467fd5ff5df2545545244544544f009900f6d5d666d76d66d67
64d66d46a959959a05dffd5076067776d4d22d4d6e0ee0e645000054033bb33004400440670dd076fd0550df054554502404404200d99d006d066d6677666677
65500556aa0990aa055005505505505504d22d400600006044000044040440400d4004d055000055f000000f00455400040550400fd44df00006d0d604400440
000cc00000f00f00005005000600006004055040d000000d0005500004055040055005504d4444d4044444400444444004444440044444404000000400055000
000cc0000d0000d00d0000d07000000700422400d405504d4dd44dd4d404404d444dd4444d4444d44d4dd4d44d4dd4d44dddddd44dddddd44205502442422424
000a9000f70d507fd009900d70077007244bb442d44dd44d4dd44dd444544544d44dd44d4d4444d44d4dd4d44d4dd4d44dd44dd44dd44dd44224422442422424
00d99d00d705507dd09a990d600b300602b7bb20d44dd44d4dd44dd4d454454dd4bddb4d4d6766d44dd44dd44d4dd4d44d4dd4d44d4dd4d44424424440422404
00d99d00f70ff07f0d9999d070f33f0720bbbb02d44a944d40d7ed04d40bc04d04babb400d6766d04dd44dd44d4dd4d44d4d64d44d46d4d4424a94240047e400
60dccd06d70ff07dd449944d74677647200bb0020d4994d0000ee000d40cc04d04dabd4004d66d404d4dd4d44d4dd4d44dd446d44d644dd404299240000ee000
6cdccdc60d0000d0004dd400f467764f0200002000d99d00000ee000d400004d00dddd0004d44d404d4dd4d44d4dd4d44dddddd44dddddd400499400000ee000
dcdccdcd00d00d0004055040600ff0060040040000044000000440000d0000d0000dd00000d44d00044444400444444004444440044444400004400000022000
24055042055005504244442404444440044444400444444004444440000000000000000000000000000000000000000000000000000000000000000000000000
24022042424224244244442442422424424224244222222442222224000000000011110000000000000000000000000000000000000000000000000000000000
44522544224224224244442442422424424224244224422442244224005ff5000110011000000000000000000000000000000000000000000000000000000000
2452254224b22b42426766244224422442422424424224244242242400f5ff000000011000000000000000000000000000000000000000000000000000000000
440bc04404babb40026766204224422442422424424264244246242400ff5f000001110000000000000000000000000000000000000000000000000000000000
240cc042042ab2400426624042422424424224244224462442644224005ff5000000000000000000000000000000000000000000000000000000000000000000
24000042002222000424424042422424424224244222222442222224000000000001100000000000000000000000000000000000000000000000000000000000
02000020000220000024420004444440044444400444444004444440000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000003333333333333bbb3bbb3bbb3bbb3bbb3bbb330000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000033bbb33333333b3b3b333b3b3b3b33b33b3b330000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000033b3b33333333bb33bb33bbb3bbb33b33bb3337777777777777777
0000000000000000000000000000000000000000000000000000000000000000000000000033bbb33333333b3b3b333b333b3b33b33b3b337777777777777777
000000000000000000000000000000000000000000000000000000000000000000000000003333333333333b3b3bbb3b333b3b3bbb3b3b337777777777777777
0000060000000000070b108e8770070004d400000a0000b0000c0022222000022002220022222222222222288828882888288828882888227777777777777777
8558060aa00c01410b01108e8770700700d00000aaa00bbb00ccc020000200020202220200208880000000080808000808080800800808027777777777777777
5885060a90c1c4140001a08e8e700707e0d0707aaaaabbbbbccccc20000020020202020200208080000000088008800888088800800880027777777777777777
c55c060980c1c141b001108e88e0700770d007000a0000b0000c0020000200020202020202208880000000080808000800080800800808027777777777777777
5cc5d6d8000c0414700b108e8080700a70d070700a0000b0000c0022222000022202020222222222222222282828882822282828882828227777777777777777
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002402300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
110800002402300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
151e0000124333f4031a4031d403194031740313403124030d4030c40308403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
490c00002143300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
040300001a3211c321234112e4111960115621126210f6110b6110a61108611076110661104611036110261101611003010030100301003010030100301003010030100301003010030100301003010030100301
001100001a0312820109001122010e2010a2010620100201002010020112201142010020100201002010020100201002010020100201002010020100201002010020100201002010020100201002010020100201
00080000282211f22118221122210e2210a2210622100211002010020112201142010020100201002010020100201002010020100201002010020100201002010020100201002010020100201002010020000200
020400011962000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
2c0400020842000440004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000400003c6303b6003a63039600386300e6002e62035600216203360000000256002f600216001d6002c6001a60016600296001360011600106002560009600066000360000000000001e600000000000000000
000200002b6103b600396002561020610266001c610066101a610006000060000600186100060000600006001b6000360000600006001761000600006000060000600006000e6100060000600006000060000600
00040004225210d5411452122541145011a501145011a501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
910d00043f7133f7233f7133f7231f7031a703147031a703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703007030070300703
000e00002f53300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
901400002541000400254100040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
901400002541000400254000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
490a00002e01022010270102e01030000350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
