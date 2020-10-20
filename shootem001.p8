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


local function shuffle(_l,_len)
 for _i=_len,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end

local ship={x=64,y=110,spd=1,firespd=10,firetim=0,shieldcount=0,hp=2}

local bullets={}

local enemyupdate={
 [16]=function(_e)
  newenemyexhaustp(_e.x-3,_e.y-3)
  newenemyexhaustp(_e.x-2,_e.y-3)
  newenemyexhaustp(_e.x+1,_e.y-3)
  newenemyexhaustp(_e.x+2,_e.y-3)

  _e.c+=1

  _e.dx+=mid(-1,ship.x-_e.x,1)*0.025*(_e.ifactor*0.5)
  _e.dx*=0.98

  if _e.c >= 80 then
   add(bullets,{x=_e.x,y=_e.y+4,spdx=0,spdy=2,s=3})
   _e.c=0
  end
  if _e.y > ship.y then
   _e.dy*=1.04
  end
 end,
 [18]=function(_e)
  newenemyexhaustp(_e.x-1,_e.y-2)

  _e.c+=1

  local _a=atan2(ship.x-_e.x,ship.y-_e.y)
  _e.dx=cos(_a)*0.5
  _e.dy+=0.011+(_e.ifactor*0.003)

  if _e.y < -8 then
   _e.dy=0.5
  end
 end,
}

local spawnqueue={}
local types={18,16,18,18,18}
local enemyhps={[16]=12,[18]=3}

for _i=1,25 do
 local _typ=shuffle(types,#types)[1]
 add(spawnqueue,{
  typ=_typ,
  x=rnd()*128,y=-4,
  dy=0.5,dx=0,
  c=0,
  hp=enemyhps[_typ],
  f=enemyupdate[_typ],
  ifactor=rnd(),
 })
end

shuffle(spawnqueue,60)

local enemies={}

local stars={}
for i=1,100 do
 add(stars,{
  x=flr(rnd()*128),
  y=flr(rnd()*128),
  spd=rnd()*2+0.5,
 })
end

local ps={}

local bulletcolors={9,4}
local enemybulletcolors={11,3}

local enemyexhaustcolors={7,15,14}
function newenemyexhaustp(_x,_y)
 local _life=rnd()*2+1
 add(ps,{
  x=_x,
  y=_y,
  r=0.1,
  spdx=0,
  spdy=-rnd(),
  spdr=0,
  colors=enemyexhaustcolors,
  life=_life,
  lifec=_life,
 })
end

local exhaustcolors={7,12,1}
function newexhaustp(_x,_y)
 local _life=rnd()*2+3
 add(ps,{
  x=_x,
  y=_y,
  r=0.1,
  spdx=(rnd()-0.5)*0.01,
  spdy=0.1+rnd()-0.1,
  spdr=0,
  colors=exhaustcolors,
  life=_life,
  lifec=_life,
 })
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

local explosioncolors={7,7,10,9,8}
local function newexplosion(_x,_y)
 for _i=1,7 do
  local _life=11
  add(ps,{
   x=_x,
   y=_y,
   r=rnd()*5,
   spdx=(rnd()-0.5),
   spdy=rnd()-1,
   spdr=rnd()*0.2+0.5,
   colors=explosioncolors,
   life=_life,
   lifec=_life,
   ondeath=explosionsmoke,
  })
 end
end

local hitcolors={7,15}
local function newhit(_x,_y)
 for _i=1,7 do
  local _life=4
  add(ps,{
   x=_x+(rnd()-0.5)*5,
   y=_y+(rnd()-0.5)*5,
   r=rnd()*5,
   spdx=(rnd()-0.5)*2,
   spdy=rnd()-0.5,
   spdr=-0.2,
   colors=hitcolors,
   life=_life,
   lifec=_life,
  })
 end
end

local burningcolors={10,9,5}
local function newburningp(_x,_y,_ydir)
 local _life=8+rnd()*4
 add(ps,{
  x=_x,
  y=_y,
  r=0.5,
  spdx=(rnd()-0.5)*0.125,
  spdy=(rnd()*0.25+1)*_ydir,
  spdr=0.25*rnd(),
  colors=burningcolors,
  life=_life,
  lifec=_life,
 })
end

local isgameover
function _update60()

 -- update particles
 shuffle(ps,#ps)
 for _p in all(ps) do
  _p.x+=_p.spdx
  _p.y+=_p.spdy
  _p.r+=_p.spdr
  _p.lifec-=1
  _p.col=_p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
  if _p.lifec<0 then
   del(ps,_p)
   if _p.ondeath then
    _p.ondeath(_p.x,_p.y)
   end
  end
 end
 
 if isgameover then
  return
 end

 -- stars
 for _s in all(stars) do
  _s.y+=_s.spd
  if _s.y>130 then
   _s.y=-3
   _s.x=flr(rnd()*128)
  end
 end

 -- spawn enemies
 local _flrt=flr(t()*3)
 debug(_flrt)
 if spawnqueue[_flrt] then
  add(enemies,spawnqueue[_flrt])
  spawnqueue[_flrt]=nil
 end
 
 -- ship moving
 local _newx=ship.x
 local _newy=ship.y
 
 if btn(0) then
  _newx+=-ship.spd
 end
 if btn(1) then
  _newx+=ship.spd
 end
 if btn(2) then
  _newy+=-ship.spd
 end
 if btn(3) then
  _newy+=ship.spd
 end
 
 ship.x=mid(4,_newx,124)
 ship.y=mid(4,_newy,119)
 
 -- ship fire
 ship.frame=0
 if btn(4) then
  ship.firetim-=1
  ship.shieldcount+=0.125
  if ship.firetim<=0 then
   add(bullets,{x=ship.x-4,y=ship.y-1,spdx=0,spdy=-3,s=2,friendly=true})
   add(bullets,{x=ship.x+3,y=ship.y-1,spdx=0,spdy=-3,s=2,friendly=true})
   ship.firetim=ship.firespd
   ship.frame=1
  end
 else
  ship.firetim=0
 end

 if ship.hp > 1 and ship.firetim == 0 and ship.shieldcount > 0 then
  ship.hasshield=true
  ship.shieldcount-=1
 else
  ship.hasshield=nil
 end

 ship.shieldcount=mid(0,ship.shieldcount,120)

 -- bullets
 for _b in all(bullets) do
  _b.x+=_b.spdx
  _b.y+=_b.spdy

  if _b.friendly then
   local _life=rnd()*4+4
   add(ps,{
    x=_b.x,
    y=_b.y+4,
    r=0.1,
    spdx=0,
    spdy=rnd()*-0.1,
    spdr=0,
    colors=bulletcolors,
    life=_life,
    lifec=_life,
   })
  else
   for _i=-1,1 do
    local _life=rnd()*4+4
    add(ps,{
     x=_b.x+_i,
     y=_b.y+4,
     r=0.1,
     spdx=0,
     spdy=rnd()*-0.1,
     spdr=0,
     colors=enemybulletcolors,
     life=_life,
     lifec=_life,
    })
   end
  end

  if _b.friendly then
   for _e in all(enemies) do
    local _dx=_e.x-_b.x
    local _dy=_e.y-_b.y
    if sqrt(_dx^2+_dy^2) < 6 then
     _e.hp-=1
     newhit(_e.x,_e.y)
     del(bullets,_b)
    end
   end
  else
   local _dx=ship.x-_b.x
   local _dy=ship.y-_b.y
   if sqrt(_dx^2+_dy^2) < 6 then
    newexplosion(ship.x,ship.y)
    if ship.hasshield then
     ship.shieldcount-=1
    elseif ship.hp > 1 then
     ship.hp-=1
    else
     isgameover=true
    end
    del(bullets,_b)
   end
  end

  if _b.x<0 or _b.x>128 or
    _b.y<0 or _b.y>128 then
   del(bullets,_b)
  end
 end

 -- enemies
 for _e in all(enemies) do
  _e.f(_e)
  _e.x+=_e.dx
  _e.y+=_e.dy

  if _e.hp <= 0 then
   newexplosion(_e.x,_e.y)
   del(enemies,_e)
  elseif _e.typ == 16 and _e.hp <= 2 then
   newburningp(_e.x,_e.y,-1)
  end

  local _dx=ship.x-_e.x
  local _dy=ship.y-_e.y
  if sqrt(_dx^2+_dy^2) < 6 then
   if ship.hasshield then
    ship.shieldcount-=1
   else
    newexplosion(ship.x,ship.y)
    isgameover=true
    del(enemies,_e)
   end
  end

  if _e.y > 132 then
   _e.y=-16
   _e.dy=0.25
   _e.x+=(rnd()-0.5)*5
   _e.c=0
  end
 end

 newexhaustp(ship.x,ship.y+4)
 newexhaustp(ship.x,ship.y+4)

 if ship.hp == 1 then
  newburningp(ship.x-2,ship.y+2,1)
 end

end

function _draw()
 cls(0)
 
 -- draw stars
 for _s in all(stars) do
  if _s.spd<=1 then
   pset(_s.x,_s.y,1)
  end
 end

 -- draw ship
 if not isgameover then
  spr(0+ship.frame,ship.x-4,ship.y-4)

  if ship.hasshield then
   circ(ship.x,ship.y,6,1)
   fillp(rnd()*32767)
   circ(ship.x+rnd()*2-1,ship.y+rnd()*2-1,6,12)
   fillp()
  end
 end

 -- draw enemies
 for _e in all(enemies) do
  spr(_e.typ,_e.x-4,_e.y-4)
 end
 
 -- draw bullets
 for _b in all(bullets) do
  spr(_b.s,_b.x-3,_b.y)
 end

 -- draw particles
 for _p in all(ps) do
  circfill(_p.x,_p.y,_p.r,_p.col)
 end

 if ship.hp == 1 then
  rect(3,124,124,127,5)
 elseif ship.shieldcount > 0 then
  rect(3,124,124,127,12)
  rectfill(3,124,3+ship.shieldcount,127,12)
 end
end


__gfx__
00099000000770000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000770000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007c000000770000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006cc600007777000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006cc600007777000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70699607707777070000000000aba000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
796996977777777700000000007a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
69699696777777770000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0550055005500550000d0000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03355330033553300d222d000d222d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3533335335333353d22d22d0d22d22d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bb33bb33bb33bb3d02d20d0d02d20d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03bbbb3003bbbb30002f2000002f2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
035bb530035bb530002f2000002f2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00533500005335000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000000330000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
