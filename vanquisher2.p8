pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- virtuous vanquisher of evil 2.0-alpha
-- by ironchest games

cartdata'ironchestgames_vvoe2_v1_dev1'

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

btnmasktoa=split'0.5,0,,0.25,0.375,0.125,,0.75,0.625,0.875'
confusedbtnmasktoa=split'0,0.5,,0.75,0.875,0.625,,0.25,0.125,0.375'

function flrrnd(_n)
 return flr(rnd(_n))
end

function norm(n)
 return n == 0 and 0 or sgn(n)
end

-- collision funcs

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

isinsidewall_wallabb={hw=4,hh=4}
function isinsidewall(aabb)
 local x1,y1,x2,y2=
  aabb.x-aabb.hw,aabb.y-aabb.hh,
  aabb.x+aabb.hw,aabb.y+aabb.hh

 for p in all{{x1,y1},{x2,y1},{x2,y2},{x1,y2}} do
  local mapx,mapy=flr(p[1]/8),flr(p[2]/8)
  isinsidewall_wallabb.x,isinsidewall_wallabb.y=mapx*8+isinsidewall_wallabb.hw,mapy*8+isinsidewall_wallabb.hh

  -- note: hitboxes should not be larger than 8x8
  if not walls[mapy] or not walls[mapy][mapx] then
   -- aabb.removeme=true
   debug('inside wall')
  elseif walls[mapy][mapx] == 1 and isaabbscolliding(aabb,isinsidewall_wallabb) then
   return isinsidewall_wallabb
  end
 end
end

collideaabbs_aabb={}
function collideaabbs(_func,_aabb,_other,_dx,_dy)
 local _sgndx,_sgndy=sgn(_dx),sgn(_dy)
 collideaabbs_aabb.x,
 collideaabbs_aabb.y,
 collideaabbs_aabb.hw,
 collideaabbs_aabb.hh=
  _aabb.x+_dx,
  _aabb.y,
  _aabb.hw,
  _aabb.hh

 local _collidedwith=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dx=(_aabb.hw+_collidedwith.hw-abs(_aabb.x-_collidedwith.x))*-_sgndx
 end

 collideaabbs_aabb.x,collideaabbs_aabb.y=_aabb.x,_aabb.y+_dy
 _collidedwith=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dy=(_aabb.hh+_collidedwith.hh-abs(_aabb.y-_collidedwith.y))*-_sgndy
 end

 return _dx,_dy
end

function dist(x1,y1,x2,y2)
 local dx,dy=x2-x1,y2-y1
 return sqrt(dx*dx+dy*dy)
end

function haslos(_x1,_y1,_x2,_y2)
 local dx,dy,x,y,xinc,yinc=
  abs(_x2-_x1),abs(_y2-_y1),_x1,_y1,sgn(_x2-_x1),sgn(_y2-_y1)
 local n,err=1+dx+dy,dx-dy
 dx*=2
 dy*=2

 while n > 0 do
  n-=1
  if walls[flr(y/8)][flr(x/8)] == 1 then
   return
  end
  if err > 0 then
   x+=xinc
   err-=dy
  else
   y+=yinc
   err+=dx
  end
 end
 return true
end

-- drawing funcs

function sortony(_t)
 for _i=1,#_t do
  local _j=_i
  while _j > 1 and _t[_j-1].y+_t[_j-1].hh > _t[_j].y+_t[_j].hh do -- todo: make cleaner
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

function drawactor(_a)
 pal(_a.colors,0)
 spr(_a.s[flr(_a.f)],_a.x-4,_a.y-(8-_a.hh),1,1,_a.sflip)
 pal()
end

---- 

avatar={
 x=68,y=60,
 hw=1,hh=1,
 s=split'41,42,43,44', -- swordsman
 -- s=split'45,46,47,48', -- ranger
 -- s=split'49,50,51,52', -- caster
 f=1,
 spd=.5,
 spdfactor=1,
 hp=3,
 colors=split'15,2,6,4,4,1,13,5'
}

theme=1

function mapinit()
 actors={}
 walls={}
 for _y=0,15 do
  walls[_y]={}
  for _x=0,15 do
   walls[_y][_x]=1
  end
 end

 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)
 local curx,cury,a,enemy_c,enemies,steps,angles=
  avatarx,avatary,0,1,{},split'440,600,420,600,450'[theme],
   ({split'0,0.25,-0.25',split'0,0,0,0.25,-0.25',split'0,0,0,0,0,0,0,0.5,0.5,0.25,-0.25',
    split'0,0,0,0,0,0,0,0,0,0.25',split'0,0,0.25'})[theme]
 local step_c=steps

 while step_c > 0 do
  a+=angles[flrrnd(#angles)+1]
  local nextx,nexty=curx+cos(a),cury+sin(a)
  
  if nextx > 0 and nextx < 15 and
     nexty > 0 and nexty < 15 then
   if nextx != avatarx or nexty != avatary then
    curx,cury=nextx,nexty
    walls[cury][curx]=0
    if step_c != 0 and step_c % (steps / enemy_c) == 0 then
     add(enemies,{x=curx*8+4,y=cury*8+4})
    end
   end
  end
  step_c-=1
 end

 -- setup enemies
 for _e in all(enemies) do
  add(actors,{
   x=_e.x,y=_e.y,
   a=0,
   hw=1,hh=1,
   dx=0,dy=0,
   spd=.375,spdfactor=1,
   s=split'53,54,55,56',
   f=1,
   colors=split'12,5,13',
   isenemy=true,
   })
 end

 -- add warpstone
 warpstone={x=curx*8+4,y=cury*8+4,dx=0,dy=0,hw=4,hh=4,s=20,spd=0,f=1}

 -- populate actors
 add(actors,avatar)
 -- ...
 add(actors,warpstone)

 -- remove walls around actors
 local _clearingarr=split'-1,-1, 0,-1, 1,-1, -1,0, 0,0, 1,0, -1,1, 0,1, 1,1'
 for _a in all(actors) do
  for _i=1,16,2 do
   local _myx,_myy=flr(_a.x/8)+_clearingarr[_i],flr(_a.y/8)+_clearingarr[_i+1]
   if _myx > 0 and _myx < 15 and
      _myy > 0 and _myy < 15 and walls[_myy][_myx] == 1 then
    walls[_myy][_myx]=0
   end
  end
 end

 -- todo: start music here
end

function _init()
 mapinit()
end

update60_curenemyi=1
function _update60()

 local _angle=btnmasktoa[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if _angle then
  if avatar.state != 'readying' and
     avatar.state != 'striking' then
   avatar.a,avatar.dx,avatar.dy=_angle,norm(cos(_angle)),norm(sin(_angle))
  end
 else
  avatar.dx,avatar.dy,avatar.f=0,0,1
 end

 update60_curenemyi+=1
 if update60_curenemyi > #actors then
  update60_curenemyi=1
 end
 local _enemy=actors[update60_curenemyi]
 if _enemy and _enemy.isenemy then
  local _disttoavatar,_haslostoavatar,_enemysight=
   dist(_enemy.x,_enemy.y,avatar.x,avatar.y),
   haslos(_enemy.x,_enemy.y,avatar.x,avatar.y),
   52

  if _haslostoavatar and _disttoavatar < _enemysight then
   -- debug('move towards avatar')
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   if _disttoavatar < 6 then
    _enemy.a+=.5
   end
   _enemy.spdfactor=1
  elseif _enemy.wallcollisiondx or _enemy.wallcollisiondy then
   -- debug('move out of wall collision')
   _enemy.a+=.5
   _enemy.targetx=nil
  elseif _enemy.targetx then
   -- debug('move towards target')
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   _enemy.spdfactor=1
   local _disttotarget=dist(_enemy.x,_enemy.y,_enemy.targetx,_enemy.targety)
   if _disttotarget < 4 then
    _enemy.targetx=nil
   end
  else -- roam
   -- debug('roam')
   _enemy.a+=rnd(.01)-.005
   _enemy.spdfactor=.25
  end

  _enemy.dx,_enemy.dy=cos(_enemy.a),sin(_enemy.a)

 end

 -- update the next-position
 for _a in all(actors) do
  local _spdfactor=_a.spd*(_a.spdfactor or 1)

  _a.dx,_a.dy=_a.dx*_spdfactor,_a.dy*_spdfactor
  if _a.dx != 0 then
   _a.sflip=sgn(_a.dx) < 0
  end

  if _a.dx != 0 or _a.dy != 0 then
   _a.f+=_spdfactor*.3125
   if _a.f >= 3 then
    _a.f=1
   end
  else
   _a.f=1
  end
  -- note: after this deltas should not change by input
 end

 -- movement check against walls
 for _a in all(actors) do
  if not _a.isstatic then
   local _dx,_dy=collideaabbs(isinsidewall,_a,nil,_a.dx,_a.dy)
   if _a != avatar then
    _a.wallcollisiondx,_a.wallcollisiondy=nil
    if _dx != _a.dx or _dy != _a.dy then
     _a.wallcollisiondx,_a.wallcollisiondy=_dx,_dy
    end
   end
   _a.x+=_dx
   _a.y+=_dy
  end
 end
end

function _draw()
 cls()

 -- draw walls
 local spr1=(theme-1)*4
 for _y=0,#walls do
  for _x=0,#walls[_y] do
   if walls[_y][_x] != 0 then
    _x8=_x*8
    _y8=_y*8

    if walls[_y+1] != nil and walls[_y+1][_x] != 0 then
     spr(spr1,_x8,_y8)
    else
     if (_y + _x) % 7 == 0 then
      spr(spr1+2,_x8,_y8)
     elseif (_y + _x) % 9 == 0 then
      spr(spr1+3,_x8,_y8)
     else
      spr(spr1+1,_x8,_y8)
     end
    end
   end
  end
 end

 -- draw actors
 add(actors,warpstone)
 sortony(actors)

 local _iscollide=isaabbscolliding(avatar,warpstone)

 for _a in all(actors) do
  if _a == warpstone then
   spr(_a.s,_a.x-_a.hw,_a.y-_a.hh)
  else
   drawactor(_a)
  end

  -- rect(_a.x-_a.hw,_a.y-_a.hh,_a.x+_a.hw,_a.y+_a.hh,_iscollide and 8 or 12)
  -- pset(_a.x,_a.y,7)
  -- pset(_a.x,_a.y+_a.hh,9)
 end
 del(actors,warpstone)

 -- custom pause screen
 if btn(6) then
  cls(2)
 end

end

__gfx__
00dddd0000dddd0000ddd00000000000000000000000000000000000515151501111111111111111111111111111111111111111111111111111111111111111
dddddd00dddddd000ddddd00000ddd00000050000000500000005000515151501111111111111111111111111111111111111111111111111111111111111111
dd5dddd0dd5dddd00ddd5d0000dd6660000551000005510000005000111111111111111111111111111131111111131111111111122122221222442212221222
ddd5d5d0ddd5d5d00d5d5d0000d666d00055511000555110000551005515551511111111dd1ddd1dd31d3d1d3d1d3d1d11111111122122221242e44212221222
0dd55dd00dd55dd000d5dd000dd66ddd000511000005110000551100111111111111111111111111113311111311331111111111122112221242f44212221122
0d0050d00d0050d00005d000d6d66d6d00551110005511100005510015551555111111111ddd1ddd1d3d1ddd13dd13dd11111111111111111122522111111111
0d0050000d005000000500006666d66d055111110551111100551110111111111111111111111111111311111131311111111111221221222214522221212212
000050000000500000050000000000000000200000002000000020005515551511111111dd1ddd1ddd13dd1ddd3d3d1d11111111221221222212212221212212
22222222222222222222222222222222000050000000000000000000000000000e88880000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222000055000e8888000f9999000e889990e800088000000000000000000000000000000000000000000000000000000000
2222222200000000000000000000050000051500e8000880f9090990e800909988f9999000000000000000000000000000000000000000000000000000000000
22222222022022220222002202502522000555008808082099909940880809948f90909900222000000430000004000000000000044443000001100000043000
22222222020022200220002002055220005155008800022099090440880090440999099402000200002342000044300003040300033332000033320000433200
22222222000000000000000000050000005555000222220004444400022244400990904402002000002001000443330004413300033130000002200000131200
22222222220222020002220222025202005515500000000000000000000000000044444000430000000110000032200002332200031330000034420000313000
22222222200220022002200220025002005555500000000000000000000000000000000000330000000000000002000000000000033300000022220000032000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00333000033322000000040000000300000004000022100000332000033022000330200000000000000000000000330000000000000004000000040000000000
03413200032212000000400000004300000020000443110002241100012311000440300000001030000010300000170000001000000010400000104000001400
03312200032412000304000000040300000300000000310002201100003210000330200000887730008877300088700006887733000677400006774000077740
00222000021112000030000000402000003000000403110002201100002430000233020000887600008876000088700066887000000674000006740000067400
00000000002220000102000003330000020000000403100002201100003210000022010000026200000626000062620066620200000262000006200000026200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000005000000000000000000000000000000000000000000000300000003000003311000000000000000000000000000000000000
00000400000050000000500000666500000000500000000000000000000033000000000000311000003110000021100000011000000000000000000000000000
00001040000015000000150000671650000010500000103000001030000011000000100000311000003110000021100000011000000000000000000000000000
00067740000777500007775000067705000777500001213000012130000120000001213300122100001221000022200000222000000000000000000000000000
00067040000676050006760500007000000676500000200000002000000020000000200000222000002220000022200000211330000000000000000000000000
00026200000262000006260000020200006262500001010000001000000101000001010000202000000200000020200002202000000000000000000000000000
