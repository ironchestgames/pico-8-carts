pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 1 hp hero
-- by ironchest games

cartdata'ironchestgames_1hphero_dev1'

function _sfx(_s)
 sfx(tonum(_s))
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

function flrrnd(_n)
 return flr(rnd(_n))
end

-- note: last char needs to be ','
-- function pfn(s)
--  local t,_s={},''
--  while #s > 0 do
--   local d=sub(s,1,1)
--   if d != ',' then
--    _s=_s..d
--   else
--    add(t,tonum(_s))
--    _s=''
--   end
--   s=sub(s,2)
--  end
--  return t
-- end

-- s2t usage:
-- t=s2t'1;2;3;4;5;6;7;hej pa dig din gamle gries;'
-- t=s2t'.x;1;.y;2;'
function s2t(s)
 local _t,_i,_s,_d={},1,''
 repeat
  _d,s=sub(s,1,1),sub(s,2)
  if _d != ';' then
   _s=_s.._d
  else
   if sub(_s,1,1) != '.' then
    _s=tonum(_s) or _s
   end
   _t[_i]=_s
   if (_s == '') _t[_i]=nil
   _i+=1
   _s=''
  end
 until #s == 0
 for _i=2,#_t,2 do
  local _tib=_t[_i-1]
  if sub(tostr(_tib),1,1) == '.' then
   _s=sub(_tib,2)
   _s=tonum(_s) or _s
   _t[_s],_t[_i-1],_t[_i]=_t[_i]
  end
 end
 return _t
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
   aabb.removeme=true
  elseif walls[mapy][mapx] == 1 and
     isaabbscolliding(aabb,wallaabb) then
   return wallaabb
  end
 end
end

function haslos(_x1,_y1,_x2,_y2)
 local dx,dy,x,y,xinc,yinc=
  abs(_x2-_x1),abs(_y2-_y1),_x1,_y1,sgn(_x2-_x1),sgn(_y2-_y1)
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

function aframes(_fs)
 local t,j={},1
 for i=0,1,0.125 do
  t[i]=s2t(_fs[j])
  j+=1
 end
 return t
end

meleevfxframes=aframes{
 '0;20;4;7;-1;-5;', -- right
 '8;20;6;4;-3;-2;', -- right/up
 '20;20;9;3;-3;-1;', -- up
 '14;20;6;4;-2;-2;', -- up/left
 '4;20;4;7;-2;-5;', -- left
 '29;20;4;7;-3;-6;', -- left/down
 '20;23;9;3;-4;-2;', -- down
 '33;20;4;7;0;-6;', -- down/right
 '0;20;4;7;-1;-5;' -- right (wrapped)
}

bowvfxframes=aframes{
 '0;27;6;7;-3;-5;', -- right
 '17;32;7;7;-4;-3;', -- right/up
 '10;31;7;6;-3;-3;', -- up
 '34;32;7;7;-3;-3;', -- up/left
 '4;27;6;7;-2;-5;', -- left
 '22;27;7;7;-2;-5;', -- left/down
 '10;27;7;6;-3;-4;', -- down
 '29;27;7;7;-4;-4;', -- down/right
 '0;27;6;7;-3;-5;' -- right (wrapped)
}

arrowframes=aframes{
 '50;20;2;1;-1;-0.5;', -- right
 '52;20;2;2;-1;-1;', -- right/up
 '54;20;1;2;-0.5;-1;', -- up
 '55;20;2;2;-1;-1;', -- up/left
 '50;20;2;1;-1;-0.5;', -- left
 '52;20;2;2;-1;-1;', -- left/down
 '54;20;1;2;-0.5;-1;', -- down
 '55;20;2;2;-1;-1;', -- down/right
 '50;20;2;1;-1;-0.5;' -- right (wrapped)
}

function getvfxframei(a)
 return min(flr((a+0.0625)*8)/8,1)
end

-- effects
pemdef=s2t'-0.3;0;'

function burningeffect(_a)
 if _a.effect.c == nil then
  _a.effect.c=0
  add(pemitters,{
   follow=_a,
   life=_a.state_c,
   prate=s2t'2;4;',
   plife=s2t'15;25;',
   poffsets=s2t'-2;0.5;2;0.5;',
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
  attackcol,typ,recovertime,dmg)
 return {
  sprite=12,
  desc='sword attack',
  preprfm=15,
  postprfm=28,
  perform=function(_a,skill)
   local x,y=getskillxy(_a)

   add(attacks,{
    isavatar=true,
    x=x,y=y,
    hw=2,hh=2,
    state_c=1,
    typ=typ,
    recovertime=recovertime or 0,
    knocka=_a.a,
    tar_c=1000,
    dmg=dmg,
   })

   local frame=clone(meleevfxframes[getvfxframei(_a.a)])
   frame.c,frame.col=15,attackcol
   frame[5]+=x
   frame[6]+=y
   add(vfxs,{frame})

   _sfx'4'
  end
 }
end

function bowattackskillfactory(
  preprfm,attackcol,arrowcol,typ,recovertime)
 return {
  sprite=13,
  desc='bow attack',
  preprfm=preprfm,
  postprfm=6,
  perform=function(_a,skill)
   local x,y=getskillxy(_a)

   add(attacks,{
    isavatar=true,
    x=x-0.5,y=y-0.5,
    hw=1,hh=1,
    state_c=1000,
    dx=cos(_a.a)*1.6,
    dy=sin(_a.a)*1.6,
    typ=typ,
    recovertime=recovertime,
    frame=clone(arrowframes[_a.a]),
    col=arrowcol,
   })

   local frame=clone(bowvfxframes[getvfxframei(_a.a)])
   frame.c,frame.col=6,attackcol
   frame[5]+=x
   frame[6]+=y
   add(vfxs,{frame})

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
    prate=s2t'2;4;',
    plife=s2t'15;25;',
    poffsets=s2t'-2;0.5;2;0.5;',
    pcol1=castpemcol1,pcol2=castpemcol2
   })
   _sfx'9'
  end,
  perform=function(_a)
   local x,y=getskillxy(_a)

   local attack={
    isavatar=_a.isavatar,
    x=x,y=y,
    hw=1,hh=1,
    state_c=1000,
    dx=cos(_a.a)*1.2,
    dy=sin(_a.a)*1.2,
    typ=typ,
    recovertime=120,
    frame=s2t'47;20;3;3;-0.5;-0.5;',
    col=attackcol,
   }
   add(attacks,attack)

   add(pemitters,{
    follow=attack,
    life=1000,
    prate=s2t'0;1;',
    plife=s2t'3;5;',
    poffsets=s2t'-1;-1;1;1;',
    dy=s2t'0;0;',
    pcol1=boltpemcol1,pcol2=boltpemcol2
   })
   _sfx'32'
  end
 }
end

-- actors
function actfact(_a)
 _a.state,_a.state_c,_a.curframe,_a.dx,_a.dy,
 _a.runspd,_a.dmgfx_c,_a.comfydist,_a.toocloseto,_a.a,_a.hh
   ='idling',0,1,0,0,_a.spd,0,_a.comfydist or 1,{},0,2
 return _a
end

function performenemymelee(_a)
 _a.a=getvfxframei(atan2(_a.tarx-_a.x,_a.tary-_a.y))
 add(attacks,{
  x=_a.x+cos(_a.a)*4,
  y=_a.y+sin(_a.a)*4,
  hw=att_siz or 2,
  hh=att_siz or 2,
  state_c=1,
  typ=_a.att_typ or 'knockback',
  recovertime=_a.att_recovertime,
  knocka=_a.a,
  tar_c=1000,
 })
 local f=clone(meleevfxframes[_a.a])
 f.c,f.col=10,_a.att_col or 7
 _x,_y=getskillxy(_a)
 f[5]+=_x
 f[6]+=_y
 add(vfxs,{f})
 _sfx'4'
end

function performenemybow(_a)
 _a.a=getvfxframei(atan2(_a.tarx-_a.x,_a.tary-_a.y))
 add(attacks,{
  x=_a.x-0.5,y=_a.y-0.5,
  hw=1,hh=1,
  state_c=1000,
  dx=cos(_a.a)*1.6,dy=sin(_a.a)*1.6,
  frame=clone(arrowframes[_a.a]),
  col=2
 })
 _sfx'5'
end

-- enemy factories
function newmeleetroll(x,y)
 return actfact{
  x=x,y=y,
  hw=1.5,
  spd=0.45,
  hp=2,
  att_preprfm=50,
  att_postprfm=20,
  prfmatt=performenemymelee,
  idling={s2t'40;91;4;5;-2;-3;'},
  moving={animspd=0.18,s2t'40;91;4;5;-2;-3;',s2t'44;91;4;5;-2;-3;'},
  attacking={animspd=0,s2t'48;91;4;5;-2;-3;',s2t'51;91;6;5;-3;-3;'},
  recovering={s2t'40;91;4;5;-2;-3;'}
 }
end

function casterfactory(_hp,_cols,_idlef,_attackf,_boltskill)
 return function(x,y)
  return actfact{
   x=x,y=y,
   hw=1.5,
   spd=0.25*_hp,
   hp=_hp,
   att_preprfm=100,
   att_postprfm=20,
   att_range=60,
   cols=_cols,
   prfmatt=function(_a)
    _a.a=atan2(_a.tarx-_a.x,_a.tary-_a.y)
    _boltskill.perform(_a)
   end,
   comfydist=30,
   idling={_idlef},
   moving={animspd=0.18,_idlef},
   attacking={animspd=0,_attackf,_idlef},
   recovering={_idlef},
   onpreprfm=_boltskill.startpemitter
  }
 end
end

newtrollcaster=casterfactory(
 1,s2t'3;4;2;5;9;',s2t'41;32;4;7;-2;-4.5;',s2t'45;32;4;7;-2;-4.5;',
 boltskillfactory('fire',14,8,14,14,8))

newdemoncaster=casterfactory(
 3,s2t'8;13;5;6;12;',s2t'41;32;4;8;-2;-5.5;',s2t'45;32;4;8;-2;-5.5;',
 boltskillfactory('ice',7,12,12,12,13))

function newgianttroll(x,y)
 boss=actfact{
  name='giant troll',
  x=x,y=y,
  hw=1.5,hh=3,
  isbig=true,
  spd=0.7,
  hp=7,
  att_preprfm=40,
  att_postprfm=30,
  prfmatt=performenemymelee,
  idling={s2t'36;25;7;7;-4;-4;'},
  moving={animspd=0.18,s2t'43;25;7;7;-4;-4;',s2t'50;25;7;7;-4;-4;'},
  attacking={animspd=0,s2t'57;25;7;7;-4;-4;',s2t'64;25;8;7;-4;-4;'},
  recovering={s2t'72;25;7;7;-4;-4;'}
 }
 return boss
end

function newmeleeskele(x,y)
 return actfact{
  x=x,y=y,
  hw=1.5,
  spd=0.5,
  hp=3,
  att_preprfm=40,
  att_postprfm=10,
  prfmatt=performenemymelee,
  idling={s2t'0;15;4;5;-2;-3;'},
  moving={animspd=0.18,s2t'0;15;4;5;-2;-3;',s2t'4;15;4;5;-2;-3;'},
  attacking={animspd=0,s2t'8;15;4;5;-2;-3;',s2t'11;15;6;5;-3;-3;'},
  recovering={s2t'0;15;4;5;-2;-3;'}
 }
end

function batfactory(_cols,_att_col,_att_typ,_att_recovertime)
 return function(x,y)
  return actfact{
   isghost=true,
   x=x,y=y,
   hw=1.5,
   spd=0.75,
   hp=1,
   att_preprfm=30,
   att_postprfm=0,
   att_col=_att_col,
   att_typ=_att_typ,
   att_recovertime=_att_recovertime,
   cols=_cols,
   prfmatt=performenemymelee,
   idling={s2t'36;15;3;3;-1.5;-1.5;'},
   moving={animspd=0.21,s2t'36;15;3;3;-1.5;-1.5;',s2t'39;15;3;3;-1.5;-1.5;'},
   attacking={animspd=0.32,s2t'36;15;3;3;-1.5;-1.5;',s2t'39;15;3;3;-1.5;-1.5;'},
   recovering={s2t'36;15;3;3;-1.5;-1.5;'}
  }
 end
end

newbatenemy=batfactory()
newfirebatenemy=batfactory(s2t'0;0;0;0;8;',14,'fire',120)

function newvampireboss(x,y)
 boss=actfact{
  name='samael',
  isghost=true,
  x=x,y=y,
  hw=1.5,
  spd=0.75,
  hp=8,
  att_preprfm=20,
  att_postprfm=75,
  att_siz=2,
  prfmatt=function(_a)
   _a.a=atan2(_a.tarx-_a.x,_a.tary-_a.y)
   add(attacks,{
    x=_a.x+cos(_a.a)*4,
    y=_a.y+sin(_a.a)*4,
    hw=2,hh=2,
    state_c=1,
    dmg=2
   })
   f=s2t'92;91;4;3;-2;-1.5;'
   f.c=4
   _x,_y=getskillxy(_a)
   f[5]+=_x
   f[6]+=_y
   add(vfxs,{f})
   _sfx'4'
  end,
  idling={s2t'82;91;5;5;-3;-3;'},
  moving={animspd=0.21,s2t'96;91;3;3;-1.5;-1.5;',s2t'99;91;3;3;-1.5;-1.5;'},
  attacking={animspd=0.3,s2t'87;91;5;5;-3;-3;',s2t'82;91;5;5;-3;-3;'},
  recovering={s2t'82;91;5;5;-3;-3;'}
 }
 return boss
end

function newbowskele(x,y)
 return actfact{
  x=x,y=y,
  hw=1.5,
  spd=0.5,
  hp=2,
  att_preprfm=60,
  att_postprfm=4,
  att_range=40,
  prfmatt=performenemybow,
  comfydist=20,
  idling={s2t'18;15;4;5;-2;-3;'},
  moving={animspd=0.18,s2t'18;15;4;5;-2;-3;',s2t'22;15;4;5;-2;-3;'},
  attacking={animspd=0,s2t'26;15;4;5;-2;-3;',s2t'31;15;4;5;-2;-3;'},
  recovering={s2t'18;15;4;5;-2;-3;'}
 }
end

function newskeleking(x,y)

 function setupmelee(_a)
  _a.att_range,
  _a.att_preprfm,
  _a.att_postprfm,
  _a.prfmatt,
  _a.afterpostprfm,
  _a.attacking,
  _a.onpreprfm,
  _a.nolos
   =7,30,60,performmelee,setupmagic,
   {animspd=0,s2t'0;40;15;18;-7;-13;',s2t'0;58;20;18;-10;-13;'}
 end

 function performmelee(_a)
  add(attacks,{
   throughwalls=true,
   x=_a.x+cos(_a.a)*2,y=_a.y-3,
   hw=7,hh=8,
   state_c=2,
   typ='knockback',
   knocka=_a.a,
  })
  _sfx'4'
 end

 function setupmagic(_a)
  _a.att_range,
  _a.att_preprfm,
  _a.att_postprfm,
  _a.prfmatt,
  _a.afterpostprfm,
  _a.attacking,
  _a.onpreprfm,
  _a.nolos
    =60,110,0,performmagic,setupmelee,{
      animspd=0,
      s2t'24;58;15;18;-7;-13;',
      s2t'24;58;15;18;-7;-13;',
     },magicpreprfm,true
 end

 function magicpreprfm(_a)
  _a.att_x,_a.att_y=findflr(_a.x,_a.y)
  add(pemitters,{
   follow={x=_a.att_x,y=_a.att_y},
   life=140,
   prate=s2t'1;2;',
   plife=s2t'10;15;',
   poffsets=s2t'-2;0.5;1;0.5;',
   pcol1=11,pcol2=3
  })
  _sfx'9'
 end

 function performmagic(_a)
  local _e=newmeleeskele(_a.att_x,_a.att_y)
  _e.state,_e.laststate,_e.state_c='recovering','recovering',50
  add(actors,_e)
 end

 boss=actfact{
  name='forgotten king',
  isbig=true,
  x=x,y=y,
  hw=1.5,hh=3,
  spd=0.4,
  hp=10,
  idling={s2t'0;40;15;18;-7;-13;'},
  moving={animspd=0.24,s2t'16;40;15;18;-7;-13;',s2t'32;40;15;18;-7;-13;'},
  recovering={s2t'0;40;15;18;-7;-13;'},
  onroam=setupmagic
 }
 setupmagic(boss)
 return boss
end

function newdemonboss(x,y)
 boss=actfact{
  name='the evil',
  isbig=true,
  x=x,y=y,
  hw=3.5,hh=3.5,
  spd=0.75,
  hp=20,
  att_preprfm=30,
  att_postprfm=50,
  att_range=10,
  att_siz=12,
  att_col=0,
  att_typ='fire',
  att_recovertime=90,
  prfmatt=performenemymelee,
  passiveskills={{immune='fire'},{immune='ice'}},
  idling={s2t'77;71;19;18;-10;-15;'},
  moving={animspd=0.24,s2t'41;71;19;18;-10;-15;',s2t'59;71;19;18;-10;-15;'},
  attacking={animspd=0,s2t'79;45;31;24;-15;-20;',s2t'48;45;31;24;-15;-20;'},
  recovering={s2t'95;71;19;18;-10;-15;'}
 }
 return boss
end

-- items
slots,comcols2={'weapon','offhand','armor','helmet','boots','amulet','book'},s2t'-1;-1;-1;-1;2;'

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
 {name='ice ',col=7,sprites=s2t'30;46;162;63;232;79;49;199;214;',
  skill=swordattackskillfactory(12,'ice',150)},
 {name='flaming ',col=8,sprites=s2t'29;45;162;62;231;78;178;198;213;',
  skill=swordattackskillfactory(14,'fire',60)},
 {name='heavy ',col=5,sprites=s2t'-1;-1;-1;-1;-1;-1;-1;196;',
  skill=swordattackskillfactory(7,'knockback')},
 {name='sharp ',col=6,sprites=s2t'-1;-1;-1;-1;-1;-1;-1;200;',
  skill=swordattackskillfactory(7,nil,nil,2)},
}

bowprefix={
 {name='',col=4,sprites={},skill=bowattackskillfactory(26,7,2),twohand=true},
 {name='ice ',col=12,sprites=s2t'30;46;162;63;232;79;49;199;214;',
  skill=bowattackskillfactory(26,7,12,'ice',150),twohand=true},
 {name='flaming ',col=8,sprites=s2t'29;45;162;62;231;78;178;198;213;',
  skill=bowattackskillfactory(26,14,8,'fire',60),twohand=true},
}

amuletprefix={
 {
  name='skull ',
  sprites=s2t'-1;-1;31;',
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
 {name='knight\'s ',sprites=s2t'26;42;-1;59;228;76;',
  cols=s2t'13;13;-1;13;13;13;-1;13;',cols2=s2t'-1;-1;-1;-1;1;',armor=1},
 {name='feathered ',sprites=s2t'27;43;161;60;229;95;177;197;212;',
  cols=s2t'4;13;-1;2;4;4;-1;15;3;',spdfactor=0.1},
 {name='dragonscale ',sprites=s2t'28;44;-1;61;230;77;',
  cols=s2t'9;9;-1;9;9;9;-1;-1;-1;',cols2=s2t'-1;-1;-1;-1;4;',skill={
  sprite=8,desc='passive, cannot be burned',immune='fire'}},
 {name='warming ',sprites=s2t'29;45;162;62;231;78;178;198;213;',
  cols=s2t'8;8;-1;2;8;8;-1;8;8;',skill={
  sprite=11,desc='passive, cannot be frozen',immune='ice'}}
}

suffix={
 {name=' of haste',sprites=s2t'27;43;161;60;229;95;177;197;212;',
  cols=s2t'4;13;-1;2;4;4;-1;15;3;',spdfactor=0.1},
 {name=' of phasing',sprites=s2t'143;127;164;111;246;94;47;199;214;',
  cols=s2t'13;1;-1;1;2;1;-1;12;12;',cols2=s2t'-1;-1;-1;-1;1;',skill={
   sprite=10,
   desc='passive, phase away on hit',
   onhit=function(_a)
    local x,y=findflr(_a.x,_a.y)
    local _f=s2t'9;9;1;1;0;0;'
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
 {name=' of firebolt',sprites=s2t'29;45;162;62;231;78;178;198;213;',
  cols=s2t'8;8;-1;2;8;8;-1;8;8;',skill=boltskillfactory(
  'fire',14,8,14,14,8,15,'firebolt')},
 {name=' of icebolt',sprites=s2t'30;46;163;63;232;79;179;199;214;',
  cols=s2t'13;6;-1;12;12;12;-1;7;12;',cols2=s2t'-1;-1;-1;-1;1;',skill=boltskillfactory(
  'ice',7,12,12,12,13,14,'icebolt')},
 {name=' of concentration',sprites=s2t'244;245;159;175;191;249;216;247;215;',
  cols=s2t'3;6;-1;3;3;6;-1;6;11;',cols2=s2t'-1;-1;-1;-1;1;',att_spd_dec=3}
}

cloakidling,shieldidling,swordidling,bowidling
  ={s2t'40;9;3;4;-1;-2;'},{s2t'35;9;5;5;-2;-3;'},
  {s2t'9;9;5;5;-2;-3;'},{s2t'25;9;5;5;-2;-3;'}

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
  idling=swordidling,moving=swordidling,attacking={
   s2t'14;9;5;5;-2;-3;',s2t'18;9;7;5;-3;-3;'},
  recovering=swordidling},
 {slot='weapon',name='bow',sprite=72,col=4,twohand=true,prefix=bowprefix,
  idling=bowidling,moving=bowidling,attacking={
   s2t'30;9;5;5;-2;-3;',s2t'25;9;1;1;-2;-3;'},
  recovering=bowidling}
}

themes={
 {newmeleetroll,newmeleetroll,newtrollcaster,newgianttroll},
 {newbatenemy,newbatenemy,newbatenemy,newvampireboss},
 {newbatenemy,newmeleeskele,newbowskele,newskeleking},
 {newfirebatenemy,newdemoncaster,newdemoncaster,newdemonboss}
}

-- init avatar
idleframe=s2t'0;10;3;4;-1;-2;'
avatar=actfact{
 isavatar=true,
 x=64,y=56,
 hw=1.5,
 spdfactor=1,
 spd=0.5,
 hp=3,
 startarmor=0,
 att_spd_dec=0,
 armor=0,
 items={},
 inventory={},
 passiveskills={},
 idling={idleframe},
 moving={idleframe,s2t'3;10;3;4;-1;-2;'},
 attacking={animspd=0,s2t'6;10;3;4;-1;-2;',idleframe},
 recovering={idleframe}
}

for k,v in pairs(slots) do
 avatar.items[v]=loaditem(k)
end

function dungeoninit()
 _update60,_draw,
 dungeonlvl,theme,nexttheme,
 avatar.hp,avatar.x,avatar.y,avatar.removeme=
  dungeonupdate,dungeondraw,
  1,1,1,3,64,56
 for _t in all(themes) do
  _t.lvl_c=4+flrrnd(2)
 end
 mapinit()
end

tick,kills,curenemyi=0,0,1

function mapinit()
 local basemap={}
 for _y=0xffff,16 do
  basemap[_y]={}
  for _x=0xffff,16 do
   basemap[_y][_x]=9
  end
 end

 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)
 local curx,cury,a,enemy_c,enemies,steps,angles=
  avatarx,avatary,0,10,{},({250,500,600,700})[theme],
   ({s2t'0.25;-0.25;',s2t'0;0;0;0;0;0.5;0.25;-0.25;',
    s2t'0;0;0.5;0.25;',s2t'0.25;'})[theme]
 local step_c,_theme=steps,themes[theme]
 _theme.lvl_c-=1

 while step_c > 0 do
  local nextx,nexty=curx+cos(a),cury+sin(a)
  if flrrnd(3) == 0 or
     nextx <= 0 or nextx > 14 or
     nexty <= 0 or nexty > 14 then
   a+=angles[flrrnd(#angles)+1]
  elseif step_c != 0 and step_c % (steps / enemy_c) == 0 then
   add(enemies,{x=curx,y=cury,typ=flrrnd(3)+1})
  else
   curx,cury=nextx,nexty
   basemap[cury][curx]=5
  end
  step_c-=1
 end

 for _e in all(enemies) do
  basemap[_e.y][_e.x]=_e.typ
 end

 if _theme.lvl_c == 0 then
  local enemy=enemies[#enemies]
  basemap[enemy.y][enemy.x]=4
  nexttheme+=1
 end

 -- reset
 basemap[cury][curx],
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
  10,15,
  1,0,{},{},{},{},{},{}

 for _y=0,16 do
  walls[_y]={}
  for _x=0,16 do
   local _col,ax,ay=basemap[_y][_x],_x*8+4,_y*8+4

   if _col == 15 then
    avatar=add(actors,actfact(avatar))
    avatar.x,avatar.y,avatar.armor=ax,ay,avatar.startarmor
    add(interactables,{
     x=avatar.x,y=avatar.y,
     hw=4,hh=2.5,
     sprite=0,
     text='\x8e inventory',
     enter=equipinit,
    })
   end

   if _col <= 4 then
    add(actors,_theme[_col](ax,ay))
   end

   if _col == 10 then
    door={
     x=ax,y=ay,hw=4,hh=4,
     text='\x8e go deeper',
     enter=function()
      theme=nexttheme
      dungeonlvl+=1
      mapinit()
     end
    }

    if nexttheme > 4 then
     door.text,door.sprite,door.enter='\x8e go home',248,splash
    else
     door.sprite=179+nexttheme*16
    end
    add(interactables,door)
   end

   walls[_y][_x]=_col == 9 and 1 or 0
  end
 end

 music(theme*10,0,0b0011)
 if boss then
  music(1,0,0b0011)
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
   avatar.inventory,kills,theme,door={},0
   equipinit()
  end
  return
 end

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

 -- button input
 skillbuttondown=btn(4) and 1 or btn(5) and 2 or nil

 -- collide against interactables
 curinteractable=nil
 if isdoorspawned then
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
   avatar.state,avatar.currentskill,avatar.ispreprfm,
   avatar.state_c,avatar.curframe=
    'attacking',skill,true,max(1,skill.preprfm-avatar.att_spd_dec),1
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
  if actor != avatar then
   enemy_c+=1
  end
  actor.state_c-=1

  -- handle states
  if actor.state == 'idling' then
   actor.tarx,actor.tary,actor.ismovingoutofcollision=nil -- reset enemy vars

  elseif actor.state == 'attacking' then
   if actor == avatar then
    if avatar.state_c <= 0 then
     if avatar.ispreprfm then
      avatar.currentskill.perform(avatar,avatar.currentskill)

      avatar.state_c,avatar.curframe,avatar.ispreprfm=
       max(1,avatar.currentskill.postprfm-avatar.att_spd_dec),2

      if avatar.items.weapon then
       avatar.items.weapon.curframe=2
      end

     else
      avatar.state='idling'
      if avatar.items.weapon then
       avatar.items.weapon.curframe=1
      end
     end
    end

   else -- enemies

    if actor.laststate != 'attacking' then
     actor.ispreprfm,actor.curframe,actor.state_c=
      true,1,actor.att_preprfm

     if actor.onpreprfm then
      actor.onpreprfm(actor,actor.att_preprfm)
     end
    end

    if actor.ispreprfm and actor.state_c <= 0 then
     actor.prfmatt(actor)
     actor.state_c,actor.curframe,actor.ispreprfm=
      actor.att_postprfm,2

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
   actor.state,actor.currentskill='idling'
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
  enemy.att_range=enemy.att_range or 7

  -- aggression vars
  disttoavatar,haslostoavatar=
   dist(enemy.x,enemy.y,avatar.x,avatar.y),
   haslos(enemy.x,enemy.y,avatar.x,avatar.y)

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
  elseif enemy.state == 'attacking' or disttoavatar <= enemy.att_range and
        (haslostoavatar or enemy.nolos) then
   if enemy.laststate != 'attacking' then
    enemy.curframe=1
   end
   enemy.state,enemy.tarx,enemy.tary='attacking',avatar.x,avatar.y

  -- colliding w wall, move out of
  elseif enemy.wallcollisiondx then
   enemy.a=atan2(
     enemy.x+enemy.wallcollisiondx-enemy.x,
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
   if enemy.onroam then
    enemy.onroam(enemy)
   end
  end
 end

 -- update the next-position
 for actor in all(actors) do
  local spdfactor=actor.spdfactor or 1
  actor.dx,actor.dy=actor.dx*(actor.spd*spdfactor),actor.dy*(actor.spd*spdfactor)
  -- note: after this deltas should not change by input
 end

 -- check lvl cleared
 if enemy_c <= 0 and not isdoorspawned then
  isdoorspawned,walls[(door.y-4)/8][(door.x-4)/8]=true,0
  if boss then 
   music(6,0,0b0011)
  end
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
    elseif attack.typ == 'ice' then
     _a.effect,_a.dmgfx_col={func=freezeeffect},12
    end
    sfx(hitsfx)

    -- hit flash
    local x,y=_a.x+_a.dx/2,_a.y+_a.dy/2
    add(vfxs,{
     {42,20,5,5,x-2.5,y-2.5,c=4,col=_a.dmgfx_col},
     {42,20,5,5,x-2.5,y-2.5,c=5,col=7}})

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

 -- update attacks
 for attack in all(attacks) do
  if attack.state_c and not attack.removeme then
   attack.state_c-=1
   attack.removeme=attack.state_c <= 0
  end

  attack.x+=(attack.dx or 0)
  attack.y+=(attack.dy or 0)

  if attack.x > 128 or attack.x < 0 or
     attack.y > 128 or attack.y < 0 then
   attack.removeme=true
  end

  if isinsidewall(attack) and not attack.throughwalls then
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
     _p.follow.x,_p.follow.y,_p.poffsets,_p.dy or pemdef

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
 cls()
 local spr1,offset=176+theme*16,0

 -- draw walls
 for _y=0,#walls do
  for _x=0,#walls[_y] do
   if walls[_y][_x] != 0 then
    _x8=_x*8
    _y8=_y*8
    if _y == #walls or walls[_y+1] and walls[_y+1][_x] != 0 then
     spr(spr1+2,_x8,_y8)
    else
     if (_y + _x) % 7 == 0 then
      spr(spr1+1,_x8,_y8)
     else
      spr(spr1,_x8,_y8)
     end
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
  if attack.frame then
   local f=attack.frame
   if attack.col then
    pal(2,attack.col,0)
   end
   sspr(f[1],f[2],f[3],f[4],attack.x+f[5],attack.y+f[6],f[3],f[4])
   pal(2,2,0)
  end
 end

 -- draw actors
 for _a in all(actors) do
  local state=_a.state
  local f,flipx=_a[state][flr(_a.curframe)],
   _a.a and _a.a >= 0.25 and _a.a <= 0.75

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

  for k,v in pairs(_a.cols or {}) do
   pal(k,v,0)
  end

  -- draw dmg overlay color
  if _a.dmgfx_c > 0 then
   for i=1,15 do
    pal(i,_a.dmgfx_col,0)
   end
  end

  sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)

  -- draw cloak
  if _a == avatar and avatar.items.armor and
     avatar.items.armor.iscloak then
   item=avatar.items.armor
   local f=item[state][min(flr(item.curframe),#item[state])]
   pal(1,item.col,0)
   pal(3,item.col2,0)
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
  end

  -- draw weapon
  if _a == avatar and avatar.items.weapon then
   item=avatar.items.weapon
   local f=item[state][min(flr(item.curframe),#item[state])]
   pal(6,item.col,0)
   sspr(f[1],f[2],f[3],f[4],_a.x+f[5],_a.y+f[6],f[3],f[4],flipx)
  end

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
 for _i=0,avatar.hp-1 do
  print('\x87',121-_i*6,1,8)
  offset=(_i+1)*6-1
 end

 for _i=0,avatar.startarmor-1 do
  x=_i >= avatar.armor and 53 or 48
  sspr(x,40,5,5,121-offset-_i*6,1)
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
 cls()

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
  local offsetx6=offsetx+6
  spr(skill.sprite,offsetx6,88)
  if sectioncur == 3 and i == availableskillscur then
   rect(4+offsetx,86,15+offsetx,97,10)
   if skill then
    print(skill.desc,4,109,7)
   end
  end
  if skill == avatar.skill1 then
   spr(24,offsetx6,100)
   print('\fb\x8e',7+offsetx,100)
  end
  if skill == avatar.skill2 then
   spr(24,offsetx6,100)
   print('\f8\x97',7+offsetx,100)
  end
  offsetx+=12
  i+=1
 end

 -- draw exit button
 print('exit',57,120,sectioncur == 4 and 10 or 4)
end

-- function splash()
--  music()
--  _update60=function()
--   tick+=1
--   if btnp(4) then
--    theme=nil
--    equipinit()
--   end
--  end
--  _draw=function()
--   cls(1)
--   sspr(79,99,49,29,42,32)
--   col=tick % 60 <= 30 and 13 or 7
--   if theme then
--    print('you truly are a',32,17,13)
--    print('\x8e to continue',38,118,col)
--   else
--    print('\x8e to start',42,118,col)
--   end
--  end
-- end

_init=equipinit

__gfx__
0000000000000055055555500550055005555500555055000555550000555550111111111d11111111111ddd111111d111111166111111441111111111111111
00000540000005550555555055555555555555505550550050000050050000001d11d111ddd11111111111dddd1d11d111111666111116411111111111111111
0022544400005550055555505055550555555550555055005000005005555500111dd1d11d1111111d111d1d11d11d11111167611111614111dc1cc111281881
05444400500555000555555050555505500500505550550005500500055555001d1d1dd11d1dddd1ddd1d111111dd1d19116761111161141d111c77c21118ee8
50400400055550000555555000555500550005505555055000055000055555001dd111d1111d1d111d1111111d1dd111196761111161151111c1c77c11818ee8
00500500005500000555555000555500550005505555505500555500055555001ddd1dd11111d1d1d1d1d1d111d11d11119611111611511111111cc111111881
00000000050500000055550000555500550005500555505500555500055555001dd1d1d11111dd1111111dd11d11d1dd14191111444411211111111111111111
000000005000500000055000000000000500050000000000000550000555550011111111111111111111ddd11d11111191119111411111121111111111111111
0000000000000000000000000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000000000d555500
00000000000000006600000000006000000000000f00000000000000000000001111111144442020ddd0dd00444420209990990088808800dddd5050d0000050
0f00f00f40000600000000000000060006000000111000000000000000000000111111114422202065506500442220207ff07f00fee0ee00dd55505050000050
44444444000006000000000660000600006660001310000000000000024224201111111104440400ddd0dd000444040099909900888088000ddd0d0005500500
04004004000000000000000000006000060660001310000002422420011111100111111009220200655065000a9909007ff07f00fee0ee000711010000776600
20202020200000000000000000000000000000000000600002299220022992200000000004444040dddd0dd00444404099990990888808800dddd0d000716100
000000000000000000000000000000000000000000700000024444200244442000000000024444045dddd0dd02444404499990992888808805dddd0d00071600
000000000dd000000000200020000000020050505060000002222220022222200000000000222202055550550022220204444044022220220055550500066000
060d060d0660060000060206020620006020555555007000000000000000000000400200000d50000d7dd5000009400009f994000f0000f00000000000ddddd0
666d666d6600666dd00662066266620666200505050600000000000000000000064442d0002d5100d7dd555000d941009f994440f000000f000000000d666650
060006000600060000062006200620006020000000070000000000000000000004666d20042d5110676666d006d94110f77f9990f008200f0007600001111150
606006006060606000606006006060060600000000000000000000000000000004400420222d5111600600d0ddd94111f22f0090ef2821fe607cc606011d1150
070000707777000077770777770000700007008880077702202202220000000004400420d6dd5555d60006509f994444f77f99900e2821e06776666601d1d150
007007000077700777007777777707000000788888777772200020202000000004400420000d5000dd60655000094000f72f099002282110d000000d01d1d150
00700700000777777000700000007700000078888877777000000000000000000440042000000000dd60655000000000977f9940088822200dddd6d0011d1150
007777000007700770007000000077700007788888777770000000000000000044000042000000000d60650000000000097f9400000000000000000001111100
0077770000000000000077777777077777777088800777000000000000000000000000000000000000000000000000006dd0055d09000040000000006770066d
07777770000000000000077777000077777700000000000000000000002230000000000000000000d6600dd56770066d06655dd0f7700ff98ee00882066d5dd0
777777770000000000000000000000070070003300000330020033002000330000000000000000001dd51550166d5dd0005225002ff949921882122000dcc500
70000000077777777000000070000000070000330020033020003302000033000003300000033000105d510010d6d50000d22500209f940210282100006cc500
77000000770777770000000077000000770003330200333300333330000333000033300000033000d0d51505606d5d0d004f9400f0f9490980821202004f9400
77700007770077700000000077700007770003333000333000033300000333000033332200333000505d5101d0d6d50500d22500909f94042028210100dccd00
7770770777000000000000007777007777000444000044430004440000044430004440000033300000051000000d5000000220000009400000021000000cc000
777000077700070000000000077777777000030300003000000003000003000003403000004443000000000000000000000220000000000000000000000cc000
7700000077000700000000070000000000700000000000005000000000000066000000420000000000000000000000007667dd600fff99900e8822800666ddd0
700000000700000000000070000000000007000000005000400000000000066500000640000000000494494000444400611111d00f9944900822002006dd11d0
0000000000007770077770000000000000000777700040004000000000006750000060400000000002222220042222406167d1d00f97f490082e802006d7c1d0
000000000007777700777700000000000000777700104010400000000006750000060040049449400222222004294240717761600f97f4900e2e808006d7c1d0
000000000077777770077700000000000000777002224222400000000467500000600500044aa440044aa4400424424061d7d1d0094ff490020880200d1cc1d0
000000000000000000007700000000000000770002324232400000000045000006005000049999400499994004222240611d11d009444490020000200d1111d0
00000000000000000000070000000000000070000232423200000000020400004444000004999940049999400044440007111600009449000080080000d11d00
00000000000000000000000000000000000000000232423200000000400000002000000004444440044444400000000000d6d0000009900000022000000dd000
00000000000000000000000000000000000000000000000066666555550888000000000000000000000000000000000000000000000000000ddd111000000000
0000000000000000000000000000000000000000000000006ddd6511158787800000000000000000000000000000000000000000000000000d550010009f4400
0000000000000000000000000000000000000000000000006ddd6511158878800000000000000000000000000000000000000000000000000d56d01009220040
00000000000000000000000000000000000000000000000006d60051508787800000000000000000000000000000000000000000000000000d56d0100f294090
0000000000000000000000000000000000000000000000000060000500088800000000000000000000000000000000000000000000000000010dd01004044040
000000000000000000000000000000000000000000000000000000000eeeeeeee000000000000000000000000000000000000000000000000100001004000040
00000000f000000000000000f000000000000000f00000000000000eeeeeeeeeeeee000000000000000000000000000000000000000000000010010000494400
0000000ff00000000000000ff00000000000000ff000000000000eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000001100000000000
0000000660000000000000066000000000000006600000000000ee0000000eeeeeeeeee000000000600000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000e0e00000000000eeeeeeee00000006665555d000000000000000000000000000000000d6600dd2
0000000600b000000000000600b000000000000600b0000000e000000000000000eeeeeee00000006000000d000000000000000000000000000000000dd21220
00000066600000000000006660000000000000666000000000000000000000000000eeeeee00000000000000d0000000000000000000000000000000002d2100
000006060660000000000606066000000000060606600000e00000000000000000000eeeeee00000000000000d00400040000000000000000000000000d21200
0040606660000000004060666000000000406066600000000000000000000000000000eeeeee0000000000000dd044dd400000000000000000000000000d2000
0004000600000000000400060000000000040006000000000000000000000000400040eeeeee00000000000000dd0ddd00000000000000000000000000000000
00d040606000000000d040606000000000d0406060000000000000000000000044dd400eeeeee0000000000000dd0ddd00000000000000000000000000000000
0d000060600000000d000060600000000d000060600000000000000000000ddddddd000eeeeee00000000000000dddddd000000000000000000000000d6dd500
d000006060000000d000006000000000d000000060000000000000000000dddddddd000eeeeeee0000000000000dddddd00000000000000000000000d6dd5510
00000077777770000000000000000000000000000000000000000dd0000dddddddd0000eeeeeee0000000000000ddddddd0000000000000000000000d6dddd10
0000777777777770000000000000000000000000000000000000000dd00dddddddd00000eeeeee00000000000000dddddd000000000000000000000050060010
007777777777777770000000000000000000000000000000000000000ddddddddddd0000eeeeeee0000000000000ddddddd000000000000000000000d6d65510
0777777777777777770000000000000000000000000000000000000000ddddddddddd000eeeeeee0000000000000dddddddd00000000000000000000ddd55510
d77777777700077777000000000000000000000000000000000000000dddddddd00ddd00eeeeeee000000000000dddd000dd000000000000000000000d6d5100
0d77777000000000777000000000000000000000000000000000005ddddd000dd0000dd00eeeeee000000000d0d0dd00000d0000000000000000000000d51000
00d777000f0000000770000000000000f000000000000000000000000000005d0000000d00eeeee00000000d00d0dd0000050000000000000000000000000000
000d7400ff000000007700000000000ff00b000000000000000000000000000000000000600eeee000000000dd00d00000000000000000000000000022221010
000040006600000000770000000000066000000000000000000000000000000000000000060007e0000000000000d00000000000000000000000000022111010
00040600660000000007000000000006600600000000000000000000000000000000000000667770000000000000500000000000000000000000000002220200
0000006060000000000700000000000600600000000000000000000000000000000000000000070000000000000000000000000000000000000000000e880800
00000006660000000007000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222020
00000000600000000007000000000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001222202
00000006660000000070000000406066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111101
00000000600000000070000000040006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009444400
00000006060000000700000000d04060600000000000000000000000000000000000000000000000000000000000000000000004000400000000000090000040
0000006000600007700000000d0000606000000000000000000000000000000000400040000000000000040004000000000000044dd400000000000040000040
000000060006077000000000d0000060600000000000000004000400000000000044dd40000000000000044dd400000000000000ddd000000000000004400400
000000000000000000000000000000000000000000000000044dd40000000000000ddd0000000000000000ddd000000000000000ddd0000000000000000bbb00
00000000000000000000000000000000000000000000000000ddd00000000000000ddd0000000000000000ddd0000000000000dddddd000d0000000000ba1b30
00000000000000000000000000000000000000000000000000ddd000000000000dddddd000d000000000dddddd000d0000000ddddddd00d50000000000bb1330
000000000000000000000000000000000000000000000000dddddd000d000000ddddddd00d500000000ddddddd00d50000000ddddddd0d050000000000033300
0d5555000944440006dddd0004222200082222000000000ddddddd00d5000000ddddddd0d0500000000ddddddd0d050000000dddddddd00500000000f6600dd9
d000005090000040600000d040000020800000200000000ddddddd0d050000000ddddddd00500000000dddddddd00500000000ddddddd005000000000ffdd990
50000050044404000ddd0d0002220200200000200000000dddddddd0050000000ddddddd005000000000ddddddd00500000000ddddd000060000000000d33d00
05550500000aaa00000eee00000777000222020000000000ddddddd005000000dddddd00006000000000ddddd000060000000dddddd000666000000000633d00
0000400000a999a000e888e0007ccc700000c000000d000dddddd0000600000d0ddddd0006660000000ddd0dd00066600000d0dd0dd0000600000000005f9500
0004440000a9a49000e8e280007c71d0000c7c000000ddd0dddddd00666000d00dddd0000060000dddd0dd0d000006000d00d0dd0d0000000000000000d33d00
00004000009444900082228000d111d00000c00000000000d000ddd006000d0000dd0000000000d00000d00d0000000000dd00d00d0000000000000000033000
000040000009990000088800000ddd000000000000000000d0000dd000000d0000d00000000000000000d00d00000000000000d00d0000000000000000033000
00999990009999900088888000666660082222000000000d00000d000000000000d0000000000000000050050000000000000050050000000000000000300100
09ffff2009ffff2008ffff40067777d0800000200000000500000500000000000050000000000000000000000000000000000000000000000000000007333160
0444442004444420022222400cccccd0022202000000000000000000000000000000000000000000000000000000000000000000000000000000000003777610
0444442004aaa420022822400c7c7cd0000777000000000006600000000000000000000000000000000000010001600610101000000000000000000003300310
0444442004444420022882400cc7ccd00076667003060306033003000000000000000000000cc000000060011611600611111100000000000000000003300310
0444442004aa4420028e82400c7c7cd000767d603336333633003336600000000000000000ccccc0000111011111800801010100000000000000000003300310
0444442004444420028e82400cccccd0006ddd60040004000400040000000000000000000cc00ccc000111001110000000000000000000000000000003300310
0444440004444400022222000ccccc000006660030300300303030300000000000000000cc0000cc000111000100000000000000000000000000000033000031
55555555555555555555555500000000000000dd000000ff0000008800000066000000660cc00cc0000000000000000000000000000000000000000000000000
5555555555555555555555550040040000000dd500000ff900000888000006660000066d00cccc00000000000000000000000000000000000000000000000000
550555555555550555555555004444009000d6500000f79066008e80dd006760000067d0000cc000000000000000000000000000000000000000000000000000
50550505505e05055555555500400400900d6500d00f79006008e800d006760090067d0000000007070777077707770707007707070077000000000000000000
5050500505585050555555550544445009d650000df79000068e80000d6760000967d00000000007070d7d07d70d7d070707d7070707dd000000000000000000
505050500502505055555555504004050095000000d900000068000000560000009d000000000007070070077d00700707070707070777000000000000000000
0050005050020050555555550555555002040000020500000205050001050500020400000000000777007007d700700707070707070dd7000000000000000000
0500050000000500555555550000000090004400d000500050005500c0005500900040000000000d7d0777070700700d77077d0d77077d000000000000000000
1111111111111111111111111111111100000063000000f800000042000000240066666000000000d00ddd0d0d00d000dd0dd000dd0dd0000000000000000000
111111111111111111111111000000010000060300000f0800000640000002040677775000000000000000000000000000000000000000000000000000000000
00000000000000001111111155011001000060030000f00e000060c0000020030333335000000000000000000000000000000000000000000000000000000000
5055505550505505111111115500001100060030000f0080000600400002003b0333335000000000000000000000000000000000000000000000000000000000
000000000000000011111111551550010060042000f004200060051000200510033b335000000007070777077000700707077700770707077707770000000000
05550555505505551111111155155001060042000f004200060051000200510003333350000000070707d707d707d707070d7d07dd070707dd07d70000000000
0000000000000000111111115515515160032000f008200044c410002003100003333350000000070707770707070707070070077707770770077d0000000000
550555055505505511111111111111113330000088e0000020000000443b000003333300000000077707d70707077d070700700dd707d707d007d70000000000
1111111111111111111111111111111100d0010000400200009004000080020000c001000000000d7d070707070d770d770777077d0707077707070000000000
1111111111111111111111110000000107ddd1600a444290079994f0078882e007ccc16000000000d00d0d0d0d00dd00dd0ddd0dd00d0d0ddd0d0d0000000000
000000000000000011111111550110010d77761004aaa92009777f4008777e200c77761000000000000000000000000000000000000000000000000000000000
111011011118110111111111550000110dd00d100440042009900940088008200cc00c1000000000000000000000000000000000000000000000000000000000
11001001110e100111111111551550010dd00d100440042009900940088008200cc00c1000000000000000000000000000000000000000000000000000000000
000000000002000011111111551550010dd00d100440042009900940088008200cc00c1000000000000000000000000000000000000000000000000000000000
011110110112101111111111551551510dd00d100440042009900940088008200cc00c1000000000000000000000000288888882888802888828888088888000
01110010011100101111111111111111dd0000d1440000429900009488000082cc0000c100000000000000000000000028822280288200288202882028220000
22222222222222222222222200000000000000000007600000200100000000660000004407776660000000000005000008800020028000082000882028800000
222222222222222222222222004004003333505000776d00062221d00000066d000442440766dd60000000050050000008800000008800880000880008800000
220222222222220222222222004444003355505007676dd002666d10090067d04424424407676d60000000505050000008888200008808820000880008800000
202202022022020222222222004004000333030067676ddd0220021099067d004424424407676d60000000505055000008828000002888200000880008800000
202020020220202022222222024444200944040077776666022002100997d0004424422206d66d60000000050050000008802000000888200000880008800000
2020202002002020222222222040040203333030000760000220021000b400004422222206dddd60000000000050000008800080000282000000880028800008
002000202002002022222222022222200533330360000006022002100104440022222222006dd600000000000500000288888880000080000228888288888882
0200020000000200222222220000000000555505d000000d22000021900040000000000000066000000000000000000022222220000020000022222022222220
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

