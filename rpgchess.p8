pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

--[[


--]]

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

function clone(_t)
 local _r={}
 for _k,_v in pairs(_t) do
  _r[_k]=_v
 end
 return _r
end

function sort(_t,_f)
 for _i=1,#_t do
  local _j=_i
  while _j > 1 and _f(_t[_j-1],_t[_j]) do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

local function sortony(_a,_b)
 return _b.y > _a.y
end

local function sortonxasc(_a,_b)
 return _b.x > _a.x
end

local function sortonxdesc(_a,_b)
 return _b.x < _a.x
end

local function sortonw(_a,_b)
 return _b.w > _a.w
end


local rows=11
local cols=16
local arlsen=rows*cols-1 -- 11 rows, 14 cols
local board={
 [0]=16,
 [cols-1]=16,
 [cols]=16,
 [arlsen]=16,
 -- [3*cols+3]=16,
 -- [4*cols+3]=16,
 -- [4*cols+4]=16,
 -- [5*cols+4]=16,
 -- [6*cols+4]=16,
 -- [7*cols+4]=16,
 -- [7*cols+5]=16,
 -- [8*cols+4]=16,
 -- [8*cols+5]=16,
 -- [9*cols+5]=16,
 -- [9*cols+4]=16,
 -- [10*cols+5]=16,
 -- [11*cols+5]=16,
 }
local creatures
local summoners

local function getcreatureonpos(_x,_y)
 for _c in all(creatures) do
  if _c.x == _x and _c.y == _y then
   return _c
  end
 end
 -- return nil
end

local function copymoves(_t)
 local _r=clone(_t)
 for _k,_v in pairs(_r) do
  _r[_k]=clone(_v)
 end
 return _r
end


movedeltas={
 spearman={
  {x=1,y=0,w=3},
  {x=1,y=-1,w=2},
  {x=1,y=1,w=2},
  {x=0,y=-1,w=1},
  {x=0,y=1,w=1},
 },
}

summoners={
 {walkdir=1,x=1,y=5,typ=0},
 {walkdir=-1,x=14,y=3,typ=0},
}

creatures={
 {summoner=1,walkdir=1,x=0,y=6,typ=0,active=true,movedeltas='spearman'},
 {summoner=2,walkdir=-1,x=15,y=8,typ=0,active=false,movedeltas='spearman'},
}

for _c in all(creatures) do
 _c.movedeltas=movedeltas[_c.movedeltas]
end


local tick=0
local tickwrap=30

function _update()
 tick+=1

 if tick >= tickwrap then

  -- is enemy in attack-squares?
   -- attack
  -- else move
   -- modify move-squares with:
    -- - board edges
    -- - board props
    -- - friendly creatures

  -- todo: sort on x first, friendly creatures with x closer to enemy summoner moves first

  -- update creatures
  for _c in all(creatures) do

   if _c.active then

    local _enemysummoner=summoners[(_c.summoner%2)+1]

    -- todo: attack

    -- move
    local _moves

    if _c.x == _enemysummoner.x then
     local _dy=sgn(_enemysummoner.y-_c.y)
     _moves={
      {x=0,y=_dy,w=3},
      {x=-_c.walkdir,y=_dy,w=1},
     }
    else
     _moves=copymoves(_c.movedeltas)
    end

    for _m in all(_moves) do
     local _nextx,_nexty=_c.x+_m.x*_c.walkdir,_c.y+_m.y

     -- is outside board long-side edges
     if _nexty < 0 or 
        _nexty >= rows or
        board[_nexty*cols+_nextx] or
        getcreatureonpos(_nextx,_nexty) then
      del(_moves,_m)
     elseif _nextx == _c.lastx and _nexty == _c.lasty then
      _m.w-=0.5
     end
    end

    sort(_moves,sortonw)

    -- todo: always go towards center row

    if #_moves > 0 then
     _c.lastx,_c.lasty=_c.x,_c.y
     _c.x+=_moves[1].x*_c.walkdir
     _c.y+=_moves[1].y
    end

   end

   _c.active=not _c.active
  end

  sort(creatures,sortony)

  -- next turn
  tick=0

 else -- animate
  -- pass
 end
end

function _draw()
 palt(0,false)
 palt(11,true)
 cls(3)

 local _offy=16

 -- draw board props
 for _i=0,arlsen do
  _p=board[_i]
  if _p then
   local _x,_y=_i%cols,_i\cols
   spr(_p,_x*8,_offy+_y*8)
  end
 end

 -- draw summoners
 for _s in all(summoners) do
  spr(_s.typ,_s.x*8,_offy+_s.y*8)
 end
 
 -- draw creatures
 for _c in all(creatures) do
  local _foffset=0
  if _c.active then
   _foffset=flr(tick/(tickwrap/5))%2
  end
  spr(_c.typ+_foffset,_c.x*8,_offy+_c.y*8,1,1,_c.walkdir == -1)
 end

 -- draw effects

 -- draw gui
 rectfill(0,119,127,127,0)
end

__gfx__
b0000b0bbbbbbb0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ffff060b00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f00600ffff0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ffff0400f0f00400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000400ffff0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddd040000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000400dddd0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbb040000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
