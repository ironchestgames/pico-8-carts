pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- the panspermia guy 1.0
-- by ironchest games

cartdata'ironchestgames_thepanspermiaguy_v1-dev8'

--[[ cartdata layout

1,2,3,4,5 = sample case
6,7,8 = sample storages
9 = fuel

11 - 25 = broken ship objects floor 1
26 - 40 = broken ship objects floor 2

59 = is game saved
60 = last seed score
61 = current nr of seeds
62 = current score
63 = highscore

--]]


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

function contains(_t,_value)
 for _v in all(_t) do
  if _v == _value then
   return true
  end
 end
end

function trimsplit(_str)
 local _newstr=''
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

function addtosamplecase(_sample)
 add(samples,_sample)
 dset(#samples,_sample)
end

function removefromsamplecase(_index)
 local _result=deli(samples,_index)
 for _i=1,5 do
  dset(_i,samples[_i])
 end
 return _result
end

floordatapos={10,25}
function breakrandomshipobj()
 local _floorindex=rnd{1,2}
 local _objindex=flr(1+rnd(#shipobjs[_floorindex]))
 dset(floordatapos[_floorindex]+_objindex,1)
 shipobjs[_floorindex][_objindex].broken=true
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
 seed={}

 resetshipobjs()

 if dget(59) == 0 then -- no ongoing game
  -- reset
  dset(59,1) -- set ongoing game
  
  dset(60,0) -- last seed
  dset(61,0) -- seeds shot
  dset(62,0) -- score

  dset(9,5) -- fuel

  dset(6,0) -- storages
  dset(7,0)
  dset(8,0)

 else
  -- load saved samples
  for _i=1,5 do
   local _savedvalue=dget(_i)
   if _savedvalue == 0 then
    samples[_i]=nil
   else
    samples[_i]=_savedvalue
   end
  end

  -- load saved broken ship objects
  for _floorindex,_floorobjs in ipairs(shipobjs) do
   for _objindex,_obj in ipairs(_floorobjs) do
    if dget(floordatapos[_floorindex]+_objindex) == 1 then
     _obj.broken=true
    end
   end
  end
 end

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
end

-- global constants
scorethreshold=1000
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
   addtosamplecase(_target.samplecolor)
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
 },
}

-- objtypes={
--  twigs={
--   sx=20,
--   sy=4,
--   sw=6,
--   sh=4,
--   ground=true,
--  },
--  flowers={
--   sx=31,
--   sy=0,
--   sw=5,
--   sh=4,
--   samplecolor=9,
--   action=takesampleaction,
--  },
--  flowers2={
--   sx=16,
--   sy=18,
--   sw=5,
--   sh=4,
--   samplecolor=9,
--   action=takesampleaction,
--  },
--  mushroom_red={
--   sx=20,
--   sy=8,
--   sw=7,
--   sh=5,
--   samplecolor=15,
--   action=takesampleaction,
--  },
--  mosstone_small={
--   sx=15,
--   sy=0,
--   sw=6,
--   sh=4,
--  },
--  mosstone_big={
--   sx=52,
--   sy=6,
--   sw=8,
--   sh=7,
--   solid=true,
--  },
--  grass1={
--   sx=21,
--   sy=0,
--   sw=5,
--   sh=4,
--  },
--  grass2={
--   sx=15,
--   sy=4,
--   sw=5,
--   sh=5,
--  },
--  lake_watercolor={
--   sx=26,
--   sy=4,
--   sw=11,
--   sh=7,
--   ground=true,
--   samplecolor=13,
--   action=takesampleaction,
--   walksfx=7,
--   sunken=true,
--  },
--  pine_small={
--   sx=37,
--   sy=0,
--   sw=7,
--   sh=9,
--   solid=true,
--   samplecolor=6,
--   action=takesampleaction,
--  },
--  pine_big={
--   sx=44,
--   sy=0,
--   sw=8,
--   sh=15,
--   solid=true,
--   samplecolor=6,
--   action=takesampleaction,
--  },
--  mushroom={
--   sx=20,
--   sy=13,
--   sw=7,
--   sh=5,
--   samplecolor=15,
--   action=takesampleaction,
--  },
--  deadtree1={
--   sx=38,
--   sy=15,
--   sw=8,
--   sh=8,
--   solid=true,
--  },
--  deadtree2={
--   sx=46,
--   sy=15,
--   sw=8,
--   sh=8,
--   solid=true,
--  },
--  lake={
--   sx=27,
--   sy=11,
--   sw=11,
--   sh=7,
--   ground=true,
--   samplecolor=13,
--   action=takesampleaction,
--   walksfx=7,
--   sunken=true,
--  },
--  marsh={
--   sx=38,
--   sy=9,
--   sw=5,
--   sh=4,
--   ground=true,
--  },
--  marsh_flipped={
--   sx=24,
--   sy=22,
--   sw=5,
--   sh=4,
--   ground=true,
--  },
--  marsh_watercolor={
--   sx=26,
--   sy=0,
--   sw=5,
--   sh=4,
--   ground=true,
--  },
--  marsh_darkgrey={
--   sx=21,
--   sy=18,
--   sw=5,
--   sh=4,
--   ground=true,
--  },
--  rock_big={
--   sx=54,
--   sy=13,
--   sw=7,
--   sh=8,
--   solid=true,
--  },
--  rock_medium={
--   sx=61,
--   sy=13,
--   sw=7,
--   sh=8,
--   solid=true,
--  },
--  rock_medium2={
--   sx=60,
--   sy=6,
--   sw=8,
--   sh=7,
--   solid=true,
--  },
--  rock_small={
--   sx=53,
--   sy=21,
--   sw=6,
--   sh=5,
--  },
--  canyon_big={
--   sx=38,
--   sy=29,
--   sw=8,
--   sh=8,
--   solid=true,
--  },
--  canyon_medium={
--   sx=46,
--   sy=30,
--   sw=8,
--   sh=7,
--   solid=true,
--  },
--  canyon_small={
--   sx=46,
--   sy=23,
--   sw=7,
--   sh=3,
--  },
--  cactus1={
--   sx=54,
--   sy=26,
--   sw=7,
--   sh=9,
--   solid=true,
--   samplecolor=13,
--   action=takesampleaction,
--  },
--  cactus2={
--   sx=54,
--   sy=35,
--   sw=7,
--   sh=8,
--   solid=true,
--   samplecolor=13,
--   action=takesampleaction,
--  },
--  skull={
--   sx=46,
--   sy=26,
--   sw=8,
--   sh=4,
--   samplecolor=6,
--   action=takesampleaction,
--  },
--  ribs={
--   sx=38,
--   sy=23,
--   sw=8,
--   sh=6,
--   samplecolor=6,
--   action=takesampleaction,
--  },
--  crack_big={
--   sx=30,
--   sy=18,
--   sw=8,
--   sh=5,
--   ground=true,
--  },
--  crack_small={
--   sx=30,
--   sy=36,
--   sw=8,
--   sh=4,
--   ground=true,
--  },
--  lavapool_big={
--   sx=27,
--   sy=29,
--   sw=11,
--   sh=7,
--   solid=true,
--   ground=true,
--  },
--  lavapool_small={
--   sx=30,
--   sy=23,
--   sw=8,
--   sh=6,
--   solid=true,
--   ground=true,
--  },
--  fireblood={
--   sx=61,
--   sy=21,
--   sw=10,
--   sh=7,
--   ground=true,
--   samplecolor=10,
--   action=takesampleaction,
--  },
--  droidblood={
--   sx=61,
--   sy=28,
--   sw=10,
--   sh=7,
--   ground=true,
--   samplecolor=7,
--   action=takesampleaction,
--  },
--  deadmartian={
--   sx=45,
--   sy=41,
--   sw=8,
--   sh=4,
--   offx=-17,
--   offy=2,
--  },
--  deadmartianblood={
--   sx=35,
--   sy=41,
--   sw=10,
--   sh=7,
--   offx=-26,
--   offy=1,
--   ground=true,
--   samplecolor=11,
--   action=takesampleaction,
--  },
--  martianwreck_ground={
--   sx=42,
--   sy=50,
--   sw=21,
--   sh=9,
--   offx=2,
--   offy=-2,
--   ground=true,
--  },
--  martianwreck_collision={
--   sx=44,
--   sy=50,
--   sw=5,
--   sh=4,
--   offx=-1,
--   offy=0,
--   solid=true,
--  },
--  martianwreck={
--   sx=63,
--   sy=48,
--   sw=14,
--   sh=8,
--   linked=trimsplit'deadmartian,deadmartianblood,martianwreck_ground,martianwreck_collision',
--  },
--  taurienwreck_wing={
--   sx=43,
--   sy=78,
--   sw=5,
--   sh=4,
--   offx=-9,
--   offy=-6,
--  },
--  taurienwreck_ground={
--   sx=42,
--   sy=82,
--   sw=9,
--   sh=7,
--   offx=-8,
--   offy=-2,
--   ground=true,
--  },
--  deadtaurien={
--   sx=26,
--   sy=41,
--   sw=9,
--   sh=3,
--   offx=-18,
--   offy=2,
--  },
--  deadtaurien_blood={
--   sx=16,
--   sy=43,
--   sw=10,
--   sh=4,
--   offx=-27,
--   offy=3,
--   ground=true,
--   samplecolor=8,
--   action=takesampleaction,
--  },
--  taurienwreck={
--   sx=49,
--   sy=78,
--   sw=10,
--   sh=9,
--   linked=trimsplit'taurienwreck_wing,taurienwreck_ground,deadtaurien,deadtaurien_blood',
--  },
--  droidpillar1={
--   sx=68,
--   sy=0,
--   sw=9,
--   sh=7,
--   solid=true,
--  },
--  droidpillar2={
--   sx=77,
--   sy=0,
--   sw=6,
--   sh=5,
--   solid=true,
--  },
--  droidpillar3={
--   sx=68,
--   sy=7,
--   sw=9,
--   sh=6,
--   solid=true,
--  },
--  droidpillar4={
--   sx=68,
--   sy=13,
--   sw=9,
--   sh=7,
--   solid=true,
--  },
--  droidpillar5={
--   sx=83,
--   sy=0,
--   sw=9,
--   sh=13,
--   solid=true,
--  },
--  droidpillar6={
--   sx=77,
--   sy=5,
--   sw=6,
--   sh=4,
--   solid=true,
--  },
-- }


-- sx,sy,sw,sh,samplecolor,ground,solid,dangerous,sunken,walksfx,action

objtypes={
 { -- lava
  sx='53,55',
  sy='22,29',
  sw='11,8',
  sh='7,6',
  lava=true,
  ground=true,
 },
 { -- lavacracks
  sx='55,55',
  sy='35,39',
  sw='8,8',
  sh='4,5',
  ground=true,
 },
 { -- sharp stones
  sx='78,78,100',
  sy='72,80,72',
  sw='7,7,6',
  sh='8,8,5',
  solid='1,1,1',
 },
 { -- cracks
  sx='100,100',
  sy='60,64',
  sw='8,8',
  sh='4,5',
  ground=true,
 },
 { -- rounded stones
  sx='69,69,85,93',
  sy='73,82,74,73',
  sw='8,8,7,6',
  sh='7,6,3,4',
  solid='1,1,0,0',
 },
 { -- lakes
  sx='53,53',
  sy='9,15',
  sw='8,11',
  sh='6,7',
  ground=true,
  samplecolor=13,
  sunken=true,
  walksfx=7,
  action=takesampleaction,
 },
 { -- skulls and ribs
  sx='61,72,82,92',
  sy='60,60,62,61',
  sw='10,8,8,8',
  sh='6,6,4,5',
  samplecolor='6,15',
  solid='1,0,0,0',
  action=takesampleaction,
 },
 { -- canyon stones
  sx='61,61,85',
  sy='72,81,74',
  sw='8,8,7',
  sh='8,7,3',
  solid='1,1,0',
 },
 { -- flowerbush
  sx='119,124',
  sy='77,77',
  sw='5,4',
  sh='7,7',
  samplecolor='15,9',
  action=takesampleaction,
 },
 { -- dead trees
  sx='39,47',
  sy='30,30',
  sw='8,8',
  sh='8,8',
  solid='1,1',
 },
 { -- red caps
  sx='39',
  sy='0',
  sw='7',
  sh='5',
  samplecolor='6,15,9,10,11,7',
  action=takesampleaction,
 },
 { -- shadow marsh
  sx='17',
  sy='0',
  sw='5',
  sh='4',
  ground=true,
 },
 { -- water marsh
  sx='17',
  sy='4',
  sw='5',
  sh='4',
  ground=true,
 },
 { -- leafshadow marsh
  sx='17',
  sy='8',
  sw='5',
  sh='4',
  ground=true,
 },
 { -- grass
  sx='16,21,26',
  sy='31,31,31',
  sw='5,5,5',
  sh='4,4,4',
 },
 { -- cactuses
  sx='53,60',
  sy='0,0',
  sw='7,7',
  sh='9,9',
  solid='1,1',
  action=takesampleaction,
  samplecolor=13,
 },
 { -- mushrooms
  sx='46',
  sy='0',
  sw='7',
  sh='5',
  samplecolor='15,9,10,8,11,7',
  action=takesampleaction,
 },
 { -- trees
  sx='77,84,112,120',
  sy='46,46,59,60',
  sw='7,7,8,8',
  sh='10,10,15,14',
  solid='1,1,1,1',
  action=takesampleaction,
  samplecolor=6,
 },
 { -- flowers
  sx='22,27',
  sy='0,0',
  sw='5,5',
  sh='4,4',
  samplecolor='15,9,10,8,11,7',
  action=takesampleaction,
 },
}

plantsamplechances={
 [15]=1,
 [9]=1,
 [10]=0.675,
 [6]=0.5,
 [8]=0.05,
 [11]=0.025,
 [7]=0.01,
}

planettypes={
 droidworld={
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
  animaltypes=trimsplit'droid,droid,droid,droid,droid,droid,droid,droid,droid,droid',
  objdist=18,
  droidworld=true,
 },
}


mapsize=255

groundcolors=split'1,2,3,4,5,6,7,9,13,14,15,18,19,20,21,22,23,27,28,29,31'
shadowcolors=split'17,18,19,20,21,22,6,na,4,na,na,na,29,8,31,na,na,16,1,18,18,5,26,na,na,na,3,1,21,na,22'

surfacecolors=split'1,4,3,4,5,6,7,na,9,na,na,na,13,13,9,na,na,2,3,2,4,5,3,na,na,na,3,1,13,na,9'

leafshadows=split'1,2,3,4,5,6,8,13,14,15,18,19,20,21,22,23,24,25,26,27,28,29,30,31'
leafcolors={
 [1]=split'19,28',
 [2]=split'4,24',
 [3]=split'27',
 [4]=split'25,30',
 [5]=split'3,22',
 [6]=split'7',
 [8]=split'14',
 [13]=split'6,14,22',
 [14]=split'15',
 [15]=split'7',
 [18]=split'20,21',
 [19]=split'3,28',
 [20]=split'4',
 [21]=split'5,29',
 [22]=split'15',
 [23]=split'7',
 [24]=split'8',
 [25]=split'9',
 [26]=split'10,23',
 [27]=split'11,26',
 [28]=split'11,13',
 [29]=split'13',
 [30]=split'14,31',
 [31]=split'15',
}

stonecolors=split'1,2,3,4,5,6,7,8,9,12,13,14,18,19,20,21,22,23,27,28,29,30'
stonehighlights={
 [1]=split'2,3,5,13,19,20,24,28,29',
 [2]=split'3,4,5,13,14,22,24,25,29,30',
 [3]=split'6,11,12,26,27',
 [4]=split'9,14,25,30,31',
 [5]=split'3,6,8,13,14,15,22,24,25,30,31',
 [6]=split'3,7,27',
 [7]=split'6',
 [8]=split'9,14,30,31',
 [9]=split'10,15',
 [12]=split'6,7,15,23,26,31',
 [13]=split'6,12,14,15,23,31',
 [14]=split'15,31',
 [18]=split'2,5,21,29',
 [19]=split'3,13,22,27,28',
 [20]=split'4,13,22,24,30',
 [21]=split'2,4,5,13,28,29',
 [22]=split'6,9,15,31',
 [23]=split'7',
 [27]=split'11,23,26',
 [28]=split'6,12,22,27,31',
 [29]=split'3,4,13,22,24,25',
 [30]=split'9,31',
}

function fixcolor(_color)
 if _color > 15 then
  return _color+112
 end
 return _color
end

function fixpal(_pal)
 for _i=1,#_pal do
  _pal[_i]=fixcolor(_pal[_i])
 end
 return _pal
end

function getplanettypes()
 local _planettypes={}

 -- palette
 local _wpal,_groundcolor,_surfacecolor
 
 while true do
  local _leafcolors,_stonehighlights,_leafshadow,_stonecolor,_shadowcolor=nil
  _groundcolor=rnd(groundcolors)
  _surfacecolor=surfacecolors[_groundcolor]
  local _shadowcolor=shadowcolors[_groundcolor]

  if rnd() > 0.5 then -- stone == ground
   _stonecolor=_groundcolor
   _groundcolor=2
   _stonehighlight=rnd(stonehighlights[_stonecolor])
   _leafshadow=rnd(leafshadows)
   _leafcolor=rnd(leafcolors[_leafshadow])
  else -- leafshadow == ground
   _leafshadow=_groundcolor
   _groundcolor=3
   _leafcolor=rnd(leafcolors[_leafshadow])
   _stonecolor=rnd(stonecolors)
   _stonehighlight=rnd(stonehighlights[_stonecolor])
  end

  if _leafcolor != 0 and _stonehighlight != 0 then
   -- debug('break!')
   -- debug('_leafcolor')
   -- debug(_leafcolor)
   -- debug('_leafshadow')
   -- debug(_leafshadow)
   -- debug('_stonehighlight')
   -- debug(_stonehighlight)
   _wpal={
    _shadowcolor,
    _stonecolor,
    _leafshadow,
    _stonehighlight,
    _leafcolor,
   }
   break
  end
 end

 -- flora
 local _objtypes={}
 local _objtypeslen=rnd(split'4,4,4,5,5,5,6,7,8,9') -- todo: good?

 while #_objtypes < _objtypeslen do
  local _a=flr((rnd(2)-1+dget(62)/scorethreshold)*#objtypes)
  local _index=mid(1,_a,#objtypes)
  local _objtype=objtypes[_index]
  add(_objtypes,_objtype)
 end

 -- fauna
 local _allanimaltypes=split'bear,bat,spider,bull,gnawer,firegnawer,slime'

 local _animaltypes={}

 local _animaltypeslen=rnd(split'1,1,1,1,2,2,2,3,3,4')
 for _i=1,_animaltypeslen do
  add(_animaltypes,rnd(_allanimaltypes))
 end

 -- debug('_animaltypes')
 -- foreach(_animaltypes,debug)

 add(_planettypes,{
  wpal=fixpal(_wpal),
  groundcolor=_groundcolor,
  surfacecolor=_surfacecolor,
  objtypes=_objtypes,
  animaltypes=_animaltypes,
  objdist=36-flr(rnd(6))-flr((dget(62)/scorethreshold)*20),
 })

 -- add(_planettypes,planettypes.droidworld)
 -- add(_planettypes,planettypes.martianworld)
 -- add(_planettypes,planettypes.taurienworld)

 return _planettypes
end


function createplanet(_planettype)
 -- _planettype=planettypes[13] -- debug
 -- _planettype=planettypes[1] -- debug
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
   sx=63,
   sy=33,
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
  local _obj=clone(rnd(_planettype.objtypes))
  local _sxs=split(_obj.sx)
  local _idx=flr(rnd(#_sxs))+1
  local _samplecolorindex0=0
  if type(_obj.samplecolor) == 'string' then
   local _samplecolors=split(_obj.samplecolor)
   _samplecolorindex0=flr(rnd(#_samplecolors))
   _obj.samplecolor=_samplecolors[_samplecolorindex0+1]
   if rnd() > plantsamplechances[_obj.samplecolor] then
    _tries=100
   end
  end

  if _tries <= 10 and not contains(_planettype.wpal,_obj.samplecolor) then
   _obj.sx=split(_obj.sx)[_idx]
   _obj.sw=split(_obj.sw)[_idx]
   _obj.sh=split(_obj.sh)[_idx]
   _obj.sy=split(_obj.sy)[_idx]+_samplecolorindex0*_obj.sh

   _obj.solid=_obj.solid and split(_obj.solid)[_idx] == 1
   _obj.x=_x
   _obj.y=_y

   add(_mapobjs,_obj)
  end
 end

 -- debug(#_mapobjs)

 local _animals={}
 local _loops=min(1+flr(dget(62)/100),50)
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
 -- local _haswreck=nil
 -- if rnd() > 0.85 then
 --  local _x=rnd(mapsize-_tooclosedist)
 --  local _y=rnd(mapsize-_tooclosedist)

 --  local _wrecktype=rnd{'martianwreck','taurienwreck'}

 --  local _wreck=clone(objtypes[_wrecktype])
 --  _wreck.x=_x
 --  _wreck.y=_y
 --  add(_mapobjs,_wreck)

 --  for _name in all(_wreck.linked) do
 --   local _linkedobj=clone(objtypes[_name])
 --   _linkedobj.x=_x+_linkedobj.offx
 --   _linkedobj.y=_y+_linkedobj.offy
 --   add(_mapobjs,_linkedobj)
 --  end

 --  if _wrecktype == 'taurienwreck' and rnd() > 0.75 then
 --   local _trap=clone(animaltypes.trap)
 --   _trap.x=_x-32
 --   _trap.y=_y
 --   closetrap(_trap)
 --   add(_mapobjs,_trap)
 --  end

 --  _haswreck=true
 -- end

 return {
  rndseed=_rndseed,
  mapobjs=_mapobjs,
  wpal=_wpal,
  groundcolor=_planettype.groundcolor,
  surfacecolor=_planettype.surfacecolor,
  animals=_animals,
  haswreck=nil,--_haswreck,
  droidworld=_planettype.droidworld,
 }
end

function nextsector()
 sfx(-1,2)

 for _,_faction in pairs(factions) do
  _faction.alertc=nil
  _faction.firingc=nil
 end

 -- local _planetcount=rnd(trimsplit'1,2,2,2,3,3')
 local _planetcount=1

 sector={
  planets={}
 }

 for _i=1,_planetcount do
  local _planettypes=getplanettypes()
  add(sector.planets,createplanet(rnd(_planettypes)))
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


  for _obj in all(sector.planets[1].mapobjs) do
   if dist(guy.x-_movex,guy.y-_movey,_obj.x,_obj.y) < _obj.sw * 0.5 and (guy.runningc > 0 and _obj.solid or _obj.lava) then
    _movex*=-3
    _movey*=-3
    guy.panting=true
    guy.runningc=24
    messages[1]=rnd(trimsplit'ouch,ouf,argh,ow,owie')
    sfx(rnd{16,17})
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
 cls(sector.planets[1].groundcolor)

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
  if dget(_index) != 0 and #samples < 5 then
   addtosamplecase(dget(_index))
   dset(_index,nil)
   sfx(14)
  elseif dget(_index) == 0 and #samples > 0 then
   dset(_index,removefromsamplecase(samplesel))
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
   dset(_index,0)
   return
  end

  local _showsamplecasearrow=nil

  local _x=_obj[1]-4
  sspr(92,0,11,13,_x,98)

  if dget(_index) != 0 and #samples < 5 then
   actiontitle='\014\x8e\015 take sample'
   sspr(99,85,5,6,_x+3,113)
  elseif dget(_index) == 0 and #samples > 0 then
   actiontitle='\014\x8e\015 store sample'
   _showsamplecasearrow=true
  end

  drawsamplecase(42,98,_showsamplecasearrow)

  if dget(_obj.index) != 0 then
   local _lx=_x+5
   line(_lx,105,_lx,107,dget(_obj.index))
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
    index=6,
    inputhandler=storageinputhandler,
    draw=storagedraw,
   },
   { -- storage 2
    77,82,
    index=7,
    inputhandler=storageinputhandler,
    draw=storagedraw,
   },
   { -- storage 3
    83,88,
    index=8,
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
      removefromsamplecase(samplesel)
      addtosamplecase(13)
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

      if dget(9) == 5 then
       add(messages,'tank is full')
      elseif samples[samplesel] == 13 then
       dset(9,dget(9)+1)
       removefromsamplecase(samplesel)
       sfx(14)
      elseif dget(9) == 0 then
       add(messages,'tank is empty')
      else
       add(messages,'only water for fuel')
       sfx(31)
      end
     end
    end,
    draw=function(_obj)
     if dget(9) > 0 then
      line(36,79,36,75+(5-dget(9)),12)

      rectfill(19,73,20,79,12)

      local _offx=(t()*78)%2 > 1 and 1 or 0
      sspr(106,79,11-_offx,5,10+_offx,74)
     end

     if dget(9) <= 1 then
      pset(34,73,8)
     end

     _obj.c-=1
     if _obj.c <= 0 then
      _obj.c=6
     end

     if dget(9) > 0 and _obj.c % 6 > 3 then
      sspr(102,80,4,5,29,75)
     end

     if _obj.inrange then
      actiontitle='engine'

      drawsamplecase(39,98,true)

      if dget(9) < 5 and #samples > 0 then
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
         add(seed,removefromsamplecase(samplesel))
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
         dset(60,seed.score)
         dset(61,dget(61)+1)
         dset(62,dget(62)+seed.score)
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
      print('total score: '..tostr(dget(62)),23,26,12)
      print('seeds: '..tostr(dget(61)),23,34,11)

      if _obj.broken then
       print((_obj.broken and rnd() > 0.5 and 'la5t sfed: ' or 'last seed: ')..tostr(flr(rnd(9999))),23,42,6)
      else
       local _quality=flr((dget(60)/38)*100)
       print('last seed: '..tostr(dget(60))..' ('..tostr(_quality)..'%)',23,42,6)
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

      if dget(9) > 0 then
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

       if dget(9) == 0 then
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
 
       if dget(9) == 0 then
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
    breakrandomshipobj()
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
    dset(9,max(0,dget(9)-_fuelconsumption))
    debug(dget(9))
    nextsector()
   end

   if traveling == 'orbiting' then
    dset(9,max(0,dget(9)-_fuelconsumption))
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
  local _spd=dget(9) == 0 and 0.25 or 1
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

 if dget(62) > dget(63) then -- score > highscore
  dset(63,dget(62)) -- set new highscore
 end

 dset(59,0) -- reset save

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
 print('score: '..tostr(dget(62)),2,2,10)
 if t()-ts > 2 then
  print('\014\x8e\015 wake up new clone',24,118,9)
 end
end


_init=function()
 resetgame()
 shipinit()
end

__gfx__
eee0000eeeeeeeeee11eeeeeeeffeeeeee000eee000eeee000eeeeee0eeeeee00eeeeee00000e0000eeee0000eee00000000000e00000000000000000000000e
ee099790eee0000eeeeeeefeeceeceefe0ccc0e08880ee04440eeee0c00ee00c0eeeee055550e05250ee057750ee055555555500ddddddddddddddddddddddd0
ee099000ee099790eeeeeeececeecece0ccfcc0e06000ee0f000eee0c0c00c0c00eeee057750e05220ee055550ee0ddddddddd00dd000d000d000d000d000dd0
e0e0990ee0099900eee111ececeecece0fccc30e068880e0f4440e00c3c00c3c0c0ee0552550e05220ee075220ee0ddd000ddd00dd060d060d060d060d060dd0
0900099009009990eddeeeeeee99eeee0ccc930e06060ee0f0f0e0c0c00ee00c3c0e05552220e022201e055550ee0ddd060ddd00ddddddddddddddddddddddd0
0b9999b00b9999b0eeeeee9eeceecee9e0c330ee000eeee000eee0c3c0eeee0c00ee05752550ee0000ee025220ee0ddddddddd00550505050505050505050550
e0bbbb0ee0bbbb0eeeeeeeececeececeee000ee08880ee04440eee00c0eeee0c0eee02222550105250ee025250ee055505055500550505050505050505050550
ee0000eeee0000eeeeedddececeececee0ccc0ee0f000ee09000eee0c0eeee0c0eeee000000ee02550ee025250ee055505055500550505050505050505050550
eeeeeeeeeeeeeeeee33eeeeeeeaaeeee0cc9cc0e0f8880e094440ee0c0eeee0c0eee05757550e022201e055250ee055505055500550505050505050505050550
eeeeeeeeeeeeeeeeeeeeeeaeeceeceea09ccc30e0f0f0ee09090eee0000eeeee000e05755550eeeeeee05752550e055505055500555055505550555055505550
ee00ee00ee00ee00eeeeeeececeecece0ccca30e000eeee000eeee011110eeee060e05552220eeeeeee05552250e055550555500555555555555555555555550
ee010010ee010010eee333ececeececee0c330e08880ee04440ee01dddd10eee000e02252550eeeeeee05252250e055555555500ddddddddddddddddddddddd0
ee011110ee011110eeeeeeeeee88eeeeee000eee09000ee0a000e0dddddd0eee050e022222201eeeeee02222220100000000000e00000000000000000000000e
e0116160e0116160eeeeee8eeceecee8e0ccc0ee098880e0a4440e0dddd0eeee050ee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000e
0111111001111110eeeeeeececeecece0ccacc0e09090ee0a0a0eee0000eeeee050e05752550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee066666660
0111111001111110eeeeeeececeecece0accc30e000eeee000eeeee0000000eee0ee05555520eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee060000060
0111111001111110eeeeeeeeeebbeeee0ccc83008880ee04440eee011111110eeeee05722520eeeeee1111111111111111111111111111111eeeeeeeeeeeeeee
01010010e010110eeeeeeebeeceeceebe0c330ee0a000ee08000e01ddddddd10eeee05552520eeee1111111111111111111111111111111111111eeeeeeeeeee
000e000eeeeeeeeeeeeeeeececeececeee000eee0a8880e0844400ddddddddd0eeee05752520eee1111111111111111111111111111111111111111eeeeeeeee
0440440eee0eeeeeeeeeeeececeececee0ccc0ee0a0a0ee08080ee0dddddddd0eeee022222201ee111111111111111111111111111111111111111111eeeeeee
e04440eee040eeeeeeeeeeeeee77eeee0cc8cc0e000eeee000eeeee00ddddd0eeeeeeeeeeeeeeee11111111111111111111111111111111111111111111eeeee
ee040eee04440eeeeeeeee7eeceecee708ccc3008880ee04440eeeeee00000eeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111eee
eee0eeee04040eeeeeeeeeececeecece0ccc830e0b000ee0b000eee0000000eeeeeeeeeeeeeaaaa111111111111111111111111111111111111111111111111e
eeeeeeee00e00eeeeeeeeeececeececee0c330ee0b8880e0b4440e0aaaaaaa0eeeeeeaaeeeeeeee1111111111111111111111111111111111111111111111111
eeeeeeeeeeeeeeee000eeeeeeeeeeeeeee000eee0b0b0ee0b0b0e0a9999999a0eeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eeee000eeeeeeee05550eeeeeeeeeeeee0ccc0ee000eeee000eee09999999990eeeeeeeeeeaaaeee11111111111111111111111111111111111111111111111e
e0e05550eeeeeee05055000eeeeeeeee0ccbcc008880ee04440eee0999999990eeeeeeeeeeeeeeeeeeee11111111111111111111111111eeeeeeeeeeeeeeeeee
0e0050500eeeeee050500ee0eeeeeeee0bccc30e07000ee07000eee00999990eeeeeeeeeeeeeeeeeeeeee11111111111111111111eeeeeeeeeeeeeeeeeeeeeee
0ee0000dd0eeeee0000dd0eeeeeeeeee0cccb30e078880e074440eeee00000eeeeeeeeeeeee7777e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0e09d90eeee0e009d90eeeeeeeeee0c330ee07070ee07070eeeee0000eeeeeeee77eeeeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0ee0000eeee0eee000eeeeeeeeeeee000eeeeeeee00e0eeee0ee0aaaa0eeeeeeeeeeeeeeeee1111eeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0ee0eeee0ee0eceeeeeeeecceeecee0ccc0ee0eee040040ee0400a9999a0eeeeeeeeeee777eee1111eeeeeeee1eee11eeeeeee1eeeee1eeeeeeeeeeeeeeee
eee0000eeee0000eeceecceeceececee0cc7cc0040e040ee040e01009999990eeeeeeeeeeeeeeee111111eeeeee1eeee111eeeeee1eeee1eee1eeeeeeeeeeeee
0e08aaa0ee08aaa0ececeececeececee07ccc30e040010ee010040ee099990ee00eee0000eeeeeee111111eee1111eee1111eee1e1ee1111ee11eeeeeeeeeeee
e0889a9000889a90ececeececeececee0ccc630e01040eeee0410eeee0000eee0d0e0aa990eeeeeee111111111111111111111111111111111111eeeeeeee1ee
e088aaa0e088aaa0eeeeeeeeeeeeeeeee0c330eee010eeeeee040eeeeeeeeaee0dd0aaaaa900eeeee1111111111111111111111111111111111111eeeeee1eee
e0888880e0888880e00ee00ee11eeeeeeeeeeeeee040eeeeee040eeeeeeeaee05666666666660eeee11111111111111111111111111111111111111eee1111ee
e000000ee000000e0ff00f901f91eeeeeeeeeeee04110eeee04110eeeaaaeaa05dddddddddd660e1111111111111111111111111111111111111111111111111
e0ee0e0eee00e0ee0ff009901991eeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeee00000000000000e1111111111111111111111111111111111111111111111111
eee0000eeeeeeeee0aa006601661eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaee111111111111ee1111111111111111111111111111111111111111111111111
ee077770eee0000e0aa006601661eeeeeeeeeeeeeeeeeeeeeeeeeeeaaaeeaeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111e
ee078780ee077770eeeeeeeeeeee00eeeeeeeeeeeeeeeeee0eeeeeeeeeaaeeeeeeeeeeeeeeeeeeee11111111111111111111111111111111111111111111111e
e0777770ee078780eeeeeeeeeee00a0000eeeeeeeeeeee6e60eeeeeeeeeeaaeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111ee
07778880e0777770eeeeee8888080885850eeeeeeeeee06bb000eeeeeeeeeeaeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111eee
077788800777888088eeeeeeeeeeeeeeeeeeeeeeebbbb06bbddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111eeee
0777777007777770eeeeeeeeeeeeeeeeeeebbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111e11111111eeeeeeeeeee1111111eeeeeeee
07070070e070770eeeeee888ee00e0e00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeee11111111111111eeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeee0606060eeeeeeebbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0c0eeeee0eeeeeeeeeeee1111111111111111111111eeeeee
ee0bbbb0eee00000eeeeeeeeee055d550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000eeeeeee0cc0eee0c0eeeeeeee1111111111111111111111111111eee
e0bb7b7b0e0bbbbb0eeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0ddddd00eeee0cc30eee0cc0eeeeee111111111111111111111111111111ee
e0bbbbbb00bbb7b7b0eeeeeeee0560eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedee0d66666dd0eee0cc30ee0cc30eeeee11111111111111111111111111111111e
e0bbbbbb00bbbbbbb0eeeeeeee0650eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0d6d000d6dd0ee0cc330e0cc330eee1111111111111111111111111111111111
ee000000ee0000000eeeeeeeee0560eeeeeeee00eeeeeeeeeeeeeeeeeeeeeee0d6d07bb0d6dd00cc3330e0cc330eee1111111111111111111111111111111111
ee0000eeee0000eeee0000eeee0000eeeeeee0dd0eeeeeeeeeeeeeeeeeeeeee0dd07bbbb0d6d0e0c330e0cc3330eeee11111111111111111111111111111111e
e0dddd0ee0dddd0ee0dddd0ee0dddd0eeeee0dd50eeeeeeeeeeeeeeeeeeeeeeeed0bbbbb0d6d0ee010eee00100eeeeeeeeee1111111111111111111111eeeeee
e0d7d70ee0d7d70ee0d7d70ee0d7d70eeee0dddd0eddeeeeeeeeeeeeeeeddeeeeeeeebb0dddd0ee010eeee010eeeeeeeeeeeeeee11111111111111eeeeeeeeee
e00ddd0eee0ddd0eee0ddd0eee0ddd0eee0dd7d50eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111eeeeeeeeeee
0d0000d0e000000ee000000ee000000eee0dd7dd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111eeeeeeeeeeee
050d00500d0d00d00d0d00d00d0d00d0e0ddd7d50eeeeeeeeeeeeeeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeee
05050050050500500505005005050050e0d7d7dd0eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeee
ee0500ee050ee0500505005005050050e0d7d7dd50eeeeee0bbb770eeeeeeeeeee0000eeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeee1eeeeeee0c0eeeeee0eeee
eeeeeeeeeeeeeeeeee000000eeeeeeee0dddd7ddd0eee000bbbbbb7000eeeee0e060600eee060600eeeeeeeeeeee00ee00eeeeeee1eeeeeeee0c0eeeee0c0eee
0000000000000000000a88a0eeeeeeee07d5d7dd50e00d60bbbbbbb06d00ee060606050ee0606050eee0000eeeee060060eeee111e11eeeee0cc0eeeee0c0eee
0a88a00a88a00a88a0e0dd0eeeeeeeee0dd5d7ddd00d6dd600000006dd6d0060606050ee0606050eee066660eeee006660ee11eeeeeeeeeeee0cc0eeee0cc0ee
e0880ee0880ee0880ee0880eeeeeeeee07ddd7dd500dd6dd6666666dd6dd0060606050ee0606050eee0656560eee0656560eeeeeee11eeeeee0c30eee0ccc0ee
005580085500005500005500eeeeeeee0dd7d7ddd0e00d66ddddddd66d00e0606060111e06060111ee06666660ee06666660111ee1eeeeeeee0cc30eee0cc30e
08dd0ee0dd8008dd8008dd80eeeeeeee05d7dddd50eee0000000000000eeeeeeee0000eeeee0000eeee0000eeeee00ee00eeeee11eeeeeeee0cc300eee0c300e
e050eeee050ee0550ee0550eeeeeeeee05d7d7ddd0eeee11111111111eeeeee0e0f0f00eee0f0f00ee0ffff0eeee0f00f0eeeeeee11eeeeee0cc330ee0cc330e
eee0eeeee0eeeee0eeeee0eeeeeeeeee05d7d7d550eeeeeeeeeeeeee0000ee0f0f0f050ee0f0f050ee0f5f5f0eee00fff0eeeeeeeee1eeee0ccc3330e0ccc330
e0000ee0000ee0000ee0000eeeeeeeee0dddddddd0eeeeeeeeeeeee08880e0f0f0f050ee0f0f050eee0ffffff0ee0f5f5f0eeeeeeeeeeeee00ccc3300ccc3300
07666007666007666007bb60eeeeeeee05d5d5d550eeeee0000000085550e0f0f0f050ee0f0f050eeeeeeeeeeeee0ffffff0eeeeeeeeeeeee0c3330ee0c3330e
06bb6006bb6006bb6006bb60eeeeeeee0dd555dd0eeeee066d0555588880e0f0f0f0111e0f0f0111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0cc333300cc33330
06bb6006bb6006bb60065560eeeeeeee055555550eeee06ddd0588588880eeee000eeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeee0eeeeeeee0001100000011000
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055555550eee06dddd05555888850ee04420eeee00eeeeeee040eeeeeeeeeee00eeeee040eeeeeeeee0110eeee0110ee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055050550ee000000055000000850ee04220eee0440eeeee0420eee000eeee0440eee0420eeeeeeeeeeeeeeeeeeeeeee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeeee0000000ee0885555550888850850e04220eeee04220eee04220ee04420eee04220e04220eeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000eee02220ee042220eee0422200422220e042220e042420eeeeeeeeeeeeeeeeeeeeee
ee088880eee0000eeeeeeeeeeeeeeeeee1111111eee11111111111111111eee04220ee0422240ee042220eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefeeeee
ee089890ee088880eeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeee0eeeeeeee042240e04224420e0422240eeee8888888888888eeeeeeeeeeeeeeeeefeecefeee
e0888880ee089890eeeeeeeeeeeeeeeeeeeeeeeeeeeee050eeee080eeeeee0422422004222220e0422420eeee888888eeee888eeeeeeeeecccccceeecceeceef
0888aaa0e0888880eeeeeeeeeeeeeeeeeeeeeeeeeeee0850eee08880eeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee88888eeeeee88cccceeccccccc66eeeecefecce
0888aaa00888aaa0eeeeeeeeeeeeeeeeeeeeeeeeeee08850ee0558880eeeeeee00eeeeeeeeeeeeee040eeeeee88888eeeeee88ddddccc6c66c666eefeccefcee
0888888008888880eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee05555800eeeeee0440eeeee000eeeee040eeeeee88888eeeeee88cccceeccccccc66eeecceeeece
08080080e080880eeeeeeeeeeeeeeeeeeeeeeeeeeeddee00055585050eeeeee04220eee04440eee04220eeeee88888eeeeee88ddddeeeeecccccceeeeceeeece
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd558508850eeee042220ee042220eee04220eeeee888888eeee888cccceeeee0000eeeeeee9eeeee
eeeeeeeeeeeeee00eee00eeeeeeeeeeeeeeeeeeeeeeeeeeedd550888850eee04220eee042220eee042240eeee101eeeeeeeee9eeee6eee06ddd0eee9eece9eee
ee00eee00eeee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeedeeeee5500000eeee042220e04224420e0422420eeee101eeeeeeee999eee6e6e06ddd0eeeecceecee9
e0ff0e0ff0eee0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0422222004242220e0422420eeee101110001199999ee6eee0dddd0eeeeece9ecce
e0ff0e0ff0eee0880e0880eeeeeeeeeeeeeeeeeeeeeeeeee555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011099901e999ee66e6e05dd50eee9ecce9cee
0daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011109990e999ee6666e055550eeeecceeeece
0daa0e0add0e0daa0e0add0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1010000990eaaae455555055550eeeeeceeeece
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424424444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee42444244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee424442444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eee42444424444444eeeeeeeeee244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee00000e070eeeeeeee0f0eeee424444244444444eeeeeeeee2222eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee0777f0e07f00eeeeee0f0eeee42444442444444444eeeeeee2444eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee0777f0e07f7f0eee007f0eeeee424444424444444444eeeee2444eeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee077f7f0e07f7f0ee07f7f0eeeee42444444222222222222ee222222eeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee0777f7f0e07f7f0ee07f7f0eeeee44244422444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee077f77f0e07f7f0ee07f7f0eeeee4424224442222222222222222222222222222222222222222222444444444444444444eeeeeeeeeeeeeee
eeeeeeeeeeeeeee0ffffff00777fff00777fff0eeee4444444224444444444444444444444444444444444444444444222444444222222222444eeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eeee44222222222222244444444444444444442222222224442222222222224442200000000000444eeeeeeeee
eeeeeeeeeeeeeeeeee00000e070eeeeeeee060eee4422000000000002242222222222222224220000000224220000000000224220eeeeeeeeeee0000eeeeeeee
eeeeeeeeeeeeeeeee077760e07600eeeeee060ee5422011111111111022200000000000002220111111102220111111111102220eeeeeeeeeeeeeeee0eeeeeee
eeeeeeeeeeeeeeeee077760e076760eee00760e54420111111111111104011111111111110401111d1111040110011118111040ee00000eeeee0000000eeeeee
eeeeeeeeeeeeeeee0776760e076760ee076760e4542011100001110110401111110000111040110000011040109901000001040e0545350eeee033330e0eeeee
eeeeeeeeeeeeeee07776760e076760ee076760e55420110dddd0105010401111105555011040110555011040109901055501040e0555550eeee033330000eeee
eeeeeeeeeeeeeee07767760e076760ee076760e44420110cccc0105010401111105555011040110555011040111111055501040e05d5350eeee0333353300eee
eeeeeeeeeeeeeee06666660077766600777666055420110dddd0105010401551105555011040110555011040106601055501040e0555550ee00033335550e0ee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00e45420110cccc0105010401551105555011040110555011040106601055501040e05d5350ee05555555550222e
eeeeeeeeeeeeeeeeee00000e060eeeeeeee0d0e54422010dddd0105010401111110440111040110555011040111111055501040e0555550ee044444422222222
eeeeeeeeeeeeeeeee0666d0e06d00eeeeee0d0ee5442222222222222222222222222222222222222222222222222222222222222222222222222222244444442
eeeeeeeeeeeeeeeee0666d0e06d6d0eee006d0eeee44222444444444444444444222222224444444444444444444444444444444444444444444444444444422
eeeeeeeeeeeeeeee066d6d0e06d6d0ee06d6d0eeee4442222222222222222224220000002242222222222242222222222222222222224222222222444444422e
eeeeeeeeeeeeeee0666d6d0e06d6d0ee06d6d0eeee0000000000000000000022201111110222000000000222000000000000000000022200000002222222422e
eeeeeeeeeeeeeee066d66d0e06d6d0ee06d6d0eeee50111111111111111110040110000110401111d111104011111111111111111110401151511024444422ee
eeeeeeeeeeeeeee0dddddd00666ddd00666ddd0eee5011111100001110011104010d6dd0104011000001104011111111111111111110401151511022224222ee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eeee501111109999010d0111040100dd0010401105550110401111111111111111111040115151102444222eee
eeeeeeeeeeeeeeeeee00000e0d0eeeeeeee050eeee50111009999990dd011104010400401040110555011040100000100000100000104010000010244222eeee
eeeeeeeeeeeeeeeee0ddd50e0d500eeeeee050eeee501106666666666650110401044440104011055501104010ddd01055d01055d010401055501024222eeeee
eeeeeeeeeeeeeeeee0ddd50e0d5d50eee00d50eeee501066dddddddddd501104010444401040110555011040105550105d50105d501040105550102222eeeeee
eeeeeeeeeeeeeeee0dd5d50e0d5d50ee0d5d50eeee501000000000000001110401004400104011055501104010555010d55010d550104010555022222eeeeeee
eeeeeeeeeeeeeee0ddd5d50e0d5d50ee0d5d50eeee22222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeee
eeeeeeeeeeeeeee0dd5dd50e0d5d50ee0d5d50eeeee2222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeee
eeeeeeeeeeeeeee055555500ddd55500ddd5550eeeeeeeeee22222222eee22222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeeeeeeeeeeeeeeeeee
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
