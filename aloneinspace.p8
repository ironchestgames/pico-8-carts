pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- the panspermia guy 1.0
-- by ironchest games

cartdata'ironchestgames_thepanspermiaguy_v1-dev10'

--[[ cartdata layout

1,2,3,4,5 = sample case
6,7,8 = sample storages
9 = fuel

11 - 25 = broken ship objects floor 1
26 - 40 = broken ship objects floor 2

41,42,43,44 = seed cannon samples

tools are: 1 = trap, 2 = deterrer, 3 = drill, 4 = spare part)
45 = tool carrying
46 = tool storage 1
47 = tool storage 2

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
poke(0x5600,5)    -- char width
poke(0x5601,7)    -- char width for high cars
poke(0x5602,5)    -- char height
poke(0x5603,0)    -- draw x offset
poke(0x5604,0)    -- draw y offset

poke(23152,0b0111110) -- 0x8e*8+0x5600
poke(23153,0b1100011) -- 0x8e*8+0x5601
poke(23154,peek(0x5f80) == 0 and 107 or 123)  -- 0x8e*8+0x5602
poke(23155,0b1100011) -- 0x8e*8+0x5603
poke(23156,0b0111110) -- 0x8e*8+0x5604

-- pink as transparent
palt(14,true)
palt(0,false)

-- utils
function flrrnd(_n)
 return flr(rnd(_n))
end

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

-- 78 token s2t (depends on trimsplit)
function s2t(_t)
 local _result={}
 local _kvstrings=trimsplit(_t)
 for _kvstring in all(_kvstrings) do
  local _kvpair=split(_kvstring,'=')
  local _value=_kvpair[2]
  for _i,_v in ipairs(split'true,false,nil') do
   if _value == _v then
    _value=({true,false})[_i]
   end
  end
  if type(_value) == 'string' then
   _value=sub(_value,2,#_value-1)
  end
  _result[_kvpair[1]]=_value
 end
 return _result
end

-- helpers
local bloodtypes={
 fire=split'20,10',
 droid=split'24,7',
 martian=split'28,11',
 taurien=split'32,8',
}

function getbloodobj(_x,_y,_bloodtype)
 local _type=bloodtypes[_bloodtype]
 return {
  sx=69,
  sy=_type[1],
  sw=10,
  sh=4,
  samplecolor=_type[2],
  action=takesampleaction,
  x=_x,
  y=_y,
  ground=true,
 }
end

function getscorepercentage()
 return dget(62)/1000 -- 1000 is top threshold
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

function addsampletoseed(_sample)
 add(seed,_sample)
 dset(40+#seed,_sample)
end

function clearseedcannon()
 dset(41,0)
 dset(42,0)
 dset(43,0)
 dset(44,0)
 seed={}
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

  dset(59,1) -- set ongoing game
  
  dset(60,0) -- last seed
  dset(61,0) -- seeds shot
  dset(62,0) -- score

  -- reset sample case + storages + seed samples + ship objects broken status
  for _i=1,44 do
   dset(_i,0)
  end

  dset(9,5) -- fuel

 else
  -- load saved sample case
  for _i=1,5 do
   local _savedvalue=dget(_i)
   if _savedvalue == 0 then
    samples[_i]=nil
   else
    samples[_i]=_savedvalue
   end
  end

  -- load seed cannon samples
  for _i=1,4 do
   local _savedvalue=dget(40+_i)
   if _savedvalue == 0 then
    seed[_i]=nil
   else
    seed[_i]=_savedvalue
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
    sy=52,
    sw=8,
    sh=8,
    sightradius=128,
    spd=0,
    huntingspd=2,
    c=0,
    alientype='droid',
    bloodtype='droid',
    behaviour=droidtalking,
   },
  },
 }

 deaddrawies={}

 particles={}
end

-- global constants
floorys={91,80}

toolnames=split'trap,deterrer,drill,spare part'

tools={
 s2t[[
  sx=28,
  sy=41,
  sw=4,
  sh=4,
  toolnr=1
 ]],
 s2t[[
  sx=19,
  sy=38,
  sw=3,
  sh=4,
  toolnr=2
 ]],
 s2t[[
  sx=24,
  sy=43,
  sw=4,
  sh=5,
  toolnr=3
 ]],
 s2t[[
  sx=28,
  sy=45,
  sw=4,
  sh=5,
  toolnr=4
 ]],
}

pickupactionfunc=function (_obj)
 if dget(45) != 0 then
  add(messages,'carrying another tool')
 else
  del(sector.planets[1].mapobjs,_obj)
  dset(45,_obj.toolnr)
 end
end

function closetrap(_trap)
 _trap.action={
  title='pick up trap',
  func=pickupactionfunc,
 }
 _trap.sy=41
 _trap.sw=4
 _trap.sh=4
 return _trap
end

function getnewtrap(_x,_y)
 return closetrap({
  x=_x,
  y=_y,
  sx=28,
  -- sy=41, -- note: set by closetrap
  -- sw=4,
  -- sh=4,
  behaviour=laidtrapbehaviour,
  toolnr=1,
 })
end

function getnewsparepart(_x,_y)
 local _tool=clone(tools[4])
 _tool.action={
  title='pick up spare part',
  func=pickupactionfunc,
 }
 _tool.x=_x
 _tool.y=_y
 return _tool
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

function laidtrapbehaviour(_behaviouree)
 local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
 if guy.runningc > 0 and _disttoguy < 2 then
  local _disttoguy=dist(_behaviouree.x,_behaviouree.y,guy.x,guy.y)
  local _drawies={guy,_behaviouree}
  closetrap(_behaviouree)
  resetplanetcamera(_drawies)
  deadinit(_drawies)
  return true
 end

 for _other in all(sector.planets[1].animals) do
  if _other != _behaviouree and dist(_behaviouree.x,_behaviouree.y,_other.x,_other.y) < 4 then
   -- kill animal
   del(sector.planets[1].animals,_other)
   add(sector.planets[1].mapobjs,getbloodobj(_other.x,_other.y,_other.bloodtype))
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
   add(messages,rnd(split'yikes,eek,uh-oh'))
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
 bear=s2t[[
  sx=0,
  sy=8,
  sw=8,
  sh=8,
  sightradius=36,
  spd=0.75,
  huntingspd=1,
  c=0
 ]],
 bat=s2t[[
  sx=0,
  sy=16,
  sw=7,
  sh=6,
  sightradius=32,
  spd=0.75,
  huntingspd=0.75,
  c=0
 ]],
 spider=s2t[[
  sx=0,
  sy=75,
  sw=12,
  sh=7,
  sightradius=38,
  spd=0.25,
  huntingspd=1.25,
  c=0
 ]],
 bull=s2t[[
  sx=0,
  sy=38,
  sw=8,
  sh=8,
  sightradius=28,
  spd=0.125,
  huntingspd=1,
  c=0
 ]],
 snake=s2t[[
  sx=0,
  sy=0,
  sw=8,
  sh=8,
  sightradius=36,
  spd=0.25,
  huntingspd=0.875,
  c=0
 ]],
 gnawer=s2t[[
  sx=0,
  sy=22,
  sw=8,
  sh=8,
  sightradius=48,
  spd=0.75,
  huntingspd=1.25,
  c=0
 ]],
 firegnawer=s2t[[
  sx=0,
  sy=30,
  sw=8,
  sh=8,
  sightradius=48,
  spd=0.75,
  huntingspd=1.25,
  c=0,
  bloodtype='fire'
 ]],
 slime=s2t[[
  sx=0,
  sy=46,
  sw=9,
  sh=6,
  sightradius=72,
  spd=0.25,
  huntingspd=0.5,
  c=0,
  bloodtype='martian'
 ]],
 droid=s2t[[
  sx=16,
  sy=52,
  sw=8,
  sh=8,
  sightradius=128,
  spd=0,
  huntingspd=2,
  c=0,
  bloodtype='droid'
 ]],
}


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
  sx='17,22,27',
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

plantsamplechances=s2t[[
 15=1,
 9=1,
 10=0.675,
 6=0.5,
 8=0.05,
 11=0.025,
 7=0.01
 ]]
 

planettypes={
 droidworld={
  wpal=split'133,130,1,1,1',
  groundcolor=133,
  surfacecolor=13,
  objtypes={
   { -- droidpillar1
    sx='68',
    sy='0',
    sw='9',
    sh='7',
    solid='1',
   },
   { -- droidpillar2
    sx='77',
    sy='0',
    sw='6',
    sh='5',
    solid='1',
   },
   { -- droidpillar3
    sx='68',
    sy='7',
    sw='9',
    sh='6',
    solid='1',
   },
   { -- droidpillar4
    sx='68',
    sy='13',
    sw='9',
    sh='7',
    solid='1',
   },
   { -- droidpillar5
    sx='83',
    sy='0',
    sw='9',
    sh='13',
    solid='1',
   },
   { -- droidpillar6
    sx='77',
    sy='5',
    sw='6',
    sh='4',
    solid='1',
   }
  },
  animaltypes=split'droid,droid,droid,droid,droid,droid,droid',
  objdist=18,
  droidworld=true,
 },
}


mapsize=255

groundcolors=split'1,2,3,4,5,6,7,9,13,14,15,18,19,20,21,22,23,27,28,29'
shadowcolors=split'17,18,19,20,21,22,6,na,4,na,na,na,29,8,31,na,na,16,1,18,18,5,26,na,na,na,3,1,21'

surfacecolors=split'1,4,3,4,5,6,7,na,9,na,na,na,13,13,9,na,na,2,3,2,4,5,3,na,na,na,3,1,13'

leafshadows=split'1,2,3,4,5,6,8,13,14,15,18,19,20,21,22,23,24,25,26,27,28,29,30,31'
leafcolors={
 split'19,28', -- 1
 split'4,24', -- 2
 split'27', -- 3
 split'25,30', -- 4
 split'3,22', -- 5
 split'7', -- 6
 nil,
 split'14', -- 8
 nil,nil,nil,nil,
 split'6,14,22', -- 13
 split'15', -- 14
 split'7', -- 15
 nil,nil,
 split'20,21', -- 18
 split'3,28', -- 19
 split'4', -- 20
 split'5,29', -- 21
 split'15', -- 22
 split'7', -- 23
 split'8', -- 24
 split'9', -- 25
 split'10,23', -- 26
 split'11,26', -- 27
 split'11,13', -- 28
 split'13', -- 29
 split'14,31', -- 30
 split'15', -- 31
}

stonecolors=split'1,2,3,4,5,6,7,8,9,12,13,14,18,19,20,21,22,23,27,28,29,30'
stonehighlights={
 split'2,3,5,13,19,20,24,28,29', -- 1
 split'3,4,5,13,14,22,24,25,29,30', -- 2
 split'6,11,12,26,27', -- 3
 split'9,14,25,30,31', -- 4
 split'3,6,8,13,14,15,22,24,25,30,31', -- 5
 split'3,7,27', -- 6
 split'6', -- 7
 split'9,14,30,31', -- 8
 split'10,15', -- 9
 nil,nil,
 split'6,7,15,23,26,31', -- 12
 split'6,12,14,15,23,31', -- 13
 split'15,31', -- 14
 nil,nil,nil,nil,
 split'2,5,21,29', -- 18
 split'3,13,22,27,28', -- 19
 split'4,13,22,24,30', -- 20
 split'2,4,5,13,28,29', -- 21
 split'6,9,15,31', -- 22
 split'7', -- 23
 nil,nil,nil,
 split'11,23,26', -- 27
 split'6,12,22,27,31', -- 28
 split'3,4,13,22,24,25', -- 29
 split'9,31', -- 30
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

function createplanettype()

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

 -- flora types
 local _objtypes={}
 local _objtypeslen=rnd(split'4,4,4,5,5,5,6,7,8,9') -- todo: good?

 while #_objtypes < _objtypeslen do
  local _a=flr((rnd(2)-1+getscorepercentage())*#objtypes)
  local _index=mid(1,_a,#objtypes)
  local _objtype=objtypes[_index]
  add(_objtypes,_objtype)
 end

 -- fauna types
 local _allanimaltypes=split'bear,bat,spider,bull,snake,gnawer,firegnawer,slime'

 local _animaltypes={}

 local _animaltypeslen=rnd(split'1,1,1,1,2,2,2,3,3,4')
 for _i=1,_animaltypeslen do
  add(_animaltypes,rnd(_allanimaltypes))
 end

 return {
  wpal=fixpal(_wpal),
  groundcolor=_groundcolor,
  surfacecolor=_surfacecolor,
  objtypes=_objtypes,
  animaltypes=_animaltypes,
  objdist=36-flrrnd(6)-flr((getscorepercentage())*20),
 }
end


function createplanet(_planettype)
 local _rndseed=rnd() -- todo: needed?
 srand(_rndseed)

 local _tooclosedist=_planettype.objdist

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
   sy=36,
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

 -- add wreck
 local _haswreck=nil
 if rnd() > 0.95 then
  _haswreck=true

  local _wrecktype=rnd{'martianwreck','taurienwreck'}
  local _x=flrrnd(mapsize-_tooclosedist)
  local _y=flrrnd(mapsize-_tooclosedist)

  if _wrecktype == 'martianwreck' then
   add(_mapobjs,{ -- ship wreck
    x=_x,
    y=_y,
    sx=58,
    sy=48,
    sw=14,
    sh=8,
    solid=true,
   })

   add(_mapobjs,{ -- debris
    x=_x+1,
    y=_y-2,
    sx=56,
    sy=50,
    sw=21,
    sh=9,
    ground=true,
   })

   add(_mapobjs,{ -- corpse
    x=_x-14,
    y=_y+2,
    sx=48,
    sy=54,
    sw=8,
    sh=4,
   })

   add(_mapobjs,getbloodobj(_x-23,_y+3,'martian'))

  else -- taurienwreck
   add(_mapobjs,{ -- ship wreck
    x=_x,
    y=_y,
    sx=49,
    sy=78,
    sw=10,
    sh=9,
    solid=true,
   })

   add(_mapobjs,{ -- small wing
    x=_x-8,
    y=_y-5,
    sx=44,
    sy=78,
    sw=5,
    sh=4,
    solid=true,
   })

   add(_mapobjs,{ -- debris
    x=_x-8,
    y=_y-1,
    sx=42,
    sy=83,
    sw=9,
    sh=6,
    ground=true,
   })

   add(_mapobjs,{ -- corpse
    x=_x-17,
    y=_y,
    sx=33,
    sy=85,
    sw=9,
    sh=3,
   })

   add(_mapobjs,getbloodobj(_x-26,_y+1,'taurien'))

   if rnd() > 0.75 then
    add(_mapobjs,getnewtrap(_x-32,_y-2))
   end
  end
 end

 -- add artifact
 if rnd() > 0.95 and not _haswreck then
  _x=flrrnd(mapsize-32)
  _y=flrrnd(mapsize-32)

  add(_mapobjs,rnd({getnewtrap,getnewsparepart})(_x,_y))

  local _ruincount=flrrnd(7)+4
  local _sy=rnd(split'104,112,120')
  for _i=0,_ruincount-1 do
   add(_mapobjs,{
    x=_x+cos(_i/_ruincount)*_ruincount*5,
    y=_y+sin(_i/_ruincount)*_ruincount*5,
    sx=rnd(split'15,23,31'),
    sy=_sy,
    sw=8,
    sh=8,
    solid=true,
   })
  end
 end


 -- add flora
 for _i=1,70 do
  local _x,_y,_tooclose
  local _tries=0
  repeat
   _x=flrrnd(mapsize-_tooclosedist)
   _y=flrrnd(mapsize-_tooclosedist)
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

  local _obj=clone(rnd(_planettype.objtypes))
  local _sxs=split(_obj.sx)
  local _idx=flrrnd(#_sxs)+1
  local _samplecolorindex0=0
  if type(_obj.samplecolor) == 'string' then
   local _samplecolors=split(_obj.samplecolor)
   _samplecolorindex0=flrrnd(#_samplecolors)
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

 -- add fauna
 local _animals={}
 local _loops=min(1+flr(dget(62)/100),50)
 for _i=1,_loops do
  if rnd() < 1 - 1 / #_planettype.animaltypes then
   local _typ=rnd(_planettype.animaltypes)
   local _animal=clone(animaltypes[_typ])
   _animal.x=flrrnd(mapsize)
   _animal.y=flrrnd(mapsize)
   if dist(mapsize/2,mapsize/2,_animal.x,_animal.y) > 60 then
    _animal.targetx=_animal.x
    _animal.targety=_animal.y
    _animal.typ=_typ
    _animal.bloodtype=_animal.bloodtype or 'taurien'
    _animal.behaviour=sighthunting
    add(_animals,_animal)
   end
  end
 end

 return {
  rndseed=_rndseed,
  mapobjs=_mapobjs,
  wpal=_wpal,
  groundcolor=_planettype.groundcolor,
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

 local _planetcount=rnd(split'1,1,2,2,2,2,3,3')

 sector={
  planets={}
 }

 for _i=1,_planetcount do
  if rnd() < (getscorepercentage())*0.25  then
   add(sector.planets,createplanet(planettypes.droidworld))
  else
   add(sector.planets,createplanet(createplanettype()))
  end
 end

end

-- planet scene

function resetplanetcamera(_drawies)
 camera()

 local _diffx=_drawies[2].x-guy.x
 local _diffy=_drawies[2].y-guy.y
 _drawies[2].x-=_diffx+62
 _drawies[2].y-=_diffy+63

 guy.x=62
 guy.y=65
end

function planetinit()
 lookinginsamplecase=nil

 factions.droid.landingc=180
 factions.droid.talkingc=140

 guy.x=mapsize/2
 guy.y=mapsize/2

 guy.sx=0
 guy.sy=83
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
  elseif btn(3) then
   _movey-=_spd
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
   messages[1]=rnd(split'*pant pant,*huff puff,*wheeeeze')
   guy.panting=true
  end


  for _obj in all(sector.planets[1].mapobjs) do
   if dist(guy.x-_movex,guy.y-_movey,_obj.x,_obj.y) < _obj.sw * 0.5 and (guy.runningc > 0 and _obj.solid or _obj.lava) then
    _movex*=-3
    _movey*=-3
    guy.panting=true
    guy.runningc=24
    messages[1]=rnd(split'ouch,ouf,argh,ow,owie')
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
  elseif dget(45) != 0 then
   if dget(45) == 1 then
    add(sector.planets[1].animals,{
     x=guy.x,
     y=guy.y,
     targetx=guy.x,
     targety=guy.y,
     sx=28,
     sy=38,
     sw=7,
     sh=3,
     toolnr=1,
     behaviour=laidtrapbehaviour,
    })
    dset(45,0)
    sfx(34)
   end
  else
   guy.talkingc=8
   sfx(rnd{0,1,2})
  end
 end

 guy.talkingc-=1
 guy.samplingc-=1

 if guy.talkingc > 0 then
  guy.sx=18
 end

 guy.sy=83
 if dget(45) != 0 then -- carrying tool
  guy.sy=90
 end
 if guy.sunken then
  guy.sy-=1
 end

 if (_movex != 0 or _movey != 0) then
  guy.sx=guy.walkingc > 3 and 12 or 6
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

function drawseed(_spin)
 for _i=1,#seed do
  local _ii=_i-1
  pset(49+_ii%2,76+flr(_ii/2),seed[_i])
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

function toolstorageinputhandler(_obj)
 if _obj.inrange and btnp(4) then
  local _carriedtool=dget(45)
  dset(45,dget(45+_obj.index))
  dset(45+_obj.index,_carriedtool)
  sfx(35)
 end
end

function toolstoragedraw(_obj)
 local _storedtool=dget(45+_obj.index)
 if _obj.inrange then
  if _storedtool != 0 then
   actiontitle='\014\x8e\015 pick up '..toolnames[_storedtool]
  elseif dget(45) != 0 then
   actiontitle='\014\x8e\015 store '..toolnames[dget(45)]
  else
   actiontitle='tool storage'
  end
 end

 if _storedtool != 0 then
  local _tool=tools[_storedtool]
  sspr(_tool.sx,_tool.sy,_tool.sw,_tool.sh,_obj[1]-1,75)
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
     if btnp(4) and not travelblocked then
      traveling='down'
      travelc=30
      sfx(27)
     end
    end,
    draw=function(_obj)
     if _obj.inrange and not travelblocked then
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
      if _obj.c == 0 then
       sampleselectinputhandler(_obj)

       if _obj.inputlastframe == true and not btn(4) then
        _obj.inputlastframe=nil
        if #samples > 0 and #seed < 4 then
         addsampletoseed(removefromsamplecase(samplesel))
         sfx(14)
        elseif #seed == 4 then
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
       travelblocked=true
       actiontitle=''
       _obj.c-=1
       if _obj.c % 30 < 15 then
        sspr(89,78,13,7,42,73)
       end

       if _obj.c == 0 then
        if not (_obj.broken and rnd() > 0.675) then
         local _seedscore=getseedquality()
         dset(60,_seedscore)
         dset(61,dget(61)+1)
         dset(62,dget(62)+_seedscore)
         _obj.seedy=60
         clearseedcannon()
         
         if not factions.droid.alertc then
          factions.droid.alertc=300+flrrnd(300)
         else
          factions.droid.alertc=max(1,factions.droid.alertc-90)
         end

         sfx(13)
        else
         sfx(31)
        end
       end

       pset(43,75,11)

      elseif _obj.inrange and #seed == 4 then
       actiontitle='\014\x8e\015 shoot seed'
       pset(43,75,11)
      elseif _obj.inrange and #samples > 0 then
       actiontitle='\014\x8e\015 add sample'
      end

      if _obj.seedy then
       if _obj.seedy > 30 then
        sspr(104,85,6,6,47,57)
       end
       _obj.seedy-=8
       pset(43,75,11)
       rectfill(49,_obj.seedy,50,_obj.seedy+1,7)
       if _obj.seedy < 0 then
        _obj.seedy=nil
       end
      else
       drawseed(#seed == 4)
      end

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
   { -- tool storage 1
    72,76,
    index=1,
    cantbreak=true, -- todo: blow off the tool
    inputhandler=toolstorageinputhandler,
    draw=toolstoragedraw,
   },
   { -- tool storage 1
    78,82,
    index=2,
    cantbreak=true, -- todo: blow off the tool
    inputhandler=toolstorageinputhandler,
    draw=toolstoragedraw,
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
       print((_obj.broken and rnd() > 0.5 and 'la5t sfed: ' or 'last seed: ')..tostr(flrrnd(9999)),23,42,6)
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
 pal(split'1,130,3,133,5,6,7,8,9,137,11,12,13,14,15',1)

 stars={}

 for i=1,30 do
  add(stars,{
   x=flrrnd(128),
   y=flrrnd(128),
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
  showrepairtitle=nil
  showbrokentitle=nil
  travelblocked=nil

  for _i=1,2 do
   local _floorobjs=shipobjs[_i]
   for _obj in all(_floorobjs) do
    _obj.firstframe=nil
    if _i == guy.floor and mid(_obj[1],guy.x,_obj[2]) == guy.x then
     if not _obj.inrange then
      _obj.firstframe=true
     end
     _obj.inrange=true
     debug('dget(45)')
     debug(dget(45))
     if dget(45) == 4 and _obj.broken and not _obj.cantbreak then -- carrying spare part
      showrepairtitle=true
      if btnp(4) then
       dset(45,0)
       -- sfx() -- todo
       _obj.broken=nil
      end
     elseif _obj.inputhandler then
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
    factions.droid.firingc=90+flrrnd(60)
   end

   factions.droid.firingc-=1

   if factions.droid.firingc == 0 then
    breakrandomshipobj()
    factions.droid.firingc=nil
    sfx(rnd{19,20})
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
   _s.y=flrrnd(128)
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
 if not guy.incryo then
  sspr(32,dget(45) == 0 and 41 or 46,5,5,guy.x-2,guy.y-5)
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

 -- draw actiontitle, repairtitle, and brokentitle
 if showrepairtitle then
  print('\014\x8e\015 repair',48,32,9)
 elseif showbrokentitle then
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

 pal(split'1,136,3,4,5,6,7,136,9,137,138,8,13,14,15',1)
 
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
ee00ee00ee00ee00e33eeeeeeeaaeeee0cc9cc0e0f8880e094440ee0c0eeee0c0eee05757550e022201e055250ee055505055500550505050505050505050550
ee010010ee010010eeeeeeaeeceeceea09ccc30e0f0f0ee09090eee0000eeeee000e05755550eeeeeee05752550e055505055500555055505550555055505550
ee011110ee011110eeeeeeececeecece0ccca30e000eeee000eeee011110eeee060e05552220eeeeeee05552250e055550555500555555555555555555555550
e0117170e0117170eee333ececeececee0c330e08880ee04440ee01dddd10eee000e02252550eeeeeee05252250e055555555500ddddddddddddddddddddddd0
0111111001111110eeeeeeeeee88eeeeee000eee09000ee0a000e0dddddd0eee050e022222201eeeeee02222220100000000000e00000000000000000000000e
0111111001111110eeeeee8eeceecee8e0ccc0ee098880e0a4440e0dddd0eeee050ee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000e
0111111001111110eeeeeeececeecece0ccacc0e09090ee0a0a0eee0000eeeee050e05752550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee066666660
01010010e010110eeeeeeeececeecece0accc30e000eeee000eeeee0000000eee0ee05555520eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee060000060
000e000eeeeeeeeeeeeeeeeeeebbeeee0ccc83008880ee04440eee011111110eeeee05722520eeeeee1111111111111111111111111111111eeeeeeeeeeeeeee
0cc0cc0eee0eeeeeeeeeeebeeceeceebe0c330ee0a000ee08000e01ddddddd10eeee05552520eeee1111111111111111111111111111111111111eeeeeeeeeee
e0ccc0eee0c0eeeeeeeeeeececeececeee000eee0a8880e0844400ddddddddd0eeee05752520eee1111111111111111111111111111111111111111eeeeeeeee
ee0c0eee0ccc0eeeeeeeeeececeececee0ccc0ee0a0a0ee08080ee0dddddddd0eeee022222201ee111111111111111111111111111111111111111111eeeeeee
eee0eeee0c0c0eeeeeeeeeeeee77eeee0cc8cc0e000eeee000eeeee00ddddd0eeeeeeeeeeeeaaaa11111111111111111111111111111111111111111111eeeee
eeeeeeee00e00eeeeeeeee7eeceecee708ccc3008880ee04440eeeeee00000eeeeeeeaaeeeeeeee1111111111111111111111111111111111111111111111eee
eee0000eeeeeeeeeeeeeeeececeecece0ccc830e0b000ee0b000eee0000000eeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111111e
ee077770eee0000eeeeeeeececeececee0c330ee0b8880e0b4440e0aaaaaaa0eeeeeeeeeeeaaaee1111111111111111111111111111111111111111111111111
ee078780ee077770eeeeeeeeeeeeeeeeee000eee0b0b0ee0b0b0e0a9999999a0eeeeeeeeeee77771111111111111111111111111111111111111111111111111
e0777770ee078780eeeeeeeeeeeeeeeee0ccc0ee000eeee000eee09999999990eeeee77eeeeeeeee11111111111111111111111111111111111111111111111e
07778880e0777770eeeeeeeeeeeeeeee0ccbcc008880ee04440eee0999999990eeeeeeeeeeeeeeeeeeee11111111111111111111111111eeeeeeeeeeeeeeeeee
0777888007778880eeeeeeeeeeeeeeee0bccc30e07000ee07000eee00999990eeeeeeeeeee777eeeeeeee11111111111111111111eeeeeeeeeeeeeeeeeeeeeee
0777777007777770eeeeeeeeeeeeeeee0cccb30e078880e074440eeee00000eeeeeeeeeeeeebbbbe1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
07070070e070770eeeeeeeeeeeeeeeeee0c330ee07070ee07070eeeee0000eeeeeeeebbeeeeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeeeeeeeeeeeeeeeeeeeee000eeeeeeee00e0eeee0ee0aaaa0eeeeeeeeeeeeeeeeee111eeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee088880eee0000eeceeeeeeeecceeece0ccc0ee0eee040040ee0400a9999a0eeeeeeeeeeebbbeee1111eeeeeeee1eee11eeeeeee1eeeee1eeeeeeeeeeeeeeee
ee089890ee088880eeceecceeceecece0cc7cc0040e040ee040e01009999990eeeeeeeeeeee8888e11111eeeeee1eeee111eeeeee1eeee1eee1eeeeeeeeeeeee
e0888880ee089890eececeececeecece07ccc30e040010ee010040ee099990eeeeeee88eeeeeeeee111111eee1111eee1111eee1e1ee1111ee11eeeeeeeeeeee
0888aaa0e0888880eececeececeecece0ccc630e01040eeee0410eeee0000eeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111eeeeeeee1ee
0888aaa00888aaa0eeeeeeeeeeeeeeeee0c330eee010eeeeee040eeeeeeeeaeeeeeeeeeeee888eeee1111111111111111111111111111111111111eeeeee1eee
0888888008888880eeeeeeeeeeeeeeeeeeeeeeeee040eeeeee040eeeeeeeaeee00eee0000eeeeeeee11111111111111111111111111111111111111eee1111ee
08080080e080880eeeeeeeeeeeeeeeeeeeeeeeee04110eeee04110eeeaaaeaae0d0e0aa990eeeee1111111111111111111111111111111111111111111111111
eee0ee0eeee0ee0eeeee0ee0ee0e00e0e00eeeeeeeeeeeeeeeeeeeeaaeeeeeee0dd0aaaaa900eee1111111111111111111111111111111111111111111111111
eee0000eeee0000eeee0a00900700606060eeeeeeeeeeeeeeeeeeeeeeeeeeaa05666666666660ee1111111111111111111111111111111111111111111111111
0e044440ee044440eee060060060055d550eeeeeeeeeeeeeeeeeeeeaaaeeaee05dddddddddd660eeeeee1111111111111111111111111111111111111111111e
e044707000447070eee0600600600000e00eee00eee00eeeeeeeeeeeeeaaeeee00000000000000ee11111111111111111111111111111111111111111111111e
e0444040e0444040eee06006006005600ff0e0ff0e0ff0eeeeeeeeeeeeeeaaeee111111111111eee1111111111111111111111111111111111111111111111ee
e0444440e0444440eeeeeeee000006500ff0e0ff0e0ff0eeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeeee111111111111111111111111111111111111111111111eee
e000000ee000000eeeeeeeee066005600aa0e0aa0e0aa0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111111111111111111111111111111eeee
e0ee0e0eee00e0eeeeeeeeee0dd0000e0aa0e0a00e00a0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111e11111111eeeeeeeeeee1111111eeeeeeee
eee0000eeeeeeeeeeeeeeeeee06009b0e00eee00eee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeee11111111111111eeeeeeeeee
ee0bbbb0eee00000eeeeeeeeee0e09900ff0e0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0c0eeeee0eeeeeeeeeeee1111111111111111111111eeeeee
e0bb7b7b0e0bbbbb0eeeeeeeeeee0bb00ff0e0ff0e0ff0eeeeeeeeeeeeeeee00000eeeeeeeeeeee0cc0eee0c0eeeeeeee1111111111111111111111111111eee
e0bbbbbb00bbb7b7b0eeeeeeeeee00000aa600aa600aa60eeeeeeeeeeeeee0ddddd00eeeeeeeee0cc30eee0cc0eeeeee111111111111111111111111111111ee
e0bbbbbb00bbbbbbb0eeeeeeeeeeeeee0aa0e0a00e00a0eeeeeeeeeeeeee0d66666dd0eeeeedde0cc30ee0cc30eeeee11111111111111111111111111111111e
ee000000ee0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0d6d000d6dd0eeeeeee0cc330e0cc330eee1111111111111111111111111111111111
ee0000eeee0000eeee0000eeee0000eeeeeeee00eeeeeeeeeeeeeeeeee0d6d07bb0d6dd0eeeee0cc3330e0cc330eee1111111111111111111111111111111111
e0dddd0ee0dddd0ee0dddd0ee0dddd0eeeeee0dd0eeeeeeeeeeeeeeeee0dd07bbbb0d6d0eeeeee0c330e0cc3330eeee11111111111111111111111111111111e
e0d7d70ee0d7d70ee0d7d70ee0d7d70eeeee0dd50eeeeeeeeee0eeeeeeeed0bbbbb0d6d0eeeeeee010eee00100eeeeeeeeee1111111111111111111111eeeeee
e00ddd0eee0ddd0eee0ddd0eee0ddd0eeee0dddd0eeeeeeee6e60eeeddeeeeeebb0dddd0eddeeee010eeee010eeeeeeeeeeeeeee11111111111111eeeeeeeeee
0d0000d0e000000ee000000ee000000eee0dd7d50eeeeeee06bb000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111eeeeeeeeeee
050d00500d0d00d00d0d00d00d0d00d0ee0dd7dd0eeeeeee06bbddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111eeeeeeeeeeee
05050050050500500505005005050050e0ddd7d50eeeeeeeeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeee
ee0500ee050ee0500505005005050050e0d7d7dd0eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeee
eeeeeeeeeeeeeeeeee000000eeeeeeeee0d7d7dd50eeeeee0bbb770eeeeeeeeeee0000eeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeee1eeeeeee0c0eeeeee0eeee
0000000000000000000a88a0eeeeeeee0dddd7ddd0eee000bbbbbb7000eeeee0e060600eee060600eeeeeeeeeeee00ee00eeeeeee1eeeeeeee0c0eeeee0c0eee
0a88a00a88a00a88a0e0dd0eeeeeeeee07d5d7dd50e00d60bbbbbbb06d00ee060606050ee0606050eee0000eeeee060060eeee111e11eeeee0cc0eeeee0c0eee
e0880ee0880ee0880ee0880eeeeeeeee0dd5d7ddd00d6dd600000006dd6d0060606050ee0606050eee066660eeee006660ee11eeeeeeeeeeee0cc0eeee0cc0ee
005580085500005500005500eeeeeeee07ddd7dd500dd6dd6666666dd6dd0060606050ee0606050eee0656560eee0656560eeeeeee11eeeeee0c30eee0ccc0ee
08dd0ee0dd8008dd8008dd80eeeeeeee0dd7d7ddd0e00d66ddddddd66d00e0606060111e06060111ee06666660ee06666660111ee1eeeeeeee0cc30eee0cc30e
e050eeee050ee0550ee0550eeeeeeeee05d7dddd50eee0000000000000eeeeeeee0000eeeee0000eeee0000eeeee00ee00eeeee11eeeeeeee0cc300eee0c300e
eee0eeeee0eeeee0eeeee0eeeeeeeeee05d7d7ddd0eeee11111111111eeeeee0e0f0f00eee0f0f00ee0ffff0eeee0f00f0eeeeeee11eeeeee0cc330ee0cc330e
e0000ee0000ee0000ee0000eeeeeeeee05d7d7d550eeeeeeeeeeeeee0000ee0f0f0f050ee0f0f050ee0f5f5f0eee00fff0eeeeeeeee1eeee0ccc3330e0ccc330
07666007666007666007bb60eeeeeeee0dddddddd0eeeeeeeeeeeee08880e0f0f0f050ee0f0f050eee0ffffff0ee0f5f5f0eeeeeeeeeeeee00ccc3300ccc3300
06bb6006bb6006bb6006bb60eeeeeeee05d5d5d550eeeee0000000085550e0f0f0f050ee0f0f050eeeeeeeeeeeee0ffffff0eeeeeeeeeeeee0c3330ee0c3330e
06bb6006bb6006bb60065560eeeeeeee0dd555dd0eeeee066d0555588880e0f0f0f0111e0f0f0111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0cc333300cc33330
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055555550eeee06ddd0588588880eeee000eeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeee0eeeeeeee0001100000011000
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055555550eee06dddd05555888850ee04420eeee00eeeeeee040eeeeeeeeeee00eeeee040eeeeeeeee0110eeee0110ee
e0dd0ee0dd0ee0dd0ee0dd0eeeeeeeee055050550ee000000055000000850ee04220eee0440eeeee0420eee000eeee0440eee0420eeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee000eeeeeeeeeeeeee0000000ee0885555550888850850e04220eeee04220eee04220ee04420eee04220e04220eeeeeeeeeeeeeeeeeeeeeee
eeee000eeeeeeee05550eeeeeeeeeeeeeeeeeeeeee000000000000000000eee02220ee042220eee0422200422220e042220e042420eeeeeeeeeeeeeeeeeeeeee
e0e05550eeeeeee05055000eeeeeeeeee1111111eee11111111111111111eee04220ee0422240ee042220eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefeeeee
0e0050500eeeeee050500ee0eeeeeeeeeeeeeeeeeeeeee00eeeee0eeeeeeee042240e04224420e0422240eeee8888888888888eeeeeeeeeeeeeeeeefeecefeee
0ee0000dd0eeeee0000dd0eeeeeeeeeeeeeeeeeeeeeee050eeee080eeeeee0422422004222220e0422420eeee888888eeee888eeeeeeeeecccccceeecceeceef
eeee0e09d90eeee0e009d90eeeeeeeeeeeeeeeeeeeee0850eee08880eeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee88888eeeeee88cccceeccccccc66eeeecefecce
eeee0ee0000eeee0eee000eeeeeeeeeeeeeeeeeeeee08850ee0558880eeeeeee00eeeeeeeeeeeeee040eeeeee88888eeeeee88ddddccc6c66c666eefeccefcee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee05555800eeeeee0440eeeee000eeeee040eeeeee88888eeeeee88cccceeccccccc66eeecceeeece
eeeeeeeeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeddee00055585050eeeeee04220eee04440eee04220eeeee88888eeeeee88ddddeeeeecccccceeeeceeeece
ee00eeee00eeee00eee0ff0eeeeeeeeeeeeeeeeeeeeeeeddd558508850eeee042220ee042220eee04220eeeee888888eeee888cccceeeee0000eeeeeee9eeeee
e0ff0ee0ff0ee0ff0ee0ff0eeeeeeeeeeee00eeeeeeeeeeedd550888850eee04220eee042220eee042240eeee101eeeeeeeee9eeee6eee06ddd0eee9eece9eee
e0ff0ee0ff0ee0ff0ee0880eeeeeeeeeee00a0000eeeedeeeee5500000eeee042220e04224420e0422420eeee101eeeeeeee999eee6e6e06ddd0eeeecceecee9
0daa0e0daa0e0daa0e0daa0eeeeeeeeee080885850eeeeeeeeeeeeeeeeeee0422222004242220e0422420eeee101110001199999ee6eee0dddd0eeeeece9ecce
0daa0e0da0ee0d0a0e0daa0eeeeeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011099901e999ee66e6e05dd50eee9ecce9cee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1011109990e999ee6666e055550eeeecceeeece
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1010000990eaaae455555055550eeeeeceeeece
ee00eeee00eeee00eeeeeeeeeeeeeeeeeeeeeee444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0ff0ee0ff0ee0ff0eeeeeeeeeeeeeeeeeeeeee42444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0ff0ee0ff0ee0ff0eeeeeeeeeeeeeeeeeeeeeee424424444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0daa600daa600daa60eeeeeeeeeeeeeeeeeeeeee42444244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0daa0e0da00e0d0a0eeeeeeeeeeeeeeeeeeeeeeee424442444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eee42444424444444eeeeeeeeee244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee00000e040eeeeeeee020eeee424444244444444eeeeeeeee2222eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee044420e04200eeeeee020eeee42444442444444444eeeeeee2444eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee044420e042420eee00420eeeee424444424444444444eeeee2444eeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee0442420e042420ee042420eeeee42444444222222222222ee222222eeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee04442420e042420ee042420eeeee44244422444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee04424420e042420ee042420eeeee4424224442222222222222222222222222222222222222222222444444444444444444eeeeeeeeeeeeeee
eeeeeeeeeeeeeee022222200444222004442220eeee4444444224444444444444444444444444444444444444444444222444444222222222444eeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eeee44222222222222244444444444444444442222222224442222222222224442200000000000444eeeeeeeee
eeeeeeeeeeeeeeeeee00000e070eeeeeeee0f0eee4422000000000002242222222222222224220000000224220000000000224220eeeeeeeeeee0000eeeeeeee
eeeeeeeeeeeeeeeee0777f0e07f00eeeeee0f0ee54220111111111110222000000000000022201111111022201dd1111dd102220eeeeeeeeeeeeeeee0eeeeeee
eeeeeeeeeeeeeeeee0777f0e07f7f0eee007f0e54420111111111111104011111111111110401111d1111040111111111111040ee00000eeeee0000000eeeeee
eeeeeeeeeeeeeeee077f7f0e07f7f0ee07f7f0e4542011100001110110401111110000111040110000011040111111111111040e0545350eeee033330e0eeeee
eeeeeeeeeeeeeee0777f7f0e07f7f0ee07f7f0e55420110dddd0105010401111105555011040110555011040111111111111040e0555550eeee033330000eeee
eeeeeeeeeeeeeee077f77f0e07f7f0ee07f7f0e44420110cccc0105010401111105555011040110555011040111111111111040e05d5350eeee0333353300eee
eeeeeeeeeeeeeee0ffffff00777fff00777fff055420110dddd0105010401551105555011040110555011040111111111111040e0555550ee00033335550e0ee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00e45420110cccc0105010401551105555011040110555011040111111111111040e05d5350ee05555555550222e
eeeeeeeeeeeeeeeeee00000e070eeeeeeee060e54422010dddd0105010401111110440111040110555011040111111111111040e0555550ee044444422222222
eeeeeeeeeeeeeeeee077760e07600eeeeee060ee5442222222222222222222222222222222222222222222222222222222222222222222222222222244444442
eeeeeeeeeeeeeeeee077760e076760eee00760eeee44222444444444444444444222222224444444444444444444444444444444444444444444444444444422
eeeeeeeeeeeeeeee0776760e076760ee076760eeee4442222222222222222224220000002242222222222242222222222222222222224222222222444444422e
eeeeeeeeeeeeeee07776760e076760ee076760eeee0000000000000000000022201111110222000000000222000000000000000000022200000002222222422e
eeeeeeeeeeeeeee07767760e076760ee076760eeee50111111111111111110040110000110401111d111104011111111111111111110401151511024444422ee
eeeeeeeeeeeeeee066666600777666007776660eee5011111100001110011104010d6dd0104011000001104011111111111111111110401151511022224222ee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eeee501111109999010d0111040100dd0010401105550110401111111111111111111040115151102444222eee
eeeeeeeeeeeeeeeeee00000e060eeeeeeee0d0eeee50111009999990dd011104010400401040110555011040100000100000100000104010000010244222eeee
eeeeeeeeeeeeeeeee0666d0e06d00eeeeee0d0eeee501106666666666650110401044440104011055501104010ddd01055d01055d010401055501024222eeeee
eeeeeeeeeeeeeeeee0666d0e06d6d0eee006d0eeee501066dddddddddd501104010444401040110555011040105550105d50105d501040105550102222eeeeee
eeeeeeeeeeeeeeee066d6d0e06d6d0ee06d6d0eeee501000000000000001110401004400104011055501104010555010d55010d550104010555022222eeeeeee
eeeeeeeeeeeeeee0666d6d0e06d6d0ee06d6d0eeee22222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeee
eeeeeeeeeeeeeee066d66d0e06d6d0ee06d6d0eeeee2222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeee
eeeeeeeeeeeeeee0dddddd00666ddd00666ddd0eeeeeeeeee22222222eee22222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeeeeeeeeeeeeeeeeee
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
00030000214201c4401c4402144021440114200340000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
