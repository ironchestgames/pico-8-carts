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
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
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
 [cols-1]=16,
 [cols]=16,
 [arlsen]=16,
 -- [3*cols+3]=16,
 -- [4*cols+3]=16,
 -- [4*cols+4]=16,
 -- [5*cols+4]=16,
 -- [6*cols+4]=16,
 -- [7*cols+4]=16,
 -- [8*cols+5]=16,
 }
local creatures

local function getcreatureonpos(_x,_y)
 for _c in all(creatures) do
  if _c.x == _x and _c.y == _y then
   return _c
  end
 end
end


movedeltasspearman={
 {x=1,y=0,w=3},
 {x=1,y=-1,w=2},
 {x=1,y=1,w=2},
 {x=0,y=-1,w=1},
 {x=0,y=1,w=1},
 }

creatures={
 {walkdir=1,x=0,y=5,typ=0,state='moving',active=true,movedeltas=movedeltasspearman},
 -- {walkdir=-1,x=15,y=5,typ=0,state='moving',active=false,update=spearman},
}


local tick=0
local tickwrap=10

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

    -- todo: attack

    -- move
    local _moves=clone(_c.movedeltas)

    for _m in all(_moves) do
     local _nextx,_nexty=_c.x+_m.x,_c.y+_m.y

     -- is outside board long-side edges
     if _nexty < 0 or _nexty > rows then
      del(_moves,_m)
     elseif board[_nexty*cols+_nextx] then
      del(_moves,_m)
     -- todo: can not step onto friendly creatures
     -- todo: if in same col as enemy summoner, move towards
     elseif _nextx == _c.lastx and _nexty == _c.lasty then
      _m.w-=0.5
     end
    end

    sort(_moves,sortonw)

    -- todo: always go towards center row

    if #_moves > 0 then
     _c.lastx,_c.lasty=_c.x,_c.y
     _c.x+=_moves[1].x
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
 
 -- draw summoners/creatures
 for _c in all(creatures) do
  spr(_c.typ,_c.x*8,_offy+_c.y*8)
 end

 -- draw effects

 -- draw gui
 rectfill(0,119,127,127,0)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
