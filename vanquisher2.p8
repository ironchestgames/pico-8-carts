pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- vanquisher of evil 2 1.0-alpha
-- by ironchest games

--[[

todo:

 - skills could use table lookup for skill increase for more and faster control

 - dimensions skill?
 sword: teleport enemy away, higher skill further away
 bow: arrow split in perpendicular arrows, more splits with higher skill
 staff: create an incasing room from the avatar and out, create it when released

 - haste skill? (run 50% faster, a haste_c goes down, +skillevel*hasteconstant to haste counter
 sword: gain haste on hit
 bow: gain haste on hit
 staff: gain haste

 - shadow skill? (enemy sight is greatly reduced, higher skill the more hits until it goes back)
 sword: gain shadow attacks on hit, ceiling is skill level
 bow: gain shadow attacks on hit, ceiling is skill level
 staff: gain shadow, skill level is speed and ceiling

 - change the evils fireballs to be venomfireballs!

 - change the evils staff to blink in attack colors

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

epic items start from 20

cartdata layout:
1 - orb
2 - skull
3 - talisman
4 - crown
5 - demon's eye

6 - shield
7 - helmet
8 - cape
9 - armor
10- boots

11- amulet
12- ring
13- jewel

14- sword
15- bow
16- staff

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

known bugs:
- music continues to play if you die on house level
- 

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

cartdata'ironchestgames_vvoe2_v1_dev2'

-- debug: reset
-- for _i=1,16 do -- inventory
--   dset(_i,0)
-- end
-- dset(62,0) -- evil kills
-- dset(63,0) -- last level cleared

-- dset(14,23)
-- dset(15,23)
-- dset(16,23)
-- dset(6,23)

poke(0x5f5c,-1) -- set auto-repeat delay for btnp to none
poke(0x5f36,0x2) -- allow circ & circfill w even diameter

btnmasktoa=split'0.5,0,,0.25,0.375,0.125,,0.75,0.625,0.875'
confusedbtnmasktoa=split'0,0.5,,0.75,0.875,0.625,,0.25,0.125,0.375'


-- utils

function flrrnd(_n)
 return flr(rnd(_n))
end

function norm(n)
 return n == 0 and 0 or sgn(n)
end

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
 local _xcheck=_a.x > _b.x-_b.hw and _a.x < _b.x+_b.hw
 if _a.topy then
  return _xcheck and _a.topy > _b.y-_b.hh and _a.topy < _b.y+_b.hh, _a.topy
 end
 return _xcheck and _a.y > _b.y-_b.hh and _a.y < _b.y+_b.hh, _a.y
end

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and a.x+a.hw > b.x-b.hw and
  a.y-a.hh < b.y+b.hh and a.y+a.hh > b.y-b.hh and b
end

isinsidewall_wallabb={hw=4,hh=4}
function isinsidewall(_aabb)
 local _mapx,_mapy=flr(_aabb.x/8),flr(_aabb.y/8)
 if walls[_mapy][_mapx] != 0 then
  isinsidewall_wallabb.x,isinsidewall_wallabb.y=_mapx*8+4,_mapy*8+4
  return isinsidewall_wallabb,_aabb.y
 end

 if _aabb.topy then
  _mapx,_mapy=flr(_aabb.x/8),flr(_aabb.topy/8)
  if walls[_mapy][_mapx] != 0 then
   isinsidewall_wallabb.x,isinsidewall_wallabb.y=_mapx*8+4,_mapy*8+4
   return isinsidewall_wallabb,_aabb.topy
  end
 end

 for _dw in all(dynwalls) do
  local _result,_y=ismiddleinsideaabb(_aabb,_dw)
  if _result then
   return _dw,_y
  end
 end
end

collideaabbs_aabb={}
function collideaabbs(_func,_aabb,_other,_dx,_dy)
 _dx,_dy=_dx or 0,_dy or 0
 local _sgndx,_sgndy=sgn(_dx),sgn(_dy)
 collideaabbs_aabb.hw,collideaabbs_aabb.hh=_aabb.hw,_aabb.hh

 collideaabbs_aabb.x,collideaabbs_aabb.y,collideaabbs_aabb.topy=
  _aabb.x+_dx,_aabb.y,_aabb.topy
 local _collidedwith=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dx=(.0001+_collidedwith.hw-abs(_aabb.x-_collidedwith.x))*-_sgndx
 end

 collideaabbs_aabb.x,collideaabbs_aabb.y,collideaabbs_aabb.topy=
  _aabb.x,_aabb.y+_dy,_aabb.topy and _aabb.topy+_dy or nil
 _collidedwith,_aabby=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dy=(.0001+_collidedwith.hh-abs((_aabby or _aabb.y)-_collidedwith.y))*-_sgndy
 end

 return _dx,_dy
end

detectandresolvehit_fxcolors=split'7'
function detectandresolvehit(_attack,_actor)
 -- detect
 local _dx,_dy=collideaabbs(isaabbscolliding,_attack,_actor)

  -- resolve
 if _dx != 0 or _dy != 0 then
  sfx(5)
  _actor.afflic=_attack.afflic
  _actor.hp-=1

  if _attack.onhit then
   _attack.onhit(_attack,_actor)
  end

  _attack.durc=0
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
     _actor.x-_actor.hw+flrrnd(4),
     _actor.y-_actor.hh+flrrnd(4),
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

function isaabbscollidingwith(_aabb,_collection)
 for _item in all(_collection) do
  local _dx,_dy=collideaabbs(isaabbscolliding,_aabb,_item)
  if _dx != 0 or _dy != 0 then
   return _item
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
 ::randomfloorpos::
 local _x,_y=rnd(120),rnd(120)
 if walls[flr(_y/8)][flr(_x/8)] != 0 then
  goto randomfloorpos
 end
 -- todo: add dynwalls?
 return _x,_y
end


-- drawing funcs

drawactor_affliccolors={
 [2]=split'12,12,12,7,12,7,7,7,7,7,7,7,12,7,7',
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
 split'6,4,2,1', -- 1 - mundane
 split'7,6,12,13', -- 2 - ice/icewall
 split'15,14,8,2', -- 3 - fire/fissure
 split'7,10,6,13', -- 4 - stun/lightning
 split'11,3,5,2', -- 5 - venom/spikes
 split'14,8,4,2', -- 6 - healing/leeching
 split'7,7,15,9', -- 7 - holy/revive
 split'7,11,12,3', -- 8 - teleportation
 split'7,6,13,2', -- 9 - deflection
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

function drawinventoryskills_getifbtn(_itemnr,_itemskill,_skilltype)
 return _itemnr == _skilltype or
  _itemskill > 1 and _itemskill == dget(_skilltype)
end
function drawinventoryskills(_itemnr)
 local _itemskill,_x,_y=dget(_itemnr),
  split'63,75,87,99,111,63,75,87,99,111,12,24,36,12,24,36'[_itemnr],
  split'24,24,24,24,24,116,116,116,116,116,24,24,24,116,116,116'[_itemnr]

 pal(itemcolors[_itemskill%20])
 spr((_itemskill > 20 and 35 or 19)+_itemnr,_x,_y-19)
 pal()

 if _itemskill > 20 then
  spr(211,_x-2,_y-10)
 end
 spr(192+_itemskill%20,_x,_y-8)

 for _i=14,16 do
  if drawinventoryskills_getifbtn(_itemnr,_itemskill%20,_i) then
   spr(219+_i,_x,_y) -- note: sprite is offset to accomodate _i
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

getfirefx_draw_r=split'1,1,1,1,1,2,2,2,2.5,2.5,2.5,2,2,1,1,1,1,1'
function getfirefx_draw(_fx)
 circfill(_fx.x,_fx.y,getfirefx_draw_r[_fx.durc],drawfx_getfxcolor(_fx))
end
function getfirefx(_x,_y)
 return {
  x=_x,y=_y,
  dur=16,durc=16,
  colors=itemcolors[3],
  vx=0,vy=0,
  ax=0,ay=-.075,
  draw=getfirefx_draw,
 }
end

getlightningstrikefx_colors=split'7,7,10,5'
function getlightningstrikefx(_x,_y)
 if rnd() > .25 then
  return getpsetfx(_x,_y,14,getlightningstrikefx_colors,0,0,0,-.0375)
 end
end

function addteleportfx(_s,_x,_y)
 add(fxs,getfx(_s,_x,_y,10,itemcolors[8]))
end

function addholyfx(_x,_y)
 add(fxs,getpsetfx(_x,_y,11,itemcolors[7],0,-.0125,0,-.0375))
end


-->8
-- attack funcs

function missile_update(_attack)
 _attack.x+=cos(_attack.a)*_attack.missile_spd
 _attack.y+=sin(_attack.a)*_attack.missile_spd
end

addicewall_colors=split'6,6,6,6,6,6,13'
function addicewall(_x,_y,_lvl)
 local _durc,_dw=12+_lvl*8,{
  x=_x,y=_y,
  hw=4,hh=4,
 }
 if isaabbscollidingwith(_dw,actors) == nil and
   isaabbscollidingwith(_dw,dynwalls) == nil then
  sfx(17)
  add(dynwalls,_dw)
  local _fx=getfx(229,_dw.x,_dw.y,_durc,addicewall_colors)
  _fx.isfloor=true
  add(fxs,_fx)
  add(attacks,{
   x=1,y=1, -- note: outside, this is just to have a counter to remove it in onmiss
   durc=_durc,
   hw=0,hh=0,
   onmiss=function()
    sfx(18)
    del(dynwalls,_dw)
   end
   })
  return true
 end
end

function addfissure(_a,_x,_y,_lvl)
 sfx(21)
 local _lvl=max(1,_lvl*.75)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=3,
  hw=_lvl,hh=_lvl,
  durc=45,
  draw=function(_attack)
   if rnd() < .5 then
    circfill(_x,_y,_lvl,2)
   end
  end,
  update=function(_attack)
   if _attack.durc % 4 == 0 then
    local _myr=_lvl*.5
    add(fxs,getfirefx(_x-_myr+rnd(_myr*2),_y-_myr+rnd(_myr*2)))
   end
  end,
  })
end

function lightningfx_draw(_fx)
 local _rnd=rnd()
 for _i=2,#_fx.xs do
  line(_fx.xs[_i-1],_fx.ys[_i-1],_fx.xs[_i],_fx.ys[_i],
   _rnd > .5 and (_i%3 == 0 and 10 or 7) or 5)
 end
end
function addlightningstrike(_actor,_x,_y)
 sfx(16)
 add(attacks,{
  isenemy=_actor.isenemy,
  islightning=true,
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
  _cury=mid(0,_cury-(6+rnd(8)),_y)
  add(_ys,_cury)
 end
 add(fxs,{
  dur=10,durc=10,
  x=0,y=0,vx=0,vy=0,ax=0,ay=0,
  xs=_xs,ys=_ys,
  draw=lightningfx_draw,
 })
end

addvenomspikes_colors=split'0,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,0'
function addvenomspikes(_a,_lvl,_x,_y)
 sfx(15)
 local _durc=_lvl*20
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
  onmiss=function()
   sfx(20)
  end,
  onhit=function()
   _fx.durc=8
  end,
 })
end

function deflectattack(_x,_y,_size,_durc)
 sfx(27)
 add(fxs,{
  x=_x,y=_y,
  dur=_durc,durc=_durc,
  vx=0,vy=0,ax=0,ay=0,
  draw=function(_fx)
   for _other in all(attacks) do
    if _other.isenemy and dist(_fx.x,_fx.y,_other.x,_other.y) < _size then
     sfx(25)
     if _other.a then
      _other.a-=.5
     end
     _other.isenemy=nil
    end
   end
   circ(_fx.x,_fx.y-2,_size,6)
   fillp(rnd(32768))
   if rnd() < .5 then
    circfill(_fx.x,_fx.y-2,_size,13)
   end
   fillp()
  end,
  })
end


-->8
-- sword attacks

function getswordattack(_actor,_afflic)
 local _x,_y=_actor.x+cos(_actor.a)*6,_actor.y-1+sin(_actor.a)*6
 sfx(3)
 add(fxs,getfx(
  240+atodirections(_actor.a)*8,
  _x,_y,
  12,
  itemcolors[_afflic]))
 return {
  isenemy=_actor.isenemy,
  x=_x,y=_y,
  a=_actor.a,
  afflic=_afflic,
  hw=4,hh=4,
  durc=2,
 }
end

function addbruisingswordattack(_actor)
 add(attacks,getswordattack(_actor,1))
end

addavatarlightningattack_strikesperlevel=split'1,2,3,4,5,6,7,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20'
function addavatarlightningattack(_level)
 for _fx in all(fxs) do
   if _fx.colors == getlightningstrikefx_colors then
    del(fxs,_fx)
   end
  end
  for _attack in all(attacks) do
   if _attack.islightning and not _attack.isenemy then
    del(attacks,_attack)
   end
  end
  for _i=1,addavatarlightningattack_strikesperlevel[_level] do
   addlightningstrike(avatar,8+rnd(120),8+rnd(120))
  end
end

swordskills={
 addbruisingswordattack, -- 1 - bruise

 function (_actor) -- 2 - freeze/icewall
  local _attack=getswordattack(_actor,2)
  if not addicewall(
    _attack.x+cos(_attack.a)*6,
    _attack.y+sin(_attack.a)*6,
    _actor.swordskill_level or 7) then
   add(attacks,_attack)
  end
 end,

 function (_actor) -- 3 - fire/fissure
  local _a=getswordattack(_actor,3)
  _a.onmiss=function(_attack)
   addfissure(_attack,_a.x,_a.y,_actor.swordskill_level or 7)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - stun/lightning strike
  add(attacks,getswordattack(_actor,4))
  addavatarlightningattack(_actor.swordskill_level)
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
  _a.onhit=function()
   _actor.hp+=0.0312*_actor.swordskill_level*.75
   addcastingfx(itemcolors[6])
  end
  add(attacks,_a)
 end,

 function (_actor) -- 7 - holy/revive
  add(attacks,getswordattack(_actor,7))
 end,

 function (_actor) -- 8 - teleport
  local _a=getswordattack(_actor,8)
  _a.onhit=function(_attack,_enemy)
   if _actor.skill_hit then
    addteleportfx(208,_actor.x,_actor.y-3)
    ::newteleport::
    _actor.x,_actor.y,_actor.topy=getnewxyfroma(_enemy.x,_enemy.y,rnd(),6)
    if isinsidewall(_actor) then
     goto newteleport
    end
    addteleportfx(208,_actor.x,_actor.y-3)
    sfx(19)
   end
  end
  add(attacks,_a)
 end,

 function (_actor) -- 9 - deflect
  add(attacks,getswordattack(_actor,9,1))
  deflectattack(
   avatar.x+cos(avatar.a)*8,
   avatar.y+sin(avatar.a)*8,
   3+avatar.swordskill_level*.5,
   16)
 end,
}

function getnewxyfroma(_x,_y,_a,_d)
 local _newy=_y+sin(_a)*_d
 return _x+cos(_a)*_d,_newy,_newy-2
end


-->8
-- bow attacks

function bowattack_teleportupdate(_attack)
 if isinsidewall(_attack) then
  add(fxs,getpsetfx(_attack.x,_attack.y,10,itemcolors[8],0,0,0,0))
 end
 missile_update(_attack)
end

function getbowattack(_actor,_afflic,_itemcolorsi)
 local _onmiss=function(_attack)
  sfx(5)
  add(fxs,getfx(227,_attack.x,_attack.y,6,itemcolors[_itemcolorsi or _afflic]))
 end
 return {
  isenemy=_actor.isenemy,
  x=flr(_actor.x+cos(_actor.a)*2),
  y=flr(_actor.y-2+sin(_actor.a)*2),
  a=_actor.a,
  afflic=_afflic,
  hw=2,hh=2,
  durc=_actor.bow_c,
  wallaware=true,
  missile_spd=2,
  update=missile_update,
  onmiss=_onmiss,
  draw=function(_attack)
   pal(1,_actor.basecolors[2])
   spr(248+atodirections(_attack.a)*8,_attack.x-4,_attack.y-4)
   pal()
  end,
 },_onmiss
end

function addbruisingbowattack(_actor)
 add(attacks,(getbowattack(_actor,1)))
end

bowskills={
 function (_actor) -- 1 - bruise
  addbruisingbowattack(_actor)
 end,

 function (_actor) -- 2 - icewall
  local _a,_onmiss=getbowattack(_actor,2)
  _a.onmiss=function(_attack)
   if not addicewall(_attack.x,_attack.y,_actor.bowskill_level) then
    _onmiss(_attack)
   end
  end
  add(attacks,_a)
 end,

 function (_actor) -- 3 - fire fissure
  local _a,_onmiss=getbowattack(_actor,3)
  _a.onmiss=function(_attack)
   addfissure(_attack,_attack.x,_attack.y,_actor.bowskill_level)
   _onmiss(_attack)
  end
  add(attacks,_a)
 end,

 function (_actor) -- 4 - stun/lightning
  local _a,_onmiss=getbowattack(_actor,4)
  _a.onmiss=function(_attack)
   addavatarlightningattack(_actor.bowskill_level)
   _onmiss(_attack)
  end
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
     isenemy=true, -- note: make it collidable w avatar
     x=_a.x,y=_a.y,
     hh=3,hw=3,
     durc=max(60,_actor.staffskill_level*20),
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

 function (_actor) -- 7 - holy/revive
  add(attacks,(getbowattack(_actor,7)))
 end,

 function(_actor) -- 8 - teleport
  local _a=getbowattack(_actor,1,8)
  _a.update,_a.wallaware=bowattack_teleportupdate
  add(attacks,_a)
 end,

 function(_actor) -- 9 - deflect
  local _a=getbowattack(_actor,1,9)
  _a.onmiss=function(_attack)
   deflectattack(
    _attack.x,
    _attack.y,
    3+avatar.bowskill_level,
    avatar.bowskill_level*16)
  end
  add(attacks,_a)
 end,
}


-->8
-- staff attacks

function addcastingfx(_colors)
 for _i=-2,1 do
  add(fxs,getpsetfx(
    avatar.x+_i,
    avatar.y+1,
    12+rnd(8),
    _colors or itemcolors[dget(16)%20],
    0,-.375,0,0))
 end
end

function addcastingmarkerfx()
 add(fxs,getpsetfx(
  avatar.x+avatar.staffdx,
  avatar.y+avatar.staffdy,
  5,
  itemcolors[dget(16)%20],
  .5-rnd(1),.5-rnd(1),0,0))
end

function staffhealing(_actor)
 _actor.staffattack_c+=1
 if _actor.staffattack_c >= 56-_actor.staffskill_level*3 then
  addcastingfx()
  _actor.hp+=0.5
  _actor.staffattack_c=0
 end
end

staffskills_attackintervals=split'16,24,2,16,16,0,24,16,16'
staffskills_castingmarker=split'0,0,1,0,1,0,0,1,0,0'
staffskills={
 function (_actor) -- 1 - bruise
  addbruisingswordattack(_actor)
 end,

 function (_actor) -- 2 - ice
  addcastingfx()
  for _i=0,1,.125 do
   local _x,_y=_actor.x+cos(_i)*12,_actor.y+sin(_i)*12
   if not addicewall(_x,_y,_actor.staffskill_level) then
    add(attacks,{
     x=_x,y=_y,
     durc=2,
     hw=3,hh=3,
     afflic=2,
     })
   end
  end
 end,

 function (_actor) -- 3 - fire
  if rnd() < .5 then
   addcastingfx()
   addfissure(_actor,-4+rnd(8)+_actor.x+_actor.staffdx,-4+rnd(8)+_actor.y+_actor.staffdy,_actor.staffskill_level)
  end
 end,

 function (_actor) -- 4 - lightning
  addcastingfx()
  addavatarlightningattack(_actor.staffskill_level)
 end,

 function (_actor) -- 5 - venomspikes
  addcastingfx()
  addvenomspikes(_actor,min(_actor.staffskill_level*.5,3),
   _actor.x+_actor.staffdx,_actor.y+_actor.staffdy)
 end,

 staffhealing, -- 6 - healing

 function (_actor) -- 7 - holy/revive
  add(attacks,getswordattack(_actor,7))
 end,

 function (_actor,_released) -- 8 - teleport
  if _released then
   local _x,_y=mid(8,avatar.x+avatar.staffdx,120),mid(10,avatar.y+avatar.staffdy,120)
   if isinsidewall({x=_x,y=_y,topy=_y-2,hw=avatar.hw,hh=avatar.hh},nil,0,0) then
    sfx(2)
   else
    sfx(19)
    addteleportfx(208,avatar.x,avatar.y)
    avatar.x,avatar.y=_x,_y
    addteleportfx(208,avatar.x,avatar.y)
   end
  else
   addcastingfx()
  end
 end,

 function (_actor,_released) -- 9 - deflect
  local _size=3+avatar.staffattack_c*avatar.staffskill_level*.0078
  if _released then
   deflectattack(avatar.x,avatar.y,_size,avatar.staffskill_level*16)
  else
   deflectattack(avatar.x,avatar.y,_size,16)
   addcastingfx()
  end
 end,
}

-->8
-- enemy attacks

function stonethrow_draw(_attack)
 spr(212,_attack.x-4,_attack.y-4)
end
function stonethrow(_actor)
 sfx(4)
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
  sfx(22)
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
    for _i=0,3 do
     add(fxs,getpsetfx(_attack.x+_i%2,_attack.y+flr(_i/2),rnd(6),_colors,0,0,0,0))
    end
   end,
   onmiss=function(_attack)
    sfx(5)
    add(fxs,getfx(227,_attack.x+1,_attack.y+1,6,_colors))
   end,
   draw=function(_attack)
    rectfill(_attack.x,_attack.y,_attack.x+1,_attack.y+1,_colors[1])
   end,
  })
 end
end

iceboltattack,
fireboltattack,
venomboltattack,
enemyattack_confusionball=
 boltskillfactory(2,itemcolors[2]),
 boltskillfactory(3,itemcolors[3]),
 boltskillfactory(5,itemcolors[5]),
 boltskillfactory(6,split'9,9,4,2')

function enemy_lightningstrikeattack(_a)
 addlightningstrike(_a,avatar.x,avatar.y)
end

function lastboss_teleport(_a)
 sfx(19)
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
   sfx(23)
   addenemy(_a.x,_a.y,rnd() < .25 and _a.summonees[2] or _a.summonees[1])
  end
 end
 drawactor(_a)
end

function enemyondeath(_actor)
 sfx(7)
 for _i=-2,3 do
  add(fxs,getfx(rnd(split'228,232,249,251'),_actor.x+_i,_actor.y,14,_actor.bloodcolors,0,-.125,0,rnd(.0625)))
 end
end

function bossondeath(_actor)
 sfx(6)
 for _i=0,.875,.125 do
  local _vx,_vy=cos(_i),sin(_i)
  add(fxs,getfx(227,_actor.x,_actor.y,40,_actor.bloodcolors,_vx,_vy,_vx*-.025,_vy*-.025))
 end
end

function lastbossondeath(_actor)
 dset(62,dget(62)+1)
 bossondeath(_actor)
 sfx(10)
 -- local _sgetystart,_sgetyend,_sgetxstart,_sgetxend=89,72,60,74
 -- local _xoff=(_sgetxend-_sgetxstart)/2
 -- for _y=_sgetyend-_sgetystart,0 do
 --  for _x=0,_sgetxend-_sgetxstart do
 --   local _col=sget(_sgetxstart+_x,_sgetystart+_y)
 for _y=-17,0 do
  for _x=0,14 do
   local _col=sget(60+_x,89+_y)
   if _col != 0 then
    add(fxs,getpsetfx(
     _actor.x-7+_x,
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
-- enemy classes

skeletonarcher={
 s=split'156,157,158,159',
 bloodcolors=split'7,7,6',
 basecolors=split',4', -- note: arrow color
 attack=addbruisingbowattack,
 conf='maxhp=6,hp=6,spd=.375,sight=80,range=58,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,bow_c=999',
}

enemyclasses={

 -- ice orcs
 {
  { -- ice orc stonethrower
   attack=stonethrow,
   conf='maxhp=12,hp=12,spd=.375,sight=80,range=58,hw=2,hh=3,dx=0,dy=0,f=1,spdfactor=1,stonethrow_afflic=1,bow_c=999',
  },

  { -- big ice orc
   attack=swordskills[2],
   conf='maxhp=16,hp=16,spd=.25,sight=64,range=8,hw=2,hh=3,dx=0,dy=0,f=1,spdfactor=1',
  },

  { -- ice orc caster
   attack=iceboltattack,
   conf='maxhp=20,hp=20,spd=.25,sight=90,range=64,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,isboss=1',
  },

  { -- bear (stun)
   attack=enemyattack_stunandknockback,
   conf='maxhp=16,hp=16,spd=.25,sight=64,range=8,hw=3,hh=3,dx=0,dy=0,f=1,spdfactor=1',
  },
 },

 -- battle trolls
 {
  { -- troll w club
   attack=enemyattack_stunandknockback,
   conf='maxhp=10,hp=10,spd=.375,sight=96,range=8,hw=3,hh=3,dx=0,dy=0,f=1,spdfactor=1',
  },

  { -- troll stonethrower (stun)
   attack=stonethrow,
   conf='maxhp=10,hp=10,spd=.25,sight=96,range=58,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,stonethrow_afflic=4,bow_c=999',
  },

  { -- battle troll champion
   attack=enemyattack_stunandknockback,
   ondeath=bossondeath,
   conf='maxhp=24,hp=24,spd=.5,sight=96,range=10,hw=3,hh=3,dx=0,dy=0,f=1,spdfactor=1,isboss=1',
  },

  { -- fireball thrower
   attack=fireballthrow,
   basecolors=split',14', -- note: arrow color
   conf='maxhp=6,hp=6,spd=.5,sight=96,range=48,hw=1.5,hh=1.5,dx=0,dy=0,f=1,spdfactor=1,bow_c=999',
  },
 },

 -- venomous beasts
 {
  { -- venom spitting snake
   basecolors=split',11', -- note: arrow color
   attack=venomspit_attack,
   conf='maxhp=6,hp=6,spd=.5,sight=80,range=58,hw=3,hh=2,dx=0,dy=0,f=1,spdfactor=1,bow_c=999',
  },

  { -- venomspike-tailed lizard
   attack=enemyattack_venomandknockback,
   conf='maxhp=16,hp=16,spd=.375,sight=64,range=8,hw=3,hh=2,dx=0,dy=0,f=1,spdfactor=1',
  },

  { -- poison druid
   attacks={
    function(_a)
     addvenomspikes(_a,5,getrandomfloorpos())
    end,
    venomboltattack,
    venomboltattack,
   },
   attack=enemy_rollingattacks,
   conf='maxhp=20,hp=20,spd=.375,sight=90,range=64,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,cur_attack=1,isboss=1',
  },

  { -- ice vulture
   attack=enemyattack_freeze,
   conf='maxhp=16,hp=16,spd=.5,sight=64,range=8,hw=3,hh=2,dx=0,dy=0,f=1,spdfactor=1',
  },
 },

 -- skeletons
 {
  skeletonarcher,

  { -- skeleton summoning gravestone
   bloodcolors=split'13,13,5',
   attack=function() end,
   draw=enemy_summonstone,
   summonees={
    { -- skeleton knight
     s=split'112,113,114,115',
     bloodcolors=split'7,7,6',
     attack=addbruisingswordattack,
     conf='maxhp=10,hp=10,spd=.25,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1',
    },
    skeletonarcher,
   },
   conf='maxhp=32,hp=32,spd=0,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,summoningc=0',
  },

  { -- skeleton queen
   bloodcolors=split'7,7,6',
   attack=enemyattack_confusionball,
   conf='maxhp=20,hp=20,spd=.25,sight=90,range=64,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,isboss=1',
  },

  { -- venomous bat
   attack=enemyattack_venomandknockback,
   conf='maxhp=6,hp=6,spd=.75,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1',
  },
 },

 -- devils
 {
  { -- big devil
   attack=swordskills[3],
   bloodcolors=split'9,9,4',
   conf='maxhp=12,hp=12,spd=.5,sight=64,range=8,hw=3,hh=3,dx=0,dy=0,f=1,spdfactor=1',
  },

  { -- evil warpstone
   bloodcolors=split'2,2,1',
   attack=function() end,
   draw=enemy_summonstone,
   summonees={
    { -- devil thrower
     s=split'172,173,174,175',
     basecolors=split',14', -- note: arrow color
     attack=fireballthrow,
     bloodcolors=split'9,9,4',
     conf='maxhp=2,hp=2,spd=.5,sight=96,range=48,hw=1.5,hh=1.5,dx=0,dy=0,f=1,spdfactor=1,bow_c=999',
    },
    { -- devil fighter
     s=split'188,189,190,191',
     bloodcolors=split'9,9,4',
     attack=swordskills[3],
     conf='maxhp=4,hp=4,spd=.375,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1',
    },
   },
   conf='maxhp=42,hp=42,spd=0,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1,summoningc=140',
  },

  { -- the evil
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
   attack=enemy_rollingattacks,
   attack_colors=split'8,12,8,11,8,10,8,7',
   draw=function(_a)
    pal(8,_a.attack_colors[_a.cur_attack])
    sspr(flr(_a.f-1)*15,72,15,18,_a.x-7.5,_a.y-12,15,18,_a.sflip)
    pal()
   end,
   conf='maxhp=52,hp=52,spd=.5,sight=128,range=86,hw=3,hh=4,dx=0,dy=0,f=1,spdfactor=1,cur_attack=1,isboss=1',
  },
  
  { -- devil confusor
   bloodcolors=split'9,9,4',
   attack=enemyattack_confusionball,
   conf='maxhp=8,hp=8,spd=.25,sight=90,range=64,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1',
  },
 },
}


-->8
-- avatar

if dget(14) == 0 then -- note: first session
 for _i=14,16 do
  dset(_i,1) -- note: set mundane items (sword,bow,staff)
 end
 dset(6,1) -- note: ...and shield
end

function recalcskills()
 avatar.reviveitems,
 avatar.swordskill_level,
 avatar.bowskill_level,
 avatar.staffskill_level=
  {},0,0,0
 for _typ=1,16 do
  local _skill=dget(_typ)
  local _skillwoepic,_skill_lvl=_skill%20,ceil(_skill/20)
  if _skillwoepic == dget(14)%20 then
   avatar.swordskill_level+=_skill_lvl
  end
  if _skillwoepic == dget(15)%20 then
   avatar.bowskill_level+=_skill_lvl
  end
  if _skillwoepic == dget(16)%20 then
   avatar.staffskill_level+=_skill_lvl
  end

  if _skillwoepic == 7 then
   add(avatar.reviveitems,_typ)
  end
 end

 avatar.basecolors=split',,,,15,0,2,4' -- note: empty first few because will always have 4 basic items (sword, bow, staff, shield)
 for _i=1,8 do
  local _skill=dget(split'14,15,16,6,7,8,9,10'[_i])
  if _skill != 0 then
   -- note: split'1,2,2,2,1,4,3,3' is itemtoskillcolor
   avatar.basecolors[_i]=itemcolors[_skill%20][split'1,2,2,2,1,4,3,3'[_i]]
  end
 end

 avatar.swordattack,
 avatar.bowattack,
 avatar.staffattack=
  swordskills[dget(14)%20],
  bowskills[dget(15)%20],
  staffskills[dget(16)%20]
end

function setupavatar()
 avatar={
  x=68,y=60,
  a=0,
  hw=1,hh=1,
  s=split'52,53,54,55', -- swordsman
  ss={
   split'52,53,54,55', -- swordsman
   split'56,57,58,59', -- ranger
   split'60,61,62,63', -- caster
  },
  f=1,
  spd=.5,
  spdfactor=1,
  -- sflip=nil,
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

 recalcskills()
end
setupavatar()


-->8
-- world

level=0 -- note: always start at home when cart boots up

function getworld()
 return level == 0 and 1 or flr(level/3.0005)+1
end

function addenemy(_x,_y,_enemyclass,_spritestart)
 for _attrib in all(split(_enemyclass.conf)) do
  local _attribparts=split(_attrib,'=')
  _enemyclass[_attribparts[1]]=_attribparts[2]
 end
 local _s={}
 for _i=1,4 do
  _s[_i]=(_spritestart or 0)+_i-1
 end
 add(actors,lmerge({
  -- ex: conf='maxhp=10,hp=10,spd=.375,sight=64,range=8,hw=2,hh=2,dx=0,dy=0,f=1,spdfactor=1'

  -- need to haves:
  -- s=split'48,49,50,51',
  -- basecolors=split'12,5,13,2,7',
  -- attack=myenemyattackfunc,
  -- conf='maxhp=6,hp=6,spd=.375',

  -- defaults
  bloodcolors=split'8,8,2',
  ondeath=_enemyclass.isboss and bossondeath or enemyondeath,
  s=_s,

  -- internals
  x=_x,y=_y,
  a=rnd(),
  isenemy=true,
  walking=true,
  draw=drawactor,
 },_enemyclass))
end

function mapinit()
 world,walls,dynwalls,actors,attacks,fxs,flooritems,deathts=
  getworld(),{},{},{},{},{},{} -- note: deathts is set to nil
 for _y=0,15 do
  walls[_y]={[0]=1,unpack(split'1,1,1,1,1,1,1,1,1,1,1,1,1,1,1')}
 end

 local avatarx,avatary,_enemycs=flr(avatar.x/8),flr(avatar.y/8),
  split'3,4,5,4,6,7,5,8,12,4,6,6,4,6,6'
 -- _enemycs=split'1,2,3,1,2,3,1,2,3,1,2,3,1,2,3'
 local curx,cury,a,enemy_c,steps,angles=
  avatarx,avatary,0,_enemycs[level] and _enemycs[level]+flr(dget(62)/2) or 0,
  split'440,600,420,600,450'[world],
  ({split'0,0.25,-0.25',split'0,0,0,0.25,-0.25',split'0,0,0,0,0,0,0,0.5,0.5,0.25,-0.25',
  split'0,0,0,0,0,0,0,0,0,0.25',split'0,0,0.25'})[world]
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
 local _extraenemyc=ceil(dget(62)/2)
 for _i=1,enemy_c do
  ::setupenemies::
  local _x,_y=flrrnd(15),flrrnd(15)
  if walls[_y][_x] != 0 do
   goto setupenemies
  end
  _x,_y=_x*8+4,_y*8+4
  local _enemytype=1
  if level%3 == 0 and _i == 1 then
   _enemytype=3
  elseif _i % 3 == 0 or rnd() < .1 then
   _enemytype=2
  end

  addenemy(_x,_y,enemyclasses[world][_enemytype],44+world*16+_enemytype*4)

  if _extraenemyc > 0 then
   addenemy(_x,_y,enemyclasses[world][4],60+world*16)
   _extraenemyc-=1
  end
 end

 -- add warpstone
 warpstone={x=curx*8,y=cury*8,hw=6,hh=8,wx=curx,wy=cury,draw=function()
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

 avatar.iswarping,avatar.afflic,avatar.hp=true,2,.0125

 if level == 0 then
  music(0)
 else
  music(-1)
  sfx(0)
 end
end


-->8
-- system init

function _init()
 mapinit()
end


-- system update

update60_hurtsfxts,update60_curenemyi,update60_enemyattackts=0,1,0
function _update60()

 -- dead
 if deathts and t() > deathts and btnp(4) then
  level=0
  setupavatar()
  mapinit()
 end

 if avatar.hp <= 0 then
  for _i=0,3 do
   sfx(-1,_i)
  end
  if deathts == nil then
   deathts=t()+2
  end
  return -- dead
 end

 -- warping
 if avatar.iswarping then
  avatar.hp+=.05
  if avatar.hp >= avatar.maxhp then
   avatar.iswarping,avatar.afflic=nil
  end
  return
 end

 if avatar.hp < avatar.maxhp and avatar.hp*.25 < t()-update60_hurtsfxts then
  sfx(1)
  update60_hurtsfxts=t()
 end

 if warpstone.iswarping then
  function _godownaworld()
   dset(63,max(dget(63),level))
   level=getworld()*3+1
   mapinit()
  end
  if btnp(4) or btnp(5) then
   warpstone.iswarping=nil
  end
  if level == 15 then
   if btnp(2) then
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

 if isinsidewall(avatar) then
  avatar.hp-=.125
 end

 avatar.spdfactor=1
 if avatar.afflic == 6 then
  _angle=confusedbtnmasktoa[_btnmask]
  if avatar.walking then
   avatar.hp+=.0312
  end
 end

 if avatar.touchingitem and btnp(4) then
  sfx(24)
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
  avatar.a,avatar.walking=
   _angle,
   avatar.attackstate != 'readying' and avatar.attackstate != 'striking'

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
   if _angle then
    local _staffdspd=min(.25+avatar.staffskill_level*.125,1.5)
    avatar.staffdx+=norm(cos(avatar.a))*_staffdspd
    avatar.staffdy+=norm(sin(avatar.a))*_staffdspd
   end
   avatar.attackstate,
   avatar.attackstate_c,
   avatar.s,
   avatar.attack=
    'readying',
    1,
    avatar.ss[3],
    avatar.staffattack

   avatar.staffattack_c+=1
   local _staffskill=dget(16)%20
   if avatar.staffattack_c%staffskills_attackintervals[_staffskill] == 1 then
    avatar.attack(avatar)
   end
   if staffskills_castingmarker[_staffskill] == 1 then
    addcastingmarkerfx()
   end
   avatar.hp-=.0096

  elseif btnp(4) then
   avatar.attackstate,
   avatar.attackstate_c,
   avatar.s,
   avatar.attack=
    'readying',
    6,
    avatar.ss[1],
    avatar.swordattack
  elseif btn(5) then
   avatar.attackstate,
   avatar.attackstate_c,
   avatar.s,
   avatar.attack,
   avatar.bow_c=
    'readying',
    1,
    avatar.ss[2],
    avatar.bowattack,
    min(avatar.bow_c+2,120)
  end

  if avatar.attackstate == 'readying' and avatar.attackstate_c <= 0 then
   avatar.skill_hit=nil
   avatar.skill_c+=1
   local _skill_level=avatar.swordskill_level
   if avatar.attack == avatar.bowattack then
    _skill_level=avatar.bowskill_level
   end
   if avatar.skill_c%flr(19/_skill_level) == 0 then
    avatar.skill_hit,avatar.skill_c=true,0
   end
   avatar.attackstate,avatar.attackstate_c='striking',28
   avatar.attack(avatar,true) -- note: 2nd arg only matters for staffs

   avatar.bow_c,avatar.staffdx,avatar.staffdy,avatar.staffattack_c=0,0,0,0
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

  if _enemy.isboss then
   _enemy.afflic=1
  end

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
    _enemy.attackstate,_enemy.attackstate_c='striking',40

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
    _enemy.afflic == 7) and not _enemy.isboss then
   -- decisiondebug('run away from avatar')
   _enemy.walking,_enemy.targetx,_enemy.targety=true,avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)+.5
   _enemy.moving_c=30

  elseif _haslostoavatar and _disttoavatar < _enemy.range then
   -- decisiondebug('attack avatar')

   if t()-update60_enemyattackts > .375 then
    _enemy.targetx,_enemy.targety=avatar.x,avatar.y
    _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)

    if not _enemy.attackstate then
     _enemy.attackstate,_enemy.attackstate_c='readying',36
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
    _enemy.moving_c,_enemy.targetx=45
   end
   
  elseif _haslostoavatar and
    _disttoavatar < _enemy.sight and
    _disttoavatar > _enemy.range and not 
    _enemy.moving_c then
   -- decisiondebug('move towards avatar')
   _enemy.walking,_enemy.targetx,_enemy.targety=true,avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   if _disttoavatar < 6 then
    _enemy.a+=.5
   end

  elseif _enemy.targetx and not _enemy.moving_c then
   -- decisiondebug('move towards target')
   _enemy.walking,_enemy.a=true,atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
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

  local _spdfactor,_dx,_dy=_a.spd*_a.spdfactor,0,0

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

   if rnd() < .5 then
    add(fxs,getfirefx(_a.x-2+rnd(4),_a.y-3+rnd(3)))
   end
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
   -- todo: use addholyfx
   add(fxs,getpsetfx(_a.x-2+rnd(4),_a.y-5+rnd(3),11,itemcolors[7],0,-.0125,0,-.0375))
   if _dx == 0 and _dy == 0 then
    _a.hp-=.0125
   else
    _a.hp+=.025
   end
  else -- catch all (other afflictions)
   _a.hp+=.0078
  end

  if _a.knockbackangle then
   _dx,_dy=_dx+cos(_a.knockbackangle)*6,_dy+sin(_a.knockbackangle)*6
   _a.knockbackangle=nil
  end

  -- movement check against walls
  _a.topy=_a.y-2
  local _postcolldx,_postcolldy=collideaabbs(isinsidewall,_a,nil,_dx,_dy)
  _a.wallcollisiondx,_a.wallcollisiondy=nil
  if _postcolldx != _dx or _postcolldy != _dy then
   _a.wallcollisiondx,_a.wallcollisiondy=_dx,_dy
  end
  _dx,_dy=_postcolldx,_postcolldy

  -- move
  _a.x=mid(8,_a.x+_dx,120)
  _a.y=mid(8,_a.y+_dy,120)

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
   local _dx,_dy=cos(_a.a)*_a.missile_spd,sin(_a.a)*_a.missile_spd
   local _postcolldx,_postcolldy=collideaabbs(isinsidewall,_a,nil,_dx,_dy)
   if _postcolldx != _dx or _postcolldy != _dy then
    if _a.bounce then
     sfx(25)
     if _postcolldx != _dx then
      _dx=-_dx
     end
     if _postcolldy != _dy then
      _dy=-_dy
     end
     _a.a=atan2(_dx,_dy)
    else
     _a.wallcollision,_a.durc=true,0
    end
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
     sfx(11)
     local _reviveitem=_a.reviveitems[1]
     dset(_reviveitem,max(1,dget(_reviveitem)-20))
     recalcskills()
     add(actors,_a)
     _a.hp=_a.maxhp
     add(fxs,getfx(210,_a.x,_a.y,240,itemcolors[7],0,-.125))
     for _i=1,10 do
      add(attacks,{
       x=64,y=64,
       hw=64,hh=64,
       durc=2,
       afflic=7,
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
   sfx(14)
   function getrndskill(_nonepicskills)
    return rnd(rnd() < dget(62)*.0625 and
     split'12,13,14,15,16,17,18' or _nonepicskills)
   end
   local _skills,_types=
    split'1,2,3,4,5,6,7,8,9',
    split'6,7,8,9,10,11,12,13,14,14,14,15,15,15,16,16,16'
   addflooritem(rnd(_types),rnd(_skills))
   if level%3 == 2 then
    addflooritem(rnd(_types),getrndskill(_skills))
   end
   if level%3 == 0 then
    addflooritem(getworld(),getrndskill(split'2,3,4,5,6,7,8,9'))
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

  -- draw floor fxs
 sortony(fxs)
 for _fx in all(fxs) do
  if _fx.isfloor then
   _fx.draw(_fx)
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
  pal(itemcolors[_item.skill%20])
  spr((_item.skill > 20 and 35 or 19)+_item.typ,_item.x-4,_item.y-4)
  pal()
  if avatar.touchingitem == _item then
   ?'\f1\#0🅾️',_item.x-4,_item.y-10
  end
 end

 -- draw actors
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
  ?'\f7\#0🅾️✽',warpstone.x-7,warpstone.y+6
 end

 -- draw inventory
 if btn(6) then
  pal()
  cls(0)
  rectfill(0,42,128,85,1)
  for _i=0,dget(62)-1 do
   spr(223,2+flr(_i/21)*106+_i%3*7,44+flr(_i%21/3)*6)
  end
  for _i=1,16 do
   drawinventoryskills(_i)
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
22222222222222222222222222222222003400000023000000030000000000000033300002233300000200000022300002203300000000000044400000320000
22222222000000000000000000000500032040000233400002232300030203000320340002344300003240000331440004324400033040000400040003234000
22222222022022220222002202502522040040000030400002030400021233000330440002344300021233000330440000234000022030000400400003004000
22222222020022200220002002055220004400000303000000334000043344000044400003444300040000000330440000312000032203000023000000440000
22222222000000000000000000050000000000000034000000030000000000000000000000333000030004000330440000234000003304000033000000000000
22222222220222020002220222025202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222200220022002200220025002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000000001000000020000002200002300000012000000020000000000000022200002223300003340000011200001102200022030000033300000120000
00223000000010000000320000001200021430000122300001121200020102000214230002334300011224000331440003213400013040000300040003213000
02233300020100000003020000030000034430000424300001020300011422000224330002314300000024000331440000124000022030000300400003004000
00344000002000000030400000300000003300000242000000223000032233000033300003444300010244000131420000213000032203000012000000440000
00040000040300000222000003000000000000000023000000020000000000000000000000333000010240000031400000134000003304000022000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000001000000020000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00112000022010000000130000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000
01122200020100000001020000034000000000000000000000001100066000000000020000000200000000000000020000003000000030000066630000000030
00233000002030000010400000304000000050100000501000005700006650000000502000005020000052000000502000005300000053000067563000005030
00030000040330000232000004000000004477100044771000447000004477110006772000067720000677200007772000077730000777300006770300077730
00000000000000000000000000000000004476000044760006447000004470000006720000067200000672000066702000067603000676030000700000067630
00000000000000000000000000000000000868000006860006680800000808000008680000068000006868000668080000086800000686000008080000686830
0000000000000000dd0000000000000000ccc00000ccc00000ccc00000ccc0000000000000000000000000702000000200000000000000005502424000000000
000cc000000cc000cdc000000000000002ccc00002ccc00000ccc00000ccc0000000070000000700000000d02222272200000000000000002522444500000000
0c5cc0000c5cc000cc5cc0000000cc0052ccc00052ccc00055ccccc005ccc5cc000ccd00000ccd00000cc0d022222d2002222200022222002222444402220000
cdd55000cdd55000005cc0000005cc00525555005255550055555cc0555555cc000ccd00000ccd000c0cc0c0022ccd2022224240222242400222222022222000
ccd55c00ccd55c0000555000005555cccc555cc0cc555cc0cc55500055cc500000222d0000222d00025555d0002ccd0022224445222244450224225522242400
00500500000550000055550000555000cc555cc0cc555cc0cc22220055cc222200255c0000255c00022552d000055c0022224444222244442244200522244450
0050050000050000005005000550500055555000555550005555500055555000002c5d00002c5d0002255200000c5d0022222220222222202242000052255445
050005000005000005000500000050005000500005500000500050005000500002255d0022255d000225520000055d0025025050025255002502500000055055
00000000000000000000000000000000000000000000000000000000000000000002220000022200040222000002220400000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000402920004029200040292000002920400000000000000000000000000000000
00040000000400000000000000000000000000000000000000000000000000000452990004529900045299000002990400000000000000000000000000000000
000499000004990004499900000000000dd990000dd99000dd990000000099000455550004555500995555000055559900000000000000000000000000000000
000499000004990000029900000099000dd990000dd99000dd990000000099009952529999525299995252990555559900089000000890000080900000000900
00092290000922900002220000009900092229000922290099229000000222909925259999252599022525990225250000092900000929000099200000002290
00022200000222000002220000022200002220000022200000229000009220000222220002222200022222002222220000002000000020000000290000092000
00090900000090000009090000922944009090000009000000900000000090000200020000220000020002000000020000090900000090000009000000000900
0000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000004000000000000000000000000000000000000
00000000000000000000000000000000000000000000000003a000000000000000000000000000000004000000002000000000000000000000004e0000000000
000000000000000000bb000000000000a00000000a00000030000000000000000000004000000040000020000b00020000000000000000000000400000000000
000000000000000000300000000000003a00000003a0000030000000099000000000f0200000f0200b00f2000f00f32005004e0500004e000000400005000050
000000000000000000030000000000003000000030000000033500000999000000033320000333200f3333200033330205504550000040000005d50005500500
000000bb000000bb0000300000000000533359905333599005559900535000a0000353200003532000553302005555000055d5000005d500005555500055d4ee
300530300530053000003000300053bb0555599905555999050599905335503a000353200003532000555300000555000555500000555550050e0e0505555000
053005303005300005353000035300000500505000555000000050500533330000035320000353200005550000055500000e0e00050e0e050000000000e0e000
000000000000000000000000000000000000000000000000000000000000000000000f0000000f0000000f0009000f0000000000000000000000000000000000
0000000000000000000000000000000000ddd10000ddd10000ddd10000ddd1000000ff000000ff000090ff000d00ff0700000000000000000000000000000000
000000000000000000000000000000000dd1dd100dd1dd100dd5dd100dd1dd10009066000090660000d066070d00660000000000000000000000000000000000
00000000000000000000dd00000000000d1d1d100d1d1d100d5d5d100d1d1d1000d0660700d0660700d066000600660600000000000000000002020000000000
000060d0000060d000006600000060000dd1dd100dd1dd100dd5dd100dd1dd1000d2200000d22000006222260d22222200220220000000000002020000000000
005566d0005566d000556000005566dd0dd1dd100dd1dd100dd5dd100dd1dd10006222600062226000d222200d22222000022200000020000002220000002000
005560000055600000556000005560000ddddd100ddddd100ddddd100ddddd1000d2220000d2220000d222000022222000002000000222000000200000022200
000606000000600000060600000606000ddddd100ddddd100ddddd100ddddd1000d2200002d20000000222000002220000000000000202000000000000220220
00000000000000008800088000000000000020000000200000002000000020000000000000000000000000000000000000000000000000000000000000090000
00e8e00000e8e000880e8e8000000000000022000000220000002200000022000000000000000000000000000000000000000000000000000009000000005000
0088000000880000220882200000000000028200000282000002e200000282000000000000000000000000000000000000000090000000900000500000000500
2222200022222000222222200022e8e0000222000002220000022200000222000000000000000000000000000000000000008050000080500000850000d08d50
882228808822288002222200022288000028220000282200002e22000028220000000000000000000000000000000000000ddd50000ddd5000dddd50002ddd05
882228808822288000222200022222200022220000222200002222000022220000000000000000000000000000000000000ddd50000ddd500022220500222200
0222200002222000002228002228828800228220002282200022e2200022822000000000000000000000000000000000000ddd50000ddd500022220000022200
080080000088000000800800222882880022222000222220002222200022222000000000000000000000000000000000000ddd50000ddd500002220000022200
00000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000800000000000000800000000000000000000004004000dd000000000000000000000000000000000000000000000000000000
000000040040800000000040040800000000040040500000000040040700000004dd4000dd000000000000000000000000000000000000000000000000000000
00000004dd4080000000004dd4050000000004dd4080000000004dd40700000000ddd00ddd000000000000000000000000000200000002000000000000000200
0000000ddd005000000000ddd008000000000ddd005000000000ddd00500000000ddd00dd0000000000000000000000000006020000060200000620000006020
0000000ddd008000000000ddd005000000000ddd005000000000ddd0070000000000000d00000000000000000000000000006620000066200006662000066620
00000222d22050000000222d22050000000222d22050000000222d220500000d0ddd220000000000000000000000000000006200000062000000620000006020
0000222dedd05000000222dedd05000000222dedddd000000222dedd050000d00deddd0000000000000000000000000000060600000060000006060000060600
0000222dddd05000000222dddddd000000222dddddd000000222dddd05000dd0ddddddd000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222dddddd000000222ddd205000000222dddddd000d00dddddd2000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222ddd205000000222ddd205000002222dddddd00dd00ddddd12000000000000000000000000000000000000000000000000000000000
0000222ddd205000000222ddd205000000222ddd208000d02222ddd20500dd002dddd11200000000000000000000000000000000000000000000000000000000
0000222ddd205000d00222ddd208000000222ddd205000d0222dddd2050000022dddd112000000000000000000000000000e8000000e800000e0800000000800
000d2221dd208000d0d222dd12050000002221dd2050000d222d1dd2070000021dd1dd1200000000000000000000000000088800000888000088800000008880
0d0d2221d12050000d2222d1120500000d2221d12080000222dd1d100500002111d1dd1120000000000000000000000000008000000080000000880000088000
00d02221d120500000222dd10008000dd02221d12050000222d11d000500002111d11d1120000000000000000000000000080800000080000008000000000800
00000d00d000800000000dd000050000000d00d00000000000d00d070707000000d00d0000000000000000000000000000000000000000000000000000000000
00000500500050000000050000000000000500500000000000500500767000000050050000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee8000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080e0000080e00008800000008000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888e0000888e00000800000008000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000800000008000000088ee
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800000080000008080000080800
00000000000000002222222022222220222222202222222022222220222222202222222022222220111111100000000000000000000000000000000000000000
000000000000000022272220222e22202ddddd20222222202fe2e820227f92202222772022767220171117100000000000000000000000000000000000000000
000000000000000022277220222ee22022272220222b22202e8888202777f920222b772027ddd620116446100000000000000000000000000000000000000000
000000000000000022777c2022eee220222aa2202b2b222028888820227f922022cbb22027ddd720111991100000000000000000000000000000000000000000
000000000000000022777c2022efee20222272202b232b2022888220227f922027cc222026ddd620111499100000000000000000000000000000000000000000
00000000000000002777cc202eeffe20222272202323232022282220227f92202772222022766220111144100000000000000000000000000000000000000000
00000000000000002222222022222220222222202222222022222220222222202222222022222220111111100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000110010000000022222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040040000
0000100000011001000010002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004dd40000
0001110000111101000111002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000
00001000001111110000100020000000000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000
00010100001111010000100020000000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000
00000000001111010000100020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111010000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000050000000500000000000000000000000700000051500066666600000000000000000000000000000000000000000000000000100000000000000
0000550000005500000055000000000000000000000777000055120066666666000000000e8888000f9999000e88999000000000000000000301001000042000
00051500000575000005050000011000000000000007717005551110d666666d00000000e8111880f9191990e811919900000000000000000003003000666d00
00055500000555000005550000111100000000000077177055551111d11611dd00011000881818209991994088181994000000000000000010030000000dd000
00515500005755000050550000111100000010000077177055500111d11611dd0001100088111220991914408811914400000000000000003000010000600d00
0055550000555500005555000001100000000000077777775502201166d1d6600000000002222200044444000222444000000000000000000010030000688d00
005515500055755000550550000000000000000077177171002222000d6d6d000000000000000000000000000000000000000000000000000030030100dddd00
00555550005555500055555000000000000000007177171102222220060606000000000000000000000000000000000000000000000000000000000300000000
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
08070000007200372006730097300c7300f7401274006720097200c7300f7301274015740187400f7201273015730187401b7401e74021740187401b7201e7302173024740277402a7402a700000000000000000
900700000173009700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000e0200802013000100000a0000300000000000000c0000a00009000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9303000026634156301462518500175001750015500145001350011500105000d5000d50014000120000f0000d0000a0000700005000010000000007000050000000006000020000100000000000000000000000
9202000015640156351950018500175001750015500145001350011500105000d5000d50014000120000f0000d0000a0000700005000010000000007000050000000006000020000100000000000000000000000
9102000026624156201462018500175001750015500145001350011500105000d5000d50014000120000f0000d0000a0000700005000010000000007000050000000006000020000100000000000000000000000
91120000104431c4331c4231c41315400144000d4000d40014400124000f4000d4000540001400004000740005400004000140000400004000040000400004000040000400004000040000400004000040000400
911200001042315400144000d4000d40014400124000f4000d4000540001400004000740005400004000140000400004000040000400004000040000400004000040000400004000040000400000000000000000
0001000003610056100761009610106100f6001260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012c000013730137351800015734167311673518734187351a7341a7321a735000000d91200000000000000013730137351800015734167311673518734187351a7341a7351c7341c73019732197321973500000
2312000000600006000060000600006000060000600006000c6140d6110e621106210f6211163112631136311564116641186411a6311c6311d6211e6111f61311611106110e6110c61500000000000000000000
4111000024263245000050000500295302953024530245322b5302b5302b5302b5350050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
192c000026715000000e71500000027250000029715267102871228715000000d7102172221725017100172226715000000e7150000002725000002971526710287122871500000297152171221715017101f715
012c00001f7150000018000217152271122715007250c715267142671226715000000d912157150e715097151f7150000018000217142271122715007250c7152671501715287150171525712257150000001715
000500000000027010290102b0102e010300103301035010370103a0103c0103c0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001161411615000002960000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
5f040000006430c040106201062500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d0d00001d6101d615000002960000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
4d0e00001d6141d615000002960000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
050200001d5201850022520005001d520005002e5202e500185003050029500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010600001161411615000002960000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
172400001062410625000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480900002862110621106150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0503000023024180200d0201502000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002401528015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003c11000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000a00001d4111d4151f4141840424400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000000000000
b82400001f62412615006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00424344
01 0c424344
02 0d424344

