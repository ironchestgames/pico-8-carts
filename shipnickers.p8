pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- shipnickers 1.0
-- by ironchest games

--[[
 - add shield
 - add cloak
 - add laser
 - add blink
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
 [13]=mrs2t's=13,bulletcolor=11,primary="boost",secondary="missile",secondaryshots=3,psets="3;6;5;3;4;6",guns="2;2;5;2",exhaustcolors="7;6;13",exhausts="-3;4;-2;4;1;4;2;4"',
 [14]=mrs2t's=14,bulletcolor=3,primary="boost",secondary="boost",secondaryshots=3,psets="0;0;9;0;0;9",guns="1;0;6;0",exhaustcolors="11;12;5",exhausts="-2;3;-1;3;0;3;1;3"',
 [15]=mrs2t's=15,bulletcolor=9,primary="boost",secondary="mines",secondaryshots=3,psets="3;4;9;3;2;10",guns="1;0;6;0",exhaustcolors="11;3;4",exhausts="-4;4;-3;4;2;4;3;4"',
 [26]=mrs2t's=26,bulletcolor=14,primary="mines",secondary="missile",secondaryshots=3,psets="0;1;13;0;1;13",guns="1;1;6;1",exhaustcolors="10;9;4",exhausts="-3;4;-2;4;1;4;2;4"',
 [27]=mrs2t's=27,bulletcolor=5,primary="mines",secondary="boost",secondaryshots=3,psets="3;5;12;3;3;11",guns="0;4;7;4",exhaustcolors="10;9;15",exhausts="-3;4;-2;4;1;4;2;4"',
 [28]=mrs2t's=28,bulletcolor=11,primary="mines",secondary="mines",secondaryshots=3,psets="3;4;1;3;3;12",guns="0;2;7;2",exhaustcolors="7;6;5",exhausts="-2;4;1;4"',
}

-- helpers
local function drawblinktext(_str,_startcolor)
 print('\^w\^t'.._str,64-#_str*4,48,_startcolor+flr((t()*12)%3))
end

local function getship(_hangaridx)
 local _ship=mr(clone(hangar[_hangaridx]),s2t'y=110,hw=3,hh=3,spd=1,hp=3,repairc=0,firingc=0,primaryc=30,secondaryc=0')
 local _guns=split(_ship.guns,';')
 _ship.guns={{x=_guns[1],y=_guns[2]},{x=_guns[3],y=_guns[4]}}
 local _psets=split(_ship.psets,';')
 _ship.psets={{_psets[1],_psets[2],_psets[3]},{_psets[4],_psets[5],_psets[6]}}
 _ship.exhaustcolors=split(_ship.exhaustcolors,';')
 _ship.exhausts=split(_ship.exhausts,';')
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

local explosioncolors=split'7,7,10,9,8'
local function newexplosion(_x,_y) -- todo: same as explode?
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

local function drawcloak(_ship)
 palt(0,false)
 fillp(rnd()*32767)
 circfill(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,1)
 circfill(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,0)
 fillp()
 palt(0,true)
end

local function drawshield(_ship)
 circ(_ship.x,_ship.y,6,1)
 fillp(rnd()*32767)
 circ(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,12)
 fillp()
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

-- weapons
local function shootmine(_ship,_life,_angle)
 add(bullets,{
  x=_ship.x,y=_ship.y,
  sx=0,sy=110,sw=2,sh=2,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  spdx=cos(_angle+rnd(0.02)),spdy=sin(_angle+rnd(0.02)),accy=0,
  dmg=6,
  life=_life,
  update=function(_obj)
   _obj.frame+=(t()*0.375)/_obj.life
   if _obj.frame > 2 then
    _obj.frame=0
   end
   _obj.sx=_obj.sw*flr(_obj.frame)
  end,
  ondeath=explode,
 })
end

local missilepcolors=split'7,10,9'
local function shootmissile(_ship,_life)
 add(bullets,{
  x=_ship.x,y=_ship.y,
  sx=16,sy=123,sw=3,sh=5,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=-rnd(0.175),accy=-0.05,spdfactor=1,
  dmg=12,
  life=_life,
  ondeath=explode,
  p=mr(s2t'xoff=1,yoff=5,r=0.1,spdx=0,spdy=-0.1,spdr=0,life=3',{colors=missilepcolors}),
 })
end

local primary={
 missile=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 and _ship.primaryc > 1 then
   shootmissile(_ship,_ship.primaryc*2)
   _ship.primaryc=0
  end
 end,
 boost=function(_btn4,_ship)
  if _ship.primaryc > 0 and not _btn4 then
   _ship.isboosting=true
  end
 end,
 mines=function(_btn4,_ship)
  if _btn4 and not _ship.lastbtn4 and _ship.primaryc > 1 then
   shootmine(_ship,_ship.primaryc*3.5+15,0.2+rnd(0.1))
   _ship.primaryc=0
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
}

local weaponcolors=s2t'missile=15,boost=2,mines=5'

local boostcolors=split'7,10,9,8'

local secondarysprites={
 missile=split'16,123,3,5',
 boost=split'23,123,2,5',
 mines=split'2,110,2,2',
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

local function enemyshootmissile(_enemy)
 add(enemybullets,{
  x=_enemy.x,y=_enemy.y,
  sx=16,sy=118,sw=3,sh=5,
  hw=2,hh=3,
  spdx=rnd(0.5)-0.25,spdy=0.1,accy=0.05,spdfactor=1,
  life=1000,
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

local function enemyshootmine(_enemy)
 add(enemybullets,{
  x=_enemy.x,y=_enemy.y,
  sx=0,sy=108,sw=2,sh=2,
  hw=2,hh=2,
  frame=0,
  spdfactor=0.96+rnd(0.01),
  spdx=rnd(0.5)-0.25,spdy=1.5,accy=0,
  life=110,
  update=function(_obj)
   _obj.frame+=(t()*0.375)/_obj.life
   if _obj.frame > 2 then
    _obj.frame=0
   end
   _obj.sx=_obj.sw*flr(_obj.frame)
  end,
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
   _ship.isboosting=nil
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
       sx=19,sy=124,sw=1,sh=4,
       spdx=0,spdy=-3,accy=0,spdfactor=1,
       dmg=1,
       life=1000,
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
  end

  for _i=1,#_ship.exhausts,2 do
   newexhaustp(_ship.exhausts[_i],_ship.exhausts[_i+1],_ship,_ship.isboosting and boostcolors or _ship.exhaustcolors,_ship.isboosting and 8 or 4)
  end

  if _ship.hp == 0 then
   newexplosion(_ship.x,_ship.y)
   del(ships,_ship)
  end

  if boss and isaabbscolliding(_ship,boss) then
   if nickitts then
    ships[_plidx+1]=mr(getship(boss.s),{plidx=_plidx,x=_ship.x,y=_ship.y,hp=1})
    createshipflashes()
    nickedts=curt
    escapeelapsed=0
    nickitts=nil
    boss=nil
   else
    newexplosion(_ship.x,_ship.y)
    newexplosion(boss.x,boss.y)
    boss=nil
    _ship.hp=0
   end
  end
 end

 -- update friendly bullets
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
    _ship.hp-=1
    _ship.primaryc=0
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
   newexplosion(_enemy.x,_enemy.y)
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
     newexplosion(_enemy.x,_enemy.y)
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
  sspr(_b.sx,_b.sy,_b.sw,_b.sh,_b.x,_b.y)
 end

 -- draw bullets
 for _b in all(bullets) do
  sspr(_b.sx,_b.sy,_b.sw,_b.sh,_b.x,_b.y)
 end

 -- draw enemies
 for _enemy in all(enemies) do
  spr(_enemy.s,_enemy.x-4,_enemy.y-4)
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
 escapeduration=24
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
 -- unlocked[28]=false
 -- unlocked[2]=false
 -- unlocked[13]=false
 -- unlocked[14]=false
 -- unlocked[15]=false
 -- unlocked[26]=false
 -- unlocked[27]=false
 
 persistunlocked()
 loadunlocked()
 
 -- for _i=0,169 do
  -- debug(unlocked[_i])
  -- debug(dget(_i))
 -- end

 pickerinit()
end


__gfx__
00044000000dd000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000880000009900007000070
00db3d00005dd500040ab04000000000000000000000000000000000000000000000000000000000000000000000000000000000000650000097690078000087
08d33d80005e2500046bb64000000000000000000000000000000000000000000000000000000000000000000000000000000000008558000867668078000087
2dd33dd206522560d66bb66d00000000000000000000000000000000000000000000000000000000000000000000000000000000082552808f6996f8780a9087
28d44d826d5225d6d66dd66d00000000000000000000000000000000000000000000000000000000000000000000000000000000002882008f8998f878099087
8dd44dd86d5dd5d6004dd40000000000000000000000000000000000000000000000000000000000000000000000000000000000082882809f8998f988599588
8d0550d866dddd660d6dd6d000000000000000000000000000000000000000000000000000000000000000000000000000000000822882289f8998f968588586
82000028044004400d0550d000000000000000000000000000000000000000000000000000000000000000000000000000000000855005589000000966088066
00000000000000000000000000000000000000000000000000000000000000000000000000000000000550000060060000d55d00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000555500006996000dd55dd0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000d59e5d000dbcd000dd11dd0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000de9eed060dccd065d1c11d5000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000004de44ed4694cc4965d1111d5000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000004d5445d4d949949d5d5115d5000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000dd5445ddd949949d0d5dd5d0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000220022005500550005dd500000000000000000000000000
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
c55c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5cc50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
85580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
58850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000000004d40000000a0000b0000c000000003333333333333bbb3bbb3bbb3bbb3bbb3bbb33000000000000000000000000000000000000000000000
00000000000000000d0000000aaa00bbb00ccc000000033bbb33333333b3b3b333b3b3b3b33b33b3b33000000000000000000000000000000000000000000000
77777777777777770d000000aaaaabbbbbccccc00000033b3b33333333bb33bb33bbb3bbb33b33bb333000000000000000000000000000000000000000000000
77777777777777770d00000000a0000b0000c0000000033bbb33333333b3b3b333b333b3b33b33b3b33000000000000000000000000000000000000000000000
77777777777777770d00000000a0000b0000c000000003333333333333b3b3bbb3b333b3b3bbb3b3b33000000000000000000000000000000000000000000000
77777777777777770600000002222200002200222002222222222222228882888288828882888288822000000000000000000000000000000000000000000000
77777777777777770607000aa2000020002020222020020888000000008080800080808080080080802000000000000000000000000000000000000000000000
777777777777777706077079a2000002002020202020020808000000008800880088808880080088002000000000000000000000000000000000000000000000
77777777777777770607070892000020002020202020220888000000008080800080008080080080802000000000000000000000000000000000000000000000
7777777777777777d6da707082222200002220202022222222222222228282888282228282888282822000000000000000000000000000000000000000000000
