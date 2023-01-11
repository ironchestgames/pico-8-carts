pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- shipnickers 1.0
-- by ironchest games

--[[
 - add laser
 - add slicer
--]]

cartdata'ironchestgames_shipnickers_v1-dev1'

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable btnp auto-repeat

pal(0,129,1)
pal(split'1,136,139,141,5,6,7,8,9,10,138,12,13,14,134',1)

local unlocked
local function loadunlocked()
 unlocked={}
 local masks={0b00000001,0b00000010,0b00000100,0b00001000,0b00010000,0b00100000,0b01000000,0b10000000}
 for _i=0,22 do
  local _n=dget(_i)
  for _j=1,#masks do
   local _jj=_j-1
   unlocked[_i*7+_jj]=(masks[_j] & _n) != 0
   if unlocked[_i*7+_jj] == true then
    debug('----')
    debug(_i*7)
    debug(_jj)
   end
  end
 end
end

local function persistunlocked()
 for _i=0,#unlocked,8 do
  local _n=0
  for _j=0,7 do
   _n=_n | (unlocked[_i+_j] and 2^_j or 0)
  end
  dset(_i,_n) -- todo: this is wrong yeah?
 end
end

-- local function persistunlocked()
--  for _i=0,#unlocked,7 do
--   local _n=0
--   for _j=0,7 do
--    _n=_n | (unlocked[_i+_j] and 2^_j or 0)
--   end
--   dset(_i/7,_n)
--  end
-- end

local function getrandomlocked()
 local _indeces={}
 for _i=0,#unlocked do
  if not unlocked[_i] then
   add(_indeces,_i)
  end
 end
 if #_indeces > 0 then
  return rnd(_indeces)
 end
end

local function getlockedcount()
 local _count=0
 for _i=0,#unlocked do
  if not unlocked[_i] then
   _count+=1
  end
 end
 return _count
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
local ships,bullets,stars,ps,psfollow,bottomps,enemies,enemybullets,boss,lockedpercentage

local hangar={
 [0]=mrs2t's=0,bulletcolor=9,primary="missile",secondary="missile",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;0;5;0",exhaustcolors="7;14;8",exhausts="-1;3;0;3"',
 mrs2t's=1,bulletcolor=12,primary="missile",secondary="boost",secondaryshots=3,psets="3;5;2;3;3;8",guns="2;0;5;0",exhaustcolors="7;10;9",exhausts="-3;4;-2;4;1;4;2;4"',
 mrs2t's=2,bulletcolor=10,primary="missile",secondary="mines",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4"',
 mrs2t's=3,bulletcolor=10,primary="missile",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="7;9;4",exhausts="-1;3;0;3"',
 mrs2t's=4,bulletcolor=15,primary="missile",secondary="cloak",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="10;11;15",exhausts="-1;3;0;3"',
 mrs2t's=5,bulletcolor=14,primary="missile",secondary="blink",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;0;6;0",exhaustcolors="14;8;2",exhausts="-1;3;0;3"',
 mrs2t's=6,bulletcolor=15,primary="missile",secondary="flak",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;0;5;0",exhaustcolors="10;9;5",exhausts="-4;4;-3;4;-1;4;0;4;2;4;3;4"',
 mrs2t's=7,bulletcolor=12,primary="missile",secondary="beam",secondaryshots=3,psets="3;6;11;3;4;10",guns="2;1;5;1",exhaustcolors="12;12;13",exhausts="-3;4;-2;4;1;4;2;4"',
 
 [13]=mrs2t's=13,bulletcolor=11,primary="boost",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="2;2;5;2",exhaustcolors="7;6;13",exhausts="-3;4;-2;4;1;4;2;4"',
 [14]=mrs2t's=14,bulletcolor=3,primary="boost",secondary="boost",secondaryshots=3,psets="0;0;9;0;0;9",guns="1;0;6;0",exhaustcolors="11;12;5",exhausts="-2;3;-1;3;0;3;1;3"',
 [15]=mrs2t's=15,bulletcolor=9,primary="boost",secondary="mines",secondaryshots=3,psets="3;4;9;3;2;10",guns="1;0;6;0",exhaustcolors="11;3;4",exhausts="-4;4;-3;4;2;4;3;4"',
 [16]=mrs2t's=16,bulletcolor=15,primary="boost",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="0;4;7;4",exhaustcolors="10;15;5",exhausts="-3;3;-1;4;0;4;2;3"',
 [17]=mrs2t's=17,bulletcolor=11,primary="boost",secondary="cloak",secondaryshots=3,psets="3;6;5;3;3;6",guns="2;2;5;2",exhaustcolors="11;3;5",exhausts="-1;4;0;4"',
 [18]=mrs2t's=18,bulletcolor=12,primary="boost",secondary="blink",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="7;14;8",exhausts="-4;4;-3;3;-2;2;1;2;2;3;3;4"',
 [19]=mrs2t's=19,bulletcolor=11,primary="boost",secondary="flak",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="14;8;2",exhausts="-4;4;-3;4;-2;4;1;4;2;4;3;4"',
 [20]=mrs2t's=20,bulletcolor=11,primary="boost",secondary="beam",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;6;2",exhaustcolors="11;11;5",exhausts="-3;4;-2;4;1;4;2;4"',
 
 [26]=mrs2t's=26,bulletcolor=14,primary="mines",secondary="missile",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="10;9;4",exhausts="-3;4;-2;4;1;4;2;4"',
 [27]=mrs2t's=27,bulletcolor=5,primary="mines",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4"',
 [28]=mrs2t's=28,bulletcolor=11,primary="mines",secondary="mines",secondaryshots=3,psets="3;4;1;3;3;12",guns="0;2;7;2",exhaustcolors="7;6;5",exhausts="-2;4;1;4"',
 [29]=mrs2t's=29,bulletcolor=15,primary="mines",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="10;14;13",exhausts="-1;3;0;3"',
 [30]=mrs2t's=30,bulletcolor=11,primary="mines",secondary="cloak",secondaryshots=3,psets="3;6;5;3;3;6",guns="2;2;5;2",exhaustcolors="10;11;5",exhausts="-1;4;0;4"',
 [31]=mrs2t's=31,bulletcolor=11,primary="mines",secondary="blink",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;2;3;2",exhaustcolors="10;11;5",exhausts="-3;4;-2;4;-1;4"',
 [32]=mrs2t's=32,bulletcolor=9,primary="mines",secondary="flak",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;0;6;0",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 [33]=mrs2t's=33,bulletcolor=14,primary="mines",secondary="beam",secondaryshots=3,psets="3;6;5;3;3;6",guns="1;0;6;0",exhaustcolors="7;7;13",exhausts="-1;3;0;3"',
 
 [39]=mrs2t's=39,bulletcolor=5,primary="shield",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 [40]=mrs2t's=40,bulletcolor=12,primary="shield",secondary="boost",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="11;12;13",exhausts="-3;4;-1;4;0;4;2;4"',
 [41]=mrs2t's=41,bulletcolor=9,primary="shield",secondary="mines",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 [42]=mrs2t's=42,bulletcolor=10,primary="shield",secondary="shield",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;10;5",exhausts="-1;4;0;4"',
 [43]=mrs2t's=43,bulletcolor=8,primary="shield",secondary="cloak",secondaryshots=3,psets="0;1;13;0;1;13",guns="2;0;5;0",exhaustcolors="14;8;2",exhausts="-2;4;1;4"',
 [44]=mrs2t's=44,bulletcolor=10,primary="shield",secondary="blink",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;2;6;2",exhaustcolors="10;11;15",exhausts="-1;3;0;3"',
 [45]=mrs2t's=45,bulletcolor=9,primary="shield",secondary="flak",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="10;14;8",exhausts="-1;4;0;4"',
 [46]=mrs2t's=46,bulletcolor=6,primary="shield",secondary="beam",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;1;6;1",exhaustcolors="10;14;15",exhausts="-1;4;0;4"',
 
 [52]=mrs2t's=52,bulletcolor=14,primary="cloak",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-2;4;1;4"',
 [53]=mrs2t's=53,bulletcolor=15,primary="cloak",secondary="boost",secondaryshots=3,psets="3;6;11;3;4;10",guns="0;4;7;4",exhaustcolors="8;2;4",exhausts="-3;3;2;3"',
 [54]=mrs2t's=54,bulletcolor=5,primary="cloak",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 [55]=mrs2t's=55,bulletcolor=4,primary="cloak",secondary="shield",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;0;6;0",exhaustcolors="7;9;5",exhausts="-1;2;0;2"',
 [56]=mrs2t's=56,bulletcolor=7,primary="cloak",secondary="cloak",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;1;6;1",exhaustcolors="9;8;2",exhausts="-1;3;0;3"',
 [57]=mrs2t's=57,bulletcolor=7,primary="cloak",secondary="blink",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;1;5;1",exhaustcolors="12;3;15"',
 [58]=mrs2t's=58,bulletcolor=7,primary="cloak",secondary="flak",secondaryshots=3,psets="3;6;3;3;4;11",guns="2;0;5;0",exhaustcolors="14;2;5",exhausts="-2;4;1;4"',
 [59]=mrs2t's=59,bulletcolor=14,primary="cloak",secondary="beam",secondaryshots=3,psets="3;6;3;3;4;11",guns="1;0;6;0",exhaustcolors="10;11;3",exhausts="-3;4;2;4"',
 
 [65]=mrs2t's=65,bulletcolor=10,primary="blink",secondary="missile",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;10;4",exhausts="-1;4;0;4"',
 [66]=mrs2t's=66,bulletcolor=9,primary="blink",secondary="boost",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="7;6;13",exhausts="-3;4;-1;4;0;4;2;4"',
 [67]=mrs2t's=67,bulletcolor=11,primary="blink",secondary="mines",secondaryshots=3,psets="3;5;2;3;3;8",guns="2;1;5;1",exhaustcolors="7;10;15",exhausts="-1;4;0;4"',
 [68]=mrs2t's=68,bulletcolor=14,primary="blink",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;9;15",exhausts="-3;4;-2;4;1;4;2;4"',
 [69]=mrs2t's=69,bulletcolor=9,primary="blink",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;2;5;2",exhaustcolors="7;8;2",exhausts="-2;4;1;4"',
 [70]=mrs2t's=70,bulletcolor=6,primary="blink",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;2;7;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 [71]=mrs2t's=71,bulletcolor=2,primary="blink",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="10;11;5",exhausts="-3;3;-2;4;1;4;2;3"',
 [72]=mrs2t's=72,bulletcolor=10,primary="blink",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="7;14;15",exhausts="-3;4;-1;4;0;4;2;4"',

 [78]=mrs2t's=78,bulletcolor=6,primary="flak",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;2;5;2",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 [79]=mrs2t's=79,bulletcolor=8,primary="flak",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;2;6;2",exhaustcolors="7;15;5",exhausts="-4;3;-3;3;-1;4;0;4;2;3;3;3"',
 [80]=mrs2t's=80,bulletcolor=2,primary="flak",secondary="mines",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="10;9;14",exhausts="-1;4;0;4"',
 [81]=mrs2t's=81,bulletcolor=15,primary="flak",secondary="shield",secondaryshots=3,psets="3;6;11;3;4;10",guns="1;1;6;1",exhaustcolors="7;11;3",exhausts="-1;4;0;4"',
 [82]=mrs2t's=82,bulletcolor=6,primary="flak",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="7;10;11",exhausts="-3;3;2;3"',
 [83]=mrs2t's=83,bulletcolor=12,primary="flak",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;6;15",exhausts="-3;3;2;3"',
 [84]=mrs2t's=84,bulletcolor=9,primary="flak",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 [85]=mrs2t's=85,bulletcolor=14,primary="flak",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',

 [91]=mrs2t's=91,bulletcolor=11,primary="beam",secondary="missile",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;9;15",exhausts="-1;4;0;4"',
 [92]=mrs2t's=92,bulletcolor=3,primary="beam",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;14;15",exhausts="-4;3;-3;4;2;4;3;3"',
 [93]=mrs2t's=93,bulletcolor=6,primary="beam",secondary="mines",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;6;5",exhausts="-1;4;0;4"',
 [94]=mrs2t's=94,bulletcolor=6,primary="beam",secondary="shield",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;1;5;1",exhaustcolors="10;11;12",exhausts="-1;4;0;4"',
 [95]=mrs2t's=95,bulletcolor=11,primary="beam",secondary="cloak",secondaryshots=3,psets="3;5;12;3;3;11",guns="2;0;5;0",exhaustcolors="10;9;15",exhausts="-1;3;0;3"',
 [96]=mrs2t's=96,bulletcolor=12,primary="beam",secondary="blink",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;7;14",exhausts="-1;3;0;3"',
 [97]=mrs2t's=97,bulletcolor=8,primary="beam",secondary="flak",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="7;7;9",exhausts="-3;3;-2;3;1;3;2;3"',
 [98]=mrs2t's=98,bulletcolor=4,primary="beam",secondary="beam",secondaryshots=3,psets="3;5;12;3;3;11",guns="1;3;6;3",exhaustcolors="10;10;15",exhausts="-1;4;0;4"',
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
    sset(8*_ship.plidx+_x,120+_y,_col)
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
  x=_x,
  y=_y,
  r=8,
  spdx=(rnd()-0.5),
  spdy=rnd()-1.22,
  spdr=-0.28,
  colors=smokecolors,
  life=_life,
  lifec=_life,
 })
end

local function newexhaustp(_xoff,_yoff,_ship,_colors,_life)
 add(psfollow,{
  x=0,
  y=0,
  follow=_ship,
  xoff=_xoff,
  yoff=_yoff,
  r=0,
  spdx=0,
  spdy=0.1+rnd()-0.1,
  spdr=0,
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
 return _closest
end

local explosioncolors=split'7,7,10,9,8'
local function explode(_obj)
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
 sspr(19,124,1,4,_bullet.x,_bullet.y)
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
local function drawbeam(_ship)
 local _x,_y=_ship.x,_ship.y
 rectfill(_x-3,_y-8,_x+2,-4,8)
 rectfill(_x-2,_y-7,_x+1,-4,14)
 rectfill(_x-1,_y-6,_x,-4,7)
 add(ps,{
  x=_x,
  y=rnd(_y),
  r=0.9,
  spdx=rnd(dirs)*(rnd(0.25)+0.25),
  spdy=0,
  spdr=0,
  colors=beampcolors,
  life=10,
  lifec=10,
 })
end

local function drawmine(_bullet)
 _bullet.frame+=(t()*0.375)/_bullet.life
 if _bullet.frame > 2 then
  _bullet.frame=0
 end
 sspr(2*flr(_bullet.frame),108,2,2,_bullet.x,_bullet.y)
end
local function shootmine(_ship,_life,_angle)
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
 sspr(16,123,3,5,_bullet.x,_bullet.y)
end
local function shootmissile(_ship,_life)
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

local flakcolors={11,3,5}
local function drawflakbullet(_bullet)
 pset(_bullet.x,_bullet.y,flakcolors[flr((t()*12)%3)+1])
end
local function shootflak(_ship,_amount,_life)
 for _i=1,_amount do
  local _spdx,_spdy=2+rnd(2),rnd(0.5)-0.25
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

local blinkpcolors={7,11,11,3,5}
local function blinkaway(_ship,_dx,_dy,_h)
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

local function emptydraw()
end

local primary={
 missile=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 and _ship.primaryc > 1 then
   shootmissile(_ship,_ship.primaryc*2)
   _ship.primaryc=0
  end
 end,
 boost=function(_btn4,_ship)
  _ship.isboosting=_ship.primaryc > 0 and not _btn4
 end,
 mines=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 and _ship.primaryc > 1 then
   shootmine(_ship,_ship.primaryc*3.5+15,0.2+rnd(0.1))
   _ship.primaryc=0
  end
 end,
 shield=function(_btn4,_ship)
  _ship.isshielding=not _btn4 and _ship.primaryc > 0
  if not _btn4 then
   _ship.primaryc-=0.5
  end
 end,
 cloak=function(_btn4,_ship)
  _ship.iscloaking=not _btn4 and _ship.primaryc > 0
 end,
 blink=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 then
   local _dx,_dy=getdirs(_ship.plidx)
   blinkaway(_ship,_dx,_dy,_ship.primaryc*2)
   _ship.primaryc=0
  end
 end,
 flak=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 and _ship.primaryc > 1 then
   shootflak(_ship,max(2,flr(_ship.primaryc/4)),_ship.primaryc*3.5)
   _ship.primaryc=0
  end
 end,
 beam=function(_btn4,_ship)
  _ship.isbeaming=not _btn4 and _ship.primaryc > 0
  if _ship.isbeaming then
   _ship.primaryc-=0.25
   shootbeam(_ship)
  end
 end,
}

local secondary={
 missile=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootmissile(_ship,60)
   shootmissile(_ship,60)
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
   shootmine(_ship,_ship.primaryc*3+30,0.375)
   shootmine(_ship,_ship.primaryc*3+30,0.125)
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
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   _ship.secondaryshots-=1
   local _dx,_dy=getdirs(_ship.plidx)
   blinkaway(_ship,_dx,_dy,22+flr(rnd(42)))
  end
 end,
 flak=function(_ship)
  if btnp(5,_ship.plidx) and _ship.secondaryshots > 0 then
   shootflak(_ship,8,100)
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
 end
}

local weaponcolors=s2t'missile=15,boost=2,mines=5,shield=12,cloak=4,blink=3,flak=11,beam=8'

local boostcolors=split'7,10,9,8'

local secondarysprites={
 missile=split'16,123,3,5',
 boost=split'23,123,2,5',
 mines=split'2,105,2,5',
 shield=split'42,118,3,5',
 cloak=split'39,118,3,5',
 blink=split'21,118,2,5',
 flak=split'19,118,2,5',
 beam=split'19,113,3,5',
}

-- enemies

-- todo: meld with newexhaustp?
local function newbossexhaustp(_xoff,_yoff,_ship,_colors,_life)
 add(psfollow,{
  x=0,
  y=0,
  follow=_ship,
  xoff=_xoff,
  yoff=_yoff,
  r=0,
  spdx=0,
  spdy=-(0.1+rnd()-0.1),
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
 sspr(16,118,3,5,_bullet.x,_bullet.y)
end
local function enemyshootmissile(_enemy)
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
   colors={7,10,11},
   life=4,
  },
 })
end

local function drawenemymine(_bullet)
 _bullet.frame+=(t()*0.375)/_bullet.life
 if _bullet.frame > 2 then
  _bullet.frame=0
 end
 sspr(2*flr(_bullet.frame),110,2,2,_bullet.x,_bullet.y)
end
local function enemyshootmine(_enemy)
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

local bossweapons={
 missile=enemyshootmissile,
 mines=enemyshootmine,
 boost=function()
  boss.boostts=t()
  boss.boost=0.5
 end
}

local minelayerexhaustcolors={12}
local function newminelayer()
 add(enemies,{
  x=rnd(128),y=-12,
  hw=4,hh=4,
  spdx=0,spdy=0,
  s=178,
  hp=6,
  ts=t(),
  update=function(_enemy)
   local _x=flr(_enemy.x)
   local _y=flr(_enemy.y)
   newenemyexhaustp(_x-1,_y-3,minelayerexhaustcolors)
   newenemyexhaustp(_x,_y-3,minelayerexhaustcolors)
   if _enemy.target then
    if t()-_enemy.ts > _enemy.duration or ispointinsideaabb(_enemy.target.x,_enemy.target.y,_enemy.x,_enemy.y,_enemy.hw,_enemy.hh) then
     _enemy.target=nil
    end
   else
    _enemy.spdx=0
    _enemy.spdy=0
    if t()-_enemy.ts > 1.5 then
     enemyshootmine(_enemy)
     _enemy.ts=t()
     _enemy.duration=1+rnd(2)
     _enemy.target={x=4+rnd(120),y=rnd(92)}
     local _a=atan2(_enemy.target.x-_enemy.x,_enemy.target.y-_enemy.y)
     _enemy.spdx=cos(_a)*0.75
     _enemy.spdy=sin(_a)*0.75
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
  s=176,
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
  s=179,
  hp=11,
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

local lastframe,curt
function gameupdate()

 curt=t()
 if escapeelapsed then
  hasescaped=escapeelapsed > escapeduration
 end

 -- update ships
 for _ship in all(ships) do
  local _plidx=_ship.plidx
  local _newx,_newy=_ship.x,_ship.y

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
  
  _ship.x=mid(4,_newx,124)
  _ship.y=mid(4,_newy,119)

  local _urx,_ury=_ship.x-4,_ship.y-4

  -- repairing/firing
  _ship.isfiring=nil

  if _ship.secondaryc <= 0 then
   _ship.isshielding=nil
   _ship.iscloaking=nil
   _ship.isboosting=nil
   _ship.isbeaming=nil
  end

  if _ship.hp < 3 then
   newburning(_ship.x,_ship.y)
   _ship.primaryc=max(0,_ship.primaryc-0.0875)
   if btnp(4,_plidx) then
    _ship.primaryc+=2.5
    if _ship.primaryc >= 37 then
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
   newexhaustp(_ship.exhausts[_i],_ship.exhausts[_i+1],_ship,_ship.isboosting and boostcolors or _ship.exhaustcolors,_ship.isboosting and 8 or 4)
  end

  if _ship.hp == 0 then
   explode(_ship)
   del(ships,_ship)
  end

  if boss and isaabbscolliding(_ship,boss) and not _ship.iscloaking then
   if nickitts then
    ships[_plidx+1]=mr(getship(boss.s),{plidx=_plidx,x=_ship.x,y=_ship.y,hp=1})
    createshipflashes()
    nickedts=curt
    escapeelapsed=0
    nickitts=nil
    boss=nil
   else
    explode(_ship)
    explode(boss)
    boss=nil
    _ship.hp=0
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
   boss.hp-=_b.dmg
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
   end
   del(bullets,_b)
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
    newbossexhaustp(boss.exhausts[_i],-(boss.exhausts[_i+1]+0.5),boss,boss.boostts and boostcolors or boss.exhaustcolors,boss.boostts and 8 or 4)
   end
  else
   for _i=1,#boss.exhausts,2 do
    newexhaustp(boss.exhausts[_i],boss.exhausts[_i+1],boss,boss.exhaustcolors,4)
   end
  end

  local _bossdt=curt-boss.ts
  if boss.hp <= 0 then
   newburning(boss.x,boss.y)
   if not nickitts then
    nickitts=curt
   end
  else
   if _bossdt > boss.flyduration then
    if _bossdt > boss.flyduration+boss.waitduration then
     bossweapons[rnd{boss.primary,boss.primary,boss.primary,boss.secondary}](boss)
     boss.waitduration=0.875+rnd(1.75)
     boss.flyduration=0.875+rnd(5)
     boss.ts=curt
    end
   else
    if boss.targetx == nil or ispointinsideaabb(boss.targetx,boss.targety,boss.x,boss.y,boss.hw,boss.hh) then
     boss.targetx=4+rnd(120)
     boss.targety=8+rnd(36)
    end

    if boss.boostts and t()-boss.boostts > 2.25 then
     boss.boost=0
     boss.boostts=nil
    end

    local _absx=abs(boss.targetx-boss.x)
    local _spd=0.5+boss.boost
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
  rnd{newkamikaze,newkamikaze,newbomber,newminelayer}()
 end

 for _enemy in all(enemies) do
  if _enemy.hp <= 0 then
   explode(_enemy)
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
     _enemy.spdy=0
     _enemy.spdx=0
     _enemy.y=-12
     _enemy.target=nil
    end
   end
   for _ship in all(ships) do
    if isaabbscolliding(_enemy,_ship) and not _ship.iscloaking then
     explode(_enemy)
     del(enemies,_enemy)
     _ship.hp-=1
     _ship.primaryc=0
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
   drawbeam(_ship)
  end
 end

 -- draw exit
 if exit then
  local _frame=flr((t()*12)%3)
  print('to secret hangar',32,3,10+_frame)
  sspr(24+_frame*5,118,5,5,18,3)
  sspr(24+_frame*5,118,5,5,104,3)
  end

 -- draw ships
 for _ship in all(ships) do
  local _urx,_ury=_ship.x-4,_ship.y-4
  spr(_ship.s,_urx,_ury)

  if _ship.isfiring then
   spr(240+_ship.plidx,_urx,_ury)
  end

  if _ship.isshielding then
   drawshield(_ship.x,_ship.y)
  end

  if _ship.iscloaking then
   drawcloak(_ship.x,_ship.y)
  end
 end

 -- draw boss
 if boss then
  local _urx,_ury=flr(boss.x)-4,flr(boss.y)-4
  if boss.hp > 0 then
   spr(boss.s,_urx,_ury,1,1,false,true)
   for _pset in all(boss.psets) do
    pset(_urx+_pset[1],_ury+_pset[2],_pset[3])
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
   sspr(45,123,38,5,_xoff,121)
   sspr(45,118,_ship.primaryc,5,_xoff,121)
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
   sspr(25,123,20,5,_xoff+41,121)
  else
   color(weaponcolors[_ship.secondary])
   rectfill(_xoff+41,121,_xoff+45,125)
   rectfill(_xoff+46,122,_xoff+46,124)
   pset(_xoff+47,123)
   sspr(20,125,3,3,_xoff+42,122)

   for _i=1,_ship.secondaryshots do
    local _sx,_sy,_sw,_sh=unpack(secondarysprites[_ship.secondary])
    sspr(_sx,_sy,_sw,_sh,_xoff+47+_i*(_sw+1),121)
   end
  end

 end

 if #ships == 0 then
  drawblinktext('bummer',8)
 end

 if t()-gamestartts < 1.5 then
  drawblinktext('nick phase!',10)
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

 -- print(#enemies,0,0,8)
 -- print(#ps,20,0,7)
 -- print(#bullets,40,0,9)
 -- print(#enemybullets,60,0,15)
 -- print(#bottomps,80,0,5)
 -- print(#psfollow,100,0,13)

end

function gameinit()
 gamestartts=t()
 gameoverts=nil
 nickitts=nil
 nickedts=nil
 escapeelapsed=nil
 madeitts=nil
 hasescaped=nil
 escapeduration=30
 exit=nil
 enemyts=t()
 ps={}
 psfollow={}
 bottomps={}
 bullets={}
 enemies={}
 enemybullets={}

 local _lockedcount=getlockedcount()
 lockedpercentage=169/_lockedcount

 stars={}
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
    picks[_i]-=13
   elseif btnp(3,_i) then
    picks[_i]+=13
   end
   picks[_i]=mid(0,picks[_i],168)

   if btnp(5,_i) and _i == 1 then
    picks[_i]=nil
   elseif btnp(4,_i) and unlocked[picks[_i]] then
    local _ship=mr(getship(picks[_i]),{plidx=_i,x=32+_i*64})
    ships[_i+1]=_ship

    local _pickcount=mycount(picks)
    if _pickcount > 0 and _pickcount == mycount(ships) then
     -- boss=mr(getship(getrandomlocked()),{ -- todo
     boss=mr(getship(rnd{2,13,14,15,26,27,28}),{
      x=64,y=0,
      hp=127,
      ts=0,
      flyduration=8,
      waitduration=2,
      boost=0,
     })

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
 for _x=0,12 do
  for _y=0,12 do
   if unlocked[_y*13+_x] then
    spr(_y*13+_x,6+_x*9,3+_y*9)
   else
    spr(224,6+_x*9,3+_y*9)
   end
  end
 end
 for _i=0,1 do
  local _pick=picks[_i]
  if _pick then
   local _x,_y=5+(_pick%13)*9,2+flr(_pick/13)*9
   rect(_x,_y,_x+9,_y+9,11+_i)
   local _s='?????'
   if unlocked[_pick] then
    local _ship=hangar[_pick]
    _s=_ship.primary..','.._ship.secondary
   end
   print(_s,1+_i*127-_i*#_s*4,122,11+_i)
  end
 end
end

function pickerinit()
 for _ship in all(ships or {}) do
  unlocked[_ship.s]=true
 end
 persistunlocked()
 ships={}
 _update60,_draw=pickerupdate,pickerdraw
end


_init=function ()
 loadunlocked()
 
 -- unlock to random ships if no ships are unlocked
 local _shipcount=0
 for _i=0,#unlocked do
  if unlocked[_i] then
   _shipcount+=1
  end
 end

 if _shipcount == 0 then
  debug('get two random unlocks')
  unlocked[getrandomlocked()]=true
  unlocked[getrandomlocked()]=true
 end

 -- for _i=0,169 do
 --  unlocked[_i]=false
 -- end
 
 unlocked[0]=true
 unlocked[1]=true
 unlocked[2]=true
 unlocked[85]=true
 -- unlocked[28]=false
 -- unlocked[2]=false
 -- unlocked[13]=true
 -- unlocked[14]=true
 -- unlocked[15]=true
 -- unlocked[26]=false
 -- unlocked[27]=false
 
 -- persistunlocked()
 -- loadunlocked()
 
 -- for _i=0,169 do
  -- debug(unlocked[_i])
  -- debug(dget(_i))
 -- end

 pickerinit()
end


__gfx__
00044000000dd000000dd000000cc000000550000900009000022000000220000000000000000000000000000000000000000000000880000009900007000070
00db3d00005dd500040ab04000dabd00004b3400090000900057e500005225000000000000000000000000000000000000000000000650000097690078000087
08d33d80005e2500046bb6400ddbbdd004d33d40690b3096005ee500005985000000000000000000000000000000000000000000008558000867668078000087
2dd33dd206522560d66bb66dddcbbcdd44d33d4469033096025ee5200668866000000000000000000000000000000000000000000825528082699628780a9087
28d44d826d5225d6d66dd66ddcdccdcd06d55d6069433496245225426ff88ff60000000000000000000000000000000000000000002882008289982878099087
8dd44dd86d5dd5d6004dd400cdccccdc6dd55dd696d66d6924422442f652256f0000000000000000000000000000000000000000082882809289982988599588
8d0550d866dddd660d6dd6d0dc0550cd6d0550d69946649922422422655225560000000000000000000000000000000000000000822882289289982968588586
82000028044004400d0550d0c000000c6600006609055090dd0dd0dd054004500000000000000000000000000000000000000000855005589000000966088066
000660000002200000033000000dd000000220000000000000000000000000000000000000000000000550000060060000d55d00000ff000000990000f0f0000
006dd6000007600000ba9b0000d76d00002a9200000000000000000000000000000000000000000000555500006996000dd55dd000fbcf0000da8d000f0f0000
06dabd60005665000b3993b00f6766f0029a992000000000000000000000000000000000000000000d59e5d000dbcd000dd11dd00f5cc5f000d88d004f4f40ab
0d4bb4d005266250b3b99b3bff6446ff2492294200000000000000000000000000000000000000000de9eed060dccd065d1c11d55d5cc5d50d6886d04ddd40bb
0d4bb4d052266225bdb33bdb00d44d002442244200000000000000000000000000000000000000004de44ed4694cc4965d1111d55d5dd5d56d6996d6ddddd544
d44dd44d52288225bd5335db0d5445d02242242200000000000000000000000000000000000000004d5445d4d949949d5dd11dd5fd5dd5df6dc99cd6d545d545
d46dd64d52288225b500005bd554455d055005500000000000000000000000000000000000000000dd5445ddd949949d0d5dd5d0fd0550dfcdc99cdcd454d045
006446005005500530000003d540045d0450054000000000000000000000000000000000000000000220022005500550005dd500f000000fc0c44c0c05550000
000dd0000200002000000000000000000000000000000000000000000009900000088000060660600c0000c00070070000077000000330000062260000000000
040ab040e200002e00000000000000000000000000000000000000000009900000888800600b30066c0000c607000070007d470000f33f000d6226d000000000
04dbbd40e20cd02e0000000000000000000000000000000000000000000bc000028a982060f33f066c0b30c67600006707c44c7000f7bf000d67c6d000000000
dd5bb5dde20dd02e0000000000000000000000000000000000000000006cc600229a9922f046640f6c0330c6760b3067c6c44c6c03b7bb30d6c7cc6d00000000
d55dd55de24dd42e0000000000000000000000000000000000000000006cc60028988982404664046c4334c676d33d67c6c77c6c3fb66bf326c22c6200000000
000dd000e242242e000000000000000000000000000000000000000070699607d828828d400ff004c6d66d6c76d77d6776c77c673f3663f32622226200000000
0d5dd5d022022022000000000000000000000000000000000000000079699697d828828d45466454cc4664cc07677670760cc067303663030d2222d000000000
0d5445d0e200002e00000000000000000000000000000000000000006969969605055050404664040c0550c000677600700000070004400000d55d0000000000
00000000000000000000000000000000000cc00000dffd000006600006000060000440000006600000f00f000400004000000000000000000000000000000000
000000000000000000000000000000000006500005dffd50000dd00062000026004af4006007f0060f0000f0500dd00500000000000000000000000000000000
0000000000000000000000000000000000d55d0055d66d5500078000620bc026041ff140644ff446fd0000dfd00e200d00000000000000000000000000000000
000000000000000000000000000000000d4554d0dd6766dd00688600625cc526415ff514600ff006fd07b0dfd442244d00000000000000000000000000000000
00000000000000000000000000000000d44cc44ddf6766fd06d88d60625225264514415460066006fd4bb4dfd002200d00000000000000000000000000000000
0000000000000000000000000000000000dccd00dff66ffd6dd44dd62202202241144114644664464d4ff4d45d4dd4d500000000000000000000000000000000
000000000000000000000000000000000dcddcd005fddf506dd44dd6f200002f410550146006600604dffd40550dd05500000000000000000000000000000000
00000000000000000000000000000000d4cddc4d00dddd006dd44dd60f0000f0400000046000000600fddf00dd0000dd00000000000000000000000000000000
00000000000bb00000088000000ff000000ff0000006600000edde000040040000d00d0000000000000000000000000000000000000000000003300005000050
000000000607e06000276200000ff00000fbcf00000660000edddde00f4004f000d33d0000000000000000000000000000000000000000000003300005076050
00000000063ee36002266220006ab6000ffccff0000a50005edaade5ffdffdff00da9d000000000000000000000000000000000000000000000a5000df0660df
00000000b33ee33b02066020006bb60006fccf6000d55d00dea7aaedfdda9ddf00d99d00000000000000000000000000000000000000000000f55f00fd4fd4dd
00000000b33bb33b00088000096bb690f6f66f6f00f55f00dea7aaedfd9a99df0bd99db0000000000000000000000000000000000000000000f55f00dd4dd4fd
00000000000bb000080880809f6ff6f96f6ff6f60f6ff6f0deeaaeedfd9ff9dfbbd33dbb000000000000000000000000000000000000000060f33f06fd0df0df
000000000b3bb3b0884884889f6ff6f9f66ff66f66f66f660dedded00fdffdf003d33d30000000000000000000000000000000000000000063f33f36550dd055
000000000b3553b08505505890d55d0905500550f6d66d6f005dd500005ff500330330330000000000000000000000000000000000000000f3f33f3f00055000
00033000030000300005500000088000000ff00000077000000000000000000000000000000000000000000003000030000ee00004000040000ff000004dd400
000a9000c300003c000550000006d0000d0ab0d00076c70000000000000000000000000000000000000000000b3003b000eb3e0042000024009ff9000d4994d0
00599500cd0000dc000e2000000dd0000d4bb4d00bc6ccb0000000000000000000000000000000000000000000be2b000023320042000024009ab9000d9a99d0
04599540cd0a90dc00f22f00008dd800454bb454b3c77c3b0000000000000000000000000000000000000000000220000e2332e0420980240fbabbf00d9a99d0
54533545dd0990dd00f22f000e8dd8e0545ff545b3b77b3b00000000000000000000000000000000000000000b3223b0e224422e42088024f9b99b9f0d9999d0
005335003d5995d3d0f55f0d2e8ee8e2000ff00073b77b370000000000000000000000000000000000000000b33bb33b04d22d4022188122ff9999ff5d5995d5
04355340dc5cc5cdd5f55f5d2e8ee8e2045ff54073b77b370000000000000000000000000000000000000000b30bb03b5d0440d52412214200f44f005d5dd5d5
54355345dc0cc0cdf5f55f5f005ee500054dd450700440070000000000000000000000000000000000000000b004400b05000050440220440005500050500505
00022000000dd0000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002b320000dabd000007e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
028338200fbabbf0200ee00200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282332820fbabbf02f0ee0f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
828228280fbddbf02f2882f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282222824fd44df40f2882f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
82055028455445540f2882f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80000008400000040025520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000007777777700000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d77dd77dd0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d7dd77ddd0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d7d7d7d7d0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000d77d77ddd0000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007777777700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007777777700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007777777700000000000000000000000000000000000000000000000000000000
d000000d000550000005500005500550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d405504d4dd44dd40d0dd0d0444dd444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d44dd44d4dd44dd44d4dd4d4d44dd44d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d44dd44d4dd44dd4dd4dd4ddd4bddb4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d44a944d40d7ed044d0bc0d404babb40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d4994d0000ee0004d0cc0d404dabd40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d99d00000ee0000d0000d000dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000440000d0000d0000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
85580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c55c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5cc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000000000008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100110000000000008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110000000000008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011100000000000008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000000004d4b107000a0000b0000c000000003333333333333bbb3bbb3bbb3bbb3bbb3bbb33000000000000000000000000000000000000000000000
00000000000000000d0110b00aaa00bbb00ccc01410c033bbb33333333b3b3b333b3b3b3b33b33b3b33000000000000000000000000000000000000000000000
77777777777777770d01a00eaaaaabbbbbccccc414c1c33b3b33333333bb33bb33bbb3bbb33b33bb333000000000000000000000000000000000000000000000
77777777777777770d011b0700a0000b0000c00141c1c33bbb33333333b3b3b333b333b3b33b33b3b33000000000000000000000000000000000000000000000
77777777777777770d0b170700a0000b0000c004140c03333333333333b3b3bbb3b333b3b3bbb3b3b33000000000000000000000000000000000000000000000
77777777777777770600000002222200002200222002222222222222228882888288828882888288822000000000000000000000000000000000000000000000
77777777777777770607000aa2000020002020222020020888000000008080800080808080080080802000000000000000000000000000000000000000000000
777777777777777706077079a2000002002020202020020808000000008800880088808880080088002000000000000000000000000000000000000000000000
77777777777777770607070892000020002020202020220888000000008080800080008080080080802000000000000000000000000000000000000000000000
7777777777777777d6da707082222200002220202022222222222222228282888282228282888282822000000000000000000000000000000000000000000000
