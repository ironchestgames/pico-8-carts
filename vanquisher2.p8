pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- vanquisher of evil 2 1.0-alpha
-- by ironchest games

--[[

todo:

- add sfxs

- try dimensions skill
sword: teleport enemy away, higher skill further away
bow: arrow split in perpendicular arrows, more splits with higher skill
staff: create an incasing room from the avatar and out, create it when released

 - make all afflictions with mundane attacks be larger index than the other ones

--]]

--[[

afflictions:
1 - bruised
2 - frozen
3 - burning
4 - stunned
5 - envenomed
6 - confused (only player)
7 - holyburn (only enemies)

cartdata layout:
1 - orb
2 - skull
3 - talisman
4 - crown
5 - demon's eye

6 - sword
7 - bow
8 - staff

9 - shield
10- helmet
11- cape
12- armor
13- boots

14- amulet
15- ring
16- jewel

62 - last boss kills
63 - level completion (boss levels only: 3,6,9,12)

button mask:
-- [0x0001]=0.5, -- left
-- [0x0002]=0, -- right
-- [0x0004]=0.25, -- up
-- [0x0005]=0.375, -- up/left
-- [0x0006]=0.125, -- right/up
-- [0x0008]=0.75, -- down
-- [0x0009]=0.625, -- left/down
-- [0x000a]=0.875, -- down/right

--]]


-- misc setup

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

-- _decisiondebug_laststr=''
-- function decisiondebug(_str)
--  if _str != _decisiondebug_laststr then
--   _decisiondebug_laststr=_str
--   debug(t()..', '.._str)
--  end
-- end

cartdata'ironchestgames_vvoe2_v1_dev1'

-- debug: reset
-- for _i=1,16 do -- inventory
--  dset(_i,0)
-- end
-- dset(62,0) -- evil kills
-- dset(63,0) -- last level cleared

poke(0x5f5c, -1) -- set auto-repeat delay for btnp to none

btnmasktoa=split'0.5,0,,0.25,0.375,0.125,,0.75,0.625,0.875'
confusedbtnmasktoa=split'0,0.5,,0.75,0.875,0.625,,0.25,0.125,0.375'


-- utils

function flrrnd(_n)
 return flr(rnd(_n))
end

function norm(n)
 return n == 0 and 0 or sgn(n)
end

-- function tconcat(_t1,_t2)
--  local _t={}
--  for _i in all(_t1) do
--   add(_t,_i)
--  end
--  for _i in all(_t2) do
--   add(_t,_i)
--  end
--  return _t
-- end

function lmerge(_t1,_t2)
 for _k,_v in pairs(_t2) do
  _t1[_k]=_v
 end
 return _t1
end

function sortony(_t)
 for _i=1,#_t do
  local _j=_i
  while _j > 1 and _t[_j-1].y+(_t[_j-1].hh or 4) > _t[_j].y+(_t[_j].hh or 4) do -- todo: make cleaner
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end


-- collision funcs

function ismiddleinsideaabb(_a,_b)
 return _a.x > _b.x-_b.hw and _a.x < _b.x+_b.hw and _a.y > _b.y-_b.hh and _a.y < _b.y+_b.hh
end

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

isinsidewall_wallabb={hw=4,hh=4}
function isinsidewall(_aabb)
 local _mapx,_mapy=flr(_aabb.x/8),flr(_aabb.y/8)
 if walls[_mapy][_mapx] != 0 then
  isinsidewall_wallabb.x,
  isinsidewall_wallabb.y=
   _mapx*8+4,
   _mapy*8+4
  return isinsidewall_wallabb
 end

 for _dw in all(dynwalls) do
  if ismiddleinsideaabb(_aabb,_dw) then
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
  _dx=(.0001+_collidedwith.hw-abs(_aabb.x-_collidedwith.x))*-_sgndx
 end

 collideaabbs_aabb.x,collideaabbs_aabb.y=_aabb.x,_aabb.y+_dy
 _collidedwith=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dy=(.0001+_collidedwith.hh-abs(_aabb.y-_collidedwith.y))*-_sgndy
 end

 return _dx,_dy
end

detectandresolvehit_fxcolors=split'7'
function detectandresolvehit(_attack,_actor)
 -- detect
 local _dx,_dy=collideaabbs(isaabbscolliding,_attack,_actor,0,0)

  -- resolve
 if _dx != 0 or _dy != 0 then
  _actor.afflic=_attack.afflic
  _actor.hp-=1

  if _attack.onhit then
   _attack.onhit(_attack,_actor)
  end

  del(attacks,_attack)
  add(fxs,getfx(227,_attack.x,_attack.y,8,detectandresolvehit_fxcolors))

  if _attack.knockback then
   _actor.knockbackangle=_attack.a or atan2(_actor.x-_attack.x,_actor.y-_attack.y)
  end

  if _actor.bleeding then
   local _s=228
   if _actor.hp <= 1 then
    _s=232
   end
   for _i=1,flr(_actor.maxhp-_actor.hp) do
    add(fxs,getfx(
     _s,
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


-- geometry

function atodirections(_a)
 return flr((_a%1)*8)/8 -- todo: maybe %1 is not needed
end

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

function getrandomfloorpos()
 local _x,_y=1,1
 while walls[flr(_y/8)][flr(_x/8)] != 0 do
  _x,_y=rnd(120),rnd(120)
 end
 -- todo: add dynwalls?
 return _x,_y
end


-- drawing funcs

drawactor_affliccolors={
 [2]=split'12,12,12,12,12,12,12,12,12,12,12,12,12,12,12',
 [5]=split'3,3,3,11,3,11,11,11,11,11,11,11,3,11,11',
 [7]=split'6,6,6,15,6,15,15,15,15,15,15,15,6,15,15',
}
function drawactor(_a)
 local _affliccolors=drawactor_affliccolors[_a.afflic]
 if _affliccolors then
  pal(_affliccolors)
 end
 spr(_a.s[flr(_a.f)],_a.x-4,_a.y-(8-_a.hh),1,1,_a.sflip)
 if _affliccolors then
  pal()
 end
end


-->8
-- items

itemcolors={
 [0]=split'1,1,1,1', -- (none)
 split'4,5,2,1', -- 1 - mundane
 split'7,12,13,1', -- 2 - ice/icewall
 split'15,14,8,2', -- 3 - fire/fissure
 split'7,10,6,13', -- 4 - stun/lightning
 split'10,11,3,5', -- 5 - venom/spikes
 split'14,8,4,2', -- 6 - healing/leeching
 split'7,7,15,6', -- 7 - holy/revive
 split'7,11,12,3', -- 8 - teleportation
}

function addflooritem(_typ,_skill)
 local _flooritem={
  hw=3,hh=3,
  typ=_typ,
  skill=_skill,
 }
 _flooritem.x,_flooritem.y=getrandomfloorpos()
 add(flooritems,_flooritem)
end

function drawskillactionbtns_getifbtn(_itemnr,_itemskill,_skilltype)
 return _itemnr == _skilltype or
  _itemskill > 1 and _itemskill == dget(_skilltype)
end
function drawskillactionbtns(_itemnr)
 local _itemskill,_x,_y=dget(_itemnr),
  split'63,75,87,99,111,12,24,36,63,75,87,99,111,12,24,36'[_itemnr],
  split'24,24,24,24,24,116,116,116,116,116,116,116,116,24,24,24'[_itemnr]

 pal(itemcolors[_itemskill])
 spr(19+_itemnr,_x,_y-19)
 pal()

 spr(175+_itemskill,_x,_y-8)

 for _i=6,8 do
  if drawskillactionbtns_getifbtn(_itemnr,_itemskill,_i) then
   spr(227+_i,_x,_y) -- note: sprite is offset to accomodate _i
   _y+=3
  end
 end
end


-->8
-- fxs

function drawfx_getfxcolor(_fx)
 return _fx.colors[flr(#_fx.colors*((_fx.dur-_fx.durc)/_fx.dur))+1]
end
function drawfx(_fx)
 pal(1,drawfx_getfxcolor(_fx))
 spr(_fx.s,_fx.x-4,_fx.y-4)
 pal()
end
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

function drawfxpset(_fx)
 pset(_fx.x,_fx.y,drawfx_getfxcolor(_fx))
end
function getpsetfx(_x,_y,_dur,_colors,_vx,_vy,_ax,_ay)
 return {
  x=_x,y=_y,
  dur=_dur,durc=_dur,
  colors=_colors,
  vx=_vx,vy=_vy,
  ax=_ax,ay=_ay,
  draw=drawfxpset,
 }
end

function getfirefx(_x,_y)
 return getpsetfx(_x,_y,11,itemcolors[3],0,-.0125,0,-.0375)
end

getlightningstrikefx_colors=split'7,7,10,5'
function getlightningstrikefx(_x,_y)
 if rnd() > .25 then
  return getpsetfx(_x,_y,14,getlightningstrikefx_colors,0,0,0,-.0375)
 end
end

function addteleportfx(_s,_x,_y)
 add(fxs,getfx(_s,_x,_y,15,itemcolors[8]))
end


-->8
-- attack funcs

function missile_update(_attack)
 _attack.x+=cos(_attack.a)*_attack.missile_spd
 _attack.y+=sin(_attack.a)*_attack.missile_spd
end

addicewall_colors=split'6,6,6,6,6,6,13'
function addicewall(_a,_x,_y,_lvl)
 local _durc,_dw=_lvl*12,{
  x=_x+cos(_a.a)*6,y=_y+sin(_a.a)*6,
  hw=4,hh=4,
 }
 add(dynwalls,_dw)
 local _fx=getfx(229,_dw.x,_dw.y,_durc,addicewall_colors)
 _fx.isfloor=true
 add(fxs,_fx)
 add(attacks,{
  x=1,y=1,
  durc=_durc,
  hw=0,hh=0,
  onmiss=function()
   del(dynwalls,_dw)
  end
  })
end

function addfissure(_a,_x,_y,_lvl)
 local _lvl=max(1,_lvl*.75)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=3,
  hw=_lvl,hh=_lvl,
  durc=80,
  draw=function(_attack)
   if rnd() < .5 then
    circfill(_x,_y,_lvl,2)
   end
  end,
  update=function(_attack)
   if rnd() < .5 then
    add(fxs,getfirefx(_x-_lvl+rnd(_lvl*2),_y-_lvl+rnd(_lvl*2)))
   end
  end,
  })
end

function lightningfx_draw(_fx)
 for _i=2,#_fx.xs do
  line(_fx.xs[_i-1],_fx.ys[_i-1],_fx.xs[_i],_fx.ys[_i],
   rnd()>.5 and (_i%3==0 and 10 or 7) or 5)
 end
end
function addlightningstrike(_a,_x,_y)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=4,
  hw=8,hh=8,
  durc=12,
  draw=function()
   circfill(_x,_y,5,5)
  end,
  update=function()
   add(fxs,getlightningstrikefx(_x-4+rnd(8),_y-4+rnd(8)))
  end,
 })
 local _xs,_ys,_cury={_x},{_y},_y
 while _cury > 0 do
  add(_xs,_x-6+rnd(12))
  _cury=mid(0,_cury-(4+rnd(8)),_y)
  add(_ys,_cury)
 end
 add(fxs,{
  dur=12,durc=12,
  x=0,y=0,vx=0,vy=0,ax=0,ay=0,
  xs=_xs,ys=_ys,
  draw=lightningfx_draw,
 })
end

addvenomspikes_colors=split'0,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,0'
function addvenomspikes(_a,_lvl,_x,_y)
 local _durc=_lvl*45
 local _fx=getfx(238,_x,_y,_durc,addvenomspikes_colors)
 _fx.isfloor=true
 add(fxs,_fx)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=5,
  knockback=true,
  hw=4,hh=4,
  durc=_durc,
  onhit=function()
   _fx.durc=8
  end,
 })
end


-->8
-- sword attacks

function getswordattack(_actor,_afflic)
 local _x,_y=_actor.x+cos(_actor.a)*6,_actor.y-1+sin(_actor.a)*6
 add(fxs,getfx(
  240+atodirections(_actor.a)*8,
  _x,_y,
  12,
  _actor.isenemy and itemcolors[_afflic] or itemcolors[dget(6)]))
 return {
  isenemy=_actor.isenemy,
  x=_x,y=_y,
  a=_actor.a,
  afflic=_afflic,
  hw=4,hh=4,
  durc=2,
 }
end

swordskills={
 function (_actor) -- 1 - bruise
  add(attacks,getswordattack(_actor,1))
 end,

 function (_actor) -- 2 - freeze/icewall
  local _a=getswordattack(_actor,2)
  local _x,_y=_a.x,_a.y
  _a.onmiss=function(_attack)
   if _actor.swordskill_level then
    addicewall(_attack,_x,_y,_actor.swordskill_level)
   end
  end
  add(attacks,_a)
 end,

 function (_actor) -- 3 - fire/fissure
  local _a=getswordattack(_actor,3)
  local _x,_y=_a.x,_a.y
  _a.onmiss=function(_attack)
   addfissure(_attack,_x,_y,_actor.swordskill_level or 7)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - stun/lightning strike
  add(attacks,getswordattack(_actor,4))
  if _actor.skill_hit then
   addlightningstrike(_actor,8+rnd(112),8+rnd(112))
  end
 end,

 function (_actor) -- 5 - venom/spikes
  local _a=getswordattack(_actor,5)
  _a.onmiss=function(_attack)
   addvenomspikes(_attack,_actor.swordskill_level,_attack.x,_attack.y)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 6 - healing/leeching
  local _a=getswordattack(_actor,6)
  _actor.swordskill_level=12
  _a.onhit=function()
   _actor.hp+=0.0312*_actor.swordskill_level*.75
  end
  add(attacks,_a)
 end,

 function (_actor) -- 7 - holy/revive
  add(attacks,getswordattack(_actor,7))
 end,

 function (_actor) -- 8 - teleport
  local _a=getswordattack(_actor,8)
  _a.onhit=function(_attack,_enemy)
   addteleportfx(208,_actor.x,_actor.y-3)
   -- todo: add safe teleport?
   local _a=rnd()
   _actor.x=_enemy.x+cos(_a)*6
   _actor.y=_enemy.y+sin(_a)*6
   addteleportfx(208,_actor.x,_actor.y-3)
  end
  add(attacks,_a)
 end,

}


-->8
-- bow attacks

function bowattack_teleportupdate(_attack)
 if isinsidewall(_attack) then
  add(fxs,getpsetfx(_attack.x,_attack.y,10,teleport_colors,0,0,0,0))
 end
 missile_update(_attack)
end

function getbowattack(_actor,_afflic,_itemcolorsi)
 return {
  isenemy=_actor.isenemy,
  x=flr(_actor.x+cos(_actor.a)*6),
  y=flr(_actor.y-1+sin(_actor.a)*6),
  a=_actor.a,
  afflic=_afflic,
  hw=2,hh=2,
  durc=_actor.bow_c,
  wallaware=true,
  missile_spd=2,
  update=missile_update,
  onmiss=function(_attack)
   add(fxs,getfx(227,_attack.x,_attack.y,6,itemcolors[_itemcolorsi or _afflic]))
  end,
  draw=function(_attack)
   pal(1,_actor.basecolors[2])
   spr(248+atodirections(_attack.a)*8,_attack.x-4,_attack.y-4)
   pal()
  end,
 }
end

bowskills={
 function (_actor) -- 1 - bruise
  add(attacks,getbowattack(_actor,1))
 end,

 function (_actor) -- 2 - icewall
  local _a=getbowattack(_actor,2)
  local _onmiss=_a.onmiss
  _a.onmiss=function(_attack)
   if _actor.bowskill_level then
    addicewall(_attack,_attack.x,_attack.y,_actor.bowskill_level)
   end
   _onmiss(_attack)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 3 - fire fissure
  local _a=getbowattack(_actor,3)
  local _onmiss=_a.onmiss
  _a.onmiss=function(_attack)
   _onmiss(_attack)
   addfissure(_attack,_attack.x,_attack.y,_actor.bowskill_level)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - stun/lightning
  local _a=getbowattack(_actor,4)
  add(attacks,_a)
 end,

 function (_actor) -- 5 - venom/spikes
  local _a=getbowattack(_actor,5)
  _a.onmiss=function(_attack)
   addvenomspikes(_attack,_actor.bowskill_level,_attack.x,_attack.y)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 6 - healing
  local _a=getbowattack(_actor,1,6)
  _a.onhit=function(_attack,_enemy)
   if _enemy.hp <= 0 then
    add(attacks,{
     isenemy=true,
     x=_a.x,y=_a.y,
     hh=3,hw=3,
     durc=450,
     onhit=function()
      add(fxs,getfx(227,_a.x,_a.y,6,itemcolors[6]))
      avatar.hp+=2
      avatar.afflic=1
     end,
     draw=function(_attack)
      if _attack.durc > 120 or _attack.durc%4 < 2 then
       spr(239,_attack.x-4,_attack.y-4)
      end
     end,
    })
   end
  end
  add(attacks,_a)
 end,

 function (_actor) -- 7 - holy
  add(attacks,getbowattack(_actor,7))
 end,

 function(_actor) -- 8 - teleport
  local _a=getbowattack(_actor,1,8)
  _a.update=bowattack_teleportupdate
  _a.wallaware=nil
  add(attacks,_a)
 end,
}


-->8
-- staff attacks

function addcastingfx()
 for _i=-2,1 do
  add(fxs,getpsetfx(avatar.x+_i,avatar.y+1,12+rnd(8),itemcolors[dget(8)],0,-.375,0,0))
 end
end

function addcastingmarkerfx()
 add(fxs,getpsetfx(
  avatar.x+avatar.staffdx,
  avatar.y+avatar.staffdy,
  5,
  itemcolors[dget(8)],
  .5-rnd(1),.5-rnd(1),0,0))
end

staffskills={
 function (_actor) -- 1 - bruise
  _actor.staffattack_c+=1
  if _actor.staffattack_c >= 16 then
   _actor.staffattack_c=0
   swordskills[1](_actor)
  end
 end,

 function (_a) -- 2 - ice
  _a.staffattack_c+=1
  if _a.staffattack_c >= 32 then
   addcastingfx()
   iceboltattack(_a)
   _a.staffattack_c=0
  end
 end,

 function (_a) -- 3 - fire
  _a.staffattack_c+=1
  if _a.staffattack_c >= 32-_a.staffskill_level then
   addcastingfx()
   addfissure(_a,_a.x+_a.staffdx-8+rnd(16),_a.y+_a.staffdy-8+rnd(16),_a.staffskill_level)
   _a.staffattack_c=0
  end
  addcastingmarkerfx()
 end,

 function (_a) -- 4 - lightning
  _a.staffattack_c+=1
  _a.staffskill_level=8
  if _a.staffattack_c >= 50-_a.staffskill_level*3 then
   addcastingfx()
   addlightningstrike(_a,8+rnd(112),8+rnd(112))
   _a.staffattack_c=0
  end
 end,

 function (_actor) -- 5 - venomspikes
  _actor.staffattack_c+=1
  if  _actor.staffattack_c >= 14 then
   addcastingfx()
   addvenomspikes(_actor,min(_actor.staffskill_level*.5,3),
    _actor.x+_actor.staffdx,_actor.y+_actor.staffdy)
   _actor.staffattack_c=0
  end
  addcastingmarkerfx()
 end,

 function (_actor) -- 6 - healing
  _actor.staffattack_c+=1
  if _actor.staffattack_c >= 56-_actor.staffskill_level*3 then
   addcastingfx()
   _actor.hp+=0.5
   _actor.staffattack_c=0
  end
 end,

 function (_actor) -- 7 - holy
  _actor.staffattack_c+=1
  if _actor.staffattack_c >= 56-_actor.staffskill_level*3 then
   addcastingfx()
   _actor.hp+=0.5
   _actor.staffattack_c=0
  end
 end,

 function (_a) -- 8 - teleport
  _a.staffattack_c+=1
  if _a.staffattack_c >= 16 then
   addcastingfx()
   _a.staffattack_c=0
  end
  addcastingmarkerfx()
 end,
}


-->8
-- enemy attacks

function stonethrow_draw(_attack)
 pal(1,13)
 spr(232,_attack.x-4,_attack.y-4)
 pal()
end
function stonethrow(_actor)
 local _a=getbowattack(_actor,_actor.stonethrow_afflic)
 _a.draw,
 _a.knockback,
 _a.missile_spd,
 _a.hh,_a.hw=
  stonethrow_draw,
  true,
  1.5,
  3,3

 add(attacks,_a)
end

function enemyattack_freeze(_actor)
 add(attacks,getswordattack(_actor,2))
end

function enemyattack_stunandknockback(_actor)
 local _a=getswordattack(_actor,4)
 _a.knockback=true
 add(attacks,_a)
end

function enemyattack_venomandknockback(_actor)
 local _a=getswordattack(_actor,5)
 _a.knockback=true
 add(attacks,_a)
end

function fireballthrow_update(_attack)
 missile_update(_attack)
 add(fxs,getpsetfx(_attack.x,_attack.y,6,itemcolors[3],0,0,0,0)) -- todo: use firefx instead?
end
function fireballthrow_onmiss(_attack)
 addfissure(_attack,_attack.x,_attack.y,5)
end
function fireballthrow(_actor)
 local _a=getbowattack(_actor,3)
 _a.update,
 _a.onmiss,
 _a.missile_spd,
 _a.hh,_a.hw=
  fireballthrow_update,
  fireballthrow_onmiss,
  1.25,
  1.5,1.5

 add(attacks,_a)
end

function venomspit_attack_update(_attack)
 missile_update(_attack)
 add(fxs,getpsetfx(_attack.x,_attack.y,6,itemcolors[5],0,0,0,0))
end
function venomspit_attack(_actor)
 local _a=getbowattack(_actor,5)
 _a.update,
 _a.missile_spd,
 _a.hh,_a.hw=
  venomspit_attack_update,
  1.25,
  1.5,1.5

 add(attacks,_a)
end

function boltskillfactory(_afflic,_colors)
 return function (_a)
  local _x,_y=_a.x+cos(_a.a)*6,_a.y-1+sin(_a.a)*6
  add(attacks,{
   isenemy=_a.isenemy,
   x=_x,y=_y,
   a=_a.a,
   afflic=_afflic,
   hw=3,hh=3,
   durc=999,
   wallaware=true,
   missile_spd=1,
   update=function(_attack)
    missile_update(_attack)
    -- todo: tokenhunt?
    add(fxs,getpsetfx(_attack.x,_attack.y,rnd(6),_colors,0,0,0,0))
    add(fxs,getpsetfx(_attack.x,_attack.y+1,rnd(6),_colors,0,0,0,0))
    add(fxs,getpsetfx(_attack.x+1,_attack.y+1,rnd(6),_colors,0,0,0,0))
    add(fxs,getpsetfx(_attack.x+1,_attack.y,rnd(6),_colors,0,0,0,0))
   end,
   onmiss=function(_attack)
    add(fxs,getfx(227,_attack.x+1,_attack.y+1,6,_colors))
   end,
   draw=function(_attack)
    rectfill(_attack.x,_attack.y,_attack.x+1,_attack.y+1,_colors[1])
   end,
  })
 end
end

iceboltattack=boltskillfactory(2,itemcolors[2])
fireboltattack=boltskillfactory(3,itemcolors[3])
venomboltattack=boltskillfactory(5,itemcolors[5])
enemyattack_confusionball=boltskillfactory(6,split'9,9,4,2')

function enemy_lightningstrikeattack(_a)
 addlightningstrike(_a,avatar.x,avatar.y)
end

function lastboss_teleport(_a)
 addteleportfx(209,_a.x,_a.y-3)
 _a.x,_a.y=getrandomfloorpos()
 addteleportfx(209,_a.x,_a.y-3)
end

function enemy_rollingattacks(_actor)
 _actor.attacks[_actor.cur_attack](_actor)
 _actor.cur_attack+=1
 if _actor.cur_attack > #_actor.attacks then
  _actor.cur_attack=1
 end
end


-->8
-- misc enemy funcs

function enemy_summonstone(_a)
 if _a.afflic != 2 then
  _a.summoningc+=1
  if #actors < 16 and _a.summoningc > 300 then
   _a.summoningc=0
   local _summonee=_a.summonees[1]
   if rnd() < .25 then
    _summonee=_a.summonees[2]
   end
   add(actors,lmerge(getenemybase(_a.x,_a.y),_summonee))
  end
 end
 drawactor(_a)
end

function enemyondeath(_actor)
 for _i=-2,3 do
  add(fxs,getfx(rnd(split'228,232,249,251'),_actor.x+_i,_actor.y,14,_actor.bloodcolors,0,-.125,0,rnd(.0625)))
 end
end

function bossondeath(_actor)
 for _i=0,.875,.125 do
  local _vx,_vy=cos(_i),sin(_i)
  add(fxs,getfx(227,_actor.x,_actor.y,40,_actor.bloodcolors,_vx,_vy,_vx*-.025,_vy*-.025))
 end
end

function lastbossondeath(_actor)
 bossondeath(_actor)
 -- todo: token hunt, specialise for last boss only
 local _sgetystart,_sgetyend,_sgetxstart,_sgetxend=81,64,60,74
 local _xoff=(_sgetxend-_sgetxstart)/2
 for _y=_sgetyend-_sgetystart,0 do
  for _x=0,_sgetxend-_sgetxstart do
   local _col=sget(_sgetxstart+_x,_sgetystart+_y)
   if _col != 0 then
    add(fxs,getpsetfx(
     _actor.x-_xoff+_x,
     _actor.y+_y,
     200+rnd(60),
     {_col,_col,_col,1},
     0,-rnd()*.025,
     0,0))
   end
  end
 end
end


-->8
-- enemy types

function getenemybase(_x,_y)
 return {
  -- need to haves:
  -- s=split'48,49,50,51',
  -- basecolors=split'12,5,13,2,7',
  -- maxhp=6,
  -- spd=.375
  -- attack=stonethrow,

  -- defaults
  hw=2,hh=2,
  sight=64,
  range=8,
  bow_c=999,
  bloodcolors=split'8,8,2',
  ondeath=enemyondeath,

  -- internals
  x=_x,y=_y,
  a=0,
  dx=0,dy=0,
  f=1,
  isenemy=true,
  walking=true,
  spdfactor=1,
  draw=drawactor,
 }
end

skeletonarcher={
 s=split'100,101,102,103',
 hp=6,maxhp=6,
 bloodcolors=split'7,7,6',
 spd=.375,
 basecolors=split',4', -- note: arrow color
 attack=bowskills[1],
 sight=80,
 range=58,
}

enemytypes={

 -- ice orcs
 {
  { -- ice orc stonethrower
   s=split'48,49,50,51',
   maxhp=12,
   spd=.375,
   attack=stonethrow,
   stonethrow_afflic=1,
   sight=80,
   range=58,
   hh=3,
  },

  { -- big ice orc
   s=split'52,53,54,55',
   maxhp=16,
   spd=.25,
   attack=enemyattack_freeze,
   hw=3,hh=3,
  },

  { -- ice orc caster
   s=split'56,57,58,59',
   maxhp=20,
   spd=.25,
   attack=iceboltattack,
   sight=90,
   range=64,
   ondeath=bossondeath,
  },

  { -- bear (stun)
   s=split'60,61,62,63',
   maxhp=16,
   spd=.25,
   attack=enemyattack_stunandknockback,
   hw=3,hh=3,
  },
 },

 -- battle trolls
 {
  { -- troll w club
   s=split'68,69,70,71',
   maxhp=10,
   spd=.25,
   attack=enemyattack_stunandknockback,
   hw=3,hh=3,
  },

  { -- troll stonethrower (stun)
   s=split'64,65,66,67',
   maxhp=10,
   spd=.375,
   attack=stonethrow,
   stonethrow_afflic=4,
   sight=80,
   range=58,
  },

  { -- fire troll champion
   s=split'72,73,74,75',
   maxhp=24,
   spd=.5,
   attack=enemyattack_stunandknockback,
   hw=3,hh=3,
   sight=56,
   range=10,
   ondeath=bossondeath,
  },

  { -- fireball thrower
   s=split'76,77,78,79',
   maxhp=6,
   spd=.5,
   basecolors=split',14', -- note: arrow color
   attack=fireballthrow,
   hw=1.5,hh=1.5,
   sight=96,
   range=48,
  },
 },

 -- venomous beasts
 {
  { -- venom spitting snake
   s=split'80,81,82,83',
   maxhp=6,
   spd=.5,
   basecolors=split',11', -- note: arrow color
   attack=venomspit_attack,
   sight=80,
   range=58,
   hw=3,
  },

  { -- venomspike-tailed lizard
   s=split'84,85,86,87',
   maxhp=16,
   spd=.375,
   attack=enemyattack_venomandknockback,
   hw=3,
  },

  { -- poison druid
   s=split'88,89,90,91',
   maxhp=20,
   spd=.375,
   attacks={
    function(_a)
     addvenomspikes(_a,5,getrandomfloorpos())
    end,
    venomboltattack,
    venomboltattack,
   },
   cur_attack=1,
   attack=enemy_rollingattacks,
   sight=90,
   range=64,
   ondeath=bossondeath,
  },

  { -- ice vulture
   s=split'92,93,94,95',
   maxhp=16,
   spd=.25,
   attack=enemyattack_freeze,
   hw=3,
  },
 },

 -- skeletons
 {
  skeletonarcher,

  { -- skeleton summoning gravestone
   s=split'236,236,236,236',
   maxhp=32,
   bloodcolors=split'13,13,5',
   spd=0,
   attack=function() end,
   draw=enemy_summonstone,
   summoningc=0,
   summonees={
    { -- skeleton knight
     s=split'96,97,98,99',
     hp=10,maxhp=10,
     bloodcolors=split'7,7,6',
     spd=.25,
     attack=swordskills[1],
    },
    skeletonarcher,
   },
  },

  { -- skeleton queen
   s=split'104,105,106,107',
   maxhp=20,
   bloodcolors=split'7,7,6',
   spd=.125,
   attack=enemyattack_confusionball,
   sight=90,
   range=64,
   ondeath=bossondeath,
  },

  { -- venomous bat
   s=split'108,109,110,111',
   maxhp=4,
   spd=.75,
   attack=enemyattack_venomandknockback,
  },
 },

 -- devils
 {
  { -- big devil
   s=split'112,113,114,115',
   maxhp=12,
   spd=.5,
   attack=swordskills[3],
   hw=3,hh=3,
   bloodcolors=split'9,9,4',
  },

  { -- evil warpstone
   s=split'237,237,237,237',
   maxhp=42,
   bloodcolors=split'2,2,1',
   spd=0,
   attack=function() end,
   draw=enemy_summonstone,
   summoningc=140,
   summonees={
    { -- devil thrower
     s=split'116,117,118,119',
     hp=2,maxhp=2,
     spd=.5,
     basecolors=split',11', -- note: arrow color
     attack=fireballthrow,
     hw=1.5,hh=1.5,
     sight=96,
     range=48,
     bloodcolors=split'9,9,4',
    },
    { -- devil fighter
     s=split'120,121,122,123',
     hp=4,maxhp=4,
     bloodcolors=split'9,9,4',
     spd=.375,
     attack=swordskills[3],
    },
   },
  },

  { -- the evil
   maxhp=52,
   spd=.25,
   hw=3,hh=4,
   sight=128,
   range=86,
   bloodcolors=split'9,9,4',
   ondeath=lastbossondeath,
   attacks={
    fireboltattack,
    iceboltattack,
    fireboltattack,
    venomboltattack,
    fireboltattack,
    enemy_lightningstrikeattack,
    fireboltattack,
    lastboss_teleport,
   },
   cur_attack=1,
   attack=enemy_rollingattacks,
   attack_colors=split'8,12,8,11,8,10,8,7',
   draw=function(_a)
    pal(8,_a.attack_colors[_a.cur_attack])
    sspr(flr(_a.f-1)*15,65,15,18,_a.x-7.5,_a.y-12,15,18,_a.sflip)
    pal()
   end,
  },
  
  { -- devil confusor
   s=split'124,125,126,127',
   maxhp=8,
   bloodcolors=split'9,9,4',
   spd=.25,
   attack=enemyattack_confusionball,
   sight=90,
   range=64,
  },
 },
}

-->8
-- avatar

if dget(6) == 0 then -- note: first session
 dset(6,1)
 dset(7,1)
 dset(8,1)
 dset(9,1)
end

function recalcskills()
 avatar.swordskill_level,avatar.bowskill_level,avatar.staffskill_level=0,0,0
 avatar.reviveitems={}
 for _typ=1,16 do
  local _skill=dget(_typ)
  if _skill == dget(6) then
   avatar.swordskill_level+=1
  end
  if _skill == dget(7) then
   avatar.bowskill_level+=1
  end
  if _skill == dget(8) then
   avatar.staffskill_level+=1
  end

  if _skill == 7 then
   add(avatar.reviveitems,_typ)
  end
 end

 avatar.basecolors=split',,,,15,0,2,4' -- note: should never have no sword, bow, staff, or shield
 local _itemtoskillcolor=split'1,2,2,2,1,4,3,3'
 for _i=1,8 do
  local _skill=dget(5+_i) -- note: offset to sword (6)
  if _skill != 0 then
   avatar.basecolors[_i]=itemcolors[_skill][_itemtoskillcolor[_i]]
  end
 end

 avatar.swordattack=swordskills[dget(6)]
 avatar.bowattack=bowskills[dget(7)]
 avatar.staffattack=staffskills[dget(8)]
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
  hp=5,
  maxhp=5,

  attackstate_c=0,
  draw=function(_a)
   pal(_a.basecolors)
   drawactor(_a)
   pal()
  end,

  skill_c=0,

  bow_c=0,

  staffattack_c=0,
  staffdx=0,
  staffdy=0,
 }
 avatar.s=avatar.ss[1]

 recalcskills()
end
setupavatar()


-->8
-- world

level=0 -- note: always start at home when cart boots up

function getworld()
 return level == 0 and 1 or flr(level/3.0005)+1
end

function mapinit()
 deathts=nil
 walls,dynwalls,actors,attacks,fxs,flooritems={},{},{},{},{},{}
 for _y=0,15 do
  walls[_y]={}
  for _x=0,15 do
   walls[_y][_x]=1
  end
 end

 local _enemycs=split'3,4,5,4,6,7,5,8,12,4,6,6,4,6,6'
 -- local _enemycs=split'1,2,3,1,2,3,1,2,3,1,2,3,1,2,3'
 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)
 local curx,cury,a,enemy_c,steps,angles=
  avatarx,avatary,0,_enemycs[level] or 0,
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
 local _extraenemyc=dget(62)
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
  local _enemy=lmerge(getenemybase(_x,_y),enemytypes[getworld()][_enemytype])
  _enemy.hp=_enemy.maxhp
  add(actors,_enemy)

  if _extraenemyc > 0 then
   local _enemy=lmerge(getenemybase(_x,_y),enemytypes[getworld()][4])
   _enemy.hp=_enemy.maxhp
   add(actors,_enemy)
   _extraenemyc-=1
  end
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
 avatar.hp=.0125

end


-->8
-- system init

function _init()
 mapinit()
end


-- system update

update60_curenemyi=1
update60_enemyattackts=0
function _update60()

 -- dead
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

 -- warping
 if avatar.iswarping then
  avatar.hp+=.05
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
  if btnp(5) then
   warpstone.iswarping=nil
  end
  if level == 15 then
   if btnp(2) then
    dset(62,dget(62)+1) -- note: exploitable
    dset(63,0)
    level=0
    mapinit()
   end
  elseif level == 0 then
   if dget(63) != 0 and btnp(3) then
    level=dget(63)+1
    mapinit()
   elseif btnp(1) then
    level=1
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

 -- player input
 -- todo: the filtering does not seem to work properly!
 local _btnmask=band(btn(),0b1111) -- note: filter out o/x buttons from dpad input
 local _angle=btnmasktoa[_btnmask]

 avatar.spdfactor=1
 if avatar.afflic == 6 then
  _angle=confusedbtnmasktoa[_btnmask]
  if avatar.walking then
   avatar.hp+=.0312
  end
 end

 if avatar.touchingitem and btnp(4) then
  local _tmpskill=dget(avatar.touchingitem.typ)
  dset(avatar.touchingitem.typ,avatar.touchingitem.skill)
  avatar.touchingitem.skill=_tmpskill
  if _tmpskill == 0 then
   del(flooritems,avatar.touchingitem)
  else
   avatar.touchingitem.x+=-.5+rnd(1)
   avatar.touchingitem.y+=-.5+rnd(1)
  end
  recalcskills()
  return
 end
 
 if avatar.afflic != 2 and _angle and type(_angle) == 'number' then
  avatar.a=_angle
  avatar.walking=avatar.attackstate != 'readying' and avatar.attackstate != 'striking'

  if avatar.attackstate != 'striking' then
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
   avatar.hp+=.25
  end
 else

  if btn(4) and btn(5) then
   if avatar.iscasting != true then
    avatar.iscasting=true
    avatar.staffdx,avatar.staffdy=0,0
   end
   if _angle then
    avatar.staffdx+=norm(cos(avatar.a))
    avatar.staffdy+=norm(sin(avatar.a))
   end
   avatar.attackstate='readying'
   avatar.attackstate_c=1
   avatar.s=avatar.ss[3]
   avatar.attack=function() end
   avatar.staffattack(avatar)
   avatar.hp-=.0096

  elseif btnp(4) then
   avatar.attackstate='readying'
   avatar.attackstate_c=6
   avatar.s=avatar.ss[1]
   avatar.attack=avatar.swordattack
  elseif btn(5) then
   avatar.bow_c+=2
   avatar.attackstate='readying'
   avatar.attackstate_c=1
   avatar.s=avatar.ss[2]
   avatar.attack=avatar.bowattack
  end

  if avatar.attackstate == 'readying' and avatar.attackstate_c <= 0 then
   avatar.skill_hit=nil
   avatar.skill_c+=1
   local _skill_level=avatar.swordskill_level
   if avatar.attack == avatar.bowattack then
    _skill_level=avatar.bowskill_level
   end
   if avatar.skill_c%flr(19/_skill_level) == 0 then
    avatar.skill_hit=true
    avatar.skill_c=0
   end
   avatar.attackstate='striking'
   avatar.attackstate_c=28
   avatar.attack(avatar)

   -- teleport
   if avatar.iscasting and avatar.staffattack == staffskills[8] then
    addteleportfx(208,avatar.x,avatar.y-3)
    avatar.x+=avatar.staffdx
    avatar.y+=avatar.staffdy
    addteleportfx(208,avatar.x,avatar.y-3)
   end

   avatar.bow_c=0
   avatar.iscasting=nil
  elseif avatar.attackstate_c <= 0 then
   avatar.attackstate=nil
  end
 end

 -- enemy decision-making
 update60_curenemyi+=1
 if update60_curenemyi > #actors then
  update60_curenemyi=1
 end
 local _enemy=actors[update60_curenemyi]
 if _enemy and _enemy.isenemy then
  _enemy.spdfactor=1
  local _disttoavatar,_haslostoavatar=
   dist(_enemy.x,_enemy.y,avatar.x,avatar.y),
   haslos(_enemy.x,_enemy.y,avatar.x,avatar.y)

  if _enemy.afflic == 4 then
   _disttoavatar,_haslostoavatar=nil
  end

  if _enemy.afflic == 2 then
   -- decisiondebug('frozen, break free!')
   -- note: frozen, do nothing

  elseif _enemy.afflic == 3 and _enemy.attackstate == nil then
   -- decisiondebug('on fire, run around!')
   _enemy.walking=true
   _enemy.a+=rnd(.01)-.005
   if rnd() < .05 then
    _enemy.a+=.5
   end

  elseif _enemy.attackstate then
   -- decisiondebug('attacking: '.._enemy.attackstate)
   _enemy.walking=nil
   if _enemy.attackstate == 'readying' and _enemy.attackstate_c <= 0 then
    _enemy.attackstate='striking'
    _enemy.attackstate_c=40

    _enemy.attack(_enemy)
   else
    if _enemy.attackstate_c <= 0 then
     _enemy.attackstate=nil
    end
   end

  elseif _enemy.wallcollisiondx == nil and _enemy.moving_c then
   -- decisiondebug('moving, '.._enemy.moving_c)
   _enemy.walking=true
   _enemy.a+=rnd(.01)-.005

  elseif _enemy.wallcollisiondx == nil and _haslostoavatar and
    (_disttoavatar < _enemy.range*.375 or
    (_enemy.afflic == 5 and _disttoavatar < 18) or
    _enemy.afflic == 7) then
   -- decisiondebug('run away from avatar')
   _enemy.walking=true
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)+.5
   _enemy.moving_c=30

  elseif _haslostoavatar and _disttoavatar < _enemy.range then
   -- decisiondebug('attack avatar')

   if t()-update60_enemyattackts > .375 then
    _enemy.targetx,_enemy.targety=avatar.x,avatar.y
    _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)

    if not _enemy.attackstate then
     _enemy.attackstate='readying'
     _enemy.attackstate_c=36
    end

    update60_enemyattackts=t()
   end

  elseif _enemy.afflic == 5 then
   -- decisiondebug('envenomed, stand still!')
   -- note: envenomed, stand still to heal
   _enemy.walking=nil

  elseif _enemy.wallcollisiondx or _enemy.wallcollisiondy then
   -- decisiondebug('move out of wall collision')
   _enemy.walking=true
   if _enemy.afflic != 4 then
    _enemy.a+=rnd()
    _enemy.targetx=nil
    _enemy.moving_c=45
   end
   
  elseif _haslostoavatar and
    _disttoavatar < _enemy.sight and
    _disttoavatar > _enemy.range and not 
    _enemy.moving_c then
   -- decisiondebug('move towards avatar')
   _enemy.walking=true
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   if _disttoavatar < 6 then
    _enemy.a+=.5
   end

  elseif _enemy.targetx and not _enemy.moving_c then
   -- decisiondebug('move towards target')
   _enemy.walking=true
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   local _disttotarget=dist(_enemy.x,_enemy.y,_enemy.targetx,_enemy.targety)
   if _disttotarget < 4 then
    _enemy.targetx=nil
   end

  else -- roam
   -- decisiondebug('roam')
   _enemy.walking=true
   _enemy.a+=rnd(.01)-.005
  end

  if (_enemy.afflic == 1 or _enemy.afflic == nil) and
   not _enemy.targetx then
   _enemy.spdfactor=.25
  end
 end

 -- update actors
 for _a in all(actors) do
  _a.a%=1 -- note: normalise angle

  -- update enemy is moving
  if _a.moving_c then
   _a.moving_c-=1
   if _a.moving_c <= 0 then
    _a.moving_c=nil
   end
  end

  -- set spdfactor
  if _a.afflic == 3 then
   _a.spdfactor=1.375
  elseif _a.afflic == 4 or _a.afflic == 5 then
   _a.spdfactor=.5
  end

  local _spdfactor=_a.spd*_a.spdfactor
  local _dx,_dy=0,0

  if _a.walking and _a.afflic != 2 then
   -- set sflip
   _a.sflip=_a.a >= .2656 and _a.a <= .7344

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

  -- update attackstate
  if _a.attackstate then
   _dx,_dy,_a.f=0,0,_a.attackstate == 'readying' and 3 or 4
   _a.attackstate_c-=1
  end

  -- update afflictions
  if _a.hp >= _a.maxhp then
   _a.afflic=nil
   _a.hp=_a.maxhp
  end
  if _a.afflic == 2 then
   _dx,_dy=0,0
   if _a.isenemy then
    _a.hp+=.025
   end
  elseif _a.afflic == 3 then
   if _dx == 0 and _dy == 0 then
    _a.hp-=.0125
   else
    _a.hp+=.025
   end
   add(fxs,getfirefx(_a.x-2+rnd(4),_a.y-3+rnd(3)))
  elseif _a.afflic == 4 then
   if _a.wallcollisiondx then
    _a.hp+=.05
   end
   add(fxs,getpsetfx(_a.x-2+rnd(2),
    _a.y-_a.hh*2-3,
    5,
    split'7,2,10,2',
    0,0.5,0,0))
  elseif _a.afflic == 5 then
   if _a.walking then
    _a.hp-=.025
   else
    _a.hp+=.025
   end
  elseif _a.afflic == 7 then
   add(fxs,getpsetfx(_a.x-2+rnd(4),_a.y-5+rnd(3),11,itemcolors[7],0,-.0125,0,-.0375))
   _a.hp+=.025
  else -- catch all (other afflictions)
   _a.hp+=.0078
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

  -- add bleeding
  if _a.isenemy and _a.bleeding == nil and _a.hp/_a.maxhp < .5 then
   _a.maxhp*=.5
   _a.bleeding=true
  end

  if _a.bleeding then
   add(fxs,getpsetfx(
    _a.x,_a.y,
    3+flrrnd(2),
    {_a.bloodcolors[1]},
    0,0,
    0,.075,0,0))
   if rnd() < .025 then
    local _fx=getpsetfx(
     _a.x,
     _a.y,
     110,
     {_a.bloodcolors[3]},
     0,0,0,0)
    _fx.isfloor=true
    add(fxs,_fx)
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
    _a.wallcollision,_a.durc=true,0
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
   if _a.ondeath then
    _a.ondeath(_a)
   end
   if _a == avatar then
    _a.hp=0
    if #_a.reviveitems > 0 then
     dset(_a.reviveitems[1],1)
     recalcskills()
     add(actors,_a)
     _a.hp=_a.maxhp
     _a.x,_a.y=getrandomfloorpos()
     add(fxs,getfx(210,_a.x,_a.y,240,itemcolors[7],0,-.125))
     for _i=1,10 do
      add(attacks,{
       x=64,y=64,
       hw=64,hh=64,
       durc=2,
       afflic=4,
       draw=function(_attack)
        cls(7)
       end
      })
     end
    end
   end
  elseif _a.isenemy then
   _enemycount+=1
  end
 end

 -- update warpstone
 if _enemycount == 0 then
  if level > 0 and walls[warpstone.wy][warpstone.wx] != 225 then
   local _typ=rnd(split'6,6,6,7,7,8,8,9,10,11,12,13,14,15,16')
   if level%3 == 2 then
    addflooritem(_typ,rnd(split'1,2,3,4,5,6,7,8')) -- dupe: item drop
   elseif level%3 == 0 then
    addflooritem(_typ,rnd(split'1,2,3,4,5,6,7,8')) -- dupe: item drop
    addflooritem(getworld(),rnd(split'2,3,4,5,6,7,8'))
   end
  end

  walls[warpstone.wy][warpstone.wx]=225

  warpstone.istouching=nil
  if ismiddleinsideaabb(avatar,warpstone) then
   warpstone.istouching=true
  end

  if rnd() < .125 then
   add(fxs,getpsetfx(warpstone.x-2+rnd(4),warpstone.y+3-rnd(5),30,split'12,12,3,1',0,0,0,-.0125))
  end
 end

 -- update flooritems
 avatar.touchingitem=nil
 for _item in all(flooritems) do
  if isaabbscolliding(avatar,_item) then
   avatar.touchingitem=_item
  end
 end
end


-->8
-- system draw

_draw_affliccolors=split'2,12,14,10,3,9'
function _draw()
 cls()

 -- warpstone menu
 if warpstone.iswarping then
  rectfill(warpstone.x-3,0,warpstone.x+3,warpstone.y+4,7)
  local _str='\f6  ➡️\n⬇️'
  if level == 0 and dget(63) > 0 then
   -- pass
  elseif level == 15 then
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

 -- draw player affliction
 if avatar.hp < avatar.maxhp then
  local _clipsize=127*(avatar.hp/avatar.maxhp)
  local _y=mid(0,avatar.y-_clipsize/2,129-_clipsize)
  cls(_draw_affliccolors[avatar.afflic] or 1)
  if avatar.hp <= 0 then
   spr(231,mid(0,avatar.x-4,120),mid(0,avatar.y-6,120))
   if deathts and t() > deathts then
    ?'\f0🅾️⌂',56,122
   end
  end
  clip(mid(0,avatar.x-_clipsize/2,129-_clipsize),_y,_clipsize,_clipsize)
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

 -- draw flooritems
 for _item in all(flooritems) do
  pal(itemcolors[_item.skill])
  spr(19+_item.typ,_item.x-4,_item.y-4)
  pal()
  if avatar.touchingitem == _item then
   print('\f4\#0🅾️',_item.x-4,_item.y-10)
  end
 end

 -- draw things in scene
 -- local _things=tconcat(actors,fxs)
 -- sortony(_things)
 -- for _thing in all(_things) do
 --  _thing.draw(_thing)
 -- end

 -- draw floor fxs
 sortony(fxs)
 for _fx in all(fxs) do
  if _fx.isfloor then
   _fx.draw(_fx)
  end
 end

 -- draw actors

 -- local _iscollide=isaabbscolliding(avatar,warpstone)

 sortony(actors)
 for _a in all(actors) do
  _a.draw(_a)

 -- debug draw actors
 --  rect(_a.x-_a.hw,_a.y-_a.hh,_a.x+_a.hw,_a.y+_a.hh,_iscollide and 8 or 12)
 --  pset(_a.x,_a.y,7)
 --  pset(_a.x,_a.y+_a.hh,9)
 end

 -- draw top fxs
 -- note: fxs already sorted above
 for _fx in all(fxs) do
  if not _fx.isfloor then
   _fx.draw(_fx)
  end
 end

 -- debug draw dynwalls
 -- for _dw in all(dynwalls) do
 --  rect(_dw.x-_dw.hw,_dw.y-_dw.hh,_dw.x+_dw.hw,_dw.y+_dw.hh,4)
 --  pset(_dw.x,_dw.y,4)
 -- end

 -- draw warping
 if avatar.iswarping then
  pal(split'7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,',1)
  pal(0,1,1)
 end

 if warpstone.istouching then
  print('\f7\#0🅾️✽',mid(0,warpstone.x-7,110),warpstone.y+6) -- todo: calc needed?
 end

 -- draw inventory
 if btn(6) then
  pal()
  cls(0)
  rectfill(0,42,128,85,4)
  for _i=1,16 do
   drawskillactionbtns(_i)
  end
 end
end

__gfx__
00dddd0000dddd0000ddd00000000000000000000000000000000000515151501111111111111111111111111111111111111111111111111111111111111111
dddddd00dddddd000ddddd00000ddd00000050000000500000005000515151501111111111111111111111111111111111111111111111111111111111111111
dd5dddd0dd5dddd00ddd5d0000dd6660000551000005510000005000111111111111111111111111111113111111111111111111122122221222442212221222
ddd5d5d0ddd5d5d00d5d5d0000d666d00055511000555110000551005515551511111111dd1ddd1d3d1d3d1ddd1ddd1d11111111122122221242e44212221222
0dd55dd00dd55dd000d5dd000dd66ddd000511000005110000551100111111111111111111111111131133111111111111111111122112221242f44212221122
0d0050d00d0050d00005d000d6d66d6d00551110005511100005510015551555111111111ddd1ddd13dd13dd1ddd1ddd11111111111111111122522111111111
0d0050000d005000000500006666d66d055111110551111100551110111111111111111111111111113131111102020111111111221221222214522221212212
000050000000500000050000000000000000200000002000000020005515551511111111dd1ddd1ddd3d3d1dd102020111111111221221222212212221212212
22222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222002300000012000000020000000000000022200000000100000002000000220002223300003340000022300002203300
22222222000000000000000000000500021430000122300001121200020102000214230000001000000013000000120002334300011224000331440004324400
22222222022022220222002202502522034430000424300001020300011422000224330002010000000102000003400002314300000024000330440000234000
22222222020022200220002002055220003300000242000000223000032233000033300000200000001040000030400003444300010244000330440000312000
22222222000000000000000000050000000000000023000000020000000000000000000004030000023200000300000000333000010240000330440000234000
22222222220222020002220222025202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222200220022002200220025002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02203000003330000012000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01304000030004000321300000112000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000
02203000030040000300400001122200000000000000000000001100000000000000020000000200000000000000020000003000000030000066630000000030
03220300001200000044000000233000000050100000501000005700000050000000502000005020000052000000502000005300000053000067563000005030
00330400002200000000000000030000004477100044771000447000004477110006772000067720000777200007772000077730000777300006770300077730
00000000000000000000000000000000004476000044760000447000064470000006720000067200000672000006702000067603000676030000700000067630
00000000000000000000000000000000000868000006860000686800666808000008680000068000000868000008680000086800000686000008080000686830
0000000000000000dd0000000000000000ccc00000ccc00000ccc00000ccc0000000000000000000000000702000000200000000000000005502424000000000
000cc000000cc000cdc00000000000000dccc0000dccc00000ccc00000ccc0000000070000000700000000d02222272200000000000000002522444500000000
0c5cc0000c5cc000cc5cc0000000cc005dccc0005dccc00055ccccc005ccc5cc000ccd00000ccd00000cc0d022222d2002222200022222002222444402220000
cdd55000cdd55000005cc0000005cc005d5555005d55550055555cc0555555cc000ccd00000ccd000c0cc0c0022ccd2022224240222242400222222022222000
ccd55c00ccd55c0000555000005555cccc555cc0cc555cc0cc55500055cc500000222d0000222d00025555d0002ccd0022224445222244450224225522242400
00500500000550000055550000555000cc555cc0cc555cc0ccdddd0055ccdddd00255c0000255c00022552d000055c0022224444222244442244200522244450
0050050000050000005005000550500055555000555550005555500055555000002c5d00002c5d0002255200000c5d0022222220222222202242000052255445
050005000005000005000500000050005000500005500000500050005000500002255d0022255d000225520000055d0025025050025255002502500000055055
00000000000000000000000000000000000000000000000000000000000000000002220000022200040222000002220400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000402920004029200040292000002920400000000000000000000000000000000
00000000000000000000000000000000000400000004000000000000000000000452990004529900045299000002990400000000000000000000000000000000
0dd990000dd99000dd99000000009900000499000004990004499900000000000455550004555500995555000055559900000000000000000000000000000000
0dd990000dd99000dd99000000009900000499000004990000029900000099009952529999525299995252990555559900089000000890000080900000000900
09222900092229009922900000022290000922900009229000022200000099009925259999252599022525990225250000092900000929000099200000002290
00222000002220000022900000922000000222000002220000022200000222000222220002222200022222002222220000002000000020000000290000092000
00909000000900000090000000009000000909000000900000090900009229440200020000220000020002000000020000090900000090000009000000000900
0000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000004000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005a000000000000000000000000000000004000000002000000000000000000000004e0000000000
000000000000000000bb000000000000a00000000a00000050000000000000000000004000000040000020000000020000000000000000000000400000000000
000000000000000000300000000000005a00000005a00000500000000bb000000000f0200000f0200000f2000030f32005004e0500004e000000400005000050
000000000000000000030000000000005000000050000000055300000bbb00000003332000033320003333200053330205504550000040000005d50005500500
000000bb000000bb000030000000000035553bb035553bb00333bb00353000a0000353200003532000555502005555000055d5000005d500005555500055d4ee
300530300530053000003000300053bb03333bbb03333bbb0303bbb03553305a000353200003532000555500000555000555500000555550050e0e0505555000
053005303005300005353000035300000300303000333000000030300355550000035320000353200005550000055500000e0e00050e0e050000000000e0e000
000000000000000000000000000000000000000000000000000000000000000000000f0000000f0000000f0009000f0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000ff000000ff000090ff000d00ff0000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000009066000090660000d066000d00660700000000000000000000000000000000
00000000000000000000dd00000000000000020000000200000000000000020000d0660000d0660000d066070600660600000000000000000002020000000000
000060d0000060d000006600000060000000602000006020000062000000602000d2207000d22070006222260d22222200220220000000000002020000000000
005566d0005566d000556000005566dd00006620000066200006662000066620006222600062226000d222200d22222000022200000020000002220000002000
005560000055600000556000005560000000620000006200000062000000602000d2220000d2220000d222000022222000002000000222000000200000022200
000606000000600000060600000606000006060000006000000606000006060000d2200002d20000000222000002220000000000000202000000000000220220
00000000000000008800088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000
00e8e00000e8e000880e8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009000000005000
00880000008800002208822000000000000000000000000000000000000000000000000000000000000000000000000000000090000000900000500000000500
2222200022222000222222200022e8e00000000000000000000000000000000000000000000000000000ee000000000000008050000080500000850000d08d50
88222880882228800222220002228800000e8000000e800000e0800000000800000080e0000080e00000880000008000000ddd50000ddd5000dddd50002ddd05
8822288088222880002222000222222000088800000888000088800000008880000888e0000888e000088000000088ee000d2d50000d2d500022220500222200
022220000222200000222800222882880000800000008000000088000008800000008000000080000000800000008000000d2d50000d2d500022220000022200
080080000088000000800800222882880008080000008000000800000000080000080800000080000008080000080800000d2d50000d2d500002220000022200
00000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000800000000000000800000000000000000000004004000dd000000000000000000000000000000000000000000000000000000
000000040040800000000040040800000000040040500000000040040700000004dd4000dd000000000000000000000000000000000000000000000000000000
00000004dd4080000000004dd4050000000004dd4080000000004dd40700000000ddd00ddd000000000000000000000000000000000000000000000000000000
0000000ddd005000000000ddd008000000000ddd005000000000ddd00500000000ddd00dd0000000000000000000000000000000000000000000000000000000
0000000ddd008000000000ddd005000000000ddd005000000000ddd0070000000000000d00000000000000000000000000000000000000000000000000000000
00000222d22050000000222d22050000000222d22050000000222d22050000000ddd220000000000000000000000000000000000000000000000000000000000
0000222dedd05000000222dedd05000000222dedddd000000222dedd050000d00deddd0000000000000000000000000000000000000000000000000000000000
0000222dddd05000000222dddddd000000222dddddd000000222dddd05000dd0ddddddd000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222dddddd000000222ddd205000000222dddddd000d00dddddd2000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222ddd205000000222ddd205000002222dddddd00dd00ddddd12000000000000000000000000000000000000000000000000000000000
0000222ddd205000000222ddd205000000222ddd208000d02222ddd20500dd002dddd11200000000000000000000000000000000000000000000000000000000
0000222ddd205000d00222ddd208000000222ddd205000d0222dddd2050000022dddd11200000000000000000000000000000000000000000000000000000000
000d2221dd208000d0d222dd12050000002221dd2050000d222d1dd2070000021dd1dd1200000000000000000000000000000000000000000000000000000000
0d0d2221d12050000d2222d1120500000d2221d12080000222dd1d100500002111d1dd1120000000000000000000000000000000000000000000000000000000
00d02221d120500000222dd10008000dd02221d12050000222d11d000500002111d11d1120000000000000000000000000000000000000000000000000000000
00000d00d000800000000dd000050000000d00d00000000000d00d070707000000d00d0000000000000000000000000000000000000000000000000000000000
00000500500050000000050000000000000500500000000000500500767000000050050000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222222202222222022222220222222202222222022222220222222200000000000000000000000000000000000000000000000000000000000000000
0000000022272220222e22202ddddd20222222202e828820227f4220222277200000000000000000000000000000000000000000000000000000000000000000
0000000022277220222ee22022272220222b2220288888202777f420222b77200000000000000000000000000000000000000000000000000000000000000000
0000000022777c2022eee220222aa2202b2b222028888820227f422022cbb2200000000000000000000000000000000000000000000000000000000000000000
0000000022777c2022efee20222272202b232b2022888220227f422027cc22200000000000000000000000000000000000000000000000000000000000000000
000000002777cc202eeffe20222272202323232022282220227f4220277222200000000000000000000000000000000000000000000000000000000000000000
00000000222222202222222022222220222222202222222022222220222222200000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000110010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111010001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111110000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000001111010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011100001111010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000011111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010100001001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000050000000500000000000000000000000700000051500066666600000000000000000000000000000000000000000000020000100000000000000
0000550000005500000055000000000000000000000777000055120066666666000000000e8888000f9999000e88999000000000000022000301001000042000
00051500000575000005050000011000000000000007717005551110d666666d00000000e8111880f9191990e811919900ddd100000282000003003000666d00
00055500000555000005550000111100000000000077177055551111d11611dd000110008818182099919940881819940dd1dd100002220010030000000dd000
00515500005755000050550000111100000010000077177055500111d11611dd000110008811122099191440881191440d1d1d10002822003000010000600d00
0055550000555500005555000001100000000000077777775502201166d1d660000000000222220004444400022244400dd1dd10002222000010030000688d00
005515500055755000550550000000000000000077177171002222000d6d6d00000000000000000000000000000000000dd1dd10002282200030030100dddd00
0055555000555550005555500000000000000000717717110222222006060600000000000000000000000000000000000ddddd10002222200000000300000000
00010000000000000000000000000000000001000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000010000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001100111100000000000000001111000110000011000010000001000011000000000000000000000000000000000000000000000000000000000000000000
00001100001110000011110000011100000110000011110001111110001111000000000000001000000010000001000000000000000010000000100000010000
00001100000111000111111000111000000110000001110000111100001110000000110000010000000010000000100000001100000100000000100000001000
00011000000110001000000100011000000011000000100000000000000100000000000000000000000000000000000000000000000000000000000000000000
__label__
00333300003333000033330000333300003333000033330000333300003330000033330000000000003333000033330000333300003333000033300000333300
33333300333333003333330033333300333333003333330033333300033333003333330000033300333333003333330033333300333333000333330033333300
33533330335333303353333033533330335333303353333033533330033353003353333000336660335333303353333033533330335333300333530033533330
33353530333535303335353033353530333535303335353033353530035353003335353000366630333535303335353033353530333535300353530033353530
03355330033553300335533003355330033553300335533003355330003533000335533003366333033553300335533003355330033553300035330003355330
03005030030050300300503003005030030050300300503003005030000530000300503036366363030050300300503003005030030050300005300003005030
03005000030050000300500003005000030050000300500003005000000500000300500066663663030050000300500003005000030050000005000003005000
00005000000050000000500000005000000050000000500000005000000500000000500000000000000050000000500000005000000050000005000000005000
00333300003333000033330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333300
33333300333333003333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333300
33533330335333303353333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033533330
33353530333535303335353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033353530
03355330033553300335533000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003355330
03005030030050300300503000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005030
03005000030050000300500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005000
00005000000050000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000
00333300003333000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333300
33333300333333003333330033333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333300
33533330335333303353333033533330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033533330
33353530333535303335353033353530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033353530
03355330033553300335533003355330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003355330
03005030030050300300503003005030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005030
03005000030050000300500003005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005000
00005000000050000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000333300
33333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000550000000000000000000000000033333300
335333300000000000000000000000000000000000000000000000000000000000000000000000000000000000c5750000000000000000000000000033533330
33353530000000000000000000000000000000000000000000000000000000000000000000000000000000000005550000000000000000000000000033353530
03355330000000000000000000000000000000000000000000000000000000000000000000000000000000000057550000000000000000000000000003355330
03005030000000000000000000000000000000000000000000000000000000000000000000000000000000000055550000000000000000000000000003005030
03005000000000000000000000000000000000000000000000000000000000000000000000000000000000000055755000000000000000000000000003005000
00005000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555000000000000000000000000000005000
00333300000000000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333300
33333300000000003333330033333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333300
33533330000000003353333033533330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033533330
33353530000000003335353033353530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033353530
03355330000000000335533003355330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003355330
03005030000000000300503003005030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005030
03005000000000000300500003005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005000
00005000000000000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000
00333300000000000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000033330000333300
33333300000000003333330033333300000000000000000000000000000000000000000000000000000000000000000000000000000000003333330033333300
33533330000000003353333033533330000000000000000000000000000000000000000000000000000000000000000000000000000000003353333033533330
33353530000000003335353033353530000000000000000000000000000000000000000000000000000000000000000000000000000000003335353033353530
03355330000000000335533003355330000000000000000000000000000000000000000000000000000000000000000000000000000000000335533003355330
03005030000000000300503003005030000000000000000000000000000000000000000000000000000000000000000000000000000000000300503003005030
03005000000000000300500003005000000000000000000000000000000000000000000000000000000000000000000000000000000000000300500003005000
00005000000000000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000005000
00333300000000000033330000000000000000000000000000000000000000000000000000000000000000000000000000000000003333000033330000333300
33333300000000003333330000000000000000000000000000000000000000000000000000000000000000000000000000033300333333003333330033333300
33533330000000003353333000000000000000000000000000000000000000000000000000000000000000000000000000336660335333303353333033533330
33353530000000003335353000000000000000000000000000000000000000000000000000000000000000000000000000366630333535303335353033353530
03355330000000000335533000000000000000000000000000000000000000000000000000000000000000000000000003366333033553300335533003355330
03005030000000000300503000000000000000000000000000000000000000000000000000000000000000000000000036366363030050300300503003005030
03005000000000000300500000000000000000000000000000000000000000000000000000000000000000000000000066663663030050000300500003005000
00005000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000500000005000
00333300000000000000000000000000000000000000000000000000000515000000000000000000000000000000000000000000000000000000000000333300
33333300000000000000000000000000000000000000000000000000005512000000f04000000000000000000000000000000000000000000000000033333300
33533330000000000000000000000000000000000000000000000000055511100055224000000000000000000000000000000000000000000000000033533330
33353530000000000000000000000000000000000000000000000000555511110055200000000000000000000000000000000000000000000000000033353530
03355330000000000000000000000000000000000000000000000000555001110004040000000000000000000000000000000000000000000000000003355330
03005030000000000000000000000000000000000000000000000000550220110000000000000000000000000000000000000000000000000000000003005030
03005000000000000000000000000000000000000000000000000000002222000000000000000000000000000000000000000000000000000000000003005000
00005000000000000000000000000000000000000000000000000000022222200000000000000000000000000000000000000000000000000000000000005000
00333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333300
33333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333300
33533330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033533330
33353530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033353530
03355330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003355330
03005030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005030
03005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003005000
00005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000
00333300003333000033330000000000000000000000000000333300003333000000000000000000000000000000000000333300003333000000000000333300
33333300333333003333330000000000000000000000000033333300333333000000000000000000000000000000000033333300333333000000000033333300
33533330335333303353333000000000000000000000000033533330335333300000000000000000000000000000000033533330335333300000000033533330
33353530333535303335353000000000000000000000000033353530333535300000000000000000000000000000000033353530333535300000000033353530
03355330033553300335533000000000000000000000000003355330033553300000000000000000000000000000000003355330033553300000000003355330
03005030030050300300503000000000000000000000000003005030030050300000000000000000000000000000000003005030030050300000000003005030
03005000030050000300500000000000000000000000000003005000030050000000000000000000000000000000000003005000030050000000000003005000
00005000000050000000500000000000000000000000000000005000000050000000000000000000000000000000000000005000000050000000000000005000
00333300003333000033330000000000000000000000000000000000000000000000000000000000000000000033300000333300000000000000000000333300
33333300333333003333330000000000000000000000000000000000000000000000000000000000000000000333330033333300000000000000000033333300
33533330335333303353333000000000000000000000000000000000000000000000000000000000000000000333530033533330000000000000000033533330
33353530333535303335353000000000000000000000000000000000000000000000000000000000000000000353530033353530000000000000000033353530
03355330033553300335533000000000000000000000000000000000000000000000000000000000000000000035330003355330000000000000000003355330
03005030030050300300503000000000000000000000000000000000000000000000000000000000000000000005300003005030000000000000000003005030
03005000030050000300500000000000000000000000000000000000000000000000000000000000000000000005000003005000000000000000000003005000
00005000000050000000500000000000000000000000000000000000000000000000000000000000000000000005000000005000000000000000000000005000
00333300003333000033330000333300003333000033330000333300003333000033330000333300000000000000000000000000000000000000000000333300
33333300333333003333330033333300333333003333330033333300333333003333330033333300000000000000000000000000000000000000000033333300
33533330335333303353333033533330335333303353333033533330335333303353333033533330000000000000000000000000000000000000000033533330
33353530333535303335353033353530333535303335353033353530333535303335353033353530000000000000000000000000000000000000000033353530
03355330033553300335533003355330033553300335533003355330033553300335533003355330000000000000000000000000000000000000000003355330
03005030030050300300503003005030030050300300503003005030030050300300503003005030000000000000000000000000000000000000000003005030
03005000030050000300500003005000030050000300500003005000030050000300500003005000000000000000000000000000000000000000000003005000
00005000000050000000500000005000000050000000500000005000000050000000500000005000000000000000000000000000000000000000000000005000
00333300003333000033330000333300003333000033330000333300003333000033330000333300000000000000000000000000000000000000000000333300
33333300333333003333330033333300333333003333330033333300333333003333330033333300000000000000000000000000000000000000000033333300
33533330335333303353333033533330335333303353333033533330335333303353333033533330000000000000000000000000000000000000000033533330
33353530333535303335353033353530333535303335353033353530333535303335353033353530000000000000000000000000000000000000000033353530
03355330033553300335533003355330033553300335533003355330033553300335533003355330000000000000000000000000000000000000000003355330
03005030030050300300503003005030030050300300503003005030030050300300503003005030000000000000000000000000000000000000000003005030
03005000030050000300500003005000030050000300500003005000030050000300500003005000000000000000000000000000000000000000000003005000
00005000000050000000500000005000000050000000500000005000000050000000500000005000000000000000000000000000000000000000000000005000
00333300003333000033330000333300003333000033330000333300003333000033330000333300000000000000000000000000000000000000000000333300
33333300333333003333330033333300333333003333330033333300333333003333330033333300000000000000000000000000000000000000000033333300
33533330335333303353333033533330335333303353333033533330335333303353333033533330000000000000000000000000000000000000000033533330
33353530333535303335353033353530333535303335353033353530333535303335353033353530000000000000000000000000000000000000000033353530
03355330033553300335533003355330033553300335533003355330033553300335533003355330000000000000000000000000000000000000000003355330
03005030030050300300503003005030030050300300503003005030030050300300503003005030000000000000000000000000000000000000000003005030
03005000030050000300500003005000030050000300500003005000030050000300500003005000000000000000000000000000000000000000000003005000
00005000000050000000500000005000000050000000500000005000000050000000500000005000000000000000000000000000000000000000000000005000
00333300003333000033330000333300003333000033330000333300003333000033330000333300000000000000000000000000000000000000000000333300
33333300333333003333330033333300333333003333330033333300333333003333330033333300000000000000000000000000000000000000000033333300
33533330335333303353333033533330335333303353333033533330335333303353333033533330000000000000000000000000000000000000000033533330
33353530333535303335353033353530333535303335353033353530333535303335353033353530000000000000000000000000000000000000000033353530
03355330033553300335533003355330033553300335533003355330033553300335533003355330000000000000000000000000000000000000000003355330
03005030030050300300503003005030030050300300503003005030030050300300503003005030000000000000000000000000000000000000000003005030
03005000030050000300500003005000030050000300500003005000030050000300500003005000000000000000000000000000000000000000000003005000
00005000000050000000500000005000000050000000500000005000000050000000500000005000000000000000000000000000000000000000000000005000
00333300003333000033330000333300003333000033330000333300003333000033330000333300003333000033330000333300003333000033330000333300
33333300333333003333330033333300333333003333330033333300333333003333330033333300333333003333330033333300333333003333330033333300
33533330335333303353333033533330335333303353333033533330335333303353333033533330335333303353333033533330335333303353333033533330
33353530333535303335353033353530333535303335353033353530333535303335353033353530333535303335353033353530333535303335353033353530
03355330033553300335533003355330033553300335533003355330033553300335533003355330033553300335533003355330033553300335533003355330
03005030030050300300503003005030030050300300503003005030030050300300503003005030030050300300503003005030030050300300503003005030
03005000030050000300500003005000030050000300500003005000030050000300500003005000030050000300500003005000030050000300500003005000
00005000000050000000500000005000000050000000500000005000000050000000500000005000000050000000500000005000000050000000500000005000

__sfx__
0008000002050020500205003050040500505005050060500705008050090500a0500b0500c0500d0500d0500f050100501105000000000000000000000000000000000000000000000000000000000000000000
