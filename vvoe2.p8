pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- virtuous vanquisher of evil 2.0
-- by ironchest games

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

cartdata'ironchestgames_vvoe2_v1_dev1'

function _sfx(_s)
 sfx(tonum(_s))
end

function curryright(f,a)
 return function(b)
  f(b,a)
 end
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

function concat(_ts)
 local _result={}
 for _t in all(_ts) do
  for _v in all(_t) do
   add(_result,_v)
  end
 end
 return _result
end

function sortony(_t)
 for _i=1,#_t do
  local _j = _i
  while _j > 1 and _t[_j-1].y > _t[_j].y do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

function flrrnd(_n)
 return flr(rnd(_n))
end

-- note: last char needs to be ','
function pfn(s)
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
 return _class != 0 and createitem(
   _class,
   band(dat,0b11110000)/16,
   band(dat,0b111100000000)/256) or nil
end

function isinside(x,y,aabb)
 return x > aabb.x-aabb.hw and x < aabb.x+aabb.hw and
        y > aabb.y-aabb.hh and y < aabb.y+aabb.hh
end

function isaabbposinside(aabb,other)
 return isinside(aabb.x,aabb.y,other) and other
end

function isaabbscolliding(a,b)
 return a.x-a.hw < b.x+b.hw and
        a.x+a.hw > b.x-b.hw and
        a.y-a.hh+(a.yoff or 0) < b.y+b.hh+(b.yoff or 0) and
        a.y+a.hh+(a.yoff or 0) > b.y-b.hh+(b.yoff or 0) and b
end

function haslos(_x1,_y1,_x2,_y2)
 local dx,dy,x,y,xinc,yinc=
  abs(_x2-_x1),abs(_y2-_y1),_x1,_y1,sgn(_x2-_x1),sgn(_y2-_y1)
 local n,err=1+dx+dy,dx-dy
 dx*=2
 dy*=2

 while n > 0 do
  n-=1
  for _p in all(props) do
   if isinside(x,y,_p) then
    return
   end
  end
  -- if walls[flr(y/8)][flr(x/8)] == 1 then
  --  return
  -- end
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
 local dx,dy=(x2-x1)*0.1,(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

function norm(n)
 return n == 0 and 0 or sgn(n)
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

function findflr(_x,_y)
 local a,d=rnd(),1
 repeat
  a+=0.05
  d+=0.02
  x,y=mid(1,flr(_x/8+cos(a)*2),14),mid(1,flr(_y/8+sin(a)*2),14)
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

arrowframe=pfn'13,26,4,1,-1,0,'

function getvfxframei(a)
 return min(flr((a+0.0625)*8)/8,1)
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
   pcol1=8,pcol2=14
  })
 end

 _a.effect.c-=1
 if _a.effect.c <= 0 then
  _a.effect.c,_a.a=12,rnd()
 end

 _a.dx,_a.dy=cos(_a.a)*_a.spd,sin(_a.a)*_a.spd
end

function freezeeffect(_a)
 add(vfxs,{{72,92,8,7,_a.x-4,_a.y-3.5,c=2}})
 _a.dx,_a.dy=0,0
end

-- skills
function getskillxy(_a)
 return _a.x+cos(_a.a)*4,_a.y+sin(_a.a)*4
end

function swordattackskillfactory(
 offsets,attackcol,typ,recovertime,dmg)
 return {
  sprite=12,
  desc='sword attack',
  preprfm=15,
  postprfm=28,
  perform=function(_a)

   add(attacks,{
    isavatar=_a.isavatar,
    x=_a.flipx and _a.x-5 or _a.x+5,
    y=_a.y-8,
    hw=6,hh=6,
    state_c=1,
    typ=typ,
    recovertime=recovertime or 0,
    knocka=_a.a,
    tar_c=1000,
    dmg=dmg or 1,
   })

   local _f=pfn('0,27,17,13,'..offsets)
   _f.flipx=_a.flipx
   _f.c,_f.col=15,attackcol
   _f[5]=_f.flipx and _a.x-_f[3]-_f[5] or _a.x+_f[5]
   _f[6]+=_a.y
   add(vfxs,{_f})

   _sfx'4'
  end
 }
end

function bowattackskillfactory(
  offsets,attackcol,arrowcol,typ,recovertime)
 return {
  sprite=13,
  desc='bow attack',
  preprfm=26,
  postprfm=6,
  perform=function(_a)
   a=getvfxframei(_a.a)

   add(attacks,{
    isavatar=_a.isavatar,
    x=_a.x-0.5,y=_a.y-8,
    hw=1,hh=1,
    state_c=1000,
    dx=cos(a)*1.6,
    dy=0,
    typ=typ,
    recovertime=recovertime or 0,
    frame=clone(arrowframe),
    col=arrowcol,
   })

   local _f=pfn('16,41,11,5,'..offsets)
   _f.flipx=_a.flipx
   _f.c,_f.col=4,attackcol
   _f[5]=_f.flipx and _a.x-_f[3]-_f[5] or _a.x+_f[5]
   _f[6]+=_a.y
   add(vfxs,{_f})

   _sfx'5'
  end
 }
end

function boltskillfactory(
  typ,
  attackcol,
  castpemcol1,
  castpemcol2,
  boltpemcol1,
  boltpemcol2,
  sprite,
  desc)
 return {
  sprite=sprite,
  desc=desc,
  preprfm=50,
  postprfm=0,
  startpemitter=function(_a,life)
   add(pemitters,{
    follow=_a,
    life=life,
    prate=pfn'1,3,',
    plife=pfn'15,25,',
    poffsets=pfn'-5,0,5,0,',
    pcol1=castpemcol1,pcol2=castpemcol2
   })
   _sfx'9'
  end,
  perform=function(_a)
   local x,y=getskillxy(_a)

   local attack={
    isavatar=_a.isavatar,
    x=x,y=y-6,
    hw=1,hh=1,
    state_c=1000,
    dx=_a.flipx and -1.2 or 1.2,
    dy=0,
    typ=typ,
    recovertime=120,
    frame=pfn'28,41,4,4,-1,-1,',
    col=attackcol,
   }
   add(attacks,attack)

   add(pemitters,{
    follow=attack,
    life=1000,
    prate=pfn'0,0,',
    plife=pfn'3,18,',
    poffsets=pfn'-1,-1,1,2,',
    dy=pfn'0,0,',
    pcol1=boltpemcol1,pcol2=boltpemcol2
   })
   _sfx'32'
  end
 }
end

-- actors
function actfact(_a)
 _a.state,
 _a.state_c,
 _a.curframe,
 _a.dx,_a.dy,
 _a.runspd,
 _a.dmgfx_c,
 _a.comfydist,
 _a.toocloseto,
 _a.a,
 _a.hh,
 _a.yoff
   =
   'idling',
   0,
   1,
   0,0,
   _a.spd,
   0,
   _a.comfydist or 1,
   {},
   0,
   _a.hh or 5,
   _a.yoff or 0
 return _a
end

-- enemy factories
function newmeleetroll(x,y)
 return actfact{
  x=x,y=y,
  hw=2,hh=4,
  yoff=-5,
  spd=0.46,
  hp=3,
  att_preprfm=50,
  att_postprfm=20,
  prfmatt=swordattackskillfactory(
   '-8,-17,',
   7,
   'knockback'
   ).perform,
  idling={pfn'28,26,9,9, -3,-10,'},
  moving={animspd=0.18,pfn'17,26,11,9, -5,-9,',pfn'28,26,9,9, -3,-10,'},
  attacking={animspd=0,pfn'37,26,10,11, -7,-11,',pfn'47,26,13,8, -4,-8,'},
  recovering={pfn'47,26,13,8, -4,-8,'}
 }
end

function newtrollcaster(x,y)
 local s=boltskillfactory('fire',14,8,14,14,8,15,'firebolt')
 return actfact{
  x=x,y=y,
  hw=1.5,hh=5,
  yoff=-6,
  spd=0.43,
  hp=2,
  att_preprfm=60,
  att_postprfm=40,
  att_range=90,
  prfmatt=s.perform,
  onpreprfm=s.startpemitter,
  comfydist=30,
  idling={pfn'70,20,10,13,-4,-13,'},
  moving={animspd=0.18,pfn'60,21,10,13,-3,-13,',pfn'70,20,10,13,-4,-13,'},
  attacking={animspd=0,pfn'80,18,10,15,-4,-15,',pfn'90,22,10,12,-4,-12,'},
  recovering={pfn'90,22,10,12,-4,-12,'}
 }
end

function newbowskele(x,y)
 return actfact{
  x=x,y=y,
  hw=1.5,hh=5,
  yoff=-6,
  spd=0.5,
  hp=2,
  att_preprfm=60,
  att_postprfm=40,
  att_range=90,
  prfmatt=bowattackskillfactory(
   '-2,-10,',
   7
   ).perform,
  comfydist=40,
  idling={pfn'33,37,12,13,-3,-13,'},
  moving={animspd=0.18,pfn'33,37,12,13,-3,-13,',pfn'45,37,13,12,-4,-13,'},
  attacking={animspd=0,pfn'58,34,12,13,-4,-13,',pfn'70,34,10,13,-4,-13,'},
  recovering={pfn'45,37,13,12,-4,-13,'}
 }
end

-- function casterfactory(_hp,_cols,_idlef,_attackf,_boltskill)
--  return function(x,y)
--   return actfact{
--    x=x,y=y,
--    hw=1.5,
--    spd=0.25*_hp,
--    hp=_hp,
--    att_preprfm=100,
--    att_postprfm=20,
--    att_range=60,
--    cols=_cols,
--    prfmatt=function(_a)
--     _a.a=atan2(_a.tarx-_a.x,_a.tary-_a.y)
--     _boltskill.perform(_a)
--    end,
--    comfydist=30,
--    idling={_idlef},
--    moving={animspd=0.18,_idlef},
--    attacking={animspd=0,_attackf,_idlef},
--    recovering={_idlef},
--    onpreprfm=_boltskill.startpemitter
--   }
--  end
-- end

-- newtrollcaster=casterfactory(
--  1,pfn'3,4,2,5,9,',pfn'41,32,4,7,-2,-4.5,',pfn'45,32,4,7,-2,-4.5,',
--  boltskillfactory('fire',14,8,14,14,8))

-- newdemoncaster=casterfactory(
--  3,pfn'8,13,5,6,12,',pfn'41,32,4,8,-2,-5.5,',pfn'45,32,4,8,-2,-5.5,',
--  boltskillfactory('ice',7,12,12,12,13))

-- function newgianttroll(x,y)
--  boss=actfact{
--   name='giant troll',
--   x=x,y=y,
--   hw=1.5,hh=3,
--   isbig=true,
--   spd=0.7,
--   hp=7,
--   att_preprfm=40,
--   att_postprfm=30,
--   prfmatt=performenemymelee,
--   idling={pfn'36,25,7,7,-4,-4,'},
--   moving={animspd=0.18,pfn'43,25,7,7,-4,-4,',pfn'50,25,7,7,-4,-4,'},
--   attacking={animspd=0,pfn'57,25,7,7,-4,-4,',pfn'64,25,8,7,-4,-4,'},
--   recovering={pfn'72,25,7,7,-4,-4,'}
--  }
--  return boss
-- end

-- function newmeleeskele(x,y)
--  return actfact{
--   x=x,y=y,
--   hw=1.5,
--   spd=0.5,
--   hp=3,
--   att_preprfm=40,
--   att_postprfm=10,
--   prfmatt=performenemymelee,
--   idling={pfn'0,15,4,5,-2,-3,'},
--   moving={animspd=0.18,pfn'0,15,4,5,-2,-3,',pfn'4,15,4,5,-2,-3,'},
--   attacking={animspd=0,pfn'8,15,4,5,-2,-3,',pfn'11,15,6,5,-3,-3,'},
--   recovering={pfn'0,15,4,5,-2,-3,'}
--  }
-- end

-- function batfactory(_cols,_att_col,_att_typ,_att_recovertime)
--  return function(x,y)
--   return actfact{
--    isghost=true,
--    x=x,y=y,
--    hw=1.5,
--    spd=0.75,
--    hp=1,
--    att_preprfm=30,
--    att_postprfm=0,
--    att_col=_att_col,
--    att_typ=_att_typ,
--    att_recovertime=_att_recovertime,
--    cols=_cols,
--    prfmatt=performenemymelee,
--    idling={pfn'36,15,3,3,-1.5,-1.5,'},
--    moving={animspd=0.21,pfn'36,15,3,3,-1.5,-1.5,',pfn'39,15,3,3,-1.5,-1.5,'},
--    attacking={animspd=0.32,pfn'36,15,3,3,-1.5,-1.5,',pfn'39,15,3,3,-1.5,-1.5,'},
--    recovering={pfn'36,15,3,3,-1.5,-1.5,'}
--   }
--  end
-- end

-- newbatenemy=batfactory()
-- newfirebatenemy=batfactory(pfn'0,0,0,0,8,',14,'fire',120)

-- function newvampireboss(x,y)
--  boss=actfact{
--   name='samael',
--   isghost=true,
--   x=x,y=y,
--   hw=1.5,
--   spd=0.75,
--   hp=8,
--   att_preprfm=20,
--   att_postprfm=75,
--   att_siz=2,
--   prfmatt=function(_a)
--    _a.a=atan2(_a.tarx-_a.x,_a.tary-_a.y)
--    add(attacks,{
--     x=_a.x+cos(_a.a)*4,
--     y=_a.y+sin(_a.a)*4,
--     hw=2,hh=2,
--     state_c=1,
--     dmg=2
--    })
--    f=pfn'92,91,4,3,-2,-1.5,'
--    f.c=4
--    _x,_y=getskillxy(_a)
--    f[5]+=_x
--    f[6]+=_y
--    add(vfxs,{f})
--    _sfx'4'
--   end,
--   idling={pfn'82,91,5,5,-3,-3,'},
--   moving={animspd=0.21,pfn'96,91,3,3,-1.5,-1.5,',pfn'99,91,3,3,-1.5,-1.5,'},
--   attacking={animspd=0.3,pfn'87,91,5,5,-3,-3,',pfn'82,91,5,5,-3,-3,'},
--   recovering={pfn'82,91,5,5,-3,-3,'}
--  }
--  return boss
-- end

-- function newskeleking(x,y)

--  function setupmelee(_a)
--   _a.att_range,
--   _a.att_preprfm,
--   _a.att_postprfm,
--   _a.prfmatt,
--   _a.afterpostprfm,
--   _a.attacking,
--   _a.onpreprfm,
--   _a.nolos
--    =7,30,60,performmelee,setupmagic,
--    {animspd=0,pfn'0,40,15,18,-7,-13,',pfn'0,58,20,18,-10,-13,'}
--  end

--  function performmelee(_a)
--   add(attacks,{
--    throughwalls=true,
--    x=_a.x+cos(_a.a)*2,y=_a.y-3,
--    hw=7,hh=8,
--    state_c=2,
--    typ='knockback',
--    knocka=_a.a,
--   })
--   _sfx'4'
--  end

--  function setupmagic(_a)
--   _a.att_range,
--   _a.att_preprfm,
--   _a.att_postprfm,
--   _a.prfmatt,
--   _a.afterpostprfm,
--   _a.attacking,
--   _a.onpreprfm,
--   _a.nolos
--     =60,110,0,performmagic,setupmelee,{
--       animspd=0,
--       pfn'24,58,15,18,-7,-13,',
--       pfn'24,58,15,18,-7,-13,',
--      },magicpreprfm,true
--  end

--  function magicpreprfm(_a)
--   _a.att_x,_a.att_y=findflr(_a.x,_a.y)
--   add(pemitters,{
--    follow={x=_a.att_x,y=_a.att_y},
--    life=140,
--    prate=pfn'1,2,',
--    plife=pfn'10,15,',
--    poffsets=pfn'-2,0.5,1,0.5,',
--    pcol1=11,pcol2=3
--   })
--   _sfx'9'
--  end

--  function performmagic(_a)
--   local _e=newmeleeskele(_a.att_x,_a.att_y)
--   _e.state,_e.laststate,_e.state_c='recovering','recovering',50
--   add(actors,_e)
--  end

--  boss=actfact{
--   name='forgotten king',
--   isbig=true,
--   x=x,y=y,
--   hw=1.5,hh=3,
--   spd=0.4,
--   hp=10,
--   idling={pfn'0,40,15,18,-7,-13,'},
--   moving={animspd=0.24,pfn'16,40,15,18,-7,-13,',pfn'32,40,15,18,-7,-13,'},
--   recovering={pfn'0,40,15,18,-7,-13,'},
--   onroam=setupmagic
--  }
--  setupmagic(boss)
--  return boss
-- end

-- function newdemonboss(x,y)
--  boss=actfact{
--   name='the evil',
--   isbig=true,
--   x=x,y=y,
--   hw=3.5,hh=3.5,
--   spd=0.75,
--   hp=20,
--   att_preprfm=30,
--   att_postprfm=50,
--   att_range=10,
--   att_siz=12,
--   att_col=0,
--   att_typ='fire',
--   att_recovertime=90,
--   prfmatt=performenemymelee,
--   passiveskills={{immune='fire'},{immune='ice'}},
--   idling={pfn'77,71,19,18,-10,-15,'},
--   moving={animspd=0.24,pfn'41,71,19,18,-10,-15,',pfn'59,71,19,18,-10,-15,'},
--   attacking={animspd=0,pfn'79,45,31,24,-15,-20,',pfn'48,45,31,24,-15,-20,'},
--   recovering={pfn'95,71,19,18,-10,-15,'}
--  }
--  return boss
-- end

-- items
slots,comcols2={'weapon','offhand','armor','helmet','boots','amulet','book'},pfn'-1,-1,-1,-1,2,'

function createitem(_itemclass,_prefix,_suffix)
 local itemclass=itemclasses[_itemclass]
 local itemname,armor,spdfactor,_att_spd_dec,prefixt,col,col2,sprite=
   itemclass.name,itemclass.armor or 0,itemclass.spdfactor or 0,0,
   itemclass.prefix or prefix

 _suffix=suffix[_suffix]
 if _suffix then
  itemname=itemname.._suffix.name
 end

 if _itemclass >=8 and _prefix == 1 and _suffix then
  col,col2,sprite=_suffix.cols[_itemclass] or _suffix.col,
   _suffix.cols2 and _suffix.cols2[_itemclass],
   _suffix.sprite
 end

 _prefix=prefixt[_prefix]
 if _prefix then
  itemname=_prefix.name..itemname
 end

 if not (_prefix or _suffix) then
  itemname='useless '..itemname
 end

 for _affix in all{_prefix,_suffix} do
  if _affix then
   armor+=(_affix.armor or 0)
   spdfactor+=(_affix.spdfactor or 0)
   _att_spd_dec+=(_affix.att_spd_dec or 0)
   col,col2,sprite=col or _affix.cols and _affix.cols[_itemclass] or _affix.col,
    col2 or _affix.cols2 and _affix.cols2[_itemclass] or itemclass.col2,
    sprite or _affix.sprites[_itemclass]
  end
 end

 return {
  class=_itemclass,
  slot=itemclass.slot,
  name=itemname,
  sprite=sprite or itemclass.sprite,
  col=col or itemclass.col,
  col2=col2 or comcols2,
  prefix=_prefix,
  suffix=_suffix,
  armor=armor,
  spdfactor=spdfactor,
  att_spd_dec=_att_spd_dec,
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
 {name='',sprites={},skill=swordattackskillfactory(7)},
 {name='ice ',col=7,sprites=pfn'30,46,162,63,232,79,49,199,214,',
  skill=swordattackskillfactory(12,'ice',150)},
 {name='flaming ',col=8,sprites=pfn'29,45,162,62,231,78,178,198,213,',
  skill=swordattackskillfactory(14,'fire',60)},
 {name='heavy ',col=5,sprites=pfn'-1,-1,-1,-1,-1,-1,-1,196,',
  skill=swordattackskillfactory(7,'knockback')},
 {name='sharp ',col=6,sprites=pfn'-1,-1,-1,-1,-1,-1,-1,200,',
  skill=swordattackskillfactory(7,nil,nil,2)},
}

bowprefix={
 {name='',col=4,sprites={},skill=bowattackskillfactory(26,7,2),twohand=true},
 {name='ice ',col=12,sprites=pfn'30,46,162,63,232,79,49,199,214,',
  skill=bowattackskillfactory(26,7,12,'ice',150),twohand=true},
 {name='flaming ',col=8,sprites=pfn'29,45,162,62,231,78,178,198,213,',
  skill=bowattackskillfactory(26,14,8,'fire',60),twohand=true},
}

amuletprefix={
 {
  name='skull ',
  sprites=pfn'-1,-1,31,',
  skill={
   sprite=9,
   desc='passive, resurrect once',
   onhit=function (_a)
    if _a.hp <= 0 then
     _a.hp,_a.removeme=3
     for k,v in pairs(slots) do
      local _item=_a.items[v]
      if _item and _item.prefix and
         _item.prefix.skill == amuletprefix[1].skill then
       _a.items[v]=nil
       saveitem(k,0,0,0)
       del(_a.passiveskills,_item.prefix.skill)
       break
      end
     end
     _sfx'21'
    end
   end
  }
 }
}

prefix={
 {name='knight\'s ',sprites=pfn'26,42,-1,59,228,76,',
  cols=pfn'13,13,-1,13,13,13,-1,13,',cols2=pfn'-1,-1,-1,-1,1,',armor=1},
 {name='feathered ',sprites=pfn'27,43,161,60,229,95,177,197,212,',
  cols=pfn'4,13,-1,2,4,4,-1,15,3,',spdfactor=0.1},
 {name='dragonscale ',sprites=pfn'28,44,-1,61,230,77,',
  cols=pfn'9,9,-1,9,9,9,-1,-1,-1,',cols2=pfn'-1,-1,-1,-1,4,',skill={
  sprite=8,desc='passive, cannot be burned',immune='fire'}},
 {name='warming ',sprites=pfn'29,45,162,62,231,78,178,198,213,',
  cols=pfn'8,8,-1,2,8,8,-1,8,8,',skill={
  sprite=11,desc='passive, cannot be frozen',immune='ice'}}
}

suffix={
 {name=' of haste',sprites=pfn'27,43,161,60,229,95,177,197,212,',
  cols=pfn'4,13,-1,2,4,4,-1,15,3,',spdfactor=0.1},
 {name=' of phasing',sprites=pfn'143,127,164,111,246,94,47,199,214,',
  cols=pfn'13,1,-1,1,2,1,-1,12,12,',cols2=pfn'-1,-1,-1,-1,1,',skill={
   sprite=10,
   desc='passive, phase away on hit',
   onhit=function(_a)
    local x,y=findflr(_a.x,_a.y)
    local _f=pfn'9,9,1,1,0,0,'
    _a.x,_a.y,_f.c=x,y,2
    add(vfxs,{
     _f,
     {draw=function(f)
       circ(x,y,f.c*1.5,12)
      end,
      c=12
     }
    })
   end
  }
 },
 {name=' of firebolt',sprites=pfn'29,45,162,62,231,78,178,198,213,',
  cols=pfn'8,8,-1,2,8,8,-1,8,8,',skill=boltskillfactory(
  'fire',14,8,14,14,8,15,'firebolt')},
 {name=' of icebolt',sprites=pfn'30,46,163,63,232,79,179,199,214,',
  cols=pfn'13,6,-1,12,12,12,-1,7,12,',cols2=pfn'-1,-1,-1,-1,1,',skill=boltskillfactory(
  'ice',7,12,12,12,13,14,'icebolt')},
 {name=' of concentration',sprites=pfn'244,245,159,175,191,249,216,247,215,',
  cols=pfn'3,6,-1,3,3,6,-1,6,11,',cols2=pfn'-1,-1,-1,-1,1,',att_spd_dec=3}
}

cloakidling,shieldidling,swordidling,bowidling
  ={pfn'40,9,3,4,-1,-2,'},{pfn'35,9,5,5,-2,-3,'},
  {pfn'9,9,5,5,-2,-3,'},{pfn'25,9,5,5,-2,-3,'}

itemclasses={
 {slot='boots',name='boots',sprite=25,col=2},
 {slot='helmet',name='helmet',sprite=41,col=5},
 {slot='amulet',name='amulet',sprite=160,prefix=amuletprefix},
 {slot='armor',name='platemail',sprite=58,col=5,armor=1},
 {slot='armor',name='cloak',sprite=40,col=4,col2=2,iscloak=true,spdfactor=0.1,
  idling=cloakidling,moving=cloakidling, attacking=cloakidling,recovering=cloakidling},
 {slot='offhand',name='shield',sprite=75,col=2,armor=1,
  idling=shieldidling,moving=shieldidling,attacking=shieldidling,recovering=shieldidling},
 {slot='book',name='book',sprite=176},
 {slot='weapon',name='sword',sprite=71,col=6,prefix=swordprefix,
  idling={pfn'0,20,6,7, 2,-10,'},
  moving={pfn'0,20,6,7, 2,-10,',pfn'0,20,6,7, 2,-9,'},
  attacking={pfn'6,21,7,5, -6,-14,',pfn'13,21,7,5, 5,-5,'},
  recovering={pfn'0,20,6,7,-2,-3,'}
 },
 {slot='weapon',name='bow',sprite=72,col=4,twohand=true,prefix=bowprefix,
  idling=bowidling,moving=bowidling,attacking={
   pfn'30,9,5,5,-2,-3,',pfn'25,9,1,1,-2,-3,'},
  recovering=bowidling}
}


themes={
 {{newmeleetroll,newtrollcaster,newbowskele},
  {pfn'0,41,8,7, -4,-4,',pfn'8,40,8,8, -4,-5,',pfn'0,48,8,16, -4,-14,'}},
}

-- init avatar
idleframe=pfn'0,8,4,12, -2,-12,'
avatar=actfact{
 isavatar=true,
 x=64,y=56,
 hw=2,
 yoff=-6,
 spdfactor=1,
 spd=0.5,
 hp=3,
 startarmor=0,
 att_spd_dec=0,
 armor=0,
 items={
  [1]=createitem(8,1,2),
 },
 skill1=swordattackskillfactory('-5,-16,'),
 skill2=boltskillfactory('fire',14,8,14,8,2,15,'firebolt'),
 inventory={},
 passiveskills={},
 idling={idleframe},
 moving={idleframe,pfn'4,8,7,11, -4,-11,'},
 attacking={animspd=0,
  pfn'11,8,7,13, -4,-13,',
  pfn'18,8,8,10, -3,-10,'},
 recovering={idleframe}
}

for k,v in pairs(slots) do
 avatar.items[v]=loaditem(k)
end

function dungeoninit()
 _update60,_draw,
 theme,nexttheme,avatar.hp,
 avatar.x,avatar.y,avatar.removeme=
  dungeonupdate,dungeondraw,
  1,1,3,10,64
 
 -- reset
 mapw,
 camx,
 curenemyi,
 actors,
 props,
 attacks,
 pemitters,
 vfxs,
 interactables,
 islevelcleared,
 boss=
  512,0,1,{},{},{},{},{},{}

 -- reset avatar
 avatar=add(actors,actfact(avatar))
 avatar.x=10
 avatar.y=64

 -- init map
 mapname='barren plains'

 local _th=themes[theme]
 local _x=-10
 local nme=false
 while _x<mapw do
  _x=_x+flrrnd(24)+12
  local _y=flrrnd(112)+16
  if nme then
   local _e=_th[1][flrrnd(#_th[1])+1]
   add(actors,_e(_x,_y))
  else
   local _f=_th[2][flrrnd(#_th[2])+1]
   add(props,actfact({x=_x,y=_y,hw=4,hh=2,idling={_f}}))
  end
  nme=not nme
  if (_x<120) nme=false
 end

 music(theme*10,0,0b0011)
 -- if boss then
 --  music(1,0,0b0011)
 -- end
end

kills,curenemyi=0,1

function dungeonupdate()

 -- if avatar.hp <= 0 then
  -- if tick-deathts > 150 and btnp(4) then
  --  avatar.inventory,kills,theme,door={},0
  --  equipinit()
  -- end
  -- return
 -- end

 local angle=btnmasktoa[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle then
  if avatar.state != 'recovering' and
     avatar.state != 'attacking' then
   avatar.a,avatar.dx,avatar.dy,avatar.state,avatar.state_c=
    angle,norm(cos(angle)),norm(sin(angle)),'moving',2
   btn0,btn1=btn(0),btn(1)
   if btn0 or btn1 then
    avatar.flipx=btn0
   end
  end
 elseif avatar.state != 'recovering' then
  avatar.dx,avatar.dy=0,0
 end

 -- button input
 skillbuttondown=btn(4) and 1 or btn(5) and 2 or nil

 -- collide against interactables
 curinteractable=nil
 if islevelcleared then
  for i in all(interactables) do
   if isaabbscolliding(avatar,i) then
    skillbuttondown=0
    curinteractable=i
    if btnp(4) then
     i.enter(i)
    end
   end
  end
 end

 if skillbuttondown and
    (avatar.state == 'idling' or
     avatar.state == 'moving') then

  local skill=avatar['skill'..skillbuttondown]
  if skill then
   avatar.state,
   avatar.ispreprfm,
   avatar.att_preprfm,
   avatar.att_postprfm,
   avatar.curframe,
   avatar.prfmatt=
    'attacking',
    true,
    max(1,skill.preprfm-avatar.att_spd_dec),
    skill.postprfm,
    1,
    curryright(skill.perform,skill)
   if avatar.items.weapon then
    avatar.items.weapon.curframe=1
   end
   avatar.onpreprfm=skill.startpemitter
  end
 end

 -- update actors
 local enemy_c=0
 for actor in all(actors) do
  if actor != avatar then
   enemy_c+=1
  end
  actor.state_c-=1

  -- handle states
  if actor.state == 'idling' then
   actor.tarx,actor.tary,actor.ismovingoutofcollision=nil -- reset enemy vars

  elseif actor.state == 'attacking' then
   if actor.laststate != 'attacking' then
    actor.ispreprfm,
    actor.curframe,
    actor.state_c=
     true,
     1,
     actor.att_preprfm

    if actor.onpreprfm then
     actor.onpreprfm(actor,actor.att_preprfm)
    end
   end

   if actor.ispreprfm and actor.state_c <= 0 then
    actor.prfmatt(actor)

    actor.state_c,
    actor.curframe,
    actor.ispreprfm=
     actor.att_postprfm,
     2

   elseif actor.state_c <= 0 then
    if actor.afterpostprfm then
     actor.afterpostprfm(actor)
    end
    actor.state='idling'
   end

  elseif actor.state == 'recovering' then
   if actor.effect then
    actor.effect.func(actor)
   end

   if actor.state_c <= 0 then
    actor.state,actor.effect='idling'
   end

  elseif actor.state == 'moving' and actor != avatar then
   if actor.state_c <= 0 then
    actor.ismovingoutofcollision=nil
   end
   actor.a=atan2(actor.tarx-actor.x,actor.tary-actor.y)

   if dist(actor.x,actor.y,actor.tarx,actor.tary) <= actor.spd + 0.1 then
    actor.state='idling'
   end
   actor.dx,actor.dy=cos(actor.a)*actor.spd,sin(actor.a)*actor.spd
  end

  if actor == avatar and actor.state_c <= 0 then
   actor.state='idling'
  end

  actor.laststate=actor.state
 end

 -- ai to make decisions
 curenemyi+=1
 if curenemyi > #actors then
  curenemyi=1
 end
 enemy=actors[curenemyi]
 if enemy and enemy != avatar and not enemy.removeme then
  enemy.att_range=enemy.att_range or 10
  enemy.flipx=enemy.a > 0.25 and enemy.a < 0.75

  -- aggression vars
  disttoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)
  ismovingoutofcollision=enemy.ismovingoutofcollision
  withinattackdist=disttoavatar <= enemy.att_range
  isinvertical=abs(avatar.y-enemy.y) < 4
  haslostoavatar=disttoavatar < 100
  -- todo: colliding with bounds
  -- todo: colliding with other
  -- todo: colliding with avatar
  -- todo: colliding with prop


  -- resolving effect
  if enemy.state=='recovering' then

  -- continue to move out of collision
  elseif enemy.ismovingoutofcollision then
   enemy.state='moving'

  -- too close to avatar, note: collided with wall not working here?
  elseif disttoavatar <= enemy.comfydist and enemy.state != 'attacking' and enemy.wallcollisiondx == nil then
   enemy.a=atan2(
     avatar.x-enemy.x,
     avatar.y-enemy.y)+0.5 -- note: go the other way
   enemy.state,enemy.tarx,enemy.tary,enemy.ismovingoutofcollision,enemy.state_c,enemy.spd=
    'moving',enemy.x+cos(enemy.a)*10,enemy.y+sin(enemy.a)*10,true,60,enemy.runspd

  -- attack
  elseif (enemy.att_range <= 10 or isinvertical) and
        (enemy.state == 'attacking' or disttoavatar <= enemy.att_range and
        (haslostoavatar or enemy.nolos)) then
   enemy.state,enemy.tarx,enemy.tary='attacking',avatar.x,avatar.y
   enemy.a=atan2(enemy.tarx-enemy.x,enemy.tary-enemy.y)
   enemy.flipx=avatar.x-enemy.x < 0 -- todo

  -- colliding w wall, move out of
  elseif enemy.wallcollisiondx then
   enemy.a=atan2(
     enemy.x+enemy.wallcollisiondx-enemy.x, -- todo: remove silly math
     enemy.y+enemy.wallcollisiondy-enemy.y)+rnd(0.2)-0.1
   enemy.state,enemy.tarx,enemy.tary,enemy.ismovingoutofcollision,enemy.state_c,enemy.spd=
    'moving',enemy.x+cos(enemy.a)*10,enemy.y+sin(enemy.a)*10,true,60,enemy.runspd

  -- colliding w other, move out of
  elseif #enemy.toocloseto > 0 then
   local collidedwith=enemy.toocloseto[1]
   enemy.a=atan2(
     collidedwith.x-enemy.x,
     collidedwith.y-enemy.y)+0.5 -- note: go the other way
   enemy.state,enemy.tarx,enemy.tary,enemy.ismovingoutofcollision,enemy.state_c,enemy.spd=
    'moving',enemy.x+cos(enemy.a)*10,enemy.y+sin(enemy.a)*10,true,60,enemy.runspd

  -- moving vertical to get into range on vertical axis
  elseif withinattackdist and enemy.att_range > 10 and not isinvertical then
   enemy.state,
   enemy.state_c,
   enemy.ismovingoutofcollision,
   enemy.tarx,
   enemy.tary=
    'moving',
    30,
    true,
    enemy.x+rnd(8)-4,
    avatar.y
   enemy.flipx=avatar.x-enemy.x < 0 -- todo

  -- set avatar position as tar, move there
  elseif haslostoavatar then
   enemy.state,enemy.tarx,enemy.tary,enemy.spd=
    'moving',avatar.x,avatar.y,enemy.runspd
   enemy.a=atan2(enemy.tarx-enemy.x,enemy.tary-enemy.y)

  -- continue to move to tar
  elseif enemy.tarx then
   enemy.state='moving'

  -- roam
  elseif not enemy.tarx then
   enemy.a=rnd()
   enemy.state,enemy.tarx,enemy.tary,enemy.spd=
    'moving',enemy.x+cos(enemy.a)*10,enemy.y+sin(enemy.a)*10,enemy.runspd*0.5
   -- if enemy.onroam then
   --  enemy.onroam(enemy)
   -- end
  end
 end

 -- update the next-position
 for actor in all(actors) do
  local spdfactor=actor.spdfactor or 1
  actor.dx,actor.dy=actor.dx*(actor.spd*spdfactor),actor.dy*(actor.spd*spdfactor)
  -- note: after this deltas should not change by input
 end

 -- check lvl cleared
 if enemy_c <= 0 and not islevelcleared then
  islevelcleared=true
  music(6,0,0b0011)
 end

 -- collide against attacks
 for attack in all(attacks) do
  attack.tar_c=attack.tar_c or 1
  for _a in all(actors) do
   if (not attack.removeme) and (not _a.removeme) and
      attack.isavatar != _a.isavatar and
      isaabbscolliding(attack,_a) then
    attack.tar_c-=1
    local dmg,hitsfx=attack.dmg or 1,6

    for skill in all(_a.passiveskills) do
     if attack.typ != nil and
        skill.immune == attack.typ then
      attack.recovertime,attack.typ=nil
     end
    end

    -- special case if ice and already frozen
    if attack.typ == 'ice' and not (_a.effect and
      _a.effect.func == freezeeffect) then
     dmg=0
    end

    -- do dmg
    if _a.armor and _a.armor > 0 then
     _a.armor-=dmg
     if _a.armor < 0 then
      _a.hp+=_a.armor
      _a.armor=0
     end
    else
     _a.hp-=dmg
    end
    _a.state='recovering'
    _a.state_c=attack.recovertime or 0

    -- check if actor is dead
    if _a.hp <= 0 then
     _a.removeme,hitsfx=true,3
     kills+=1

     -- add chest
     isbosschest=_a == boss or theme == 4 and boss
     if kills % (6-theme) <= 0 or isbosschest then
      sprite,kills=isbosschest and 73 or 22,0
      add(interactables,{
       x=_a.x,y=_a.y,
       hw=4,hh=4,
       sprite=sprite,
       text='\x8e loot',
       isbosschest=isbosschest,
       enter=function(i)
        if #avatar.inventory < 10 and not i.isopen then
         i.isopen,i.sprite,i.text=
           true,i.sprite+1,''

         _itemclassn,_n,_m=
          flrrnd(9)+1,1,0
         if theme == 4 and boss then
          _n,_m=0,1
         end

         itemclass=itemclasses[_itemclassn]
         _prefix=itemclass.prefix or prefix
         _prefixn,_suffixn=_itemclassn == 7 and 0 or
          flrrnd(#_prefix+_n)+_m,
          flrrnd(5+_n)+_m

         _suffixn=i.isbosschest and _suffixn or 0
         _prefixn=_itemclassn >= 8 and _suffix != 0 and _prefixn == 0 and 1 or _prefixn
         _sfx'20'
         add(avatar.inventory,createitem(_itemclassn,_prefixn,_suffixn))
        else
         _sfx'30'
        end
       end
      })
     end
    end

    -- effects
    _a.dmgfx_col,_a.dmgfx_c=8,20
    if attack.typ == 'knockback' and not _a.isbig then
     _a.dx,_a.dy=cos(attack.knocka)*5,sin(attack.knocka)*5
    elseif attack.typ == 'fire' then
     _a.effect={func=burningeffect}
     _a.dmgfx_c=48
    elseif attack.typ == 'ice' then
     _a.effect,_a.dmgfx_col={func=freezeeffect},12
    end
    sfx(hitsfx)

    -- hit flash
    local x,y=_a.x+_a.hw+_a.dx/2,_a.y+_a.dy/2-_a.hh
    add(vfxs,{
     {
      draw=function(f)
       circfill(x,y,4,_a.dmgfx_col)
      end,
      c=4,
     },
     {
      draw=function(f)
       circfill(x,y,5,7)
      end,
      c=5,
     },
    })

    -- on hit handling
    for skill in all(_a.passiveskills) do
     if skill.onhit then
      skill.onhit(_a)
     end
    end
    attack.removeme=attack.tar_c <= 0
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
   if enemy != other and enemy != avatar and other != avatar and
      dist(enemy.x,enemy.y,other.x,other.y) <
        enemy.hh + other.hh then
    add(enemy.toocloseto,other)
    add(other.toocloseto,enemy)
   end
  end
 end

 -- actor movement check against props
 for _a in all(actors) do
  local _dx,_dy=_a.dx,_a.dy
  for _p in all(props) do
   local _tmp=clone(_a)
   _tmp.hh=1
   _tmp.hw=1
   _dx,_dy=collideaabbs(isaabbscolliding,_tmp,_p,_dx,_dy)
   _a.wallcollisiondx,_a.wallcollisiondy=nil
   if _dx != _a.dx or _dy != _a.dy then
    _a.wallcollisiondx,_a.wallcollisiondy=_dx,_dy
   end
  end
  _a.x+=_dx
  _a.y+=_dy
  if boss then
   _a.x=mid(mapw-128,_a.x,mapw)
  else
   _a.x=mid(0,_a.x,mapw)
  end
  _a.y=mid(10,_a.y,128)
  _a.dx,_a.dy=0,0
 end

 -- update camera
 if boss then
  camx=mapw-128
 else
  camx=mid(0,avatar.x-64,mapw-128)
 end
 camera(camx)

 -- update attacks
 for _a in all(attacks) do
  if _a.state_c and not _a.removeme then
   _a.state_c-=1
   _a.removeme=_a.state_c <= 0
  end

  _a.x+=(_a.dx or 0)
  _a.y+=(_a.dy or 0)

  if _a.x > mapw or _a.x < 0 or
     _a.y > 128 or _a.y < 0 then
   _a.removeme=true
  end

  for _p in all(props) do
   if _a.dx and isaabbscolliding(_a,_p) then
    -- hit flash
    local x,y=_a.x+_a.hw+_a.dx/2,_a.y+_a.dy/2-_a.hh
    add(vfxs,{
     {
      draw=function(f)
       circfill(x,y,2,_a.dmgfx_col)
      end,
      c=4,
     },
     {
      draw=function(f)
       circfill(x,y,3,7)
      end,
      c=5,
     },
    })
    _a.removeme=true
   end
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
  _a.curframe+=(stateframes.animspd or 0.25)*_a.spd
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
  vfx.removeme=#vfx <= 0
 end

 -- update pemitters
 for _p in all(pemitters) do
  _p.c,_p.particles=_p.c or _p.prate[1],_p.particles or {}
  _p.c-=1
  if _p.c <= 0 then
   local x,y,poffsets,pdy=
     _p.follow.x,_p.follow.y,_p.poffsets,_p.dy or pfn'-0.3,0,'

   x+=poffsets[1]+rnd(poffsets[3]+abs(poffsets[1]))
   y+=poffsets[2]+rnd(poffsets[4]+abs(poffsets[2]))

   local dy=pdy[1]+rnd(pdy[2]+abs(pdy[1]))

   add(_p.particles,{
    c=_p.plife[1]+rnd(_p.plife[2]),
    x=x,y=y,dy=dy,
   })

   _p.c=_p.prate[1]+rnd(_p.prate[2])
  end

  _p.life-=1
  _p.removeme=_p.life <= 0

  -- update this pemitters particles
  for par in all(_p.particles) do
   par.c-=1
   par.col=par.c <= _p.plife[1] and _p.pcol2 or _p.pcol1
   par.y+=par.dy
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
  music(0xffff)
  deathts=tick
  _sfx'2'
 end
end


function dungeondraw()
 cls(5)
 palt(0,false)
 palt(11,true)

 local spr1,offset=176+theme*16,0

 -- draw interactables
 if islevelcleared then
  for _i in all(interactables) do
   spr(_i.sprite,_i.x-_i.hw,_i.y-_i.hh)
  end
 end

 -- draw attacks
 for _att in all(attacks) do
  if _att.frame then
   local _f=_att.frame
   if _att.col then
    pal(7,_att.col,0)
   end
   sspr(_f[1],_f[2],_f[3],_f[4],_att.x+_f[5],_att.y+_f[6],_f[3],_f[4])
   pal(7,7,0)
  end

  -- rect(
  --  _att.x-_att.hw,
  --  _att.y-_att.hh,
  --  _att.x+_att.hw,
  --  _att.y+_att.hh,
  --  15)
 end

 -- draw actors, draw props
 local _drawables=concat({actors,props})
 sortony(_drawables)

 for _,_d in pairs(_drawables) do
  local _a=_d
  local state=_a.state
  local _curframe=flr(_a.curframe)
  local f=_a[state][_curframe]

  for k,v in pairs(_a.cols or {}) do
   pal(k,v,0)
  end

  -- draw dmg overlay color
  if _a.dmgfx_c % 8 >= 4 then
   for i=1,15 do
    pal(i,_a.dmgfx_col,0)
   end
  end

  -- draw weapon
  if _a == avatar and avatar.items.weapon then
   item=avatar.items.weapon
   local f=item[state][_curframe]
   pal(6,item.col,0)
   sspr(
    f[1],f[2],
    f[3],f[4],
    _a.flipx and _a.x-f[3]-f[5] or _a.x+f[5],
    _a.y+f[6],
    f[3],f[4],_a.flipx)
  end

  sspr(
   f[1],f[2],
   f[3],f[4],
   _a.flipx and _a.x-f[3]-f[5] or _a.x+f[5],
   _a.y+f[6],
   f[3],f[4],_a.flipx)

  -- draw offhand
  if _a == avatar and avatar.items.offhand then
   item=avatar.items.offhand
   local f=item[state][min(flr(item.curframe),#item[state])]
   pal(6,item.col,0)
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
  end

  -- reset colors
  for i=1,15 do
   pal(i,i,0)
  end

  -- rect(
  --  _a.x-_a.hw,
  --  _a.y-_a.hh+_a.yoff,
  --  _a.x+_a.hw,
  --  _a.y+_a.hh+_a.yoff,
  --  13)

  -- circfill(_a.x,_a.y,1,14)
 end

 -- draw vfx
 for vfx in all(vfxs) do
  local f=vfx[1]
  if f.draw then
   f.draw(f)
  else
   pal(7,f.col or 7,0)
   sspr(
    f[1],f[2],
    f[3],f[4],
    f[5],f[6],
    f[3],f[4],f.flipx)
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
 for _i=0,avatar.hp-1 do
  sspr(17,35,7,6,camx+2+_i*8,2)
  -- offset=(_i+1)*6-1
 end

 for _i=0,avatar.startarmor-1 do
  x=_i >= avatar.armor and 53 or 48
  sspr(x,40,5,5,camx+121-offset-_i*6,1)
 end

 if avatar.hp <= 0 then
  print('a deadly blow',40,60,8)
  -- if tick-deathts > 150 then
  --  print('(you\'ve lost your inventory)',12,72,8)
  --  print('press \x8e to continue',26,80,8)
  -- end
 end

 -- draw boss hp
 if boss then
  local hw=boss.hp*6/2
  rectfill(camx+64-hw,123,camx+64+hw,125,8)
  print(boss.name,camx+64-#boss.name*2,122,15)
 else
  local pos=min(120*(avatar.x/(mapw-64)),123)
  rectfill(camx+3,123,camx+123,125,1)
  rectfill(camx+3,123,camx+pos,125,12)
  print(mapname,camx+64-#mapname*2,122,7)
 end

end




-- equip scene

function equipinit()
 _update60,
 _draw,
 inventorycur,
 equippedcur,
 availableskillscur,
 sectioncur,
 spdfactornr,
 equipped,
 availableskills=
   equipupdate,equipdraw,1,1,1,4,0,{},{}
end

function equipupdate()
 btnp0,btnp1,btnp4,btnp5,
 avatar.startarmor,
 avatar.spdfactor,
 avatar.att_spd_dec,
 avatar_items,
 spdfactornr,
 equipped,
 avatar.passiveskills,
 availableskills=
  btnp(0),btnp(1),btnp(4),btnp(5),
  0,1,0,avatar.items,0,{},{},{}

  -- init equipped items
 for _,item in pairs(avatar_items) do
  add(equipped,item)
  if item.armor then
   avatar.startarmor+=item.armor
  end
  if item.spdfactor then
   avatar.spdfactor+=item.spdfactor
   spdfactornr+=-flr(item.spdfactor*0xff9c)
  end
  avatar.att_spd_dec+=item.att_spd_dec
 end

 -- init available active skills
 for item in all(equipped) do
  if item.prefix and item.prefix.skill and
     item.prefix.skill.perform then
   add(availableskills,item.prefix.skill)
  end
  if item.suffix and item.suffix.skill and
     item.suffix.skill.perform then
   add(availableskills,item.suffix.skill)
  end
 end

 -- init available passive skills
 for item in all(equipped) do
  local _prefix,_suffix=item.prefix,item.suffix
  if _prefix == amuletprefix[1] or
     _prefix and _prefix.skill and
     (not _prefix.skill.perform) then
   add(availableskills,_prefix.skill)
   add(avatar.passiveskills,_prefix.skill)
  end
  if _suffix and _suffix.skill and
     (not _suffix.skill.perform) then
   add(availableskills,_suffix.skill)
   add(avatar.passiveskills,_suffix.skill)
  end
 end

 -- changing sections
 _d=btnp(2) and 1 or btnp(3) and 0xffff or nil
 if _d then
  sectioncur=mid(1,sectioncur-_d,4)
  _sfx'7'
 end

 -- init inventory
 for item in all(avatar.inventory) do
  if avatar_items[item.slot] == item then
   del(avatar.inventory,item)
  end
 end

 -- inventory
 inventoryn=#avatar.inventory
 if sectioncur == 1 then
  _d=btnp0 and 1 or btnp1 and 0xffff or 0
  inventorycur=mid(1,inventorycur-_d,inventoryn)
  if _d != 0 then
   sellcur=nil
   _sfx'7'
  end

  if inventoryn > 0 then
   if btnp4 then
    selecteditem,avatar.skill1,avatar.skill2=avatar.inventory[inventorycur]

    if avatar_items[selecteditem.slot] then
     add(avatar.inventory,avatar_items[selecteditem.slot])
    end
    avatar_items[selecteditem.slot]=selecteditem

    if selecteditem.twohand then
     add(avatar.inventory,avatar_items.offhand)
     avatar_items.offhand=nil
    end

    if selecteditem.slot == 'offhand' and
       avatar_items.weapon and
       avatar_items.weapon.twohand then
     add(avatar.inventory,avatar_items.weapon)
     avatar_items.weapon=nil
    end
    inventorycur=mid(1,inventorycur,inventoryn-1)
    _sfx'8'

   elseif btnp5 then
    if sellcur then
     del(avatar.inventory,avatar.inventory[sellcur])
     sellcur,avatar.skill1,avatar.skill2=nil
     inventorycur=min(inventorycur,inventoryn-1)
     _sfx'29'
    else
     sellcur=inventorycur
    end
   end
  end

 -- equipped
 elseif sectioncur == 2 then
  sellcur=nil
  _d=btnp0 and 1 or btnp1 and 0xffff or nil
  if _d then
   equippedcur=mid(1,equippedcur-_d,#slots)
   _sfx'7'
  end

  if btnp4 or btnp5 then
   if #avatar.inventory >= 10 then
    _sfx'6'
   else
    local selecteditem=avatar_items[slots[equippedcur]]
    if selecteditem then
     avatar_items[selecteditem.slot],avatar.skill1,avatar.skill2=nil
     add(avatar.inventory,selecteditem)
    end
    _sfx'8'
   end
  end

 -- available skills
 elseif sectioncur == 3 then
  _d=btnp0 and 1 or btnp1 and 0xffff or nil
  if _d then
   availableskillscur=mid(1,availableskillscur-_d,#availableskills)
   _sfx'7'
  end

  local selectedskill=availableskills[availableskillscur]
  if selectedskill then
   if btnp4 then
    if selectedskill.perform then
     avatar.skill1=selectedskill
     if avatar.skill2 == avatar.skill1 then
      avatar.skill2=nil
     end
     _sfx'8'
    else
     _sfx'6'
    end
   end
   if btnp5 then
    if selectedskill.perform then
     avatar.skill2=selectedskill
     if avatar.skill1 == avatar.skill2 then
      avatar.skill1=nil
     end
     _sfx'8'
    else
     _sfx'6'
    end
   end
  end

 -- exit
 elseif sectioncur == 4 then
  if btnp4 then
   if avatar.skill1 or avatar.skill2 then
    for k,v in pairs(slots) do
     if avatar_items[v] then
      saveitem(k,avatar_items[v].class,has(
          itemclasses[avatar_items[v].class].prefix or
          prefix,avatar_items[v].prefix),
        has(suffix,avatar_items[v].suffix))
     else
      saveitem(k,0,0,0)
     end
    end
    
    if theme then
     _update60,_draw=dungeonupdate,dungeondraw
    else
     dungeoninit()
    end
   else
    sectioncur=3
    _sfx'6'
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
 local offsetx,i=0,1
 print('saddlebags',4,8,sectioncur == 1 and 10 or 4)
 for item in all(avatar.inventory) do
  spr(item.sprite,6+offsetx,17)
  if sectioncur == 1 and i == inventorycur then
   rect(4+offsetx,15,15+offsetx,26,10)
   if i == sellcur then
    sspr(58,40,5,5,offsetx+4,15)
   end
   print(item.name,4,29,7)
  end
  offsetx+=12
  i+=1
 end

 -- draw equipped section
 offsetx,i=0,1
 print('equipped',4,43,sectioncur == 2 and 10 or 4)
 print('+'..spdfactornr..'% spd',41,43,13)
 print(avatar.att_spd_dec..' -af',79,43,3)
 for _i=0,avatar.startarmor-1 do
  sspr(48,40,5,5,121-_i*6,43)
 end
 for k,v in pairs(slots) do
  local item=avatar.items[v]
  if item then
   spr(item.sprite,6+offsetx,52)
  else
   spr(k,6+offsetx,52)
  end
  if sectioncur == 2 and k == equippedcur then
   rect(4+offsetx,50,15+offsetx,61,10)
   if item then
    print(item.name,4,64,7)
   end
  end
  offsetx+=12
 end

 -- draw availableskills section
 offsetx,i=0,1
 print('skills',4,79,sectioncur == 3 and 10 or 4)
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
 print('exit',57,120,sectioncur == 4 and 10 or 4)
end

function splash()
 music()
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

-- _init=splash
_init=function()
 dungeoninit()
end

__gfx__
00000000b00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000222222220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000244444420bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000222ff2220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000244444420bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000244444420bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000222222220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b00bbbb0b00bbbb00bbbbbbb0bbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0ff0bb0f0ff0bb0ff0bbbb0050bb0ff0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0ff0bb0f0ff0bb0ff0bbb0ff50bb0ff0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0ff0bb0f0ff0bb0ff0bbb0ff50bb0ff0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0550bb050550bb0550bbb0ff50000550bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0550b0550550b05550bbb0550bf555550bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
055005050550050550bb05550b00555500bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
05500f0505500f0550b050550bbb05505fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0f50bb0d0f50bb0d0d00f0550bb0dddd00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0dd0bb0d0dd0bb0d0d0bb055d002d0020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0dd0b0200dd0b020020bb0ddd0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0220bbbb0220bbbbbbbbb0d020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0e0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb00bbbbbb00bbbbbb0200bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbb080bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb060bbbbb060bbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbb0e0bbbbbbb040bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0b060bb00b060bb000009900000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0e0bbbbbbb080bbbbbbb040bbbbbbbb0bbbbbbbbbbbbbbbbbbbbb
9060bb069060bb06666699666660bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb080bbbbbbb040bbbbbbb040bbbbbbb0e0bbbbbbbbbbbbbbbbbbbb
590bbbb0590bbbb000009900000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb040bb0000b040bb0000b040bbbbbbb080bbbbbbbbbbbbbbbbbbbb
0090bbbb0090bbbbbbbb00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000b040b022230040b022230040bb0000b040bbbbbbbbbbbbbbbbbbbb
bb0bbbbbbb0bbbbbbbbbb7777bbb000bbbbbb000bbbbbb000000bbbbbb000bbbbbbbb02223004002022330400202233040b022230040bbbbbbbbbbbbbbbbbbbb
bbb77777bbb77777777bbbbbbbb0330bbb000330bbb00022230000bbb03300bbbbbb0202233040000223004000022303400202233040bbbbbbbbbbbbbbbbbbbb
b77bbb77b77bbb7777777bbbbbb03330b02003330b020b000003300b003330bbbbbb0002230040bb0223004003022300400002230040bbbbbbbbbbbbbbbbbbbb
7bbbbbbb7bbbbbbb777777bbbbb0330b020b0330b020bbbbbb03330033330000000bbb02230040bb02220340b022220040bb02230040bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb777777bbb03330020bb0330020bbbbbbb0330bb003303322220bb02220340bb02220040bb02220040bb02220040bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbb77777bb03033030bbb033030bbbbbbb03330bbb0330000000bb032220040bb02320040bb02220bbbbb02220340bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb77777b0004400bbbb04400bbbbbbb030330bbb04440bbbbbbbb02222040bb02220040bb02220bbbbb02232040bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb77777bbb04040bbbb0440bbbbbbbbb00440bb0330030bbbbbb022222040bb02220bbbbb02220bbbb022222040bbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb77777bb030030bbbb0330bbbbbbbbbb04440bbbbbbbbbbbbbbbb000bbbbbbbbb000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb77777b00b00bbbbbbbbbbbbbbbbbb040030bbbbbbbbbbbbbb000520bbbbbb000520bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb777770880880bbbbbbbbbbbbbbbbb03000bbbbbbbbbbbbbb06650020bbbb06605020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb777770888880bbbbbbbbbbbbb000bbbbbbbbbb000bbbbbbb06500020bbbb06605020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb77777b08880bbbbbbbbbbbb000520bbbbbbb000520bbbbb0056000200bb000605020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbb7bb080bbbbbbbbbbbb06605020bbbbb06605020bbb065d002260d0066d005060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbb00bbbbbb0bbbbbbbbbbbbb06650020bbbbb06650020bbbb0056000200bb006605020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb00bbbbbb00bbbbbb0660bbbbb777bbbbbb77bbbb065002000bbbb065002000bbb0d500020bbbb0d005020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb0660bbbb0660bbbb0dd60bbb7777777bbb7777b06d06dd602d0b06d06dd602d0bb06650020bbbb06605020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b06d60bbb06d60bbb0d6d60b77777777777b7777bb0665002000bbb0665002000bbb0d00520bbbbb0d00520bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0ddd60bb0ddd60bb000dd60bbb7777777bbb77bbb0d050020bbbbb0d050020bbbbb060d00bbbbbb060d00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
06ddd60b06ddd60b00660d60bbbbb777bbbbbbbbbb06605020bbbbb06605020bbbbb06060bbbbbbb06060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0d66dd600d66dd600dd60060bbbbbbbbbbbbbbbbbb0d00520bbbbbb06d0520bbbbbb06060bbbbbbb06060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0ddddd600ddddd600ddd60d0bbbbbbbbbbbbbbbbbb060b00bbbbbb0606000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b0b0bb0bb0b0bb0bbbbbbbbbbbbbbbbbbbbbbbbbbb060bbbbbbbb060060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0202002002020020bbbbbbbbbbbbbbbbbbbbbbbbbb060bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0220b0200220b020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
020bb020020bb020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b020020bb020020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b02020bbb02020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b02020bbb02020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb020bbbbb020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb0200bbbb0200bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb02220bbb02220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb0200bbbb0200bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb020bbbbb020bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb0220bbbb0220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb0220bbbb0220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb0220bbbb0220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b022220bb022220bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
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
010a00001d1322113024130291302d1302f1303013030130001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000
010b00001a7321a7301a7201a725000000000000000007001c7321c7321c7201c7201c72500000000000000019740197401973219732197321973219732197201972500700000000000000000000000000000000
010800001a85000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000025040250502604026050280402805029040290502b0502b0402d0402d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001d1322113024130291302d130001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000
000300000a5500c5500c5500f55013550185501b5501d5501f550225502455029550295503055020500265002a500345003d50000500005000050000500005000050000500005000050000500005000050000500
012c00001a7301a7321a7351c91000000007001d7351a7301c7321c7321c73500700157321573505910000001a7301a7321a7350000000000007001d7321a7301c7321c735000001d73015732157350000013735
012c000013730137351800015734167311673518734187351a7341a7321a735000000d91200000000000000013730137351800015734167311673518734187351a7341a7351c7341c73019732197321973500000
012c00000e734021350e734021350e734021350e7340213509734091350973409135097340913509734011350e734021350e734021350e734021350e734021350973409135097340913509734091350973409135
012c00000773407135077340713507734071350773407135027340213502734021350273402135027340513507734071350773407135077340713507734071350e734021350e7340213509734091350973401135
01c800080e7740d77511774107750e7740d7750a7740b775007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000704
014000200e7340e7300e735000000d7340d7300d7350000011734117301173500000107341073010735000000e7340e7300e735000000d7340d7320d735000000a7340a7300a735000000b7340b7300b73500500
01320020000000000000000000000e0530010000000000000000000000000000e0530e053000000000000000000000000000500000000e053000000000000000000000000000000000000e053000000000000000
010200002e5302d5302c5302a5302753024530225301f5301b5301753011530085300053000500005000050002500345003d50000500005000050000500005000050000500005000050000500005000050000500
000600002d520365202b5202e5000a500165202b5002b500245002450024500245002450018500185001850016500185000450007500045000050000500005000050000500005000050000500005000050000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b6202a6202962033620286202762031620256202463022630226301f6301b630196401464012640106400a6400563003630016300063000620006200062000620006300163002630036300463005620
000200002f62027620236202c6201a62021620146301c6300d6300b6300a6301c63009630006401a6401a640006401a64000630006301d6200165001650016500065000600006000060000600006000060000600
010e00001361500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010900000474404740047400474104751047530374403740037400374103751037530274402740027400274102751027430174401741017510175101751017510176101761017610177300000000000000000000
01090000137441374013740137411375113753127441274012740127411275112753117441174011740117411175111743107441074110741107411075110751107611076110761107730c000000000000000000
0115000002750057450275009745027500c74502750057450275005745027400774502750097450274005745097500c7450975010745097500c7450975004745097400c745097501074509750137400975515755
011500000e752117450e750157450e750187450e750117450e752117450e740137450e750157450e740117451575018745157501c745157501874515750107451574018745157521c745157501f7451575521754
0115000001760047550176008755017600d75501760047550176004755017600875501760097550176004755087600d7550876010755087600d75508765047600876519740145450d54510555147401074503755
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
016000000e5300e5350e714115341053010535107141353411530115351171415534135301652116522165250e5300e5350e7141153410530105350f7140f5240e5200e5250c5000d5340e5300e5220e52500515
01c00010027350000004735000000573500000077350a735027350000004735000000273501735027350000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012400000e755020550e755000000e755020550e755000000d755010550d755000000d755010550d755000000e755020550e755000000e755020550e755000001174505055117550000011755040551075500055
012400000e755020550e755000050e755020550e7550475511755050551175500000147450805514755000001374507055137550000013745070551375509755167450a055167550000014745080551175505745
012400000e755020550e755000000e755020550e755000000d755010550d755000000d745010550d755000000e745020550e745000000e735020350e725000000e72600000017160000001715000000171300000
__music__
03 1a6e4344
00 23244344
01 25264344
00 25264344
02 27674344
03 1a6e4344
03 1a1c4344
00 64644344
02 6c424344
00 65674344
00 114b4344
01 3c584344
00 3c584344
00 3d584344
02 3e6e4344
00 67674344
00 706e4344
00 706e4344
00 6f6c4344
00 706e4344
00 114b4344
03 38394344
00 6e6e4344
00 6c6e4344
00 706e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 114b4344
01 16184344
02 17194344
00 6c6e4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 114b4344
01 2d6e4344
00 2e6e4344
02 2c6e4344

