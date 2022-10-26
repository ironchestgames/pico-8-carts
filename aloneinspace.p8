pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable auto-repeat for btnp

-- pink as transparent
palt(14,true)
palt(0,false)

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

function contains(_t,_v)
 for _other in all(_t) do
  if _other == _v then
   return true
  end
 end
end

function isinsiderange(_n,_min,_max)
 return mid(_min,_n,_max) == _n
end

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*.1
 local dy=(y2-y1)*.1
 return sqrt(dx*dx+dy*dy)*10
end

function sortbyy(a)
 for i=1,#a do
  local j=i
  local y1=a[j].y
  if a[j].ground then
   y1=-1
  end
  while j > 1 and a[j-1].y > y1 do
   a[j],a[j-1]=a[j-1],a[j]
   j=j-1
  end
 end
 return a
end

function wrap(_min,_n,_max)
  return (((_n-_min)%(_max-_min))+(_max-_min))%(_max-_min)+_min
end

function drawmessages()
 if #messages > 0 then
  local _strlen=#messages[1]*4
  local _y=guy.y-36
  rectfill(guy.x-_strlen/2,_y,guy.x+_strlen/2+2,_y+8,7)
  line(guy.x,_y,guy.x,guy.y-7,7)
  print(messages[1],guy.x+2-_strlen/2,_y+2,0)
 end
end

function updatemessages()
 if #messages > 0 then
  messages.c-=1
  if messages.c <= 0 then
   del(messages,messages[1])
   messages.c=30
  end
 end
end

function drawsamplecase(_x,_y,_showarrow)
 sspr(103,0,25,13,_x,_y)

 samplesel=mid(1,samplesel,#samples)

 for _i=1,#samples do
  local _lx=_x+4+(_i-1)*4

  if lookinginsamplecase or (_i != #samples or guy.samplingc % 8 > 4) then
   line(_lx,_y+6,_lx,_y+8,samples[_i])
  end

  if _showarrow and _i == samplesel then
   sspr(99,122,5,6,_lx-2,_y+15)
  end
 end
end

function updatedroidalert()
 if droidalertc and droidalertc > 0 then
  droidalertc-=1
 end
end

-- global vars
sector={
 planets={},
}
guy={}
lookinginsamplecase=nil
samples={}
samplesel=1
storages={}
seed={}
fuel=5
score=0
seedsshot=0
lastseed=0
traveling='warping'
travelc=60

droidalertc=nil
droidlandingx=128
droidlandingy=128
droidlandingc=nil -- note: set in planetinit
droidtalkingc=nil
droids={}

takesampleaction={
 title='take sample',
 func=function (_target)
  if #samples == 5 then
   add(messages,'sample case is full')
  else
   _target.action=nil
   add(samples,_target.samplecolor)
   guy.samplingc=20
   sfx(8)
  end
 end,
}

function sighthunting(_behaviouree)
 local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
 local _disttotarget=dist(_behaviouree.x,_behaviouree.y,_behaviouree.targetx,_behaviouree.targety)
 _behaviouree.hunting=nil

 if _disttoguy < _behaviouree.spd + 0.5 then
  debug('dead by caughten')

 elseif _disttoguy < _behaviouree.sightradius then
  _behaviouree.targetx=guy.x
  _behaviouree.targety=guy.y
  _behaviouree.hunting=true

 elseif _disttotarget < _behaviouree.spd + 0.5 then
  _behaviouree.targetx=_behaviouree.x+rnd(_behaviouree.sightradius)-_behaviouree.sightradius/2
  _behaviouree.targety=_behaviouree.y+rnd(_behaviouree.sightradius)-_behaviouree.sightradius/2

 end
 
 local _spd=_behaviouree.hunting and _behaviouree.huntingspd or _behaviouree.spd
 local _a=atan2(_behaviouree.targetx-_behaviouree.x,_behaviouree.targety-_behaviouree.y)
 _behaviouree.x+=cos(_a)*_spd
 _behaviouree.y+=sin(_a)*_spd

 _behaviouree.flipx=_behaviouree.x > _behaviouree.targetx

 local _animfactor=_behaviouree.hunting and 4 or 8

 _behaviouree.c-=1
 if _behaviouree.c <= 0 then
  _behaviouree.c=_animfactor*2
 end
 _behaviouree.sx=0
 if _behaviouree.c > _animfactor then
  _behaviouree.sx=_behaviouree.sw
 end

end

animaltypes={
 bear={
  sx=0,
  sy=10,
  sw=8,
  sh=8,
  sightradius=36,
  spd=0.75,
  huntingspd=1,
  c=0,
 },
 bat={
  sx=0,
  sy=18,
  sw=7,
  sh=6,
  sightradius=32,
  spd=0.75,
  huntingspd=0.75,
  c=0,
 },
 spider={
  sx=0,
  sy=24,
  sw=12,
  sh=7,
  sightradius=38,
  spd=0.25,
  huntingspd=1.25,
  c=0,
 },
 bull={
  sx=0,
  sy=31,
  sw=8,
  sh=8,
  sightradius=28,
  spd=0.125,
  huntingspd=1,
  c=0,
 },
 gnawer={
  sx=0,
  sy=39,
  sw=8,
  sh=8,
  sightradius=48,
  spd=0.75,
  huntingspd=1.25,
  c=0,
 },
 slime={
  sx=0,
  sy=47,
  sw=9,
  sh=6,
  sightradius=72,
  spd=0.25,
  huntingspd=0.5,
  c=0,
 },
}

objtypes={
 berrybush={
  sx=52,
  sy=0,
  sw=7,
  sh=6,
  samplecolor=10,
  action=takesampleaction,
 },
 twigs={
  sx=20,
  sy=4,
  sw=6,
  sh=4,
  ground=true,
 },
 flowers={
  sx=31,
  sy=0,
  sw=5,
  sh=4,
  samplecolor=9,
  action=takesampleaction,
 },
 mushroom_red={
  sx=20,
  sy=8,
  sw=7,
  sh=5,
  samplecolor=15,
  action=takesampleaction,
 },
 mosstone_small={
  sx=15,
  sy=0,
  sw=6,
  sh=4,
 },
 mosstone_big={
  sx=52,
  sy=6,
  sw=8,
  sh=7,
 },
 grass1={
  sx=21,
  sy=0,
  sw=5,
  sh=4,
 },
 grass2={
  sx=15,
  sy=4,
  sw=5,
  sh=5,
 },
 lake_watercolor={
  sx=26,
  sy=4,
  sw=11,
  sh=7,
  ground=true,
  samplecolor=13,
  action=takesampleaction,
  walksfx=7,
  sunken=true,
 },
 pine_small={
  sx=37,
  sy=0,
  sw=7,
  sh=9,
  samplecolor=6,
  action=takesampleaction,
 },
 pine_big={
  sx=44,
  sy=0,
  sw=8,
  sh=15,
  samplecolor=6,
  action=takesampleaction,
 },
 mushroom={
  sx=20,
  sy=13,
  sw=7,
  sh=5,
  samplecolor=15,
  action=takesampleaction,
 },
 deadtree1={
  sx=38,
  sy=15,
  sw=8,
  sh=8,
 },
 deadtree2={
  sx=46,
  sy=15,
  sw=8,
  sh=8,
 },
 lake={
  sx=27,
  sy=11,
  sw=11,
  sh=7,
  ground=true,
  samplecolor=13,
  action=takesampleaction,
  walksfx=7,
  sunken=true,
 },
 marsh={
  sx=38,
  sy=9,
  sw=5,
  sh=4,
  ground=true,
 },
 marsh_watercolor={
  sx=26,
  sy=0,
  sw=5,
  sh=4,
  ground=true,
 },
 marsh_darkgrey={
  sx=21,
  sy=18,
  sw=5,
  sh=4,
  ground=true,
 },
 rock_big={
  sx=54,
  sy=13,
  sw=7,
  sh=8,
 },
 rock_small={
  sx=53,
  sy=21,
  sw=6,
  sh=5,
 },
 canyon_big={
  sx=38,
  sy=29,
  sw=8,
  sh=8,
 },
 canyon_medium={
  sx=46,
  sy=30,
  sw=8,
  sh=7,
 },
 canyon_small={
  sx=46,
  sy=23,
  sw=7,
  sh=3,
 },
 cactus1={
  sx=54,
  sy=26,
  sw=7,
  sh=9,
  samplecolor=13,
  action=takesampleaction,
 },
 cactus2={
  sx=54,
  sy=35,
  sw=7,
  sh=8,
  samplecolor=13,
  action=takesampleaction,
 },
 skull={
  sx=46,
  sy=26,
  sw=8,
  sh=4,
  samplecolor=6,
  action=takesampleaction,
 },
 ribs={
  sx=38,
  sy=23,
  sw=8,
  sh=6,
  samplecolor=6,
  action=takesampleaction,
 },
}

-- {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
planettypes={
 { -- light forest
  wpal={3,141,0,135,139},
  surfacecolor=3,
  objtypes={
   'berrybush',
   'flowers',
   'mushroom_red',
   'mosstone_small',
   'mosstone_big',
   'marsh_watercolor',
   'grass1',
   'grass2',
   'lake_watercolor',
   'pine_small',
   'pine_small',
   'pine_big',
   'pine_big',
   'pine_big',
  },
  animaltypes={'bear','bat'},
  objdist=20,
 },
 { -- dark forest
  wpal={131,141,134,135,3},
  surfacecolor=3,
  objtypes={
   'pine_big',
   'pine_big',
   'pine_big',
   'pine_big',
   'pine_small',
   'pine_small',
   'grass1',
   'grass2',
   'marsh_watercolor',
   'marsh_watercolor',
   'marsh_watercolor',
   'mosstone_small',
   'mosstone_small',
   'mosstone_big',
   'mosstone_big',
   'lake_watercolor',
   'twigs',
   'twigs',
   'mushroom_red',
   'flowers',
  },
  animaltypes={'bear','bat','bat'},
  objdist=24,
 },
 { -- marsh
  wpal={133,130,134,141,131},
  surfacecolor=4,
  objtypes={
   'grass1',
   'grass1',
   'grass1',
   'grass1',
   'grass2',
   'grass2',
   'grass2',
   'grass2',
   'deadtree1',
   'deadtree2',
   'lake',
   'berrybush',
   'mushroom',
   'marsh_darkgrey',
   'marsh_darkgrey',
   'marsh_darkgrey',
   'marsh_darkgrey',
   'marsh_darkgrey',
   'marsh_darkgrey',
  },
  animaltypes={'spider','spider','spider','bat'},
  objdist=26,
 },
 { -- ice
  wpal={7,6,6,7,7},
  surfacecolor=7,
  objtypes={
   'deadtree1',
   'deadtree2',
   'lake',
   'marsh',
   'marsh',
   'marsh',
   'rock_small',
   'rock_small',
   'rock_big',
   'rock_big',
  },
  animaltypes={'gnawer','gnawer'},
  objdist=28,
 },
 { -- wasteland 1
  wpal={4,132,141,9,15},
  surfacecolor=9,
  objtypes={
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'cactus1',
   'cactus2',
   'skull',
   'ribs',
   'canyon_big',
   'canyon_big',
   'canyon_medium',
   'canyon_medium',
   'canyon_small',
   'canyon_small',
  },
  animaltypes={'bull','bull'},
  objdist=30,
 },
 { -- wasteland 2
  wpal={134,141,141,15,6},
  surfacecolor=6,
  objtypes={
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'skull',
   'ribs',
   'canyon_big',
   'canyon_big',
   'canyon_medium',
   'canyon_medium',
   'canyon_small',
   'canyon_small',
   'canyon_small',
   'canyon_small',
  },
  animaltypes={'gnawer','gnawer'},
  objdist=30,
 },
 { -- desert
  wpal={15,143,3,8,3},
  surfacecolor=9,
  objtypes={
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'marsh',
   'flowers',
   'cactus1',
   'cactus2',
  },
  animaltypes={'spider','spider'},
  objdist=30,
 },
}

mapsize=255


function createplanet(_planettype)
 local _rndseed=rnd()
 srand(_rndseed)

 local _wpal={
  _planettype.wpal[1],
  _planettype.wpal[2],
  _planettype.wpal[3],
  _planettype.wpal[4],
  5,6,7,136,9,137,11,
  _planettype.wpal[5],
  13,14,15}

 local _mapobjs={
  { -- player ship
   x=mapsize/2,
   y=mapsize/2-10,
   sx=0,
   sy=0,
   sw=15,
   sh=6,

   action={
    title='go back to ship',
    func=function()
     traveling='up'
     travelc=30
     shipinit()
     return true
    end,
   }
  },
  { -- player ship shadow
   x=mapsize/2+1,
   y=mapsize/2-10,
   sx=8,
   sy=9,
   sw=12,
   sh=1,
   ground=true,
  },
 }

 local _tooclosedist=_planettype.objdist

 for _i=1,50 do
  local _x,_y,_tooclose
  local _tries=0
  repeat
   _x=rnd(mapsize-_tooclosedist)
   _y=rnd(mapsize-_tooclosedist)
   _tooclose=nil

   for _other in all(_mapobjs) do
    if dist(_x,_y,_other.x,_other.y) < _tooclosedist then
     _tooclose=true
     break
    end
   end

   _tries+=1

   if _tries > 20 then
    break
   end

  until _tooclose == nil

  local _obj=clone(objtypes[rnd(_planettype.objtypes)])
  _obj.x=_x
  _obj.y=_y

  add(_mapobjs,_obj)
 end

 local _animals={}
 for _i=1,5 do
  if rnd() < 1 - 1 / #_planettype.animaltypes then
   local _typ=rnd(_planettype.animaltypes)
   local _animal=clone(animaltypes[_typ])
   _animal.x=flr(rnd(mapsize))
   _animal.y=flr(rnd(mapsize))
   if dist(mapsize/2,mapsize/2,_animal.x,_animal.y) > 60 then
    _animal.targetx=_animal.x
    _animal.targety=_animal.y
    _animal.typ=_typ
    add(_animals,_animal)
   end
  end
 end

 return {
  rndseed=_rndseed,
  mapobjs=_mapobjs,
  wpal=_wpal,
  surfacecolor=_planettype.surfacecolor,
  animals=_animals,
 }
end

function nextsector()
 local _planetcount=rnd{1,2,2,2,3,3}

 sector={
  planets={}
 }

 for _i=1,_planetcount do
  add(sector.planets,createplanet(rnd(planettypes)))
  -- add(sector.planets,createplanet(planettypes[7]))
 end
end

-- planet scene

function planetinit(_planetid)
 lookinginsamplecase=nil

 droidlandingc=180
 droidtalkingc=140

 guy={
  x=mapsize/2,
  y=mapsize/2,
  sx=58,
  sy=60,
  sw=6,
  sh=6,

  spd=1,
  talkingc=0,
  walkingc=0,
  runningc=0,
  walksfx=6,
  samplingc=0,
 }

 pal(sector.planets[1].wpal,1)

 messages={
  c=30,
 }

 camera(guy.x/2,guy.y/2)

 _update=planetupdate
 _draw=planetdraw
end

function planetupdate()
 local _movex=0
 local _movey=0

 local _spd=guy.spd

 guy.sx=58

 if guy.panting then
  _spd=0
 elseif guy.runningc > 0 then
  _spd*=2
 end

 if guy.talkingc <= 0 and guy.samplingc <= 0 then
  if btn(0) then
   _movex+=_spd
  elseif btn(1) then
   _movex-=_spd
  end

  if btn(2) then
   _movey+=_spd
   guy.sx=64
  elseif btn(3) then
   _movey-=_spd
   guy.sx=58
  end 
 end

 if _movex != 0 or _movey != 0 then
  guy.walkingc-=1
  if guy.runningc > 0 then
   guy.walkingc-=1
  end
  if guy.walkingc <= 0 then
   guy.walkingc=6
   sfx(guy.walksfx)
  end

  if btn(5) then
   guy.runningc+=1
  else
   guy.runningc=max(0,guy.runningc-2)
  end

  lookinginsamplecase=nil

  if guy.runningc > 30 and not guy.panting then
   add(messages,rnd{'*pant pant','*huff puff','*wheeeeze'})
   guy.panting=true
  end

 else
  guy.walkingc=0

  guy.runningc=max(0,guy.runningc-2)

  if guy.runningc == 0 then
   guy.panting=nil
  end

  lookinginsamplecase=(not guy.panting) and btn(5)

 end

 guy.walksfx=6
 guy.action=nil
 guy.sunken=nil

 local _mapobjs=sector.planets[1].mapobjs

 droidlandingx=wrap(0,droidlandingx+_movex,mapsize)
 droidlandingy=wrap(0,droidlandingy+_movey,mapsize)

 for _droid in all(droids) do
  _droid.x=wrap(0,_droid.x+_movex,mapsize)
  _droid.y=wrap(0,_droid.y+_movey,mapsize)
  _droid.targetx=wrap(0,_droid.targetx+_movex,mapsize)
  _droid.targety=wrap(0,_droid.targety+_movey,mapsize)
 end

 for _animal in all(sector.planets[1].animals) do
  _animal.x=wrap(0,_animal.x+_movex,mapsize)
  _animal.y=wrap(0,_animal.y+_movey,mapsize)
  _animal.targetx=wrap(0,_animal.targetx+_movex,mapsize)
  _animal.targety=wrap(0,_animal.targety+_movey,mapsize)
 end

 for _obj in all(_mapobjs) do
  _obj.x=wrap(0,_obj.x+_movex,mapsize)
  _obj.y=wrap(0,_obj.y+_movey,mapsize)

  if (_obj.action or _obj.walksfx or _obj.sunken) and dist(guy.x,guy.y,_obj.x,_obj.y) < 5 then
   if _obj.walksfx then
    guy.walksfx=_obj.walksfx
   end

   if _obj.sunken then
    guy.sunken=_obj.sunken
   end

   if _obj.action then
    guy.action=_obj.action
    guy.action.target=_obj
   end
  end
 end

 if btnp(4) then
  if guy.action then
   if guy.action.func(guy.action.target) then
    return
   end
  else
   guy.talkingc=8
   sfx(rnd{0,1,2})
  end
 end

 guy.talkingc-=1
 guy.samplingc-=1

 if guy.talkingc > 0 then
  guy.sx=70
 end

 if guy.sunken then
  guy.sy=59
 else
  guy.sy=60
 end

 -- update droid co
 updatedroidalert()

 if droidalertc == 0 then
  if droidlandingc > 0 then
   droidlandingc-=1
   if droidlandingc == 0 then
    add(droids,{
     x=droidlandingx+16,
     y=droidlandingy+16,
     targetx=droidlandingx+16,
     targety=droidlandingy+16,
     sx=16,
     sy=53,
     sw=8,
     sh=8,
     sightradius=128,
     spd=0,
     huntingspd=2,
     c=0,
    })
   end
  elseif droidtalkingc > 0 then
   droidtalkingc-=1
  end
 end

 if droidlandingc == 0 and droidtalkingc == 0 then
  for _droid in all(droids) do
   sighthunting(_droid)
  end
 end

 -- update animals
 for _animal in all(sector.planets[1].animals) do
  sighthunting(_animal)
 end

 -- update messages
 updatemessages()
end

function planetdraw()
 cls(1)

 local _mapobjs=sector.planets[1].mapobjs
 local _drawies=clone(_mapobjs)
 add(_drawies,guy)

 for _animal in all(sector.planets[1].animals) do
  add(_drawies,_animal)
 end

 if droidlandingc == 0 then
  for _droid in all(droids) do
   add(_drawies,_droid)
  end
 end

 sortbyy(_drawies)

 for _obj in all(_drawies) do
  local _y=_obj.y-_obj.sh
  if _obj.ground then
   _y=_obj.y-flr(_obj.sh/2)
  end
  sspr(
   _obj.sx,
   _obj.sy,
   _obj.sw,
   _obj.sh,
   _obj.x-flr(_obj.sw/2),
   _y,
   _obj.sw,
   _obj.sh,
   _obj.flipx)
 end

 -- draw droid ship
 if droidalertc == 0 then
  local _y=droidlandingy-droidlandingc
  sspr(48,49,10,24,droidlandingx,_y)
 end

 -- draw droid talk
 if droidlandingc == 0 and droidtalkingc > 0 then
  local _strlen=19*4
  local _droid=droids[1]
  local _y=_droid.y-36
  rectfill(_droid.x-_strlen/2,_y,_droid.x+_strlen/2+2,_y+8,13)
  line(_droid.x,_y,_droid.x,_droid.y-12,13)
  print('stop spreading life',_droid.x+2-_strlen/2,_y+2,7)
 end

 -- draw guy action
 if guy.action then
  local _strlen=#guy.action.title*4+14
  local _targetx=guy.action.target.x
  local _y=guy.action.target.y-22
  rectfill(_targetx-_strlen/2,_y,_targetx+_strlen/2,_y+8,0)
  line(_targetx,_y,_targetx,guy.action.target.y-guy.action.target.sh-2,0)
  print('\x8e '..guy.action.title,_targetx+2-_strlen/2,_y+2,9)
 end

 -- draw sample case
 if lookinginsamplecase or guy.samplingc > 0 then
  local _x=guy.x-10
  local _y=guy.y+10
  sspr(119,13,9,3,_x+8,_y-3)
  drawsamplecase(_x,_y)
 end

 -- draw message
 drawmessages()
end


-- ship scene

function drawdoor(_obj)
 if _obj.firstframe then
  sfx(11)
 end
 if _obj.inrange then
  sspr(89,122,3,6,_obj.x,_obj.y)
  _obj.c=6
 else
  if _obj.c == 6 then
   sfx(10)
  end
  _obj.c-=1
  if _obj.c > 0 then
   local _d=(6-_obj.c)
   sspr(89,122,3,6-_d,_obj.x,_obj.y+_d)
  end
 end
end

function drawelevator(_obj)
 _obj.c-=1
 if _obj.inrange then
  pset(62,73,11)
  pset(62,84,11)
  rectfill(61,_obj.y,63,_obj.y+4,6)
  _obj.c=6

 elseif _obj.c > 0 then
  local _d=2-flr(_obj.c/2)
  rectfill(61+_d,_obj.y,63,_obj.y+4,6)
 end
end

function drawseed(_x,_y,_spin)
 for _i=1,#seed do
  local _ii=_i-1
  pset(_x+_ii%2,_y+flr(_ii/2),seed[_i])
 end
 if _spin then
  add(seed,deli(seed,1))
 end
end

function sampleselectinputhandler(_obj)
 if btn(4) then
  if btnp(0) then
   samplesel-=1
  elseif btnp(1) then
   samplesel+=1
  end
  samplesel=wrap(1,samplesel,#samples+1)

  _obj.inputlastframe=true
 end
end

function storageinputhandler(_obj)
 sampleselectinputhandler(_obj)

 if _obj.inputlastframe == true and not btn(4) then
  _obj.inputlastframe=nil

  local _index=_obj.index
  if storages[_index] != nil and #samples < 5 then
   add(samples,storages[_index])
   storages[_index]=nil
  elseif storages[_index] == nil and #samples > 0 then
   storages[_index]=deli(samples,samplesel)
  end
 end
end

function storagedraw(_obj)
 if _obj.inrange then
  local _index=_obj.index
  local _showsamplecasearrow=nil

  local _x=_obj[1]-4
  sspr(92,0,11,13,_x,98)

  if storages[_index] != nil and #samples < 5 then
   actiontitle='\x8e take sample'
   sspr(99,122,5,6,_x+3,113)
  elseif storages[_index] == nil and #samples > 0 then
   actiontitle='\x8e store sample'
   _showsamplecasearrow=true
  end

  drawsamplecase(42,98,_showsamplecasearrow)

  if storages[_obj.index] then
   local _lx=_x+5
   line(_lx,105,_lx,107,storages[_obj.index])
  end
 end
end

samplecolorvalues={
 [6]=2, -- stone
 [15]=3, -- sandish
 [9]=4, -- orange
 [13]=5, -- water
 [10]=6, -- bloody orange / taurus blood
 [11]=10, -- mars blood
}

function getseedpoints()
 local _result=0
 local _samples=clone(seed)

 local _kinds={}

 for _color=1,15 do
  local _value=samplecolorvalues[_color]
  if _value then
   while del(_samples,_color) do
    _result+=_value
    if not contains(_kinds,_value) then
     add(_kinds,_value)
    end
   end
  end
 end

 _result=_result+#_kinds*5

 return _result
end

shipobjs={
 { -- floor 1
  { -- elevator
   [1]=60,
   [2]=65,
   c=0,
   y=86,
   inputhandler=function(_obj)
    if btnp(2) then
     _obj.c=6
     guy.floor=2
     sfx(4)
    end
   end,
   draw=drawelevator,
  },
  { -- small ship
   [1]=29,
   [2]=43,
   inputhandler=function(_obj)
    if btnp(4) then
     traveling='down'
     travelc=30
    end
   end,
   draw=function(_obj)
    if _obj.inrange then
     sspr(92,124,7,4,31,84)
     actiontitle='\x8e go to surface'
    end
   end,
  },
  { -- storage 1
   [1]=71,
   [2]=76,
   index=1,
   inputhandler=storageinputhandler,
   draw=storagedraw,
  },
  { -- storage 2
   [1]=77,
   [2]=82,
   index=2,
   inputhandler=storageinputhandler,
   draw=storagedraw,
  },
  { -- storage 3
   [1]=83,
   [2]=88,
   index=3,
   inputhandler=storageinputhandler,
   draw=storagedraw,
  },
  { -- destructor
   [1]=94,
   [2]=99,
   inputhandler=function(_obj)
    sampleselectinputhandler(_obj)

    if _obj.inputlastframe == true and not btn(4) then
     _obj.inputlastframe=nil

     deli(samples,samplesel)
     sfx(15)
    end
   end,
   draw=function(_obj)
    if _obj.inrange then
     drawsamplecase(80,98,true)

     if #samples > 0 then
      actiontitle='\x8e destroy sample'
     end
    end
   end,
  },
  { -- door
   [1]=43,
   [2]=49,
   x=44,
   y=85,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=54,
   [2]=60,
   x=55,
   y=85,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=66,
   [2]=72,
   x=67,
   y=85,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=88,
   [2]=94,
   x=89,
   y=85,
   c=0,
   draw=drawdoor,
  },
 },

 { -- floor 2
  { -- engine
   [1]=28,
   [2]=37,
   c=0,
   inputhandler=function(_obj)
    sampleselectinputhandler(_obj)

    if _obj.inputlastframe == true and not btn(4) then
     _obj.inputlastframe=nil

     local _sample=samples[samplesel]
     if fuel == 5 then
      add(messages,'tank is full')
     elseif _sample == nil and fuel == 0 then
      add(messages,'tank is empty')
     elseif _sample == 13 then
      fuel+=1
      deli(samples,samplesel)
     else
      add(messages,'only water for fuel')
     end
    end
   end,
   draw=function(_obj)
    if fuel > 0 then
     line(36,79,36,75+(5-fuel),12)

     rectfill(19,73,20,79,12)

     local _offx=(t()*78)%2 > 1 and 1 or 0
     sspr(117,123,11-_offx,5,10+_offx,74)
    end

    if fuel <= 1 then
     pset(34,73,8)
    end

    _obj.c-=1
    if _obj.c <= 0 then
     _obj.c=6
    end

    if fuel > 0 and _obj.c % 6 > 3 then
     sspr(102,117,4,5,29,75)
    end

    if _obj.inrange then
     drawsamplecase(39,98,true)

     if #samples > 0 then
      actiontitle='\x8e put in engine'
     end
    end
   end,
  },
  { -- seed cannon
    [1]=44,
    [2]=49,
    c=0,
    inputhandler=function(_obj)
     sampleselectinputhandler(_obj)

     if _obj.inputlastframe == true and not btn(4) then
      _obj.inputlastframe=nil
      if #samples > 0 and #seed < 4 then
       add(seed,deli(samples,samplesel))
       sfx(14)
      elseif #seed == 4 then
       seed.score=getseedpoints()
       _obj.c=90
       sfx(12)
       if not droidalertc then
        droidalertc=300+flr(rnd(300))
       else
        droidalertc=mid(1,droidalertc-90,32000)
       end
      end
     end
    end,
    draw=function(_obj)
     if _obj.c > 0 then
      _obj.c-=1
      if _obj.c % 30 < 15 then
       sspr(89,115,13,7,42,73)
      end

      if _obj.c == 0 then
       lastseed=seed.score
       seedsshot+=1
       score+=seed.score
       seed.y=60
       sfx(13)
      end

      pset(43,75,11)

     elseif _obj.inrange and #seed == 4 and not seed.y then
      actiontitle='\x8e shoot seed'
      pset(43,75,11)
     elseif _obj.inrange and #samples > 0 then
      actiontitle='\x8e add sample'
     end

     if seed.y then
      if seed.y > 30 then
       sspr(104,122,6,6,47,57)
      end
      seed.y-=8
      pset(43,75,11)
     end

     drawseed(49,seed.y or 76,#seed == 4)

     if _obj.inrange then
      drawsamplecase(39,98,true)
     end

    end,
  },
  { -- elevator
   [1]=60,
   [2]=65,
   c=0,
   y=75,
   inputhandler=function(_obj)
    if btnp(3) then
     _obj.c=6
     guy.floor=1
     sfx(5)
    end
   end,
   draw=drawelevator,
  },
  { -- score tracker
   [1]=87,
   [2]=92,
   c=0,
   draw=function(_obj)
    if _obj.inrange then
     rectfill(19,11,109,50,5)
     print('highscore: '..tostr(score),23,14,9)
     line(19,22,109,22,0)
     print('total score: '..tostr(score),23,26,12)
     print('seeds: '..tostr(seedsshot),23,34,11)
     print('last seed: '..tostr(lastseed),23,42,6)
    end

    _obj.c-=1
    if _obj.c <= 0 then
     _obj.c=20
     _obj.blink=rnd{{88,74,9},{88,76,12},{88,78,12},{90,74,11},{90,76,11},{90,78,11}}
    end

    pset(unpack(_obj.blink))
   end,
  },
  { -- nav computer
   [1]=96,
   [2]=97,
   c=0,
   inputhandler=function(_obj)
    if btnp(4) then
     if fuel > 0 then
      if #sector.planets == 1 then
       traveling='warping'
      else
       traveling='orbiting'
       deli(sector.planets, 1)
      end
      travelc=60
     else
      -- sfx() -- todo: error sound
     end
    end
   end,
   draw=function(_obj)
    if fuel == 0 or droidalertc == 0 then
     pset(103,76,8)
    end
    if _obj.inrange and not traveling then
     rectfill(17,10,109,51,3)

     if fuel == 0 then
      _obj.c-=1
      if _obj.c <= 0 then
       _obj.c=16
      end
      if _obj.c % 16 > 8 then 
       print('no fuel',78,14,8)
      end
     end

     print('navcom',21,14,11)
     print('orbiting planet',21,23,11)

     if droidalertc == 0 then
      print('hostile ship near',21,32,8)
     end

     if #sector.planets > 1 then
      print('> orbit next planet',21,41,11)
     else
      print('> warp to next sector',21,41,11)
     end
    end
   end,
  },
  { -- door
   [1]=38,
   [2]=43,
   x=39,
   y=74,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=54,
   [2]=60,
   x=55,
   y=74,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=66,
   [2]=72,
   x=67,
   y=74,
   c=0,
   draw=drawdoor,
  },
  { -- door
   [1]=81,
   [2]=87,
   x=82,
   y=74,
   c=0,
   draw=drawdoor,
  },
 },
}

function shipinit()
 lookinginsamplecase=true
 pal({1,130,3,133,5,6,7,8,9,137,11,12,13,14,15},1)

 stars={}

 for i=1,30 do
  add(stars,{
   x=flr(rnd()*128),
   y=flr(rnd()*128),
   spd=rnd()+0.5,
   col=rnd{1,13}
  })
 end

 guy.x=37
 guy.y=91
 guy.floor=1 -- 0 space, 1 below, 2 deck

 actiontitle=''

 messages={
  c=30,
 }

 ts=t()

 camera()

 _update=shipupdate
 _draw=shipdraw
end

function shipupdate()
 
 if not traveling then
  if not btn(4) then
   if btn(0) then
    guy.x-=1
   elseif btn(1) then
    guy.x+=1
   end
  end

  if guy.floor > 0 then
   guy.x=mid(27,guy.x,97)

   guy.y=({91,80})[guy.floor]
  end

  actiontitle=''

  for _i=1,2 do
   local _floorobjs=shipobjs[_i]
   for _obj in all(_floorobjs) do
    if _i == guy.floor and isinsiderange(guy.x,_obj[1],_obj[2]) then
     if not _obj.inrange then
      _obj.firstframe=true
     else
      _obj.firstframe=nil
     end
     _obj.inrange=true
     if _obj.inputhandler then
      actiontitle=_obj.actiontitle or ''
      _obj.inputhandler(_obj)
     end
    else
     _obj.inrange=nil
    end
   end
  end

  -- update droid co
  updatedroidalert()

  -- update seed
  if seed.y then
   seed.y-=6
   if seed.y < 0 then
    seed={}
   end
  end

  -- update messages
  updatemessages()


 else -- traveling
  travelc-=1

  if travelc <= 0 then
   if traveling == 'warping' then
    fuel-=1
    droidalertc=nil
    nextsector()
   end

   if traveling == 'orbiting' then
    fuel-=1
   end

   if traveling == 'down' then
    traveling=nil
    travelc=0
    planetinit()
    return
   end

   traveling=nil
   travelc=0
  end
 end

 -- stars
 for _s in all(stars) do
  local _spd=fuel == 0 and 0.25 or 1
  if traveling == 'warping' or traveling == 'orbiting' then
   _spd=4
  end
  _s.x-=_s.spd*_spd
  if _s.x < 0 then
   _s.x=140
   _s.y=flr(rnd()*128)
  end
 end

end

function shipdraw()
 cls(0)

 if traveling == 'warping' then
  cls(1)
  if travelc == 1 then
   cls(7)
  end
 end

 -- draw stars
 for _s in all(stars) do
  if traveling == 'warping' then
   line(_s.x,_s.y,_s.x-10,_s.y,13)
  else
   pset(_s.x,_s.y,_s.col)
  end
 end

 -- draw planet
 if sector.planets[1] and traveling != 'warping' then
  local _x=64
  if traveling == 'orbiting' then
   _x+=travelc*2.5
  end
  circfill(_x,318,200,sector.planets[1].surfacecolor)
 end

 -- draw droid ship

 if droidalertc == 0 then
  sspr(79,16,49,12,8,25)
 elseif droidalertc == 1 then
  circfill(30,30,12,7)
 end

 -- draw ship
 sspr(0,91,89,37,21,57)

 -- draw shipobjs
 for _floorobjs in all(shipobjs) do
  for _obj in all(_floorobjs) do
   _obj.draw(_obj)
  end
 end

 -- draw guy
 if guy.floor > 0 then
  sspr(58,54,4,5,guy.x-2,guy.y-5)
 elseif guy.floor == 0 then
  sspr(66,54,4,5,guy.x-2,guy.y-5)
 end

 -- draw small ship
 if traveling == 'down' then
  rectfill(24,84,41,90,1)
  pset(26+(30-travelc),92+(30-travelc),6)
 end

 if traveling == 'up' then
  rectfill(24,84,41,90,1)
  pset(26+travelc,92+travelc,6)
 end

 -- draw actiontitle
 local _strlen=#actiontitle*4+5
 print(actiontitle,64-_strlen/2,32,9)

 -- draw message
 drawmessages()

end


_init=shipinit

__gfx__
e00eee0000eeeeeee00eeceeeeddeeeeeee4eeee0eeeeee0eeeeee000eeee000eeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000e00000000000000000000000e
e0d0e0aa990eeeee0cc0eeceeceeeee4eeceeee0c0eeee0c0eeee0ccc0ee0ccc0eeeeeeeeeeeeeeeeeeeeeeeeeee055555555500ddddddddddddddddddddddd0
e0dd0aaaaa900ee00cdd0ececeeeeeeececeeee0cc0eee0c0eee0cc9cc00ccdcc0eeeeeeeeeeeeeeeeeeeeeeeeee0ddddddddd00dd000d000d000d000d000dd0
05666666666660e0cddd0ececeeedddececeee0ccc10e0cc0eee09ccc100dccc10eeeeeeeeeeeeeeeeeeeeeeeeee0ddd000ddd00dd060d060d060d060d060dd0
05dddddddddd660eeeecee0eeeee0000000eeee0c10ee00cc0ee0ccca100ccc210eeeeeeeeeeeeeeeeeeeeeeeeee0ddd060ddd00ddddddddddddddddddddddd0
e00000000000000eeecee0200ee022222220ee0cc10eee0c10eee0c110ee0c110eeeeeeeeeeeeeeeeeeeeeeeeeee0ddddddddd00550505050505050505050550
eeeeeeeeeeeeeeeceecee0022002ddddddd200cc1110ee0c110eeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055505055500550505050505050505050550
eeeeeeeeeeeeeeeecece022eee0ddddddddd0e00200ee0cc100eee0cc0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055505055500550505050505050505050550
eeeeeeeeeeeeeeeeceeee000eee0dddddddd0ee020eee0cc110eee0cdc0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055505055500550505050505050505050550
eeeeeeee22222222222208880eee00ddddd0ee22eeee0ccc1110e0cddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055505055500555055505550555055505550
ee00ee00ee00ee00eeeee0f000eeee00000eeeeeeeee00cc1100e0cdddc0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055550555500555555555555555555555550
ee050050ee050050eeeee0f8880ee0000000eeeeeeeee0c1110e0cddccd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee055555555500ddddddddddddddddddddddd0
ee055550ee055550eeeee0f0f0ee044444440eee222e0cc111100cddddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000e00000000000000000000000e
e0556560e0556560eeeee000eee04222222240eeeeee00022000eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000e
0555555005555550eeee0ccc0ee02222222220eeeeeeee0220eeeeeee020eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee066666660
0555555005555550eeeee03000ee0222222220eeeeee00e0eeee0eee0210eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee060000060
0555555005555550eeeee03ccc0ee00222220ee0eee040040ee040e02110eeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111eeeeeeeeeeeeeee
05050050e050550eeeeee03030eeeee00000ee040e040ee040e020e021110eeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111eeeeeeeeeee
000e000eeeeeeeeeeeeee55eeeeeeeeeeeeeeee040020ee020040ee021110eeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111eeeeeeeee
0dd0dd0eee0eeeeeeeeeeeeeeeeeeeeeeeeeeee02040eeee0420ee0211120eeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111eeeeeee
e0ddd0eee0d0eeeeeeeeeeeeeeeeeeeeeeeeeeee020eeeeee040ee0211210eeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111eeeee
ee0d0eee0ddd0eeeeeeeeee555eeeeeeeeeeeeee040eeeeee040eeee0eeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111eee
eee0eeee0d0d0eeeeeeeeeeeeeeeeeeeeeeeeee04220eeee04220ee020eeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111111e
eeeeeeee00e00eeeeeeeeeeeeeeeeeeeeeeeeeeee0000eee000eee0210eeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eeeeeeeeeeeeeeee000eeeeeeeeeeeeeeeeeeeee0c0c00e04120e02110eeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eeee000eeeeeeee05550eeeeeeeeeeeeeeeeeee0c0c0500412220021110eeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111111e
e0e05550eeeeeee05055000eeeeeeeeeeeeeee0c0c050ee0000eeeeee0eeeeeeeeeeeeeeeeeeeeeeeeee11111111111111111111111111eeeeeeeeeeeeeeeeee
0e0050500eeeeee050500ee0eeeeeeeeeeeeee0c0c050e0cccc0eeee0300eeeeeeeeeeeeeeeeeeeeeeeee11111111111111111111eeeeeeeeeeeeeeeeeeeeeee
0ee0000dd0eeeee0000dd0eeeeeeeeeeeeeeee0c0c02220c5c5c0eee03030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0e09d90eeee0e009d90eeeeeeeeeeeeeeeeee000ee0cccccc0e003330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0ee0000eeee0eee000eeeeeeeeeeeeeeeeee04410eeee000ee030300eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0ee0eeee0ee0eeeeeeeeeeeeeeeeeeeeeeeee04120eee0440ee03330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeee0000eeeeeeeeeeeeeeeeeeeeeeee04120eeee04120ee0030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0e08aaa0ee08aaa0eeeeeeeeeeeeeeeeeeeeeeee02220ee041120eee030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e088bab00088bab0eeeeeeeeeeeeeeeeeeeeeeee04120ee04120eeee030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e088aaa0e088aaa0eeeeeeeeeeeeeeeeeeeeeee041220ee041120eeee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0888880e0888880eeeeeeeeeeeeeeeeeeeeee0411122004122220e0030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e000000ee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee030300eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0ee0e0eee00e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0333030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee003330eeeeeeeeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee077770eee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0300eeeeeeeeeeeeeeeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee078780ee077770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee030eeeeeeeeeeeeeeeeeeee1111eeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0777770ee078780eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee030eeeeeeeeeeeeeeeeeeeee1111eeeeeeee1eee11eeeeeee1eeeee1eeeeeeeeeeeeeeee
07778880e0777770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeee1eeee111eeeeee1eeee1eee1eeeeeeeeeeeee
0777888007778880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eee1111eee1111eee1e1ee1111ee11eeeeeeeeeeee
0777777007777770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111eeeeeeee1ee
07070070e070770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111eeeeee1eee
eee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111eee1111ee
ee0bbbb0eee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
e0bb7b7b0e0bbbbb0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
e0bbbbbb00bbb7b7b0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0dd0eeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
e0bbbbbb00bbbbbbb0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0dd50eeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111e
ee000000ee0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0dddd0eeeeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111111e
ee0000eeee0000eeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeee0dd7d50eeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111ee
e0dddd0ee0dddd0ee0dddd0eeeeeeeeeeeeeeeeeeeeeeeeeee0dd7dd0ee00ee00ee11eeeeeeeeeee111111111111111111111111111111111111111111111eee
e0d7d70ee0d7d70ee0d7d70eeeeeeeeeeeeeeeeeeeeeeeeee0ddd7d50e0ff00f901f91eeeeeeeeeeeeeee111111111111111111111111111111111111111eeee
e00ddd0eee0ddd0eee0ddd0eeeeeeeeeeeeeeeeeeeeeeeeee0d7d7dd0e0ff009901991eeeeeeeeeeeeeeeee111111e11111111eeeeeeeeeee1111111eeeeeeee
0d0000d0e000000ee000000eeeeeeeeeeeeeeeeeeeeeeeeee0d7d7dd500aa006601661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
050d00500d0d00d00d0d00d0eeeeeeeeeeeeeeeeeeeeeeee0dddd7ddd00aa006601661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
050500500505005005050050eeeeeeeeeeeeeeeeeeeeeeee07d5d7dd50eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0500ee050ee05005050050eeeeeeeeeeeeeeeeeeeeeeee0dd5d7ddd0eeeeeeeeeeeeee00eee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee000000eeeeeeeeeeeeeeeeeeeeeeee07ddd7dd50ee00eee00eeee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000000000000000000098890eeeeeeeeeeeeeeeeeeeeeeee0dd7d7ddd0e0ff0e0ff0eee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
098890098890098890e0dd0eeeeeeeeeeeeeeeeeeeeeeeee05d7dddd50e0ff0e0ff0eee0880e0880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0880ee0880ee0880ee0880eeeeeeeeeeeeeeeeeeeeeeeee05d7d7ddd00daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
005580085500005500005500eeeeeeeeeeeeeeeeeeeeeeee05d7d7d5500daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
08dd0ee0dd8008dd8008dd80eeeeeeeeeeeeeeeeeeeeeeee0dddddddd0eeeeeeeeeeeeeeeeeeeee11111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e050eeee050ee0550ee0550eeeeeeeeeeeeeeeeeeeeeeeee05d5d5d550eeeeeeeeeeeeeeeee1111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0eeeee0eeeee0eeeee0eeeeeeeeeeeeeeeeeeeeeeeeee0dd555dd0eeeeeeeeeeeeeee1111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeeee
e0000ee0000ee0000ee0000eeeeeeeeeeeeeeeeeeeeeeeee055555550eeeeeeeeeeeeee111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeeee
07666007666007666007bb60eeeeeeeeeeeeeeeeeeeeeeee055555550eeeeeeeeeeeee11111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeeee
06bb6006bb6006bb6006bb60eeeeeeeeeeeeeeeeeeeeeeee055050550eeeeeeeeeeee1111111111111111111111111111111111eeeeeeeeeeeeeeeeeeeeeeeee
06bb6006bb6006bb60065560eeeeeeeeeeeeeeeeeeeeeeeee0000000eeeeeeeeeeeee1111111111111111111111111111111111eeeeeeeee00000eeeeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111eeeeeeeee0ddddd00eeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeee1111111111111111111111eeeeeeeeeeeee0d66666dd0eeeeeeed
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0bbb770eeeeeeeeeeeeeeeee11111111111111eeeeeeeeeeeeeeee0d6d000d6dd0eeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000bbbbbb7000eeeeeeeeeeeeeee111111111111eeeeeeeeeeeeeeee0d6d07bb0d6dd0eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00d60bbbbbbb06d00eeeeeeeeeeeeee1111111111eeeeeeeeeeeeeeeee0dd07bbbb0d6d0eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0d6dd600000006dd6d0eeeeeeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeeed0bbbbb0d6d0eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0dd6dd6666666dd6dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeeeebb0dddd0eeddee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00d66ddddddd66d00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee08880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000085550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6e60eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee066d0555588880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee06bb000e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee06ddd0588588880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbb06bbddd0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee06dddd05555888850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000055000000850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0885555550888850850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeee
444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0090000e
42444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888080885850
e424424444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeeeeeeeeeeeeeee
e42444244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee424442444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888eeeeeeeeeee
ee42444424444444eeeeeeeeee244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee424444244444444eeeeeeeee2222eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee42444442444444444eeeeeee2444eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee424444424444444444eeeee2444eeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee42444444222222222222ee222222eeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee44244422444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee4424224442222222222222222222222222222222222222222222444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee4444444224444444444444444444444444444444444444444444222444444222222222444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee44222222222222244444444444444444442222222224442222222222224442200000000000444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee4422000000000002242222222222222224220000000224220000000000224220eeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e5422011111111111022200000000000002220111111102220111111111102220eeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
54420111111111111104011111111111110401111d1111040110011118111040ee00000eeeee0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
4542011100001110110401111110000111040110000011040109901000001040e05d5350eeee033330e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
55420110dddd0105010401111105555011040110555011040109901055501040e0555550eeee033330000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44420110cccc0105010401111105555011040110555011040111111055501040e05d5350eeee033335b500eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
55420110dddd0105010401551105555011040110555011040106601055501040e0555550ee00033335550e0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
45420110cccc0105010401551105555011040110555011040106601055501040e05d5350ee05555555550222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
54422010dddd0105010401111110440111040110555011040111111055501040e0555550ee055555522222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e5442222222222222222222222222222222222222222222222222222222222222222222222222222244444442eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee442224444444444444444442222222244444444444444444444444444444444444444444444444444444228888888888888eeeeeeeeeeeeeeeeeeeeeeeeee
eee4442222222222222222224220000002242222222222242222222222222222222224222222222444444422e888888eeee888eeeeeeeeeeeeeeeeeeeeeeeeee
eee0000000000000000000022201111110222000000000222000000000000000000022200000002222222422e88888eeeeee88cccceeeeeeeeeeeeeeeeeeeeee
eee50111111111111111110040110000110401111d111104011111111111111111110401151511024444422ee88888eeeeee88ddddeeeeeeeeeeeeeeeeeeeeee
eee5011111100001110011104010d6dd0104011000001104011111111111111111110401151511022224222ee88888eeeeee88cccceeeeeeeeeeeeeeeeeeeeee
eee501111109999010d0111040100dd0010401105550110401111111111111111111040115151102444222eee88888eeeeee88ddddeeeeeeeeeeeeeeeeeeeeee
eee50111009999990dd011104010400401040110555011040100000100000100000104010000010244222eeee888888eeee888cccceeeeeeeeeeeeeeeeeeeeee
eee501106666666666650110401044440104011055501104010ddd01055d01055d010401055501024222eeeee101eeeeeeeee9eeee6eeeeeeeeeeeeeeeeeeeee
eee501066dddddddddd501104010444401040110555011040105550105d50105d501040105550102222eeeeee101eeeeeeee999eee6e6eeeeeeeeeeeeecccccc
eee501000000000000001110401004400104011055501104010555010d55010d550104010555022222eeeeeee101110001199999ee6eeeeeeeeeeeeccccccc66
eee22222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeee1011099901e999ee66e6eeeeeeeeccc6c66c666
eeee2222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeee1011109990e999ee6666eeeeeeeeeeccccccc66
eeeeeeeeee22222222eee22222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeeeeeeeeeeeeeeeeee1010000990eaaae455555eeeeeeeeeeeecccccc
__sfx__
000200001e5501f550205501f5501f5501f5502355000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000200001f550165502155023550245501c5502155024550000002155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002155021550295502555026550255502755024550215501f55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000011010110101301016010190101e010210102500028000280002d0003c0003c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000074200742007420074200a4200c4200f420114201442017420194201d4202042022420004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0002000023420214201e4201b4201742014420104200d420094200642005420054200542005420054000540000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000562019600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060011600006000060000600006000060000600
000500002e610146002a6102a61000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060011600006000060000600006000060000600
00020000167501675013750137501175011750177001675016750187501b7501b7501f750297503075033750007003370029700227001f70033750337001d7001d7001d7001d7003375033700000000000000000
000100001e0101e0101d0101d0101c0101b0101b0101a0101a01019010180101701016010150101401013010110100f0100d0100c0100a01009010070100501004010020100a0000d00000000000000000000000
000300000241002410024100241000410004100041000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000400000241000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
003c00002230022330223002233022300223302230000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000500003f6603565030640276401e63018620126200f6200d6200b62009620086200762007620066200662005620046200362003620036200262002620026200160000610016000061001600006100160000610
000800001f4203a4202e40033400244002b4003c4002040037400394003c4003f40009400064000540003400004000940006400074000b4000c4000b400084000040000400004000040000400004000040000400
000400003544027440304401f44024440164400f440134300c4300743000430004200040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
