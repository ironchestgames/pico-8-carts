pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- shipnickers 1.0
-- by ironchest games

--[[
 - fix bolt
 - unify game event code
 - mash shield and aegis?
 - replace bolt w slicer?

dget:
63 - boss kills

sfx channels:
0 - looping plidx 0
1 - looping plidx 1
2 - looping boss sounds
3 - general

--]]

-- dev4, dev6 = all unlocked
cartdata'ironchestgames_shipnickers_v1-dev4'
-- cartdata'ironchestgames_shipnickers_v1-dev7'

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
local ships,bullets,stars,ps,psfollow,bottomps,enemies,enemybullets,boss,issuperboss,cargos,lockedpercentage

local hangar={
 [0]=s2t's=0,bulletcolor=11,primary="missile",secondary="missile",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="7;9;5",exhausts="-1;4;0;4",flyduration=1',
 s2t's=1,bulletcolor=12,primary="missile",secondary="boost",secondaryshots=3,psets="3;5;2;3;3;8",guns="2;0;5;0",exhaustcolors="7;10;9",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=2,bulletcolor=10,primary="missile",secondary="mines",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4",flyduration=1',
 s2t's=3,bulletcolor=10,primary="missile",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="7;9;4",exhausts="-1;3;0;3",flyduration=1',
 s2t's=4,bulletcolor=15,primary="missile",secondary="aegis",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;0;5;0",exhaustcolors="10;11;15",exhausts="-1;3;0;3",flyduration=1',
 s2t's=5,bulletcolor=14,primary="missile",secondary="blink",secondaryshots=3,psets="3;5;3;3;3;11",guns="1;0;6;0",exhaustcolors="14;8;2",exhausts="-1;3;0;3",flyduration=1',
 s2t's=6,bulletcolor=15,primary="missile",secondary="flak",secondaryshots=3,psets="3;6;14;3;4;7",guns="2;0;5;0",exhaustcolors="10;9;5",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4",flyduration=1',
 s2t's=7,bulletcolor=12,primary="missile",secondary="beam",secondaryshots=3,psets="3;5;8;3;3;9",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=8,bulletcolor=12,primary="missile",secondary="bubbles",secondaryshots=3,psets="3;4;3;3;3;11",guns="2;0;5;0",exhaustcolors="14;8;2",exhausts="-2;4;1;4",flyduration=1',
 s2t's=9,bulletcolor=12,primary="missile",secondary="bolt",secondaryshots=3,psets="3;5;11;3;3;7",guns="0;3;7;3",exhaustcolors="7;12;15",exhausts="-1;4;0;4",flyduration=1',

 s2t's=10,bulletcolor=11,primary="boost",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="2;2;5;2",exhaustcolors="7;6;13",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=11,bulletcolor=3,primary="boost",secondary="boost",secondaryshots=3,psets="0;0;9;0;0;9",guns="1;0;6;0",exhaustcolors="11;12;5",exhausts="-2;3;-1;3;0;3;1;3",flyduration=1',
 s2t's=12,bulletcolor=9,primary="boost",secondary="mines",secondaryshots=3,psets="3;4;9;3;2;10",guns="1;0;6;0",exhaustcolors="11;3;4",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 s2t's=13,bulletcolor=15,primary="boost",secondary="shield",secondaryshots=3,psets="3;5;11;3;3;10",guns="0;4;7;4",exhaustcolors="10;15;5",exhausts="-3;3;-1;4;0;4;2;3",flyduration=1',
 s2t's=14,bulletcolor=11,primary="boost",secondary="aegis",secondaryshots=3,psets="3;6;6;3;3;7",guns="2;2;5;2",exhaustcolors="11;3;5",exhausts="-1;4;0;4",flyduration=1',
 s2t's=15,bulletcolor=12,primary="boost",secondary="blink",secondaryshots=3,psets="3;6;9;3;4;10",guns="1;2;6;2",exhaustcolors="7;14;8",exhausts="-4;4;-3;3;-2;2;1;2;2;3;3;4",flyduration=1',
 s2t's=16,bulletcolor=11,primary="boost",secondary="flak",secondaryshots=3,psets="3;6;7;3;5;7",guns="1;2;6;2",exhaustcolors="14;8;2",exhausts="-4;4;-3;4;-2;4;1;4;2;4;3;4",flyduration=1',
 s2t's=17,bulletcolor=11,primary="boost",secondary="beam",secondaryshots=3,psets="3;6;10;3;5;10",guns="1;2;6;2",exhaustcolors="11;11;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=18,bulletcolor=11,primary="boost",secondary="bubbles",secondaryshots=3,psets="3;5;8;3;4;8",guns="1;2;6;2",exhaustcolors="10;11;5",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 s2t's=19,bulletcolor=14,primary="boost",secondary="bolt",secondaryshots=3,psets="3;5;6;3;2;6",guns="1;1;6;1",exhaustcolors="7;7;15",exhausts="-3;3;2;3",flyduration=1',
 
 s2t's=20,bulletcolor=14,primary="mines",secondary="missile",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="10;9;4",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=21,bulletcolor=8,primary="mines",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=22,bulletcolor=11,primary="mines",secondary="mines",secondaryshots=3,psets="3;4;1;3;3;12",guns="0;2;7;2",exhaustcolors="7;6;5",exhausts="-2;4;1;4",flyduration=1',
 s2t's=23,bulletcolor=15,primary="mines",secondary="shield",secondaryshots=3,psets="3;6;9;3;4;10",guns="1;1;6;1",exhaustcolors="10;14;13",exhausts="-1;3;0;3",flyduration=1',
 s2t's=24,bulletcolor=11,primary="mines",secondary="aegis",secondaryshots=3,psets="3;6;8;3;4;10",guns="2;2;5;2",exhaustcolors="10;11;5",exhausts="-1;4;0;4",flyduration=1',
 s2t's=25,bulletcolor=11,primary="mines",secondary="blink",secondaryshots=3,psets="6;5;11;6;4;10",guns="1;2;3;2",exhaustcolors="10;11;5",exhausts="-3;4;-2;4;-1;4",flyduration=1',
 s2t's=26,bulletcolor=9,primary="mines",secondary="flak",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;0;6;0",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=27,bulletcolor=14,primary="mines",secondary="beam",secondaryshots=3,psets="3;5;13;3;3;12",guns="1;0;6;0",exhaustcolors="7;7;13",exhausts="-1;3;0;3",flyduration=1',
 s2t's=28,bulletcolor=9,primary="mines",secondary="bubbles",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="7;14;8",exhausts="-1;3;0;3",flyduration=1',
 s2t's=29,bulletcolor=11,primary="mines",secondary="bolt",secondaryshots=3,psets="3;6;2;3;4;8",guns="1;2;6;2",exhaustcolors="11;11;4",exhausts="-1;3;0;3",flyduration=1',

 s2t's=30,bulletcolor=5,primary="shield",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=31,bulletcolor=12,primary="shield",secondary="boost",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="11;12;13",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 s2t's=32,bulletcolor=9,primary="shield",secondary="mines",secondaryshots=3,psets="3;6;3;3;5;11",guns="1;0;6;0",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=33,bulletcolor=10,primary="shield",secondary="shield",secondaryshots=3,psets="3;5;3;3;3;11",guns="1;0;6;0",exhaustcolors="7;10;5",exhausts="-1;4;0;4",flyduration=1', 
 s2t's=34,bulletcolor=8,primary="shield",secondary="aegis",secondaryshots=3,psets="3;4;2;3;3;14",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;3;-2;4;1;4;2;3",flyduration=1',
 s2t's=35,bulletcolor=10,primary="shield",secondary="blink",secondaryshots=3,psets="3;6;4;3;4;13",guns="1;2;6;2",exhaustcolors="10;11;15",exhausts="-1;3;0;3",flyduration=1',
 s2t's=36,bulletcolor=9,primary="shield",secondary="flak",secondaryshots=3,psets="3;6;3;3;4;7",guns="2;1;5;1",exhaustcolors="10;14;8",exhausts="-1;4;0;4",flyduration=1',
 s2t's=37,bulletcolor=6,primary="shield",secondary="beam",secondaryshots=3,psets="3;6;2;3;4;7",guns="1;1;6;1",exhaustcolors="10;14;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=38,bulletcolor=11,primary="shield",secondary="bubbles",secondaryshots=3,psets="3;5;11;3;4;7",guns="0;3;7;3",exhaustcolors="3;3;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=39,bulletcolor=3,primary="shield",secondary="bolt",secondaryshots=3,psets="3;5;9;3;4;9",guns="1;2;6;2",exhaustcolors="10;10;3",exhausts="-3;3;-1;4;0;4;2;3",flyduration=1',
 
 s2t's=40,bulletcolor=14,primary="aegis",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="1;2;6;2",exhaustcolors="10;14;4",exhausts="-2;4;1;4",flyduration=1',
 s2t's=41,bulletcolor=15,primary="aegis",secondary="boost",secondaryshots=3,psets="3;6;15;3;4;7",guns="0;4;7;4",exhaustcolors="10;9;4",exhausts="-3;3;2;3",flyduration=1',
 s2t's=42,bulletcolor=5,primary="aegis",secondary="mines",secondaryshots=3,psets="3;4;11;3;3;7",guns="1;1;6;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=43,bulletcolor=4,primary="aegis",secondary="shield",secondaryshots=3,psets="3;4;11;3;5;12",guns="1;0;6;0",exhaustcolors="7;9;5",exhausts="-1;2;0;2",flyduration=1',
 s2t's=44,bulletcolor=7,primary="aegis",secondary="aegis",secondaryshots=3,psets="3;6;15;3;4;10",guns="1;1;6;1",exhaustcolors="9;8;2",exhausts="-1;3;0;3",flyduration=1',
 s2t's=45,bulletcolor=7,primary="aegis",secondary="blink",secondaryshots=3,psets="3;6;15;3;4;7",guns="2;1;5;1",exhaustcolors="1",exhausts="-4;4;3;4",flyduration=1',
 s2t's=46,bulletcolor=10,primary="aegis",secondary="flak",secondaryshots=3,psets="3;5;14;3;3;6",guns="1;3;6;3",exhaustcolors="11;11;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=47,bulletcolor=6,primary="aegis",secondary="beam",secondaryshots=3,psets="3;3;7;3;5;6",guns="1;1;6;1",exhaustcolors="7;12;4",exhausts="-1;4;0;4",flyduration=1',
 s2t's=48,bulletcolor=8,primary="aegis",secondary="bubbles",secondaryshots=3,psets="3;5;9;3;3;10",guns="0;3;7;3",exhaustcolors="9;8;5",exhausts="-1;4;0;4",flyduration=10',
 s2t's=49,bulletcolor=11,primary="aegis",secondary="bolt",secondaryshots=3,psets="3;6;15;3;4;9",guns="1;1;6;1",exhaustcolors="9;9;2",exhausts="-1;4;0;4",flyduration=1',
 
 s2t's=50,bulletcolor=10,primary="blink",secondary="missile",secondaryshots=3,psets="3;6;14;3;4;7",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4",flyduration=1',
 s2t's=51,bulletcolor=9,primary="blink",secondary="boost",secondaryshots=3,psets="3;6;6;3;4;7",guns="1;1;6;1",exhaustcolors="7;6;13",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 s2t's=52,bulletcolor=11,primary="blink",secondary="mines",secondaryshots=3,psets="3;5;11;3;3;10",guns="2;1;5;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=53,bulletcolor=14,primary="blink",secondary="shield",secondaryshots=3,psets="3;6;12;3;4;11",guns="1;2;6;2",exhaustcolors="7;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=54,bulletcolor=9,primary="blink",secondary="aegis",secondaryshots=3,psets="3;5;5;3;3;10",guns="2;2;5;2",exhaustcolors="7;8;2",exhausts="-2;4;1;4",flyduration=1',
 s2t's=55,bulletcolor=6,primary="blink",secondary="blink",secondaryshots=3,psets="3;5;10;3;3;7",guns="0;2;7;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3",flyduration=1',
 s2t's=56,bulletcolor=2,primary="blink",secondary="flak",secondaryshots=3,psets="3;5;15;3;3;10",guns="2;0;5;0",exhaustcolors="10;11;5",exhausts="-3;3;-2;4;1;4;2;3",flyduration=1',
 s2t's=57,bulletcolor=11,primary="blink",secondary="beam",secondaryshots=3,psets="3;5;7;3;2;10",guns="0;4;7;4",exhaustcolors="11;11;3",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 s2t's=58,bulletcolor=10,primary="blink",secondary="bubbles",secondaryshots=3,psets="3;5;9;3;3;10",guns="2;0;5;0",exhaustcolors="7;14;15",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 s2t's=59,bulletcolor=14,primary="blink",secondary="bolt",secondaryshots=3,psets="3;4;3;3;2;11",guns="0;4;7;4",exhaustcolors="12;12;3",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',

 s2t's=60,bulletcolor=6,primary="flak",secondary="missile",secondaryshots=3,psets="3;5;5;3;3;10",guns="2;2;5;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3",flyduration=1',
 s2t's=61,bulletcolor=8,primary="flak",secondary="boost",secondaryshots=3,psets="3;5;7;3;6;6",guns="1;2;6;2",exhaustcolors="7;15;5",exhausts="-4;3;-3;3;-1;4;0;4;2;3;3;3",flyduration=1',
 s2t's=62,bulletcolor=2,primary="flak",secondary="mines",secondaryshots=3,psets="3;6;9;3;4;10",guns="1;1;6;1",exhaustcolors="10;9;14",exhausts="-1;4;0;4",flyduration=1',
 s2t's=63,bulletcolor=15,primary="flak",secondary="shield",secondaryshots=3,psets="3;2;10;3;4;9",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-1;4;0;4",flyduration=1',
 s2t's=64,bulletcolor=6,primary="flak",secondary="aegis",secondaryshots=3,psets="3;5;2;3;3;14",guns="0;4;7;4",exhaustcolors="7;10;11",exhausts="-3;3;2;3",flyduration=1',
 s2t's=65,bulletcolor=12,primary="flak",secondary="blink",secondaryshots=3,psets="3;6;13;3;3;6",guns="1;3;6;3",exhaustcolors="7;6;15",exhausts="-3;3;2;3",flyduration=1',
 s2t's=66,bulletcolor=9,primary="flak",secondary="flak",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=67,bulletcolor=9,primary="flak",secondary="beam",secondaryshots=3,psets="3;5;8;3;3;14",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=68,bulletcolor=14,primary="flak",secondary="bubbles",secondaryshots=3,psets="3;5;6;3;3;7",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=69,bulletcolor=9,primary="flak",secondary="bolt",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;1;5;1",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',

 s2t's=70,bulletcolor=11,primary="beam",secondary="missile",secondaryshots=3,psets="3;5;2;3;3;14",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=71,bulletcolor=3,primary="beam",secondary="boost",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;3;6;3",exhaustcolors="10;14;15",exhausts="-4;3;-3;4;2;4;3;3",flyduration=1',
 s2t's=72,bulletcolor=6,primary="beam",secondary="mines",secondaryshots=3,psets="3;4;8;3;2;9",guns="1;3;6;3",exhaustcolors="7;6;5",exhausts="-1;4;0;4",flyduration=1',
 s2t's=73,bulletcolor=6,primary="beam",secondary="shield",secondaryshots=3,psets="3;5;10;3;3;9",guns="2;1;5;1",exhaustcolors="10;11;12",exhausts="-1;4;0;4",flyduration=1',
 s2t's=74,bulletcolor=11,primary="beam",secondary="aegis",secondaryshots=3,psets="3;5;9;3;3;10",guns="2;0;5;0",exhaustcolors="10;9;15",exhausts="-1;3;0;3",flyduration=1',
 s2t's=75,bulletcolor=12,primary="beam",secondary="blink",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;3;6;3",exhaustcolors="7;7;14",exhausts="-1;3;0;3",flyduration=1',
 s2t's=76,bulletcolor=8,primary="beam",secondary="flak",secondaryshots=3,psets="3;5;10;3;4;10",guns="1;3;6;3",exhaustcolors="7;7;9",exhausts="-3;3;-2;3;1;3;2;3",flyduration=1',
 s2t's=77,bulletcolor=4,primary="beam",secondary="beam",secondaryshots=3,psets="3;6;14;3;4;7",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-1;4;0;4",flyduration=1',
 s2t's=78,bulletcolor=12,primary="beam",secondary="bubbles",secondaryshots=3,psets="3;5;7;3;4;7",guns="1;2;6;2",exhaustcolors="10;10;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=79,bulletcolor=10,primary="beam",secondary="bolt",secondaryshots=3,psets="3;6;14;3;4;7",guns="1;2;6;2",exhaustcolors="4;1",exhausts="-4;4;-3;3;2;3;3;4",flyduration=1',

 s2t's=80,bulletcolor=6,primary="bubbles",secondary="missile",secondaryshots=3,psets="3;5;14;3;3;6",guns="0;0;7;0",exhaustcolors="7;12;3",exhausts="-1;4;0;4",flyduration=1',
 s2t's=81,bulletcolor=14,primary="bubbles",secondary="boost",secondaryshots=3,psets="3;4;8;3;2;14",guns="1;0;6;0",exhaustcolors="12;12;2",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 s2t's=82,bulletcolor=11,primary="bubbles",secondary="mines",secondaryshots=3,psets="3;5;7;3;3;6",guns="2;1;5;1",exhaustcolors="10;9;2",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=83,bulletcolor=2,primary="bubbles",secondary="shield",secondaryshots=3,psets="3;5;11;3;4;11",guns="1;1;6;1",exhaustcolors="7;7;5",exhausts="-3;3;-1;4;0;4;2;3",flyduration=10',
 s2t's=84,bulletcolor=10,primary="bubbles",secondary="aegis",secondaryshots=3,psets="3;5;6;3;3;7",guns="0;3;7;3",exhaustcolors="11;11;4",exhausts="-1;4;0;4",flyduration=1',
 s2t's=85,bulletcolor=12,primary="bubbles",secondary="blink",secondaryshots=3,psets="3;4;12;3;3;11",guns="1;0;6;0",exhaustcolors="7;12;2",exhausts="-4;3;-3;4;2;4;3;3",flyduration=1',
 s2t's=86,bulletcolor=9,primary="bubbles",secondary="flak",secondaryshots=3,psets="3;5;7;3;6;11",guns="1;0;6;0",exhaustcolors="10;9;4",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 s2t's=87,bulletcolor=9,primary="bubbles",secondary="beam",secondaryshots=3,psets="3;5;11;3;3;10",guns="2;1;5;1",exhaustcolors="10;10;2",exhausts="-1;3;0;3",flyduration=1',
 s2t's=88,bulletcolor=10,primary="bubbles",secondary="bubbles",secondaryshots=3,psets="3;5;7;3;3;11",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 s2t's=89,bulletcolor=11,primary="bubbles",secondary="bolt",secondaryshots=3,psets="3;5;11;3;3;12",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',

 s2t's=90,bulletcolor=10,primary="bolt",secondary="missile",secondaryshots=3,psets="3;6;12;3;4;11",guns="0;3;7;3",exhaustcolors="7;2;5",exhausts="-1;3;0;3",flyduration=10',
 s2t's=91,bulletcolor=5,primary="bolt",secondary="boost",secondaryshots=3,psets="0;5;2;0;4;14",guns="4;0;6;0",exhaustcolors="10;9;2",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4",flyduration=1',
 s2t's=92,bulletcolor=14,primary="bolt",secondary="mines",secondaryshots=3,psets="3;5;14;3;4;9",guns="1;0;6;0",exhaustcolors="9;15;5",exhausts="-1;4;0;4",flyduration=10',
 s2t's=93,bulletcolor=10,primary="bolt",secondary="shield",secondaryshots=3,psets="3;6;2;3;4;14",guns="1;2;6;2",exhaustcolors="7;11;5",exhausts="-1;4;0;4",flyduration=10',
 s2t's=94,bulletcolor=12,primary="bolt",secondary="aegis",secondaryshots=3,psets="0;5;9;0;4;7",guns="4;1;6;1",exhaustcolors="7;9;5",exhausts="-1;4;0;4;2;4;3;4",flyduration=10',
 s2t's=95,bulletcolor=12,primary="bolt",secondary="blink",secondaryshots=3,psets="3;5;2;3;3;14",guns="2;0;5;0",exhaustcolors="7;12;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=10',
 s2t's=96,bulletcolor=15,primary="bolt",secondary="flak",secondaryshots=3,psets="3;5;9;3;3;10",guns="0;3;7;3",exhaustcolors="7;6;4",exhausts="-1;4;0;4",flyduration=10',
 s2t's=97,bulletcolor=7,primary="bolt",secondary="beam",secondaryshots=3,psets="3;5;5;3;4;6",guns="2;0;5;0",exhaustcolors="1",exhausts="-3;3;-2;4;1;4;2;3",flyduration=10',
 s2t's=98,bulletcolor=10,primary="bolt",secondary="bubbles",secondaryshots=3,psets="3;4;3;3;3;11",guns="1;0;6;0",exhaustcolors="14;14;4",exhausts="-1;4;0;4",flyduration=10',
 s2t's=99,bulletcolor=9,primary="bolt",secondary="bolt",secondaryshots=3,psets="3;4;9;3;3;10",guns="2;0;5;0",exhaustcolors="11;15;5",exhausts="-1;4;0;4",flyduration=10',

 -- superboss
 s2t's=100,bulletcolor=11,primary="bolt",secondary="beam",secondaryshots=3,psets="3;4;7;3;3;11",guns="2;0;5;0",exhaustcolors="7;10;2",exhausts="-1;4;0;4"',
}

-- helpers
local function getblink()
 return flr((t()*12)%3)
end

local function drawblinktext(_str,_startcolor)
 print('\^w\^t'.._str,64-#_str*4,48,_startcolor+getblink())
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

local function shipsfx(_ship,_sfx)
 if not _ship.loopingsfx then
  sfx(_sfx,_ship.plidx)
 end
end

local burningcolors=split'10,9,5'
local function newburning(_x,_y)
 local _life=8+rnd()*4
 add(ps,{
  x=_x,y=_y,
  r=0.5,
  spdx=(rnd()-0.5)*0.125,
  spdy=rnd()*0.25+1,
  spdr=0.25*rnd(),
  colors=burningcolors,
  life=_life,lifec=_life,
 })
end

local hitcolors=split'7,7,10'
local function newhit(_x,_y)
 sfx(11,3)
 for _i=1,7 do
  add(ps,{
   x=_x+(rnd()-0.5)*5,
   y=_y+(rnd()-0.5)*5,
   r=rnd()*5,
   spdx=(rnd()-0.5)*2,
   spdy=rnd()-0.5,
   spdr=-0.2,
   colors=hitcolors,
   life=4,lifec=4,
  })
 end
end

local smokecolors={5}
local function explosionsmoke(_x,_y)
 local _life=rnd()*10+25
 add(ps,{
  x=_x,y=_y,r=8,
  spdx=(rnd()-0.5),spdy=rnd()-1.22,spdr=-0.28,
  colors=smokecolors,
  life=_life,lifec=_life,
 })
end

local function newexhaustp(_xoff,_yoff,_ship,_colors,_life,_vdir)
 add(psfollow,{
  x=0,y=0,r=0,
  follow=_ship,
  xoff=_xoff,yoff=_yoff,
  spdx=0,spdy=(0.1+rnd())*_vdir,spdr=0,
  colors=_colors,
  life=_life,lifec=_life,
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
 sfx(10,3)
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
 sfx(18,3)
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
local function emptydraw()
end

local function drawbullet(_bullet)
 sspr(5,119,1,4,_bullet.x,_bullet.y)
end

local function drawaegis(_x,_y)
 circ(_x,_y,6,1)
 fillp(rnd(32767))
 circ(_x+rnd(2)-1,_y+rnd(2)-1,6,8)
 fillp()
end

local function drawshield(_x,_y)
 circ(_x,_y,6,1)
 fillp(rnd(32767))
 circ(_x+rnd(2)-1,_y+rnd(2)-1,6,12)
 fillp()
end

local function drawmine(_bullet)
 _bullet.frame+=(t()*0.375)/_bullet.life
 if _bullet.frame > 2 then
  _bullet.frame=0
 end
 sspr(2*flr(_bullet.frame),126,2,2,_bullet.x,_bullet.y)
end
local function shootmine(_ship,_life,_angle)
 shipsfx(_ship,13)
 add(bullets,{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  spdx=cos(_angle+rnd(0.02)),spdy=sin(_angle+rnd(0.02)),accy=0,
  dmg=8,
  life=_life,
  draw=drawmine,
  ondeath=explode,
 })
end

local missilepcolors=split'7,10,9'
local function drawmissile(_bullet)
 sspr(4,123,3,5,_bullet.x-_bullet.hw,_bullet.y)
end
local function shootmissile(_ship,_life)
 shipsfx(_ship,12)
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

local flakcolors=split'7,10,5'
local function drawflakbullet(_bullet)
 pset(_bullet.x,_bullet.y,flakcolors[getblink()+1])
end
local function getflakbullet(_x,_y,_spdx,_spdy,_life)
 return {
  x=_x,y=_y,
  hw=1,hh=1,
  spdx=_spdx,
  spdy=_spdy,
  accy=0.01,
  spdfactor=0.95,
  dmg=2,
  life=_life,
  draw=drawflakbullet,
  ondeath=fizzle,
 }
end
local function shootflak(_ship,_amount,_life)
 shipsfx(_ship,17)
 for _i=1,_amount do
  local _spdx,_spdy,_blife=1+rnd(2),rnd(1)-0.5,_life+rnd(20)-40
  add(bullets,getflakbullet(_ship.x,_ship.y,_spdx,_spdy,_blife))
  add(bullets,getflakbullet(_ship.x,_ship.y,-_spdx,_spdy,_blife))
 end
end

local blinkpcolors=split'7,11,11,3,5'
local function blinkaway(_ship,_dx,_dy,_h)
 shipsfx(_ship,21)
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

local beampcolors=split'7,7,14'
local dirs={1,-1}
local function drawbeam(_bullet)
 local _x,_topy,_bottomy=_bullet.x,_bullet.y-_bullet.hh,_bullet.y+_bullet.hh
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
local function shootbeam(_ship)
 local _hh=_ship.y/2
 add(bullets,{
  x=_ship.x,y=_hh-6,
  hw=3,hh=_hh,
  spdx=0,
  spdy=0,
  accy=0,
  spdfactor=0,
  dmg=0.25,
  life=1,
  draw=drawbeam,
 })
end

local function shootboost(_ship)
 add(bullets,{
  x=_ship.x,y=_ship.y+8,
  hw=3,hh=5,
  spdx=0,
  spdy=0,
  accy=0,
  spdfactor=0,
  dmg=1,
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

local function updatebubble(_bullet,_otherbullets)
 for _other in all(_otherbullets) do
  if isaabbscolliding(_bullet,_other) then
   _bullet.life=0
   _other.life=0
   break
  end
 end
end
local function updatefriendlybubble(_bullet)
 updatebubble(_bullet,enemybullets)
end
local function drawbubble(_bullet)
 circ(_bullet.x,_bullet.y,2,12)
 pset(_bullet.x-1,_bullet.y-1,7)
end
local bubblepcolors=split'14,12,4'
local function shootbubble(_ship)
 for _i=1,3 do
  local _life=10+rnd(20)
  add(ps,{
   y=_ship.y,x=_ship.x,
   r=1+rnd(1),
   spdx=rnd(0.5)-0.25,
   spdy=rnd(0.5)-0.25,
   spdr=-0.05,
   colors=bubblepcolors,
   life=_life,
   lifec=_life,
  })
 end
 add(bullets,{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2.5,
  spdx=rnd()-0.5,spdy=rnd()-0.5,
  accy=0,spdfactor=0.96,
  dmg=2,
  life=190,
  update=updatefriendlybubble,
  ondeath=fizzle,
  draw=drawbubble,
 })
 shipsfx(_ship,29)
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
  if _ship.isboosting then
   shootboost(_ship)
  end
 end,
 mines=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   shootmine(_ship,_ship.primaryc*4+30,0.375+rnd(0.1))
   shootmine(_ship,_ship.primaryc*4+30,0.125-rnd(0.1))
   _ship.primaryc=0
  end
 end,
 shield=function(_btn4,_ship)
  _ship.isshielding=_ship.primaryc > 0 and not _btn4
 end,
 aegis=function(_btn4,_ship)
  _ship.isaegising=_ship.primaryc > 0 and not _btn4
 end,
 blink=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 then
   local _dx,_dy=getdirs(_ship.plidx)
   blinkaway(_ship,_dx,_dy,_ship.primaryc*1.25)
   _ship.primaryc=0
  end
 end,
 flak=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   shootflak(_ship,max(2,flr(_ship.primaryc/3)),_ship.primaryc*6)
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
 bubbles=function(_btn4,_ship)
  if not _btn4 and _ship.primaryc > 1 and _ship.primaryc % 4 < 1 then
   shootbubble(_ship)
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

local function firesecondary(_ship,_secondaryc)
 if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
  _ship.secondaryshots-=1
  _ship.secondaryc=_secondaryc
 end
end

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
  firesecondary(_ship,100)
  if _ship.secondaryc > 0 then
   _ship.isboosting=true
   shootboost(_ship)
  end
 end,
 mines=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootmine(_ship,160,0.375)
   shootmine(_ship,160,0.125)
   _ship.secondaryshots-=1
  end
 end,
 shield=function(_ship)
  _ship.secondaryc-=1
  firesecondary(_ship,150)
  if _ship.secondaryc > 0 then
   _ship.isshielding=true
  end
 end,
 aegis=function(_ship)
  _ship.secondaryc-=1
  firesecondary(_ship,170)
  if _ship.secondaryc > 0 then
   _ship.isaegising=true
  end
 end,
 blink=function(_ship)
  local _dx,_dy=getdirs(_ship.plidx)
  if _ship.secondaryshots > 0 and (
    (btnp(5,_ship.plidx) and (_dx != 0 or _dy != 0)) or
    (btn(5,_ship.plidx) and (btnp(0,_ship.plidx) or btnp(1,_ship.plidx) or btnp(2,_ship.plidx) or btnp(3,_ship.plidx)))
  ) then
   _ship.secondaryshots-=1
   blinkaway(_ship,_dx,_dy,20+flr(rnd(38)))
  end
 end,
 flak=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootflak(_ship,8,160)
   _ship.secondaryshots-=1
  end
 end,
 beam=function(_ship)
  _ship.secondaryc-=1
  firesecondary(_ship,45)
  if _ship.secondaryc > 0 then
   _ship.isbeaming=true
   shootbeam(_ship)
  end
 end,
 bubbles=function(_ship)
  _ship.secondaryc-=1
  firesecondary(_ship,20)
  if _ship.secondaryc > 0 and _ship.secondaryc % 2 == 0 then
   shootbubble(_ship)
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

local weaponcolors=s2t'missile=13,boost=9,mines=5,shield=12,aegis=2,blink=3,flak=15,beam=8,bubbles=14,bolt=6'

local boostcolors=split'7,10,9,8'

local secondarysprites={
 missile=split'5,123',
 boost=split'8,123',
 mines=split'2,124',
 shield=split'11,123',
 aegis=split'14,123',
 blink=split'17,123',
 flak=split'20,123',
 beam=split'23,123',
 bubbles=split'26,123',
 bolt=split'29,123'
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
 sfx(12,3)
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
 sspr(2*flr(_bullet.frame),121,2,2,_bullet.x,_bullet.y)
end
local function enemyshootmine(_enemy)
 sfx(13,3)
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
 sfx(8,3)
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
 pset(_bullet.x,_bullet.y,bossflakcolors[getblink()+1])
end
local function shootbossflak()
 sfx(17,3)
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

local function updatebossbubble(_bullet)
 updatebubble(_bullet,bullets)
end
local function drawbossbubble(_bullet)
 circ(_bullet.x,_bullet.y,2,14)
 pset(_bullet.x-1,_bullet.y-1,7)
end
local function shootbossbubble()
 add(enemybullets,{
  x=boss.x,
  y=boss.y,
  hw=2,hh=2.5,
  spdx=rnd()-0.5,spdy=rnd()-0.5,
  accy=0,spdfactor=0.96,
  dmg=1,
  life=210,
  update=updatebossbubble,
  ondeath=fizzle,
  draw=drawbossbubble,
 })
 sfx(29,2)
end

local blinkdirs=split'-1,0,1'
local superbossweaponnames=split'missile,mines,boost,shield,blink,flak,beam,bolt,bubbles,bullet'
local bossweapons={
 missile=enemyshootmissile,
 mines=enemyshootmine,
 boost=function()
  boss.boostts=t()
  boss.boost=0.5
  sfx(15,2)
 end,
 shield=function()
  boss.shieldts=t()
  sfx(19,2)
 end,
 aegis=function()
  boss.aegists=t()
  sfx(20,2)
 end,
 blink=function()
  blinkaway(boss,rnd(blinkdirs),rnd(blinkdirs),38)
  boss.y=mid(4,boss.y,64)
 end,
 flak=shootbossflak,
 beam=function()
  boss.beamts=t()
  boss.boost=-0.25
  sfx(16,2)
 end,
 bubbles=function() 
  shootbossbubble()
  shootbossbubble()
  shootbossbubble()
 end,
 bolt=shootbossbolt,

 bullet=function()
  enemyshootbullet(boss)
 end,
}

local minelayerexhaustcolors={12}
local function newminelayer()
 add(enemies,mrs2t('y=-12,hw=4,hh=4,spdx=0,spdy=0,s=103,hp=5',{
  x=rnd(128),
  ts=t(),
  update=function(_enemy)
   local _x,_y=flr(_enemy.x),flr(_enemy.y)-3
   newenemyexhaustp(_x-1,_y,minelayerexhaustcolors)
   newenemyexhaustp(_x,_y,minelayerexhaustcolors)
   if _enemy.target then
    if t()-_enemy.ts > _enemy.duration or ispointinsideaabb(_enemy.target.x,_enemy.target.y,_enemy.x,_enemy.y,_enemy.hw,_enemy.hh) then
     _enemy.target=nil
    end
   else
    _enemy.spdx,_enemy.spdy=0,0
    if t()-_enemy.ts > 1.5 then
     enemyshootmine(_enemy)
     _enemy.ts,_enemy.duration,_enemy.target=t(),1+rnd(2),{x=4+rnd(120),y=rnd(92)}
     local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
     _enemy.spdx,_enemy.spdy=cos(_a)*0.75,sin(_a)*0.75
    end
   end
  end,
 }))
end

local kamikazeexhaustcolors=split'10,9'
local function newkamikaze()
 add(enemies,mrs2t('y=-12,hw=4,hh=4,spdx=0,spdy=0,s=101,hp=4',{
  x=rnd(128),
  update=function(_enemy)
   local _x=flr(_enemy.x)
   local _y=flr(_enemy.y)-3
   newenemyexhaustp(_x-1,_y,kamikazeexhaustcolors)
   newenemyexhaustp(_x,_y,kamikazeexhaustcolors)
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
 }))
end

local bomberexhaustcolors=split'11,3'
local function newbomber()
 local _spdy=rnd(0.25)+0.325
 add(enemies,mrs2t('x=0,y=-12,hw=4,hh=4,spdx=0,accx=0,s=104,hp=9',{
  spdy=_spdy,ogspdy=_spdy,
  ts=t(),
  update=function(_enemy)
   local _x=flr(_enemy.x)
   local _y=flr(_enemy.y)-4
   newenemyexhaustp(_x-3,_y,bomberexhaustcolors)
   newenemyexhaustp(_x-2,_y,bomberexhaustcolors)
   newenemyexhaustp(_x+1,_y,bomberexhaustcolors)
   newenemyexhaustp(_x+2,_y,bomberexhaustcolors)
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
 }))
end

local fighterexhaustcolors=split'14,2,4'
local function newfighter()
 add(enemies,mrs2t('x=0,y=-12,hw=4,hh=4,spdx=0,spdy=0,accx=0,s=102,hp=5',{
  ts=t(),
  update=function(_enemy)
   local _x,_y=flr(_enemy.x),flr(_enemy.y)-4
   newenemyexhaustp(_x-1,_y,fighterexhaustcolors)
   newenemyexhaustp(_x,_y,fighterexhaustcolors)
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
 }))
end

local enemycargobulletpcolors=split'7,6,15'
local function drawenemycargobullet(_bullet)
 rectfill(_bullet.x,_bullet.y,_bullet.x+1,_bullet.y+1,7)
end
local function enemyshootcargobullet(_enemy)
 add(enemybullets,mrs2t('hw=1,hh=1,life=1000,spdy=1,accy=0,spdfactor=1',{
  x=_enemy.x,y=_enemy.y,
  spdx=_enemy.s == 109 and -1 or 1,
  draw=drawenemycargobullet,
  ondeath=explode,
  p=mrs2t('xoff=0,yoff=0,r=0.1,spdx=0,spdy=0,spdr=0,life=3',{ colors=enemycargobulletpcolors }),
 }))
end

local cargoshipexhaustcolors=split'7,6,13'
local cargoshipsprites=split'106,107,108,109'
local function newcargoship()
 local _allparts,_x={},flr(16+rnd(100))
 for _i=1,flr(2+rnd(4)) do
  local _s=_i == 1 and 105 or rnd(cargoshipsprites)
  local _part=mrs2t('hw=4,hh=4,spdx=0,spdy=0,accx=0,hp=14',{
   x=_x,y=-(12+_i*8),
   s=_s,
   ts=t(),
   update=function(_enemy)
    local _x=flr(_enemy.x)
    local _y=flr(_enemy.y)-4
    if _enemy == _allparts[#_allparts] then
     newenemyexhaustp(_x-1,_y,cargoshipexhaustcolors)
     newenemyexhaustp(_x,_y,cargoshipexhaustcolors)
    end
    if _y > 130 then
     del(enemies,_enemy)
    end
    _enemy.spdy=0.25
    if _enemy.s >= 108 and t()-_enemy.ts > 2+rnd(2) then
     enemyshootcargobullet(_enemy)
     _enemy.ts=t()
    end
   end,
  })
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
   _ship.isshielding,_ship.isaegising,_ship.isboosting,_ship.isbeaming=nil
  end

  if _ship.hp < 3 then
   newburning(_ship.x,_ship.y)
   _ship.primaryc=max(0,_ship.primaryc-0.0875)
   if btnp(4,_plidx) then
    _ship.primaryc+=2.5
    if _ship.primaryc >= 37 then
     sfx(24,_ship.plidx)
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
      shipsfx(_ship,8+_ship.plidx)
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

  for _i=1,#_ship.exhausts,2 do
   newexhaustp(
    _ship.exhausts[_i],
    _ship.exhausts[_i+1],
    _ship,
    _ship.isboosting and boostcolors or _ship.exhaustcolors,
    _ship.isboosting and 5 or 4,
   1)
  end

  if _ship.loopingsfx and not (_ship.isboosting or _ship.isbeaming or _ship.isshielding or _ship.isaegising) then
   _ship.loopingsfx=nil
   sfx(-2,_plidx)
  elseif not _ship.loopingsfx then
   if _ship.isboosting then
    _ship.loopingsfx=true
    sfx(15,_plidx)
   elseif _ship.isbeaming then
    _ship.loopingsfx=true
    sfx(16,_plidx)
   elseif _ship.isshielding then
    _ship.loopingsfx=true
    sfx(19,_plidx)
   elseif _ship.isaegising then
    _ship.loopingsfx=true
    sfx(20,_plidx)
   end
  end

  for _cargo in all(cargos) do
   if isaabbscolliding(_ship,_cargo) then
    del(cargos,_cargo)
    _ship.secondaryshots=3
    sfx(25,3)
   end
  end

  if boss and isaabbscolliding(_ship,boss) then
   if nickitts then
    del(ships,_ship)
    add(ships,mr(getship(boss.s),{plidx=_plidx,x=_ship.x,y=_ship.y,hp=1}))
    createshipflashes()
    nickedts=curt
    escapeelapsed,nickitts,boss=0
    sfx(1,2)
   elseif _ship.isaegising then
    boss.hp-=0.5
    newhit(boss.x,boss.y)
   else
    explode(_ship)
    explode(boss)
    _ship.hp,boss=0
    sfx(-2,2)
   end
  end

  if _ship.hp == 0 then
   explode(_ship)
   sfx(-2,_ship.plidx)
   del(ships,_ship)
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
      sfx(21+_ship.hp,_ship.plidx)
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
   for _i=1,#boss.exhausts,2 do
    newexhaustp(
     boss.exhausts[_i],
     -(boss.exhausts[_i+1]+0.5),
     boss,
     boss.boostts and boostcolors or boss.exhaustcolors,
     boss.boostts and 5 or 4,
    -1)
   end
  end

  local _bossdt=curt-boss.ts
  if boss.hp <= 0 then
   sfx(-2,2)
   if issuperboss then
    for _enemy in all(enemies) do
     _enemy.hp=0
    end
    for _bullet in all(enemybullets) do
     _bullet.life=0
    end
    explode(boss)
    explode(boss)
   else
    newburning(boss.x,boss.y)
    if not nickitts then
     nickitts=curt
    end
   end
  else
   if _bossdt > boss.flydurationc then
    if _bossdt > boss.flydurationc+boss.waitdurationc then
     bossweapons[rnd{boss.primary,boss.primary,boss.secondary}](boss)
     boss.waitdurationc,boss.flydurationc,boss.ts=0.875+rnd(1.75),boss.flyduration+rnd(5),curt
     if issuperboss then
      boss.primary=rnd(superbossweaponnames)
     end
    end
   else
    if boss.targetx == nil or ispointinsideaabb(boss.targetx,boss.targety,boss.x,boss.y,boss.hw,boss.hh) then
     local _targety=8+rnd(36)
     if boss.aegists then
      _targety+=42
     end
     boss.targetx,boss.targety=4+rnd(120),_targety
    end

    if boss.boostts then
     add(enemybullets,{
      x=boss.x,y=boss.y-8,
      hw=3,hh=5,
      spdx=0,
      spdy=0,
      accy=0,
      spdfactor=0,
      dmg=1,
      life=1,
      draw=emptydraw,
     })

     if t()-boss.boostts > 2 then
      boss.boost,boss.boostts=0
      sfx(-2,2)
     end
    end

    if boss.shieldts and t()-boss.shieldts > 2.25 then
     boss.shieldts=nil
     sfx(-2,2)
    end

    if boss.aegists and t()-boss.aegists > 2.25 then
     boss.aegists=nil
     sfx(-2,2)
    end

    if boss.beamts then
     add(enemybullets,{
      x=boss.x,y=boss.y+64+6,
      hw=3,hh=64,
      spdx=0,
      spdy=0,
      accy=0,
      spdfactor=0,
      dmg=1,
      life=1,
      draw=drawbeam,
     })
     if t()-boss.beamts > 2 then
      boss.boost,boss.beamts=0
      sfx(-2,2)
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
 local issuperbossdead=issuperboss and (boss == nil or boss.hp <= 0)

 -- update enemies
 local _spawninterval=max(0.75,10*lockedpercentage)
 local _spawnmin=3
 if escapeelapsed then
  _spawninterval=max(0.75,5*lockedpercentage)
  _spawnmin=6
 end
 if nickitts == nil and (not (hasescaped or issuperbossdead)) and (t()-enemyts > _spawninterval and #enemies < min(15,10+dget(63))  or #enemies < _spawnmin) then
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
   _enemy.x+=_enemy.spdx*(issuperboss and 1.5 or 1)
   _enemy.y+=_enemy.spdy*(issuperboss and 1.25 or 1)
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
    if isaabbscolliding(_enemy,_ship) then
     explode(_enemy)
     del(enemies,_enemy)
     if not _ship.isaegising then
      _ship.hp-=1
      _ship.primaryc=0
      if _ship.hp > 0 then
       sfx(21+_ship.hp,_ship.plidx)
      end
     end
    end
   end
  end
 end

 if ((hasescaped and #enemies == 0) or issuperbossdead) and not madeitts then
  if issuperbossdead and boss then
   boss=nil
   dset(63,dget(63)+1)
  end
  if ships[1] then
   madeitts,exit=t(),s2t'x=64,y=0,hw=64,hh=8'
   sfx(3)
  end
 end

 local _isshipinsideexit=nil
 if exit then
  for _ship in all(ships) do
   if isaabbscolliding(_ship,exit) then
    _isshipinsideexit=true
   end
  end
 end

 if #ships == 0 and not gameoverts then
  sfx(2)
  gameoverts=t()
 end

 if ((hasescaped or issuperbossdead) and madeitts and _isshipinsideexit) or
    gameoverts and t()-gameoverts > 1 and btnp(4) then
  sfx(4)
  pickerinit()
  return
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
  spr(_enemy.s+(issuperboss and 9 or 0),_enemy.x-4,_enemy.y-4)
 end

 -- draw ships
 for _ship in all(ships) do
  local _urx,_ury=_ship.x-4,_ship.y-4
  spr(_ship.s,_urx,_ury)

  if _ship.isfiring then
   spr(254+_ship.plidx,_urx,_ury)
  end
 end

 -- draw exit
 if exit then
  local _frame=getblink()
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
   elseif boss.aegists then
    drawaegis(boss.x,boss.y)
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

  if _ship.isaegising then
   drawaegis(_ship.x,_ship.y)
  end
 end

 -- draw debug bullet mids
 -- for _b in all(enemybullets) do
 --  pset(_b.x,_b.y,11)
 -- end
 -- for _b in all(bullets) do
 --  pset(_b.x,_b.y,12)
 -- end

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
    print('\ferepair',_xoff+13,121)
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
  local _frame=getblink()
  sspr(39+_frame*5,123,5,5,boss.x-2,boss.y+8)
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
 escapeduration,lockedpercentage=40,#getlocked()/100

 for i=1,24 do
  add(stars,{
   x=flr(rnd()*128),
   y=flr(rnd()*128),
   spd=0.5+rnd(0.5),
  })
 end

 createshipflashes()

 sfx(0,3)

 _update60,_draw=gameupdate,gamedraw
end

local picks={[0]=0}
function pickerupdate()
 for _i=0,1 do
  if picks[_i] then
   if btnp(0,_i) then
    picks[_i]-=1
    sfx(26)
  elseif btnp(1,_i) then
    picks[_i]+=1
    sfx(26)
  elseif btnp(2,_i) then
    picks[_i]-=10
    sfx(26)
  elseif btnp(3,_i) then
    picks[_i]+=10
    sfx(26)
   end
   picks[_i]=mid(0,picks[_i],99)

   if btnp(5,_i) and _i == 1 then
    picks[_i]=nil
    sfx(27)
  elseif btnp(4,_i) and isunlocked(picks[_i]) then
    local _ship=mr(getship(picks[_i]),{plidx=_i,x=32+_i*64})
    ships[_i+1]=_ship
    sfx(28,3)

    local _pickcount=mycount(picks)
    if _pickcount > 0 and _pickcount == mycount(ships) then
      local _locked=getlocked()
     if #_locked == 0 then
      issuperboss=true
      boss=mr(getship(100),s2t'x=64,y=40,hp=127,flydurationc=3,waitdurationc=1,boost=0,flyduration=1,plidx=2')
     else
      issuperboss=nil
      boss=mr(getship(rnd(_locked)),s2t'x=64,y=0,hp=127,flydurationc=8,waitdurationc=2,boost=0,plidx=2')
     end
     boss.ts=t()
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

local newship
function pickerdraw()
 cls()
 if dget(63) > 0 then
  print('\fdsecret hangar     \f8boss kills:'..dget(63),2,1)
 else
  print('\fdsecret hangar',38,1)
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
   if _pick == newship then
    newship=nil
   end
   print(_s,1+_i*127-_i*#_s*4,122,11+_i)
  end
 end
 for _x=0,9 do
  for _y=0,9 do
   local _s,_x,_y=_y*10+_x,10+_x*11,8+_y*11
   if isunlocked(_s) then
    spr(_s,_x,_y)
    if _s == newship then
     print('new',_x-1,_y+5,10+getblink())
    end
   else
    spr(120,_x,_y)
   end
  end
 end
end

function pickerinit()
 sfx(-2,0)
 sfx(-2,1)
 sfx(-2,2)
 if #getlocked() == 100 then
  unlock(rnd(getlocked()))
  unlock(rnd(getlocked()))
 end
 newship=nil
 for _ship in all(ships or {}) do
  if not isunlocked(_ship.s) then
   newship=_ship.s
  end
  unlock(_ship.s)
 end
 ships={}
 _update60,_draw=pickerupdate,pickerdraw
end

-- splash
_update60=emptydraw
_draw=function ()
 if btnp(4) then
  pickerinit()
 end

 cls()
 sspr(unpack(split'0,64,128,54,0,18'))
 print('\fbpress \x8e',48,121)
end
-- _init=pickerinit

__gfx__
00066000000dd000000dd000000cc000000550000900009000022000000220000070070000088000000880000009900007000070000660000002200000033000
000af000005dd500040ab04000dabd00004b3400090000900057e500005225000700007000088000000650000097690078000087006dd6000007600000ba9b00
00dffd00005e2500046bb6400ddbbdd004d33d40690b3096005ee50000598500760000670007b00000855800086766807800008706dabd60005665000b3993b0
06dffd6006522560d66bb66dddcbbcdd44d33d4469033096025ee52006688660760b306700fbbf000825528082699628780a90870d4bb4d005266250b3d99d3b
66d66d666d5225d6d66dd66ddcdccdcd06d55d6069433496245225426ff88ff676d33d67f0fbbf0f0028820082899828780990870d4bb4d052266225bd5dd5db
00d66d006d5dd5d6004dd400cdccccdc6dd55dd696d66d6924422442f652256f76d77d67f2f88f2f082882809289982988599588d44dd44d52288225bd5335db
06d66d6066dddd660d6dd6d0dc0550cd6d0550d699466499224224226552255607677670f2f88f2f822882289289982968588586d46dd64d52288225b500005b
66d55d66044004400d0550d0c000000c6600006609055090dd0dd0dd054004500067760002f88f20055005509000000966088066006446005005500530000003
000dd00000022000000ee00000422400000550000060060000d55d0000066000000990000f0f0000000dd0000200002000044000000660000009900000088000
00d76d00002a9200006ee6000542245000555500006996000dd55dd0006a960000da8d000f0f0000040ab040e200002e00db3d00006826000009900000888800
0f6766f0029a992005782750554994550d59e5d000dbcd000dd11dd006d99d6000d88d004f4f40ab04dbbd40e20cd02e08d33d8006f22f60000bc000028a9820
ff6446ff2492294265282256449a99440de9eed060dccd065d1c11d5dfd99dfd0d6886d04ddd40bbdd5bb5dde20dd02e2dd33dd27f6226f7006cc600229a9922
00d44d0024422442762ee267429a99244de44ed4694cc4965d1111d5dfdffdfd6d6996d6ddddd544d55dd55de24dd42e28d44d8276f77f67006cc60028988982
0d5445d022422422d7eeee7d422992244d5445d4d949949d5dd11dd56fdffdf66dc99cd6d545d545000dd000e242242e8dd44dd87ff77ff770699607d828828d
d554455d05500550d545545d05244250dd5445ddd949949d0d5dd5d06f0dd0f6cdc99cdcd454d0450d5dd5d0220220228d0550d86f0550f679699697d828828d
d540045d04500540d404404d004444000220022005500550005dd50060000006c0c44c0c055500000d5445d0e200002e82000028600000066969969605055050
060660600c0000c00060060000077000000330000062260000dffd0000d66d000005500000dffd0000f00f000600006000044000000660000006600000088000
600b30066c0000c606000060007d470000f33f000d6226d00dffffd00fd66df0000ab00005dffd500f0000f062000026004af4006007f006006e860000822800
60f33f066c0b30c66d0000d607c44c7000f7bf000d67c6d05dfbbfd5dfd92dfd007bb70055d66d55fd0000df620bc026041ff140655ff5560d8e88d008276280
f046640f6c0330c66d0820d6c6c44c6c03b7bb30d6c7cc6dfdb7bbdf6d2922d6076bb670dd6766ddfd07b0df625cc526415ff514600ff006d486684d02466420
404664046c4334c66d4224d6c6c77c6c3fb66bf326c22c62fdb7bbdf6d2442d676655667df6766fdfd4bb4df625225264514415460066006d4d66d4d02466420
400ff004c6d66d6c6d4664d676c77c673f3663f326222262fddbbddffdf44fdf00733700dff66ffd4d4ff4d422022022411441146556655664d66d4624422442
45466454cc4664cc06d66d60760cc067303663030d2222d005dffd5004f44f400763367005fddf5004dffd40f200002f410550146006600664d66d4624822842
404664040c0550c000d66d00700000070004400000d55d000550055000d44d007665566700dddd0000fddf000f0000f040000004600000066550055600844800
000cc00000066000000bb00000088000000ff000000ff0000006600000edde0000400400000bb00000d00d000a0000a000033000050000500003300003000030
000cc0000d09f0d00607e06000276200000ff00000fbcf00000660000edddde00f4004f000b7bb0000d33d00a200002a0003300005076050000a9000c300003c
000a90000d7ff7d0063ee36002266220006ab6000ffccff0000a50005edaade5fddffddf0fb7bbf000da9d00a200002a000a5000df0660df00599500cd0000dc
00d99d00677ff776b33ee33b02066020006bb60006fccf6000d55d00dea7aaedfdda9ddf0fb7bbf000d99d00a20b302a00f55f00fd4fd4dd04599540cd0a90dc
00d99d0067766776b33bb33b00088000096bb690f6f66f6f00f55f00dea7aaedfd9a99df04bbbb400bd99db0a203302a00f55f00dd4dd4fd54533545dd0990dd
60dccd0600066000000bb000080880809f6ff6f96f6ff6f60f6ff6f0deeaaeedfd9ff9df54fbbf45bbd33dbb2253352260f33f06fd0df0df005335003d5995d3
6cdccdc6007667000b3bb3b0824884289f6ff6f9f66ff66f66f66f660dedded00fdffdf0f5f55f5f03d33d309252252963f33f36550dd05504355340dc5cc5cd
dcdccdcd000550000b3553b08505505890d55d0905500550f6d66d6f005dd500005ff500054554503303303399022099f3f33f3f0005500054355345dc0cc0cd
0005500000088000000ff0000004d00000077000000dd00003000030000ee00004000040000ff000004dd40000022000000dd00000088000000330000f0ff0f0
000550000006d0000d0ab0d0000d40000076c700000dd0000b3003b000eb3e0042000024009ff9000d4994d0002b320000dabd000007e00000333300ff0760ff
000e2000000dd0000d4bb4d0000e80000bc6ccb0005bc50000be2b000023320042000024009ab9000d9a99d0028338200fbabbf0200ee0020537635067566576
00f22f00008dd800454bb45400f88f00b3c77c3b005cc500000220000e2332e0420980240fbabbf00d9a99d0282332820fbabbf02f0ee0f205676650f606606f
00f22f000e8dd8e0545ff54500f88f00b3b77b3b0f5cc5f00b3223b0e224422e42088024f9b99b9f0d9999d0828228280fbddbf02f2882f2d56dd65d675ff576
d0f55f0d2e8ee8e2000ff00060fd4f0673b77b37fd5dd5dfb33bb33b04d22d4022188122ff9999ff5d5995d5282222824fddddf40f2882f0d53dd35df65ff56f
d5f55f5d2e8ee8e2045ff54064f4dfd673b77b37fd5dd5dfb30bb03b5d0440d52412214200f44f005d5dd5d58205502845d44d540f2882f05d3dd3d5670ff076
f5f55f5f00055000054dd450fdf4df4f70044007f0f44f0fb004400b0500005044022044000550005050050580000008400000040025520005500550f000000f
d00dd00d07000070000ff0000052250000028000070000700f0000f000077000000bb000000ff000000ff0000000d0d00d0000d0000660000000060000066000
0d2dd2d07900009700f66f0005522550000820007e0000e70f0000f00039830000c76c0000cffc0000fbcf0000007670d500005d000c50000000d6d000d66d00
002ab200790000970f6766f0555bc555000760007e0000e77607b067033883300c6766c00fcb9cf00f5cc5f0e2067676d509e05d002552007906d6d600de2d00
0dbabbd0790e8097fd6766df25cbcc5200d66d007e0bc0e7760bb06700688600bc6bb6cb0f9b99f05d5cc5d522076767d50ee05d042552409906d6d607d22d70
d2b22b2d79088097fdd66ddf25c55c52d0d66d0d7e5cc5e76657756606377360bccbbccbdf9cc9fd5d5ff5d577476767d545545d442662446656d6d676d22d67
d2d22d2d9958859904dffd4025455452d4d28d4dee5ee5ee7606606763377336bbcbbcbbdcfccfcdfd5ff5df7647676755455455400660046d5d666d76d66d67
d0d44d0da959959a05dffd5002455420c4d82d4c6e0ee0e6f500005f63055036044004405d5dd5d5fd0550df76067776d505505d002662006d066d6677666677
000ff000aa0990aa055005500045540004c28c4006000060ff0000ff600000060d4004d004400440f000000f5505505505044050042552400006d0d604400440
000dd00000f00f00060000600050050000400400d000000d0005500004055040055005504d4444d4044444400444444004444440044444404000000400055000
000dd0000d0000d0700000070d0000d002000020d405504d4dd44dd4d404404d444dd4444d4444d44d4dd4d44d4dd4d44dddddd44dddddd44205502442422424
00076000f70d507f70077007d009900d200bb002d44dd44d4dd44dd444544544d44dd44d4d4444d44d4dd4d44d4dd4d44dd44dd44dd44dd44224422442422424
00d66d00d705507d600b3006d09a990d20bbbb02d44dd44d4dd44dd4d454454dd4bddb4d4d6766d44dd44dd44d4dd4d44d4dd4d44d4dd4d44424424440422404
00c66c00f70ff07f70f33f070d9999d002b7bb20d44a944d40d7ed04d40bc04d04babb400d6766d04dd44dd44d4dd4d44d4d64d44d46d4d4424a94240047e400
30cddc03d70ff07d74677647d449944d244bb4420d4994d0000ee000d40cc04d04dabd4004d66d404d4dd4d44d4dd4d44dd446d44d644dd404299240000ee000
3dcddcd30d0000d0f467764f004dd4000042240000d99d00000ee000d400004d00dddd0004d44d404d4dd4d44d4dd4d44dddddd44dddddd400499400000ee000
cdcddcdc00d00d00600ff006040550400405504000044000000440000d0000d0000dd00000d44d00044444400444444004444440044444400004400000022000
24055042055005504242242404444440044444400442244004422440000000000000000000000000000000000000000000000000000000000000000000000000
24022042424224244242242442222424424224244244442442444424000000000011110000000000000000000000000000000000000000000000000000000000
44522544224224220242242044444424042442400442244004422440005ff5000110011000000000000000000000000000000000000000000000000000000000
2452254224b22b42426226244242242442422424442222444422224400f5ff000000011000000000000000000000000000000000000000000000000000000000
440bc04404babb40026766204242242442422424042262400426224000ff5f000001110000000000000000000000000000000000000000000000000000000000
240cc042042ab2404427624442444444042442404442264444622444005ff5000000000000000000000000000000000000000000000000000000000000000000
24000042002222000442244042422224424224244244442442444424000000000001100000000000000000000000000000000000000000000000000000000000
02000020000220000042240044444444044444400442244004422440000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111aa1a1a1aaa1aaa1aa11aaa11aa1a1a1aaa1aaa11aa111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111a111a1a11a11a1a1a1a11a11a111a1a1a111a1a1a11111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111aaa1aaa11a11aaa1a1a11a11a111aa11aa11aa11aaa111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111a1a1a11a11a111a1a11a11a111a1a1a111a1a111a111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111aa11a1a1aaa1a111a1a1aaa11aa1a1a1aaa1a1a1aa1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000000000000000000000000000000000000003333333333333bbb3bbb3bbb3bbb3bbb3bbb330000000000000000
0000070000000000000000000000000000000000000000000000000000000000000000000033bbb33333333b3b3b333b3b3b3b33b33b3b330000000000000000
0000070000000000000000000000000000000000000000000000000000000000000000000033b3b33333333bb33bb33bbb3bbb33b33bb3337777777777777777
c55c070000000000000000000000000000000000000000000000000000000000000000000033bbb33333333b3b3b333b333b3b33b33b3b337777777777777777
5cc50a000000000000000000000000000000000000000000000000000000000000000000003333333333333b3b3bbb3b333b3b3bbb3b3b337777777777777777
00000060aa0000000070a008e87c007004d400000a0000b0000c0022222000022002220022222222222222288828882888288828882888227777777777777777
00000060aa00c08880b00008e8cc070000d00000aaa00bbb00ccc020000200020202220200208880000000080808000808080800800808027777777777777777
00000060a90c0c8280000708e8000070e0d0707aaaaabbbbbccccc20000020020202020200208080000000088008800888088800800880027777777777777777
85580060980c0c828b000008e80c070070d007000a0000b0000c0020000200020202020202208880000000080808000800080800800808027777777777777777
58850d6d8000c0080700a008e800070070d070700a0000b0000c0022222000022202020222222222222222282828882822282828882828227777777777777777
__sfx__
000e00001c2200622019220062201c220062201922006225012202322523220002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
000c00001c220062201d220072201e220082201f2200922523220232052322523220000000c22024220242200d220252202522000200002000020000200002000020000200002000020000200002000020000000
000f00001c2200622019220062201b2200522018220042201a2200322017220022201922001220162001620004200062000120001200002000020000200002000020000200002000020000200002000020000200
000e00001c2200621019220062201c2100621019220062201c2102322019220062101c22006220192100622004200062000120001200002000020000200002000020000200002000020000200002000020000200
001000002653300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002402300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
110800002402300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
151e0000124333f4031a4031d403194031740313403124030d4030c40308403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
490c00002143300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
040300001a3211c321234112e4111960115621126210f6110b6110a61108611076110661104611036110261101611003010030100301003010030100301003010030100301003010030100301003010030100301
161100002663509601126010e6010a601066010060100601006011260114601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100600
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
000400002e123291232e6202e625000002f6002e123291232e6202e62500000000000000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000000000000
010100001e0532a003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
000400001f0201f0201f0201d02015020110200e02009020060200202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001f0201f0201f0201f0202002024020290202d020300203100036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000220530050027551085511a551005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151e00200422500205042250221504225002050422500205042250020504225002000422502215042250421504225002050422500205042250020504225022150422500000042250420002225022250222502225
151e00200422500205042250221504225002050422500205042250020504225002000422502215042250421504225002050422500205042250020504225022150422500000042250421502225042230000002221
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 41424320
02 41424321

