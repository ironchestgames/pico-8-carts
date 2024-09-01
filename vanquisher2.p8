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

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

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
 x=64,y=56,
 hw=1.5,hh=1.5,
 spdfactor=1,
 spd=0.5,
 hp=3,
 att_spd_dec=0,
 armor=0,
}

theme=2

function mapinit()
 local basemap={}
 for _y=0,15 do
  basemap[_y]={}
  for _x=0,15 do
   basemap[_y][_x]=1
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
    basemap[cury][curx]=0
   end
  end
  step_c-=1
 end

 -- for _e in all(enemies) do
 --  basemap[_e.y][_e.x]=_e.typ
 -- end

 -- if _theme.lvl_c == 0 then
 --  local enemy=enemies[#enemies]
 --  basemap[enemy.y][enemy.x]=4
 --  nexttheme+=1
 -- end

 door={
  x=curx*8,y=cury*8
 }
 local _clearingarr=split'-1,-1,-1,0,-1,1,0,-1,0,1,1,-1,1,0,1,-1'
 for _i=1,16,2 do
  local _myx,_myy=curx+_clearingarr[_i],cury+_clearingarr[_i+1]
  if _myx > 0 and _myx < 15 and
     _myy > 0 and _myy < 15 and basemap[_myy][_myx]==1 then
   debug(_myx..','.._myy)
   basemap[_myy][_myx]=0
  end
 end

 -- reset
 basemap[avatary][avatarx],
 curenemyi,
 tick,
 walls,
 actors,
 attacks,
 pemitters,
 vfxs,
 interactables,
 isdoorspawned,
 boss=
  15,
  1,0,{},{},{},{},{},{}

 for _y=0,15 do
  walls[_y]={}
  for _x=0,15 do
   local _col,ax,ay=basemap[_y][_x],_x*8+4,_y*8+4

   if _col == 15 then
    avatar.x,avatar.y=ax,ay
   end

   -- if _col <= 4 then
   --  add(actors,_theme[_col](ax,ay))
   -- end

   -- if _col == 10 then
   --  door={
   --   x=ax,y=ay,hw=4,hh=4,
   --   text='\x8e go deeper',
   --   enter=function()
   --    theme=nexttheme
   --    dungeonlvl+=1
   --    avatar.x,avatar.y=door.x,door.y
   --    return true
   --   end
   --  }

   --  if nexttheme > 4 then
   --   door.text,door.sprite,door.enter='\x8e go home',248,splash
   --  else
   --   door.sprite=179+nexttheme*16
   --  end
   --  add(interactables,door)
   -- end

   -- walls[_y][_x]=_col == 9 and 1 or 0
   walls[_y][_x]=_col
  end
 end

 -- music(theme*10,0,0b0011)
 -- if boss then
 --  music(1,0,0b0011)
 -- end
end

function _init()
 mapinit()
end

function _update60()

actors={avatar}

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

 -- movement check against walls
 for _a in all(actors) do
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

 -- draw warpstone
 spr(20,door.x,door.y)

 -- draw avatar
 pset(avatar.x,avatar.y)

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
22222222222222222222222222222222000050000e8888000f9999000e8899900022200000043000000400000003000000000000044443000001100003300000
2222222222222222222222222222222200005500e8000880f9090990e80090990200020000234200004430000443430003040300033332000033320003400000
22222222000000000000000000000500000515008808082099909940880809940200200000200100044333000403020004413300033130000002200000120000
22222222022022220222002202502522000555008800022099090440880090440043000000011000003220000033200002332200031330000034420000102000
22222222020022200220002002055220005155000222220004444400022244400033000000000000000200000003000000000000033300000022220000000200
22222222000000000000000000050000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222220222020002220222025202005515500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222200220022002200220025002005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00043000003330000022200003302000000004000000030000000400003320000330220003332200004000000003300000000000000000000000000000000000
00433200034132000443220004403000000040000000430000002000022411000123110003221200000200000034230000000000000000000000000000000000
00131200033122000111320003302000030400000004030000030000022011000032100003241200000023000032230000000000000000000000000000000000
00313000002220000413220002330200003000000040200000300000022011000024300002111200000030000003300000000000000000000000000000000000
00032000000000000413200000220100020300000333000002000000022011000032100000222000000000000000000000000000000000000000000000000000
