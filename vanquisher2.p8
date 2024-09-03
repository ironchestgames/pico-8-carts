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

btnmasktoa={
 [0x0002]=0, -- right
 [0x0006]=0.125, -- right/up
 [0x0004]=0.25, -- up
 [0x0005]=0.375, -- up/left
 [0x0001]=0.5, -- left
 [0x0009]=0.625, -- left/down
 [0x0008]=0.75, -- down
 [0x000a]=0.875, -- down/right
}

function flrrnd(_n)
 return flr(rnd(_n))
end

function norm(n)
 return n == 0 and 0 or sgn(n)
end

function sortony(_t)
 for _i=1,#_t do
  local _j=_i
  while _j > 1 and _t[_j-1].y > _t[_j].y do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end


function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

-- if
--         other.pos.x+other.hitbox.x+other.hitbox.w > obj.pos.x+obj.hitbox.x and 
--         other.pos.y+other.hitbox.y+other.hitbox.h > obj.pos.y+obj.hitbox.y and
--         other.pos.x+other.hitbox.x < obj.pos.x+obj.hitbox.x+obj.hitbox.w and
--         other.pos.y+other.hitbox.y < obj.pos.y+obj.hitbox.y+obj.hitbox.h 
--     then

wallaabb={hw=4,hh=4}
function isinsidewall(aabb)
 local x1,y1,x2,y2=
  aabb.x-aabb.hw,aabb.y-aabb.hh,
  aabb.x+aabb.hw,aabb.y+aabb.hh

 for p in all{{x1,y1},{x2,y1},{x2,y2},{x1,y2}} do
  local mapx,mapy=flr(p[1]/8),flr(p[2]/8)
  wallaabb.x,wallaabb.y=mapx*8+wallaabb.hw,mapy*8+wallaabb.hh

  -- note: hitboxes should not be larger than 8x8
  if not walls[mapy] or not walls[mapy][mapx] then
   -- aabb.removeme=true
   debug('inside wall')
  elseif walls[mapy][mapx] == 1 and isaabbscolliding(aabb,wallaabb) then
   return wallaabb
  end
 end
end

_aabb={}
function collideaabbs(func,aabb,other,_dx,_dy)
 local dx,dy=_dx,_dy

 _aabb.x,_aabb.y,_aabb.hw,_aabb.hh=aabb.x+_dx,aabb.y,aabb.hw,aabb.hh
 local collidedwith=func(_aabb,other)
 if collidedwith then
  dx=(aabb.hw+collidedwith.hw-abs(aabb.x-collidedwith.x))*-sgn(_dx)
 end

 _aabb.x,_aabb.y=aabb.x,aabb.y+_dy
 local collidedwith=func(_aabb,other)
 if collidedwith then
  dy=(aabb.hh+collidedwith.hh-abs(aabb.y-collidedwith.y))*-sgn(_dy)
 end

 return dx,dy
end


avatar={
 x=68,y=60,
 hw=1.5,hh=1.5,
 -- s=split'48,49',
 -- s=split'52,53',
 s=split'56,57',
 f=1,
 spdfactor=1,
 spd=0.5,
 hp=3,
 att_spd_dec=0,
 armor=0,
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
  avatarx,avatary,0,10,{},split'440,600,420,600,450'[theme],
   ({split'0,0.25,-0.25',split'0,0,0,0.25,-0.25',split'0,0,0,0,0,0,0,0.5,0.5,0.25,-0.25',
    split'0,0,0,0,0,0,0,0,0,0.25',split'0,0,0.25'})[theme]
 local step_c=steps

 while step_c > 0 do
  a+=angles[flrrnd(#angles)+1]
  local nextx,nexty=curx+cos(a),cury+sin(a)
  
  if nextx > 0 and nextx < 15 and
     nexty > 0 and nexty < 15 then
  -- elseif step_c != 0 and step_c % (steps / enemy_c) == 0 then
  --  add(enemies,{x=curx,y=cury,typ=flrrnd(3)+1})
   if nextx != avatarx or nexty != avatary then
    curx,cury=nextx,nexty
    walls[cury][curx]=0
   end
  end
  step_c-=1
 end

 -- add warpstone
 warpstone={x=curx*8+4,y=cury*8+7,dx=0,dy=0,hw=4,hh=4,s=20}

 -- populate actors
 add(actors,avatar)
 -- ...
 add(actors,warpstone)

 -- remove walls around avatar and warpstone
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

 -- reset
 curenemyi,
 tick,
 attacks,
 pemitters,
 vfxs,
 boss=
  1,0,{},{},{},{}

 -- todo: start music here
end

function _init()
 mapinit()
end

function _update60()
 local angle=btnmasktoa[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle then
  if avatar.state != 'recovering' and
     avatar.state != 'attacking' then
   avatar.a,avatar.dx,avatar.dy,avatar.state,avatar.state_c=
    angle,norm(cos(angle)),norm(sin(angle)),'moving',2
  end
 elseif avatar.state != 'recovering' then
  avatar.dx,avatar.dy=0,0
 end

 avatar.f+=.1
 if avatar.f >= 3 then
  avatar.f=1
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
   _a.dx,_a.dy=0,0
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
 for _a in all(actors) do
  if _a == warpstone then
   spr(_a.s,_a.x-4,_a.y-7)
  else
   pal(_a.colors,0)
   spr(_a.s[flr(_a.f)],_a.x-4,_a.y-7)
   pal()
  end

  rect(_a.x,_a.y,_a.x+_a.hw,_a.y+_a.hh,12)
  pset(_a.x,_a.y,7)
 end
 del(actors,warpstone)

 -- custom pause screen
 if btn(6) then
  cls(2)
 end

end

__gfx__
00000000000000000000000000000000101000101010001000005000000000001111111111111111111111111111111111111111111111111111111111111111
00005000000050000000500000055500010001000100010000051000000000001111111111111111111111111111111111111111111111111111111111111111
0005510000055100000050000055ddd0001111000011110000051100000100001111111111111111111131111111131111111111122122221222442212221222
005551100055511000055100005ddd500001100000011000005111000001110011111111dd1ddd1dd31d3d1d3d1d3d1d11111111122122221242e44212221222
000511000005110000551100055dd555000110000001100000511510000111001111111111111111113311111311331111111111122112221242f44212221122
0055111000551110000551005d5dd5d500111000001110000511151000111100111111111ddd1ddd1d3d1ddd13dd13dd11111111111111111122522111111111
055111110551111100551110dddd5dd5011111000111110005115110010010101111111111111111111311111131311111111111221221222214522221212212
000020000000200000002000000000000000000000000000000000000001000011111111dd1ddd1ddd13dd1ddd3d3d1d11111111221221222212212221212212
22222222222222222222222222222222000050000000000000000000000000000e88880000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222000055000e8888000f9999000e889990e800088000222000000430000004000000030000000000000444430000011000
2222222200000000000000000000050000051500e8000880f9090990e800909988f9999002000200002342000044300004434300030403000333320000333200
22222222022022220222002202502522000555008808082099909940880809948f90909902002000002001000443330004030200044133000331300000022000
22222222020022200220002002055220005155008800022099090440880090440999099400430000000110000032200000332000023322000313300000344200
22222222000000000000000000050000005555000222220004444400022244400990904400330000000000000002000000030000000000000333000000222200
22222222220222020002220222025202005515500000000000000000000000000044444000000000000000000000000000000000000000000000000000000000
22222222200220022002200220025002005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03300000000430000033300000221000033020000000040000000300000004000033200003302200033322000040000000033000000000000000000000000000
03400000004332000341320004431100044030000000400000004300000020000224110001231100032212000002000000342300000000000000000000000000
00120000001312000331220000003100033020000304000000040300000300000220110000321000032412000000230000322300000000000000000000000000
00102000003130000022200004031100023302000030000000402000003000000220110000243000021112000000300000033000000000000000000000000000
00000200000320000000000004031000002201000203000003330000020000000220110000321000002220000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000
00000000000000000000330000000000000004000000040000000000000004000000500000005000006665000000005000000000000000000000000000000000
00001030000010300000170000001000000010400000104000001400000010400000150000001500006716500000105000000000000000000000000000000000
00887730008877300088700006887733000677400006774000077740000677400007775000077750000677050007775000000000000000000000000000000000
00887600008876000088700066887000000674000006740000067400000670400006760500067605000070000006765000000000000000000000000000000000
00026200000626000062620066620200000262000006200000026200000262000002620000062600000202000062625000000000000000000000000000000000
