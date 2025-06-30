pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function dist(_x1,_y1,_x2,_y2)
 local _dx,_dy=_x2-_x1,_y2-_y1
 return sqrt(_dx*_dx+_dy*_dy)
end

avatar={
 x=64,y=64,
 vx=0,vy=0,
 kills=0,
}

function spawnenemy()
 local _side=flr(rnd(4)+1)
 local _x,_y={128,rnd(128),0,rnd(128)},{rnd(128),128,rnd(128),0}
 return {
  x=_x[_side],y=_y[_side],
  vx=0,vy=0,
  walkspd=0.087+rnd(.125),
 }
end

function getclosestenemy()
 local _closest,_d=enemies[1],999
 for _e in all(enemies) do
  local _newd=dist(_e.x,_e.y,avatar.x,avatar.y)
  if _newd < _d then
   _closest,_d=_e,_newd
  end
 end
 return _closest
end

function angleto(_pos)
 return atan2(_pos.x-avatar.x,_pos.y-avatar.y)
end

enemies={}

for _i=1,4 do
 add(enemies,spawnenemy())
end

function _update60()

 if avatar.dead or #enemies == 0 then
  return
 end

 local _closestenemy=getclosestenemy()
 local _angletoclosestenemy=angleto(_closestenemy)
 
 -- update input
 if btn(5) then
  if avatar.spd == nil then
   avatar.spd=3
  end
  avatar.spd+=0.175
  avatar.btndown=true
  avatar.vx+=cos(_angletoclosestenemy+.25)*.087
  avatar.vy+=sin(_angletoclosestenemy+.25)*.087
 else
  if avatar.btndown then
   avatar.spd=min(avatar.spd,24)
   avatar.vx+=cos(_angletoclosestenemy)*avatar.spd
   avatar.vy+=sin(_angletoclosestenemy)*avatar.spd
   avatar.spd,avatar.btndown=0
  end
 end

 -- update avatar
 avatar.vx*=0.825
 avatar.vy*=0.825

 if abs(avatar.vx) < 0.01 then
  avatar.vx=0
 end
 if abs(avatar.vy) < 0.01 then
  avatar.vy=0
 end

 avatar.x+=avatar.vx
 avatar.y+=avatar.vy

 avatar.x=mid(0,avatar.x,128)
 avatar.y=mid(0,avatar.y,128)

 -- update enemy hits
 for _e in all(enemies) do
  if dist(_e.x,_e.y,avatar.x,avatar.y) < 6 then
   if dist(avatar.vx,avatar.vy,0,0) > 1 then
    del(enemies,_e)
    avatar.kills+=1
   else
    debug(avatar.spd)
    avatar.dead=true
   end
  end
 end

 -- update enemies
 for _e in all(enemies) do
  local _a=atan2(avatar.x-_e.x,avatar.y-_e.y)
  _e.x+=cos(_a)*_e.walkspd
  _e.y+=sin(_a)*_e.walkspd
 end

 if #enemies < 4 then
  add(enemies,spawnenemy())
 end

end

function _draw()
 if #enemies == 0 then
  return
 end

 cls()

 local _closestenemy=getclosestenemy()
 local _angletoclosestenemy=angleto(_closestenemy)

 -- draw enemies
 for _e in all(enemies) do
  circfill(_e.x,_e.y,3,8)
  if _e == _closestenemy then
   circfill(_e.x,_e.y,3,14)
  end
 end

 -- draw avatar
 circfill(avatar.x,avatar.y,3,12)
 line(
  avatar.x,
  avatar.y,
  avatar.x+cos(_angletoclosestenemy)*6,
  avatar.y+sin(_angletoclosestenemy)*6,
  7)

 print(avatar.kills,1,1,2)

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
