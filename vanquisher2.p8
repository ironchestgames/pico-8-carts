pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- vanquisher of evil 2 1.0-alpha
-- by ironchest games

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

cartdata'ironchestgames_vvoe2_v1_dev1'

--[[

63 - level completion (boss levels only: 3,6,9,12)

--]]

poke(0x5f5c, -1) -- set auto-repeat delay for btnp

btnmasktoa=split'0.5,0,,0.25,0.375,0.125,,0.75,0.625,0.875'
confusedbtnmasktoa=split'0,0.5,,0.75,0.875,0.625,,0.25,0.125,0.375'

-- [0x0001]=0.5, -- left
-- [0x0002]=0, -- right
-- [0x0004]=0.25, -- up
-- [0x0005]=0.375, -- up/left
-- [0x0006]=0.125, -- right/up
-- [0x0008]=0.75, -- down
-- [0x0009]=0.625, -- left/down
-- [0x000a]=0.875, -- down/right

function flrrnd(_n)
 return flr(rnd(_n))
end

function norm(n)
 return n == 0 and 0 or sgn(n)
end

function atodirections(_a)
 return flr((_a%1)*8)/8 -- todo: maybe %1 is not needed
end

function tconcat(_t1,_t2)
 local _t={}
 for _i in all(_t1) do
  add(_t,_i)
 end
 for _i in all(_t2) do
  add(_t,_i)
 end
 return _t
end

-- collision funcs

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

isinsidewall_wallabb={hw=4,hh=4}
function isinsidewall(_aabb)
 local _x1,_y1,_x2,_y2=
  _aabb.x-_aabb.hw,_aabb.y-_aabb.hh,
  _aabb.x+_aabb.hw,_aabb.y+_aabb.hh

 for _p in all{{_x1,_y1},{_x2,_y1},{_x2,_y2},{_x1,_y2}} do
  local _mapx,_mapy=flr(_p[1]/8),flr(_p[2]/8)
  isinsidewall_wallabb.x,isinsidewall_wallabb.y=_mapx*8+isinsidewall_wallabb.hw,_mapy*8+isinsidewall_wallabb.hh

  -- note: hitboxes should not be larger than 8x8
  if not walls[_mapy] or not walls[_mapy][_mapx] then
   -- _aabb.removeme=true
   debug('warn - inside wall! should not happen')
  elseif walls[_mapy][_mapx] != 0 and isaabbscolliding(_aabb,isinsidewall_wallabb) then
   return isinsidewall_wallabb
  end
 end

 for _dw in all(dynwalls) do
  if isaabbscolliding(_aabb,_dw) then
   return _dw
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

function detectandresolvehit(_attack,_actor)
 -- detect
 local _dx,_dy=collideaabbs(isaabbscolliding,_attack,_actor,0,0)
 if _dx != 0 or _dy != 0 then
  del(attacks,_attack)
  _actor.afflic=_attack.afflic
  _actor.hp-=1
  add(fxs,getfx(227,_attack.x,_attack.y,8,split'7'))

  -- resolve
  if _attack.knockback then
   _actor.knockbackangle=_attack.a
  end
  if _actor.isenemy and _actor.bleeding == nil and _actor.hp/_actor.maxhp < .5 then
   _actor.maxhp*=.5
   _actor.bleeding=true
  end

  if _actor.bleeding then
   for _i=1,flr((_actor.maxhp/2-_actor.hp)/2) do
    add(fxs,getfx(
     228,
     _attack.x-_attack.hw+flrrnd(4),
     _attack.y-_attack.hh+flrrnd(4),
     16+flrrnd(5),
     _actor.bloodcolors,
     cos(_attack.a)*.5,
     -.25,
     0,
     .05))
   end
  end
 end
end


-- helpers

function dist(_x1,_y1,_x2,_y2)
 local _dx,_dy=_x2-_x1,_y2-_y1
 return sqrt(_dx*_dx+_dy*_dy)
end

function haslos(_x1,_y1,_x2,_y2)
 local _dx,_dy,_x,_y,_xinc,_yinc=
  abs(_x2-_x1),abs(_y2-_y1),_x1,_y1,sgn(_x2-_x1),sgn(_y2-_y1)
 local _n,_err=1+_dx+_dy,_dx-_dy
 _dx*=2
 _dy*=2

 while _n > 0 do
  _n-=1
  if walls[flr(_y/8)][flr(_x/8)] != 0 then
   return
  end
  if _err > 0 then
   _x+=_xinc
   _err-=_dy
  else
   _y+=_yinc
   _err+=_dx
  end
 end
 return true
end

-- drawing funcs

function sortony(_t)
 for _i=1,#_t do
  local _j=_i
  while _j > 1 and _t[_j-1].y+(_t[_j-1].hh or 4) > _t[_j].y+(_t[_j].hh or 4) do -- todo: make cleaner
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

function getfxcolor(_fx)
 return _fx.colors[flr(#_fx.colors*((_fx.dur-_fx.durc)/_fx.dur))+1]
end

function drawfx(_fx)
 pal(1,getfxcolor(_fx))
 spr(_fx.s,_fx.x-4,_fx.y-4)
 pal()
end

function getsflip(_angle)
 return _angle >= .375 and _angle <= .625
end

-- creators

function getfx(_s,_x,_y,_dur,_colors,_vx,_vy,_ax,_ay)
 return {
  s=_s,
  x=_x,y=_y,
  dur=_dur,durc=_dur,
  colors=_colors,
  vx=_vx or 0,vy=_vy or 0,
  ax=_ax or 0,ay=_ay or 0,
  draw=drawfx,
 }
end

getfirefx_colors=split'14,14,8'
function getfirefx(_x,_y)
 if rnd() > .25 then
  return getfx(
   228,
   _x,_y,
   10,
   getfirefx_colors,
   0,-.0125,
   0,-.0375)
 end
end

----

create_icewall_colors=split'6,6,6,6,6,6,13'
function create_icewall(_a,_x,_y)
 local _dw={
  x=_x+cos(_a.a)*6,y=_y+sin(_a.a)*6,
  hw=4,hh=4,
  }
 add(dynwalls,_dw)
 add(attacks,{
  x=999,y=999,
  durc=120,
  hw=0,hh=0,
  onmiss=function()
   del(dynwalls,_dw)
  end
  })
 add(fxs,getfx(229,_dw.x,_dw.y,120,create_icewall_colors))
end

function addfissure(_a,_x,_y,_dur)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=3,
  hw=8,hh=8,
  durc=_dur,
  draw=function()
   if rnd() < .5 then
    circfill(_x,_y,5,2)
   end
  end,
  update=function()
   add(fxs,getfirefx(_x-4+rnd(8),_y-4+rnd(8)))
  end,
  })
end

-- damage,ice,fyre,stun,venom,fear
affliccolors=split'2,12,14,10,11,13'

quickfxcolors={
 split'6,6,4,1', -- mundane
 split'7,7,7,12,13', -- ice
 split'7,14,15,15,14,14', -- fyre
 split'7,7,13,2', -- knockback

 -- split'3,3,3,11,11,10', -- venom
 -- split'4,4,10,10,10,7', -- stun
}

function getswordattack(_actor,_afflic)
 local _x,_y=_actor.x+cos(_actor.a)*6,_actor.y-1+sin(_actor.a)*6
 add(fxs,getfx(240+atodirections(_actor.a)*8,_x,_y,12,quickfxcolors[_afflic]))
 return {
  isenemy=_actor.isenemy,
  x=_x,y=_y,
  a=_actor.a,
  afflic=_afflic,
  hw=4,hh=4,
  durc=2,
 },_x,_y
end

swordskills={
 function (_actor) -- 1 - mundane
  local _a=getswordattack(_actor,1)
  add(attacks,_a)
 end,

 function (_actor) -- 2 - icewall
  local _a,_x,_y=getswordattack(_actor,2)
  _a.onmiss=function(_attack)
   create_icewall(_attack,_x,_y)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 3 - fire fissure
  local _a,_x,_y=getswordattack(_actor,3)
  _a.onmiss=function(_attack)
   addfissure(_attack,_x,_y,80)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - knockback
  local _a=getswordattack(_actor,4)
  _a.knockback=true
  add(attacks,_a)
 end
}

function missile_update(_attack)
 _attack.x+=cos(_attack.a)*_attack.missile_spd
 _attack.y+=sin(_attack.a)*_attack.missile_spd
end

function arrow_onmiss_factory(_afflic)
 return function(_attack)
  add(fxs,getfx(227,_attack.x,_attack.y,6,quickfxcolors[_afflic]))
 end
end

function arrow_draw_factory(_color)
 return function(_attack)
  pal(1,_color)
  spr(248+atodirections(_attack.a)*8,_attack.x-4,_attack.y-4)
  pal()
 end
end

function getbowattack(_actor,_afflic)
 return {
  isenemy=_actor.isenemy,
  x=_actor.x+cos(_actor.a)*6,
  y=_actor.y-1+sin(_actor.a)*6,
  a=_actor.a,
  afflic=_afflic,
  hw=2,hh=2,
  durc=_actor.bow_c,
  wallaware=true,
  missile_spd=2,
  update=missile_update,
 }
end

bowskills={
 function (_actor) -- 1 - mundane
  local _a=getbowattack(_actor,1)
  _a.draw,_a.onmiss=arrow_draw_factory(4),arrow_onmiss_factory(1)
  add(attacks,_a)
 end,

 nil, -- 2 - icewall

 function (_actor) -- 3 - fire fissure
  local _a=getbowattack(_actor,3)
  _a.draw=arrow_draw_factory(14)
  local _onmiss=arrow_onmiss_factory(3)
  _a.onmiss=function(_attack)
   _onmiss(_attack)
   addfissure(_attack,_attack.x,_attack.y,80)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - knockback
  local _a=getbowattack(_actor,1)
  _a.draw,_a.onmiss,_a.knockback=arrow_draw_factory(6),arrow_onmiss_factory(4),true
  add(attacks,_a)
 end,
}



frozencolor=split'12,12,12,12,12,12,12,12,12,12,12,12,12,12,12'

function stonethrow_draw(_attack)
 pal(1,13)
 spr(232,_attack.x-4,_attack.y-4)
 pal()
end

function stonethrow(_actor)
 local _a=getbowattack(_actor,1)
 _a.draw,
 _a.onmiss,
 _a.knockback,
 _a.missile_spd,
 _a.hh,_a.hw=
  stonethrow_draw,
  arrow_onmiss_factory(1),
  true,
  1.5,
  3,3

 add(attacks,_a)
end

fireballthrow_update_colors=split'15,14,14,8,2'
function fireballthrow_update(_attack)
 missile_update(_attack)
 add(fxs,getfx(228,_attack.x,_attack.y,6,fireballthrow_update_colors))
end

function fireballthrow_draw(_attack)
 pset(_attack.x,_attack.y,15)
end

function fireballthrow_onmiss(_attack)
 addfissure(_attack,_attack.x,_attack.y,80)
end

function fireballthrow(_actor)
 local _a=getbowattack(_actor,3)
 _a.update,
 _a.draw,
 _a.onmiss,
 _a.missile_spd,
 _a.hh,_a.hw=
  fireballthrow_update,
  fireballthrow_draw,
  fireballthrow_onmiss,
  1.25,
  1.5,1.5

 add(attacks,_a)
end

function staff_mundaneattack(_a)
 _a.staffattack_c+=1
 if _a.staffattack_c >= 16 then
  _a.staffattack_c=0
  swordskills[1](_a)
 end
end

function sword_iceattack(_a)
 local _x,_y=_a.x+cos(_a.a)*6,_a.y-1+sin(_a.a)*6
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  a=_a.a,
  afflic=2,
  hw=4,hh=4,
  durc=2,
  })

 add(fxs,getfx(240+atodirections(_a.a)*8,_x,_y,12,quickfxcolors[2]))
end

function staff_iceboltattack(_a)
 local _x,_y=_a.x+cos(_a.a)*6,_a.y-1+sin(_a.a)*6
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  a=_a.a,
  afflic=2,
  hw=3,hh=3,
  durc=999,
  wallaware=true,
  missile_spd=1,
  update=function(_attack)
   missile_update(_attack)
   add(fxs,getfx(232,_attack.x,_attack.y,6,split'7,7,7,12,12,13,13'))
  end,
  onmiss=function(_attack)
   add(fxs,getfx(227,_attack.x+1,_attack.y+1,6,split'7,12'))
  end,
  draw=function(_attack)
   -- todo: rect instead?
   pal(1,7)
   spr(232,_attack.x-4,_attack.y-4)
   pal()
  end,
  })
end

function staff_fireattack(_a)
 _a.staffattack_c+=1
 if _a.staffattack_c >= 16 then
  add(fxs,getfirefx(_a.x-2,_a.y))
  add(fxs,getfirefx(_a.x-1,_a.y))
  add(fxs,getfirefx(_a.x,_a.y))
  _a.staffattack_c=0
  addfissure(_a,_a.x+_a.staffdx-16+rnd(32),_a.y+_a.staffdy-16+rnd(32),80)
 end
end

function setupavatar()
 avatar={
  x=68,y=60,
  a=0,
  hw=1,hh=1,
  ss={
   split'36,37,38,39', -- swordsman
   split'40,41,42,43', -- ranger
   split'44,45,46,47', -- caster
  },
  f=1,
  spd=.5,
  spdfactor=1,
  sflip=nil, -- todo: remove for token hunt
  basecolors=split'15,4,4,4,4,2,13,5',
  hp=5,
  maxhp=5,
  state_c=0,
  draw=drawactor,

  swordattack=swordskills[4],

  bow_c=0,
  bowattack=bowskills[4],

  staffattack_c=0,
  staffdx=0,
  staffdy=0,
  staffattack=staff_fireattack,
  -- staffattack=staff_mundaneattack,
 }
 avatar.s=avatar.ss[1]
end
setupavatar()

function getworld()
 return level == 0 and 1 or flr(level/3.0005)+1
end

level=0

enemybloodcolor=split'8,8,2' -- note: need to be 3



enemytypes={
 { -- ice orcs
  function (_x,_y) -- ice orc stonethrower
   return {
    x=_x,y=_y,
    a=0,
    hw=2,hh=2,
    dx=0,dy=0,
    spd=.375,spdfactor=1,
    s=split'48,49,50,51',
    f=1,
    bow_c=999,
    attack=stonethrow,
    sight=80,
    range=58,
    basecolors=split'12,5,13,2,7',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=6,
    maxhp=6,
    draw=drawactor,
   }
  end,

  function (_x,_y) -- big ice orc
   return {
    x=_x,y=_y,
    a=0,
    hw=3,hh=3,
    dx=0,dy=0,
    spd=.25,spdfactor=1,
    s=split'52,53,54,55',
    f=1,
    attack=swordskills[2],
    sight=64,
    range=8,
    basecolors=split'12,5,13,2,7',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=12,
    maxhp=12,
    draw=drawactor,
   }
  end,

  function (_x,_y) -- ice orc caster
   return {
    x=_x,y=_y,
    a=0,
    hw=3,hh=3,
    dx=0,dy=0,
    spd=.25,spdfactor=1,
    s=split'56,57,58,59',
    f=1,
    attack=staff_iceboltattack,
    sight=90,
    range=64,
    basecolors=split'12,5,13,2,7',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=20,
    maxhp=20,
    draw=drawactor,
   }
  end,
 },
 { -- fire trolls
  function (_x,_y) -- fireball thrower
   return {
    x=_x,y=_y,
    a=0,
    hw=1.5,hh=1.5,
    dx=0,dy=0,
    spd=.5,spdfactor=1,
    s=split'64,65,66,67',
    f=1,
    bow_c=999,
    attack=fireballthrow,
    sight=96,
    range=48,
    basecolors=split'9,2,4,8,13,14',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=4,
    maxhp=4,
    draw=drawactor,
   }
  end,

  function (_x,_y) -- fire troll w club
   return {
    x=_x,y=_y,
    a=0,
    hw=3,hh=3,
    dx=0,dy=0,
    spd=.25,spdfactor=1,
    s=split'68,69,70,71',
    f=1,
    attack=swordskills[4],
    sight=64,
    range=8,
    basecolors=split'9,2,4,8,13,14',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=10,
    maxhp=10,
    draw=drawactor,
   }
  end,

  function (_x,_y) -- fire troll champion
   return {
    x=_x,y=_y,
    a=0,
    hw=3,hh=3,
    dx=0,dy=0,
    spd=.5,spdfactor=1,
    s=split'72,73,74,75',
    f=1,
    attack=swordskills[3],
    sight=56,
    range=10,
    basecolors=split'9,2,4,8,13,14',
    bloodcolors=enemybloodcolor,
    isenemy=true,
    walking=true,
    hp=24,
    maxhp=24,
    draw=drawactor,
   }
  end,
 }
}

function mapinit()
 deathts=nil
 walls,dynwalls,actors,attacks,fxs={},{},{},{},{}
 for _y=0,15 do
  walls[_y]={}
  for _x=0,15 do
   walls[_y][_x]=1
  end
 end

 local _enemycs=split'1,2,3,1,2,3,1,2,3,1,2,3,1,2,3'
 -- local _enemycs=split'5,9,13,5,9,13,5,9,13,5,9,13,5,9,13'
 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)
 local curx,cury,a,enemy_c,enemies,steps,angles=
  avatarx,avatary,0,_enemycs[level] or 0,{},
  split'440,600,420,600,450'[getworld()],
  ({split'0,0.25,-0.25',split'0,0,0,0.25,-0.25',split'0,0,0,0,0,0,0,0.5,0.5,0.25,-0.25',
  split'0,0,0,0,0,0,0,0,0,0.25',split'0,0,0.25'})[getworld()]
 local step_c=steps

 while step_c > 0 do
  a+=angles[flrrnd(#angles)+1]
  local nextx,nexty=curx+cos(a),cury+sin(a)
  
  if nextx > 0 and nextx < 15 and
     nexty > 0 and nexty < 15 then
   if nextx != avatarx or nexty != avatary then
    curx,cury=nextx,nexty
    walls[cury][curx]=0
   end
  end
  step_c-=1
 end

 -- setup enemies
 for _i=1,enemy_c do
  local _x,_y=0,0
  while walls[_y][_x] != 0 do
   _x,_y=flrrnd(15),flrrnd(15)
  end
  _x,_y=_x*8+4,_y*8+4
  local _enemytype=1
  if level%3 == 0 and _i == 1 then
   _enemytype=3
  elseif _i % 3 == 0 or rnd() < .1 then
   _enemytype=2
  end
  add(actors,enemytypes[getworld()][_enemytype](_x,_y))
 end

 -- add warpstone
 warpstone={x=curx*8,y=cury*8,hw=6,hh=6,wx=curx,wy=cury,draw=function()
  spr(226,warpstone.x-4,warpstone.y-4)
  end}
 add(actors,warpstone)

 -- populate actors
 add(actors,avatar)
 -- ...

 -- remove walls around actors
 local _clearingarr=split'-1,-1, 0,-1, 1,-1, -1,0, 0,0, 1,0, -1,1, 0,1, 1,1'
 for _a in all(actors) do
  for _i=1,18,2 do
   local _myx,_myy=flr(_a.x/8)+_clearingarr[_i],flr(_a.y/8)+_clearingarr[_i+1]
   if _myx > 0 and _myx < 15 and
      _myy > 0 and _myy < 15 and walls[_myy][_myx] != 0 then
    walls[_myy][_myx]=0
   end
  end
 end

 if level == 0 then
  walls[avatary][avatarx-1]=230 -- note: house
 end

 warpstone.x+=4
 warpstone.y+=4
 del(actors,warpstone)
 walls[cury][curx]=224

 avatar.iswarping=true
 avatar.afflic=2
 avatar.hp=0.0125


end

function _init()
 mapinit()
end

update60_curenemyi=1
function _update60()

 if deathts and t() > deathts and btnp(4) then
  level=0
  setupavatar()
  mapinit()
 end

 if avatar.hp <= 0 then
  if deathts == nil then
   deathts=t()+2
  end
  return -- dead
 end

 if avatar.iswarping then
  avatar.hp+=0.05
  if avatar.hp >= avatar.maxhp then
   avatar.iswarping=nil
   avatar.afflic=nil
  end
  return
 end

 if warpstone.iswarping then
  function _godownaworld()
   dset(63,max(dget(63),level))
   level=getworld()*3+1
   mapinit()
  end
  if level == 15 then
   if btnp(2) then
    level=0
    mapinit()
   end
  elseif level == 0 then
   if btnp(1) then
    level+=1
    mapinit()
   end
  elseif level%3 == 0 then
   if btnp(3) then
    _godownaworld()
   end
  elseif dget(63) > level then
   if btnp(3) then
    _godownaworld()
   elseif btnp(1) then
    level+=1
    mapinit()
   end
  elseif btnp(1) then
   level+=1
   mapinit()
  end
  return
 elseif warpstone.istouching and btnp(4) then
  warpstone.iswarping=true
  return
 end

 if avatar.hp >= avatar.maxhp then
  avatar.afflic=nil
  avatar.hp=avatar.maxhp
 end

 -- todo: the filtering does not seem to work properly!
 local _btnmask=band(btn(),0b1111) -- note: filter out o/x buttons from dpad input
 local _angle=btnmasktoa[_btnmask]
 
 if avatar.afflic != 2 and _angle and type(_angle) == 'number' then
  avatar.a=_angle
  avatar.walking=avatar.state != 'readying' and avatar.state != 'striking'

  if avatar.state != 'striking' then
   if _angle >= .375 and _angle <= .625 then
    avatar.sflip=true
   elseif _angle >= .875 or _angle <= .125 then
    avatar.sflip=nil
   end
  end
 else
  avatar.f,avatar.walking=1
 end

 if avatar.afflic == 2 then
  if btnp(4) or btnp(5) then
   avatar.hp+=0.25
  end
 else

  if btn(4) and btn(5) then
   if avatar.iscasting != true then
    avatar.iscasting=true
    avatar.staffdx,avatar.staffdy=0,0
   end
   if _angle then
    local _castingspeed=.25
    avatar.staffdx+=norm(cos(avatar.a))*_castingspeed
    avatar.staffdy+=norm(sin(avatar.a))*_castingspeed
   end
   avatar.state='readying'
   avatar.state_c=1
   avatar.s=avatar.ss[3]
   avatar.attack=function() end
   avatar.staffattack(avatar)

  elseif btnp(4) then
   avatar.state='readying'
   avatar.state_c=6
   avatar.s=avatar.ss[1]
   avatar.attack=avatar.swordattack
  elseif btn(5) then
   avatar.bow_c+=1
   avatar.state='readying'
   avatar.state_c=1
   avatar.s=avatar.ss[2]
   avatar.attack=avatar.bowattack
  end

  if avatar.state == 'readying' and avatar.state_c <= 0 then
   avatar.state='striking'
   avatar.state_c=28
   avatar.attack(avatar)
   avatar.bow_c=0
   avatar.iscasting=nil
   avatar.ireadyingbow=nil
  elseif avatar.state_c <= 0 then
   avatar.state=nil
  end
 end

 update60_curenemyi+=1
 if update60_curenemyi > #actors then
  update60_curenemyi=1
 end
 local _enemy=actors[update60_curenemyi]
 if _enemy and _enemy.isenemy then
  local _disttoavatar,_haslostoavatar=
   dist(_enemy.x,_enemy.y,avatar.x,avatar.y),
   haslos(_enemy.x,_enemy.y,avatar.x,avatar.y)

  if _enemy.afflic == 1 then
   _enemy.hp+=.0075
  end

  if _enemy.afflic == 2 then
   _enemy.hp+=.025

  elseif _enemy.afflic == 3 and _enemy.state == nil then
   _enemy.a+=rnd(.01)-.005
   if rnd() < .05 then
    _enemy.a+=.5
   end
   _enemy.spdfactor=1.5
   _enemy.walking=true

  elseif _enemy.state then
   if _enemy.state == 'readying' and _enemy.state_c <= 0 then
    _enemy.state='striking'
    _enemy.state_c=40

    _enemy.attack(_enemy)
   else
    if _enemy.state_c <= 0 then
     _enemy.state=nil
    end
   end

  elseif _haslostoavatar and
    _disttoavatar < _enemy.range*.375 and
    not _enemy.wallcollisiondx then
   -- debug('run away from avatar')
   _enemy.spdfactor=1
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)+.5

  elseif _haslostoavatar and _disttoavatar < _enemy.range then
   -- debug('attack avatar')
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)

   if not _enemy.state then
    _enemy.state='readying'
    _enemy.state_c=36
   end
   
  elseif _haslostoavatar and
    _disttoavatar < _enemy.sight and
    _disttoavatar > _enemy.range then
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
 end

 -- update actors
 for _a in all(actors) do
  local _spdfactor=_a.spd*(_a.spdfactor or 1)
  local _dx,_dy=0,0

  if _a.walking and _a.afflic != 2 then
   -- set sflip
   _a.sflip=getsflip(_a.a)

   -- set walk frame
   _a.f+=_spdfactor*.375
   if _a.f >= 3 then
    _a.f=1
   end

   -- calc deltas
   if _a == avatar then
    _dx,_dy=norm(cos(_a.a))*_spdfactor,norm(sin(_a.a))*_spdfactor
   else
    _dx,_dy=cos(_a.a)*_spdfactor,sin(_a.a)*_spdfactor
   end

  else
   -- set stand frame
   _a.f=1
  end

  -- update state
  if _a.state then
   _dx,_dy,_a.f=0,0,_a.state == 'readying' and 3 or 4
   _a.state_c-=1
  end

  -- update afflictions
  if _a.afflic and _enemy.hp >= _enemy.maxhp then
   _enemy.afflic=nil
  end
  _a.colors=_a.basecolors
  if _a.afflic == 1 then
   _a.hp+=0.0075
  elseif _a.afflic == 2 then
   _a.colors=frozencolor
   _dx,_dy=0,0
  elseif _a.afflic == 3 then
   if _dx == 0 and _dy == 0 then
    _a.hp-=.0125
   else
    _a.hp+=.025
   end
   add(fxs,getfirefx(_a.x-2+rnd(4),_a.y-3+rnd(3)))
  else
   _a.colors=_a.basecolors
  end

  if _a.knockbackangle then
   _dx,_dy=_dx+cos(_a.knockbackangle)*6,_dy+sin(_a.knockbackangle)*6
   _a.knockbackangle=nil
  end
  -- movement check against walls
  local _postcolldx,_postcolldy=collideaabbs(isinsidewall,_a,nil,_dx,_dy)
  _a.wallcollisiondx,_a.wallcollisiondy=nil
  if _postcolldx != _dx or _postcolldy != _dy then
   _a.wallcollisiondx,_a.wallcollisiondy=_dx,_dy
  end
  _dx,_dy=_postcolldx,_postcolldy

  -- move
  -- _a.x=mid(0,_a.x+_dx,128) -- todo: add this when adding wallwarping
  -- _a.y=mid(0,_a.y+_dy,128)
  _a.x+=_dx
  _a.y+=_dy

  -- add bleed fx
  if _a.bleeding then
   add(fxs,getfx(
    228,
    _a.x,_a.y,
    4+flrrnd(2),
    {_a.bloodcolors[1]},
    0,0,
    0,.075))
   if rnd() < 0.025 then
    add(fxs,getfx(
     228,
     _a.x,
     _a.y,
     240,
     {_a.bloodcolors[3]}))
   end
  end
 end

 -- update attacks
 for _a in all(attacks) do
  _a.durc-=1

  if _a.x <= 0 or _a.x >= 128 or _a.y <= 0 or _a.y >= 128 then
   _a.durc=0
  end

  if _a.wallaware then
   local _postcolldx,_postcolldy=collideaabbs(isinsidewall,_a,nil,0,0)
   if _postcolldx != 0 or _postcolldy != 0 then
    _a.durc=0
   end
  end

  if _a.durc <= 0 then
   if _a.onmiss then
    _a.onmiss(_a)
   end
   del(attacks,_a)
  else
   if _a.update then
    _a.update(_a)
   end
   if _a.isenemy then
    detectandresolvehit(_a,avatar)
   else
    for _actor in all(actors) do
     if _actor.isenemy then
      detectandresolvehit(_a,_actor)
     end
    end
   end
  end
 end

 -- update fxs
 for _fx in all(fxs) do
  if not _fx.durc then
   _fx.durc=_fx.dur
  end

  _fx.vx+=_fx.ax
  _fx.vy+=_fx.ay
  _fx.x+=_fx.vx
  _fx.y+=_fx.vy

  _fx.durc-=1
  if _fx.durc <= 0 then
   del(fxs,_fx)
  end
 end

 -- remove dead actors
 local _enemycount=0
 for _a in all(actors) do
  if _a.hp and _a.hp <= 0 or
   _a.x <= 0 or _a.x >= 128 or _a.y <= 0 or _a.y >= 128 then -- note: intentional ice wall kill bug
   del(actors,_a)
  elseif _a.isenemy then
   _enemycount+=1
  end
 end

 if _enemycount == 0 then
  walls[warpstone.wy][warpstone.wx]=225

  warpstone.istouching=nil
  if isaabbscolliding(avatar,warpstone) then
   warpstone.istouching=true
  end

  if rnd() < .125 then
   add(fxs,getfx(228,warpstone.x-2+rnd(4),warpstone.y+3-rnd(5),30,split'12,3,1',0,0,0,-.0125))
  end
 end
end

function _draw()
 cls()

 if warpstone.iswarping then
  rectfill(warpstone.x-3,0,warpstone.x+3,warpstone.y+4,7)
  local _str='\f6  ➡️\n⬇️'
  if level == 15 then
   _str='\n\f3⬆️'
  elseif level >= 13 or level == 0 then
   _str='\f6  ➡️'
  elseif level%3 == 0 then
   _str='\n\f6⬇️'
  elseif level >= dget(63) then
   _str='\f6  ➡️'
  end
  ?_str,warpstone.x-3,warpstone.y
  warpstone.draw()
  return
 end

 if avatar.hp < avatar.maxhp then
  local _clipsize=128*(avatar.hp/avatar.maxhp)
  local _y=mid(0,avatar.y-_clipsize/2,128-_clipsize)
  cls(affliccolors[avatar.afflic])
  if avatar.hp <= 0 then
   spr(231,avatar.x-4,avatar.y-6)
   if deathts and t() > deathts then
    ?'\f0🅾️⌂',56,122
   end
  end
  clip(mid(0,avatar.x-_clipsize/2,128-_clipsize),_y,_clipsize+1,_clipsize+1)
  rectfill(0,0,128,128,0)
 end

 -- debug draw attacks
 -- for _a in all(attacks) do
 --  rect(_a.x-_a.hw,_a.y-_a.hh,_a.x+_a.hw,_a.y+_a.hh,8)
 --  pset(_a.x,_a.y,8)
 -- end

 -- draw attack areas
 for _attack in all(attacks) do
  if _attack.draw then
   _attack.draw(_attack)
  end
 end

 -- draw walls
 if level == 0 then
  pal(13,3)
 end
 for _y=0,#walls do
  for _x=0,#walls[_y] do
   local spr1=(getworld()-1)*4
   if walls[_y][_x] != 0 then
    _x8=_x*8
    _y8=_y*8

    if walls[_y][_x] != 1 then
     spr1=walls[_y][_x]
    elseif walls[_y+1] != nil and walls[_y+1][_x] != 1 then
     if (_y + _x) % 7 == 0 then
      spr1+=2
     elseif (_y + _x) % 9 == 0 then
      spr1+=3
     else
      spr1+=1
     end
    end

    spr(spr1,_x8,_y8)
   end
  end
 end
 pal()

 -- draw things in scene
 local _things=tconcat(actors,fxs)
 sortony(_things)
 for _thing in all(_things) do
  _thing.draw(_thing)
 end

 -- draw actors
 -- sortony(actors)

 -- local _iscollide=isaabbscolliding(avatar,warpstone)

 -- for _a in all(actors) do
 --  _a.draw(_a)

  -- rect(_a.x-_a.hw,_a.y-_a.hh,_a.x+_a.hw,_a.y+_a.hh,_iscollide and 8 or 12)
  -- pset(_a.x,_a.y,7)
  -- pset(_a.x,_a.y+_a.hh,9)
 -- end

 -- draw fxs
 -- sortony(fxs)
 -- for _fx in all(fxs) do
 --  _fx.draw(_fx)
 -- end

 -- debug draw dynwalls
 -- for _dw in all(dynwalls) do
 --  rect(_dw.x-_dw.hw,_dw.y-_dw.hh,_dw.x+_dw.hw,_dw.y+_dw.hh,4)
 --  pset(_dw.x,_dw.y,4)
 -- end

 if avatar.iswarping then
  pal(split'7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,',1)
  pal(0,1,1)
 end

 -- draw warpstone gui
 if warpstone.istouching then
  print('\f7\#0🅾️✽',mid(0,warpstone.x-7,110),warpstone.y+6)
 end

 function drawskillactionbtns(_itemnr)
  -- todo: add dget
  local _itemskill=1
  local _swordskill=1
  local _bowskill=0
  local _staffskill=1
  local _skillactionbtns={
   _itemskill == _swordskill,
   _itemskill == _bowskill,
   _itemskill == _staffskill,
  }

  local _x=split'63,75,87,99,111,12,24,36,63,75,87,99,111,12,24,36'[_itemnr]
  local _y=split'24,24,24,24,24,116,116,116,116,116,116,116,116,24,24,24'[_itemnr]

  pal{1,1,1,1}
  spr(19+_itemnr,_x,_y-19)
  pal()

  for _i=1,3 do
   if _skillactionbtns[_i] then
    spr(232+_i,_x,_y)
    _y+=3
   end
  end
 end

 -- custom pause screen
 if btn(6) then
  pal()
  cls(0)
  rectfill(0,42,128,85,4)

  spr(233,12,89)
  spr(234,24,89)
  spr(235,36,89)

  for _i=1,16 do
   drawskillactionbtns(_i)
  end

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
22222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222003300000043000000030000000000000033300000000400000003000000330003332200002210000033200003302200
22222222000000000000000000000500034230000433200004434300030403000341320000004000000043000000430003221200044311000224110001231100
22222222022022220222002202502522032230000131200004030200044133000331220003040000000403000002100003241200000031000220110000321000
22222222020022200220002002055220003300000313000000332000023322000022200000300000004020000020100002111200040311000220110000243000
22222222000000000000000000050000000000000032000000030000000000000000000001020000033300000200000000222000040310000220110000321000
22222222220222020002220222025202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222200220022002200220025002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03302000002220000043000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04403000020002000234200000443000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000
03302000020020000200100004433300000000000000000000003300000000000000040000000400000000000000040000005000000050000066650000000050
02330200004300000011000000322000000010300000103000001700000010000000104000001040000014000000104000001500000015000067165000001050
00220100003300000000000000020000008877300088773000887000008877330006774000067740000777400007774000077750000777500006770500077750
00000000000000000000000000000000008876000088760000887000068870000006740000067400000674000006704000067605000676050000700000067650
00000000000000000000000000000000000262000006260000626200666202000002620000062000000262000002620000026200000626000002020000626250
00000000000000000000000000000000001110000011100000111000001110000000000000000000000000504000000400000000000000000000000000000000
00000000000000000000000000000000031110000311100000111000001110000000050000000500000000304444454400000000000000000000000000000000
00000000000000000000000000000000231110002311100022111110021112110001130000011300000110304444434000000000000000000000000000000000
03311000033110003311000000001100232222002322220022222110222222110001130000011300010110100441134000000000000000000000000000000000
03311000033110003311000000001100112221101122211011222000221120000044430000444300042222300041130000000000000000000000000000000000
01222100012221001122100000022210112221101122211011333300221133330042210000422100044224300002210000000000000000000000000000000000
00222000002220000022200000222000222220002222200022222000222220000041230000412300044224000001230000000000000000000000000000000000
00202000000200000020000000002000200020000220000020002000200020000442230044422300044224000002230000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002220000022200060222000002220600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000602120006021200060212000002120600000000000000000000000000000000
00000000000000000000000000000000000300000003000000000000000000000652110006521100065211000002110600000000000000000000000000000000
00000000000000000000000000000000000311000003110003311100000000000655550006555500115555000055551100000000000000000000000000000000
00041000000410000040100000000100000311000003110000021100000011001152521111525211115252110555551100000000000000000000000000000000
00012100000121000011200000002210000122100001221000022200000011001125251111252511022525110225250000000000000000000000000000000000
00002000000020000000210000012000000222000002220000022200000222000222220002222200022222002222220000000000000000000000000000000000
00010100000010000001000000000100000202000000200000020200002221330200020000220000020002000000020000000000000000000000000000000000
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
00000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000800000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000004004080000000040040800000000400405000000004004070000000000000000000000000000000000000000000000000000000000000000000000000
00000004dd408000000004dd405000000004dd408000000004dd4070000000000000000000000000000000000000000000000000000000000000000000000000
0000000ddd00500000000ddd00800000000ddd00500000000ddd0050000000000000000000000000000000000000000000000000000000000000000000000000
0000000ddd00800000000ddd00500000000ddd00500000000ddd0070000000000000000000000000000000000000000000000000000000000000000000000000
00000222d2205000000222d2205000000222d2205000000222d22050000000000000000000000000000000000000000000000000000000000000000000000000
0000222dedd0500000222dedd0500000222dedddd00000222dedd050000000000000000000000000000000000000000000000000000000000000000000000000
0000222dddd0500000222dddddd00000222dddddd00000222dddd050000000000000000000000000000000000000000000000000000000000000000000000000
0000222dddddd00000222dddddd00000222ddd20500000222dddddd0000000000000000000000000000000000000000000000000000000000000000000000000
0000222dddddd00000222ddd20500000222ddd20500002222dddddd0000000000000000000000000000000000000000000000000000000000000000000000000
0000222ddd20500000222ddd20500000222ddd20800d02222ddd2050000000000000000000000000000000000000000000000000000000000000000000000000
0000222ddd20500d00222ddd20800000222ddd20500d0222dddd2050000000000000000000000000000000000000000000000000000000000000000000000000
000d2221dd20800d0d222dd1205000002221dd205000d222d1dd2070000000000000000000000000000000000000000000000000000000000000000000000000
0d0d2221d1205000d2222d112050000d2221d1208000222dd1d10050000000000000000000000000000000000000000000000000000000000000000000000000
00d02221d12050000222dd1000800dd02221d1205000222d11d00050000000000000000000000000000000000000000000000000000000000000000000000000
00000d00d00080000000dd00005000000d00d0000000000d00d00070000000000000000000000000000000000000000000000000000000000000000000000000
00000500500050000000500000000000050050000000000500507787700000000000000000000000000000000000000000000000000000000000000000000000
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
00005000000050000000500000000000000000000000700000051500066666600000000000000000000000000000000000000000000000000000000000000000
0000550000005500000055000000000000000000000777000055120066666666000000000e8888000f9999000e88999000000000000000000000000000000000
00051500000575000005050000011000000000000007717005551110d666666d00000000e8111880f9191990e811919900000000000000000000000000000000
00055500000555000005550000111100000000000077177055551111d11611dd0001100088181820999199408818199400000000000000000000000000000000
00515500005755000050550000111100000010000077177055500111d11611dd0001100088111220991914408811914400000000000000000000000000000000
0055550000555500005555000001100000000000077777775502201166d1d6600000000002222200044444000222444000000000000000000000000000000000
005515500055755000550550000000000000000077177171002222000d6d6d000000000000000000000000000000000000000000000000000000000000000000
00555550005555500055555000000000000000007177171102222220060606000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000000000000001000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000010000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001100111100000000000000001111000110000011000010000001000011000000000000000000000000000000000000000000000000000000000000000000
00001100001110000011110000011100000110000011110001111110001111000000000000001000000010000001000000000000000010000000100000010000
00001100000111000111111000111000000110000001110000111100001110000000110000010000000010000000100000001100000100000000100000001000
00011000000110001000000100011000000011000000100000000000000100000000000000000000000000000000000000000000000000000000000000000000
