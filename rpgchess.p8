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
 return _b.y < _a.y
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
 [3*cols+3]=16,
 [4*cols+3]=16,
 -- [4*cols+4]=16,
 -- [5*cols+4]=16,
 -- [6*cols+4]=16,
 -- [7*cols+4]=16,
 [7*cols+5]=16,
 -- [8*cols+4]=16,
 -- [8*cols+5]=16,
 -- [9*cols+5]=16,
 -- [9*cols+4]=16,
 -- [10*cols+5]=16,
 -- [11*cols+5]=16,
 }
local creatures
local summoners
local isvictory

local function getcreatureonpos(_x,_y)
 for _c in all(creatures) do
  if _c.x == _x and _c.y == _y then
   return _c
  end
 end
 -- return nil
end

local function copydeltas(_t)
 local _r=clone(_t)
 for _k,_v in pairs(_r) do
  _r[_k]=clone(_v)
 end
 return _r
end

attackdeltas={
 spearman={
  {x=1,y=0,w=1},
  {x=1,y=-1,w=1},
  {x=1,y=1,w=1},
  {x=0,y=-1,w=1},
  {x=0,y=1,w=1},
 }
}

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
 {walkdir=1,x=1,y=5,typ=0,hp=3},
 {walkdir=-1,x=14,y=3,typ=0,hp=3},
}

creatures={
 {summoner=1,walkdir=1,x=1,y=6,typ=0,hp=2,active=true,movedeltas='spearman',attackdeltas='spearman'},
 {summoner=1,walkdir=1,x=0,y=6,typ=0,hp=2,active=true,movedeltas='spearman',attackdeltas='spearman'},
 {summoner=2,walkdir=-1,x=15,y=7,typ=0,hp=2,active=false,movedeltas='spearman',attackdeltas='spearman'},
}

for _c in all(creatures) do
 _c.movedeltas=movedeltas[_c.movedeltas]
 _c.attackdeltas=attackdeltas[_c.attackdeltas]
end


local tick=0
local tickwrap=56

local animtick=0
local animlen=12

function _update60()
 if animtick > 0 then
  animtick-=1

 elseif summoners[1].hp <= 0 or summoners[2].hp <= 0 then

  if summoners[1].hp <= 0 then
   isvictory=true
  else
   isvictory=false
  end

 else

  tick+=1

  if tick >= tickwrap then

   -- todo: sort on x first, friendly creatures with x closer to enemy summoner moves first

   -- update creatures
   for _c in all(creatures) do

    _c.anim=nil

    if _c.active then

     local _enemysummoner=summoners[(_c.summoner%2)+1]

     local _attacks=copydeltas(_c.attackdeltas)

     for _a in all(_attacks) do
      local _ax,_ay=_c.x+_a.x*_c.walkdir,_c.y+_a.y
      local _other=getcreatureonpos(_ax,_ay)
      if _other == nil or
         _other.summoner == _c.summoner then
       if not (_ax == _enemysummoner.x and _ay == _enemysummoner.y) then 
        del(_attacks,_a)
       end
      end
     end

     if #_attacks > 0 then

      _c.anim='attacking'

      _c.lastmovx=nil

      _c.attx=_c.x+_attacks[1].x*_c.walkdir
      _c.atty=_c.y+_attacks[1].y

      local _other=getcreatureonpos(_c.attx,_c.atty)
      if _other then
       _other.hp-=1
       if _other.hp <= 0 then
        del(creatures,_other)
       end
      elseif _c.attx == _enemysummoner.x and _c.atty == _enemysummoner.y then
       _enemysummoner.hp-=1
      end

     else -- move

      _c.anim='moving'

      local _moves

      if _c.x == _enemysummoner.x then
       local _dy=sgn(_enemysummoner.y-_c.y)
       _moves={
        {x=0,y=_dy,w=3},
        {x=-_c.walkdir,y=_dy,w=1},
       }
      else
       _moves=copydeltas(_c.movedeltas)
      end

      for _m in all(_moves) do
       local _nextx,_nexty=_c.x+_m.x*_c.walkdir,_c.y+_m.y

       -- is outside board long-side edges
       -- todo: always go towards center row
       if _nexty < 0 or
          _nexty >= rows or
          board[_nexty*cols+_nextx] or
          getcreatureonpos(_nextx,_nexty) then
        del(_moves,_m)
       elseif _nextx == _c.lastmovx and _nexty == _c.lastmovy then
        _m.w-=0.5
       end
      end

      sort(_moves,sortonw)

      _c.lastmovx,_c.lastmovy=_c.x,_c.y
      if #_moves > 0 then
       _c.x+=_moves[1].x*_c.walkdir
       _c.y+=_moves[1].y
      end

     end
    end

    _c.active=not _c.active
   end

   -- next turn
   tick=0
   animtick=animlen
  end
 end
end

function _draw()
 palt(0,false)
 palt(11,true)
 cls(3)

 local _yoff=16

 -- draw board props
 for _i=0,arlsen do
  _p=board[_i]
  if _p then
   local _x,_y=_i%cols,_i\cols
   spr(_p,_x*8,_yoff+_y*8)
  end
 end

 -- draw summoners
 for _s in all(summoners) do
  spr(_s.typ,_s.x*8,_yoff+_s.y*8)
 end
 
 -- draw creatures
 sort(creatures,sortony)
 for _c in all(creatures) do
  local _foff=0
  local _animxoff=0
  local _animyoff=0
  if _c.active then
   _foff=flr(tick/(tickwrap/5))%2
  end
  if _c.anim and animtick > 0 then
   local _p=animtick/animlen
   if _c.anim == 'moving' then
    _animxoff=(_c.lastmovx-_c.x)*_p^2*8
    _animyoff=(-_p^2+_p)*-10+(_c.lastmovy-_c.y)*_p^2*8
   elseif _c.anim == 'attacking' then
    _animxoff=(_c.attx-_c.x)*_p^3*5
    _animyoff=(_c.atty-_c.y)*_p^3*5
   end
  end
  spr(_c.typ+_foff,_animxoff+_c.x*8,_yoff+_animyoff+_c.y*8,1,1,_c.walkdir == -1)
 end

 -- draw effects

 -- draw isvictory
 if isvictory != nil then
  print('victory!',64,64,7)
 end

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
