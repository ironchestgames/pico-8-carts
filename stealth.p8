pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

function shuffle(_l)
 for _i=#_l,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end

lvlmap={
 {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,},
 {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,},
 {0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,},
}

light={
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
}

players={
 {x=15,y=19,},
 -- {x=10,y=19,},
}

-- guard states:
-- 0 - standing
-- 1 - walking
-- 2 - turning
guard={
 x=24,y=5,
 dx=1,dy=0,
 state=1,
}

t=30

function iswallclose(_x,_y,_dx,_dy)
 local _c=0
 while _y >= 1 and _y <= 32 and _x >= 1 and _x <= 32 and lvlmap[_y][_x] != 2 do
  _x+=_dx
  _y+=_dy
  _c+=1
 end
 return _c <= 3
end

function _update()
 t-=1

 for i=1,#players do
  local p=players[i]
  local nextx,nexty=p.x,p.y
  if btnp(0,i-1) then
   nextx-=1
  elseif btnp(1,i-1) then
   nextx+=1
  elseif btnp(2,i-1) then
   nexty-=1
  elseif btnp(3,i-1) then
   nexty+=1
  end
  if nextx > 32 or nextx < 1 or nexty > 32 or nexty < 1 then
   -- todo: leave premises
   debug('player left premises',i)
  else
   local tile=lvlmap[nexty][nextx]
   if tile == 0 or tile == 1 then
    p.x,p.y=nextx,nexty
   end
  end
 end

 if t <= 0 then

  -- handle state
  if guard.state == 0 then
   -- set to walking
   guard.state=1

  elseif guard.state == 1 then
   -- move guard
   guard.x+=guard.dx
   guard.y+=guard.dy

  elseif guard.state == 2 then
   -- turn and set to standing
   local _turns=shuffle{
    {dx=guard.dy,dy=guard.dx},
    {dx=-guard.dy,dy=-guard.dx},
   }
   add(_turns,{dx=-guard.dx,dy=-guard.dy})
   for _t in all(_turns) do
    if not iswallclose(guard.x,guard.y,_t.dx,_t.dy) then
     guard.dx=_t.dx
     guard.dy=_t.dy
     break
    end
   end
   guard.state=1
  end

  -- set up next state
  if iswallclose(guard.x,guard.y,guard.dx,guard.dy) then
   guard.state=2
  end

  t=10
 end

end

function _draw()
 cls(0)

 -- clear light
 for y=1,32 do
  for x=1,32 do
   light[y][x]=0
  end
 end

 -- shine guard flashlight
 local _x,_y=guard.x+guard.dx,guard.y+guard.dy
 local _beams={{x=_x,y=_y}}

 if guard.dx != 0 then
  local _bx=_x+guard.dx
  local _by=_y+1
  while lvlmap[_by][_bx] != 2 do
   add(_beams,{x=_bx,y=_by})
   _bx+=guard.dx
   _by+=1
  end
  _bx=_x+guard.dx
  _by=_y-1
  while lvlmap[_by][_bx] != 2 do
   add(_beams,{x=_bx,y=_by})
   _bx+=guard.dx
   _by-=1
  end
 elseif guard.dy != 0 then
  local _bx=_x+1
  local _by=_y+guard.dy
  while lvlmap[_by][_bx] != 2 do
   add(_beams,{x=_bx,y=_by})
   _bx+=1
   _by+=guard.dy
  end
  _bx=_x-1
  _by=_y+guard.dy
  while lvlmap[_by][_bx] != 2 do
   add(_beams,{x=_bx,y=_by})
   _bx-=1
   _by+=guard.dy
  end
 end

 for _b in all(_beams) do
  local _bx,_by=_b.x,_b.y
  while lvlmap[_by][_bx] != 2 and _bx <= 32 and _bx >= 1 and _by <= 32 and _by >= 1 do
   light[_by][_bx]=1
   _bx+=guard.dx
   _by+=guard.dy
  end
 end
 -- while lvlmap[_y][_x] != 2 do
 --  light[_y][_x]=1
 --  for _b in all(_beams) do
 --   light[_b.y][_b.x]=1
 --  end
 --  _x,_y=_x+guard.dx,_y+guard.dy
 -- end

 -- light up walls
 for y=1,31 do
  for x=1,31 do
   if light[y+1][x] == 1 and lvlmap[y][x] == 2 and lvlmap[y+1][x] != 2 then
    light[y][x]=1
   end
  end
 end

 -- draw floors
 for y=1,32 do
  for x=1,32 do
   local tile=lvlmap[y][x]
   local l=light[y][x]*4
   local sx,sy=x*4-4,y*4-4
   if tile == 0 then
    sspr(8,0+l,4,4,sx,sy)
   elseif tile == 1 then
    sspr(12,0+l,4,4,sx,sy)
   elseif tile == 2 then
    sspr(16,0+l,4,4,sx,sy)
   end
  end
 end

 -- draw walls
 for y=1,32 do
  for x=1,32 do
   local tile=lvlmap[y][x]
   local l=light[y][x]*5
   local sx,sy=x*4-4,y*4-4
   if tile == 2 then
    if y < 32 then
     if lvlmap[y+1][x] == 0 then
      palt(0,false)
      sspr(4,0+l,4,5,sx,sy)
      palt(0,true)
     elseif lvlmap[y+1][x] == 1 then
      sspr(0,0+l,4,5,sx,sy)
     end
    end
   end
  end
 end

 -- draw players
 for i=1,#players do
  local p=players[i]
  rectfill(p.x*4-4,p.y*4-4-4,p.x*4-4+3,p.y*4-4+3,0)
 end

 -- draw guards
 rectfill(guard.x*4-4,guard.y*4-4-4,guard.x*4-4+3,guard.y*4-4+3,4)

 -- print('cpu: '..stat(2),0,0,11) -- note: cpu usage
end


function _init()
 t=30
end


__gfx__
dddd2220000011112222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd0000000011112222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd0222000011112222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd0000000011112222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd22021111dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666644451111dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666655551111dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666654441111dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66665555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66664454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000