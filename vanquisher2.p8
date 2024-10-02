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

poke(0x5f5c, -1) -- set auto-repeat delay for btnp to none

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

function lmerge(_t1,_t2)
 for _k,_v in pairs(_t2) do
  _t1[_k]=_v
 end
 return _t1
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
  _dx=(0.1+_collidedwith.hw-abs(_aabb.x-_collidedwith.x))*-_sgndx
 end

 collideaabbs_aabb.x,collideaabbs_aabb.y=_aabb.x,_aabb.y+_dy
 _collidedwith=_func(collideaabbs_aabb,_other)
 if _collidedwith then
  _dy=(0.1+_collidedwith.hh-abs(_aabb.y-_collidedwith.y))*-_sgndy
 end

 return _dx,_dy
end

function detectandresolvehit(_attack,_actor)
 -- detect
 local _dx,_dy=collideaabbs(isaabbscolliding,_attack,_actor,0,0)
 if _dx != 0 or _dy != 0 then
  del(attacks,_attack)
  _actor.afflic=_attack.afflic
  if _actor.isenemy and _attack.afflic == 5 then
   _actor.a+=.5
  end
  _actor.hp-=1
  add(fxs,getfx(227,_attack.x,_attack.y,8,split'7'))

  -- resolve
  if _attack.knockback then
   _actor.knockbackangle=_attack.a
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
 if _a.afflic == 2 then
  pal(frozencolors)
 elseif _a.afflic == 6 then
  pal(envenomedcolors)
 end
 spr(_a.s[flr(_a.f)],_a.x-4,_a.y-(8-_a.hh),1,1,_a.sflip)
 if _a.afflic == 2 or _a.afflic == 6 then
  pal()
 end
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

getlightningstrikefx_colors=split'7,7,10,5'
function getlightningstrikefx(_x,_y)
 if rnd() > .25 then
  return getfx(
   228,
   _x,_y,
   14,
   getlightningstrikefx_colors,
   0,0,
   0,-.0375)
 end
end

----

addicewall_colors=split'6,6,6,6,6,6,13'
function addicewall(_a,_x,_y)
 local _dw={
  x=_x+cos(_a.a)*6,y=_y+sin(_a.a)*6,
  hw=4,hh=4,
 }
 add(dynwalls,_dw)
 add(fxs,getfx(229,_dw.x,_dw.y,120,addicewall_colors))
 add(attacks,{
  x=1,y=1,
  durc=120,
  hw=0,hh=0,
  onmiss=function()
   del(dynwalls,_dw)
  end
  })
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

function addvenomspit(_actor,_x,_y,_a)
 add(attacks,{
  isenemy=_actor.isenemy,
  x=_x,y=_y,
  a=_a,
  afflic=6,
  hw=1,hh=1,
  durc=20,
  ay=-1,
  update=function(_attack)
   spit_update(_attack)
   add(fxs,getfx(
    228,
    _attack.x,_attack.y,
    10,
    bowattack_venom_fx_colors))
  end,
  })
end

function lightningfx_draw(_fx)
 for _i=2,#_fx.xs do
  local _col=_i%3==0 and 10 or 7
  line(_fx.xs[_i-1],_fx.ys[_i-1],_fx.xs[_i],_fx.ys[_i],rnd()>.5 and _col or 5)
 end
end

function addlightningstrike(_a,_x,_y)
 add(attacks,{
  isenemy=_a.isenemy,
  x=_x,y=_y,
  afflic=5,
  hw=8,hh=8,
  durc=12,
  draw=function()
   circfill(_x,_y,5,5)
  end,
  update=function()
   add(fxs,getlightningstrikefx(_x-4+rnd(8),_y-4+rnd(8)))
  end,
 })
 local _lightningfx={
  dur=12,durc=12,
  x=0,y=0,vx=0,vy=0,ax=0,ay=0,
 }
 local _xs,_ys,_cury={_x},{_y},_y
 while _cury > 0 do
  add(_xs,_x-6+rnd(12))
  _cury=mid(0,_cury-(4+rnd(8)),_y)
  add(_ys,_cury)
 end
 _lightningfx.xs=_xs
 _lightningfx.ys=_ys
 _lightningfx.draw=lightningfx_draw
 add(fxs,_lightningfx)
end
-- damage,ice,fyre,stun,venom,fear
affliccolors=split'2,12,14,7,10,11,9'

quickfxcolors={
 split'6,6,4,1', -- bleed
 split'7,7,7,12,13', -- ice
 split'7,14,15,15,14,14', -- fyre
 split'7,7,13,2', -- knockback
 split'4,4,10,10,10,7', -- stun
 split'3,3,3,11,11,10', -- venom
}

function getswordattack(_actor,_afflic,_damagetype)
 local _x,_y=_actor.x+cos(_actor.a)*6,_actor.y-1+sin(_actor.a)*6
 add(fxs,getfx(240+atodirections(_actor.a)*8,_x,_y,12,quickfxcolors[_damagetype or _afflic]))
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
 function (_actor) -- 1 - bleed
  local _a=getswordattack(_actor,1)
  add(attacks,_a)
 end,

 function (_actor) -- 2 - icewall
  local _a,_x,_y=getswordattack(_actor,2)
  _a.onmiss=function(_attack)
   addicewall(_attack,_x,_y)
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
  local _a=getswordattack(_actor,1,4)
  -- _a.skillvl=_actor.swordskillvl
  if _actor.maxhp then
   -- _a.skillvl=_actor.swordskillvl
   _a.skillvl=4
  end
  _a.wallaware,_a.knockback,_a.durc=true,true,4
  _a.onmiss=function (_attack)
   _attack.skillvl-=1
   if _attack.skillvl > 0 and not _attack.wallcollision then
    swordskills[4](_attack)
   end
  end
  add(attacks,_a)
 end,

 function (_actor) -- 5 - stun
  local _a=getswordattack(_actor,5)
  add(attacks,_a)
  -- if rnd() < .125 then -- todo: add chance based on skill level
   addlightningstrike(_actor,8+rnd(112),8+rnd(112))
  -- end
 end,

 function (_actor) -- 6 - venom
  local _a=getswordattack(_actor,6)
  if _actor.swordskill_hit then
   addvenomspit(_actor,_actor.x,_actor.y,rnd())
  end
  add(attacks,_a)
 end,
}

function spit_update(_attack)
 _attack.x+=cos(_attack.a)*.75
 _attack.y+=sin(_attack.a)*.75+_attack.ay
 _attack.ay+=.125
end

function missile_update(_attack)
 _attack.x+=cos(_attack.a)*_attack.missile_spd
 _attack.y+=sin(_attack.a)*_attack.missile_spd
end

function arrow_onmiss_factory(_afflic,_colors)
 return function(_attack)
  add(fxs,getfx(227,_attack.x,_attack.y,6,_colors or quickfxcolors[_afflic]))
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
 function (_actor) -- 1 - bleed
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
  _a.draw,_a.onmiss,_a.knockback=
   arrow_draw_factory(6),
   arrow_onmiss_factory(1,quickfxcolors[4]),
   true
  add(attacks,_a)
 end,
}


frozencolors=split'12,12,12,12,12,12,12,12,12,12,12,12,12,12,12'
envenomedcolors=split'3,3,3,11,3,11,11,11,11,11,11,11,3,11,11'

function swordattack_stunandknockback(_actor)
 local _a=getswordattack(_actor,5)
 _a.knockback=true
 add(attacks,_a)
end

function stonethrow_draw(_attack)
 pal(1,13)
 spr(232,_attack.x-4,_attack.y-4)
 pal()
end

function stonethrow(_actor)
 local _a=getbowattack(_actor,_actor.stonethrow_afflic)
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

bowattack_venom_fx_colors=split'10,11,11,3,5'
function bowattack_venom_update(_attack)
 missile_update(_attack)
 add(fxs,getfx(228,_attack.x,_attack.y,6,bowattack_venom_fx_colors))
end

function bowattack_venom_draw(_attack)
 pset(_attack.x,_attack.y,10)
end

function bowattack_venom(_actor)
 local _a=getbowattack(_actor,6)
 _a.update,
 _a.draw,
 _a.missile_spd,
 _a.hh,_a.hw=
  bowattack_venom_update,
  bowattack_venom_draw,
  1.25,
  1.5,1.5

 add(attacks,_a)
end

function staff_bleedattack(_a)
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

function enemyattack_confusionball(_a)
 local _x,_y=_a.x+cos(_a.a)*6,_a.y-1+sin(_a.a)*6
 add(attacks,{
  isenemy=true,
  x=_x,y=_y,
  a=_a.a,
  afflic=7,
  hw=3,hh=3,
  durc=999,
  wallaware=true,
  missile_spd=1,
  update=function(_attack)
   missile_update(_attack)
   add(fxs,getfx(232,_attack.x,_attack.y,6,split'9,9,4,2'))
  end,
  onmiss=function(_attack)
   add(fxs,getfx(227,_attack.x+1,_attack.y+1,6,split'9,4'))
  end,
  draw=function(_attack)
   -- todo: rect instead?
   pal(1,15)
   spr(232,_attack.x-4,_attack.y-4)
   pal()
  end,
  })
end

function bossondeath(_actor)
 for _y=0,7 do
  for _x=0,7 do
   local _col=sget((_actor.s[3]*8)%16+_x,flr(_actor.s[3]*8/16)+_y)
   if _col != 0 then
    add(fxs,getfx(
     228,
     _actor.x-4+_x,
     _actor.y-_actor.hh+_y,
     80+rnd(26),
     {_col,_col,1},
     0,0,0,-rnd()*.0078))
   end
  end
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
  draw=function(_a)
   pal(_a.basecolors)
   drawactor(_a)
   pal()
  end,

  swordskill_level=14,
  swordskill_c=0,
  swordattack=swordskills[6],

  bow_c=0,
  bowattack=bowskills[4],

  staffattack_c=0,
  staffdx=0,
  staffdy=0,
  staffattack=staff_fireattack,
  -- staffattack=staff_bleedattack,
 }
 avatar.s=avatar.ss[1]
end
setupavatar()

function getworld()
 return level == 0 and 1 or flr(level/3.0005)+1
end

level=0

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
   attack=swordskills[2],
   hw=3,hh=3,
  },

  { -- ice orc caster
   s=split'56,57,58,59',
   maxhp=20,
   spd=.25,
   attack=staff_iceboltattack,
   sight=90,
   range=64,
   ondeath=bossondeath,
  },

  { -- bear (stun)
   s=split'60,61,62,63',
   maxhp=16,
   spd=.25,
   attack=swordattack_stunandknockback,
   hw=3,hh=3,
  },
 },

 -- battle trolls
 {
  { -- troll w club
   s=split'68,69,70,71',
   maxhp=10,
   spd=.25,
   attack=swordattack_stunandknockback,
   hw=3,hh=3,
  },

  { -- troll stonethrower (stun)
   s=split'64,65,66,67',
   maxhp=10,
   spd=.375,
   attack=stonethrow,
   stonethrow_afflic=5,
   sight=80,
   range=58,
  },

  { -- fire troll champion
   s=split'72,73,74,75',
   maxhp=24,
   spd=.5,
   attack=swordattack_stunandknockback,
   hw=3,hh=3,
   sight=56,
   range=10,
   ondeath=bossondeath,
  },

  { -- fireball thrower
   s=split'76,77,78,79',
   maxhp=6,
   spd=.5,
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
   attack=bowattack_venom,
   sight=80,
   range=58,
   hw=3,
  },

  { -- venomspike-tailed lizard
   s=split'84,85,86,87',
   maxhp=16,
   spd=.375,
   attack=swordskills[6],
   hw=3,
  },

  { -- poison druid
   s=split'88,89,90,91',
   maxhp=20,
   spd=.125,
   attack=staff_iceboltattack,
   sight=90,
   range=64,
   ondeath=bossondeath,
  },

  { -- ice vulture
   s=split'92,93,94,95',
   maxhp=16,
   spd=.25,
   attack=sword_iceattack,
   hw=3,
  },
 },

 -- skeletons
 {
  { -- skeleton knight
   s=split'96,97,98,99',
   maxhp=10,
   bloodcolors=split'6,6,5',
   spd=.25,
   attack=swordattack_stunandknockback,
  },

  { -- skeleton archer
   s=split'100,101,102,103',
   maxhp=6,
   bloodcolors=split'6,6,5',
   spd=.375,
   attack=bowskills[1],
   sight=80,
   range=58,
  },

  { -- skeleton queen
   s=split'104,105,106,107',
   maxhp=20,
   bloodcolors=split'6,6,5',
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
   attack=swordskills[6],
  },
 },

  -- the devils
 {
  { -- big devil
   s=split'112,113,114,115',
   maxhp=16,
   spd=.5,
   attack=swordskills[3],
   hw=3,hh=3,
   bloodcolors=split'7,7,6',
  },

  { -- devil thrower
   s=split'116,117,118,119',
   maxhp=8,
   spd=.5,
   attack=fireballthrow,
   hw=1.5,hh=1.5,
   sight=96,
   range=48,
   bloodcolors=split'7,7,6',
  },

  { -- the evil
   maxhp=52,
   spd=.25,
   hw=3,hh=4,
   sight=128,
   range=86,
   bloodcolors=split'7,7,6',
   ondeath=bossondeath,
   attacks={
    staff_iceboltattack,
    fireballthrow,
   },
   cur_attack=1,
   attack_colors=split'12,8',
   attack=function(_actor)
    _actor.attacks[_actor.cur_attack](_actor)
    _actor.cur_attack+=1
    if _actor.cur_attack > #_actor.attacks then
     _actor.cur_attack=1
    end
   end,
   draw=function(_a)
    pal(8,_a.attack_colors[_a.cur_attack])
    sspr(flr(_a.f-1)*15,65,15,18,_a.x-7.5,_a.y-12,15,18,_a.sflip)
    pal()
   end,
  },

  { -- venomous bat -- todo: change to smt else
   s=split'108,109,110,111',
   maxhp=4,
   spd=.75,
   attack=swordskills[6],
  },
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
 local _extraenemyc=1 -- todo: base on bosses killed or smt
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

 -- todo: the filtering does not seem to work properly!
 local _btnmask=band(btn(),0b1111) -- note: filter out o/x buttons from dpad input
 local _angle=btnmasktoa[_btnmask]
 if avatar.afflic == 7 then
  _angle=confusedbtnmasktoa[_btnmask]
  if avatar.walking then
   avatar.hp+=.0312
  end
 end
 
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
   avatar.hp+=.25
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
   avatar.bow_c+=1.25
   avatar.state='readying'
   avatar.state_c=1
   avatar.s=avatar.ss[2]
   avatar.attack=avatar.bowattack
  end

  if avatar.state == 'readying' and avatar.state_c <= 0 then
   avatar.swordskill_hit=nil
   avatar.swordskill_c+=1
   -- if avatar.swordskill_c%(17-avatar.swordskill_level) == 0 then
   if avatar.swordskill_c%flr(19/avatar.swordskill_level) == 0 then
    avatar.swordskill_hit=true
    avatar.swordskill_c=0
   end
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

  if _enemy.afflic == 5 then
   _disttoavatar,_haslostoavatar=nil
  end

  if _enemy.afflic == 2 then
   -- note: frozen, do nothing

  elseif _enemy.afflic == 3 and _enemy.state == nil then
   _enemy.walking=true
   _enemy.a+=rnd(.01)-.005
   if rnd() < .05 then
    _enemy.a+=.5
   end

  elseif _enemy.state then
   _enemy.walking=nil
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
   _enemy.walking=true
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

  elseif _enemy.afflic == 6 then
   -- note: envenomed, stand still to heal
   _enemy.walking=nil
   
  elseif _haslostoavatar and
    _disttoavatar < _enemy.sight and
    _disttoavatar > _enemy.range then
   -- debug('move towards avatar')
   _enemy.walking=true
   _enemy.targetx,_enemy.targety=avatar.x,avatar.y
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   if _disttoavatar < 6 then
    _enemy.a+=.5
   end

  elseif _enemy.wallcollisiondx or _enemy.wallcollisiondy then
   -- debug('move out of wall collision')
   _enemy.walking=true
   if _enemy.afflic != 5 then
    _enemy.a+=.5
    _enemy.targetx=nil
   end

  elseif _enemy.targetx then
   -- debug('move towards target')
   _enemy.walking=true
   _enemy.a=atan2(_enemy.targetx-_enemy.x,_enemy.targety-_enemy.y)
   local _disttotarget=dist(_enemy.x,_enemy.y,_enemy.targetx,_enemy.targety)
   if _disttotarget < 4 then
    _enemy.targetx=nil
   end

  else -- roam
   -- debug('roam')
   _enemy.walking=true
   _enemy.a+=rnd(.01)-.005
   _enemy.spdfactor=.25
  end
 end

 -- update actors
 for _a in all(actors) do
  -- set spdfactor
  _a.spdfactor=1
  if _a.afflic == 3 then
   _a.spdfactor=1.375
  elseif _a.afflic == 5 or _a.afflic == 6 then
   _a.spdfactor=.5
  end

  local _spdfactor=_a.spd*_a.spdfactor
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
  if _a.afflic and _a.hp >= _a.maxhp then
   _a.afflic=nil
   _a.hp=_a.maxhp
  end
  if _a.afflic == 1 then
   _a.hp+=.0075
  elseif _a.afflic == 2 then
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
  elseif _a.afflic == 5 then
   if _a.wallcollisiondx then
    _a.hp+=.05
   end
   add(fxs,getfx(
    228,
    _a.x-2+rnd(2),
    _a.y-_a.hh*2-2,
    6,
    split'7,2,10,2',
    0,0.5))
  elseif _a.afflic == 6 then
   if _a.walking then
    _a.hp-=.025
   else
    _a.hp+=.025
   end
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
   add(fxs,getfx(
    228,
    _a.x,_a.y,
    4+flrrnd(2),
    {_a.bloodcolors[1]},
    0,0,
    0,.075))
   if rnd() < .025 then
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
  elseif _a.isenemy then
   _enemycount+=1
  end
 end

 if _enemycount == 0 then
  walls[warpstone.wy][warpstone.wx]=225

  warpstone.istouching=nil
  if ismiddleinsideaabb(avatar,warpstone) then
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

 --  rect(_a.x-_a.hw,_a.y-_a.hh,_a.x+_a.hw,_a.y+_a.hh,_iscollide and 8 or 12)
 --  pset(_a.x,_a.y,7)
 --  pset(_a.x,_a.y+_a.hh,9)
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
dd5dddd0dd5dddd00ddd5d0000dd6660000551000005510000005000111111111111111111111111111113111111111111111111122122221222442212221222
ddd5d5d0ddd5d5d00d5d5d0000d666d00055511000555110000551005515551511111111dd1ddd1d3d1d3d1ddd1ddd1d11111111122122221242e44212221222
0dd55dd00dd55dd000d5dd000dd66ddd000511000005110000551100111111111111111111111111131133111111111111111111122112221242f44212221122
0d0050d00d0050d00005d000d6d66d6d00551110005511100005510015551555111111111ddd1ddd13dd13dd1ddd1ddd11111111111111111122522111111111
0d0050000d005000000500006666d66d055111110551111100551110111111111111111111111111113131111102020111111111221221222214522221212212
000050000000500000050000000000000000200000002000000020005515551511111111dd1ddd1ddd3d3d1dd102020111111111221221222212212221212212
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
0000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000e000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005a00000000000000000000000000000000e00000000200000000000000000000000e00000000000
000000000000000000bb000000000000a00000000a0000005000000000000000000000e0000000e0000020000000020000000000000000000004000000000000
000000000000000000300000000000005a00000005a00000500000000bb000000000f0200000f0200000f2000030f32005004e0500004e000000400005000005
000000000000000000030000000000005000000050000000055300000bbb00000003332000033320003333200053330205504550000040000005d50005500550
000000bb000000bb000030000000000035553bb035553bb00333bb00353000a0000353200003532000555502005555000055d5000005d500005555500055d44e
300530300530053000003000300053bb03333bbb03333bbb0303bbb03553305a000353200003532000555500000555000555500000555550050e0e0505555000
053005303005300005353000035300000300303000333000000030300355550000035320000353200005550000055500000e0e00050e0e0500000000000e0e00
000000000000000000000000000000000000000000000000000000000000000000000f0000000f0000000f0009000f0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000ff000000ff000090ff000d00ff0000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000009066000090660000d066000d00660700000000000000000000000000000000
00000000000000000000dd00000000000000020000000200000000000000020000d0660000d0660000d066070600660600000000000000000002020000000000
000060d0000060d000006600000060000000602000006020000062000000602000d2207000d22070006222260d22222200220220000000000002020000000000
005566d0005566d000556000005566dd00006620000066200006662000066620006222600062226000d222200d22222000022200000020000002220000002000
005560000055600000556000005560000000620000006200000062000000602000d2220000d2220000d222000022222000002000000222000000200000022200
000606000000600000060600000606000006060000006000000606000006060000d2200002d20000000222000002220000000000000202000000000000220220
00000000000000008800088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00e8e00000e8e000880e8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880000008800002208822000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222200022222000222222200022e8e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88222880882228800222220002228800000e8000000e800000e08000000008000000000000000000000000000000000000000000000000000000000000000000
88222880882228800022220002222220000888000008880000888000000088800000000000000000000000000000000000000000000000000000000000000000
02222000022220000022280022288288000080000000800000008800000880000000000000000000000000000000000000000000000000000000000000000000
08008000008800000080080022288288000808000000800000080000000008000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000080000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000004004080000000004004080000000004004050000000004004070000000000000000000000000000000000000000000000000000000000000000000000
00000004dd4080000000004dd4050000000004dd4080000000004dd4070000000000000000000000000000000000000000000000000000000000000000000000
0000000ddd005000000000ddd008000000000ddd005000000000ddd0050000000000000000000000000000000000000000000000000000000000000000000000
0000000ddd008000000000ddd005000000000ddd005000000000ddd0070000000000000000000000000000000000000000000000000000000000000000000000
00000222d22050000000222d22050000000222d22050000000222d22050000000000000000000000000000000000000000000000000000000000000000000000
0000222dedd05000000222dedd05000000222dedddd000000222dedd050000000000000000000000000000000000000000000000000000000000000000000000
0000222dddd05000000222dddddd000000222dddddd000000222dddd050000000000000000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222dddddd000000222ddd205000000222dddddd0000000000000000000000000000000000000000000000000000000000000000000000
0000222dddddd000000222ddd205000000222ddd205000002222dddddd0000000000000000000000000000000000000000000000000000000000000000000000
0000222ddd205000000222ddd205000000222ddd208000d02222ddd2050000000000000000000000000000000000000000000000000000000000000000000000
0000222ddd205000d00222ddd208000000222ddd205000d0222dddd2050000000000000000000000000000000000000000000000000000000000000000000000
000d2221dd208000d0d222dd12050000002221dd2050000d222d1dd2070000000000000000000000000000000000000000000000000000000000000000000000
0d0d2221d12050000d2222d1120500000d2221d12080000222dd1d10050000000000000000000000000000000000000000000000000000000000000000000000
00d02221d120500000222dd10008000dd02221d12050000222d11d00050000000000000000000000000000000000000000000000000000000000000000000000
00000d00d000800000000dd000050000000d00d00000000000d00d00070000000000000000000000000000000000000000000000000000000000000000000000
00000500500050000000050000000000000500500000000000500507777700000000000000000000000000000000000000000000000000000000000000000000
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
00005000000050000000500000000000000000000000700000051500066666600000000000000000000000000000000000000000000020000000000000000000
0000550000005500000055000000000000000000000777000055120066666666000000000e8888000f9999000e88999000000000000022000000000000000000
00051500000575000005050000011000000000000007717005551110d666666d00000000e8111880f9191990e811919900ddd100000282000000000000000000
00055500000555000005550000111100000000000077177055551111d11611dd000110008818182099919940881819940dd1dd10000222000000000000000000
00515500005755000050550000111100000010000077177055500111d11611dd000110008811122099191440881191440d1d1d10002822000000000000000000
0055550000555500005555000001100000000000077777775502201166d1d660000000000222220004444400022244400dd1dd10002222000000000000000000
005515500055755000550550000000000000000077177171002222000d6d6d00000000000000000000000000000000000dd1dd10002282200000000000000000
0055555000555550005555500000000000000000717717110222222006060600000000000000000000000000000000000ddddd10002222200000000000000000
00010000000000000000000000000000000001000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000010000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000
00001100111100000000000000001111000110000011000010000001000011000000000000000000000000000000000000000000000000000000000000000000
00001100001110000011110000011100000110000011110001111110001111000000000000001000000010000001000000000000000010000000100000010000
00001100000111000111111000111000000110000001110000111100001110000000110000010000000010000000100000001100000100000000100000001000
00011000000110001000000100011000000011000000100000000000000100000000000000000000000000000000000000000000000000000000000000000000
