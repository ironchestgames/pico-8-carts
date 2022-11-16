pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- the panspermia guy 1.0
-- by ironchest games

cartdata'ironchestgames_thepanspermiaguy_v1-dev1'

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable auto-repeat for btnp

-- note: set special char o-button to look like c-button if gpio 1 is set, pico8_gpio[0]=1 in js
poke(0x8e*8+0x5602,peek(0x5f80) == 0 and 107 or 123)
-- poke(0x8e*8+0x5602,123)

-- pink as transparent
palt(14,true)
palt(0,false)

-- function s2t(_s)
--  local _t={}
--  local _key=''
--  local _value=''
--  local _i=1
--  local _mode='search'

--  repeat
--   local _c=_s[_i]

--   if _c == '{' then
--    -- todo
--   elseif _c == '$' then
--    _mode='key'
--    _key=''
--   elseif _c == '=' then
--    _mode='value'
--    _value=''
--   elseif _c == ',' or _c == '}' then
--    _mode='kvpairend'
--   end

--   debug('char "'.._c..'"  mode: '.._mode..' key: '.._key..' value: '.._value)
  
--   if _mode == 'search' then
--   elseif _mode == 'kvpairend' then
--    _value=tonum(_value) or _value
--    _t[_key]=_value
--    _mode='search'
--   elseif _mode == 'key' and _c != '$' then
--    _key=_key.._c
--   elseif _mode == 'value' and _c != '=' then
--    _value=_value.._c
--   end

--   _i+=1

--   debug('char "'.._c..'"  mode: '.._mode..' key: '.._key..' value: '.._value)
--   debug('---')
--  until _i == #_s+1

--  debug(_t['12'])
--  debug(_t.b)

--  return _t
-- end

-- -- debug(s2t'{ $a=1,$b=2}')
-- -- debug(s2t'{ $12=1,$b=2}')
-- debug(s2t'{ 14,3,43,22 }')

function trimsplit(_str)
 local _newstr,_result='',{}
 for _i=1,#_str do
  local _chr=_str[_i]
  if _chr != ' ' and _chr != '\n' then
   _newstr..=_chr
  end
 end
 return split(_newstr)
end

function clone(_t)
 local _result={}
 for _k,_v in pairs(_t) do
  _result[_k]=_v
 end
 return _result
end

function dist(_x1,_y1,_x2,_y2)
 local _dx,_dy=(_x2-_x1)*.1,(_y2-_y1)*.1
 return sqrt(_dx*_dx+_dy*_dy)*10
end

function sortbyy(_t)
 for _i=1,#_t do
  local _j=_i
  local _y1=_t[_j].y
  if _t[_j].ground then
   _y1=-1
  end
  while _j > 1 and _t[_j-1].y > _y1 do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
 return _t
end

function wrap(_min,_n,_max)
 return (((_n-_min)%(_max-_min))+(_max-_min))%(_max-_min)+_min
end

function drawmessages()
 if #messages > 0 then
  local _strlen=#messages[1]*4
  local _y=guy.y-36
  local _x=mid(0,guy.x-_strlen/2,128-_strlen/2)
  local _x2=_x+_strlen+2
  rectfill(_x,_y,_x2,_y+8,7)
  line(guy.x,_y,guy.x,guy.y-7,7)
  print(messages[1],_x+2,_y+2,0)
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
   sspr(99,85,5,6,_lx-2,_y+15)
  end
 end
end

function updatefactionalerts()
 for _,_faction in pairs(factions) do
  if _faction.alertc and _faction.alertc > 0 then
   local _prevalertc=_faction.alertc

   _faction.alertc-=1

   if _faction.alertc == 0 then
    if _faction == factions.droid and _prevalertc != 0 then
     sfx(21,2)
    end
   end
  end
 end
end

function resetgame()
 -- note: global vars
 sector={
  planets={},
 }
 guy={incryo=true}

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


 factions={
  droid={
   alertc=nil,
   shipsx=79,
   shipsy=16,
   shipsw=49,
   shipsh=12,
   shipx=73,
   shipy=15,
   landingx=128,
   landingy=128,
   landingc=nil,
   talkingc=nil,
   firingc=nil,
   talkcol=7,
   talkbgcol=13,
   talkstr='stop spreading life',
   talksfx=29,
   alien={
    sx=16,
    sy=53,
    sw=8,
    sh=8,
    sightradius=128,
    spd=0,
    huntingspd=2,
    c=0,
    alientype='droid',
    bloodtype='droidblood',
    behaviour=droidtalking,
   },
  },
 }

 deaddrawies={}

 particles={}

 resetshipobjs()
end

-- global constants
floorys={91,80}

function closetrap(_trap)
 _trap.action=pickuptrapaction
 _trap.sy=49
 _trap.sw=4
 _trap.sh=4
end

takesampleaction={
 title='take sample',
 func=function (_target)
  if #samples == 5 then
   add(messages,'sample case is full')
  else
   _target.action=nil
   add(samples,_target.samplecolor)
   guy.samplingc=20
   sector.planets[1].haswreck=nil
   sfx(8)
  end
 end,
}

pickuptrapaction={
 title='pick up trap',
 func=function (_obj)
  del(sector.planets[1].mapobjs,_obj)
  _obj.sy=46
  _obj.sw=7
  _obj.sh=3
  guy.trap=_obj
 end,
}

function trapbehaviour(_behaviouree)
 local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
 if guy.runningc > 0 and _disttoguy < 2 then
  local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
  local _drawies={guy,_behaviouree}
  resetplanetcamera(_drawies)
  deadinit(_drawies)
  return true
 end

 for _other in all(sector.planets[1].animals) do
  if _other != _behaviouree and dist(_behaviouree.x,_behaviouree.y,_other.x,_other.y) < 4 then
   -- kill animal
   del(sector.planets[1].animals,_other)
   local _blood=clone(objtypes[_other.bloodtype])
   _blood.x=_other.x
   _blood.y=_other.y
   add(sector.planets[1].mapobjs,_blood)
   sfx(33)

   -- close trap
   closetrap(_behaviouree)
   del(sector.planets[1].animals,_behaviouree)
   add(sector.planets[1].mapobjs,_behaviouree)
   break
  end
 end
end

function martiantalking(_behaviouree)
 local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
 
 if _disttoguy < 32 then

 end
end

function droidtalking(_behaviouree)
 if factions.droid.talkingc <= 0 then
  _behaviouree.behaviour=sighthunting
 end
end

function sighthunting(_behaviouree)
 local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
 local _disttotarget=dist(_behaviouree.x,_behaviouree.y,_behaviouree.targetx,_behaviouree.targety)
 local _prevhunting=_behaviouree.hunting
 _behaviouree.hunting=nil

 if _disttoguy < _behaviouree.spd + 0.5 then
  local _drawies={guy,_behaviouree}
  resetplanetcamera(_drawies)
  deadinit(_drawies)
  return true

 elseif _disttoguy < _behaviouree.sightradius then
  _behaviouree.targetx=guy.x
  _behaviouree.targety=guy.y
  if _behaviouree.alientype == 'droid' and not _prevhunting then
   add(messages,rnd{'yikes','eek','uh-oh'})
  end
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
 trap={
  sx=26,
  sy=49,
  sw=4,
  sh=4,
  behaviour=trapbehaviour,
 },
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
 firegnawer={
  sx=0,
  sy=76,
  sw=8,
  sh=8,
  sightradius=48,
  spd=0.75,
  huntingspd=1.25,
  c=0,
  bloodtype='fireblood',
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
  bloodtype='deadmartianblood',
 },
 droid={
  sx=16,
  sy=53,
  sw=8,
  sh=8,
  sightradius=128,
  spd=0,
  huntingspd=2,
  c=0,
  bloodtype='droidblood',
 }
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
 flowers2={
  sx=16,
  sy=18,
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
  solid=true,
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
  solid=true,
  samplecolor=6,
  action=takesampleaction,
 },
 pine_big={
  sx=44,
  sy=0,
  sw=8,
  sh=15,
  solid=true,
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
  solid=true,
 },
 deadtree2={
  sx=46,
  sy=15,
  sw=8,
  sh=8,
  solid=true,
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
 marsh_flipped={
  sx=24,
  sy=22,
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
  solid=true,
 },
 rock_medium={
  sx=61,
  sy=13,
  sw=7,
  sh=8,
  solid=true,
 },
 rock_medium2={
  sx=60,
  sy=6,
  sw=8,
  sh=7,
  solid=true,
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
  solid=true,
 },
 canyon_medium={
  sx=46,
  sy=30,
  sw=8,
  sh=7,
  solid=true,
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
  solid=true,
  samplecolor=13,
  action=takesampleaction,
 },
 cactus2={
  sx=54,
  sy=35,
  sw=7,
  sh=8,
  solid=true,
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
 crack_big={
  sx=30,
  sy=18,
  sw=8,
  sh=5,
  ground=true,
 },
 crack_small={
  sx=30,
  sy=36,
  sw=8,
  sh=4,
  ground=true,
 },
 lavapool_big={
  sx=27,
  sy=29,
  sw=11,
  sh=7,
  solid=true,
  ground=true,
 },
 lavapool_small={
  sx=30,
  sy=23,
  sw=8,
  sh=6,
  solid=true,
  ground=true,
 },
 fireblood={
  sx=61,
  sy=21,
  sw=10,
  sh=7,
  ground=true,
  samplecolor=10,
  action=takesampleaction,
 },
 droidblood={
  sx=61,
  sy=28,
  sw=10,
  sh=7,
  ground=true,
  samplecolor=7,
  action=takesampleaction,
 },
 deadmartian={
  sx=45,
  sy=41,
  sw=8,
  sh=4,
  offx=-17,
  offy=2,
 },
 deadmartianblood={
  sx=35,
  sy=41,
  sw=10,
  sh=7,
  offx=-26,
  offy=1,
  ground=true,
  samplecolor=11,
  action=takesampleaction,
 },
 martianwreck_ground={
  sx=42,
  sy=50,
  sw=21,
  sh=9,
  offx=2,
  offy=-2,
  ground=true,
 },
 martianwreck_collision={
  sx=44,
  sy=50,
  sw=5,
  sh=4,
  offx=-1,
  offy=0,
  solid=true,
 },
 martianwreck={
  sx=63,
  sy=48,
  sw=14,
  sh=8,
  linked=trimsplit'deadmartian,deadmartianblood,martianwreck_ground,martianwreck_collision',
 },
 taurienwreck_wing={
  sx=43,
  sy=78,
  sw=5,
  sh=4,
  offx=-9,
  offy=-6,
 },
 taurienwreck_ground={
  sx=42,
  sy=82,
  sw=9,
  sh=7,
  offx=-8,
  offy=-2,
  ground=true,
 },
 deadtaurien={
  sx=26,
  sy=41,
  sw=9,
  sh=3,
  offx=-18,
  offy=2,
 },
 deadtaurien_blood={
  sx=16,
  sy=43,
  sw=10,
  sh=4,
  offx=-27,
  offy=3,
  ground=true,
  samplecolor=8,
  action=takesampleaction,
 },
 taurienwreck={
  sx=49,
  sy=78,
  sw=10,
  sh=9,
  linked=trimsplit'taurienwreck_wing,taurienwreck_ground,deadtaurien,deadtaurien_blood',
 },
 droidpillar1={
  sx=68,
  sy=0,
  sw=9,
  sh=7,
  solid=true,
 },
 droidpillar2={
  sx=77,
  sy=0,
  sw=6,
  sh=5,
  solid=true,
 },
 droidpillar3={
  sx=68,
  sy=7,
  sw=9,
  sh=6,
  solid=true,
 },
 droidpillar4={
  sx=68,
  sy=13,
  sw=9,
  sh=7,
  solid=true,
 },
 droidpillar5={
  sx=83,
  sy=0,
  sw=9,
  sh=13,
  solid=true,
 },
 droidpillar6={
  sx=77,
  sy=5,
  sw=6,
  sh=4,
  solid=true,
 },
}

planettypes={
 { -- light forest
  wpal={3,141,0,135,139},
  surfacecolor=3,
  objtypes=trimsplit[[
   berrybush,
   flowers,
   mushroom_red,
   mosstone_small,
   mosstone_big,
   marsh_watercolor,
   grass1,
   grass2,
   lake_watercolor,
   pine_small,
   pine_small,
   pine_big,
   pine_big,
   pine_big
  ]],
  animaltypes=trimsplit'bear,bat',
  objdist=16,
 },
 { -- dark forest
  wpal=trimsplit'131,141,134,135,3',
  surfacecolor=3,
  objtypes=trimsplit[[
   pine_big,
   pine_big,
   pine_big,
   pine_big,
   pine_small,
   pine_small,
   grass1,
   grass2,
   marsh_watercolor,
   marsh_watercolor,
   marsh_watercolor,
   mosstone_small,
   mosstone_small,
   mosstone_big,
   mosstone_big,
   lake_watercolor,
   twigs,
   twigs,
   mushroom_red,
   flowers
  ]],
  animaltypes=trimsplit'bear,bat,bat',
  objdist=24,
 },
 { -- marsh
  wpal=trimsplit'133,130,134,141,131',
  surfacecolor=4,
  objtypes=trimsplit[[
   grass1,
   grass1,
   grass1,
   grass1,
   grass2,
   grass2,
   grass2,
   grass2,
   deadtree1,
   deadtree2,
   lake,
   berrybush,
   mushroom,
   marsh_darkgrey,
   marsh_darkgrey,
   marsh_darkgrey,
   marsh_darkgrey,
   marsh_darkgrey,
   marsh_darkgrey
  ]],
  animaltypes=trimsplit'spider,spider,spider,bat',
  objdist=26,
 },
 { -- ice
  wpal=trimsplit'7,6,6,7,7',
  surfacecolor=7,
  objtypes=trimsplit[[
   deadtree1,
   deadtree2,
   lake,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   rock_small,
   rock_small,
   rock_small,
   rock_small,
   rock_small,
   rock_small,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big
  ]],
  animaltypes=trimsplit'gnawer,gnawer',
  objdist=18,
 },
 { -- wasteland 1
  wpal=trimsplit'4,132,141,9,15',
  surfacecolor=9,
  objtypes=trimsplit[[
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   cactus1,
   cactus2,
   skull,
   ribs,
   canyon_big,
   canyon_big,
   canyon_medium,
   canyon_medium,
   canyon_small,
   canyon_small
  ]],
  animaltypes=trimsplit'bull,bull',
  objdist=30,
 },
 { -- wasteland 2
  wpal=trimsplit'134,141,141,15,6',
  surfacecolor=6,
  objtypes=trimsplit[[
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   skull,
   ribs,
   canyon_big,
   canyon_big,
   canyon_medium,
   canyon_medium,
   canyon_small,
   canyon_small,
   canyon_small,
   canyon_small
  ]],
  animaltypes=trimsplit'gnawer,gnawer',
  objdist=30,
 },
 { -- desert
  wpal=trimsplit'15,143,3,8,3',
  surfacecolor=9,
  objtypes=trimsplit[[
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   marsh,
   flowers,
   cactus1,
   cactus2
  ]],
  animaltypes=trimsplit'spider,spider',
  objdist=30,
 },
 { -- blue lava world
  wpal=trimsplit'1,133,12,137,131',
  surfacecolor=1,
  objtypes=trimsplit[[
   flowers2,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium2,
   rock_medium2,
   rock_medium2,
   rock_medium2,
   rock_medium2,
   rock_medium2,
   rock_medium2,
   rock_small,
   rock_small,
   rock_small,
   crack_big,
   crack_big,
   crack_big,
   crack_big,
   crack_big,
   crack_big,
   crack_small,
   crack_small,
   crack_small,
   crack_small,
   lavapool_big,
   lavapool_small,
   lavapool_small
  ]],
  animaltypes=trimsplit'slime,slime,slime',
  objdist=24,
 },
 { -- dark lava world
  wpal=trimsplit'130,2,10,136,134',
  surfacecolor=2,
  objtypes=trimsplit[[
   flowers2,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_big,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_medium,
   rock_small,
   rock_small,
   rock_small,
   crack_big,
   crack_big,
   crack_big,
   crack_big,
   crack_small,
   crack_small,
   crack_small,
   crack_small,
   crack_small,
   lavapool_big,
   lavapool_big,
   lavapool_big,
   lavapool_small,
   lavapool_small,
   lavapool_small,
   lavapool_small,
   lavapool_small
  ]],
  animaltypes=trimsplit'firegnawer,firegnawer',
  objdist=18,
 },
 { -- red lava world
  wpal=trimsplit'2,130,142,136,143',
  surfacecolor=2,
  objtypes=trimsplit[[
   cactus1,
   cactus1,
   cactus2,
   cactus2,
   lavapool_big,
   lavapool_small,
   lavapool_small,
   skull,
   ribs,
   canyon_small,
   canyon_small,
   canyon_medium,
   canyon_medium,
   canyon_medium,
   canyon_medium,
   canyon_big,
   canyon_big,
   canyon_big,
   canyon_big,
   marsh_flipped,
   marsh_flipped
  ]],
  animaltypes=trimsplit'bull,bull,bull,bull',
  objdist=20,
 },
 { -- blue marsh world
  wpal=trimsplit'140,12,15,3,139',
  surfacecolor=1,
  objtypes=trimsplit[[
   marsh_flipped,
   marsh_flipped,
   marsh_flipped,
   marsh_flipped,
   marsh_flipped,
   marsh_flipped,
   mushroom,
   flowers2,
   berrybush,
   grass1,
   grass1,
   grass2,
   grass2,
   lake
  ]],
  animaltypes=trimsplit'gnawer,gnawer,slime,slime,slime,slime',
  objdist=24,
 },
 { -- brown wasteland
  wpal=trimsplit'132,130,139,4,143',
  surfacecolor=4,
  objtypes=trimsplit[[
   marsh,
   marsh,
   marsh,
   marsh,
   mushroom_red,
   flowers2,
   flowers2,
   cactus1,
   cactus1,
   cactus2,
   cactus2,
   canyon_big,
   canyon_big,
   canyon_big,
   canyon_big,
   canyon_medium,
   canyon_medium,
   canyon_medium,
   canyon_medium,
   canyon_medium,
   canyon_small,
   canyon_small,
   canyon_small,
   skull,
   ribs
  ]],
  animaltypes=trimsplit'bull,bull,bull,bull,bull,bull',
  objdist=26,
 },
 { -- droid world
  wpal=trimsplit'133,130,1,1,1',
  surfacecolor=13,
  objtypes=trimsplit[[
   marsh,
   droidpillar1,
   droidpillar2,
   droidpillar3,
   droidpillar4,
   droidpillar5,
   droidpillar6
  ]],
  -- animaltypes={'bull'},
  animaltypes=trimsplit'droid,droid,droid,droid,droid,droid,droid,droid,droid,droid',
  objdist=18,
  droidworld=true,
 },
}

mapsize=255


function createplanet(_planettype)
 -- _planettype=planettypes[13] -- debug
 _planettype=planettypes[5] -- debug
 local _rndseed=rnd()
 srand(_rndseed)

 local _wpal={
  _planettype.wpal[1],
  _planettype.wpal[2],
  _planettype.wpal[3],
  _planettype.wpal[4],
  5,6,7,136,9,137,138,
  _planettype.wpal[5],
  13,14,15}

 local _mapobjs={
  { -- player ship
   x=mapsize/2,
   y=mapsize/2-10,
   sx=0,
   sy=0,
   sw=15,
   sh=7,

   action={
    title='go back to ship',
    func=function()
     traveling='up'
     travelc=30
     sfx(27)
     for _a in all(sector.planets[1].animals) do
      if _a.alientype == 'droid' then
       del(sector.planets[1].animals,_a)
      end
     end
     shipinit()
     return true
    end,
   }
  },
 }

 local _tooclosedist=_planettype.objdist

 for _i=1,70 do
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

   if _tries > 10 then
    break
   end

  until _tooclose == nil

  -- debug(#_planettype.objtypes)
  -- debug(rnd(_planettype.objtypes))
  if _tries <= 10 then
   local _obj=clone(objtypes[rnd(_planettype.objtypes)])
   _obj.x=_x
   _obj.y=_y

   add(_mapobjs,_obj)
  end
 end

 debug(#_mapobjs)

 local _animals={}
 local _loops=min(5+flr(score/100),50)
 for _i=1,_loops do
  if rnd() < 1 - 1 / #_planettype.animaltypes then
   local _typ=rnd(_planettype.animaltypes)
   local _animal=clone(animaltypes[_typ])
   _animal.x=flr(rnd(mapsize))
   _animal.y=flr(rnd(mapsize))
   if dist(mapsize/2,mapsize/2,_animal.x,_animal.y) > 60 then
    _animal.targetx=_animal.x
    _animal.targety=_animal.y
    _animal.typ=_typ
    _animal.bloodtype=_animal.bloodtype or 'deadtaurien_blood'
    _animal.behaviour=sighthunting
    add(_animals,_animal)
   end
  end
 end

 -- add wreck
 local _haswreck=nil
 if rnd() > 0.85 then
  local _x=rnd(mapsize-_tooclosedist)
  local _y=rnd(mapsize-_tooclosedist)

  local _wrecktype=rnd{'martianwreck','taurienwreck'}

  local _wreck=clone(objtypes[_wrecktype])
  _wreck.x=_x
  _wreck.y=_y
  add(_mapobjs,_wreck)

  for _name in all(_wreck.linked) do
   local _linkedobj=clone(objtypes[_name])
   _linkedobj.x=_x+_linkedobj.offx
   _linkedobj.y=_y+_linkedobj.offy
   add(_mapobjs,_linkedobj)
  end

  if _wrecktype == 'taurienwreck' and rnd() > 0.75 then
   local _trap=clone(animaltypes.trap)
   _trap.x=_x-32
   _trap.y=_y
   closetrap(_trap)
   add(_mapobjs,_trap)
  end

  _haswreck=true
 end

 return {
  rndseed=_rndseed,
  mapobjs=_mapobjs,
  wpal=_wpal,
  surfacecolor=_planettype.surfacecolor,
  animals=_animals,
  haswreck=_haswreck,
  droidworld=_planettype.droidworld,
 }
end

function nextsector()
 sfx(-1,2)

 for _,_faction in pairs(factions) do
  _faction.alertc=nil
  _faction.firingc=nil
 end

 local _planetcount=rnd(trimsplit'1,2,2,2,3,3')

 sector={
  planets={}
 }

 for _i=1,_planetcount do
  add(sector.planets,createplanet(rnd(planettypes)))
 end

end

-- planet scene

function resetplanetcamera(_drawies)
 camera()

 local _diffx=_drawies[2].x-guy.x
 local _diffy=_drawies[2].y-guy.y
 _drawies[2].x-=_diffx+62
 _drawies[2].y-=_diffy+62

 guy.x=62
 guy.y=65
end

function planetinit(_planetid)
 lookinginsamplecase=nil

 factions.droid.landingc=180
 factions.droid.talkingc=140

 guy.x=mapsize/2
 guy.y=mapsize/2

 guy.sx=0
 guy.sy=85
 guy.sw=6
 guy.sh=6

 guy.spd=1
 guy.talkingc=0
 guy.walkingc=0
 guy.runningc=0
 guy.walksfx=6
 guy.samplingc=0

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

 guy.sx=0

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
   guy.sx=6
  elseif btn(3) then
   _movey-=_spd
   guy.sx=0
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
   guy.runningc=0
  end

  lookinginsamplecase=nil

  if guy.runningc > 30 and not guy.panting then
   messages[1]=rnd(trimsplit'*pant pant,*huff puff,*wheeeeze')
   guy.panting=true
  end

  if guy.runningc > 0 then
   for _obj in all(sector.planets[1].mapobjs) do
    if _obj.solid and dist(guy.x-_movex,guy.y-_movey,_obj.x,_obj.y) < _obj.sw * 0.5 then
     _movex*=-3
     _movey*=-3
     guy.panting=true
     guy.runningc=24
     messages[1]=rnd(trimsplit'ouch,ouf,argh,ow,owie')
     sfx(rnd{16,17})
    end
   end
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

 for _,_faction in pairs(factions) do
  _faction.landingx=wrap(0,_faction.landingx+_movex,mapsize)
  _faction.landingy=wrap(0,_faction.landingy+_movey,mapsize)
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
  elseif guy.trap then
   local _trap=guy.trap
   guy.trap=nil
   _trap.x=guy.x
   _trap.y=guy.y
   _trap.targetx=guy.x
   _trap.targety=guy.y
   add(sector.planets[1].animals,_trap)
   sfx(34)
  else
   guy.talkingc=8
   sfx(rnd{0,1,2})
  end
 end

 guy.talkingc-=1
 guy.samplingc-=1

 if guy.talkingc > 0 then
  guy.sx=12
 end

 if guy.sunken then
  guy.sy=84
 else
  guy.sy=85
 end

 -- update factions
 updatefactionalerts()

 for _,_faction in pairs(factions) do
  if _faction.alertc == 0 then
   if _faction.landingc > 0 then
    _faction.landingc-=1

    if _faction.landingc == 0 then
     local _alien=clone(_faction.alien)
     _alien.x=_faction.landingx+16
     _alien.y=_faction.landingy+16
     _alien.targetx=_faction.landingx+16
     _alien.targety=_faction.landingy+16
     add(sector.planets[1].animals,_alien)
     sfx(_faction.talksfx)
    end

   elseif _faction.talkingc > 0 then
    _faction.talkingc-=1
   end
  end
 end

 -- update animals
 for _animal in all(sector.planets[1].animals) do
  if _animal.behaviour(_animal) then
   return
  end
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

 -- draw faction ship
 for _factionname,_faction in pairs(factions) do
  if _faction.alertc == 0 then
   local _y=_faction.landingy-_faction.landingc
   local _sh=24
   if _faction.landingc == 0 then
    _sh=26
   end
   sspr(32,52,10,_sh,_faction.landingx,_y)
  end

  -- draw alien talk
  if _faction.landingc == 0 and _faction.talkingc > 20 and _faction.talkingc < 140 then
   local _alien
   for _a in all(sector.planets[1].animals) do
    if _a.alientype == _factionname then
     _alien=_a
     break
    end
   end
   local _strlen=#_faction.talkstr*4
   local _y=_alien.y-36
   rectfill(_alien.x-_strlen/2,_y,_alien.x+_strlen/2+2,_y+8,_faction.talkbgcol)
   line(_alien.x,_y,_alien.x,_alien.y-12,_faction.talkbgcol)
   print(_faction.talkstr,_alien.x+2-_strlen/2,_y+2,_faction.talkcol)
  end
 end

 -- draw guy action
 if guy.action then
  local _strlen=#guy.action.title*4+14
  local _targetx=guy.action.target.x
  local _y=guy.action.target.y-22
  rectfill(_targetx-_strlen/2,_y,_targetx+_strlen/2,_y+8,0)
  line(_targetx,_y,_targetx,guy.action.target.y-guy.action.target.sh-2,0)
  print('\014\x8e\015 '..guy.action.title,_targetx+2-_strlen/2,_y+2,9)
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
  sfx(26)
 end
 if _obj.inrange then
  sspr(89,85,3,6,_obj.x,_obj.y)
  _obj.c=6
 else
  -- if _obj.c == 6 then
  --  sfx(10)
  -- end
  _obj.c-=1
  if _obj.c > 0 then
   local _d=(6-_obj.c)
   sspr(89,85,3,6-_d,_obj.x,_obj.y+_d)
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

  actiontitle='\x94\x83 elevator'

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

  if _obj.broken then
   -- todo: add sfx
   return
  end
  local _index=_obj.index
  if storages[_index] != nil and #samples < 5 then
   add(samples,storages[_index])
   storages[_index]=nil
   sfx(14)
  elseif storages[_index] == nil and #samples > 0 then
   storages[_index]=deli(samples,samplesel)
   sfx(14)
  end
 end
end

function storagedraw(_obj)
 if _obj.inrange then
  local _index=_obj.index
  
  actiontitle='sample storage'
  
  if _obj.broken then
   showbrokentitle=true
   storages[_index]=nil
   return
  end

  local _showsamplecasearrow=nil

  local _x=_obj[1]-4
  sspr(92,0,11,13,_x,98)

  if storages[_index] != nil and #samples < 5 then
   actiontitle='\014\x8e\015 take sample'
   sspr(99,85,5,6,_x+3,113)
  elseif storages[_index] == nil and #samples > 0 then
   actiontitle='\014\x8e\015 store sample'
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
 [6]=1, -- stonish
 [15]=1, -- sandish
 [9]=2, -- orange
 [13]=2, -- water
 [10]=2, -- bloody orange / taurien blood
 [8]=10, -- taurien blood
 [11]=12, -- mars blood
 [7]=10, -- droid blood
}

function getseedquality()
 local _result=0
 local _samples=clone(seed)

 local _kinds={}

 for _color=1,15 do
  local _value=samplecolorvalues[_color]
  if _value then
   while del(_samples,_color) do
    _result+=_value
    if count(_kinds,_color) == 0 then
     add(_kinds,_color)
    end
   end
  end
 end

 if #_kinds == 4 then
  _result+=12
 end

 return _result
end

function resetshipobjs()
 shipobjs={
  { -- floor 1
   { -- elevator
    60,65,
    c=0,
    y=86,
    inputhandler=function(_obj)
     if btnp(2) then
      if not (_obj.broken and rnd() < 0.5) then
       _obj.c=6
       guy.floor=2
       sfx(4)
      else
       sfx(31)
      end
     end
    end,
    draw=drawelevator,
   },
   { -- small ship
    29,43,
    cantbreak=true,
    inputhandler=function(_obj)
     if btnp(4) and not seed.score then
      traveling='down'
      travelc=30
      sfx(27)
     end
    end,
    draw=function(_obj)
     if _obj.inrange and not seed.score then
      sspr(92,87,7,4,31,84)
      actiontitle='\014\x8e\015 go to surface'
     end
    end,
   },
   { -- cryo
    50,53,
    cantbreak=true,
    inputhandler=function(_obj)
     if guy.incryo then
      if btnp(4) then
       guy.incryo=nil
       sfx(24)
      elseif btnp(5) then
       deadinit({_obj})
      end
     elseif btnp(4) then
      sfx(25)
      guy.incryo=true
     end
    end,
    draw=function(_obj)
     if guy.incryo then
      sspr(110,84,6,7,48,84)
     end
     if _obj.inrange then
      if guy.incryo and _update != deadupdate then
       actiontitle='\014\x8e\015 exit cryo'
       print('\x97 self-destruct',38,43,9)
      else
       actiontitle='\014\x8e\015 enter cryo'
      end
     end
    end,
   },
   { -- storage 1
    71,76,
    index=1,
    inputhandler=storageinputhandler,
    draw=storagedraw,
   },
   { -- storage 2
    77,82,
    index=2,
    inputhandler=storageinputhandler,
    draw=storagedraw,
   },
   { -- storage 3
    83,88,
    index=3,
    inputhandler=storageinputhandler,
    draw=storagedraw,
   },
   { -- water converter
    94,99,
    inputhandler=function(_obj)
     sampleselectinputhandler(_obj)

     if _obj.inputlastframe == true and not btn(4) then
      _obj.inputlastframe=nil

      if _obj.broken or #samples == 0 then
       -- todo: add n/a sfx
       return
      end
      deli(samples,samplesel)
      add(samples,13)
      sfx(15)
     end
    end,
    draw=function(_obj)
     if _obj.inrange then
      actiontitle='water converter'

      drawsamplecase(80,98,true)

      if _obj.broken then
       showbrokentitle=true
      elseif #samples > 0 then
       actiontitle='\014\x8e\015 convert to water'
      end
     end
    end,
   },
   { -- door
    43,49,
    x=44,
    y=85,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    54,60,
    x=55,
    y=85,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    66,72,
    x=67,
    y=85,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    88,94,
    x=89,
    y=85,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
  },

  { -- floor 2
   { -- engine
    28,37,
    c=0,
    inputhandler=function(_obj)
     sampleselectinputhandler(_obj)

     if _obj.inputlastframe == true and not btn(4) then
      _obj.inputlastframe=nil

      local _sample=samples[samplesel]
      if fuel == 5 then
       add(messages,'tank is full')
      elseif _sample == 13 then
       fuel+=1
       deli(samples,samplesel)
       sfx(14)
      elseif fuel == 0 then
       add(messages,'tank is empty')
      else
       add(messages,'only water for fuel')
       sfx(31)
      end
     end
    end,
    draw=function(_obj)
     if fuel > 0 then
      line(36,79,36,75+(5-fuel),12)

      rectfill(19,73,20,79,12)

      local _offx=(t()*78)%2 > 1 and 1 or 0
      sspr(117,86,11-_offx,5,10+_offx,74)
     end

     if fuel <= 1 then
      pset(34,73,8)
     end

     _obj.c-=1
     if _obj.c <= 0 then
      _obj.c=6
     end

     if fuel > 0 and _obj.c % 6 > 3 then
      sspr(102,80,4,5,29,75)
     end

     if _obj.inrange then
      actiontitle='engine'

      drawsamplecase(39,98,true)

      if fuel < 5 and #samples > 0 then
       actiontitle='\014\x8e\015 refuel with water'
      end
     end
    end,
   },
   { -- seed cannon
     44,49,
     c=0,
     inputhandler=function(_obj)
      if not seed.score then
       sampleselectinputhandler(_obj)

       if _obj.inputlastframe == true and not btn(4) then
        _obj.inputlastframe=nil
        if #samples > 0 and #seed < 4 then
         add(seed,deli(samples,samplesel))
         sfx(14)
        elseif #seed == 4 then
         seed.score=getseedquality()
         _obj.c=90
         sfx(12)
        end
       end
      end
     end,
     draw=function(_obj)
      if _obj.inrange then
       actiontitle='seed cannon'
       drawsamplecase(39,98,true)
      end

      if _obj.c > 0 then
       actiontitle=''
       _obj.c-=1
       if _obj.c % 30 < 15 then
        sspr(89,78,13,7,42,73)
       end

       if _obj.c == 0 then
        if not (_obj.broken and rnd() > 0.675) then
         lastseed=seed.score
         seedsshot+=1
         score+=seed.score
         seed.y=60
         
         if not factions.droid.alertc then
          factions.droid.alertc=300+flr(rnd(300))
         else
          factions.droid.alertc=max(1,factions.droid.alertc-90)
         end

         sfx(13)
        else
         seed.score=nil
         sfx(31)
        end
       end

       pset(43,75,11)

      elseif _obj.inrange and #seed == 4 and not seed.y then
       actiontitle='\014\x8e\015 shoot seed'
       pset(43,75,11)
      elseif _obj.inrange and #samples > 0 then
       actiontitle='\014\x8e\015 add sample'
      end

      if seed.y then
       if seed.y > 30 then
        sspr(104,85,6,6,47,57)
       end
       seed.y-=8
       pset(43,75,11)
      end

      drawseed(49,seed.y or 76,#seed == 4)
     end,
   },
   { -- elevator
    60,65,
    c=0,
    y=75,
    inputhandler=function(_obj)
     if btnp(3) then
      if not (_obj.broken and rnd() < 0.5) then
       _obj.c=6
       guy.floor=1
       sfx(5)
      else
       sfx(31)
      end
     end
    end,
    draw=drawelevator,
   },
   { -- score tracker
    87,92,
    c=0,
    draw=function(_obj)
     if _obj.inrange then
      rectfill(19,11,109,50,5)
      print('highscore: '..tostr(dget(63)),23,14,9)
      line(19,22,109,22,0)
      print('total score: '..tostr(score),23,26,12)
      print('seeds: '..tostr(seedsshot),23,34,11)

      if _obj.broken then
       print((_obj.broken and rnd() > 0.5 and 'la5t sfed: ' or 'last seed: ')..tostr(flr(rnd(9999))),23,42,6)
      else
       local _quality=flr((lastseed/38)*100)
       print('last seed: '..tostr(lastseed)..' ('..tostr(_quality)..'%)',23,42,6)
      end
     end

     _obj.c-=1
     if _obj.c <= 0 then
      _obj.c=20
      _obj.blink=rnd{{88,74,9},{88,76,12},{88,78,12},{90,74,11},{90,76,11},{90,78,11}}
     end

     pset(unpack(_obj.blink))
    end,
   },
   { -- navcom
    96,97,
    c=0,
    inputhandler=function(_obj)
     if btnp(4) then
      if _obj.broken then
       if rnd() > 0.425 and not _obj.rebootingc then
        _obj.rebootingc=60
       end
       if _obj.rebootingc then
        _obj.rebootingc-=10
        return
       end
      end

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
     if _obj.rebootingc then
      _obj.rebootingc-=1
      if _obj.rebootingc <= 0 then
       _obj.rebootingc=nil
      end
     end

     local _blink=(t()*6)%2 > 1

     if not traveling then
      -- todo: better check for hostile
      if not _obj.broken then
       if _blink then
        if factions.droid.alertc == 0 or _obj.rebootingc then
         pset(103,76,8)
        elseif sector.planets[1].haswreck then
         pset(103,76,11)
        end
       end

       if fuel == 0 then
        pset(104,76,8)
       elseif #sector.planets == 1 then
        pset(104,76,11)
       end
      end

      if _obj.inrange then
       line(98,74,100,74,11)
       line(98,76,99,76,11)
 
       rectfill(17,10,109,51,3)
 
       if _obj.rebootingc then
        print('rebooting...',21,14,11)
        rectfill(21,23,81-_obj.rebootingc,26,11)
        return
       end
 
       if fuel == 0 then
        print('no fuel',78,14,8)
       end
       print(_obj.broken and rnd() > 0.5 and 'navcdm' or 'navcom',21,14,11)
       print('orbiting planet',21,23,11)
  
       if _obj.broken then
        print('system unstable',21,32,8)
       elseif _blink then
        if factions.droid.alertc == 0 then
         print('hostile ship near',21,32,8)
        elseif sector.planets[1].haswreck then
         print('distress signal',21,32,11)
        end
       end
  
       if #sector.planets > 1 then
        print('> orbit next planet',21,41,11)
       else
        print('> warp to next sector',21,41,11)
       end
      end
     end
    end,
   },
   { -- door
    38,43,
    x=39,
    y=74,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    54,60,
    x=55,
    y=74,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    66,72,
    x=67,
    y=74,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
   { -- door
    81,87,
    x=82,
    y=74,
    c=0,
    cantbreak=true,
    draw=drawdoor,
   },
  },
 }
end

function addbrokenparticle(_x,_y)
 if rnd() > 0.85 and #particles < 20 then
  add(particles,{
   x=_x,
   y=_y,
   vx=rnd(2)-1,
   vy=-rnd(),
   ax=0.9,
   ay=0.9,
   col=9,
   life=5,
   })
 end
end

function shipinit()
 lookinginsamplecase=true
 pal(trimsplit'1,130,3,133,5,6,7,8,9,137,11,12,13,14,15',1)

 stars={}

 for i=1,30 do
  add(stars,{
   x=flr(rnd()*128),
   y=flr(rnd()*128),
   spd=mid(0.125,rnd()+0.5,1),
   col=rnd{1,13}
  })
 end

 particles={}

 guy.x=guy.incryo and 52 or 37
 guy.y=91

 guy.floor=1 -- 0 space, 1 below, 2 deck

 actiontitle=''
 showbrokentitle=nil

 messages={
  c=30,
 }

 camera()

 _update=shipupdate
 _draw=shipdraw
end

function shipupdate()
 
 if not traveling then
  if guy.incryo == nil and not btn(4) then
   if btn(0) then
    guy.x-=1
   elseif btn(1) then
    guy.x+=1
   end
  end

  if guy.floor > 0 then
   guy.x=mid(27,guy.x,97)

   guy.y=floorys[guy.floor]
  end

  actiontitle=''
  showbrokentitle=nil

  for _i=1,2 do
   local _floorobjs=shipobjs[_i]
   for _obj in all(_floorobjs) do
    _obj.firstframe=nil
    if _i == guy.floor and mid(_obj[1],guy.x,_obj[2]) == guy.x then
     if not _obj.inrange then
      _obj.firstframe=true
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
  updatefactionalerts()

  if factions.droid.alertc == 0 then
   if not factions.droid.firingc then
    factions.droid.firingc=90+flr(rnd(60))
   end

   factions.droid.firingc-=1

   if factions.droid.firingc == 0 then
    local _shipobj=rnd(shipobjs[rnd{1,2}])
    _shipobj.broken=true
    factions.droid.firingc=nil
    sfx(rnd{19,20})
   end
  end

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
  if travelc == 60 then
   if traveling == 'warping' then
    sfx(22)
   elseif traveling == 'orbiting' then
    sfx(23)
   end
  end

  travelc-=1

  if travelc <= 0 then
   local _fuelconsumption=1
   if shipobjs[2][1].broken then -- engine
    _fuelconsumption=2
   end

   if traveling == 'warping' then
    fuel=max(0,fuel-_fuelconsumption)
    nextsector()
   end

   if traveling == 'orbiting' then
    fuel=max(0,fuel-_fuelconsumption)
   end

   if traveling == 'warping' or traveling == 'orbiting' then
    if sector.planets[1].droidworld then
     factions.droid.alertc = 10
    end
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

 -- update broken
 for _i=1,2 do
  local _floorobjs=shipobjs[_i]
  for _obj in all(_floorobjs) do
   if _obj.broken and not _obj.cantbreak then
    addbrokenparticle(_obj[2]-3,floorys[_i])
   end
  end
 end

 -- update particles
 for _p in all(particles) do
  _p.life-=1
  if _p.life <= 0 then
   del(particles,_p)
  else
   _p.x+=_p.vx
   _p.y+=_p.vy
   _p.vx*=_p.ax
   _p.vy*=_p.ay
  end
 end

 -- update stars
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

 if factions.droid.firingc == 1 then
  cls(13)
 end

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
 if traveling != 'warping' then
  local _x=64
  if traveling == 'orbiting' then
   _x+=travelc*2.5
  end
  circfill(_x,318,200,sector.planets[1].surfacecolor)
 end

 -- draw factions ships
 for _,_faction in pairs(factions) do
  local _shipx=_faction.shipx
  local _shipy=_faction.shipy
  local _shipsw=_faction.shipsw
  local _shipsh=_faction.shipsh
  local _shipcx=_shipx+_shipsw/2
  local _shipcy=_shipy+_shipsh/2
  if factions.droid.alertc == 0 then
   sspr(
    _faction.shipsx,
    _faction.shipsy,
    _shipsw,
    _shipsh,
    _shipx,
    _shipy)

  elseif factions.droid.alertc == 1 then
   circfill(_shipcx,_shipcy,12,7) -- note: warp vfx
  end

  if factions.droid.firingc and factions.droid.firingc < 3 then
   line(_shipcx,_shipcy,65,80,7) -- note: laser vfx
  end
 end

 -- draw ship
 sspr(39,91,89,37,21,57)

 -- draw shipobjs
 for _floorobjs in all(shipobjs) do
  for _obj in all(_floorobjs) do
   _obj.draw(_obj)
  end
 end

 -- draw guy
 if guy.floor > 0 and not guy.incryo then
  sspr(16,36,4,5,guy.x-2,guy.y-5)
 elseif guy.floor == 0 then
  sspr(24,36,4,5,guy.x-2,guy.y-5)
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

 -- draw particles
 for _p in all(particles) do
  pset(_p.x,_p.y,_p.col)
 end

 -- draw actiontitle and brokentitle
 if showbrokentitle then
  print('broken',52,32,8)
 else
  local _strlen=#actiontitle*4
  print(actiontitle,64-_strlen/2,32,9)
 end

 -- draw message
 drawmessages()

 -- rectfill(5,5,15,14,5)
 -- -- circfill(10,10,4,5)
 -- local _r=-t()/20
 -- local _x=cos(_r)*4
 -- local _y=sin(_r)*4
 -- line(10,10,10+_x,10+_y,7)

end


function deadinit(_drawies)
 sfx(-1,2)
 sfx(30)
 deaddrawies=_drawies

 local _curhiscore=dget(63)
 if score > _curhiscore then
  dset(63,score)
 end

 ts=t()

 pal(trimsplit'1,136,3,4,5,6,7,136,9,137,138,8,13,14,15',1)
 
 _update=deadupdate
 _draw=deaddraw
end

function deadupdate()
 if t()-ts > 2 and btnp(4) then
  resetgame()
  shipinit()
  return
 end
end

function deaddraw()
 cls(2)

 for _obj in all(deaddrawies) do
  if _obj.draw then
   _obj.draw(_obj)
  else
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
 end

 print('deceased',48,32,12)
 local _highscorestr='highscore: '..tostr(dget(63))
 print(_highscorestr,126-#_highscorestr*4,2,10)
 print('score: '..tostr(score),2,2,10)
 if t()-ts > 2 then
  print('\014\x8e\015 wake up new clone',24,118,9)
 end
end


_init=function()
 resetgame()
 shipinit()
end

__gfx__
e00eee0000eeeeeee00eeceeeeddeeeeeee4eeee0eeeeee0eeeeee000eeee000eeeeeee00000e0000eeee0000eee00000000000e00000000000000000000000e
e0d0e0aa990eeeee0cc0eeceeceeeee4eeceeee0c0eeee0c0eeee0ccc0ee0ccc0eeeee055550e05150ee057750ee055555555500ddddddddddddddddddddddd0
e0dd0aaaaa900ee00cdd0ececeeeeeeececeeee0cc0eee0c0eee0cc9cc00ccdcc0eeee057750e05110ee055550ee0ddddddddd00dd000d000d000d000d000dd0
05666666666660e0cddd0ececeeedddececeee0ccc10e0cc0eee09ccc100dccc10eee0551550e05110ee075110ee0ddd000ddd00dd060d060d060d060d060dd0
05dddddddddd660eeeecee0eeeee0000000eeee0c10ee00cc0ee0ccca100ccc210ee05551110e011102e055550ee0ddd060ddd00ddddddddddddddddddddddd0
e00000000000000eeecee0200ee022222220ee0cc10eee0c10eee0c110ee0cee0eee05751550ee0000ee015110ee0ddddddddd00550505050505050505050550
ee222222222222eceecee0022002ddddddd200cc1110ee0c110eeee00eeeeee00eee01111550205150ee015150ee055505055500550505050505050505050550
eeeeeeeeeeeeeeeecece022eee0ddddddddd0e00200ee0cc100eee0cc0eeee0220eee000000ee01550ee015150ee055505055500550505050505050505050550
eeeeeeeeeeeeeeeeceeee000eee0dddddddd0ee020eee0cc110eee0cdc0eee02120e05757550e011102e055150ee055505055500550505050505050505050550
eeeeeeeeeeeeeeeeeeee08880eee00ddddd0ee22eeee0ccc1110e0cddd0ee021110e05755550eeeeeee05751550e055505055500555055505550555055505550
ee00ee00ee00ee00eeeee0f000eeee00000eeeeeeeee00cc1100e0cdddc0e021112005551110eeeeeee05551150e055550555500555555555555555555555550
ee050050ee050050eeeee0f8880ee0000000eeeeeeeee0c1110e0cddccd00211221001151550eeeeeee05151150e055555555500ddddddddddddddddddddddd0
ee055550ee055550eeeee0f0f0ee044444440eee222e0cc111100cddddd002111110011111102eeeeee01111110200000000000e00000000000000000000000e
e0556560e0556560eeeee000eee04222222240eeeeee00022000eeeeee0eeeee0eeee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000e
0555555005555550eeee0ccc0ee02222222220eeeeeeee0220eeeeeee020eee020ee05751550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee066666660
0555555005555550eeeee03000ee0222222220eeeeee00e0eeee0eee0210eee020ee05555510eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee060000060
0555555005555550eeeee03ccc0ee00222220ee0eee040040ee040e02110ee02110e05711510eeeeee1111111111111111111111111111111eeeeeeeeeeeeeee
05050050e050550eeeeee03030eeeee00000ee040e040ee040e020e021110e02110e05551510eeee1111111111111111111111111111111111111eeeeeeeeeee
000e000eeeeeeeee3eeee55eeeeeeeeeeeee44e040020ee020040ee021110002110e05751510eee1111111111111111111111111111111111111111eeeeeeeee
0dd0dd0eee0eeeeeecee3eeeeeeeee444ee4eee02040eeee0420ee0211120021120e011111102ee111111111111111111111111111111111111111111eeeeeee
e0ddd0eee0d0eeeeececeeeeeeeeeeeee44eeeee020eeeeee040ee02112100212110eeeeeeeeeee11111111111111111111111111111111111111111111eeeee
ee0d0eee0ddd0eeeececeee555eeeeeeeee44eee040eeeeee040eeee0eeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111eee
eee0eeee0d0d0eeeeeeeeeeeeee44eeeeeeee4e04220eeee04220ee020eeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111111e
eeeeeeee00e00eeeeeeeeeeeeeeeeeee0000eeeee0000eee000eee0210eeeeeeeeeaaaaeeeeeeee1111111111111111111111111111111111111111111111111
eeeeeeeeeeeeeeee000eeeeeeeeeeee044440eee0c0c00e04120e02110eeeaaeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eeee000eeeeeeee05550eeee444eee04999940e0c0c0500412220021210eeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111111e
e0e05550eeeeeee05055000eeeeeee099999900c0c050ee0000eeeeee0eeeeeeeeaaaeeeeeeeeeeeeeee11111111111111111111111111eeeeeeeeeeeeeeeeee
0e0050500eeeeee050500ee0eeeeeee099990e0c0c050e0cccc0eeee0300eeeeeeeeeeeeeeeeeeeeeeeee11111111111111111111eeeeeeeeeeeeeeeeeeeeeee
0ee0000dd0eeeee0000dd0eeeeeeeeee0000ee0c0c02220c5c5c0eee03030eeeeeeeeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0e09d90eeee0e009d90eeeeee0000000eeeee000ee0cccccc0e003330eeeeee7777eeeeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0ee0000eeee0eee000eeeeee044444440eee04410eeee000ee030300e77eeeeeeeeeeeeeeee1111eeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0ee0eeee0ee0eeeeeeeeeeee04999999940ee04120eee0440ee03330eeeeeeeeeeeeeeeeeeeee1111eeeeeeee1eee11eeeeeee1eeeee1eeeeeeeeeeeeeeee
eee0000eeee0000eeeeeeeeeeee09999999990e04120eeee04120ee0030eeeeeee777eeeeeeeeee111111eeeeee1eeee111eeeeee1eeee1eee1eeeeeeeeeeeee
0e08aaa0ee08aaa0eeeeeeeeeeee0999999990ee02220ee041120eee030eeeeeeeeeeeeeeeeeeeee111111eee1111eee1111eee1e1ee1111ee11eeeeeeeeeeee
e0889a9000889a90eeeeeeeeeeeee00999990eee04120ee04120eeee030eeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111eeeeeeee1ee
e088aaa0e088aaa0eeeeeeeeeeeeeee00000eee041220ee041120eeee00eeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111eeeeee1eee
e0888880e0888880e00ee00ee11eeeeeeeee4e0411122004122220e0030eeeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111eee1111ee
e000000ee000000e0ff00f901f91eeeeeee4eeeeeeeeeeeeeeeeee030300eeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
e0ee0e0eee00e0ee0ff009901991eeee444e44eeeeeeeeeeeeeeee0333030eeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eee0000eeeeeeeee0aa006601661ee44eeeeeeeeeeeeeeeeeeeeeee003330eeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
ee077770eee0000e0aa006601661eeeeeeeeeeeeeeeeeeeeeeeeeeee0300eeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111e
ee078780ee077770eeeeeeeeeeee00eeeeeeeeeeeeeeeeee0eeeeeee030eeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111111e
e0777770ee078780eeeeeeeeeee00a0000eeeeeeeeeeee6e60eeeeee030eeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111ee
07778880e0777770eeeeee8888080885850eeeeeeeeee06bb000eeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111eee
077788800777888088eeeeeeeeeeeeeeeeeeeeeeebbbb06bbddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111eeee
0777777007777770eeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111e11111111eeeeeeeeeee1111111eeeeeeee
07070070e070770eeeeee888ee00e0e00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11111111111111eeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeee0606060eeeeeeebbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111eeeeee
ee0bbbb0eee00000eeeeeeeeee055d550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111eee
e0bb7b7b0e0bbbbb0eeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0ddddd00eeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111ee
e0bbbbbb00bbb7b7b0eeeeeeee0560eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedee0d66666dd0eeeeeeeeeeeeeeeeeeee11111111111111111111111111111111e
e0bbbbbb00bbbbbbb0eeeeeeee0650eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0d6d000d6dd0eeeeeeeeeeeeeeeeee1111111111111111111111111111111111
ee000000ee0000000eeeeeeeee0560eeeeeeee00eeeeeeeeeeeeeeeeeeeeeee0d6d07bb0d6dd0eeeeeeeeeeeeeeeee1111111111111111111111111111111111
ee0000eeee0000eeee0000eeee0000eeeeeee0dd0eeeeeeeeeeeeeeeeeeeeee0dd07bbbb0d6d0eeeeeeeeeeeeeeeeee11111111111111111111111111111111e
e0dddd0ee0dddd0ee0dddd0ee0dddd0eeeee0dd50eeeeeeeeeeeeeeeeeeeeeeeed0bbbbb0d6d0eeeeeeeeeeeeeeeeeeeeeee1111111111111111111111eeeeee
e0d7d70ee0d7d70ee0d7d70ee0d7d70eeee0dddd0eddeeeeeeeeeeeeeeeddeeeeeeeebb0dddd0eeeeeeeeeeeeeeeeeeeeeeeeeee11111111111111eeeeeeeeee
e00ddd0eee0ddd0eee0ddd0eee0ddd0eee0dd7d50eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111eeeeeeeeeee
0d0000d0e000000ee000000ee000000eee0dd7dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111eeeeeeeeeeee
050d00500d0d00d00d0d00d00d0d00d0e0ddd7d50eeeeeeeeeeeeeeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeee
05050050050500500505005005050050e0d7d7dd0eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0500ee050ee0500505005005050050e0d7d7dd50eeeeee0bbb770eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee000000eeeeeeee0dddd7ddd0eee000bbbbbb7000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0000000000000000000a88a0eeeeeeee07d5d7dd50e00d60bbbbbbb06d00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0a88a00a88a00a88a0e0dd0eeeeeeeee0dd5d7ddd00d6dd600000006dd6d0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0880ee0880ee0880ee0880eeeeeeeee07ddd7dd500dd6dd6666666dd6dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
005580085500005500005500eeeeeeee0dd7d7ddd0e00d66ddddddd66d00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
08dd0ee0dd8008dd8008dd80eeeeeeee05d7dddd50eee0000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e050eeee050ee0550ee0550eeeeeeeee05d7d7ddd0eeee22222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0eeeee0eeeee0eeeee0eeeeeeeeee05d7d7d550eeeeeeeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0000ee0000ee0000ee0000eeeeeeeee0dddddddd0eeeeeeeeeeeee08880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
07666007666007666007bb60eeeeeeee05d5d5d550eeeee0000000085550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
06bb6006bb6006bb6006bb60eeeeeeee0dd555dd0eeeee066d0555588880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
06bb6006bb6006bb60065560eeeeeeee055555550eeee06ddd0588588880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055555550eee06dddd05555888850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055050550ee000000055000000850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeeee0000000ee0885555550888850850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee088880eee0000eeeeeeeeeeeeeeeeee2222222eee22222222222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee089890ee088880eeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888888eeeeeeeeeeeeeeeeeeeeeeeeee
e0888880ee089890eeeeeeeeeeeeeeeeeeeeeeeeeeeee050eeee080eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888eeee888eeeeeeeeeeeeeeeeeeeeeeeeee
0888aaa0e0888880eeeeeeeeeeeeeeeeeeeeeeeeeeee0850eee08880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888eeeeee88cccceeeeeeeeeeeeeeeeeeeeee
0888aaa00888aaa0eeeeeeeeeeeeeeeeeeeeeeeeeee08850ee0558880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888eeeeee88ddddeeeeeeeeeeeeeeeeeeeeee
0888888008888880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee05555800eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888eeeeee88cccceeeeeeeeeeeeeeeeeeeeee
08080080e080880eeeeeeeeeeeeeeeeeeeeeeeeeeeddee00055585050eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888eeeeee88ddddeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd558508850eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888eeee888cccceeeee0000eeeeeeeeeeeee
eeeeeeeeeeeeee00eee00eeeeeeeeeeeeeeeeeeeeeeeeeeedd550888850eeeeeeeeeeeeeeeeeeeeeeeeeeeeee101eeeeeeeee9eeee6eee06ddd0eeeeeeeeeeee
ee00eee00eeee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeedeeeee5500000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee101eeeeeeee999eee6e6e06ddd0eeeeeecccccc
e0ff0e0ff0eee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee101110001199999ee6eee0dddd0eeeccccccc66
e0ff0e0ff0eee0880e0880eeeeeeeeeeeeeeeeeeeeeeeeee555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011099901e999ee66e6e05dd50eccc6c66c666
0daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011109990e999ee6666e055550eeeccccccc66
0daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1010000990eaaae455555055550eeeeeecccccc
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424424444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424442444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444424444444eeeeeeeeee244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424444244444444eeeeeeeee2222eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444442444444444eeeeeee2444eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424444424444444444eeeee2444eeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444444222222222222ee222222eeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44244422444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4424224442222222222222222222222222222222222222222222444444444444444444eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444224444444444444444444444444444444444444444444222444444222222222444eeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44222222222222244444444444444444442222222224442222222222224442200000000000444eeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4422000000000002242222222222222224220000000224220000000000224220eeeeeeeeeee0000eeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5422011111111111022200000000000002220111111102220111111111102220eeeeeeeeeeeeeeee0eeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee54420111111111111104011111111111110401111d1111040110011118111040ee00000eeeee0000000eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4542011100001110110401111110000111040110000011040109901000001040e0545350eeee033330e0eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55420110dddd0105010401111105555011040110555011040109901055501040e0555550eeee033330000eeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44420110cccc0105010401111105555011040110555011040111111055501040e05d5350eeee0333353300eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55420110dddd0105010401551105555011040110555011040106601055501040e0555550ee00033335550e0ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee45420110cccc0105010401551105555011040110555011040106601055501040e05d5350ee05555555550222e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee54422010dddd0105010401111110440111040110555011040111111055501040e0555550ee044444422222222
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5442222222222222222222222222222222222222222222222222222222222222222222222222222244444442
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44222444444444444444444222222224444444444444444444444444444444444444444444444444444422
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4442222222222222222224220000002242222222222242222222222222222222224222222222444444422e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000022201111110222000000000222000000000000000000022200000002222222422e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee50111111111111111110040110000110401111d111104011111111111111111110401151511024444422ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5011111100001110011104010d6dd0104011000001104011111111111111111110401151511022224222ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee501111109999010d0111040100dd0010401105550110401111111111111111111040115151102444222eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee50111009999990dd011104010400401040110555011040100000100000100000104010000010244222eeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee501106666666666650110401044440104011055501104010ddd01055d01055d010401055501024222eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee501066dddddddddd501104010444401040110555011040105550105d50105d501040105550102222eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee501000000000000001110401004400104011055501104010555010d55010d550104010555022222eeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eee22222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeeeeeeeeeeeeeeeeee
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
000200002145021450204501f4501a450184500040000400094500845000400004000040001450014500245000400004000040000400004000040000400004000040000400004000040001400014000040000400
00030000214501d4501845012450154501a4501845012450004000040005450004000545007400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000300001945023450174501e450184500000011450134500d4500f45000000114500045000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000336503365033650336502f4502e4502e4502c4502b4502a45028450284502465024450226501f4501e6501a45015450104500b4500345005400004000065000640006400063000620006200061000620
00020000336503365033650336502e4502d4502d4502c4502a650286502745026450234501e45018450134500d4500645001450004400b4000065000640006400063000620006300065000650006400062000630
001000100605006040005500054005050050300175001740060500604000550005400505005030027500274000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001e6200f550226200f550226200f550226200f550246200f550246200f550256200f550276200f550296200f5502a6200f5502b6200f5502e6200f5502e6200f5502d6200f550296403b650146500c650
000700000362003620036200462005620076200b6200f62013620176201b6201e6202062021620226202362023620236202362021620206201d6201a6201762014620116200d6200b62009620056200362000620
000600002243022430164300d4301261012610126101161011610106100f6100d6100c6100a610086100761005610046100161000610066000560004600036000260002600006000060000600006000060000600
000600000b420174202242022420096100a6100d6100e61011610166101b6101d610256102e6103f610266002e6003c6003f60000000000000000000000000000000000000000000000000000000000000000000
001000000211002110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00040000286201f6201a620166201262011620106200f6200f6200f6200f6200e6200e6200d6200d6200d6200d6200c6200b6200a620096200962008620076200662005620046200462003620026200062000620
0005000000610006100061000610006100061000610006100061000610006100061000610006100061001610026100361005610056100661007610086100b6100b6100f6101161014620176201b6302264026650
000200003265029250292500545028650161501515006350063501f6501f650102501025017250162500725007250236501d65019650000000a30000000000001025010250000000430000000000001125011250
000a00002c5502d5502c5502b550275501d55017550125500e5500955006550035500255001550005500055000550005500055000550005500055000540005000050000500047500475004700047000450008700
000900001a05014050080501500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00001f050150500a0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500003b6503a650295502655032450324501b550185501855000000154500f4500d55005450024500150000500005000050000000000000000000000000000000000000000000000000000000000000000000
000600001514016150211500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
