pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- shipnickers 0.2
-- by ironchest games

--[[
 - fix mem leak
 - add bigger mines (graphics)
 - redesign bg color in hangar
 - move cargo sprite and police lights to old ship flashes
 - data loading from like excel sheet or smt?
 - does 2p work?
 - add cargo moving down while escaping
 - are all enemies working?
 - fix drawing of bullets (sometimes above sometimes below)
 - fix beam + boost bug (beam stops after btn up for boost)
 - no sound if enemy shooting off screen
 - fix psets
 - fix hangar flyduration?
 - unify game event code?

0x5e00+:
0-99 - unlocked
100-199 - killed boss

dget:
62 - nicks since police
63 - boss kill count

sfx channels:
0 - looping plidx 0
1 - looping plidx 1
2 - looping boss sounds
3 - general

--]]

-- cartdata'ironchestgames_shipnickers_v1'
-- cartdata'ironchestgames_shipnickers_v1-qa' -- ottos
-- cartdata'ironchestgames_shipnickers_v1-dev9' -- all unlocked
-- cartdata'ironchestgames_shipnickers_v1-dev10'
-- cartdata'ironchestgames_shipnickers_v1-dev11'
cartdata'ironchestgames_shipnickers_v1-dev12'

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable btnp auto-repeat

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

local function mycount(_t) -- todo: needed??
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

local function ispointinsideaabb(_x,_y,_ax,_ay,_ahw,_ahh)
 return _x > _ax-_ahw and _x < _ax+_ahw and _y > _ay-_ahh and _y < _ay+_ahh
end

local function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh
end

-- globals
local ships,bullets,stars,ps,psfollow,bottomps,enemies,enemiestoadd,enemybullets,boss,issuperboss,cargos,lockedpercentage,escapefactor

local hangar={
 [0]='s=0,bulletcolor=11,primary="missile",secondary="missile",psets="3;6;3_3;4;11",guns="2;1;5;1",exhaustcolors="7;9;5",exhausts="-1;4;0;4",flyduration=1',
 's=1,bulletcolor=12,primary="missile",secondary="boost",psets="3;5;2_3;3;8",guns="2;0;5;0",exhaustcolors="7;10;9",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=2,bulletcolor=10,primary="missile",secondary="mines",psets="3;6;11_3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4",flyduration=1',
 's=3,bulletcolor=10,primary="missile",secondary="shield",psets="3;5;11_3;3;10",guns="2;0;4;0",exhaustcolors="7;12;5",exhausts="-2;4;-1;4;0;4",flyduration=1',
 's=4,bulletcolor=15,primary="missile",secondary="ice",psets="3;6;3_3;4;11",guns="2;0;5;0",exhaustcolors="10;11;15",exhausts="-1;3;0;3",flyduration=1',
 's=5,bulletcolor=14,primary="missile",secondary="blink",psets="3;5;3_3;3;11",guns="1;0;6;0",exhaustcolors="14;8;2",exhausts="-1;3;0;3",flyduration=1',
 's=6,bulletcolor=15,primary="missile",secondary="flak",psets="3;6;14_3;4;7",guns="2;0;5;0",exhaustcolors="10;9;5",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4",flyduration=1',
 's=7,bulletcolor=12,primary="missile",secondary="beam",psets="3;5;8_3;3;9",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=8,bulletcolor=12,primary="missile",secondary="bubbles",psets="3;4;3_3;3;11",guns="2;0;5;0",exhaustcolors="14;8;2",exhausts="-2;4;1;4",flyduration=1',
 's=9,bulletcolor=12,primary="missile",secondary="slicer",psets="3;5;11_3;3;7",guns="1;3;6;3",exhaustcolors="7;12;15",exhausts="-1;4;0;4",flyduration=1',

 's=10,bulletcolor=11,primary="boost",secondary="missile",psets="3;6;5_3;4;6",guns="2;2;5;2",exhaustcolors="7;9;13",exhausts="-1;4;0;4",flyduration=1',
 's=11,bulletcolor=3,primary="boost",secondary="boost",psets="0;0;9_0;0;9",guns="1;0;6;0",exhaustcolors="11;12;5",exhausts="-2;3;-1;3;0;3;1;3",flyduration=1',
 's=12,bulletcolor=9,primary="boost",secondary="mines",psets="3;4;9_3;2;10",guns="1;0;6;0",exhaustcolors="11;3;4",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 's=13,bulletcolor=10,primary="boost",secondary="shield",psets="3;6;11_3;4;10",guns="2;0;5;0",exhaustcolors="7;9;4",exhausts="-1;3;0;3",flyduration=1',
 's=14,bulletcolor=11,primary="boost",secondary="ice",psets="3;5;7_3;3;6",guns="2;1;5;1",exhaustcolors="10;9;2",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=15,bulletcolor=12,primary="boost",secondary="blink",psets="3;6;9_3;4;10",guns="1;2;6;2",exhaustcolors="7;14;8",exhausts="-4;4;-3;3;-2;2;1;2;2;3;3;4",flyduration=1',
 's=16,bulletcolor=11,primary="boost",secondary="flak",psets="3;6;7_3;5;7",guns="1;2;6;2",exhaustcolors="14;8;2",exhausts="-4;4;-3;4;-2;4;1;4;2;4;3;4",flyduration=1',
 's=17,bulletcolor=11,primary="boost",secondary="beam",psets="3;6;10_3;5;10",guns="1;2;6;2",exhaustcolors="11;11;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=18,bulletcolor=11,primary="boost",secondary="bubbles",psets="3;5;8_3;4;8",guns="1;2;6;2",exhaustcolors="10;11;5",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 's=19,bulletcolor=14,primary="boost",secondary="slicer",psets="3;5;6_3;2;6",guns="1;1;6;1",exhaustcolors="7;7;15",exhausts="-3;3;2;3",flyduration=1',
 
 's=20,bulletcolor=14,primary="mines",secondary="missile",psets="0;1;13_0;1;13",guns="1;1;6;1",exhaustcolors="10;9;4",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=21,bulletcolor=8,primary="mines",secondary="boost",psets="3;5;12_3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=22,bulletcolor=11,primary="mines",secondary="mines",psets="3;4;1_3;3;12",guns="0;2;7;2",exhaustcolors="7;6;5",exhausts="-2;4;1;4",flyduration=1',
 's=23,bulletcolor=15,primary="mines",secondary="shield",psets="3;6;9_3;4;10",guns="1;1;6;1",exhaustcolors="10;14;13",exhausts="-1;3;0;3",flyduration=1',
 's=24,bulletcolor=11,primary="mines",secondary="ice",psets="3;6;8_3;4;10",guns="2;2;5;2",exhaustcolors="10;11;5",exhausts="-1;4;0;4",flyduration=1',
 's=25,bulletcolor=11,primary="mines",secondary="blink",psets="6;5;11_6;4;10",guns="1;2;3;2",exhaustcolors="10;11;5",exhausts="-3;4;-2;4;-1;4",flyduration=1',
 's=26,bulletcolor=9,primary="mines",secondary="flak",psets="3;6;11_3;4;10",guns="1;0;6;0",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 's=27,bulletcolor=14,primary="mines",secondary="beam",psets="3;5;13_3;3;12",guns="1;0;6;0",exhaustcolors="7;7;13",exhausts="-1;3;0;3",flyduration=1',
 's=28,bulletcolor=9,primary="mines",secondary="bubbles",psets="3;6;3_3;4;11",guns="2;1;5;1",exhaustcolors="7;14;8",exhausts="-1;3;0;3",flyduration=1',
 's=29,bulletcolor=11,primary="mines",secondary="slicer",psets="3;6;2_3;4;8",guns="1;2;6;2",exhaustcolors="11;11;4",exhausts="-1;3;0;3",flyduration=1',

 's=30,bulletcolor=5,primary="shield",secondary="missile",psets="3;5;12_3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 's=31,bulletcolor=12,primary="shield",secondary="boost",psets="0;1;13_0;1;13",guns="1;1;6;1",exhaustcolors="11;12;13",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 's=32,bulletcolor=9,primary="shield",secondary="mines",psets="3;6;3_3;5;11",guns="1;0;6;0",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 's=33,bulletcolor=10,primary="shield",secondary="shield",psets="3;5;3_3;3;11",guns="1;0;6;0",exhaustcolors="7;10;5",exhausts="-1;4;0;4",flyduration=1',
 's=34,bulletcolor=3,primary="shield",secondary="ice",psets="3;5;9_3;4;9",guns="1;2;6;2",exhaustcolors="10;10;3",exhausts="-1;4;0;4",flyduration=1',
 's=35,bulletcolor=10,primary="shield",secondary="blink",psets="3;6;4_3;4;13",guns="1;2;6;2",exhaustcolors="10;11;15",exhausts="-1;3;0;3",flyduration=1',
 's=36,bulletcolor=9,primary="shield",secondary="flak",psets="3;6;3_3;4;7",guns="0;3;7;3",exhaustcolors="10;9;5",exhausts="-2;4;1;4",flyduration=1',
 's=37,bulletcolor=6,primary="shield",secondary="beam",psets="3;6;2_3;4;7",guns="1;1;6;1",exhaustcolors="10;14;15",exhausts="-1;4;0;4",flyduration=1',
 's=38,bulletcolor=11,primary="shield",secondary="bubbles",psets="3;5;11_3;4;7",guns="0;3;7;3",exhaustcolors="3;3;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=39,bulletcolor=12,primary="shield",secondary="slicer",psets="3;4;2_3;3;14",guns="2;0;5;0",exhaustcolors="7;9;2",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 
 's=40,bulletcolor=14,primary="ice",secondary="missile",psets="3;6;5_3;4;6",guns="1;2;6;2",exhaustcolors="10;14;4",exhausts="-2;4;1;4",flyduration=1',
 's=41,bulletcolor=15,primary="ice",secondary="boost",psets="3;6;15_3;4;7",guns="0;4;7;4",exhaustcolors="10;9;4",exhausts="-3;3;2;3",flyduration=1',
 's=42,bulletcolor=5,primary="ice",secondary="mines",psets="3;4;11_3;3;7",guns="1;1;6;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 's=43,bulletcolor=4,primary="ice",secondary="shield",psets="3;4;11_3;5;12",guns="1;0;6;0",exhaustcolors="7;9;5",exhausts="-1;2;0;2",flyduration=1',
 's=44,bulletcolor=7,primary="ice",secondary="ice",psets="3;5;5_3;3;10",guns="2;2;5;2",exhaustcolors="7;8;2",exhausts="-2;4;1;4",flyduration=1',
 's=45,bulletcolor=7,primary="ice",secondary="blink",psets="3;6;15_3;4;7",guns="2;1;5;1",exhaustcolors="1",exhausts="-4;4;3;4",flyduration=1',
 's=46,bulletcolor=10,primary="ice",secondary="flak",psets="3;5;14_3;3;6",guns="1;3;6;3",exhaustcolors="11;11;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=47,bulletcolor=6,primary="ice",secondary="beam",psets="3;3;7_3;5;6",guns="1;1;6;1",exhaustcolors="7;12;4",exhausts="-1;4;0;4",flyduration=1',
 's=48,bulletcolor=8,primary="ice",secondary="bubbles",psets="3;5;9_3;3;10",guns="0;3;7;3",exhaustcolors="9;8;5",exhausts="-1;4;0;4",flyduration=10',
 's=49,bulletcolor=11,primary="ice",secondary="slicer",psets="3;6;15_3;4;9",guns="1;1;6;1",exhaustcolors="9;9;2",exhausts="-1;4;0;4",flyduration=1',
 
 's=50,bulletcolor=10,primary="blink",secondary="missile",psets="3;6;14_3;4;7",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4",flyduration=1',
 's=51,bulletcolor=9,primary="blink",secondary="boost",psets="3;6;6_3;4;7",guns="1;1;6;1",exhaustcolors="7;6;13",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 's=52,bulletcolor=11,primary="blink",secondary="mines",psets="3;5;11_3;3;10",guns="2;1;5;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4",flyduration=1',
 's=53,bulletcolor=14,primary="blink",secondary="shield",psets="3;6;12_3;4;11",guns="1;2;6;2",exhaustcolors="7;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=54,bulletcolor=9,primary="blink",secondary="ice",psets="3;6;15_3;4;10",guns="1;1;6;1",exhaustcolors="9;8;2",exhausts="-1;3;0;3",flyduration=1',
 's=55,bulletcolor=14,primary="blink",secondary="blink",psets="3;5;10_3;3;7",guns="0;2;7;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3",flyduration=1',
 's=56,bulletcolor=5,primary="blink",secondary="flak",psets="3;5;15_3;3;10",guns="2;0;5;0",exhaustcolors="5;1;1",exhausts="-3;3;-2;4;1;4;2;3",flyduration=1',
 's=57,bulletcolor=11,primary="blink",secondary="beam",psets="3;5;7_3;2;10",guns="0;4;7;4",exhaustcolors="11;11;3",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 's=58,bulletcolor=10,primary="blink",secondary="bubbles",psets="3;5;9_3;3;10",guns="2;0;5;0",exhaustcolors="7;14;15",exhausts="-3;4;-1;4;0;4;2;4",flyduration=1',
 's=59,bulletcolor=14,primary="blink",secondary="slicer",psets="3;4;3_3;2;11",guns="0;4;7;4",exhaustcolors="12;12;3",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',

 's=60,bulletcolor=6,primary="flak",secondary="missile",psets="3;5;5_3;3;10",guns="2;2;5;2",exhaustcolors="7;10;2",exhausts="-2;4;1;4",flyduration=1',
 's=61,bulletcolor=8,primary="flak",secondary="boost",psets="3;5;7_3;6;6",guns="1;2;6;2",exhaustcolors="7;15;5",exhausts="-4;3;-3;3;-1;4;0;4;2;3;3;3",flyduration=1',
 's=62,bulletcolor=2,primary="flak",secondary="mines",psets="3;6;9_3;4;10",guns="1;1;6;1",exhaustcolors="10;9;14",exhausts="-1;4;0;4",flyduration=1',
 's=63,bulletcolor=15,primary="flak",secondary="shield",psets="3;2;10_3;4;9",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-1;4;0;4",flyduration=1',
 's=64,bulletcolor=6,primary="flak",secondary="ice",psets="3;5;2_3;3;14",guns="0;4;7;4",exhaustcolors="7;10;11",exhausts="-3;3;2;3",flyduration=1',
 's=65,bulletcolor=9,primary="flak",secondary="blink",psets="3;6;13_3;3;6",guns="1;3;6;3",exhaustcolors="7;6;15",exhausts="-1;3;0;3",flyduration=1',
 's=66,bulletcolor=9,primary="flak",secondary="flak",psets="3;6;11_3;4;10",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 's=67,bulletcolor=9,primary="flak",secondary="beam",psets="3;5;8_3;3;14",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 's=68,bulletcolor=14,primary="flak",secondary="bubbles",psets="3;5;6_3;3;7",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 's=69,bulletcolor=9,primary="flak",secondary="slicer",psets="3;5;12_3;3;11",guns="2;1;5;1",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',

 's=70,bulletcolor=11,primary="beam",secondary="missile",psets="3;5;2_3;3;14",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4",flyduration=1',
 's=71,bulletcolor=3,primary="beam",secondary="boost",psets="3;6;3_3;4;11",guns="1;3;6;3",exhaustcolors="10;14;15",exhausts="-4;3;-3;4;2;4;3;3",flyduration=1',
 's=72,bulletcolor=6,primary="beam",secondary="mines",psets="3;4;8_3;2;9",guns="1;3;6;3",exhaustcolors="7;6;5",exhausts="-1;4;0;4",flyduration=1',
 's=73,bulletcolor=6,primary="beam",secondary="shield",psets="3;5;10_3;3;9",guns="2;1;5;1",exhaustcolors="10;11;12",exhausts="-1;4;0;4",flyduration=1',
 's=74,bulletcolor=11,primary="beam",secondary="ice",psets="3;5;9_3;3;10",guns="2;0;5;0",exhaustcolors="10;9;15",exhausts="-1;3;0;3",flyduration=1',
 's=75,bulletcolor=12,primary="beam",secondary="blink",psets="3;6;3_3;4;11",guns="2;0;5;0",exhaustcolors="1",exhausts="-2;3;1;3",flyduration=1',
 's=76,bulletcolor=8,primary="beam",secondary="flak",psets="3;5;10_3;4;10",guns="1;3;6;3",exhaustcolors="7;7;9",exhausts="-3;3;-2;3;1;3;2;3",flyduration=1',
 's=77,bulletcolor=4,primary="beam",secondary="beam",psets="3;6;14_3;4;7",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-1;4;0;4",flyduration=1',
 's=78,bulletcolor=12,primary="beam",secondary="bubbles",psets="3;5;7_3;4;7",guns="1;2;6;2",exhaustcolors="10;10;5",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=79,bulletcolor=10,primary="beam",secondary="slicer",psets="3;6;14_3;4;7",guns="1;2;6;2",exhaustcolors="4;1",exhausts="-4;4;-3;3;2;3;3;4",flyduration=1',

 's=80,bulletcolor=6,primary="bubbles",secondary="missile",psets="3;5;10_3;4;10",guns="0;0;7;0",exhaustcolors="7;12;3",exhausts="-1;4;0;4",flyduration=1',
 's=81,bulletcolor=14,primary="bubbles",secondary="boost",psets="3;4;8_3;2;14",guns="1;0;6;0",exhaustcolors="12;12;2",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 's=82,bulletcolor=11,primary="bubbles",secondary="mines",psets="3;6;6_3;3;7",guns="2;2;5;2",exhaustcolors="10;14;2",exhausts="-1;0;0;0",flyduration=1',
 's=83,bulletcolor=2,primary="bubbles",secondary="shield",psets="3;5;11_3;4;11",guns="1;1;6;1",exhaustcolors="7;7;5",exhausts="-3;3;-1;4;0;4;2;3",flyduration=10',
 's=84,bulletcolor=10,primary="bubbles",secondary="ice",psets="3;5;6_3;3;7",guns="0;3;7;3",exhaustcolors="11;11;4",exhausts="-1;4;0;4",flyduration=1',
 's=85,bulletcolor=12,primary="bubbles",secondary="blink",psets="3;4;12_3;3;11",guns="1;0;6;0",exhaustcolors="7;12;2",exhausts="-4;3;-3;4;2;4;3;3",flyduration=1',
 's=86,bulletcolor=9,primary="bubbles",secondary="flak",psets="3;5;7_3;6;11",guns="1;0;6;0",exhaustcolors="10;9;4",exhausts="-4;4;-3;4;2;4;3;4",flyduration=1',
 's=87,bulletcolor=9,primary="bubbles",secondary="beam",psets="3;5;11_3;3;10",guns="2;1;5;1",exhaustcolors="10;10;2",exhausts="-1;3;0;3",flyduration=1',
 's=88,bulletcolor=10,primary="bubbles",secondary="bubbles",psets="3;5;7_3;3;11",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',
 's=89,bulletcolor=11,primary="bubbles",secondary="slicer",psets="3;5;11_3;3;12",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4",flyduration=1',

 's=90,bulletcolor=10,primary="slicer",secondary="missile",psets="3;6;12_3;4;11",guns="0;3;7;3",exhaustcolors="7;2;5",exhausts="-1;3;0;3",flyduration=10',
 's=91,bulletcolor=5,primary="slicer",secondary="boost",psets="0;5;2_0;4;14",guns="4;0;6;0",exhaustcolors="10;9;2",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4",flyduration=1',
 's=92,bulletcolor=14,primary="slicer",secondary="mines",psets="3;5;14_3;4;9",guns="1;0;6;0",exhaustcolors="9;15;5",exhausts="-1;4;0;4",flyduration=10',
 's=93,bulletcolor=10,primary="slicer",secondary="shield",psets="3;6;2_3;4;14",guns="1;2;6;2",exhaustcolors="7;11;5",exhausts="-1;4;0;4",flyduration=10',
 's=94,bulletcolor=12,primary="slicer",secondary="ice",psets="0;5;9_0;4;7",guns="4;1;6;1",exhaustcolors="7;9;5",exhausts="-1;4;0;4;2;4;3;4",flyduration=10',
 's=95,bulletcolor=12,primary="slicer",secondary="blink",psets="3;5;2_3;3;14",guns="2;0;5;0",exhaustcolors="10;9;2",exhausts="-3;4;-2;4;1;4;2;4",flyduration=10',
 's=96,bulletcolor=15,primary="slicer",secondary="flak",psets="3;5;9_3;3;10",guns="0;3;7;3",exhaustcolors="7;6;4",exhausts="-1;4;0;4",flyduration=10',
 's=97,bulletcolor=7,primary="slicer",secondary="beam",psets="3;5;5_3;4;6",guns="2;0;5;0",exhaustcolors="1",exhausts="-3;3;-2;4;1;4;2;3",flyduration=10',
 's=98,bulletcolor=10,primary="slicer",secondary="bubbles",psets="3;4;3_3;3;11",guns="1;0;6;0",exhaustcolors="14;14;4",exhausts="-1;4;0;4",flyduration=10',
 's=99,bulletcolor=9,primary="slicer",secondary="slicer",psets="3;4;9_3;3;10",guns="2;0;5;0",exhaustcolors="11;15;5",exhausts="-1;4;0;4",flyduration=10',

 -- enemies
 's=100,s2=128,bulletcolor=0,factory=1,primary="kamikaze",secondary="none",secondaryshots=0,psets="0;0;0_0;0;0",guns="0;0;0;0",exhaustcolors="10;9",exhausts="-1;0",y=139,hw=4,hh=4,spdx=0,spdy=0,hp=4',
 's=102,s2=129,bulletcolor=0,factory=2,primary="fighter",secondary="none",secondaryshots=0,psets="0;0;0_0;0;0",guns="0;0;0;0",exhaustcolors="14;2;4",exhausts="-1;0",x=0,y=-12,hw=4,hh=4,spdx=0,spdy=0,accx=0,hp=5',
 's=104,s2=130,bulletcolor=0,factory=3,primary="minelayer",secondary="none",secondaryshots=0,psets="0;0;0_0;0;0",guns="0;0;0;0",exhaustcolors="12",exhausts="-1;0",y=-12,hw=4,hh=4,spdx=0,spdy=0,hp=5',
 's=106,s2=131,bulletcolor=0,factory=4,primary="bomber",secondary="none",secondaryshots=0,psets="0;0;0_0;0;0",guns="0;0;0;0",exhaustcolors="11;3",exhausts="-3;-2;1;2",x=0,y=-12,hw=4,hh=4,spdx=0,accx=0,hp=9',
 's=108,s2=132,bulletcolor=0,factory=5,primary="cargoship",secondary="none",secondaryshots=0,psets="0;0;0_0;0;0",guns="0;0;0;0",exhaustcolors="7;6;13",exhausts="-1;0",hw=4,hh=4,spdx=0,spdy=0.25,accx=0,hp=14',

 -- superboss
 's=105,bulletcolor=14,primary="slicer",secondary="beam",psets="3;4;7_3;3;11",guns="2;0;5;0",exhaustcolors="7;9;5",exhausts="-3;6;-2;6;1;6;2;6",x=64,y=40,vdir=1,hw=7,hh=7,hp=127,flydurationc=3,waitdurationc=1,boost=0,flyduration=1,plidx=2,firedir=1',
}

for _i=0,105 do
 hangar[_i]=s2t(hangar[_i])
end

-- helpers
local function getblink()
 return flr((t()*12)%3)
end

local function drawblinktext(_str,_startcolor)
 print('\^w\^t'.._str,64-#_str*4,48,_startcolor+getblink())
end

local function addps(_x,_y,_r,_spdx,_spdy,_spdr,_colors,_life,_ondeath)
 add(ps,{
  x=_x,y=_y,r=_r,
  spdx=_spdx,spdy=_spdy,spdr=_spdr,
  colors=_colors,
  life=_life,lifec=_life,
  ondeath=_ondeath,
 })
end

local function addbulletps(_ship,_gun)
 add(psfollow,{
  x=0,y=0,r=3,
  follow=_ship,
  xoff=_gun.x-4,yoff=_gun.y-4,
  spdx=0,spdy=0,spdr=-0.5,
  colors={7,9},
  life=5,lifec=5,
 })
end

local function addbullet(_bullet)
 add(bullets,mr({
  spdx=0,spdy=0,accy=0,spdfactor=1,escapefactor=0,
  ondeath=function (_b) del(bullets,_b) end,
 },_bullet))
end

local function addenemybullet(_bullet)
 add(enemybullets,mr({
  spdx=0,spdy=0,accy=0,spdfactor=1,life=1,isenemy=true,escapefactor=0,
  ondeath=function (_b) del(enemybullets,_b) end,
 },_bullet))
end

local function getship(_hangaridx)
 local _ship=clone(hangar[_hangaridx])
 local _guns=split(_ship.guns,';')
 _ship.guns={{x=_guns[1],y=_guns[2]},{x=_guns[3],y=_guns[4]}}
 local _psets=split(_ship.psets,'_')
 _ship.psets={split(_psets[1],';'),split(_psets[2],';')}
 _ship.exhaustcolors=split(_ship.exhaustcolors,';')
 _ship.exhausts=split(_ship.exhausts,';')
 return _ship
end

local function getplayership(_hangaridx)
 return mr(s2t'y=110,firedir=-1,hw=3,hh=3,spd=1,hp=3,firingc=0,primaryc=12,secondaryc=0,secondaryshots=3',clone(getship(_hangaridx)))
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
 addps(
  _x,_y,0.5,
  (rnd()-0.5)*0.125,
  rnd()*0.25+1,
  0.25*rnd(),
  burningcolors,
  8+rnd()*4)
end

local hitcolors=split'7,7,10'
local function newhit(_x,_y)
 sfx(11,3)
 for _i=1,7 do
  addps(
   _x+(rnd()-0.5)*5,
   _y+(rnd()-0.5)*5,
   rnd()*5,
   (rnd()-0.5)*2,
   rnd()-0.5,
   -0.2,
   hitcolors,
   4)
 end
end

local smokecolors={5}
local function explosionsmoke(_x,_y)
 addps(
  _x,_y,8,
  rnd()-0.5,
  rnd()-1.22,
  -0.28,
  smokecolors,
  rnd()*10+25)
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

local explosioncolors=split'7,7,10,9,8'
local function explode(_obj)
 del(bullets,_obj)
 del(enemybullets,_obj)
 sfx(10,3)
 for _i=1,7 do
  addps(
   _obj.x,_obj.y,
   rnd()*5,
   rnd()-0.5,
   rnd()-1,
   rnd()*0.2+0.5,
   explosioncolors,
   11,
   explosionsmoke)
 end
end

local function fizzlebase(_obj,_colors)
 del(bullets,_obj)
 del(enemybullets,_obj)
 sfx(18,3)
 for _i=1,5 do
  addps(
   _obj.x+rnd(8)-4,_obj.y+rnd(8)-4,
   0.9,
   0,
   -rnd(0.375),
   0,
   _colors,
   4+rnd(10))
 end
end
local fizzlecolors=split'7,9,10,5,9,15,5'
local function fizzle(_obj)
 fizzlebase(_obj,fizzlecolors)
end
local icefizzlecolors=split'7,7,6,12,3,5'
local function icefizzle(_obj)
 fizzlebase(_obj,icefizzlecolors)
end


local function updatebullets(_bullets)
 for _b in all(_bullets) do
  _b.x+=_b.spdx
  _b.y+=_b.spdy+_b.escapefactor*(escapefactor-1)

  _b.spdy+=_b.accy

  _b.life-=1

  _b.spdx*=_b.spdfactor
  _b.spdy*=_b.spdfactor

  if _b.update then
   _b.update(_b)
  end

  if _b.p then
   local _bp=_b.p
   add(bottomps,mr(clone(_bp),{
    x=_b.x+_bp.xoff,
    y=_b.y+_bp.yoff,
    life=rnd(_bp.life)+_bp.life,
    lifec=rnd(_bp.life)+_bp.life,
   }))
  end

  if _b.isenemy then
   for _ship in all(ships) do
    if isaabbscolliding(_b,_ship) then
     if not _ship.isshielding then
      if _b.isice then
       _b.enemyhit=_ship
      else
       _ship.hp-=1
       _ship.primaryc=0
       if _ship.hp > 0 then
        sfx(21+_ship.hp,_ship.plidx)
       end
      end
     end
     _b.life=0
     newhit(_ship.x,_ship.y)
    end
   end

  else

   if boss and isaabbscolliding(_b,boss) then
    if not boss.shieldts then
     local _dmg=_b.bossdmg or _b.dmg
     if issuperboss then
      _dmg*=0.5
     end
     boss.hp-=_dmg
     _b.enemyhit=boss
    end
    _b.life=0
    newhit(boss.x,boss.y)
   end

   for _enemy in all(enemies) do
    if isaabbscolliding(_b,_enemy) then
     _enemy.hp-=_b.dmg
     _b.enemyhit=_enemy
     _b.life=0
     newhit(_enemy.x,_enemy.y)
    end
   end
  end

  if _b.life <= 0 then
   _b.ondeath(_b)
  elseif not ispointinsideaabb(_b.x,_b.y,64,64,64,64) then
   del(_bullets,_b)
  end
 end
end

-- weapons
local function bulletclearbullets(_bullet,_otherbullets)
 for _other in all(_otherbullets) do
  if isaabbscolliding(_bullet,_other) then
   _bullet.life,_other.life=0,0
  end
 end
end

local function clearenemybullets(_bullet)
 bulletclearbullets(_bullet,enemybullets)
end

local function emptyfn()
end

local function drawbullet(_bullet)
 sspr(5,119,1,4,_bullet.x,_bullet.y)
end

local function drawshield(_x,_y,_color,_radius)
 _radius=_radius or 6
 circ(_x,_y,_radius,1)
 fillp(rnd(32767))
 circ(_x+rnd(2)-1,_y+rnd(2)-1,_radius,_color)
 fillp()
end

local function mineexplodedraw(_bullet)
 circfill(_bullet.x,_bullet.y,_bullet.hw,7)
end
local mineexplodepos=split'-16,0,0,0,16,0,0,-16,0,16'
local function onminedeathbase(_bullet,_bullets)
 if not _bullet.disarmed then
  for _i=1,#mineexplodepos,2 do
   if _bullet.charge > rnd(170) then
    add(_bullets,{
     x=_bullet.x+mineexplodepos[_i],y=_bullet.y+mineexplodepos[_i+1],
     hw=8,hh=8,
     spdfactor=0,
     escapefactor=0,
     spdx=0,spdy=0,accy=0,
     dmg=6,
     life=2,
     isenemy=_bullets == enemybullets,
     draw=mineexplodedraw,
     ondeath=explode,
    })
   end
  end
 end
 explode(_bullet)
end
local function onminedeath(_bullet)
 onminedeathbase(_bullet,bullets)
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
 addbullet{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  escapefactor=1,
  spdx=cos(_angle+rnd(0.02)),spdy=sin(_angle+rnd(0.02)),accy=0,
  dmg=5,
  life=_life,
  charge=_life,
  draw=drawmine,
  ondeath=onminedeath,
 }
end

local missilepcolors=split'7,10,9'
local function drawmissile(_bullet)
 sspr(4,123,3,5,_bullet.x-_bullet.hw,_bullet.y)
end
local function shootmissile(_ship,_life)
 shipsfx(_ship,12)
 addbullet{
  x=_ship.x,y=_ship.y,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=-rnd(0.175),accy=-0.05,spdfactor=1,
  dmg=12,
  life=_life,
  ondeath=explode,
  draw=drawmissile,
  p=mr(s2t'xoff=1,yoff=5,r=0.1,spdx=0,spdy=-0.1,spdr=0,life=3',{colors=missilepcolors}),
 }
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
  escapefactor=1,
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

local blinkpcolors,blinkaab=split'7,11,11,3,5',s2t'hw=16,hh=16'
local function blinkaway(_ship,_dx,_dy,_h)
 shipsfx(_ship,21)
 local _newx,_newy=_ship.x+_dx*_h,_ship.y+_dy*_h
 for _i=1,6 do
  addps(
   _ship.x+rnd(8)-4,
   _ship.y+rnd(8)-4,
   1+rnd(0.25),
   0,
   0,
   -0.05,
   blinkpcolors,
   10+rnd(5))
 end
 _newx,_newy=mid(4,_newx,124),mid(4,_newy,119)
 _ship.x,_ship.y,blinkaab.x,blinkaab.y=_newx,_newy,_newx,_newy
 for _enemybullet in all(enemybullets) do
  if isaabbscolliding(blinkaab,_enemybullet) then
   _enemybullet.life,_enemybullet.disarmed=0,true
  end
 end
 for _enemy in all(enemies) do
  if isaabbscolliding(blinkaab,_enemy) then
   _enemy.hp=0
  end
 end
 if boss and _ship != boss and isaabbscolliding(blinkaab,boss) then
  boss.hp-=55
 end
end

local beamcolors=split'9,10'
local enemybeamcolors=split'8,14'
local beampcolors=split'7,10,9'
local enemybeampcolors=split'7,7,14'
local dirs={1,-1}
local function drawbeam(_bullet)
 local _x,_topy,_bottomy=_bullet.x,_bullet.y-_bullet.hh,_bullet.y+_bullet.hh
 rectfill(_x-3,_topy+2,_x+2,_bottomy-2,_bullet.colors[1])
 rectfill(_x-2,_topy+1,_x+1,_bottomy-1,_bullet.colors[2])
 rectfill(_x-1,_topy,_x,_bottomy,7)
 addps(
  _x,
  _topy+rnd(_bottomy),
  0.9,
  rnd(dirs)*(rnd(0.125)+0.125),
  0,
  0,
  _bullet.pcolors,
  20)
end
local function shootbeam(_ship)
 local _hh=_ship.y/2
 addbullet{
  x=_ship.x,y=_hh-6,
  hw=3,hh=_hh,
  spdfactor=0,
  dmg=0.25,
  life=1,
  colors=beamcolors,
  pcolors=beampcolors,
  draw=drawbeam,
  update=clearenemybullets,
 }
end

local function shootboost(_ship)
 addbullet{
  x=_ship.x,y=_ship.y+8,
  hw=3,hh=5,
  spdfactor=0,
  dmg=4,bossdmg=0.5,
  life=1,
  draw=emptyfn,
 }
end

local function drawslicer(_bullet)
 sspr(
  _bullet.sx,
  _bullet.sy,
  _bullet.sw,
  _bullet.sh,
  _bullet.x-_bullet.hw,
  _bullet.y-_bullet.hh,
  _bullet.sw,
  _bullet.sh,
  _bullet.spdx > 0)
end
local function slicerdeath(_bullet)
 local _slicecount=_bullet.slicecount-1
 explode(_bullet)
 if _slicecount > 0 then
  if _bullet.isstraight then
   shootslicer(_bullet.x-12,_bullet.y-12,-1,-1,_slicecount)
   shootslicer(_bullet.x+12,_bullet.y-12,1,-1,_slicecount)
  else
   shootslicer(_bullet.x,_bullet.y-12,0,-2,_slicecount,true)
  end
 end
end
function shootslicer(_x,_y,_spdx,_spdy,_slicecount,_isstraight)
 addbullet{
  x=_x,y=_y,
  hw=3,hh=3,
  spdx=_spdx,spdy=_spdy,
  isstraight=_isstraight,
  sx=_isstraight and 50 or 58,
  sy=118,
  sw=_isstraight and 8 or 7,
  sh=_isstraight and 5 or 7,
  dmg=5,
  life=999,
  slicecount=_slicecount,
  ondeath=slicerdeath,
  update=clearenemybullets,
  draw=drawslicer,
 }
end

local function drawbubble(_bullet)
 circ(_bullet.x,_bullet.y,2,12)
 pset(_bullet.x-1,_bullet.y-1,7)
end
local bubblepcolors=split'14,12,4'
local function shootbubble(_ship)
 for _i=1,3 do
  addps(
   _ship.x,
   _ship.y,
   1+rnd(1),
   rnd(0.5)-0.25,
   rnd(0.5)-0.25,
   -0.05,
   bubblepcolors,
   10+rnd(20))
 end
 addbullet{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2.5,
  spdx=rnd()-0.5,spdy=rnd()-0.5,
  spdfactor=0.96,
  escapefactor=1,
  dmg=2,
  life=190,
  update=clearenemybullets,
  ondeath=fizzle,
  draw=drawbubble,
 }
 shipsfx(_ship,29)
end

local function addicep(_x,_y,_spdy,_life)
 addps(
  _x,
  _y,
  0.05,
  rnd(0.25)-0.125,
  _spdy,
  0,
  icefizzlecolors,
  _life)
end
local function updateicec(_ship)
 addicep(_ship.x+rnd(8)-4,_ship.y+rnd(8)-4,0,10)
 _ship.icec-=1
 if _ship.icec <= 0 then
  _ship.icec=nil
 end
end
local function drawice(_bullet)
 pset(_bullet.x,_bullet.y,7)
end
local function iceondeath(_bullet)
 if _bullet.enemyhit then
  _bullet.enemyhit.icec,_bullet.enemyhit=110
 end
 icefizzle(_bullet)
end
local function shootice(_ship,_life,_bullets)
 add(_bullets,{
  x=_ship.x,y=_ship.y,
  hw=2,hh=2,
  spdx=_ship.firedir*rnd(0.1),spdy=_ship.firedir+_ship.firedir*rnd(0.1),
  accy=0,spdfactor=1,
  escapefactor=1,
  dmg=0,
  isice=true,
  life=_life,
  isenemy=_bullets == enemybullets,
  ondeath=iceondeath,
  draw=drawice,
 })
 if rnd() > 0.5 then
  addicep(_ship.x,_ship.y,_ship.firedir+rnd(0.25)-0.125,_life)
 end
end

local primary={
 missile=function(_btn4,_ship,_justpressedwithcharge)
  if _justpressedwithcharge then
   shootmissile(_ship,_ship.primaryc*3)
   shootmissile(_ship,_ship.primaryc*3)
   _ship.primaryc=0
  end
 end,
 boost=function(_btn4,_ship)
  _ship.isboosting=_ship.primaryc > 0 and not _btn4
  if _ship.isboosting then
   shootboost(_ship)
  end
 end,
 mines=function(_btn4,_ship,_justpressedwithcharge)
  if _justpressedwithcharge then
   local _life=_ship.primaryc*4
   shootmine(_ship,_life,0.375+rnd(0.1))
   shootmine(_ship,_life,0.125-rnd(0.1))
   _ship.primaryc=0
  end
 end,
 shield=function(_btn4,_ship)
  _ship.isshielding=_ship.primaryc > 0 and not _btn4
  if _ship.isshielding then
   _ship.primaryc-=0.25
  end
 end,
 ice=function(_btn4,_ship)
  if (not _btn4 and _ship.primaryc > 1 and flr(_ship.primaryc*10) % 5 == 0) then
   shootice(_ship,_ship.primaryc*2.25,bullets)
  end
 end,
 blink=function(_btn4,_ship)
  if _btn4 and _ship.primaryc > 1 and not _ship.lastbtn4 then
   local _dx,_dy=getdirs(_ship.plidx)
   blinkaway(_ship,_dx,_dy,_ship.primaryc*1.25)
   _ship.primaryc=0
  end
 end,
 flak=function(_btn4,_ship,_justpressedwithcharge)
  if _justpressedwithcharge then
   shootflak(_ship,max(2,flr(_ship.primaryc/2)),_ship.primaryc*6)
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
 slicer=function(_btn4,_ship,_justpressedwithcharge)
  if _justpressedwithcharge then
   shipsfx(_ship,30)
   shootslicer(_ship.x,_ship.y,0,-2,flr(_ship.primaryc/5),true)
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
 ice=function(_ship)
  _ship.secondaryc-=1
  firesecondary(_ship,40)
  if _ship.secondaryc > 0 and _ship.secondaryc % 2 == 0 then
   shootice(_ship,40,bullets)
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
   shootflak(_ship,12,160)
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
 slicer=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootslicer(_ship.x,_ship.y,-1,-1,6)
   shootslicer(_ship.x,_ship.y,1,-1,6)
   _ship.secondaryshots-=1
  end
 end,
}

local weaponcolors=s2t'missile=13,boost=8,mines=5,shield=12,ice=6,blink=3,flak=15,beam=9,bubbles=14,slicer=11'

local boostcolors=split'7,10,9,8'

local secondarysprites={
 missile=split'5,123',
 boost=split'8,123',
 mines=split'2,124',
 shield=split'11,123',
 ice=split'14,123',
 blink=split'17,123',
 flak=split'20,123',
 beam=split'23,123',
 bubbles=split'26,123',
 slicer=split'29,123'
}

local function newcargodrop(_x,_y)
 add(cargos,{
  x=_x,y=_y,
  hw=2,hh=2,
  spdx=rnd(0.05)-0.025,
  spdy=0.0125+rnd(0.05),
 })
end

-- enemies
local enemyexhaustpyoffset={[-1]=4,-5}

local function drawenemymissile(_bullet)
 sspr(33,123,3,5,_bullet.x,_bullet.y,3,5,false,_bullet.flipy)
end
local enemymissilep=mr(s2t'xoff=1,yoff=0,r=0.1,spdx=0,spdy=0.1,spdr=0,life=4',{colors=split'7,14,8'})
local function enemyshootmissile(_enemy)
 local _vdir=_enemy.vdir
 sfx(12,3)
 addenemybullet{
  x=_enemy.x,y=_enemy.y,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=0.1*_vdir,accy=0.05*_vdir,spdfactor=1,
  escapefactor=1,
  life=85,
  draw=drawenemymissile,
  ondeath=explode,
  flipy=_vdir == -1,
  p=enemymissilep,
 }
end

local function onenemyminedeath(_bullet)
 _bullet.charge=100
 onminedeathbase(_bullet,enemybullets)
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
 addenemybullet{
  x=_enemy.x,y=_enemy.y,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  escapefactor=1,
  spdx=rnd(0.5)-0.25,spdy=1.5*_enemy.vdir,accy=0,
  life=110,
  draw=drawenemymine,
  ondeath=onenemyminedeath,
 }
end

local function drawenemybullet(_bullet)
 sspr(32,125,1,3,_bullet.x,_bullet.y,1,3,false,_bullet.flipy)
end
local enemybulletp=mr(s2t'xoff=0,yoff=0,r=0.1,spdx=0,spdy=0,spdr=0,life=3',{colors=split'2,2,4'})
local enemybulletxoffs={-4,3}
local function enemyshootbullet(_enemy)
 local _vdir=_enemy.vdir
 sfx(8,3)
 for _i=1,2 do
  addenemybullet{
   x=_enemy.x+enemybulletxoffs[_i],y=_enemy.y,
   hw=1,hh=2,
   spdy=2*_vdir,
   escapefactor=0,
   life=1000,
   flipy=_vdir == -1,
   draw=drawenemybullet,
   ondeath=explode,
   p=enemybulletp,
  }
 end
end

local bossflakcolors=split'14,8,5'
local function drawbossflakbullet(_bullet)
 pset(_bullet.x,_bullet.y,bossflakcolors[getblink()+1])
end
local function shootbossflak()
 sfx(17,3)
 for _i=1,8 do
  local _spdx,_spdy=1+rnd(2),rnd(1)-0.5
  addenemybullet{
   x=boss.x,y=boss.y,
   hw=1,hh=1,
   spdx=_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.9,
   life=rnd(90)+60,
   draw=drawbossflakbullet,
   ondeath=fizzle,
  }
  addenemybullet{
   x=boss.x,y=boss.y,
   hw=1,hh=1,
   spdx=-_spdx,
   spdy=_spdy,
   accy=0.01,
   spdfactor=0.95,
   life=rnd(90)+60,
   draw=drawbossflakbullet,
   ondeath=fizzle,
  }
 end
end

local function drawbossslicer(_bullet)
 sspr(42,118,8,5,_bullet.x-3,_bullet.y-2)
end
local function shootbossslicer()
 addenemybullet{
  x=boss.x,y=boss.y,
  hw=3,hh=3,
  spdy=2,
  life=999,
  ondeath=explode,
  draw=drawbossslicer,
 }
 sfx(30,2)
end

local function updatebossbubble(_bullet)
 bulletclearbullets(_bullet,bullets)
end
local function drawbossbubble(_bullet)
 circ(_bullet.x,_bullet.y,2,14)
 pset(_bullet.x-1,_bullet.y-1,7)
end
local function shootbossbubble()
 addenemybullet{
  x=boss.x,y=boss.y,
  hw=2,hh=2.5,
  spdx=rnd()-0.5,spdy=rnd()-0.5,
  spdfactor=0.96,
  life=210,
  update=updatebossbubble,
  ondeath=fizzle,
  draw=drawbossbubble,
 }
 sfx(29,2)
end

local blinkdirs=split'-1,0,1'
local superbossweaponnames=split'missile,mines,boost,shield,ice,blink,flak,beam,bubbles,slicer,bullet'
local bosstses=split'boostts,shieldts,beamts,icets'
local bosststs=s2t'boostts=2,shieldts=2.5,beamts=2,icets=1.125'
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
 ice=function()
  boss.icets=t()
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
 slicer=shootbossslicer,

 bullet=function()
  enemyshootbullet(boss)
 end,
}


local enemycargobulletpcolors=split'7,14,2'
local function drawenemycargobullet(_bullet)
 rectfill(_bullet.x,_bullet.y,_bullet.x+1,_bullet.y+1,7)
end
local function enemyshootcargobullet(_enemy)
 addenemybullet{
  hw=1,hh=1,life=1000,spdy=_enemy.vdir,
  escapefactor=0,
  x=_enemy.x,y=_enemy.y,
  spdx=_enemy.s == 116 and -1 or 1,
  draw=drawenemycargobullet,
  ondeath=explode,
  p=mr(s2t'xoff=0,yoff=0,r=0.1,spdx=0,spdy=0,spdr=0,life=3',{ colors=enemycargobulletpcolors }),
 }
end

local cargoshipsprites,cargoshipsprites2=split'110,112,114,116',split'133,134,135,136'

local enemyfactories={
 -- kamikaze
 function(_vdir)
  return mr(getship(100),{
   x=rnd(128),
   vdir=_vdir,
   update=function(_enemy)
    if _enemy.target == nil then
     _enemy.target=rnd(ships)
     _enemy.ifactor=rnd()
    end
    if _enemy.target then
     local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
     _enemy.spdx=cos(_a)*0.5
     _enemy.spdy+=(0.011+_enemy.ifactor*0.003)*_vdir
    end
   end,
  })
 end,

 -- fighter
 function(_vdir)
  return mr(getship(101),{
   vdir=_vdir,
   ts=t(),
   update=function(_enemy)
    if not _enemy.target then
     _enemy.x=flr(8+rnd(120))
     _enemy.spdy=(rnd(0.5)+0.5)
     _enemy.target=true
    end
    if t()-_enemy.ts > 0.875 and not _enemy.icec then
      enemyshootbullet(_enemy)
      _enemy.ts=t()
    end
   end,
  })
 end,

 -- minelayer
 function(_vdir)
  return mr(getship(102),{
   x=rnd(128),
   vdir=_vdir,
   ts=t(),
   update=function(_enemy)
    if _enemy.target then
     if t()-_enemy.ts > _enemy.duration or ispointinsideaabb(_enemy.target.x,_enemy.target.y,_enemy.x,_enemy.y,_enemy.hw,_enemy.hh) then
      _enemy.target=nil
     end
    else
     _enemy.spdx,_enemy.spdy=0,0
     if t()-_enemy.ts > 1.5 and not _enemy.icec then
      enemyshootmine(_enemy)
      _enemy.ts,_enemy.duration,_enemy.target=t(),1+rnd(2),{x=4+rnd(120),y=rnd(116)}
      local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
      _enemy.spdx,_enemy.spdy=cos(_a)*0.75,sin(_a)*0.75+(_enemy.vdir == -1 and 0.5 or 0)
     end
    end
   end,
  })
 end,

 -- bomber
 function(_vdir)
  local _spdy=rnd(0.25)+0.325
  return mr(getship(103),{
   vdir=_vdir,
   spdy=_spdy,ogspdy=_spdy,
   ts=t(),
   update=function(_enemy)
    if not _enemy.target then
     _enemy.x=rnd(128)
     _enemy.target=true
    end
    if t()-_enemy.ts > 0.875 then
     _enemy.accx=rnd{0.0125,-0.0125}
     if rnd() > 0.375 and not _enemy.icec then
      enemyshootmissile(_enemy)
     end
     _enemy.ts=t()
    end
    _enemy.spdx=mid(-0.5,_enemy.spdx+_enemy.accx,0.5)
    _enemy.spdy=_enemy.ogspdy
   end,
  })
 end,

 -- cargoship
 function(_vdir)
  local _x,_len=flr(16+rnd(100)),flr(2+rnd(4))
  for _i=1,_len do
   local _si=_i == 1 and 1 or rnd(split'2,2,2,3,4')
   local _part=mr(getship(104),{
    x=_x,y=(_vdir == 1 and -12 or 140)+_i*8*-_vdir,
    vdir=_vdir,
    s=cargoshipsprites[_si],
    s2=cargoshipsprites2[_si],
    ts=t(),
    update=function(_enemy)
     if _enemy.s >= 114 and t()-_enemy.ts > 2+rnd(2) and not _enemy.icec then
      enemyshootcargobullet(_enemy)
      _enemy.ts=t()
     end
    end,
   })
   if _i < _len then
    _part.exhausts=nil
   end
   add(enemies,_part)
  end
 end,
}

local function explodeenemy(_enemy)
 explode(_enemy)
 if _enemy.s == 112 then
  newcargodrop(_enemy.x,_enemy.y)
 end
 del(enemies,_enemy)
end


local lastframe,curt
function gameupdate()

 curt=t()
 
 escapefactor=1
 if #ships > 0 and not boss then
  local _fastestship=ships[1]
  if ships[2] and ships[2].y < _fastestship.y then
   _fastestship=ships[2]
  end
  escapefactor=max(1,(128-_fastestship.y)/32)
 end

 if escapeelapsed then
  hasescaped=escapeelapsed > escapeduration
 end

 -- update bullets
 updatebullets(bullets)
 updatebullets(enemybullets)

 -- update ships
 for _ship in all(ships) do
  local _plidx,_newx,_newy,_spd=_ship.plidx,_ship.x,_ship.y,1

  if _ship.isboosting then
   _spd=2
  end

  if _ship.isbeaming then
   _spd*=0.25
  end

  if _ship.icec then
   _spd*=0.5
   updateicec(_ship)
  end
  
  -- move
  if btn(0,_plidx) then
   _newx+=-_spd
  end
  if btn(1,_plidx) then
   _newx+=_spd
  end
  if btn(2,_plidx) then
   _newy+=-_spd
  end
  if btn(3,_plidx) then
   _newy+=_spd
  end
  
  _ship.x,_ship.y=mid(4,_newx,124),mid(4,_newy,119)
  local _urx,_ury=_ship.x-4,_ship.y-4

  -- repairing/firing
  if _ship.secondaryc <= 0 then
   _ship.isshielding,_ship.isboosting,_ship.isbeaming=nil
  end

  if _ship.hp < 3 then
   newburning(_ship.x,_ship.y)
   _ship.primaryc=max(0,_ship.primaryc-0.0875)
   if btnp(4,_plidx) then
    _ship.primaryc+=4
    if _ship.primaryc >= 37 then
     sfx(24,_ship.plidx)
     _ship.hp,_ship.primaryc=3,0
    end
   end
  else
   local _btn4=btn(4,_plidx)
   if _ship.icec then
    _btn4=nil
   end
   if _btn4 then
    _ship.primaryc+=0.25
    _ship.firingc-=1
    if _ship.firingc <= 0 then
     _ship.firingc=10
     for _gun in all(_ship.guns) do
      shipsfx(_ship,8+_ship.plidx)
      addbulletps(_ship,_gun)
      addbullet{
       x=_urx+_gun.x,y=_ury+_gun.y,
       hw=1,hh=2,
       spdy=-3,
       dmg=1,
       life=1000,
       draw=drawbullet,
       p={
        xoff=0,yoff=4,r=0.1,
        spdx=0,spdy=-0.1,spdr=0,
        colors={_ship.bulletcolor},
        life=2,
       },
      }
     end
    end
   else
    _ship.primaryc=max(0,_ship.primaryc-0.25)
    _ship.firingc=0
   end

   _ship.primaryc=mid(0,_ship.primaryc,38)
   primary[_ship.primary](_btn4,_ship,_btn4 and _ship.primaryc > 1 and not _ship.lastbtn4)
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

  if _ship.loopingsfx and not (_ship.isboosting or _ship.isbeaming or _ship.isshielding) then
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
    add(ships,mr(getplayership(boss.s),{plidx=_plidx,x=_ship.x,y=_ship.y,hp=1}))
    nickedts,escapeelapsed,nickitts,boss=curt,0
    pal(0,0,1)
    sfx(1,2)
    for _enemy in all(enemies) do
     if _enemy.s < 108 then
      _enemy.vdir=-1
     end
    end
   elseif _ship.isshielding and not boss.shieldts then
    boss.hp-=0.5
    newhit(boss.x,boss.y)
   else
    explode(_ship)
    _ship.hp=0
    sfx(-2,2)
   end
  end

  if _ship.hp == 0 then
   explode(_ship)
   sfx(-2,_ship.plidx)
   del(ships,_ship)
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
   else
    newburning(boss.x,boss.y)
    nickitts=nickitts or curt
   end
  else
   if boss.icec then
    updateicec(boss)
    boss.waitdurationc=0
   end
   for _ts in all(bosstses) do
    local _t=boss[_ts]
    if _t and curt-_t > bosststs[_ts] then
     boss.boost,boss[_ts]=0
     sfx(-2,2)
    end
   end
   local _icefactor=boss.icec and 0.5 or 1
   if _bossdt > boss.flydurationc and not (boss.beamts or boss.icets or boss.boostts or boss.shieldts) then
    if _bossdt > boss.flydurationc+boss.waitdurationc then
     sfx(-2,2)

     boss.waitdurationc,
     boss.flydurationc,
     boss.ts,
     boss.boost,
     boss.boostts,boss.shieldts,boss.beamts=
     0.875+rnd(1.75),
     boss.flyduration+rnd(5),
     curt,
     0

     if not boss.icec then
      bossweapons[rnd{boss.primary,boss.primary,boss.secondary}](boss)
      if issuperboss then
       boss.primary=rnd(superbossweaponnames)
      end
     end
    end
   else
    if boss.targetx == nil or ispointinsideaabb(boss.targetx,boss.targety,boss.x,boss.y,boss.hw,boss.hh) then
     local _targety=8+rnd(36)
     if boss.shieldts then
      _targety+=42
     end
     boss.targetx,boss.targety=4+rnd(120),_targety
    end

    if boss.boostts then
     addenemybullet{
      x=boss.x,y=boss.y-8,
      hw=3,hh=5,
      spdfactor=0,
      draw=emptyfn,
     }
    end

    if boss.icets then
     shootice(boss,60,enemybullets)
    end

    if boss.beamts then
     addenemybullet{
      x=boss.x,y=boss.y+64+6,
      hw=3,hh=64,
      spdfactor=0,
      colors=enemybeamcolors,
      pcolors=enemybeampcolors,
      draw=drawbeam,
      -- todo: add clear bullets?
     }
    end

    local _absx,_spd=abs(boss.targetx-boss.x),0.5+boss.boost
    if _absx > 1 and boss.targetx-boss.x < 0 then
     boss.x-=_spd*_icefactor
    elseif _absx > 1 and boss.targetx-boss.x > 0 then
     boss.x+=_spd*_icefactor
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
 for _enemy in all(enemiestoadd) do
  add(enemies,_enemy)
 end
 enemiestoadd={}
 local _spawninterval=max(0.75,6*lockedpercentage)
 if escapeelapsed then
  _spawninterval=max(0.25,2*lockedpercentage)
 end
 local gamestartdone=issuperboss or (boss and t()-gamestartts > 1.25) or true
 local _vdir=boss and 1 or -1
 if gamestartdone and
    (not (hasescaped or issuperbossdead)) and
    curt-enemyts > _spawninterval and
    #enemies < 25 and
    nickitts == nil and
    curt-(nickedts or (curt-2)) > 1.5 then
  enemyts=curt
  local _count=1
  if #enemies == 0 then
   _count=4
  end

  local _enemytypes=clone(enemyfactories)
  add(_enemytypes,enemyfactories[1]) -- note: add kamikaze again to have more of those enemies
  for _i=0,_count do
   add(enemies,rnd(_enemytypes)(_vdir))
  end
 end

 for _enemy in all(enemies) do
  for _exhaust in all(_enemy.exhausts) do
   newexhaustp(_exhaust,enemyexhaustpyoffset[_enemy.vdir],_enemy,_enemy.exhaustcolors,3,-_enemy.vdir)
  end

  if _enemy.hp <= 0 then
   explodeenemy(_enemy)
  else
   if _enemy.icec then
    updateicec(_enemy)
   end
   _enemy.x+=_enemy.spdx*(issuperboss and 1.5 or 1)*(_enemy.icec and 0.5 or 1)
   _enemy.y+=_enemy.spdy*(issuperboss and 1.25 or 1)*((boss and _enemy.icec and 0.5) or 1)
   _enemy.update(_enemy)

   if _enemy.s >= 104 then
    if not ispointinsideaabb(_enemy.x,_enemy.y,64,64,64,112) then -- 128 (0), 224 ()
     del(enemies,_enemy)
    end
   elseif not ispointinsideaabb(_enemy.x,_enemy.y,64,64,75,77) then -- 150 (11), 154 (13)
    del(enemies,_enemy)
    if boss then
     local _newenemy=enemyfactories[_enemy.factory](_vdir)
     _newenemy.x=_enemy.x
     add(enemiestoadd,_newenemy)
    end
   end

   for _ship in all(ships) do
    if isaabbscolliding(_enemy,_ship) then
     explodeenemy(_enemy)
     if not _ship.isshielding then
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

 -- events
 if ((hasescaped and #enemies == 0) or issuperbossdead) and not madeitts then
  if issuperbossdead and boss then
   boss=nil
   dset(63,dget(63)+1)
   for _ship in all(ships) do
    poke(0x5e64+_ship.s,1) -- set kill boss count
   end
  end
  if ships[1] then
   madeitts,exit=t(),s2t'x=64,y=0,hw=64,hh=8'
   sfx(3,2)
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
  return pickerinit()
 end

end

local function getpcolor(_p)
 return _p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
end
local function drawps(_ps)
 for _p in all(_ps) do
  _p.x+=_p.spdx
  _p.y+=_p.spdy
  _p.r+=_p.spdr
  _p.lifec-=1
  _p.col=getpcolor(_p)
  circfill(_p.x,_p.y,_p.r,_p.col)
  if _p.lifec < 0 or not ispointinsideaabb(_p.x,_p.y,64,64,64,64) then
   del(_ps,_p)
   if _p.ondeath then
    _p.ondeath(_p.x,_p.y)
   end
  end
 end
end

function gamedraw()
 cls()

 -- draw stars
 local _starcol=nickedts and 5 or 1
 for _s in all(stars) do
  _s.y+=_s.spd*escapefactor
  if _s.y>130 then
   _s.y=-3
   _s.x=flr(rnd()*128)
  end
  pset(_s.x,_s.y,_starcol)
 end

 -- draw particles below
 drawps(bottomps)

 -- draw cargos
 for _c in all(cargos) do
  _c.x+=_c.spdx
  _c.y+=_c.spdy
  spr(137,_c.x-4,_c.y-4)
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
  spr((issuperboss and _enemy.s2 or _enemy.s)+(_enemy.vdir == 1 and 0 or 1),_enemy.x-4,_enemy.y-4)
 end

 -- draw ships
 for _ship in all(ships) do
  spr(_ship.s,_ship.x-4,_ship.y-4)
 end

 -- draw exit
 if exit then
  local _frame=getblink()
  local _sx=39+_frame*5
  print('to secret hangar',32,3,10+_frame)
  sspr(_sx,123,5,5,18,3)
  sspr(_sx,123,5,5,104,3)
 end

 -- draw boss
 if boss then
  local _urx,_ury=flr(boss.x)-4,flr(boss.y)-4
  if boss.hp > 0 then
   if issuperboss then
    spr(126,flr(boss.x)-8,flr(boss.y)-6,2,2)
    spr(140+flr((t()*8)%2),_urx,_ury)
    if boss.shieldts then
     drawshield(boss.x,boss.y,8,11)
    end
   else
    spr(boss.s,_urx,_ury,1,1,false,true)
    for _pset in all(boss.psets) do
     pset(_urx+_pset[1],_ury+_pset[2],_pset[3])
    end
    if boss.shieldts then
     drawshield(boss.x,boss.y,8)
    end
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
  _p.col=getpcolor(_p)
  circfill(_p.x+_p.follow.x+_p.xoff,_p.follow.y+_p.yoff+_p.y,_p.r,_p.col)
  if _p.lifec < 0 then
   del(psfollow,_p)
  end
 end

 drawps(ps)

 -- draw top fx
 for _ship in all(ships) do
  if _ship.isshielding then
   drawshield(_ship.x,_ship.y,12)
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
   escapeelapsed+=(t()-lastframe)*escapefactor
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
   local _str=_ship.primary
   local _strx=_xoff+37-#_str*4
   rectfill(_xoff,121,_xoff+37,125,1)
   rect(_xoff+2,122,_xoff+4,124,13)
   print(_str,_strx,121,13)
   clip(_xoff,121,_ship.primaryc,5)
   rectfill(_xoff,121,_xoff+37,125,weaponcolors[_str])
   rect(_xoff+2,122,_xoff+4,124,7)
   print(_str,_strx,121,7)
   clip()
  end

  -- secondary
  if _ship.hp < 2 then
   sspr(9,118,20,5,_xoff+41,121)
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

 if t()-gamestartts < 2 and boss then
  local _frame=getblink()
  sspr(39+_frame*5,123,5,5,boss.x-2,boss.y+8)

  if issuperboss then
   drawblinktext('embarrass!',8)
  else

   if t()-gamestartts < 1 then
    print('neat ship',boss.x-17,boss.y+14,10+_frame)
   else
    drawblinktext('want it!',8)
   end

  end
 end

 if nickitts and t()-nickitts < 1.5 then
  drawblinktext('nick it!',6)
 end

 if nickedts and t()-nickedts < 1.5 then
  drawblinktext('get away!',9)
 end

 if madeitts then
  drawblinktext('made it!',10)
 end

 lastframe=curt

end

function gameinit()
 gamestartts,gameoverts,nickitts,nickedts,escapeelapsed,madeitts,hasescaped,exit=t()
 ps,psfollow,bottomps,bullets,enemies,enemiestoadd,enemybullets,cargos,stars={},{},{},{},{},{},{},{},{}
 enemyts,escapeduration,lockedpercentage,escapefactor=gamestartts,55,#getlocked()/100,1

 for i=1,24 do
  add(stars,{x=flr(rnd()*128),y=flr(rnd()*128),spd=0.5+rnd(0.5)})
 end

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
    ships[_i+1]=mr(getplayership(picks[_i]),{plidx=_i,x=32+_i*64})
    sfx(28,3)

    local _pickcount=mycount(picks)
    if _pickcount > 0 and _pickcount == mycount(ships) then
     local _locked=getlocked()
     if #_locked == 0 or dget(62) >= 5 then
      boss,issuperboss=getship(105),true
     else
      boss,issuperboss=mr(getship(rnd(_locked)),s2t'x=64,y=0,hw=3,hh=3,vdir=1,hp=127,flydurationc=8,waitdurationc=2,boost=0,plidx=2,firedir=1')
     end
     boss.ts=t()
     return gameinit()
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
 local _locked=getlocked()

 if #_locked == 0 then
  sspr(unpack(split'6,120,3,3,15,1'))
  print('\f8police embarrasments:'..dget(63),19,1)
 elseif dget(62) >= 5 then
  print('\fdsecret hangar     \f8police raid!',2,1)
 else
  rectfill(unpack(split'65,1,125,5,3'))
  print('\fdsecret hangar   \fbconvoy defense',2,1)
  clip(65,1,(98-#_locked)/100*61,5)
  rectfill(unpack(split'65,1,125,5,2'))
  print('\fdsecret hangar   \f8convoy defense',2,1)
  clip()
 end
 for _i=0,1 do
  local _pick=picks[_i]
  if _pick then
   local _x,_y=9+(_pick%10)*11,9+flr(_pick/10)*11
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
   local _s,_x,_y=_y*10+_x,10+_x*11,10+_y*11
   if isunlocked(_s) then
    spr(_s,_x,_y)
    if _s == newship then
     print('new',_x-1,_y+5,10+getblink())
    elseif peek(0x5e64+_s) == 1 then -- get boss kill count
     sspr(6,120,3,3,_x-1,_y-1)
    end
   else
    spr(248,_x,_y)
   end
  end
 end
end

function pickerinit()
 pal(0,129,1)
 pal(split'1,136,139,141,5,6,7,8,9,10,138,12,13,14,134',1)
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
 local _d62=dget(62)
 if madeitts then
  _d62+=1
 end
 if issuperboss then
  _d62=0
 end
 dset(62,_d62)
 ships={}
 _update60,_draw=pickerupdate,pickerdraw
end

-- splash
pal(split'1,2,3,4,5,6,7,8,9,10,138,0,13,14,129',1)
music(1)
_update60=emptyfn
local splashshipsd=0
_draw=function ()
 if btnp(4) then
  music(-1)
  sfx(3)
  return pickerinit()
 end

 cls()
 splashshipsd+=0.5
 if splashshipsd > 16 then
  splashshipsd=0
 end
 for _x=0,12 do
  for _y=0,12 do
   spr(118+(8-_x+_y)%8,4+_x*16-splashshipsd,4+_y*16-splashshipsd)
  end
 end
 sspr(unpack(split'0,72,128,46,0,26'))
 print('\fbpress \x8e',48,121)
end

__gfx__
00066000000dd000000dd00000606000000550000900009000022000000220000070070000088000000990000009900007000070000cc000000ff00000033000
000af000005dd500040ab04000606000004b3400090000900057e500005225000700007000088000009af900009769007800008700dabd0000f66f0000ba9b00
00dffd00005e2500046bb64006f6f60004d33d40690b3096005ee50000598500760000670007b00000faff0008676680780000870ddbbdd00f6766f00b3993b0
06dffd6006522560d66bb66d06f6f67544d33d4469033096025ee52006688660760b306700fbbf0000f99f0082699628780a9087ddcbbcddfd6666dfb3d99d3b
66d66d666d5225d6d66dd66d6f666f5506d55d6069433496245225426ff88ff676d33d67f0fbbf0f009999008289982878099087dcdccdcdfdd66ddfbd5dd5db
00d66d006d5dd5d6004dd400666f666f6dd55dd696d66d6924422442f652256f76d77d67f2f88f2f029229209289982988599588cdccccdc04dffd40bd5335db
06d66d6066dddd660d6dd6d06f666fff6d0550d699466499224224226552255607677670f2f88f2f229229229289982968588586dc0550cd05dffd50b500005b
66d55d66044004400d0550d006f6f6006600006609055090dd0dd0dd054004500067760002f88f20229229229000000966088066c000000c0550055030000003
000dd00000022000000ee00000422400000550000060060000d55d0000066000000990000f0f0000000dd0000200002000044000000660000009900000088000
00d76d00002a9200006ee6000542245000555500006996000dd55dd0006a960000da8d000f0f0000040ab040e200002e00db3d00006826000009900000888800
0f6766f0029a992005782750554994550d5f15d000dbcd000dd11dd006d99d6000d88d004f4f40ab04dbbd40e20cd02e08d33d8006f22f60000bc000028a9820
ff6446ff2492294265282256449a99440d1f11d060dccd065d1c11d5dfd99dfd0d6886d04ddd40bbdd5bb5dde20dd02e2dd33dd27f6226f7006cc600229a9922
00d44d0024422442762ee267429999244d1441d4694cc4965d1111d5dfdffdfd6d6996d6ddddd544d55dd55de24dd42e28d44d8276f77f67006cc60028988982
0d5445d022422422d7eeee7d422992244d5445d4d949949d5dd11dd56fdffdf66dc99cd6d545d545000dd000e242242e8dd44dd87ff77ff770699607d828828d
d554455d05500550d545545d05244250dd5445ddd949949d0d5dd5d06f0dd0f6cdc99cdcd454d0450d5dd5d0220220228d0550d86f0550f679699697d828828d
d540045d04500540d404404d004444000440044005500550005dd50060000006c0c44c0c055500000d5445d0e200002e82000028600000066969969605055050
060660600c0000c00003300000077000000660000062260000dffd0000800800000ff00000dffd0000f00f000600006000066000000660000006600000066000
600b30066c0000c600f33f00007d4700000660000d6226d00dffffd000900900000c400004dffd400f0000f062000026000660006007f006006e2600006dd600
60f33f066c0b30c600f95f0007c44c70000660000d6946d05dfbbfd50a9009a00074470044d66d44fd0000df620bc026000a5000655ff5560d2e22d006de8d60
f046640f6c0330c603595530c6c44c6c600c5006d649446dfdb7bbdf0a9009a007644670dd6766ddfd07b0df625cc52600d55d00600ff006d426624d0d4884d0
404664046c4334c63f5665f3c6c77c6cf0d55d0f26422462fdbbbbdfa907c09a766ff667df6666fdfd4bb4df6252252600f55f0060066006d4d66d4d0d4884d0
400ff004c6d66d6c3f3663f376c77c6762f66f2626d22d62fddbbddfa90cc09a007ff700dff66ffd4d4ff4d4220220220f6ff6f06556655664d66d46d44dd44d
45466454cc4664cc30366303760cc06762f66f260dd22dd005dffd50099dd990076ff67004fddf4004dffd40f200002f66f66f666006600664d66d46d46dd64d
404664040c0550c00005500070000007f040040f00d55d0005500550055005507665566700dddd0000fddf000f0000f0f6d66d6f600000066550055600644600
000cc00000066000000bb00000088000000ff000000ff00000044000006ff60000200200000bb00000d00d000a0000a000066000050000500002200003000030
000cc0000d09f0d00607e06000276200000ff00000fbcf00004af40006ffff600240042000b7bb0000d33d00a200002a00066000050760500009f000c300003c
000a90000d7ff7d0063ee36002266220006846000ffccff0041ff140f6f55f6f240000420fb7bbf000da9d00a200002a00066000df0660df005ff500cd0000dc
00d99d00677ff776b33ee33b020660200064460006fccf60415ff514f65c556f240e80420fb7bbf000d99d00a20b302a000c5000fd4fd4dd045ff540cd0a90dc
00d99d0067766776b33bb33b0008800009644690f6f66f6f45144154f655556f5408804504bbbb400bd99db0a203302a00655600dd4dd4fd54522545dd0990dd
60dccd0600066000000bb000080880809f6ff6f96f6ff6f641144114f665566f5404404554fbbf45bbd33dbb22533522096ff690fd0df0df005225003d5995d3
6cdccdc6007667000b3bb3b0824884289f6ff6f9f66ff66f410550140f6ff6f002400420f5f55f5f03d33d3092522529696ff696550dd05504255240dc5cc5cd
dcdccdcd000550000b3553b08505505890d55d09055005504000000400ffff0000200200054554503303303399022099695ff5960005500054255245dc0cc0cd
00055000000dd000000ff0000004d00000077000000dd00003000030000ee00004000040000ff000004dd40000600600000dd00000088000000330000f0ff0f0
0005500000de4d000d0ab0d0000d40000076c700000dd0000b3003b000eb3e0042000024009ff9000d4994d00060060000dabd000007e00000333300ff0760ff
000e20000f4e44f00d4bb4d0000e80000bc6ccb0005bc50000be2b000023320042000024009ab9000d9a99d006f00f600fbabbf0200ee0020537635067566576
00f22f00f54fd45f454bb45400f88f00b3c77c3b005cc500000220000e2332e0420980240fbabbf00d9a99d06f0000f60fbabbf02f0ee0f205676650f606606f
00f22f0000ddfd00545ff54500f88f00b3b77b3b0f5cc5f00b3223b0e224422e42088024f9b99b9f0d9999d06f0000f60fbddbf02f2882f2d56dd65d675ff576
d0f55f0d0f5fd5f0000ff00060fd4f0673b77b37fd5dd5dfb33bb33b04d22d4022188122ff9999ff5d5995d56f07b0f64fddddf40f2882f0d53dd35df65ff56f
d5f55f5dfd5df5df045ff54064f4dfd673b77b37fd5dd5dfb30bb03b5d0440d52412214200f44f005d5dd5d506cbbc6045d44d540f2882f05d3dd3d5670ff076
f5f55f5ff050050f054dd450fdf4df4f70044007f0f44f0fb004400b05000050440220440005500050500505000ff000400000040025520005500550f000000f
d00dd00d07000070005ff5000052250000028000070000700f0000f000077000000bb000000ff000000ff0000000d0d00d0000d0000660000000060000700700
0d2dd2d0790000970f5b35f005522550000820007e0000e70f0000f00039830000c76c0000cffc0000fbcf0000007670d500005d000c50000000d6d000800800
002ab20079000097f53b335f555bc555000760007e0000e77607b067033883300c6766c00fcb9cf00f5cc5f0e2067676d50e405d002552007906d6d60086d800
0dbabbd0790e8097f535535f25cbcc5200d66d007e0bc0e7760bb06700688600bc6bb6cb0f9b99f05d5cc5d522076767d504405d042552409906d6d6608d6806
42b22b2479088097f550055f25c55c52d0d66d0d7e5cc5e76657756606377360bccbbccbdf9cc9fd5d5ff5d577476767d515515d442662446656d6d6658dd856
d2d22d2d995885990500005025455452d4d28d4dee5ee5ee7606606763377336bbcbbcbbdcfccfcdfd5ff5df7647676755155155400660046d5d666df666666f
d0d44d0da959959a0500005002455420c4d82d4c6e0ee0e6f500005f63055036044004405d5dd5d5fd0550df76067776d505505d002662006d066d666d5dd5d6
00055000aa0990aa005005000045540004c28c4006000060ff0000ff600000060d4004d004400440f000000f5505505505011050042552400006d0d601155110
000dd00000f00f000600006000500500f004400f000550000004400000055000050440500f0000f004400440000ff00000000000000000005f5555f500f55f00
000dd0000d0000d0700000070d0000d0f50ff05f00fa9f005ff55ff50007e000f505505ff500005f555ff55500ffff0000000000000000005f5555f505f55f50
00076000f70d507f70077007d009900df55ff55f0f5995f05ff55ff5000ee00055155155f50bc05ff55ff55f05fabf5000000000000000005f5555f505f76f50
00d66d00d705507d600b3006d09a990df55ff55ff559955f5ff55ff550feef05f515515ff50cc05ff5bffb5f05babb5000000000000000005f6766f50f6766f0
00c66c00f70ff07f70f33f070d9999d0f55a955ff55ff55f50f7ef055ff55ff5f50bc05ff515515f05babb50f5bffb5f00000000000000000f6766f05f6766f5
30cddc03d70ff07d74677647d449944d0f5995f0f55ff55f000ee0005ff55ff5f50cc05f5515515505fabf50f55ff55f000000000000000005f66f505f5555f5
3dcddcd30d0000d0f467764f004dd40000f99f00f50ff05f000ee0005ff55ff5f500005ff505505f00ffff00555ff555000000000000000005f55f505f5555f5
cdcddcdc00d00d00600ff0060405504000055000f004400f00055000000440000f0000f005044050000ff00004400440000000000000000000f55f005f5555f5
055555500555555005555550055555500555555005555550000ff0000f0000f0000ff000000ff000000ff000000ff000000ff000000ff0000000055005500000
5f5ff5f55f5ff5f55ffffff55ffffff55ffffff55ffffff5000ff000ff0000ff00ff0f0000ffff000f0f00f0000ff00000ff0f00000f000000006d6666d60000
5f5ff5f55f5ff5f55ff55ff55ff556f55ff55ff55f655ff5000f0000ff0000ff0ff00ff000ff0f000ff00ff0000ff0000f0f00f000f00f000006d6d66d6d6000
5ff55ff55ff55ff55f5ff5f55f5f65f55f5ff5f55f56f5f500f00f00ff0f00fffff00fff0f0f00f0fff00ffff00f000f0f0ff0f00ff00ff0006d6d6dd6d6d600
5ff55ff55ff55ff55f5f65f55f5ff5f55f56f5f55f5ff5f500f00f00ff0000ffffffffffff0ff0fffffffffff0f00f0f0ffffff0ffffffff0066dd6dd6dd6600
5f5ff5f55f5ff5f55ff556f55ff55ff55f655ff55ff55ff5f0ffff0ffff00fffffffffffffffffff000ff000ffffffffffffffff00ffff006dd6dd6666dd6dd6
5f5ff5f55f5ff5f55ffffff55ffffff55ffffff55ffffff5ffffffffffffffffff0ff0ff00ffff000ffffff0ffffffffff0ff0ff0ffffff006d6d8c668cd6d60
055555500555555005555550055555500555555005555550ffffffffff0ff0fff000000f000ff0000ffffff0f0f00f0ff000000fffffffff06d6d666666d6d60
d000000d000550006d0550d60550055000000000d6d66d6d0dddddd00dd66dd00dd66dd0000000000000000000000000000000000000000000d6116666116d00
d605506dd6d66d6d6d0660d6d6d66d6d00000000d6d66d6dd6666d6dd6dddd6dd6dddd6d00000000000000000000000000000000000000006006d1f1111d6006
d66dd66dd6d66d6ddd5665dd66d66d660000000006d66d60dddddd6d0dd66dd00dd66dd0004dd400000000000000000000000000000000006dd6ddf111dd6dd6
dd6dd6ddd0d66d0d6d5665d66d5665d600000000d616616dd6d66d6ddd6666dddd6666dd00d4dd0000000000000000000000000000000000066d6dd11dd6d660
d6d95d6d00de4d00dd0c40dd0d5355d000000000061f1160d6d66d6d0d6616d00d6166d000dd4d00000000000000000008c668c00c866c80006dd6dddd6dd600
0d6556d0000440006d0440d60d6356d000000000dd6f16ddd6ddddddddd661dddd166ddd004dd40000000000000000000000000000000000006dd6d00d6dd600
00d55d00000440006d0000d600666600000000000dd66dd0d6d6666dd6dddd6dd6dddd6d00000000000000000000000000000000000000000006d600006d6000
000dd0000006600006000060000660000000000000d66d00dddddddd0dd66dd00dd66dd000000000000000000000000000000000000000000000660000660000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111717111111111111111111111711111111111111111111111111111111111111111111111111111111171111111111111111111111
11111111111111111111111171111111111111111111117171111111111777777777111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111711111117777ccccccccc777711111111111171111111111111111111171111111111111111111111
1111111111111111111111111111111111111111111111111111177cccc222288888cccc77111111111717111111111111111111171111111111111111111111
11111111111111111111111111111111117777111111111111177cc22222228888888888cc771111111171111111111111111717717717111111111111111111
1111111111111111111111111111111117cccc7111111111117cc222222228888888888888cc7111111111111111111111111111171111111111111111111111
111111111111111111111111111111117c6666c71111111117c8222222228888888888822222c711111111111111111111111111171111111111111111111111
11111111111111111111111111111117cd66d66c711111117c888222288888888888222222222c71111111111111111111111111111111111111111111111111
1111111111111111111111111111117cdd666666c7111117c88888888888888888822222222222c7111111111111111111111111171111111111111111111111
1111111111111111111111111111117c666666ddc711117c8888888888888888882222222222228c711111111111111111111111111111111111111111111111
1111111111111111711111111111117c6666d6ddc71117c888888888888888888882222222228888c71111111111111111111111111111111111111111111111
1111111111111111111111111111117c66d6666dc7117c88888888888888888888882222228888888c7111117771111111111111111111111111111111111111
11111111111111117111111111111117c666666c7117c8888888888888888888888888888888888888c71117ccc7111111111111111111111111111111111111
111111111111111171111111111111117c66ddc71117c8888888888888888888888888888888888888c7117c9a9c711111111111111111111111111111111111
1111111111117177177171111111111117cccc71117c222222222888888888888888888888888888222c77c9a9aac71111111111111111111111111111111111
1111111111111111711111111111111111777711117c222222222222228888888888888888222222222c77ca99a9c71111111111111111111111111111111111
111111111111111171111111111111111111111117c22222222222222888888888888888222222222222c7c9aa9ac71111111111111111111111111111111111
111111111111111111111111111111111111111117c22222222222228888888888888882222222222222c77ca9ac711111111111111111111711111111111111
111111111111111171111111111111111111111117c22222222222228888888888888888222222222222c717ccc7111111111111111111117171111111111111
11111111111111111111111111111111111111117c2222222222228888888888888888888888222222222c717771111111111111111111111711111111111111
11111111111111111111111111111111111111117c2222222222888888888888888888888888888222222c711111111111111111111111111111111111111111
11111111111111111111111111111111111111117c2222222228888888888822222888888888888888888c711111111111111111111111111111111111111111
11111111111111111111111111111111111111117c8888888888888888822222222222888888888888888c711111111111111111111111111111111111111111
11111177777771117771117771117777777111177c8888888888888888222222222222228888888888888c717771177777771111777777711177777771111111
111117ccccccc717ccc717ccc717ccccccc7117ccccccc888ccc888ccc22ccccccc2222ccccccc8888cccc77ccc77ccccccc7717ccccccc717ccccccc7111111
11117caaaaaaac7caaac7caaac7caaaaaaac77caaaaaaac8caaac8caaaccaaaaaaac22caaaaaaacc8caaac7caaaccaaaaaaacc7caaaaaaac7caaaaaaac711111
11117caaaaaaacccaaac7caaac7caaaaaaacc7caaaaaaac8caaac8caaaccaaaaaaacccaaaaaaaaaaccaaac7caaacaaaaaaaaaaccaaaaaaac7caaaaaaacc71111
1117caaaaaaaaaacaaac7caaaacaaaaaaaaaacaaaaaaaaacaaaac8caaacaaaaaaaaaacaaaaaaaaaacaaaaccaaaacaaaaaaaaaacaaaaaaaaacaaaaaaaaaac7111
1117caaaaaa8aaacaaacccaaaac888aaaa888caaaa8888acaaaacccaaac888aaaa888caaaaaaaaaacaaaaccaaaacaaaaaaaaaacaaaa8888acaaaaaa8aaac7111
1117caaaaaa8888caaaaaaaaaac888aaaa888caaaa8888acaaaaaacaaac888aaaa888caaaaaaaaaacaaaaaaa888caaaa888888caaaa8888acaaaaaa8888c7111
1117caaaaaaaaaacaaaaaaaaaac888aaaa888caaaa8888acaaaaaaaaaac888aaaa888caaa8888888caaaaaaaaa8caaaa888888caaaaaaaaacaaaaaaaaaac7111
1117caaaaaaaaaacaaaaaaaaaac888aaaa888caaaaaaaaacaaaaaaaaaac888aaaa888caaa8888888caaaaaaaaa8caaaaaaaaaacaaaaaaaaacaaaaaaaaaac7111
1117c8888aaaaaacaaa888aaaaccccaaaaccccaaaa88888caaaa8aaaaaccccaaaaccccaaa8888888caaaa88aaaacaaaa888888caaaaaaaa8c8888aaaaaac7111
1117caaaaaaaaaacaaa888aaaacaaaaaaaaaacaaaa88888caaaa888aaacaaaaaaaaaacaaaaaaaaaacaaaa88aaaacaaaaaaaaaacaaaa8aaa8caaaaaaaaaac7111
1117caaaaaaaaaacaaa888aaaacaaaaaaaaaacaaaa88888caaaa888aaacaaaaaaaaaacaaaaaaaaaacaaaa88aaaacaaaaaaaaaacaaaa8aaa8caaaaaaaaaac7111
1117caaaaaaaaaacaaa888aaaacaaaaaaaaaacaaaa88888caaaa888aaacaaaaaaaaaacaaaaaaaaaacaaaa88aaaacaaaaaaaaaacaaaa8aaa8caaaaaaaaaac7111
1117c8888888888c888ccc8888c8888888888c8888cccccc8888c88888c8888888888c8888888888c8888cc8888c8888888888c88888888cc8888888888c7111
1117c8888888888c888c7c8888c8888888888c8888c7777c8888ccc888c8888888888c8888888888c8888cc8888c8888888888c8888c888cc8888888888c7111
1117c8888888888c888c7c8888c8888888888c8888c7117c8888c7c888c8888888888c8888888888c8888cc8888c8888888888c8888c888cc8888888888c7111
1117c8888888888c888c7c8888c8888888888c8888c7117c8888c7c888c8888888888c8888888888c8888cc8888c8888888888c8888c888cc8888888888c7111
11117cccccccccc7ccc717cccc7cccccccccc7cccc711117cccc717ccc7cccccccccc7cccccccccc7cccc77cccc7cccccccccc7cccc7ccc77cccccccccc71111
11111777777777717771117777177777777771777711111177771117771777777777717777777777177771177771777777777717777177711777777777711111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
0000000002222200002200222002200000d0000000e000000e0077770000777700000000003333333333333bbb3bbb3bbb3bbb3bbb3bbb330000000000000000
0000070002000020002020222020000000d00000007e0000e707777770077aaa700000000033bbb33333333b3b3b333b3b3b3b33b33b3b330000000000000000
0000070a02000002002020202020000000d000000077eeee7777aaaa7777aa00000000000033b3b33333333bb33bb33bbb3bbb33b33bb3337777777777777777
855807aa92000020002020202020200000d0000000077777707a0000a77aa000001111000033bbb33333333b3b3b333b333b3b33b33b3b337777777777777777
58850a0902222200002220202022200074d400000000777700a000000a7a000001100110003333333333333b3b3bbb3b333b3b3bbb3b3b337777777777777777
00000060aa0000606070a009a97c0a0074d400000a0000b0000c0000007a00000000011000222222222222288828882888288828882888227777777777777777
00000060aa00c00700b00009a9cc0070e0d00000aaa00bbb00ccc000000700000001110000208880000000080808000808080800800808027777777777777777
00000060a90c0c7670000709a9000070e0d0707aaaaabbbbbccccc00000000000000000000208080000000088008800888088800800880027777777777777777
c55c0060980c0c070b000009a90c007070d007000a0000b0000c0000000000000001100000208880000000080808000800080800800808027777777777777777
5cc50d6d8000c0606700a009a9000a0070d070700a0000b0000c0000000000000000000000222222222222282828882822282828882828227777777777777777
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000001001000000000000011000000000000001100000000000000110000000000000011000000000000100001000000000001111000000
00000001000000000000001001000000000000111100000000000001100000000000000110000000000000110100000000001100001100000000011111100000
00000010010000000000011001100000000000110100000000000001000000000000001101000000000001010010000000001100001100000000111001110000
00000110011000000000110000110000000001010010000000000010010000000000001001000000000001011010000000001101001100000000110100110000
00001111111100000000110000110000000011011011000000000010010000000000011001100000000001111110000000001100001100000000110000110000
00000011110000000000110110110000000011111111000000001011110100000000111111110000000011111111000000001110011100000000111001110000
00000111111000000000011111100000000000111100000000001111111100000000111111110000000011011011000000001111111100000000011111100000
00001111111100000000000110000000000000011000000000001111111100000000101001010000000010000001000000001101101100000000001111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111717111111111111111111111711111111111111111111111111111111111111111111111111111111171111111111111111111111
11111111111111111111111171111111111111111111117171111111111777777777111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111711111117777000000000777711111111111171111111111111111111171111111111111111111111
11111111111111111111111111111111111111111111111111111770000222288888000077111111111717111111111111111111171111111111111111111111
11111111111111111111111111111111117777111111111111177002222222888888888800771111111171111111111111111717717717111111111111111111
11111111111111111111111111111111170000711111111111700222222228888888888888007111111111111111111111111111171111111111111111111111
11111111111111111111111111111111706666071111111117082222222288888888888222220711111111111111111111111111171111111111111111111111
111111111111111111111111111111170d66d6607111111170888222288888888888222222222071111111111111111111111111111111111111111111111111
11111111111111111111111111111170dd6666660711111708888888888888888882222222222207111111111111111111111111171111111111111111111111
11111111111111111111111111111170666666dd0711117088888888888888888822222222222280711111111111111111111111111111111111111111111111
111111111111111171111111111111706666d6dd0711170888888888888888888882222222228888071111111111111111111111111111111111111111111111
1111111111111111111111111111117066d6666d0711708888888888888888888888222222888888807111117771111111111111111111111111111111111111
11111111111111117111111111111117066666607117088888888888888888888888888888888888880711170007111111111111111111111111111111111111
111111111111111171111111111111117066dd071117088888888888888888888888888888888888880711709a90711111111111111111111111111111111111
1111111111117177177171111111111117000071117022222222288888888888888888888888888822207709a9aa071111111111111111111111111111111111
111111111111111171111111111111111177771111702222222222222288888888888888882222222220770a99a9071111111111111111111111111111111111
1111111111111111711111111111111111111111170222222222222228888888888888882222222222220709aa9a071111111111111111111111111111111111
1111111111111111111111111111111111111111170222222222222288888888888888822222222222220770a9a0711111111111111111111711111111111111
11111111111111117111111111111111111111111702222222222222888888888888888822222222222207170007111111111111111111117171111111111111
11111111111111111111111111111111111111117022222222222288888888888888888888882222222220717771111111111111111111111711111111111111
11111111111111111111111111111111111111117022222222228888888888888888888888888882222220711111111111111111111111111111111111111111
11111111111111111111111111111111111111117022222222288888888888222228888888888888888880711111111111111111111111111111111111111111
11111111111111111111111111111111111111117088888888888888888222222222228888888888888880711111111111111111111111111111111111111111
11111177777771117771117771117777777111177088888888888888882222222222222288888888888880717771177777771111777777711177777771111111
11111700000007170007170007170000000711700000008880008880002200000002222000000088880000770007700000007717000000071700000007111111
111170aaaaaaa070aaa070aaa070aaaaaaa0770aaaaaaa080aaa080aaa00aaaaaaa0220aaaaaaa0080aaa070aaa00aaaaaaa0070aaaaaaa070aaaaaaa0711111
111170aaaaaaa000aaa070aaa070aaaaaaa0070aaaaaaa080aaa080aaa00aaaaaaa000aaaaaaaaaa00aaa070aaa0aaaaaaaaaa00aaaaaaa070aaaaaaa0071111
11170aaaaaaaaaa0aaa070aaaa0aaaaaaaaaa0aaaaaaaaa0aaaa080aaa0aaaaaaaaaa0aaaaaaaaaa0aaaa00aaaa0aaaaaaaaaa0aaaaaaaaa0aaaaaaaaaa07111
11170aaaaaa8aaa0aaa000aaaa0888aaaa8880aaaa8888a0aaaa000aaa0888aaaa8880aaaaaaaaaa0aaaa00aaaa0aaaaaaaaaa0aaaa8888a0aaaaaa8aaa07111
11170aaaaaa88880aaaaaaaaaa0888aaaa8880aaaa8888a0aaaaaa0aaa0888aaaa8880aaaaaaaaaa0aaaaaaa8880aaaa8888880aaaa8888a0aaaaaa888807111
11170aaaaaaaaaa0aaaaaaaaaa0888aaaa8880aaaa8888a0aaaaaaaaaa0888aaaa8880aaa88888880aaaaaaaaa80aaaa8888880aaaaaaaaa0aaaaaaaaaa07111
11170aaaaaaaaaa0aaaaaaaaaa0888aaaa8880aaaaaaaaa0aaaaaaaaaa0888aaaa8880aaa88888880aaaaaaaaa80aaaaaaaaaa0aaaaaaaaa0aaaaaaaaaa07111
111708888aaaaaa0aaa888aaaa0000aaaa0000aaaa888880aaaa8aaaaa0000aaaa0000aaa88888880aaaa88aaaa0aaaa8888880aaaaaaaa808888aaaaaa07111
11170aaaaaaaaaa0aaa888aaaa0aaaaaaaaaa0aaaa888880aaaa888aaa0aaaaaaaaaa0aaaaaaaaaa0aaaa88aaaa0aaaaaaaaaa0aaaa8aaa80aaaaaaaaaa07111
11170aaaaaaaaaa0aaa888aaaa0aaaaaaaaaa0aaaa888880aaaa888aaa0aaaaaaaaaa0aaaaaaaaaa0aaaa88aaaa0aaaaaaaaaa0aaaa8aaa80aaaaaaaaaa07111
11170aaaaaaaaaa0aaa888aaaa0aaaaaaaaaa0aaaa888880aaaa888aaa0aaaaaaaaaa0aaaaaaaaaa0aaaa88aaaa0aaaaaaaaaa0aaaa8aaa80aaaaaaaaaa07111
11170888888888808880008888088888888880888800000088880888880888888888808888888888088880088880888888888808888888800888888888807111
11170888888888808880708888088888888880888807777088880008880888888888808888888888088880088880888888888808888088800888888888807111
11170888888888808880708888088888888880888807117088880708880888888888808888888888088880088880888888888808888088800888888888807111
11170888888888808880708888088888888880888807117088880708880888888888808888888888088880088880888888888808888088800888888888807111
11117000000000070007170000700000000007000071111700007170007000000000070000000000700007700007000000000070000700077000000000071111
11111777777777717771117777177777777771777711111177771117771777777777717777777777177771177771777777777717777177711777777777711111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011110000000000000110000000000000011000000000000001100000000000000110000000000000011000000000000100001000000000000110000000
00000111111000000000001101000000000000011000000000000101001000000000000100000000000000110100000000001000000100000000000110000000
00001110011100000000010100100000000000010000000000000110011000000000001001000000000001010010000000001001100100000000001101000000
00001101001100000000010110100000000000100100000000001110011100000000011001100000000001011010000000001001000100000000001001000000
00001100001100000000111111110000000000100100000000001111111100000000111111110000000001111110000000001010010100000000011001100000
00001110011100000000111111110000000010111101000000000001100000000000001111000000000011111111000000001011110100000000111111110000
00000111111000000000111111110000000011111111000000000111111000000000011111100000000011011011000000001111111100000000111111110000
00000011110000000000011001100000000011111111000000000111111000000000111111110000000010000001000000001011110100000000101001010000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000010110100000000000011000000000000001100000000000010000100000000000100100000000000001100000000000000110000000
00000001100000000000100100010000000000011000000000000001000000000000110000110000000000100100000000000011010000000000001111000000
00000001000000000000101001010000000000110100000000000010010000000000110000110000000000111100000000000110011000000000001101000000
00000010010000000000101111010000000000100100000000000110011000000000110100110000000010111101000000001110011100000000010100100000
00001010010100000000101111010000000001100110000000001111111100000000110000110000000011111111000000001111111100000000110110110000
00001111111100000000100110010000000011111111000000001001100100000000111001110000000011111111000000001111111100000000111111110000
00001111111100000000111111110000000011111111000000000011110000000000110110110000000011111111000000001101101100000000001111000000
00000111111000000000101111010000000010111101000000000111111000000000010000100000000001100110000000001000000100000000000110000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000000110000000000000100100000000000001100000000000001111000000000000011000000000000001100000000000000110000000
00000001100000000000010100100000000000100100000000000011010000000000011111100000000000011000000000000011110000000000000100000000
00000001100000000000011001100000000001100110000000000101001000000000111001110000000000010000000000000111011000000000001001000000
00001001000100000000111001110000000011000011000000000101101000000000110100110000000000100100000000000110011000000000001001000000
00001010010100000000111111110000000011000011000000000111111000000000110000110000000010100101000000000110011000000000011111100000
00001111111100000000000110000000000011011011000000001111111100000000111001110000000011111111000000001111111100000000111111110000
00001111111100000000011111100000000001111110000000001101101100000000111111110000000011111111000000001111111100000000111111110000
00001010010100000000011111100000000000011000000000001000000100000000011111100000000001111110000000000011110000000000011001100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001100000000000000110000000000000011000000000000100001000000000000110000000000000011000000000000001100000000000010000100000
00000011010000000000000110000000000000110100000000000100001000000000001101000000000000010000000000000101001000000000110000110000
00000110011000000000000100000000000001010010000000001001100100000000010100100000000000100100000000000110011000000000110000110000
00001110011100000000001001000000000011011011000000001001100100000000010110100000000001100110000000001110011100000000110100110000
00001111111100000000001001000000000000111100000000001011010100000000111111110000000000111100000000001111111100000000110000110000
00001111111100000000101111010000000001111110000000001110011100000000111111110000000001111110000000000001100000000000111001110000
00001101101100000000111111110000000011111111000000001111111100000000111111110000000011111111000000000111111000000000111111110000
00001000000100000000111111110000000010100101000000001001100100000000011001100000000000011000000000000111111000000000110110110000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

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
00020000336202c620236201a620136200c6200762002620006200060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
141800200425500205042550224504255022350425502235042550123504255002300425502245042550424504255022350425501235042550023504255022450425500200042550023002255022550225502245
141800200425500205042550224504255022350425502235042550123504255002300425502245042550424504255022350425501235042550023504255022450425500250042550424502255102430000002251
011800202832028320283220000000000000000000025300253212532025325000000000000000000000000028320283202832200000000000000000000000002f3202f3222f3220000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 41422220
02 41422221

