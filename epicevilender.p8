pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- virtuous vanquisher of evil 1.0
-- by ironchest games

cartdata('ironchestgames_vvoe_v1_dev5')

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function has(_t,_v)
 for k,v in pairs(_t) do
  if v == _v then
   return k
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
function pfn(s) -- parseflat num
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

function saveitem(_slot,_class,_prefix,_suffix)
 dset(_slot,_class+shl(_prefix,4)+shl(_suffix,8))
end

if dget(1) == 0 then
 saveitem(1,8,1,0)
end

function loaditem(_i)
 local dat=dget(_i)
 local _class=band(dat,0b1111)
 if _class == 0 then
  return
 end
 return createitem(
   _class,
   band(dat,0b11110000)/16,
   band(dat,0b111100000000)/256)
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
 hw=4,
 hh=4,
}
function isinsidewall(aabb)
 local x1,y1,x2,y2=
   aabb.x-aabb.hw,
   aabb.y-aabb.hh,
   aabb.x+aabb.hw,
   aabb.y+aabb.hh

 for point in all{
    {x1,y1},
    {x2,y1},
    {x2,y2},
    {x1,y2},
   } do
  local mapx,mapy=flr(point[1]/8),flr(point[2]/8)
  wallaabb.x,wallaabb.y=
    mapx*8+wallaabb.hw,
    mapy*8+wallaabb.hh

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
 return n == 0 and 0 or sgn(n)
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

function aframes(_fs)
 local t={}
 local j=1
 for i=0,1,0.125 do
  t[i]=pfn(_fs[j])
  j+=1
 end
 return t
end

meleevfxframes=aframes{
 '0,20,4,7,-1,-5,', -- right
 '8,20,6,4,-3,-2,', -- right/up
 '20,20,9,3,-3,-1,', -- up
 '14,20,6,4,-2,-2,', -- up/left
 '4,20,4,7,-2,-5,', -- left
 '29,20,4,7,-3,-6,', -- left/down
 '20,23,9,3,-4,-2,', -- down
 '33,20,4,7,0,-6,', -- down/right
 '0,20,4,7,-1,-5,', -- right (wrapped)
}

bowvfxframes=aframes{
 '0,27,6,7,-3,-5,', -- right
 '17,32,7,7,-4,-3,', -- right/up
 '10,31,7,6,-3,-3,', -- up
 '34,32,7,7,-3,-3,', -- up/left
 '4,27,6,7, -2,-5,', -- left
 '22,27,7,7,-2,-5,', -- left/down
 '10,27,7,6,-3,-4,', -- down
 '29,27,7,7,-4,-4,', -- down/right
 '0,27,6,7,-3,-5,', -- right (wrapped)
}

arrowframes=aframes{
 '50,20,2,1,-1,-0.5,', -- right
 '52,20,2,2,-1,-1,', -- right/up
 '54,20,1,2,-0.5,-1,', -- up
 '55,20,2,2,-1,-1,', -- up/left
 '50,20,2,1,-1,-0.5,', -- left
 '52,20,2,2,-1,-1,', -- left/down
 '54,20,1,2,-0.5,-1,', -- down
 '55,20,2,2,-1,-1,', -- down/right
 '50,20,2,1,-1,-0.5,', -- right (wrapped)
}

function getvfxframei(a)
 return min(flr((a+0.0625)*8)/8,1)
end

-- todo: this is only convenience dev function
function actorfactory(_a)
 _a.state,
 _a.state_c,
 _a.curframe,
 _a.dx,
 _a.dy,
 _a.runspd,
 _a.dmgfx_c,
 _a.comfydist,
 _a.toocloseto
   =
   'idling',
   0,
   1,
   0,
   0,
   _a.spd,
   0,
   _a.comfydist or 1,
   {}

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
 f[5],
 f[6],
 f.c,
 f.col
   =
   _a.x+cos(_a.a)*4+f[5],
   _a.y+sin(_a.a)*4+f[6],
   10,
   7

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
 return actorfactory{
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
  idling={pfn'41,32,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   pfn'41,32,4,5,-2,-3,',
   pfn'45,32,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   pfn'49,32,4,5,-2,-3,',
   pfn'52,32,6,5,-3,-3,',
  },
  recovering={pfn'41,32,4,5,-2,-3,'},
 }
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
   pfn'8,14,',
   pfn'14,8,'),
  pfn'59,32,4,6,-2,-3,'

 return actorfactory{
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
   pfn'63,32,4,6,-2,-3,',
   idleframe,
  },
  recovering={idleframe},
  onpreprfm=boltskill.startpemitter,
 }
end

function newgianttroll(x,y)
 boss=actorfactory{
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
  idling={pfn'36,25,7,7,-4,-4,'},
  moving={
   animspd=0.18,
   pfn'43,25,7,7,-4,-4,',
   pfn'50,25,7,7,-4,-4,'
  },
  attacking={
   animspd=0,
   pfn'57,25,7,7,-4,-4,',
   pfn'64,25,8,7,-4,-4,',
  },
  recovering={pfn'72,25,7,7,-4,-4,'},
 }
 return boss
end

function newmeleeskele(x,y)
 return actorfactory{
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
  idling={pfn'0,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   pfn'0,15,4,5,-2,-3,',
   pfn'4,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   pfn'8,15,4,5,-2,-3,',
   pfn'11,15,6,5,-3,-3,',
  },
  recovering={pfn'0,15,4,5,-2,-3,'},
 }
end

function newbatenemy(x,y)
 return actorfactory{
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
  idling={pfn'36,15,3,3,-1.5,-1.5,'},
  moving={
   animspd=0.21,
   pfn'36,15,3,3,-1.5,-1.5,',
   pfn'39,15,3,3,-1.5,-1.5,'
  },
  attacking={
   animspd=0.32,
   pfn'36,15,3,3,-1.5,-1.5,',
   pfn'39,15,3,3,-1.5,-1.5,'
  },
  recovering={pfn'36,15,3,3,-1.5,-1.5,'},
 }
end

function newbowskele(x,y)
 return actorfactory{
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
  idling={pfn'18,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   pfn'18,15,4,5,-2,-3,',
   pfn'22,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   pfn'26,15,4,5,-2,-3,',
   pfn'31,15,4,5,-2,-3,'
  },
  recovering={pfn'18,15,4,5,-2,-3,'},
 }
end

function newskeleking(x,y)

 function setupmelee(_a)
  _a.nolos=nil
  _a.att_range=7
  _a.att_preprfm=30
  _a.att_postprfm=60
  _a.attacking={
   animspd=0,
   pfn'0,40,15,18,-7,-13,',
   pfn'0,58,20,18,-10,-13,',
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
   pfn'24,58,15,18,-7,-13,',
   pfn'24,58,15,18,-7,-13,',
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
   prate=pfn'1,2,',
   plife=pfn'10,15,',
   poffsets=pfn'-2,0.5,1,0.5,',
   dx=pfn'0,0,',
   dy=pfn'-0.3,0,',
   pcolors=pfn'11,3,1,',
  })

  sfx(9)
 end

 function performmagic(_a)
  local _e=newmeleeskele(_a.att_x,_a.att_y)

  -- summoning sickness
  _e.state,
  _e.laststate,
  _e.state_c
    =
    'recovering',
    'recovering',
    50

  add(actors,_e)
 end

 boss=actorfactory{
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
  idling={pfn'0,40,15,18,-7,-13,'},
  moving={
   animspd=0.24,
   pfn'16,40,15,18,-7,-13,',
   pfn'32,40,15,18,-7,-13,'
  },
  recovering={pfn'0,40,15,18,-7,-13,'},
  onroam=setupmagic,
 }

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
   prate=pfn'2,4,',
   plife=pfn'15,25,',
   poffsets=pfn'-2,0.5,2,0.5,',
   dx=pfn'0,0,',
   dy=pfn'-0.3,0,',
   pcolors=pfn'8,14,',
  })
 end

 _a.effect.c-=1

 if _a.effect.c <= 0 then
  _a.effect.c=12

  _a.a=rnd()
 end

 _a.dx,_a.dy=
   cos(_a.a)*_a.spd,
   sin(_a.a)*_a.spd

end

function freezeeffect(_a)
 add(vfxs,{
  {
   57,18,8,7,
   _a.x-4,_a.y-3.5,
   c=2,
  },
 })

 _a.dx,_a.dy=0,0
end

-- skills -- todo: maybe remove this?
function skillfactory(sprite,desc,onhit,immune)
 return {
  sprite=sprite,
  desc=desc,
  onhit=onhit,
  immune=immune,
 }
end

function swordattackskillfactory(
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

function bowattackskillfactory(
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

function boltskillfactory(
  dmg,
  preprfm,
  postprfm,
  recovertime,
  tar_c,
  typ,
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
    prate=pfn'2,4,',
    plife=pfn'15,25,',
    poffsets=pfn'-2,0.5,2,0.5,',
    dx=pfn'0,0,',
    dy=pfn'-0.3,0,',
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
    typ=typ,
    recovertime=recovertime,
    tar_c=tar_c,
    frames={
     curframe=1,
     pfn'47,20,3,3, -0.5,-0.5,',
    },
    col=attackcol,
   }

   add(attacks,attack)

   add(pemitters,{
    follow=attack,
    life=1000,
    prate=pfn'0,1,',
    plife=pfn'3,5,',
    poffsets=pfn'-1,-1,1,1,',
    dx=pfn'0,0,',
    dy=pfn'0,0,',
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
slots={
 'weapon',
 'offhand',
 'armor',
 'boots',
 'helmet',
 'book',
 'amulet',
}

function createitem(_itemclass,_prefix,_suffix)
 local itemclass=itemclasses[_itemclass]
 local itemname,
   armor,
   spdfactor,
   sprite,
   prefixt,
   col,
   col2
   =
   itemclass.name,
   0,
   0,
   itemclass.sprite,
   itemclass.prefix or prefix,
   itemclass.col,
   itemclass.col2

 if _suffix != 0 then
  _suffix=suffix[_suffix]
  itemname=itemname.._suffix.name
  armor+=(_suffix.armor or 0)
  spdfactor+=(_suffix.spdfactor or 0)
  sprite=_suffix[itemclass.slot..'_spr']
  col=_suffix.col
  col2=_suffix.col2
 else
  _suffix=nil
 end

 if _prefix != 0 then
  _prefix=prefixt[_prefix]
  itemname=_prefix.name..itemname
  armor+=(_prefix.armor or 0)
  spdfactor+=(_prefix.spdfactor or 0)
  sprite=_prefix[itemclass.slot..'_spr']
  col=_prefix.col
  col2=_prefix.col2
 else
  _prefix=nil
 end

 if _prefix == nil and _suffix == nil then
  itemname='useless '..itemname
 end

 return {
  class=_itemclass,
  slot=itemclass.slot,
  name=itemname,
  sprite=sprite or itemclass.sprite,
  col=col or itemclass.col,
  col2=col2 or itemclass.col2,
  prefix=_prefix,
  suffix=_suffix,
  armor=armor,
  spdfactor=spdfactor,
  iscloak=itemclass.iscloak,
  twohand=itemclass.twohand,
  curframe=1,
  idling=itemclass.idling,
  moving=itemclass.moving,
  attacking=itemclass.attacking,
  recovering=itemclass.recovering,
 }
end

swordprefix={
 {
  name='',
  skill=swordattackskillfactory(1,15,28,1000,7),
 },
 {
  name='ice ',
  col=12,
  skill=swordattackskillfactory(1,15,28,1000,7,'ice',150),
 },
 {
  name='flaming ',
  col=8,
  skill=swordattackskillfactory(1,15,28,1000,14,'fire',60),
 },
 {
  name='heavy ',
  col=13,
  skill=swordattackskillfactory(1,15,28,1000,7,'knockback'),
 },
}

bowprefix={
 {
  name='',
  col=4,
  skill=bowattackskillfactory(1,26,6,1,7,2),
  twohand=true,
 },
 {
  name='ice ',
  col=12,
  skill=bowattackskillfactory(1,26,6,1,7,12,'ice',150),
  twohand=true,
 },
}

prefix={
 {
  name='knight\'s ',
  armor=1,
 },
 {
  name='feathered ',
  spdfactor=0.1,
 },
 {
  name='dragonscale ',
  skill=skillfactory(7,'passive, cannot be burned',nil,'fire'),
 },
}

suffix={
 {
  name=' of resurrect',
  amulet_spr=6,
  skill=skillfactory(5,'passive, resurrect once',function (_a)
   if _a.hp <= 0 then
    _a.hp,_a.removeme=3,nil
    for k,v in pairs(slots) do
     local _item=_a.items[v]
     if _item and
        _item.suffix and
        _item.suffix.skill == suffix[1].skill then
      _a.items[v]=nil
      saveitem(k,0,0,0)
      del(_a.passiveskills,suffix[1].skill)
      break
     end
    end
    sfx(21)
   end
  end),
 },
 {
  name=' of haste',
  spdfactor=0.1,
 },
 {
  name=' of phasing',
  skill=skillfactory(27,'passive, phase away on hit',phasing),
 },
 {
  name=' of firebolt',
  book_spr=45,
  skill=boltskillfactory(
    1,
    50,
    0,
    120,
    1,
    'fire',
    14,
    pfn'8,14,',
    pfn'14,8,',
    29,
    'firebolt'),
 },
 {
  name=' of icebolt',
  book_spr=63,
  skill=boltskillfactory(
    0,
    40,
    0,
    150,
    1,
    'ice',
    7,
    pfn'12,12,',
    pfn'12,13,',
    28,
    'icebolt')
 },
}

cloakidling,
shieldidling,
swordidling,
bowidling
  =
  {pfn'0,6,3,4,-1,-2,'},
  {pfn'35,9,5,5,-2,-3,'},
  {pfn'9,9,5,5,-2,-3,'},
  {pfn'25,9,5,5,-2,-3,'}


itemclasses={
 { -- 1
  slot='boots',
  name='boots',
  sprite=41,
  col=4,
 },
 { -- 2
  slot='helmet',
  name='helmet',
  sprite=42,
  col=13,
 },
 { -- 3
  slot='amulet',
  name='amulet',
  sprite=25,
 },
 { -- 4 platemail
  slot='armor',
  name='platemail',
  sprite=58,
  col=6,
 },
 { -- 5 cloak
  slot='armor',
  name='cloak',
  iscloak=true,
  sprite=26,
  col=2,
  col2=1,
  idling=cloakidling,
  moving=cloakidling,
  attacking=cloakidling,
  recovering=cloakidling,
 },
 { -- 6 shield
  slot='offhand',
  name='shield',
  sprite=44,
  col=13,
  idling=shieldidling,
  moving=shieldidling,
  attacking=shieldidling,
  recovering=shieldidling,
 },
 { -- 7
  slot='book',
  name='book',
  sprite=79,
 },
 { -- 8 sword
  slot='weapon',
  name='sword',
  sprite=47,
  col=6,
  prefix=swordprefix,
  idling=swordidling,
  moving=swordidling,
  attacking={
   pfn'14,9,5,5,-2,-3,',
   pfn'18,9,7,5,-3,-3,'
  },
  recovering=swordidling,
 },
 { -- 9 bow
  slot='weapon',
  name='bow',
  twohand=true,
  sprite=46,
  col=4,
  prefix=bowprefix,
  idling=bowidling,
  moving=bowidling,
  attacking={
   pfn'30,9,5,5,-2,-3,',
   pfn'25,9,1,1,-2,-3,',
  },
  recovering=bowidling,
 }
}

themes={
 { -- forest
  newmeleetroll,
  newmeleetroll,
  newtrollcaster,
  newgianttroll,
 },
 { -- cave
  newbatenemy,
  newmeleeskele,
  newbowskele,
  newskeleking,
 },
 { --  catacombs
  newbatenemy,
  newmeleeskele,
  newbowskele,
  newskeleking,
 },
}

-- init avatar

idleframe=pfn'0,10,3,4,-1,-2,'

avatar=actorfactory{
 x=64,y=56,
 hw=1.5,hh=2,
 a=0,
 spdfactor=1,
 spd=0.5,
 hp=3,
 startarmor=0,
 armor=0,
 items={},
 inventory={},
 passiveskills={},
 idling={idleframe},
 moving={idleframe,pfn'3,10,3,4,-1,-2,'},
 attacking={animspd=0,pfn'6,10,3,4,-1,-2,',idleframe},
 recovering={idleframe},
}

for k,v in pairs(slots) do
 avatar.items[v]=loaditem(k)
end

function dungeoninit()
 _update60,_draw=
   dungeonupdate,
   dungeondraw

 avatar.removeme,
 avatar.hp,
 avatar.x,
 avatar.y
   =nil,3,64,56

 dungeonlvl,
 theme,
 nexttheme
   =1,1,1

 for _t in all(themes) do
  _t.lvl_c=4+flr(rnd()*1)
 end

 mapinit()
end

function nextfloor()
 theme=nexttheme
 dungeonlvl+=1
 mapinit()
end

tick,
kills,
curenemyi
  =0,0,1

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
 local enemytypes=pfn'5,6,7,'
 local enemies={}
 local angles=pfn'-0.25,0.25,'
 themes[theme].lvl_c-=1

 while step_c > 0 do
  local nextx,nexty=curx+cos(a),cury+sin(a)

  if flr(rnd(3)) == 0 or
     nextx <= 0 or nextx > 14 or
     nexty <= 0 or nexty > 14 then
   a+=angles[flr(rnd(#angles)+1)]
  elseif step_c != 0 and step_c % (steps / enemy_c) == 0 then
   add(enemies,{
    x=curx,
    y=cury,
    typ=enemytypes[flr(rnd(#enemytypes)+1)],
   })
  else
   curx,cury=nextx,nexty
   basemap[cury][curx]=0
  end
  step_c-=1
 end

 for _e in all(enemies) do
  basemap[_e.y][_e.x]=_e.typ
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
  while curx > 0 and curx < 15 and
        cury > 0 and cury < 15 do
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
   1,0,nil,nil,{},{},{},{},{},{}

 for _y=-1,16 do
  walls[_y]={}
  for _x=-1,16 do
   local _col,ax,ay=basemap[_y][_x],_x*8+4,_y*8+4

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
      themes[theme][_col-4](ax,ay))
    _col=0
   end

   -- create door
   if _col == 2 then

    door={
     x=ax,
     y=ay,
     hw=4,
     hh=4,
     text='\x8e go deeper',
     enter=function()
      if btnp(4) then
       nextfloor()
      end
     end,
    }

    if nexttheme > #themes then
     door.text,door.sprite,door.enter=
      '\x8e go home',248,function()
       if btnp(4) then
        splash()
       end
      end
    else
     door.sprite=178+nexttheme*16
    end

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
 music(theme*10,0,0b0011)
 if boss then
  music(1)
 end

end

function dungeonupdate()
 tick+=1
 if tick < 120 then
  curinteractable=nil
  return
 end

 if avatar.hp <= 0 then
  if tick-deathts > 150 and btnp(4) then
   avatar.inventory,kills,theme,door={},0,nil,nil
   equipinit()
  end
  return
 end

 local angle=btnmasktoa[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
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
 local skillbuttondown=nil
 if btn(4) then
  skillbuttondown=1
 elseif btn(5) then
  skillbuttondown=2
 end

 if skillbuttondown and
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

   -- reset enemy vars
   actor.tarx,actor.tary,actor.ismovingoutofcollision=nil,nil,nil

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
  actor.dx,actor.dy=
    actor.dx*(actor.spd*spdfactor),
    actor.dy*(actor.spd*spdfactor)
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
     if attack.typ and
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
     if kills % 5 == 0 or _a == boss then
      add(interactables,{
       x=_a.x,y=_a.y,
       hw=4,hh=4,
       sprite=22,
       text='\x8e loot',
       enter=function(i)
        if btnp(4) and not i.isopen then
         if #avatar.inventory >= 10 then
          i.text='inventory full, \x8e try again'
          sfx(7)
         else
          i.isopen,i.text,i.sprite=
            true,'[empty]',23

          local _itemclassn=flr(rnd(#itemclasses))+1
          local itemclass=itemclasses[_itemclassn]
          local _prefix=itemclass.prefix or prefix
          local _prefixn,_suffixn=
            flr(rnd(#_prefix+1)),
            flr(rnd(#suffix+1))

          if _itemclassn == 7 then
           _prefixn=0
          end

          item=createitem(_itemclassn,_prefixn,_suffixn)

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

    elseif attack.typ == 'ice' then
     _a.effect={func=freezeeffect}
     _a.dmgfx_col=12
    end

    sfx(hitsfx)

    -- start dmg indication
    _a.dmgfx_c=20

    -- hit flash
    local x,y=_a.x+_a.dx/2,_a.y+_a.dy/2
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
   local enemy,other=actors[i],actors[j]
   if enemy != other and
      enemy != avatar and
      other != avatar and
      enemy.isenemy and
      dist(enemy.x,enemy.y,other.x,other.y) <
        enemy.hh + other.hh then
    add(enemy.toocloseto,other)
    add(other.toocloseto,enemy)
   end
  end
 end

 -- avatar movement check against other actors
 for _a in all(actors) do
  if _a != avatar and not _a.isghost then
   local _dx,_dy=collideaabbs(
     isaabbscolliding,avatar,_a,avatar.dx,avatar.dy)

   avatar.dx,avatar.dy=_dx,_dy
  end
 end

 -- movement check against walls
 for _a in all(actors) do
  local _dx,_dy=collideaabbs(
    isinsidewall,_a,nil,_a.dx,_a.dy)

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

  if attack.x > 128 or attack.x < 0 or
     attack.y > 128 or attack.y < 0 then
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
    c=_p.plife[1]+rnd(_p.plife[2]),
    x=x,y=y,dx=dx,dy=dy,
   })

   _p.c=_p.prate[1]+rnd(_p.prate[2])
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
  if _p.removeme or _p.follow.removeme then
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
 local spr1=176+theme*16

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
   spr(_i.sprite,_i.x-_i.hw,_i.y-_i.hh)
  end
 end

 -- draw attacks
 for attack in all(attacks) do
  if attack.frames then
   local f=attack.frames[attack.frames.curframe]
   if attack.col then
    pal(2,attack.col,0)
   end
   sspr(f[1],f[2],f[3],f[4],attack.x+f[5],attack.y+f[6],f[3],f[4])
   pal(2,2,0)
  end
 end

 -- draw actors
 for _a in all(actors) do
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

  sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)

  -- draw weapon
  if _a == avatar and
     avatar.items.weapon then
   item=avatar.items.weapon
   local stateframes=item[state]
   local f=stateframes[min(
     flr(item.curframe),
     #stateframes)]
   pal(6,item.col,0)
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
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
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
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
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
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
   sspr(f[1],f[2],f[3],f[4],f[5],f[6])
   pal(7,7,0)
  end
 end

 -- draw particles
 for _p in all(pemitters) do
  for par in all(_p.particles) do
   pset(par.x,par.y,par.col)
  end
 end

 -- draw interactable text
 if curinteractable then
  print(curinteractable.text,
   mid(0,
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
   print('(you\'ve lost your inventory)',12,72,8)
   print('press \x8e to continue',26,80,8)
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
spdfactornr,
equipped,
availableskills,
equipslots=
  1,1,1,4,0,{},{},
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
end

function equipupdate()

 -- init equipped items
 avatar.startarmor,
 avatar.spdfactor,
 spdfactornr,
 equipped=0,1,0,{}
 for _,item in pairs(avatar.items) do
  add(equipped,item)
  if item.armor then
   avatar.startarmor+=item.armor
  end
  if item.spdfactor then
   avatar.spdfactor+=item.spdfactor
   spdfactornr+=-flr(-item.spdfactor*100)
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
  local _prefix,_suffix=item.prefix,item.suffix
  if _prefix and
     _prefix.skill and
     (not _prefix.skill.perform) and
     not has(avatar.passiveskills,_prefix.skill) then
   add(availableskills,_prefix.skill)
   add(avatar.passiveskills,_prefix.skill)
  end
  if _suffix == suffix[1] or
     _suffix and
     _suffix.skill and
     (not _suffix.skill.perform) and
      not has(avatar.passiveskills,_suffix.skill) then
   add(availableskills,_suffix.skill)
   add(avatar.passiveskills,_suffix.skill)
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
  if avatar.items[item.slot] == item then
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

    if avatar.items[selecteditem.slot] then
     add(avatar.inventory,avatar.items[selecteditem.slot])
    end

    avatar.items[selecteditem.slot]=selecteditem

    if selecteditem.twohand then
     add(avatar.inventory,avatar.items.offhand)
     avatar.items.offhand=nil
    end

    if selecteditem.slot == 'offhand' and
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
    local selecteditem=avatar.items[
      equipslots[equippedcur][1]]
    if selecteditem then
     avatar.items[selecteditem.slot]=nil
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
   for k,v in pairs(slots) do
    if avatar.items[v] then
     saveitem(
       k,
       avatar.items[v].class,
       has(
         itemclasses[avatar.items[v].class].prefix or
         prefix,avatar.items[v].prefix),
       has(suffix,avatar.items[v].suffix))
    else
     saveitem(k,0,0,0)
    end
   end
   
   if theme then
    _draw=dungeondraw
    _update60=dungeonupdate
   else
    dungeoninit()
   end
  end
 end

end

function equipdraw()

 cls(0)

 fillp(0b1010000110000101)
 rectfill(0,0,128,3,1)
 fillp()

 -- draw inventory section
 local offsetx,i,col=0,1,
   sectioncur == 1 and 10 or 4
 print('saddlebags',4,17-9,col)
 for item in all(avatar.inventory) do
  spr(item.sprite,6+offsetx,17)
  if sectioncur == 1 and i == inventorycur then
   rect(4+offsetx,15,15+offsetx,26,10)
   if i == sellcur then
    sspr(10,0,5,5,offsetx+4,15)
   end
   print(item.name,4,29,7)
  end
  offsetx+=12
  i+=1
 end

 -- draw equipped section
 offsetx,i,col=0,1,
   sectioncur == 2 and 10 or 4
 print('equipped',4,43,col)
 if spdfactornr > 0 then
  print('+'..spdfactornr..'% spd',50,43,13)
 end
 for _i=0,avatar.startarmor-1 do
  sspr(0,0,5,5,121-_i*6,43)
 end
 for slot in all(equipslots) do
  local item=avatar.items[slot[1]]
  if not item then
   spr(slot[2],6+offsetx,52)
  else
   spr(item.sprite,6+offsetx,52)
  end
  if sectioncur == 2 and i == equippedcur then
   rect(4+offsetx,50,15+offsetx,61,10)
   if item then
    print(item.name,4,64,7)
   end
  end
  offsetx+=12
  i+=1
 end

 -- draw availableskills section
 offsetx,i,col=0,1,
   sectioncur == 3 and 10 or 4
 print('skills',4,79,col)
 for skill in all(availableskills) do
  spr(skill.sprite,6+offsetx,88)
  if sectioncur == 3 and i == availableskillscur then
   rect(4+offsetx,86,15+offsetx,97,10)
   if skill then
    print(skill.desc,4,109,7)
   end
  end
  if skill == avatar.skill1 then
   spr(24,6+offsetx,100)
   print('\x8e',7+offsetx,100,11)
  end
  if skill == avatar.skill2 then
   spr(24,6+offsetx,100)
   print('\x97',7+offsetx,100,8)
  end
  offsetx+=12
  i+=1
 end

 -- draw exit button
 col=sectioncur == 4 and 10 or 4
 print('exit',57,120,col)
end

function splash()
 music(0)
 _update60=function()
  tick+=1
  if btnp(4) then
   theme=nil
   equipinit()
  end
 end
 _draw=function()
  cls(1)
  sspr(79,99,49,29,42,32)
  col=tick % 60 <= 30 and 13 or 7
  if theme then
   print('you truly are a',32,17,13)
   print('\x8e to continue',38,118,col)
  else
   print('\x8e to start',42,118,col)
  end
 end
end

_init=splash

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
00000d0000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d00d0000d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d11000d0d1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd01100ddd01100000000000000000000000000000000000000000000000000000000000000007070777077707770707007707070077000000000000000000
0dd101100dd101100000000000000000000000000000000000000000000000000000000000000007070d7d07d70d7d070707d7070707dd000000000000000000
ddd11011ddd110110000000000000000000000000000000000000000000000000000000000000007070070077d00700707070707070777000000000000000000
dd111011dd111011000000000000000000000000000000000000000000000000000000000000000777007007d700700707070707070dd7000000000000000000
0010010000100100000000000000000000000000000000000000000000000000000000000000000d7d0777070700700d77077d0d77077d000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000d00ddd0d0d00d000dd0dd000dd0dd0000000000000000000
11111111111111110050050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11011111111111110055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10110101111111110050050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101001111111110155551000000000000000000000000000000000000000000000000000000007070777077000700707077700770707077707770000000000
101010101111111110500501000000000000000000000000000000000000000000000000000000070707d707d707d707070d7d07dd070707dd07d70000000000
001000101111111101111110000000000000000000000000000000000000000000000000000000070707770707070707070070077707770770077d0000000000
010001001111111100000000000000000000000000000000000000000000000000000000000000077707d70707077d070700700dd707d707d007d70000000000
1111111111111111111111110000000000000000000000000000000000000000000000000000000d7d070707070d770d770777077d0707077707070000000000
11111111111111110000000100000000000000000000000000000000000000000000000000000000d00d0d0d0d00dd00dd0ddd0dd00d0d0ddd0d0d0000000000
00000000111111115501100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01101111111111115500001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01001110111111115515500100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111115515500100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11011011111111115515515100000000000000000000000000000000000000000000000000000000000000000000000288888882888802888828888088888000
10010011111111111111111100000000000000000000000000000000000000000000000000000000000000000000000028822280288200288202882028220000
11111111111111111111111100000000000000000000000000000000000000000000005500000000000000000005000008800020028000082000882028800000
11111111111111110000000100000000000000000000000000000000000000000005515500000000000000050050000008800000008800880000880008800000
00000000111111115501100100000000000000000000000000000000000000005515515500000000000000505050000008888200008808820000880008800000
01101111111111115500001100000000000000000000000000000000000000005515515500000000000000505055000008828000002888200000880008800000
01001110111111115515500100000000000000000000000000000000000000005515511100000000000000050050000008802000000888200000880008800000
00000000111111115515500100000000000000000000000000000000000000005511111100000000000000000050000008800080000282000000880028800008
11011011111111115515515100000000000000000000000000000000000000001111111100000000000000000500000288888880000080000228888288888882
10010011111111111111111100000000000000000000000000000000000000000000000000000000000000000000000022222220000020000022222022222220
__label__
00000000000000001110001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111100100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00101111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111101000000000000000000000000000000000
01000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111100000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000101111111111111111111111100000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000001011111111555555515111111110000000001111100000000000
00000000000000000000000000000000000000000000000000000000000000000000000000011111111555555555555555111111000000111111000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000011111111555dd66676766dd5551111111111111111000000000000
00000000000000000000000000000000000000000000000000000000000000000000000001111115555667777777777776d55515111111111511111110000000
000000000000000000000000000000000000000000000000000000000000000000000000011111555d7777777777777777766555511111155551111110001001
0000000000000000000000000000000000000000000000000000000000000000000000000111155d6777777777777777777776d5555155555555551111111111
0000000000000000000000000000000000000000000000000000000000000000000001101111556777777777777777777777777d555555555555511111515111
00000000000000000000000000000000000000000000000000000077000000000000111111155677777777777777777777777777d55555551555551511151511
000000000000000000000000000000000000000000000000000000670000000000001111115567777777777777777777777777777d5111115151515111111111
000000000000000000000000000000000000000000000000000000672000000000011111155d7777777777777777777777776766665111111111111111111111
00000000000000000000000000000000000000000000000000000076200000000011111155d7777777777777777777777777766dddd511111111111111111111
00000000000000000000000000000000000000000000000000000d74200000000001111555677777777777777777776777777766ddd511111111111111111111
0000000000000000000000000000005000000000057760000000077400000000001551115d7777777777777777777676777776766d6d51111111111111111111
0000000000000000000000000000077d00000005776500000000576200100000015d111556777777777777777777777777777767666651111111111111111511
00000000000000000000000000006750000000677702200000006642067d000015d51155d77777777777777777777777777777777666d5111111111111115111
0000000000000000000000000000772200000676d4200057776d7640007710015dd515556777777777777777777777777777777777666d111111111111111111
00000000000000000000000000057420000067d022200d77d5677740005740115d5155556777777777777777777777777777777777766d511111111111111111
000000000000000000000000000d7420000d7602047757d02227677767772015dd55555d77777777777777777777777777777777777766511111111111111111
00000000000000000000000000067400005765200777777220d7f24d6665255d6555555d77777777777777777777777777777777777776511111111111111111
00000000000000000000000000076400007754601777d5400076422f742465d6677655d777777777777777777777777777777777777777511111111111111111
000000000000000000000000000772000d7d2771077744740576400774477dd67777d57777777777749777777777777777777777777777d15111111111111111
000000000000000000000000001762001764476506774775067450d7646764d77677d5774f774777f44777777777777777777777777777d51111111111111111
0000000000000000000011111157f511674267420777776207645176427744776477467d46764f77f4f777777777777777777777777777655111111111111111
0000000000000000011111151157d5157724774557446742d764567f2d7f44774477477447744777f47777777777777777777777777777655511111111111111
00000000000000001111115151d74556744d764576427f45774557744674467644777762d7f4f74774777777f4f7777777777777777777d55111111111111111
00000000000000011511151515d745d764567456752d762d7745676447744774257777447744772f7466777f44f7777777777777777777d55511111111111111
0000000000000011111111115167457742577247d2567447764577f277f477745d74774d7746744674d677744677777777777777777776555551111111111111
00000000000001111111111115674d7644576476545777777747674777477674576477d77f777f47744667f44777777777777777777776555555111515111111
00000110001111111111111111774774775777652567777577765777d77714777652777d77767777f44d7794f67777777777777777777d555551555551511151
001111111111111111111111117747d775157f525776f4244760247444752247d025574547477f66444d7744d666666777777777777765555555555515151555
0111111111111111111111111176774762202225776542420222554245222002225112425244744444dd7644dd66d666667777777777d5555555555111515551
11111111111111110001111115777467420002577552525000001d5451020000200111251544444455567f44ddddddd6d6677777666655555555151511155555
11111111111000000000000016774276450000766220000000005dd5500000000000001111155455511674455555dddddd7776666dd555555511515111115555
0101111111000000000000000774227650000676520000000005ddd50000000000000000000155675117645555555555d77776dd555115151111111111155515
000000111000000000000000005225765000576426715d001d567dd1006700651710060006101d77715765775555d77657767555511111111111111111555111
0000000000000000000000000052057f500077d267777750677777500777767667d067d057600d774067477765557777d7774477111111111111111115551111
00000000000000000000000000000574500d76447657760077767700d76477607640764067400674227777674557764745774776101111111111111115555111
00000000000000000000000000000d74000764277447742677df74207754775f762d76257625d77425777467456764d746777774551111111111111115551111
0000000000000000000000000000067400d762476247f457774774267d26762774277427742077760d77447645774476477247f4577111111111111151511111
00000000000000000000000000000674007742674267426774476257742774d76257625774267577577f2f742677776467526742575111111111111111111111
000000000000000000000000000006740d7d207645764577f2774277f247727742674277725772f7477447724777f44475227645762511111111111111111111
0000000000000000000000000000076417645576267f277744762d774277d477447746774267426767d2d7d277742447d5257626752511111111111111111111
000000000000000000000000000007f267d20d7d4774777444764777467747774776d767477742777742674776742d7d525d7467d25111111111111111111111
0000000000000000000000000000076476450d77767776744d777567777767777d777d47775f777774256777547777d5255d777d545111111111111111111111
000000000000000000000000000017d674200077d0f7444250674047757f7547f047f026752246674221177522676552555177d5455111111111111111111111
00000000000000000000000000005767625000022224244400022205247f65222202220022255424225115222554242555115424511111111111111111111111
0000000000000000000000000000d777420000052554455500002000267742002000201152511555251111225155455551111225111111111111111111111100
000000000000000000000000000077742500000015dd5d5000020222277722820228884888211112222222284422288411222222221111111111111111111000
00000000000000000000000000007742200000005ddddd1000888888877424888888888888811128888888888888888888888888888411111111111111110000
00000000000000000000000000000222000000015dddd51100888888877228888888888888211148888888888888888888888888884811111111111111000000
0000000000000000000000000000022000000005ddddd11110888888774288848888888884111128888888888888888888888888888801111111101100000000
000000000000000000000000000000000000005ddddd1111112888887f4288888488888811111112888888842888882188888888888000000100000000000000
00000000000000000000000000000010000001ddddd5111111112888744528888818888881111118888881115888882108888888000000000000000000000000
00000000000000000000000000011111111115ddddd1111111111887f22111288218888882111128888825111888884100888888000000000000000000000000
0000000000000000001110001111111111115ddddd51111551111887425111111114888888111188888851111888888100888884000000000000000000000000
000000000000000111111111111111111115ddddd511115441111877221111111112888888111588888211111888884000888882000000000000000000000000
000000000000000111111111111011111115ddddd111114551112774241228811111288888411488888111111888884000888882000000000000000000000000
00000000000000111111111100000111115d5ddd5111154111112882288888881111188888812888881111111888888000888880000000000000000000000000
0000000000000011111111100000000111d5ddd51111154111114822888888841000128888828888821111111888888000888480000000000000000000000000
000000000000001111111510000000011dd55dd11154544411118888888888881000018888888888811111111888888000888480000000000000000000000000
000000000000001111111151000000015d55dd511145455111118888888888821011108888888888411111111888888000888280000000000000000000000000
00000000000001111111100110000005dd5dd5111511441111118888841128211111110888888888211000011888888002888480000000042000000000000000
0000000000000011111100001110001dd5ddd1111415541111118888841111111111111888888888111000000888888002888280000000888200000000000000
00000000000000111111000001551155555d51111454141111112888881111122111111288888882111000000888888002888480000028888000000000000000
0000000000001011111100000015555555d511111445141111112888882224888811110088888881111100000888882002888282222888888000000000000000
00000000000111111111000001115555555111111111541111128888288888888811110028888881111000000888888828888448888888882000000000000000
00000000001111111110000011115555555111111111551112888888888888888111100008888820000000008888884888888888888888880000000000000000
00000001011111111100000011111555555111111545411128888888888888882111000008888800000000088888888888888888888888820000000000000000
11001011111111111000000001110015555511111444511128888888888888881111100002888800000000088888888888888888888888200000000000000000
11111111110111000000000001100001111555111111111114884842211102211111100000888800000000028200222442484200020000000000000000000000
00111111000000000000000000000011111115511111111111111111111111111111110000088000000000000000000000000000000000000000000000000000
00001111000000000000000000000011111111155511111111111111111110001111110000000000000000000000000000000000000000000000000000000000
00000111100000000000000010000011111110115551111111111111111110000000110000000000000000000000000000000000000000000000000000000000
00000011110000000000000015100001111111011111111111111111111110000000010000000000000000000000000000000000000000000000000000000000
00000011111000000000000001551000000010001110011111111111111111000000000000000000000000000000000000000000000000000000000000000000
00000001111000000000000000010000000000000000001111111111111111000000000000000000000000000000000000000001110001100000000000000011
00000000111100001000000000000000000000000000000010001000111110000000000000000000000000000000000000011111111151511100101001100111
00000000011100010000000000000000000000000000000000000000000100000000000000000000000000000000000000115555555551151111111111111111
00000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000001111555555511111111151511111111111
00000000010111000000110000000000000000000000000000000000000000000000000000000000000000001111151515551515111100111111111111111111
00000000000010000001555000000000000000000000000000000000000000000000000000000011100000115555515151111111111000111111111111111111
00000000000000000111555100000000000000000000000000000000000000000000000000000011151101151511111111111111110000000000111111111111
00000000000000000151115000000000000000000000000000000000000111100000110000000111555111511111111111100000000000000000001000000000
00000001000001000155111000000000000000000000000000010100111115111515551011111115115511111111000000000000000000000000000000000000
00000010000000100155510000000000000000000000000111111111115111511151511111111111111111110000000000000000000000000000000000000000
00000001000000000015100000000000000000000000001111111511111111111111111511111111110100000000000000000000000000000000000000000000
00000000000000000000000000000011100000000111001111111111111111100000111111111110000000000000000000000000000000000000000000000000
00000000000000000000000000000111111000011111111111111111110000000000000111111100000000001111000000000000000000000000000000000000
00000000000000000000000000001111111111111111111000000000000000000000000000000000000000001110000000000000000000000000000000000000
00000000000000000000000000000111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000001111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000011111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000001110111110111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000011111111101011111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000001011111010111111111110100000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000111110111111111110111010000000000010000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000010100011111111100010101000000000001011111000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000010001010101000001000000000000000011111111111111000000000000000000000000000000000000000000010000
00000000000000000000000000000000000000000000000000000000000000000011111111111111100000000011000000000000000000000000000011110000
00000000000000000000000000000000000000000000000000000000000000000001001111011111110101111111110000011101000000000000000011010000
00000000000000000000000000000000000000000000000000000000000000000000000010111011111011111111111010111111101010000000000010000010
00000000000000000000000000000000000000000000000000000000000000000000000000000001010111111111111110000111111111111101000000001111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111100000011111111111111100000001111
00000000000000000001010000000001110000000000000000000000000000000000000000000000000111111111111100000001111111111111000000011111
00000000000000000000001100000000111000000000000000000000000000000000000000000000001111111111111111000000110010000000000011001110
00000000000000000000000101000000010100000000000000000000000000000000000000000000001111111111111111110000000000000000000011000000
00000000000000000000000000000000101010000000000000000000000011100000000000000000000011111111111111110000000000000000000011100000
00000000000000000000000000000000010001010100000000000000000011110100000000000000000001111111111111110000000000000000000011111001
00000000000000000000000000000000001000111110000000000000000011101110000000000000000001111111111111100000000000000000000011111100
00000000000000000000000000000000010100001111110100000000000111111111000000000000000001111111111111000000000000000000000001111111
00000000000000000000000000000000001010000010111111111000000011111111100000000000000011111111111110000000000000000000000011111111
00000000000000000000000000000000000000000001010111111000000111111111110000011111000111011111111111000000000000000000000011111111
00000000000000000000000000000000100000000000000000111000000111111111111101111011100110111110111111100000000000111111000111111110

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
03 1a6e4344
00 23244344
01 25264344
00 25264344
02 27674344
00 6e424344
02 6c424344
00 64644344
02 6c424344
00 65674344
00 114b4344
01 16184344
02 17194344
00 706e4344
00 706e4344
00 67674344
00 706e4344
00 706e4344
00 6f6c4344
00 706e4344
00 114b4344
01 2d6e4344
00 2e6e4344
02 2c6e4344
00 706e4344

