pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- epic evil ender (v1.0)
-- by ironchest games

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function has(_t,_v)
 for v in all(_t) do
  if v == _v then
   return true
  end
 end
end

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

-- note: last char needs to be ','
function paf(s) -- parseflat
 local t,_s={},''
 while #s > 0 do
  local d=sub(s,1,1)
  if d != ',' then
   _s=_s..d
  else
   add(t,tonum(_s))
   _s=''
  end
  s=sub(s,2)
 end
 return t
end

function isaabbscolliding(a,b)
 if a.x - a.hw < b.x + b.hw and
    a.x + a.hw > b.x - b.hw and
    a.y - a.hh < b.y + b.hh and
    a.y + a.hh > b.y - b.hh then
  return b
 end
end

wallaabb={
 x=0,
 y=0,
 hw=4,
 hh=4,
}
function isinsidewall(aabb)
 local x1,y1,x2,y2=
   aabb.x-aabb.hw,
   aabb.y-aabb.hh,
   aabb.x+aabb.hw,
   aabb.y+aabb.hh

 for point in all({
    {x1,y1},
    {x2,y1},
    {x2,y2},
    {x1,y2},
   }) do
  local mapx,mapy=flr(point[1]/8),flr(point[2]/8)
  wallaabb.x=mapx*8+wallaabb.hw
  wallaabb.y=mapy*8+wallaabb.hh

  -- note: hitboxes should not be larger than 8x8
  if walls[mapy][mapx] == 1 and
     isaabbscolliding(aabb,wallaabb) then
   return wallaabb
  end
 end
end

function haslos(_x1,_y1,_x2,_y2)
 local dx,dy,x,y,xinc,yinc=
   abs(_x2-_x1),
   abs(_y2-_y1),
   _x1,
   _y1,
   sgn(_x2-_x1),
   sgn(_y2-_y1)

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

function dist(x1,y1,x2,y2)
 local dx,dy=x2-x1,y2-y1
 return sqrt(dx*dx+dy*dy)
end

function norm(n)
 if n == 0 then
  return 0
 end
 return sgn(n)
end

_aabb={}
function collideaabbs(func,aabb,other,_dx,_dy)
 local dx,dy=_dx,_dy

 -- set aabb halves
 _aabb.hw,_aabb.hh=aabb.hw,aabb.hh

 -- set next pos along x
 _aabb.x,_aabb.y=aabb.x+_dx,aabb.y

 -- is it colliding w other
 local collidedwith=func(_aabb,other)
 if collidedwith then
  dx=(aabb.hw+collidedwith.hw-abs(aabb.x-collidedwith.x))*-sgn(_dx)
 end

 -- set next pos along y
 _aabb.x,_aabb.y=aabb.x,aabb.y+_dy

 -- is it colliding w other
 local collidedwith=func(_aabb,other)
 if collidedwith then
  dy=(aabb.hh+collidedwith.hh-abs(aabb.y-collidedwith.y))*-sgn(_dy)
 end

 return dx,dy
end

function findflr(_x,_y)
 local a,d=rnd(),1

 repeat
  a+=0.05
  d+=0.02
  x,y=
    mid(1,flr(_x/8+cos(a)*2),14),
    mid(1,flr(_y/8+sin(a)*2),14)
 until walls[y] and walls[y][x] == 0

 return x*8+4,y*8+4
end

btnmasktoangle={
 [0x0002]=0, -- right
 [0x0006]=0.125, -- right/up
 [0x0004]=0.25, -- up
 [0x0005]=0.375, -- up/left
 [0x0001]=0.5, -- left
 [0x0009]=0.625, -- left/down
 [0x0008]=0.75, -- down
 [0x000a]=0.875, -- down/right
}

meleevfxframes={
 [0]=paf'0,20,4,7,-1,-5,', -- right
 [0.125]=paf'8,20,6,4,-3,-2,', -- right/up
 [0.25]=paf'20,20,9,3,-3,-1,', -- up
 [0.375]=paf'14,20,6,4,-2,-2,', -- up/left
 [0.5]=paf'4,20,4,7,-2,-5,', -- left
 [0.625]=paf'29,20,4,7,-3,-6,', -- left/down
 [0.75]=paf'20,23,9,3,-4,-2,', -- down
 [0.875]=paf'33,20,4,7,0,-6,', -- down/right
 [1]=paf'0,20,4,7,-1,-5,', -- right (wrapped)
}

bowvfxframes={
 [0]=paf'0,27,6,7,-3,-5,', -- right
 [0.125]=paf'17,32,7,7,-4,-3,', -- right/up
 [0.25]=paf'10,31,7,6,-3,-3,', -- up
 [0.375]=paf'34,32,7,7,-3,-3,', -- up/left
 [0.5]=paf'4,27,6,7, -2,-5,', -- left
 [0.625]=paf'22,27,7,7,-2,-5,', -- left/down
 [0.75]=paf'10,27,7,6,-3,-4,', -- down
 [0.875]=paf'29,27,7,7,-4,-4,', -- down/right
 [1]=paf'0,27,6,7,-3,-5,', -- right (wrapped)
}

arrowframes={
 [0]=paf'50,20,2,1,-1,-0.5,', -- right
 [0.125]=paf'52,20,2,2,-1,-1,', -- right/up
 [0.25]=paf'54,20,1,2,-0.5,-1,', -- up
 [0.375]=paf'55,20,2,2,-1,-1,', -- up/left
 [0.5]=paf'50,20,2,1,-1,-0.5,', -- left
 [0.625]=paf'52,20,2,2,-1,-1,', -- left/down
 [0.75]=paf'54,20,1,2,-0.5,-1,', -- down
 [0.875]=paf'55,20,2,2,-1,-1,', -- down/right
 [1]=paf'50,20,2,1,-1,-0.5,', -- right (wrapped)
}

function getvfxframei(a)
 return min(flr((a+0.0625)*8)/8,1)
end

-- todo: this is only convenience dev function
function actorfactory(_a)
 _a.state='idling'
 _a.state_c=0
 _a.curframe=1
 _a.dx=0
 _a.dy=0
 _a.runspd=_a.spd
 _a.dmgfx_c=0
 _a.comfydist=_a.comfydist or 1
 _a.toocloseto={}

 return _a
end

function performenemymelee(_a)
 local a=atan2(
  _a.tarx-_a.x,
  _a.tary-_a.y)

 add(attacks,{
  isenemy=true,
  x=_a.x+cos(a)*4,
  y=_a.y+sin(a)*4,
  hw=2,
  hh=2,
  state_c=1,
  typ='knockback',
  knocka=a,
  dmg=1,
  tar_c=1000,
 })

 local f=clone(meleevfxframes[getvfxframei(_a.a)])
 f[5]=_a.x+cos(_a.a)*4+f[5]
 f[6]=_a.y+sin(_a.a)*4+f[6]
 f.c=10
 f.col=7

 add(vfxs,{f})

 sfx(4)
end

function performenemybow(_a)
 local a=getvfxframei(atan2(
  _a.tarx-_a.x,
  _a.tary-_a.y))

 add(attacks,{
  isenemy=true,
  x=_a.x-0.5,
  y=_a.y-0.5,
  hw=1,
  hh=1,
  state_c=1000,
  dx=cos(a)*1.6,
  dy=sin(a)*1.6,
  dmg=1,
  tar_c=1,
  frames={
   curframe=1,
   clone(arrowframes[a]),
  },
  col=2,
 })

 sfx(5)
end


-- enemy factories

function newmeleetroll(x,y)
 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=2,
  spd=0.45,
  hp=2,
  att_preprfm=50,
  att_postprfm=20,
  att_range=7,
  prfmatt=performenemymelee,
  idling={paf'41,32,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   paf'41,32,4,5,-2,-3,',
   paf'45,32,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   paf'49,32,4,5,-2,-3,',
   paf'52,32,6,5,-3,-3,',
  },
  recovering={paf'41,32,4,5,-2,-3,'},
 })
end

function newtrollcaster(x,y)
 local boltskill,idleframe=boltskillfactory(
   1,
   50,
   0,
   120,
   1,
   'fire',
   14,
   paf'8,14,',
   paf'14,8,'),
  paf'59,32,4,6,-2,-3,'

 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=2,
  spd=0.25,
  hp=1,
  att_preprfm=100,
  att_postprfm=20,
  att_range=60,
  prfmatt=function(actor)
   a,actor.a=actor.a,atan2(
     actor.tarx-actor.x,
     actor.tary-actor.y)
   boltskill.perform(actor)
   actor.a=a
  end,
  comfydist=30,
  idling={idleframe},
  moving={
   animspd=0.18,
   idleframe
  },
  attacking={
   animspd=0,
   paf'63,32,4,6,-2,-3,',
   idleframe,
  },
  recovering={idleframe},
  onpreprfm=boltskill.startpemitter,
 })
end

function newgianttroll(x,y)
 boss=actorfactory({
  name='giant troll',
  isenemy=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=3,
  isbig=true,
  spd=0.7,
  hp=7,
  att_preprfm=40,
  att_postprfm=30,
  att_range=7,
  prfmatt=performenemymelee,
  idling={paf'36,25,7,7,-4,-4,'},
  moving={
   animspd=0.18,
   paf'43,25,7,7,-4,-4,',
   paf'50,25,7,7,-4,-4,'
  },
  attacking={
   animspd=0,
   paf'57,25,7,7,-4,-4,',
   paf'64,25,8,7,-4,-4,',
  },
  recovering={paf'72,25,7,7,-4,-4,'},
 })
 return boss
end

function newmeleeskele(x,y)
 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=2,
  spd=0.5,
  hp=3,
  att_preprfm=40,
  att_postprfm=10,
  att_range=7,
  prfmatt=performenemymelee,
  idling={paf'0,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   paf'0,15,4,5,-2,-3,',
   paf'4,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   paf'8,15,4,5,-2,-3,',
   paf'11,15,6,5,-3,-3,',
  },
  recovering={paf'0,15,4,5,-2,-3,'},
 })
end

function newbatenemy(x,y)
 return actorfactory({
  isenemy=true,
  isghost=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=2,
  spd=0.75,
  hp=1,
  att_preprfm=30,
  att_postprfm=0,
  att_range=7,
  prfmatt=performenemymelee,
  idling={paf'36,15,3,3,-1.5,-1.5,'},
  moving={
   animspd=0.21,
   paf'36,15,3,3,-1.5,-1.5,',
   paf'39,15,3,3,-1.5,-1.5,'
  },
  attacking={
   animspd=0.32,
   paf'36,15,3,3,-1.5,-1.5,',
   paf'39,15,3,3,-1.5,-1.5,'
  },
  recovering={paf'36,15,3,3,-1.5,-1.5,'},
 })
end

function newbowskele(x,y)
 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=2,
  spd=0.5,
  hp=2,
  att_preprfm=60,
  att_postprfm=4,
  att_range=40,
  prfmatt=performenemybow,
  comfydist=20,
  idling={paf'18,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   paf'18,15,4,5,-2,-3,',
   paf'22,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   paf'26,15,4,5,-2,-3,',
   paf'31,15,4,5,-2,-3,'
  },
  recovering={paf'18,15,4,5,-2,-3,'},
 })
end

function newskeleking(x,y)

 function setupmelee(_a)
  _a.nolos=nil
  _a.att_range=7
  _a.att_preprfm=30
  _a.att_postprfm=60
  _a.attacking={
   animspd=0,
   paf'0,40,15,18,-7,-13,',
   paf'0,58,20,18,-10,-13,',
  }
  _a.onpreprfm=nil
  _a.prfmatt=performmelee
  _a.afterpostprfm=setupmagic
 end

 function performmelee(_a)
  add(attacks,{
   isenemy=true,
   throughwalls=true,
   x=_a.x+cos(_a.a)*2,
   y=_a.y-3,
   hw=7,
   hh=8,
   state_c=2,
   typ='knockback',
   knocka=_a.a,
   dmg=1,
   tar_c=1,
  })

  sfx(4)
 end

 function setupmagic(_a)
  _a.nolos=true
  _a.att_range=60
  _a.att_preprfm=110
  _a.att_postprfm=0
  _a.attacking={
   animspd=0,
   paf'24,58,15,18,-7,-13,',
   paf'24,58,15,18,-7,-13,',
  }
  _a.onpreprfm=magicpreprfm
  _a.prfmatt=performmagic
  _a.afterpostprfm=setupmelee
 end

 function magicpreprfm(_a)
  _a.att_x,_a.att_y=findflr(_a.x,_a.y)
  add(pemitters,{
   follow={
    x=_a.att_x,
    y=_a.att_y,
   },
   life=140,
   prate=paf'1,2,',
   plife=paf'10,15,',
   poffsets=paf'-2,0.5,1,0.5,',
   dx=paf'0,0,',
   dy=paf'-0.3,0,',
   pcolors=paf'11,3,1,',
  })

  sfx(9)
 end

 function performmagic(_a)
  local enemy=newmeleeskele(_a.att_x,_a.att_y)

  -- summoning sickness
  enemy.state='recovering'
  enemy.laststate='recovering'
  enemy.state_c=50

  add(actors,enemy)
 end

 boss=actorfactory({
  name='skeleton king',
  isenemy=true,
  isbig=true,
  x=x,
  y=y,
  a=0,
  hw=1.5,
  hh=3,
  spd=0.4,
  hp=10,
  idling={paf'0,40,15,18,-7,-13,'},
  moving={
   animspd=0.24,
   paf'16,40,15,18,-7,-13,',
   paf'32,40,15,18,-7,-13,'
  },
  recovering={paf'0,40,15,18,-7,-13,'},
  onroam=setupmagic,
 })

 setupmagic(boss)

 return boss
end


-- effects

function burningeffect(_a)
 if _a.effect.c == nil then
  _a.effect.c=0
  add(pemitters,{
   follow=_a,
   life=_a.state_c,
   prate=paf'2,4,',
   plife=paf'15,25,',
   poffsets=paf'-2,0.5,2,0.5,',
   dx=paf'0,0,',
   dy=paf'-0.3,0,',
   pcolors=paf'8,14,',
  })
 end

 _a.effect.c-=1

 if _a.effect.c <= 0 then
  _a.effect.c=12

  _a.a=rnd()
 end

 _a.dx=cos(_a.a)*_a.spd
 _a.dy=sin(_a.a)*_a.spd

end

function freezeeffect(_a)
 add(vfxs,{
  {
   57,18,8,7,
   _a.x-4,_a.y-3.5,
   c=2,
  },
 })

 _a.dx=0
 _a.dy=0
end

function stunningeffect(_a)
 if _a.effect.c == nil or
    _a.effect.c <= 0 then
  local t,x,y=
    5,
    _a.x-1.5,
    _a.y-_a.hh*2-1

  _a.effect.c=t*3
  add(vfxs,{
   {42,13,3,2, x,y, c=t,col=7},
   {42,15,3,2, x,y, c=t,col=7},
   {42,17,3,2, x,y, c=t,col=7},
  })
 end

 _a.effect.c-=1

 _a.dx,_a.dy=0,0
end

-- skills
skillfactory=function(sprite,desc,onhit,immune)
 return {
  sprite=sprite,
  desc=desc,
  onhit=onhit,
  immune=immune,
 }
end

swordattackskillfactory=function(
  dmg,
  preprfm,
  postprfm,
  tar_c,
  attackcol,
  typ,
  recovertime)
 return {
  sprite=31,
  desc='sword attack',
  preprfm=preprfm,
  postprfm=postprfm,
  perform=function(_a,skill)
   local x,y=
     _a.x+cos(_a.a)*4,
     _a.y+sin(_a.a)*4

   add(attacks,{
    x=x,
    y=y,
    hw=2,
    hh=2,
    state_c=1,
    typ=typ,
    recovertime=recovertime or 0,
    knocka=_a.a,
    dmg=dmg,
    tar_c=tar_c,
   })

   local frame=clone(meleevfxframes[_a.a])
   frame[5]=x+frame[5]
   frame[6]=y+frame[6]
   frame.c=skill.postprfm
   frame.col=attackcol

   add(vfxs,{frame})

   sfx(4)
  end,
 }
end

bowattackskillfactory=function(
  dmg,
  preprfm,
  postprfm,
  tar_c,
  attackcol,
  arrowcol,
  typ,
  recovertime)
 return {
  sprite=30,
  desc='bow attack',
  preprfm=preprfm,
  postprfm=postprfm,
  perform=function(_a,skill)
   local x,y=
     _a.x+cos(_a.a)*4,
     _a.y+sin(_a.a)*4

   add(attacks,{
    x=x-0.5,
    y=y-0.5,
    hw=1,
    hh=1,
    state_c=1000,
    dx=cos(_a.a)*1.6,
    dy=sin(_a.a)*1.6,
    dmg=dmg,
    typ=typ,
    recovertime=recovertime,
    tar_c=tar_c,
    frames={
     curframe=1,
     clone(arrowframes[_a.a]),
    },
    col=arrowcol,
   })

   local frame=clone(bowvfxframes[_a.a])
   frame[5]=x+frame[5]
   frame[6]=y+frame[6]
   frame.c=skill.postprfm
   frame.col=attackcol

   add(vfxs,{frame})

   sfx(5)
  end,
 }
end

boltskillfactory=function(
  dmg,
  preprfm,
  postprfm,
  recovertime,
  tar_c,
  effecttype,
  attackcol,
  castingpemittercols,
  boltpemittercols,
  sprite,
  desc)
 return {
  sprite=sprite,
  desc=desc,
  preprfm=preprfm,
  postprfm=postprfm,
  startpemitter=function(_a,life)
   add(pemitters,{
    follow=_a,
    life=life or _a.att_preprfm,
    prate=paf'2,4,',
    plife=paf'15,25,',
    poffsets=paf'-2,0.5,2,0.5,',
    dx=paf'0,0,',
    dy=paf'-0.3,0,',
    pcolors=castingpemittercols,
   })
   sfx(9)
  end,
  perform=function(_a)
   local x,y=
     _a.x+cos(_a.a)*4,
     _a.y+sin(_a.a)*4

   local attack={
    isenemy=_a.isenemy,
    x=x,
    y=y,
    hw=1,
    hh=1,
    state_c=1000,
    dx=cos(_a.a)*1.2,
    dy=sin(_a.a)*1.2,
    dmg=dmg,
    typ=effecttype,
    recovertime=recovertime,
    tar_c=tar_c,
    frames={
     curframe=1,
     paf'47,20,3,3, -0.5,-0.5,',
    },
    col=attackcol,
   }

   add(attacks,attack)

   add(pemitters,{
    follow=attack,
    life=1000,
    prate=paf'0,1,',
    plife=paf'3,5,',
    poffsets=paf'-1,-1,1,1,',
    dx=paf'0,0,',
    dy=paf'0,0,',
    pcolors=boltpemittercols,
   })
   sfx(32)
  end,
 }
end

-- passive skills
function phasing(_a)
 local x,y=findflr(_a.x,_a.y)
 _a.x,_a.y=x,y
 add(vfxs,{
  {9,9,1,1,0,0,c=2},
  {
   draw=function(f)
    circ(x,y,f.c*1.5,12)
   end,
   c=12,
  },
 })
end

-- items
prefix={
 { -- 1
  name='knight\'s ',
  armor=1,
 },
 { -- 2
  name='dragonscale ',
  skill=skillfactory(7,'passive, cannot be burned',nil,'fire'),
 },
}

suffix={
 { -- 1
  name=' of resurrection',
  amulet_sprite=6,
  skill=skillfactory(5,'passive, resurrect once',function (_a)
   if _a.hp <= 0 then
    _a.removeme=nil
    _a.hp=3
    _a.items.amulet=nil
    del(_a.passiveskills,suffix[1].skill)
    sfx(21)
   end
  end),
 },
 { -- 2
  name=' of haste',
  spdfactor=0.1,
 },
 { -- 3
  name=' of phasing',
  skill=skillfactory(27,'passive, phase away on hit',phasing),
 },
 { -- 4
  name=' of firebolt',
  book_sprite=45,
  skill=boltskillfactory(
    1,
    50,
    0,
    120,
    1,
    'fire',
    14,
    paf'8,14,',
    paf'14,8,',
    29,
    'firebolt'),
 },
 { -- 5
  name=' of icebolt',
  book_sprite=63,
  skill=boltskillfactory(
    0,
    40,
    0,
    150,
    1,
    'ice',
    7,
    paf'12,12,',
    paf'12,13,',
    28,
    'icebolt')
 },
 { -- 6 (sword attack)
  name=' of fire',
  col=8,
  skill=swordattackskillfactory(1,15,28,1000,14,'fire',60),
 },
 { -- 7 (bow attack)
  name='',
  col=4,
  skill=bowattackskillfactory(1,26,6,1,7,2),
 },
 { -- 8 (bow attack)
  name=' of ice',
  col=12,
  skill=bowattackskillfactory(1,26,6,1,7,12,'ice',150),
 },
 { -- 9 (sword attack)
  name=' of the bear',
  skill=swordattackskillfactory(1,15,28,1000,7,'knockback'),
 },
}

cloakidling={paf'0,6,3,4,-1,-2,'}
shieldidling={paf'35,9,5,5,-2,-3,'}
swordidling={paf'9,9,5,5,-2,-3,'}
bowidling={paf'25,9,5,5,-2,-3,'}

itemclasses={
 {
  class='boots',
  sprite=41,
  col=4,
  prefix=paf'2,',
  suffix=paf'2,',
 },
 {
  class='helmet',
  sprite=42,
  col=13,
  prefix=paf'1,',
  suffix={},
 },
 {
  class='amulet',
  sprite=25,
  prefix=paf'2,',
  suffix=paf'1,',
 },
 { -- platemail
  class='armor',
  sprite=58,
  col=6,
  prefix=paf'1,',
  suffix={},
 },
 { -- cloak
  class='armor',
  iscloak=true,
  sprite=26,
  col=2,
  col2=1,
  prefix=paf'2,',
  suffix=paf'2,3,',
  idling=cloakidling,
  moving=cloakidling,
  attacking=cloakidling,
  recovering=cloakidling,
 },
 { -- shield
  class='offhand',
  sprite=44,
  col=13,
  prefix=paf'1,2,',
  suffix=paf'3,',
  idling=shieldidling,
  moving=shieldidling,
  attacking=shieldidling,
  recovering=shieldidling,
 },
 {
  class='book',
  sprite=79,
  prefix={},
  suffix=paf'4,5,'
 },
 { -- sword
  class='weapon',
  sprite=47,
  col=6,
  prefix={},
  suffix=paf'6,9,',
  idling=swordidling,
  moving=swordidling,
  attacking={
   paf'14,9,5,5,-2,-3,',
   paf'18,9,7,5,-3,-3,'
  },
  recovering=swordidling,
 },
 { -- bow
  class='weapon',
  twohand=true,
  sprite=46,
  col=4,
  prefix={},
  suffix=paf'7,8,',
  idling=bowidling,
  moving=bowidling,
  attacking={
   paf'30,9,5,5,-2,-3,',
   paf'25,9,1,1,-2,-3,',
  },
  recovering=bowidling,
 }
}

themes={
 { -- forest
  spr1=240,
  musicstart=0,
  enemytypes={
   newmeleetroll,
   newmeleetroll,
   newtrollcaster,
   newgianttroll,
  }
 },
 { -- cave
  spr1=224,
  musicstart=3,
  enemytypes={
   newbatenemy,
   newmeleeskele,
   newbowskele,
   newskeleking,
  }
 },
 { --  catacombs
  spr1=208,
  musicstart=0,
  enemytypes={
   newbatenemy,
   newmeleeskele,
   newbowskele,
   newskeleking,
  }
 },
}


function dungeoninit()
 _update60,_draw=
   dungeonupdate,
   dungeondraw

 sword={
  class='weapon',
  name='sword',
  sprite=47,
  col=6,
  suffix={
   skill=swordattackskillfactory(1,15,28,1000,7),
  },
  curframe=1,
  idling=swordidling,
  moving=swordidling,
  attacking={
   paf'14,9,5,5,-2,-3,',
   paf'18,9,7,5,-3,-3,',
  },
  recovering=swordidling,
 }

 idleframe=paf'0,10,3,4,-1,-2,'

 avatar=actorfactory({
  x=64,
  y=56,
  hw=1.5,
  hh=2,
  a=0,
  spdfactor=1,
  spd=0.5,
  hp=3,
  startarmor=0,
  armor=0,
  items={
   weapon=sword,
   -- offhand=nil,
   -- armor=nil,
   -- boots=nil,
   -- helmet=nil,
   -- book=nil,
   -- amulet=nil,
  },
  inventory={},
  skill1=sword.suffix.skill,
  -- skill2=nil,
  -- currentskill=nil,
  passiveskills={},
  idling={idleframe},
  moving={
   idleframe,
   paf'3,10,3,4,-1,-2,'
  },
  attacking={
   animspd=0,
   paf'6,10,3,4,-1,-2,',
   idleframe
  },
  recovering={idleframe},
 })

 dungeonlvl=1
 theme=1
 nexttheme=1

 for theme in all(themes) do
  theme.lvl_c=2+flr(rnd()*1)
 end

 mapinit()
end

function nextfloor()
 theme=nexttheme
 dungeonlvl+=1
 mapinit()
end

curenemyi=1
tick=0
kills=0

function mapinit()
 local basemap={}
 for _y=-1,16 do
  basemap[_y]={}
  for _x=-1,16 do
   basemap[_y][_x]=1
  end
 end

 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)

 if theme == 1 and door then
  local doorx,doory=flr(door.x/8),flr(door.y/8)
  if doorx == 0 then
   avatarx=14
  elseif doorx == 15 then
   avatarx=1
  elseif doory == 0 then
   avatary=14
  elseif doory == 15 then
   avatary=1
  end
 end

 local curx,cury=avatarx,avatary
 local a=0
 local steps=500
 local step_c=steps
 local enemy_c=10
 local enemytypes=paf'5,6,7,'
 local enemies={}
 local angles=paf'-0.25,0.25,'
 themes[theme].lvl_c-=1

 while step_c > 0 do

  local nextx,nexty=curx+cos(a),cury+sin(a)

  if flr(rnd(3)) == 0 or
     nextx <= 0 or
     nextx > 14 or
     nexty <= 0 or
     nexty > 14 then
   a+=angles[flr(rnd(#angles)+1)]
  elseif step_c != 0 and step_c % (steps / enemy_c) == 0 then
   add(enemies,{
    x=curx,
    y=cury,
    typ=enemytypes[flr(rnd(#enemytypes)+1)],
   })
  else
   curx=nextx
   cury=nexty
   basemap[cury][curx]=0
  end
  step_c-=1
 end

 for enemy in all(enemies) do
  basemap[enemy.y][enemy.x]=enemy.typ
 end

 if themes[theme].lvl_c == 0 then
  local enemy=enemies[#enemies]
  basemap[enemy.y][enemy.x]=8
  nexttheme+=1
 end

 -- door
 if nexttheme == 1 then
  if abs(a%1) == 0.25 then
   a=0.75
  end
  while curx > 0 and
     curx < 15 and
     cury > 0 and
     cury < 15 do
   basemap[cury][curx]=0
   curx+=cos(a)
   cury+=sin(a)
  end
 end
 basemap[cury][curx]=2

 basemap[avatary][avatarx]=15

 -- reset
 curenemyi,
 tick,
 isdoorspawned,
 boss,
 walls,
 actors,
 attacks,
 pemitters,
 vfxs,
 interactables=
   1,
   0,
   nil,
   nil,
   {},
   {},
   {},
   {},
   {},
   {}

 for _y=-1,16 do
  walls[_y]={}
  for _x=-1,16 do
   local _col,ax,ay=
     basemap[_y][_x],
     _x*8+4,
     _y*8+4

   -- create avatar
   if _col == 15 then
    avatar=actorfactory(avatar)
    avatar.x,avatar.y=ax,ay
    avatar.armor=avatar.startarmor

    add(actors,avatar)

    -- add mule
    add(interactables,{
     x=avatar.x,
     y=avatar.y,
     hw=4,
     hh=2.5,
     sprite=2,
     text='\x8e inventory',
     enter=function ()
      if btnp(4) then
       equipinit()
      end
     end,
    })

    _col=0
   end

   -- create enemy
   if _col >= 5 and _col <= 8 then
    add(actors,
      themes[theme].enemytypes[_col-4](ax,ay))
    _col=0
   end

   -- create door
   if _col == 2 then

    door={
     x=ax,
     y=ay,
     hw=4,
     hh=4,
     sprite=themes[nexttheme].spr1+2,
     text='\x8e go deeper',
     enter=function()
      if btnp(4) then
       nextfloor()
      end
     end,
    }

    add(interactables,door)

    _col=0
    if theme == 1 then
     _col=1
    end
   end

   -- set walls value
   walls[_y][_x]=_col
  end
 end

 -- start theme music
 music(themes[theme].musicstart,0,0b0011)
 if boss then
  music(7)
 end

end

function dungeonupdate()

 --note: devkit debug
 -- if stat(30)==true then
 --  c=stat(31)
 --  if c == 'd' then
 --   isdebug=not isdebug
 --   debug('isdebug',isdebug)
 --  end
 -- end

 tick+=1

 if tick < 120 then
  curinteractable=nil
  return
 end

 if avatar.hp <= 0 then
  if tick-deathts > 150 and btnp(4) then
   kills=0
   dungeoninit()
  end
  return
 end

 local angle=btnmasktoangle[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle then
  if avatar.state != 'recovering' and
     avatar.state != 'attacking' then
   avatar.a=angle
   avatar.dx=norm(cos(avatar.a))
   avatar.dy=norm(sin(avatar.a))
   avatar.state='moving'
   avatar.state_c=2
  end
 elseif avatar.state != 'recovering' then
  avatar.dx,avatar.dy=0,0
 end

 -- consider skill button input
 local skillbuttondown=0
 if btn(4) then
  skillbuttondown=1
 elseif btn(5) then
  skillbuttondown=2
 end

 if skillbuttondown != 0 and
    (avatar.state == 'idling' or
     avatar.state == 'moving') then

  local skill=avatar['skill'..skillbuttondown]

  if skill then
   avatar.state='attacking'
   avatar.currentskill=skill
   avatar.ispreprfm=true

   avatar.state_c=skill.preprfm

   avatar.curframe=1
   if avatar.items.weapon then
    avatar.items.weapon.curframe=1
   end

   if avatar.currentskill.startpemitter then
    avatar.currentskill.startpemitter(avatar,skill.preprfm)
   end
  end
 end

 -- update actors
 local enemy_c=0
 for actor in all(actors) do
  if actor.isenemy then
   enemy_c+=1
  end

  if actor.state_c > 0 then
   actor.state_c-=1
  end

  -- handle states
  if actor.state == 'idling' then

   -- reset enemy specifics
   actor.tarx,actor.tary=nil,nil
   actor.ismovingoutofcollision=nil

  elseif actor.state == 'attacking' then

   if actor == avatar then

    -- update skills
    if avatar.state_c <= 0 then
     if avatar.ispreprfm then

      local skill=avatar.currentskill
      skill.perform(avatar,skill)

      -- set avatar to postperform
      avatar.state_c=skill.postprfm
      avatar.ispreprfm=false

      -- set next attacking frame
      avatar.curframe=2
      if avatar.items.weapon then
       avatar.items.weapon.curframe=2
      end

     else -- note: done performing
      avatar.state='idling'
      if avatar.items.weapon then
       avatar.items.weapon.curframe=1
      end
     end
    end


   else -- enemies

    if actor.laststate != 'attacking' then
     actor.ispreprfm=true
     actor.curframe=1
     actor.state_c=actor.att_preprfm

     if actor.onpreprfm then
      actor.onpreprfm(actor)
     end
    end

    if actor.ispreprfm and actor.state_c <= 0 then
     actor.prfmatt(actor)
     actor.ispreprfm=false
     actor.state_c=actor.att_postprfm
     actor.curframe=2

    elseif actor.state_c <= 0 then
     if actor.afterpostprfm then
      actor.afterpostprfm(actor)
     end
     actor.state='idling'
    end
   end

  elseif actor.state == 'recovering' then

   if actor.effect then
    actor.effect.func(actor)
   end

   if actor.state_c <= 0 then
    actor.state='idling'
    actor.effect=nil
   end

  elseif actor.state == 'moving' and
         actor.isenemy then

   if actor.state_c <= 0 then
    actor.ismovingoutofcollision=nil
   end

   actor.a=atan2(
     actor.tarx-actor.x,
     actor.tary-actor.y)

   if dist(
       actor.x,
       actor.y,
       actor.tarx,
       actor.tary) <= actor.spd + 0.1 then
    actor.state='idling'
   end

   actor.dx=cos(actor.a)*actor.spd
   actor.dy=sin(actor.a)*actor.spd

  end

  if actor == avatar and
     actor.state_c <= 0 then
   actor.state='idling'
   actor.currentskill=nil
  end

  actor.laststate=actor.state
 end


 -- ai to make decisions
 curenemyi+=1
 if curenemyi > #actors then
  curenemyi=1
 end
 do
  local enemy=actors[curenemyi]
  if enemy and enemy.isenemy then

   -- todo: ai should have aggravator instead of
   --       avatar hard-coded

   -- aggression vars
   local disttoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)
   local inattdist=disttoavatar <= enemy.att_range
   local haslostoavatar=haslos(enemy.x,enemy.y,avatar.x,avatar.y)
   local isattacking=enemy.state == 'attacking'

   -- movement vars
   local collidedwithwall=enemy.wallcollisiondx != nil
   local istooclosetoavatar=disttoavatar <= enemy.comfydist
   local hastoocloseto=#enemy.toocloseto > 0
   local hastarget=enemy.tarx!=nil

   -- resolving effect
   if enemy.state=='recovering' then

   -- continue to move out of collision
   elseif enemy.ismovingoutofcollision then

    enemy.state='moving'

   -- too close to avatar, note: collidedwithwall not working here?
   elseif istooclosetoavatar and (not isattacking) and (not collidedwithwall) then

    enemy.state='moving'
    enemy.a=atan2(
      avatar.x-enemy.x,
      avatar.y-enemy.y)+0.5 -- note: go the other way
    enemy.tarx=enemy.x+cos(enemy.a)*10
    enemy.tary=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_c=60
    enemy.spd=enemy.runspd

   -- attack
   elseif isattacking or inattdist and
         (haslostoavatar or enemy.nolos) then

    if enemy.laststate != 'attacking' then
     enemy.curframe=1
    end

    enemy.state='attacking'
    enemy.tarx=avatar.x
    enemy.tary=avatar.y
    -- todo: swing timer

   -- colliding w wall, move out of
   elseif collidedwithwall then

    enemy.state='moving'
    enemy.a=atan2(
      enemy.x+enemy.wallcollisiondx-enemy.x,
      enemy.y+enemy.wallcollisiondy-enemy.y)+rnd(0.2)-0.1
    enemy.tarx=enemy.x+cos(enemy.a)*10
    enemy.tary=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_c=60

   -- colliding w other, move out of
   elseif hastoocloseto then

    enemy.state='moving'
    local collidedwith=enemy.toocloseto[1]
    enemy.a=atan2(
      collidedwith.x-enemy.x,
      collidedwith.y-enemy.y)+0.5 -- note: go the other way
    enemy.tarx=enemy.x+cos(enemy.a)*10
    enemy.tary=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_c=60

   -- set avatar position as tar, move there
   elseif haslostoavatar then

    enemy.state='moving'
    enemy.tarx=avatar.x
    enemy.tary=avatar.y
    enemy.a=atan2(
      enemy.tarx-enemy.x,
      enemy.tary-enemy.y)
    enemy.spd=enemy.runspd

   -- continue to move to tar
   elseif hastarget then

    enemy.state='moving'

   -- roam
   elseif not hastarget then

    enemy.state='moving'
    enemy.a=rnd()
    enemy.tarx=enemy.x+cos(enemy.a)*10
    enemy.tary=enemy.y+sin(enemy.a)*10
    enemy.spd=enemy.runspd*0.5

    if enemy.onroam then
     enemy.onroam(enemy)
    end

   end
  end
 end

 -- update the next-position
 for actor in all(actors) do

  local spdfactor=1
  if actor.spdfactor then
   spdfactor=actor.spdfactor
  end
  actor.dx=actor.dx*(actor.spd*spdfactor)
  actor.dy=actor.dy*(actor.spd*spdfactor)

  -- note: after this deltas should not change by input
 end

 -- check lvl cleared
 if enemy_c <= 0 and not isdoorspawned then
  isdoorspawned=true
  walls[(door.y-4)/8][(door.x-4)/8]=0
  music(20)
 end

 -- collide against interactables
 curinteractable=nil
 if isdoorspawned then
  for i in all(interactables) do
   if isaabbscolliding(avatar,i) then
    i.enter(i)
    curinteractable=i
   end
  end
 end

 -- collide against attacks
 for attack in all(attacks) do
  for _a in all(actors) do
   if (not attack.removeme) and
      (not _a.removeme) and
      attack.isenemy != _a.isenemy and
      isaabbscolliding(attack,_a) then

    attack.tar_c-=1

    local hitsfx=6

    -- special case if ice and already frozen
    if attack.typ == 'ice' and
       _a.effect and
       _a.effect.func == freezeeffect then
     attack.dmg=max(attack.dmg,1)
    end

    for skill in all(_a.passiveskills) do
     if attack.typ != nil and
        skill.immune == attack.typ then
      attack.dmg=0
      attack.recovertime=nil
      attack.typ=nil
     end
    end

    -- do dmg
    if _a.armor and _a.armor > 0 then
     _a.armor-=attack.dmg
     if _a.armor < 0 then
      _a.hp+=_a.armor
      _a.armor=0
     end
    else
     _a.hp-=attack.dmg
    end

    -- go into recovering
    _a.state='recovering'
    if attack.recovertime then
     _a.state_c=attack.recovertime
    else
     _a.state_c=0
    end

    -- check if _a dead
    if _a.hp <= 0 then
     _a.removeme=true
     kills+=1
     hitsfx=3

     -- add chest
     if kills % 5 == 0 then
      add(interactables,{
       x=_a.x,
       y=_a.y,
       hw=4,
       hh=4,
       sprite=22,
       text='\x8e loot',
       enter=function(i)
        if btnp(4) and not i.isopen then
         if #avatar.inventory >= 10 then
          i.text='inventory full, \x8e try again'
          sfx(7)
         else
          i.isopen=true
          i.text='[empty]'
          i.sprite=23

          local itemclass=itemclasses[
            flr(rnd(#itemclasses))+1]
          local _prefix=flr(rnd(#prefix))+1
          local _suffix=flr(rnd(#suffix))+1

          local itemname=itemclass.class
          local armor=0
          local spdfactor=0
          local sprite=itemclass.sprite

          if has(itemclass.prefix,_prefix) then
           _prefix=prefix[_prefix]
           itemname=_prefix.name..itemname
           armor+=(_prefix.armor or 0)
           spdfactor+=(_prefix.spdfactor or 0)
           sprite=_prefix[itemclass.class..'_sprite']
          else
           _prefix=nil
          end

          if has(itemclass.suffix,_suffix) then
           _suffix=suffix[_suffix]
           itemname=itemname.._suffix.name
           armor+=(_suffix.armor or 0)
           spdfactor+=(_suffix.spdfactor or 0)
           sprite=_suffix[itemclass.class..'_sprite']
          else
           _suffix=nil
          end

          if _prefix == nil and _suffix == nil then
           itemname='useless '..itemname
          end

          local item={
           class=itemclass.class,
           name=itemname,
           sprite=sprite or itemclass.sprite,
           col=itemclass.col,
           col2=itemclass.col2,
           prefix=_prefix,
           suffix=_suffix,
           armor=armor,
           spdfactor=spdfactor,
           iscloak=itemclass.iscloak,
           curframe=1,
           idling=itemclass.idling,
           moving=itemclass.moving,
           attacking=itemclass.attacking,
           recovering=itemclass.recovering,
          }

          add(avatar.inventory,item)
          sfx(20)
         end
        end
       end,
      })
     end

     -- todo: add death vfx here
    end

    -- effects

    _a.dmgfx_col=8 -- note: red is default color

    if attack.typ == 'knockback' and not _a.isbig then
     _a.dx=cos(attack.knocka)*5
     _a.dy=sin(attack.knocka)*5

    elseif attack.typ == 'fire' then
     _a.effect={func=burningeffect}

    elseif attack.typ == 'stun' then
     _a.effect={func=stunningeffect}

    elseif attack.typ == 'ice' then
     _a.effect={func=freezeeffect}
     _a.dmgfx_col=12
    end

    sfx(hitsfx)

    -- vfx

    -- start dmg indication
    _a.dmgfx_c=20

    -- hit flash
    local x,y=
      _a.x+_a.dx/2,
      _a.y+_a.dy/2
    add(vfxs,{
     {42,20,5,5,x-2.5,y-2.5,c=4,col=_a.dmgfx_col},
     {42,20,5,5,x-2.5,y-2.5,c=5,col=7},
    })

    -- on hit handling
    for skill in all(_a.passiveskills) do
     if skill.onhit then
      skill.onhit(_a)
     end
    end
   end
  end
 end

 -- reset toocloseto
 for _a in all(actors) do
  _a.toocloseto={}
 end

 -- enemies movement check against others
 for i=1,#actors-1 do
  for j=i+1,#actors do
   local enemy=actors[i]
   local other=actors[j]
   if enemy != other and
      enemy != avatar and
      other != avatar and
      enemy.isenemy and
      dist(
        enemy.x,
        enemy.y,
        other.x,
        other.y) < enemy.hh + other.hh then
    add(enemy.toocloseto,other)
    add(other.toocloseto,enemy)
   end
  end
 end

 -- avatar movement check against other actors
 for _a in all(actors) do
  if _a != avatar and not _a.isghost then
   local _dx,_dy=collideaabbs(
     isaabbscolliding,
     avatar,
     _a,
     avatar.dx,
     avatar.dy)

   avatar.dx,avatar.dy=_dx,_dy
  end
 end

 -- movement check against walls
 for _a in all(actors) do
  local _dx,_dy=collideaabbs(
    isinsidewall,
    _a,
    nil,
    _a.dx,
    _a.dy)

  if _a.isenemy then
   _a.wallcollisiondx=nil
   _a.wallcollisiondy=nil
   if _dx != _a.dx or
      _dy != _a.dy then
    _a.wallcollisiondx=_dx
    _a.wallcollisiondy=_dy
   end
  end

  _a.x+=_dx
  _a.y+=_dy
  _a.dx,_a.dy=0,0
 end

 -- update attacks
 for attack in all(attacks) do
  if attack.state_c then
   attack.state_c-=1
   if attack.state_c <= 0 or
      attack.tar_c <= 0 then
    attack.removeme=true
   end
  end

  if attack.dx then
   attack.x+=attack.dx
  end

  if attack.dy then
   attack.y+=attack.dy
  end

  if attack.x > 128 or
     attack.x < 0 or
     attack.y > 128 or
     attack.y < 0 then
   attack.removeme=true
  end

  if not attack.throughwalls and
     isinsidewall(attack) then
   attack.removeme=true
  end
 end

 -- update dmg indicator
 for _a in all(actors) do
  if _a.dmgfx_c > 0 then
   _a.dmgfx_c-=1
  end
 end

 -- update actor animation frames
 for _a in all(actors) do
  local stateframes=_a[_a.state]

  local animspd=0.25 -- note: default
  if stateframes.animspd then
   animspd=stateframes.animspd
  end
  _a.curframe+=animspd*_a.spd

  if _a.curframe >= #stateframes+1 then
   _a.curframe=1
  end
 end

 -- update vfx
 for vfx in all(vfxs) do
  vfx[1].c-=1
  if vfx[1].c <= 0 then
   del(vfx,vfx[1])
  end

  if not(#vfx > 0) then
   vfx.removeme=true
  end
 end

 -- update pemitters
 for _p in all(pemitters) do
  if not _p.c then
   _p.c=_p.prate[1]
  end
  if not _p.particles then
   _p.particles={}
  end
  _p.c-=1
  if _p.c <= 0 then
   local x,y,poffsets,pdx,pdy=
     _p.follow.x,
     _p.follow.y,
     _p.poffsets,
     _p.dx,
     _p.dy

   x+=poffsets[1]+rnd(poffsets[3]+abs(poffsets[1]))
   y+=poffsets[2]+rnd(poffsets[4]+abs(poffsets[2]))

   local dx,dy=
     pdx[1]+rnd(pdx[2]+abs(pdx[1])),
     pdy[1]+rnd(pdy[2]+abs(pdy[1]))

   add(_p.particles,{
    c=
      _p.plife[1]+rnd(_p.plife[2]),
    x=x,
    y=y,
    dx=dx,
    dy=dy,
   })

   _p.c=
     _p.prate[1]+rnd(_p.prate[2])
  end

  _p.life-=1
  if _p.life <= 0 then
   _p.removeme=true
  end

  -- update this pemitters particles
  for par in all(_p.particles) do
   par.c-=1
   par.col=_p.pcolors[1]
   par.x+=par.dx
   par.y+=par.dy
   if par.c <= _p.plife[1] then
    par.col=_p.pcolors[2]
   end

   if par.c <= 0 then
    del(_p.particles,par)
   end
  end

 end

 -- remove pemitters
 for _p in all(pemitters) do
  if _p.removeme or
     _p.follow.removeme then
   del(pemitters,_p)
  end
 end

 -- remove actors
 for _a in all(actors) do
  if _a.removeme then
   del(actors,_a)
  end
 end

 -- remove attacks
 for attack in all(attacks) do
  if attack.removeme then
   del(attacks,attack)
  end
 end

 -- remove vfxs
 for vfx in all(vfxs) do
  if vfx.removeme then
   del(vfxs,vfx)
  end
 end

 -- play death sound
 if avatar.hp <= 0 then
  music(-1)
  deathts=tick
  sfx(2)
 end
end


function dungeondraw()
 cls(0)

 -- get theme start sprite
 local spr1=themes[theme].spr1

 -- draw walls
 for _y=0,#walls do
  for _x=0,#walls[_y] do
   if walls[_y][_x] != 0 then
    if _y == #walls or walls[_y+1] and walls[_y+1][_x] != 0 then
     spr(spr1+1,_x*8,_y*8)
    else
     spr(spr1,_x*8,_y*8)
    end
   end
  end
 end

 -- draw interactables
 if isdoorspawned then
  for _i in all(interactables) do
   spr(
    _i.sprite,
    _i.x-_i.hw,
    _i.y-_i.hh)
  end
 end

 -- draw attacks
 for attack in all(attacks) do

  if attack.frames then
   local f=attack.frames[attack.frames.curframe]
   if attack.col then
    pal(2,attack.col,0)
   end
   sspr(
    f[1],
    f[2],
    f[3],
    f[4],
    attack.x+f[5],
    attack.y+f[6],
    f[3],
    f[4])

   pal(2,2,0)
  end
 end

 -- todo: sort on y and z
 --       maybe z can be layers?
 --       per z add 128 (plus margin)
 --       to y when sorting

 -- draw actors
 for _a in all(actors) do

  -- draw actor frame
  local state,flipx=_a.state,false
  local f=_a[state][flr(_a.curframe)]
  if _a.a and _a.a >= 0.25 and _a.a <= 0.75 then
   flipx=true
  end

  -- draw item colors
  if _a == avatar then
   if avatar.items.helmet then
    pal(15,avatar.items.helmet.col,0)
   end
   if avatar.items.armor then
    pal(4,avatar.items.armor.col,0)
   end
   if avatar.items.boots then
    pal(2,avatar.items.boots.col,0)
   end
  end

  -- draw dmg overlay color
  if _a.dmgfx_c > 0 then
   for i=1,15 do
    pal(i,_a.dmgfx_col,0)
   end
  end

  sspr(
    f[1],
    f[2],
    f[3],
    f[4],
    _a.x+f[5],
    _a.y+f[6],
    f[3],
    f[4],
    flipx)

  -- draw weapon
  if _a == avatar and
     avatar.items.weapon then
   item=avatar.items.weapon
   local stateframes=item[state]
   local f=stateframes[min(
     flr(item.curframe),
     #stateframes)]
   pal(6,item.col,0)
   sspr(
     f[1],
     f[2],
     f[3],
     f[4],
     _a.x+f[5],
     _a.y+f[6],
     f[3],
     f[4],
     flipx)
  end

  -- draw offhand
  if _a == avatar and
     avatar.items.offhand then
   item=avatar.items.offhand
   local stateframes=item[state]
   local f=stateframes[min(
     flr(item.curframe),
     #stateframes)]
   pal(6,item.col,0)
   sspr(
     f[1],
     f[2],
     f[3],
     f[4],
     _a.x+f[5],
     _a.y+f[6],
     f[3],
     f[4],
     flipx)
  end

  -- draw cloak
  if _a == avatar and
     avatar.items.armor and
     avatar.items.armor.iscloak then
   item=avatar.items.armor
   local stateframes=item[state]
   local f=stateframes[min(
     flr(item.curframe),
     #stateframes)]
   pal(1,item.col,0)
   pal(3,item.col2,0)
   sspr(
     f[1],
     f[2],
     f[3],
     f[4],
     _a.x+f[5],
     _a.y+f[6],
     f[3],
     f[4],
     flipx)
  end

  -- reset colors
  for i=1,15 do
   pal(i,i,0)
  end

 end

 -- draw vfx
 for vfx in all(vfxs) do
  local f=vfx[1]
  if f.draw then
   f.draw(f)
  else
   pal(7,f.col,0)
   sspr(
     f[1],
     f[2],
     f[3],
     f[4],
     f[5],
     f[6])
   pal(7,7,0)
  end
 end

 -- draw particles
 for _p in all(pemitters) do
  for par in all(_p.particles) do
   pset(
     par.x,
     par.y,
     par.col)
  end
 end

 -- draw interactable text
 if curinteractable then
  print(
   curinteractable.text,
   mid(
     0,
     curinteractable.x-#curinteractable.text*2,
     124-#curinteractable.text*4),
   max(8,curinteractable.y-8),
   10)
 end

 -- draw gui
 offset=0
 for _i=0,avatar.hp-1 do
  print('\x87',121-_i*6,1,8)
  offset=(_i+1)*6-1
 end

 for _i=0,avatar.startarmor-1 do
  x=0
  if _i >= avatar.armor then
   x=5
  end
  sspr(x,0,5,5,121-offset-_i*6,1)
 end

 if dungeonlvl > 0 then
  print('level '..dungeonlvl,3,1,6)
 end

 if avatar.hp <= 0 then
  print('a deadly blow',40,60,8)
  if tick-deathts > 150 then
   print('press \x8e to continue',26,68,8)
  end
 end

 -- draw boss hp
 if boss and boss.hp > 0 then
  local hw=boss.hp*6/2
  rectfill(64-hw,123,64+hw,125,8)
  print(boss.name,64-#boss.name*2,122,15)
 end

end




-- equip scene

inventorycur,
equippedcur,
availableskillscur,
sectioncur,
equipped,
availableskills,
equipslots=
  1,
  1,
  1,
  4,
  {},
  {},
  {
   {'helmet',10},
   {'armor',11},
   {'amulet',8},
   {'boots',9},
   {'book',13},
   {'offhand',12},
   {'weapon',15},
  }

function equipinit()
 _update60=equipupdate
 _draw=equipdraw
 poke(0x5f43,0b0011) -- note: undocumented lopass
end

function equipupdate()

 -- init equipped items
 avatar.startarmor=0
 avatar.spdfactor=1
 equipped={}
 for _,item in pairs(avatar.items) do
  add(equipped,item)
  if item.armor then
   avatar.startarmor+=item.armor
  end
  if item.spdfactor then
   avatar.spdfactor+=item.spdfactor
  end
 end

 -- init available active skills
 availableskills={}
 for item in all(equipped) do
  if item.prefix and
     item.prefix.skill and
     item.prefix.skill.perform then
   add(availableskills,item.prefix.skill)
  end
  if item.suffix and
     item.suffix.skill and
     item.suffix.skill.perform then
   add(availableskills,item.suffix.skill)
  end
 end

 -- init available passive skills
 avatar.passiveskills={}
 for item in all(equipped) do
  if item.prefix and
     item.prefix.skill
     and not item.prefix.skill.perform then
   add(availableskills,item.prefix.skill)
   add(avatar.passiveskills,item.prefix.skill)
  end
  if item.suffix and
     item.suffix.skill
     and not item.suffix.skill.perform then
   add(availableskills,item.suffix.skill)
   add(avatar.passiveskills,item.suffix.skill)
  end
 end

 -- changing sections
 if btnp(2) then
  sectioncur=mid(1,sectioncur-1,4)
  sfx(7)
 elseif btnp(3) then
  sectioncur=mid(1,sectioncur+1,4)
  sfx(7)
 end

 -- init inventory
 for item in all(avatar.inventory) do
  if avatar.items[item.class] == item then
   del(avatar.inventory,item)
  end
 end

 -- inventory
 if sectioncur == 1 then
  if btnp(0) then
   inventorycur=mid(1,inventorycur-1,#avatar.inventory)
   sfx(7)
  elseif btnp(1) then
   inventorycur=mid(1,inventorycur+1,#avatar.inventory)
   sfx(7)
  end

  if #avatar.inventory > 0 then
   if btnp(4) then
    local selecteditem=avatar.inventory[inventorycur]

    avatar.skill1,avatar.skill2=nil,nil

    if avatar.items[selecteditem.class] then
     add(avatar.inventory,avatar.items[selecteditem.class])
    end

    avatar.items[selecteditem.class]=selecteditem

    if selecteditem.twohand then
     add(avatar.inventory,avatar.items.offhand)
     avatar.items.offhand=nil
    end

    if selecteditem.class == 'offhand' and
       avatar.items.weapon and
       avatar.items.weapon.twohand then
     add(avatar.inventory,avatar.items.weapon)
     avatar.items.weapon=nil
    end

    inventorycur=mid(1,inventorycur,#avatar.inventory-1)

    sfx(8)

   elseif btnp(5) then
    if sellcur then
     del(avatar.inventory,avatar.inventory[sellcur])
     avatar.skill1,avatar.skill2=nil,nil

     sfx(21)
    else
     sellcur=inventorycur
    end
   end
  end

 -- equipped
 elseif sectioncur == 2 then
  sellcur=nil
  if btnp(0) then
   equippedcur=mid(1,equippedcur-1,#equipslots)
   sfx(7)
  elseif btnp(1) then
   equippedcur=mid(1,equippedcur+1,#equipslots)
   sfx(7)
  end

  if btnp(4) then
   if #avatar.inventory >= 10 then
    sfx(6)
   else
    local selectedclass=equipslots[equippedcur][1]
    local selecteditem=avatar.items[selectedclass]
    if selecteditem then
     avatar.items[selecteditem.class]=nil
     add(avatar.inventory,selecteditem)
     avatar.skill1,avatar.skill2=nil,nil
    end
    sfx(8)
   end
  end

 -- available skills
 elseif sectioncur == 3 then
  if btnp(0) then
   availableskillscur=mid(1,availableskillscur-1,#availableskills)
   sfx(7)
  elseif btnp(1) then
   availableskillscur=mid(1,availableskillscur+1,#availableskills)
   sfx(7)
  end

  local selectedskill=availableskills[availableskillscur]

  if selectedskill then
   if btnp(4) then
    if selectedskill.perform then
     avatar.skill1=selectedskill
     if avatar.skill2 == avatar.skill1 then
      avatar.skill2=nil
     end
     sfx(8)
    else
     sfx(6)
    end
   end
   if btnp(5) then
    if selectedskill.perform then
     avatar.skill2=selectedskill
     if avatar.skill1 == avatar.skill2 then
      avatar.skill1=nil
     end
     sfx(8)
    else
     sfx(6)
    end
   end
  end

 -- exit
 elseif sectioncur == 4 then
  if btnp(4) or btnp(5) then
   _draw=dungeondraw
   _update60=dungeonupdate
   poke(0x5f43,0)
  end
 end

end

function equipdraw()

 cls(0)

 fillp(0b1010000110000101)
 rectfill(0,0,128,3,1)
 fillp()

 -- draw inventory section
 local offsetx,y,i,col=0,17,1,0
 if sectioncur == 1 then
  col=10
 else
  col=4
 end
 print('saddlebags',4,y-9,col)
 for item in all(avatar.inventory) do
  spr(item.sprite,6+offsetx,y)
  if sectioncur == 1 and i == inventorycur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)

   if i == sellcur then
    sspr(10,0,5,5,offsetx+4,y-2)
   end

   print(
    item.name,
    4,
    y+12,
    7)
  end

  offsetx+=12
  i+=1
 end

 -- draw equipped section
 offsetx,y,i=0,52,1
 if sectioncur == 2 then
  col=10
 else
  col=4
 end
 print('equipped',4,y-9,col)
 for slot in all(equipslots) do
  local item=avatar.items[slot[1]]
  if not item then
   spr(slot[2],6+offsetx,y)
  else
   spr(item.sprite,6+offsetx,y)
  end

  if sectioncur == 2 and i == equippedcur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)

   if item then
    print(
     item.name,
     4,
     y+12,
     7)
   end
  end

  offsetx+=12
  i+=1
 end

 -- draw availableskills section
 offsetx,y,i=0,88,1
 if sectioncur == 3 then
  col=10
 else
  col=4
 end
 print('skills',4,y-9,col)
 for skill in all(availableskills) do
  spr(skill.sprite,6+offsetx,y)
  if sectioncur == 3 and i == availableskillscur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)

    if skill then
     print(
      skill.desc,
      4,
      y+21,
      7)
    end
  end

  if skill == avatar.skill1 then
   spr(24,6+offsetx,y+12)
   print('\x8e',6+offsetx+1,y+12,11)
  end
  if skill == avatar.skill2 then
   spr(24,6+offsetx,y+12)
   print('\x97',6+offsetx+1,y+12,8)
  end

  offsetx+=12
  i+=1
 end

 -- draw exit button
 if sectioncur == 4 then
  col=10
 else
  col=4
 end
 print('exit',57,120,col)

end


_init=function()
 music(11)
 _update60=function()
  tick+=1
  if btnp(4) then
   dungeoninit()
  end
 end
 _draw=function()
  cls(1)
  sspr(79,99,49,29,42,32)
  col=7
  if tick % 60 <= 30 then
   col=13
  end
  print('\x8e to start',42,118,col)
 end
end

__gfx__
66666555550888000000000000000000000000001d1111110d555500111111110555550000000000055555000550055005555550005555500000005500000055
6ddd651115878780000005400000000000000000ddd11111d00000501d11d1115000005055505500555555505555555505555550050000000000055000000555
6ddd6511158878800022544400000000000000001d11111150000050111dd1d15000005055505500555555505055550505555550055555000000505000005550
06d60051508787800544440000000000000000001d1dddd1055005001d1d1dd10550050055505500500500505055550505555550055555000005005050055500
0060000500088800504004000000000000000000111d1d11007766001dd111d10005500055505500550005500055550005555550055555000050050005555000
00000000000000000050050000000000000000001111d1d1007161001ddd1dd10055550055550550550005500055550005555550055555000500500000550000
0f000000000000000000000000000000000000001111dd11000716001dd1d1d10055550055555055550005500055550000555500055555005555000005050000
11100000000000000000000000000000000000001111111100066000111111110005500005555055050005000000000000055000055555005000000050005000
13100000000000000000000000000000000000000000000000000000000000000111111006dddd000080020011111ddd11111111111111111111114411111166
131000000000000066000000000060000000000000000000000000000000000011111111600000d0078882e0111111dd11111111111111111111164111111666
0f00f00f40000600000000000000060006000000000000000000000000000000111111110ddd0d0008777e201d111d1d11dc1cc1112818811111614111116761
444444440000060000000006600006000066600000000000000000000242242011111111000eee0008800820ddd1d111d111c77c21118ee81116114191167611
04004004000000000000000000006000060660000000000002422420011111100111111000e888e0088008201d11111111c1c77c11818ee81161151119676111
20202020200000000000000000000000000000000000600002299220022992200000000000e8e28008800820d1d1d1d111111cc1111118811611511111961111
000000000000000000000000000000000000000000700000024444200244442000000000008222800880082011111dd111111111111111114444112114191111
000000000dd000000000200020000000020050505060000002222220022222200000000000088800880000821111ddd111111111111111114111111291119111
060d060d0660060000060206020620006020555555007000000000000000000000000000000000000006d00005600d5000000000008888800000004200000066
666d666d6600666dd0066206626662066620050505060000000000000000000000000000444420200066d500d556d55d0066dd0008ffff40000006400000066d
060006000600060000062006200620006020000000070000000000000000cc00000000004422202006d6d55050d55d0506dd11d00222224000006040000067d0
60600600606060600060600600606006060000000000000000000000000ccccc0000000004440400d6d6d555d024920d06d6d1d0022822400006004000067d00
0700007077770000777707777700007000070088800777022022022200cc00ccc00000000a9909006766dddd00d55d000d1dd1d002288240006005000f67d000
007007000077700777007777777707000000788888777772200020202cc0000cc0000000044440400006d0000056d5000d1111d0028e824006005000009d0000
0070070000077777700070000000770000007888887777700000000000cc00cc0000000002444404d000000d00d55d0000dddd00028e82404444000002090000
00777700000770077000700000007770000778888877777000000000000cccc00000000000222202500000050000000000000000022222002000000090000000
007777000000000000007777777707777777708880077700000000000000cc000000000000000000000000000766dd60000000880000007c0020010000666660
077777700000000000000777770000777777000000000000000000000022300000000000000000006770066d06cc11d0000008880000070c0e2221d0067777d0
77777777000000000000000000000007007000330000033002003300200033000000000000000000166d5dd006c6d1d066008e800000700c02eeed100cccccd0
7000000007777777700000007000000007000033002003302000330200003300000330000003300010d6d50007c6d1606008e800000700c6022002100c7c7cd0
77000000770777770000000077000000770003330200333300333330000333000033300000033000606d5d0d0d1dd1d0068e800000700d20022002100cc7ccd0
77700007770077700000000077700007770003333000333000033300000333000033332200333000d0d6d5050d1111d0006800000700d200022002100c7c7cd0
77707707770000000000000077770077770004440000444300044400000444300044400000333000000d50000061160002050500700c2000022002100cccccd0
7770000777000700000000000777777770000303000030000000030000030000034030000044430000000000000dd00050005500ccc60000220000210ccccc00
77000000770007000000000700000000007000000000000000660000000000000090000000000000000000000000000000000000000000000000000000999990
70000000070000000000007000000000000700000030603060330030000000900050000000000000000000000000000000000000000000000000000009ffff20
00000000000077700777700000000000000007777333633363300333660030503050000000000000000000000000000000000000000000000000000004444420
00000000000777770077770000000000000077770040004000400040000444544450000000000000000000000000000000000000000000000000000004444420
00000000007777777007770000000000000077700303003003030303000424542450000000000000000000000000000000000000000000000000000004444420
00000000000000000000770000000000000077000000000000000000000424542400000000000000000000000000000000000000000000000000000004444420
00000000000000000000070000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000004444420
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444400
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f000000000000000f000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ff00000000000000ff00000000000000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000600b000000000000600b000000000000600b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066600000000000006660000000000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000606066000000000060606600000000006060660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00406066600000000040606660000000004060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040006000000000004000600000000000400060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d040606000000000d040606000000000d040606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000060600000000d000060600000000d0000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000006060000000d000006000000000d00000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7777777770007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d777770000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d777000f0000000770000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d7400ff000000007700000000000ff00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004000660000000077000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040600660000000007000000000006600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000060600000000007000000000006006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006660000000007000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000000007000000000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006660000000070000000406066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600000000070000000040006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006060000000700000000d04060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000006000600007700000000d000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000060006077000000000d0000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000007070777077707770707007707070077000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000007070d7d07d70d7d070707d7070707dd000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000007070070077d00700707070707070777000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000777007007d700700707070707070dd7000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000d7d0777070700700d77077d0d77077d000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000d00ddd0d0d00d000dd0dd000dd0dd0000000000000000000
11111111111111110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111115501100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01101111111111115500001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01001110111111115515500100000000000000000000000000000000000000000000000000000007070777077000700707077700770707077707770000000000
000000001111111155155001000000000000000000000000000000000000000000000000000000070707d707d707d707070d7d07dd070707dd07d70000000000
110110111111111155155151000000000000000000000000000000000000000000000000000000070707770707070707070070077707770770077d0000000000
100100111111111111111111000000000000000000000000000000000000000000000000000000077707d70707077d070700700dd707d707d007d70000000000
1111111111111111000000000000000000000000000000000000000000000000000000000000000d7d070707070d770d770777077d0707077707070000000000
11111111111111110050050000000000000000000000000000000000000000000000000000000000d00d0d0d0d00dd00dd0ddd0dd00d0d0ddd0d0d0000000000
11011111111111110055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10110101111111110050050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101001111111110155551000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010111111111050050100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100010111111110111111000000000000000000000000000000000000000000000000000000000000000000000000288888882888802888828888088888000
01000100111111110000000000000000000000000000000000000000000000000000000000000000000000000000000028822280288200288202882028220000
00000d0000000d000000000000000000000000000000000000000000000000000000000000000000000000000005000008800020028000082000882028800000
00d00d0000d00d000000000000000000000000000000000000000000000000000000000000000000000000050050000008800000008800880000880008800000
00d0d11000d0d1100000000000000000000000000000000000000000000000000000000000000000000000505050000008888200008808820000880008800000
0ddd01100ddd01100000000000000000000000000000000000000000000000000000000000000000000000505055000008828000002888200000880008800000
0dd101100dd101100000000000000000000000000000000000000000000000000000000000000000000000050050000008802000000888200000880008800000
ddd11011ddd110110000000000000000000000000000000000000000000000000000000000000000000000000050000008800080000282000000880028800008
dd111011dd1110110000000000000000000000000000000000000000000000000000000000000000000000000500000288888880000080000228888288888882
00100100001001000000000000000000000000000000000000000000000000000000000000000000000000000000000022222220000020000022222022222220
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
eee0e0e0ee00eee0eee0eee0eee00000eee0eee0eee00ee0eee00000e000eee0ee00eee00000ee00eee0e0e0eee00000eee0eee0eee00000eee0000000000000
e0e0e0e0e0e00e000e00eee0e0000000e000e0e0e0e0e0e0e0e00000e0000e00e0e0e00000000e0000e0e0e0e00000000e00e0e0e0e00000e0e0000000000000
ee00e0e0e0e00e000e00e0e0ee000000ee00ee00ee00e0e0ee000000e0000e00e0e0ee0000000e000ee0eee0eee000000e00eee0ee000000e0e0000000000000
e0e0e0e0e0e00e000e00e0e0e0000000e000e0e0e0e0e0e0e0e00000e0000e00e0e0e00000000e0000e000e000e000000e00e0e0e0e00000e0e0000000000000
e0e00ee0e0e00e00eee0e0e0eee00000eee0e0e0e0e0ee00e0e00000eee0eee0e0e0eee00000eee0eee000e0eee000000e00e0e0eee00000eee0000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000077077707770777077707770000077007070770007707770077077007770707077707770777007707700770077707070777077707070
00000000000000000000700070707070070007007000777070707070707070007000707070700700707070007770700070007000707070007070070007007070
00000000000000000000777077707700070007007700000070707070707070007700707070700700777077007070770077707000707077000700070007007770
00000000000000000000007070007070070007007000777070707070707070707000707070700700707070007070700000707000707070007070070007007070
00000000000000000000770070007070777007007770000077700770707077707770770070700700707077707070777077007700707077707070070007007070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707770777007700000077077707770770000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007770700000700000700070707070070007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77007070770000700000777077707700070077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007070700000700000007070007070070007007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707070777007700700770070007070777000007770700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660666066606660666066600000666006600000666066006600666060600000666066606660600066000000060066600600000006006660000066006660
60600600060060006660606006000000060060600000060060606060600060600000600006006000600060600000600000606000000060006060000060600600
66600600060066006060666006000000060060600000060060606060660006000000660006006600600060600000000006600000000060006660000060600600
60600600060060006060600006000000060060600000060060606060600060600000600006006000600060600000000000000000000060006060000060600600
60600600060066606060600006000000060066000000666060606660666060600000600066606660666066600000000006000000000006006060000060606660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000606066606000606066600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000606060606000606060000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000606066606000606066000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000666060606000606060000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000060060606660066066600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0dd000000ddd0ddd0ddd0ddd0dd00ddd0ddd00000d000ddd0dd00ddd00000dd00ddd0d0d0ddd000000d00ddd0ddd0ddd00000ddd00d000000000000000000
0d00d0d00000ddd0d0d0d0d00d00d0d00d000d000000d0000d00d0d0d00000000d0000d0d0d0d0000000d0000d00d0d0d0d00000d0d000d00000000000000000
0d00d0d00000d0d0ddd0ddd00d00d0d00d000d000000d0000d00d0d0dd0000000d000dd0ddd0ddd00000d0000d00ddd0dd000000d0d000d00000000000000000
0d00d0d00000d0d0d0d0d0000d00d0d00d000d000000d0000d00d0d0d00000000d0000d000d000d00000d0000d00d0d0d0d00000d0d000d00000000000000000
ddd0d0d00000d0d0d0d0d000ddd0d0d0ddd00d000000ddd0ddd0d0d0ddd00000ddd0ddd000d0ddd000000d000d00d0d0ddd00000ddd00d000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0dd000000dd00ddd0d0d0ddd0ddd0d0000dd00dd0ddd00000d000ddd0dd00ddd00000dd00dd00ddd0ddd000000d00ddd0ddd0ddd00000ddd00d0000000000
0d00d0d00000d0d0d000d0d00d00d000d000d0d0d0d0d0d00000d0000d00d0d0d00000000d000d0000d000d00000d0000d00d0d0d0d00000d0d000d000000000
0d00d0d00000d0d0dd000d000d00dd00d000d0d0d0d0dd000000d0000d00d0d0dd0000000d000d0000d000d00000d0000d00ddd0dd000000d0d000d000000000
0d00d0d00000d0d0d000d0d00d00d000d000d0d0d0d0d0d00000d0000d00d0d0d00000000d000d0000d000d00000d0000d00d0d0d0d00000d0d000d000000000
ddd0d0d00000d0d0ddd0d0d00d00d000ddd0dd00dd00d0d00000ddd0ddd0d0d0ddd00000ddd0ddd000d000d000000d000d00d0d0ddd00000ddd00d0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0dd000000ddd0dd00ddd0ddd0ddd00000d000ddd0dd00ddd00000dd00ddd0d0d0ddd000000d00ddd0ddd0ddd00000ddd00d00000000000000000000000000
0d00d0d00000d000d0d00d00d000d0d00000d0000d00d0d0d00000000d0000d0d0d0d0d00000d0000d00d0d0d0d00000d0d000d0000000000000000000000000
0d00d0d00000dd00d0d00d00dd00dd000000d0000d00d0d0dd0000000d000dd0ddd0ddd00000d0000d00ddd0dd000000d0d000d0000000000000000000000000
0d00d0d00000d000d0d00d00d000d0d00000d0000d00d0d0d00000000d0000d000d000d00000d0000d00d0d0d0d00000d0d000d0000000000000000000000000
ddd0d0d00000ddd0d0d00d00ddd0d0d00000ddd0ddd0d0d0ddd00000ddd0ddd000d000d000000d000d00d0d0ddd00000ddd00d00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0dd0000000000d0d0ddd0dd00ddd0ddd0ddd0d000ddd00000d000ddd0dd00ddd00000dd00ddd0ddd0ddd000000d00ddd0ddd0ddd00000ddd00d0000000000
0d00d0d000000000d0d0d0d0d0d0d0d00d00d000d000d0d00000d0000d00d0d0d00000000d0000d0d0d0d0d00000d0000d00d0d0d0d00000d0d000d000000000
0d00d0d000000000d0d0ddd0d0d0ddd00d00dd00ddd0d0d00000d0000d00d0d0dd0000000d0000d0d0d0ddd00000d0000d00ddd0dd000000d0d000d000000000
0d00d0d000000000d0d0d000d0d0d0d00d00d000d0d0d0d00000d0000d00d0d0d00000000d0000d0d0d0d0d00000d0000d00d0d0d0d00000d0d000d000000000
ddd0d0d00000ddd00dd0d000ddd0d0d00d00ddd0ddd0ddd00000ddd0ddd0d0d0ddd00000ddd000d0ddd0ddd000000d000d00d0d0ddd00000ddd00d0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0ddd00000d000ddd0dd00ddd00000ddd000000d00ddd0ddd0ddd00000ddd00d00000000000000000000000000000000000000000000000000000000000000
d0d00d000000d0000d00d0d0d0000000d0d00000d0000d00d0d0d0d00000d0d000d0000000000000000000000000000000000000000000000000000000000000
ddd00d000000d0000d00d0d0dd000000d0d00000d0000d00ddd0dd000000d0d000d0000000000000000000000000000000000000000000000000000000000000
d0d00d000000d0000d00d0d0d0000000d0d00000d0000d00d0d0d0d00000d0d000d0000000000000000000000000000000000000000000000000000000000000
d0d00d000000ddd0ddd0d0d0ddd00000ddd000000d000d00d0d0ddd00000ddd00d00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000077707770777007707770707077707000777077007700777077700000777007700000000000000000000011111111
07000000700070707070707070700700000070007070070070007000707007007000700070707070700070700000070070000000000000000000000011111111
00700000770007007770707077000700000077007770070070007700707007007000770070707070770077000000070077700000000000000000000011111111
07000000700070707000707070700700000070007000070070007000777007007000700070707070700070700000070000700000000000000000000011111111
70000000777070707000770070700700000077707000777007707770070077707770777070707770777070700700770077000000000000000000000011111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
66606000666066600660666000000660666066606660606066606660000066600000600066606660666060000000666066606660066066600000000000000000
60606000600060606000600000006000606060600600606060606000000060600000600060606060600060000000600006006060600006000000000000000000
66606000660066606660660000006000666066600600606066006600000066600000600066606600660060000000660006006600666006000000000000000000
60006000600060600060600000006000606060000600606060606000000060600000600060606060600060000000600006006060006006000000000000000000
60006660666060606600666000000660606060000600066060606660000060600000666060606660666066600000600066606060660006000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000077707770777007707770707077707000777077007700777077700000707077707770700000000000000011111111
07000000700070707070707070700700000070007070070070007000707007007000700070707070700070700000707007007770700000000000000011111111
00700000770007007770707077000700000077007770070070007700707007007000770070707070770077000000777007007070700000000000000011111111
07000000700070707000707070700700000070007000070070007000777007007000700070707070700070700000707007007070700000000000000011111111
70000000777070707000770070700700000077707000777007707770070077707770777070707770777070700700707007007070777000000000000011111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
66606000666066600660666000000660666066606660606066606660000066600000600066606660666060000000666066606660066066600000000000000000
60606000600060606000600000006000606060600600606060606000000060600000600060606060600060000000600006006060600006000000000000000000
66606000660066606660660000006000666066600600606066006600000066600000600066606600660060000000660006006600666006000000000000000000
60006000600060600060600000006000606060000600606060606000000060600000600060606060600060000000600006006060006006000000000000000000
60006660666060606600666000000660606060000600066060606660000060600000666060606660666066600000600066606060660006000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000888800001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
07000000888800001111111100000000110110111101101111011011110110111101101100000000110110111101101100000000000000000000000011111111
00700000888800001111111100000000100100111001001110010011100100111001001100000000100100111001001100000000000000000000000011111111
07000000888800001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
70000000888800001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
00000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000005400000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000002254440000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000054444000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000504004000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000005005000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111
11111111000000001111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000001111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000110111101101111011011110110111111111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000100111001001110010011100100111011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000001101101111011011110110111101101111111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000001001001110010011100100111001001111111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111000000000000000000000000000000000000000011111111111111111111111111111111111111110000000000000000000000000000000011111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
010800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001361513625136151361500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0116000021040210451f0401f0451d0401d0451c0401c0451a0401a0421a0421a0451800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400002115300100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000
010a00003261432613000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700003133300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000914102121001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010200000e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002602100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
014000000063400600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00001a7321a7301a7201a725000000000000000007001c7321c7321c7201c7201c72500000000000000019740197401973219732197321973219732197201972500700000000000000000000000000000000
010800001a85000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000025040250502604026050280402805029040290502b0502b0402d0402d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001d1322113024130291302d130001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000
000300000a5500c5500c5500f55013550185501b5501d5501f550225502455029550295503055020500265002a500345003d50000500005000050000500005000050000500005000050000500005000050000500
012c00001a7301a7321a7351c91000000007001d7351a7301c7321c7321c73500700157321573505910000001a7301a7321a7350000000000007001d7321a7301c7321c735000001d73015732157350000013735
012c000013730137351800015734167311673518734187351a7341a7321a735000000d91200000000000000013730137351800015734167311673518734187351a7341a7351c7341c73019732197321973500000
012c00000e734021350e734021350e734021350e7340213509734091350973409135097340913509734011350e734021350e734021350e734021350e734021350973409135097340913509734091350973409135
012c00000773407135077340713507734071350773407135027340213502734021350273402135027340513507734071350773407135077340713507734071350e734021350e7340213509734091350973401135
01e300080e77515775147750c7751077517775167750f775007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b6202a6202962033620286202762031620256202463022630226301f6301b630196401464012640106400a6400563003630016300063000620006200062000620006300163002630036300463005620
000200002f62027620236202c6201a62021620146301c6300d6300b6300a6301c63009630006401a6401a640006401a64000630006301d6200165001650016500065000600006000060000600006000060000600
010e00001361500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010900000473404730047300473104741047430373403730037300373103741037430273402730027300273102741027330173401731017410174101741017410175101751017510176300000000000000000000
01090000137341373013730137311374113743127341273012730127311274112743117341173011730117311174111733107341073110731107311074110741107511075110751107630c000000000000000000
0115000002740057350274009735027400c73502740057350274005735027300773502740097350273005735097400c7350974010735097400c7350973004745097300c735097401073509740137300974515745
011500000e742117350e740157350e740187350e740117350e742117350e730137350e740157350e730117351574018735157401c735157401873515730107451573018735157421c735157401f7351574521744
0115000001750047450175008745017500d74501750047450175004745017500874501750097450175004745087500d7450875010745087500d74508755047500875519730145350d53510545147301073503745
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001d7321d73500145001421d7341d73500142000001c7321c73500145001421c7341c73500142000001b7341b7350014500142247342473500142000002373223735001450014222734227350014500142
011800201a7321a73502145021421d7341d73502142000001a7321a7350214502142217342173502142000001a7321a7350214502142247342473502142000002273422735021450214218734187350214502142
011800001a7321a73502145021421d7341d7350214200000217322173502145021422273422735021420000023734237350214502142247342473502142000002573425735021450214226734267350214502142
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600002671226715217140070021710217151a7101a7151f7141f7151e710007001c7101c7151a714007002571025715217120070021710217151f7101f7151f7121f715217140070021714217151e71100700
011600001f7101f7151f7101f7151f7121f7151f7141f7151f7101f7152171121715227102271521714217152171521712217142171521710217151f7121f7151f7141f7151d7101d7151d7121d7151d71018711
011600001f7101f7151f7101f7151f7121f7151f7141f7151f7101f71521712217152271022715217142171521715217122171421715217102171521712217152571425715257102571525712257152071119711
__music__
00 114b4344
01 16184344
02 17194344
00 114b4344
01 2d424344
00 2e424344
02 2c424344
00 23244344
01 25264344
00 25264344
02 27674344
03 1a6e4344
00 706e4344
00 706e4344
00 706e4344
00 706e4344
00 706e4344
00 706e4344
00 6f6c4344
00 706e4344
00 13424344
01 314b4344
00 314b4344
00 324e4344
02 33504344

