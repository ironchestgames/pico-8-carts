pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- the panspermia guy 1.0
-- by ironchest games

cartdata'ironchestgames_thepanspermiaguy_v1'

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

last seed
50 = sample 1 color
51 = sample 2 color
52 = sample 3 color
53 = sample 4 color

59 = is ongoing game

61 = current nr of seeds
62 = current score
63 = highscore

--]]

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

poke(0x5f5c,-1) -- disable btnp auto-repeat btnp

-- note: set special char o-button to look like c-button if gpio 1 is set, pico8_gpio[0]=1
poke(0x5600,unpack(split'5,7,5,0,0'))
poke(0x5a70,unpack(split('62,99,'..(peek(0x5f80) == 0 and 107 or 123)..',99,62')))

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
 local _result=''
 for _i=1,#_str do
  local _chr=_str[_i]
  if _chr != ' ' and _chr != '\n' then
   _result..=_chr
  end
 end
 return split(_result)
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

-- 77 token s2t (depends on trimsplit)
function s2t(_t)
 local _result,_kvstrings={},trimsplit(_t)
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

function mr(_t1,_t2) -- mergeright
 for _k,_v in pairs(_t2) do
  _t1[_k]=_v
 end
 return _t1
end

function s2tmr(_t1,_t2)
 return mr(s2t(_t1),_t2)
end

-- helpers
function mapwrap(_n)
 return wrap(0,_n,mapsize)
end

local bloodtypes={
 fire=split'20,10',
 droid=split'25,7',
 martian=split'30,11',
 taurien=split'35,8',
}

function getbloodobj(_x,_y,_bloodtype)
 local _type=bloodtypes[_bloodtype]
 return s2tmr('sx=69,sw=10,sh=5,ground=true',{
  x=_x,y=_y,
  sy=_type[1],
  samplecolor=_type[2],
  action=takesampleaction,
 })
end

function getscorepercentage()
 return dget(62)/640 -- 640 is top threshold
end

function disttoguy(_other)
 return dist(_other.x,_other.y,guy.x,guy.y)
end

function drawtalk()
 if talk then
  local _talker=talk.talker
  local _y=_talker.y-33
  local _x1=_talker.x-talk.strwidth/2
  if _talker == guy then
   _x1=mid(1,_x1,127-talk.strwidth/2)
  end
  local _x2=_x1+talk.strwidth+2
  rectfill(_x1-1,_y-1,_x2+1,_y+9,talk.strcolor)
  rectfill(_talker.x-1,_y,_talker.x+1,_talker.y-8,talk.strcolor)
  rectfill(_x1,_y,_x2,_y+8,talk.bgcolor)
  line(_talker.x,_y,_talker.x,_talker.y-8,talk.bgcolor)
  print(talk.str,_x1+2,_y+2,talk.strcolor)
  talk.c-=1
  if talk.c == 0 then
   talk=nil
  end
 end
end

function addtalk(_str,_talker,_bgcolor,_strcolor,_dur)
 if talk == nil or _str != talk.str then
  talk={
   c=_dur or 24,
   str=_str,talker=_talker,bgcolor=_bgcolor,strcolor=_strcolor,strwidth=#_str*4,
  }
 end
end

function guytalk(_str)
 addtalk(_str,guy,7,0)
end

function droidtalk(_str,_droid)
 addtalk(_str,_droid,13,7)
end

function martiantalk(_str,_alien)
 addtalk(_str,_alien,6,13,44)
end

function taurientalk(_str,_alien)
 addtalk(_str,_alien,5,6,44)
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

function clearseedcannon()
 for _i=41,44 do
  dset(_i,0)
 end
 seed={}
end

local floordatapos={10,25}
local hitpos
function breakrandomshipobj()
 local _floorindex=rnd{1,2}
 local _objindex=flr(1+rnd(#shipobjs[_floorindex]))
 dset(floordatapos[_floorindex]+_objindex,1)
 local _obj=shipobjs[_floorindex][_objindex]
 _obj.broken=true
 if _obj.datapos then
  dset(_obj.datapos,0)
 end
 hitpos={x=_obj.x1+(_obj.x2-_obj.x1),y=floorys[_floorindex]}
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
   if btn(4) then
    print('\fa\x8b  \x91',_lx-11,_y+16)
   end
  end
 end
end

function updatedroidalert()
 if droidalertc and droidalertc > 0 then
  droidalertc-=1
  if droidalertc == 1 then
   sfx(21,2)
  end
 end
end

function resetgame()
 guy={incryo=true}
 samples,seed,samplesel,lookinginsamplecase={},{},1
 resetshipobjs()

 if dget(59) == 0 then -- no ongoing game
  for _i=1,62 do -- 63 is highscore
   dset(_i,0)
  end
  dset(9,5) -- starting fuel
  dset(59,1) -- set ongoing game
 else
  -- load saved sample case
  for _i=1,5 do
   local _savedvalue=dget(_i)
   samples[_i]=_savedvalue != 0 and _savedvalue or nil
  end

  -- load seed cannon samples
  for _i=1,4 do
   local _savedvalue=dget(40+_i)
   seed[_i]=_savedvalue != 0 and _savedvalue or nil
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

 traveling,travelc='warping',60
 deaddrawies,particles,talk,alienhostile,alienfiringc={},{}
end

-- global constants
mapsize,floorys,toolnames=255,split'91,80',split'trap,deterrer,drill,spare part'

tools={
 s2t'sx=28,sy=41,sw=4,sh=4,toolnr=1',
 s2t'sx=16,sy=38,sw=3,sh=4,toolnr=2',
 s2t'sx=20,sy=43,sw=4,sh=5,drillc=150,toolnr=3',
 s2t'sx=28,sy=45,sw=4,sh=4,toolnr=4',
}

pickupactionfunc=function (_obj)
 if dget(45) != 0 then
  guytalk('carrying another tool')
 else
  del(sector[1].mapobjs,_obj)
  dset(45,_obj.toolnr)
 end
 sector[1].hasartifact=nil
end

function closetrap(_trap)
 return mr(_trap,s2tmr('sy=41,sw=4,sh=4',{
  action={title='pick up trap',func=pickupactionfunc},
 }))
end

function getnewtool(_x,_y,_toolindex)
 return mr(clone(tools[_toolindex]),{
  x=_x,y=_y,
  action={title='pick up '..toolnames[_toolindex],func=pickupactionfunc},
 })
end

function getnewtrap(_x,_y)
 return closetrap(s2tmr('sx=28,toolnr=1',{
   x=_x,y=_y,behaviour=laidtrapbehaviour,
 }))
end

function getnewdeterrer(_x,_y) return getnewtool(_x,_y,2) end
function getnewdrill(_x,_y) return getnewtool(_x,_y,3) end
function getnewsparepart(_x,_y) return getnewtool(_x,_y,4) end

takesampleaction={
 title='take sample',
 func=function (_target)
  if #samples == 5 then
   guytalk('sample case is full')
   sfx(0)
  else
   _target.sy+=_target.sh-1
   _target.sh=1
   _target.action,_target.solid,_target.sunken=nil
   addtosamplecase(_target.samplecolor)
   guy.samplingc=20
   sector[1].haswreck=nil
   sfx(8)
  end
 end,
}

function laidtrapbehaviour(_behaviouree)
 if guy.runningc > 0 and disttoguy(_behaviouree) < 2 then
  local _drawies={guy,_behaviouree}
  closetrap(_behaviouree)
  resetplanetcamera(_drawies)
  deadinit(_drawies)
  return true
 end

 for _other in all(sector[1].animals) do
  if _other != _behaviouree and dist(_behaviouree.x,_behaviouree.y,_other.x,_other.y) < 4 then
   -- kill animal
   del(sector[1].animals,_other)
   add(sector[1].mapobjs,getbloodobj(_other.x,_other.y,_other.bloodtype))
   sfx(33)

   -- close trap
   closetrap(_behaviouree)
   del(sector[1].animals,_behaviouree)
   add(sector[1].mapobjs,_behaviouree)
   break
  end
 end
end

function scaredbehaviour(_behaviouree)
 _behaviouree.scaredc-=1
 if _behaviouree.scaredc <= 0 then
  _behaviouree.behaviour=_behaviouree.oldbehaviour or sighthunting
 else
  if not _behaviouree.scaredx then
   _behaviouree.scaredx=guy.x
   _behaviouree.scaredy=guy.y
  end
  local _a=atan2(_behaviouree.scaredx-_behaviouree.x,_behaviouree.scaredy-_behaviouree.y)+0.5
  _behaviouree.x+=cos(_a)*_behaviouree.spd
  _behaviouree.y+=sin(_a)*_behaviouree.spd
  _behaviouree.flipx=_behaviouree.x < _behaviouree.scaredx
  _behaviouree.c-=1
  if _behaviouree.c <= 0 then
   _behaviouree.c=16
  end
  _behaviouree.sx=0
  if _behaviouree.c > 8 then
   _behaviouree.sx=_behaviouree.sw
  end
 end
end

function laiddeterrerbehaviour(_behaviouree)
 if _behaviouree.c > 0 then
  _behaviouree.c-=1
  _behaviouree.sx=16+(_behaviouree.c % 4)*3
  for _other in all(sector[1].animals) do
   if _other != _behaviouree and _other.spd and _other.behaviour != scaredbehaviour and dist(_behaviouree.x,_behaviouree.y,_other.x,_other.y) < 48 then
    -- scare animal
    _other.oldbehaviour=_other.behaviour
    _other.behaviour=scaredbehaviour
    _other.scaredc=120
    _other.scaredx=_behaviouree.x
    _other.scaredy=_behaviouree.y
   break
   end
  end
 else
  del(sector[1].animals,_behaviouree)
  add(sector[1].mapobjs,getnewdeterrer(_behaviouree.x,_behaviouree.y))
 end
end

function laiddrillbehaviour(_behaviouree)
 _behaviouree.drillc-=1
 if _behaviouree.drillc <= 0 then
  del(sector[1].animals,_behaviouree)
  add(sector[1].mapobjs,getnewdrill(_behaviouree.x,_behaviouree.y))
  add(sector[1].mapobjs,s2tmr([[
   sx=53,
   sy=9,
   sw=8,
   sh=6,
   ground=true,
   samplecolor=13,
   sunken=true,
   walksfx=7
   ]],{
    x=_behaviouree.x,
    y=_behaviouree.y,
    action=takesampleaction,
  }))
 else

  if _behaviouree.drillc % 40 == 29 then
   _behaviouree.sh-=1
  end
  _behaviouree.sx=20+(_behaviouree.drillc % 2)*4
 end
end

function droidbehaviour(_behaviouree)
 if not _behaviouree.talkingc then
  sfx(29)
  _behaviouree.talkingc=140
 end
 if _behaviouree.talkingc > 0 then
  droidtalk('stop spreading life',_behaviouree)
  _behaviouree.talkingc-=1
 elseif _behaviouree.talkingc <= 0 then
  sighthunting(_behaviouree)
 end
end

function sighthunting(_behaviouree)
 local _disttoguy,_disttotarget=disttoguy(_behaviouree),dist(_behaviouree.x,_behaviouree.y,_behaviouree.targetx,_behaviouree.targety)
 local _prevhunting=_behaviouree.hunting
 _behaviouree.hunting=nil

 if _disttoguy < _behaviouree.spd + 0.5 then
  local _drawies={guy,_behaviouree}
  resetplanetcamera(_drawies)
  deadinit(_drawies)
  return true

 elseif _disttoguy < _behaviouree.sightradius then
  _behaviouree.targetx,_behaviouree.targety=guy.x,guy.y
  if _behaviouree.isscary and guy.scared == nil and not _prevhunting then
   guytalk(rnd(split'yikes,eek,uh-oh'))
   guy.scared=true
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
 bear=s2t'sx=0,sy=8,sw=8,sh=8,sightradius=36,spd=0.75,huntingspd=1,c=0',
 bat=s2t'sx=0,sy=16,sw=7,sh=6,sightradius=32,spd=0.75,huntingspd=0.75,c=0,bloodtype="fire"',
 rabbit=s2t'sx=0,sy=70,sw=8,sh=5,sightradius=32,spd=1,huntingspd=1,c=0,scaredc=3000',
 spider=s2t'sx=0,sy=75,sw=12,sh=7,sightradius=38,spd=0.25,huntingspd=1.25,c=0,bloodtype="fire"',
 bull=s2t'sx=0,sy=38,sw=8,sh=8,sightradius=28,spd=0.125,huntingspd=1,c=0',
 snake=s2t'sx=0,sy=0,sw=8,sh=8,sightradius=36,spd=0.25,huntingspd=0.875,c=0,bloodtype="fire"',
 gnawer=s2t'sx=0,sy=22,sw=8,sh=8,sightradius=48,spd=0.75,huntingspd=1.25,c=0',
 firegnawer=s2t'sx=0,sy=30,sw=8,sh=8,sightradius=48,spd=0.75,huntingspd=1.25,c=0,bloodtype="fire"',
 slime=s2t'sx=0,sy=46,sw=9,sh=6,sightradius=72,spd=0.25,huntingspd=0.5,c=0,bloodtype="martian"',
 droid=s2t'sx=16,sy=52,sw=8,sh=8,sightradius=128,spd=0.05,huntingspd=2,c=0,bloodtype="droid",isscary=true',
}

-- sx,sy,sw,sh,samplecolor,ground,solid,lava,sunken,walksfx,action
objtypes={
 -- 1, lava
 s2t[[
  sx='53;55',
  sy='22;29',
  sw='11;8',
  sh='7;6',
  lava=true,ground=true
 ]],
 -- 2, lavacracks
 s2t[[
  sx='55;55',
  sy='35;39',
  sw='8;8',
  sh='4;5',
  ground=true
 ]],
 -- 3, sharp stones
 s2t[[
  sx='78;78;100',
  sy='72;80;73',
  sw='7;7;6',
  sh='8;8;5',
  solid='1;1;1'
 ]],
 -- 4, cracks
 s2t[[
  sx='103;103',
  sy='64;68',
  sw='8;8',
  sh='4;5',
  ground=true
 ]],
 -- 5, rounded stones
 s2t[[
  sx='69;69;85;93',
  sy='73;82;75;74',
  sw='8;8;7;6',
  sh='7;6;3;4',
  solid='1;1;0;0'
 ]],
 -- 6, lakes
 s2tmr([[
  sx='53;53',
  sy='9;15',
  sw='8;11',
  sh='6;7',
  ground=true,samplecolor=13,sunken=true,walksfx=7
  ]],{action=takesampleaction}),
 -- 7, skulls and ribs
 s2tmr([[
  sx='61;72;24;16',
  sy='60;60;0;0',
  sw='10;8;8;8',
  sh='6;6;4;5',
  samplecolor='6;15',
  solid='1;0;0;0'
  ]],{action=takesampleaction}),
 -- 8, canyon stones
 s2t[[
  sx='61;61;85',
  sy='72;81;75',
  sw='8;8;7',
  sh='8;7;3',
  solid='1;1;0'
 ]],
 -- 9, flowerbush
 s2tmr([[
  sx='16;23',
  sy='20;20',
  sw='7;6',
  sh='8;8',
  samplecolor='15;9'
  ]],{action=takesampleaction}),
 -- 10, dead trees
 s2t[[
  sx='39;47',
  sy='30;30',
  sw='8;8',
  sh='8;8',
  solid='1;1'
 ]],
 -- 11, red caps
 s2tmr([[
  sx='39',
  sy='0',
  sw='7',
  sh='5',
  samplecolor='6;15;9;10;11;7'
  ]],{action=takesampleaction}),
 -- 12, water marsh
 s2t[[
  sx='48',
  sy='42',
  sw='5',
  sh='4',
  ground=true
 ]],
 -- 13, leafshadow marsh
 s2t[[
  sx='48',
  sy='46',
  sw='5',
  sh='4',
  ground=true
 ]],
 -- 14, grass
 s2t[[
  sx='80;87;94',
  sy='67;67;67',
  sw='7;7;7',
  sh='5;5;5'
 ]],
 -- 15, cactuses
 s2tmr([[
  sx='53;60;60',
  sy='0;0;0',
  sw='7;7;7',
  sh='9;9;8',
  solid='1;1;1',
  samplecolor=13
  ]],{action=takesampleaction}),
 -- 16, mushrooms
 s2tmr([[
  sx='46',
  sy='0',
  sw='7',
  sh='5',
  samplecolor='15;9;10;8;11;7'
  ]],{action=takesampleaction}),
 -- 17, trees
 s2tmr([[
  sx='16;23;112;120',
  sy='10;11;62;63',
  sw='7;7;8;8',
  sh='10;9;15;14',
  solid='1;1;1;1',
  samplecolor=6
  ]],{action=takesampleaction}),
 -- 18, flowers
 s2tmr([[
  sx='0;7',
  sy='98;98',
  sw='7;7',
  sh='5;5',
  samplecolor='15;9;10;8;11;7'
  ]],{action=takesampleaction}),
  -- 19, berrybush
  s2tmr([[
  sx='32',
  sy='0',
  sw='7',
  sh='6',
  samplecolor='15;9;10;8;11;7'
  ]],{action=takesampleaction}),
}

plantsamplechances=s2t'15=1,9=1,10=0.675,6=0.5,8=0.05,11=0.025,7=0.01'
 
planettypes={
 martianworld=s2tmr([[
  groundcolor=12,
  surfacecolor=15,
  animalcount=0,
  objdist=36,
  alientype='martian'
  ]],{
   wpal=split'142,134,1,1,143',
   objtypes={
    -- craters etc
    s2t[[
     sx='0;4;10;19',
     sy='60;60;60;60',
     sw='5;7;9;6',
     sh='3;3;3;3',
     ground=true
    ]],
    s2t[[
     sx='0;4;10;19',
     sy='60;60;60;60',
     sw='5;7;9;6',
     sh='3;3;3;3',
     ground=true
    ]],
    objtypes[7], -- skulls, ribs
      -- martian pillars
    s2t[[
     sx='80;0;7;28',
     sy='63;63;63;88',
     sw='6;7;7;11',
     sh='4;7;7;8',
     solid='1;1;1;1'
     ]],
  }
 }),
 taurienworld=s2tmr([[
   groundcolor=2,
   surfacecolor=4,
   animalcount=5,
   objdist=28,
   alientype='taurien'
  ]],{
   animaltypes=split'bull,bear,rabbit,rabbit,rabbit',
   wpal=split'133,132,131,141,3',
   objtypes={
    objtypes[4], -- cracks
    objtypes[7], -- skulls, ribs
    objtypes[8], -- canyon rocks
    -- taurien industry
    s2t[[
     sx='106;106;16;15;117',
     sy='73;76;69;63;77',
     sw='5;6;9;10;11',
     sh='3;3;6;6;14',
     solid='1;1;1;1;1'
    ]],
   },
  }),
 droidworld=s2tmr([[
  groundcolor=5,
  surfacecolor=13,
  animalcount=12,
  objdist=18,
  droidworld=true
  ]],{
  animaltypes=split'droid',
  wpal=split'133,133,1,1,1',
  objtypes={
   -- droid pillars
   s2t[[
    sx='68;77;68;68;83;77',
    sy='0;0;7;13;0;5',
    sw='9;6;9;9;9;6',
    sh='7;5;6;7;13;4',
    solid='1;1;1;1;1;1'
   ]],
  },
 }),
}

groundcolors=split'1,2,3,4,5,6,7,9,13,14,15,18,19,20,21,22,23,27,28,29'
shadowcolors=split'17,18,19,20,21,22,6,na,4,na,na,na,29,8,31,na,na,16,1,18,18,5,26,na,na,na,3,1,21'

surfacecolors=split'1,4,3,4,5,6,7,na,9,na,na,na,13,13,9,na,na,2,3,2,4,5,3,na,na,na,3,1,13'

leafshadows=split'1,2,3,4,5,6,8,13,14,15,18,19,20,21,22,23,24,25,26,27,28,29,30,31'
leafcolors={
 '19,28', -- 1
 '4,24', -- 2
 '27', -- 3
 '25,30', -- 4
 '3,22', -- 5
 '7', -- 6
 nil,
 '14', -- 8
 nil,nil,nil,nil,
 '6,14,22', -- 13
 '15', -- 14
 '7', -- 15
 nil,nil,
 '20,21', -- 18
 '3,28', -- 19
 '4', -- 20
 '5,29', -- 21
 '15', -- 22
 '7', -- 23
 '8', -- 24
 '9', -- 25
 '10,23', -- 26
 '11,26', -- 27
 '11,13', -- 28
 '13', -- 29
 '14,31', -- 30
 '15', -- 31
}

stonecolors=split'1,2,3,4,5,6,7,8,9,12,13,14,18,19,20,21,22,23,27,28,29,30'
stonehighlights={
 '2,3,5,13,19,20,24,28,29', -- 1
 '3,4,5,13,14,22,24,25,29,30', -- 2
 '6,11,12,26,27', -- 3
 '9,14,25,30,31', -- 4
 '3,6,8,13,14,15,22,24,25,30,31', -- 5
 '3,7,27', -- 6
 '6', -- 7
 '9,14,30,31', -- 8
 '10,15', -- 9
 nil,nil,
 '6,7,15,23,26,31', -- 12
 '6,12,14,15,23,31', -- 13
 '15,31', -- 14
 nil,nil,nil,
 '2,5,21,29', -- 18
 '3,13,22,27,28', -- 19
 '4,13,22,24,30', -- 20
 '2,4,5,13,28,29', -- 21
 '6,9,15,31', -- 22
 '7', -- 23
 nil,nil,nil,
 '11,23,26', -- 27
 '6,12,22,27,31', -- 28
 '3,4,13,22,24,25', -- 29
 '9,31', -- 30
}

for _i=1,31 do
 leafcolors[_i]=leafcolors[_i] and split(leafcolors[_i])
 stonehighlights[_i]=stonehighlights[_i] and split(stonehighlights[_i])
end

function fixpal(_pal)
 for _i=1,#_pal do
  local _color=_pal[_i]
  _pal[_i]=_color > 15 and _color+112 or _color
 end
 return _pal
end

function createplanettype()
 local _scorepercentage=getscorepercentage()

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
 local _objtypes={s2t'sx="48",sy="38",sw="5",sh="4",ground=true'} -- always add shadow marsh
 local _objtypeslen=rnd(split'3,4,4,5,5,5,6,7,8,9')

 while #_objtypes < _objtypeslen do
  local _objtypelen=#objtypes-(_scorepercentage < 0.4 and 2 or _scorepercentage < 0.6 and 1 or 0) -- never have flowers and or berrybushes if not enough points
  local _index=mid(
   (_wpal[2] == 7 or rnd(_scorepercentage) > 0.0875) and 3 or 1, -- if white/snow then never have lava
    flr((rnd(2)-1+_scorepercentage)*_objtypelen),
    _objtypelen)
  add(_objtypes,objtypes[_index])
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
  objdist=mid(12,36-flrrnd(6)-flr(_scorepercentage*20),52),
 }
end


function createplanet(_planettype)
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
  -- shuttle
  s2tmr('sx=63,sy=40,sw=15,sh=7',{
   x=mapsize/2,y=mapsize/2-10,
   action={
    title='go back to ship',
    func=function()
     traveling,travelc='up',30
     sfx(27)
     shipinit()
     return true
    end,
   }
  }),
 }

 -- add wreck
 local _haswreck=nil
 if rnd() < 0.12 then
  _haswreck=true
  local _wrecktype=rnd{'martianwreck','taurienwreck'}
  local _x,_y=flrrnd(mapsize-_tooclosedist),flrrnd(mapsize-_tooclosedist)

  -- add tool
  if rnd() < 0.5 then
   add(_mapobjs,getnewsparepart(_x-34,_y-2))
  end

  local function addwreckobj(_x,_y,_strobj)
   add(_mapobjs,s2tmr(_strobj,{x=_x,y=_y}))
  end

  if _wrecktype == 'martianwreck' then
   addwreckobj(_x,_y,'sx=58,sy=48,sw=14,sh=8,solid=true') -- ship wreck
   addwreckobj(_x+1,_y-2,'sx=56,sy=50,sw=21,sh=9,ground=true') -- debris
   addwreckobj(_x-14,_y+2,'sx=48,sy=54,sw=8,sh=4') -- corpse
   add(_mapobjs,getbloodobj(_x-23,_y+3,'martian'))

  else -- taurienwreck
   addwreckobj(_x,_y,'sx=49,sy=78,sw=10,sh=9,solid=true') -- ship wreck
   addwreckobj(_x-8,_y-5,'sx=44,sy=78,sw=5,sh=4,solid=true') -- small wing
   addwreckobj(_x-8,_y-1,'sx=42,sy=83,sw=9,sh=6,ground=true') -- debris
   addwreckobj(_x-17,_y,'sx=33,sy=85,sw=9,sh=3') -- corpse
   add(_mapobjs,getbloodobj(_x-26,_y+1,'taurien'))
  end
 end

 -- add artifact
 local _hasartifact=nil
 if rnd() < 0.1 then
  _hasartifact=true
  local _x,_y=flrrnd(mapsize-32),flrrnd(mapsize-32)
  local _ruincount,_sy=flrrnd(7)+4,rnd(split'96,104,112,120')
  add(_mapobjs,rnd({getnewtrap,getnewdeterrer,getnewdrill,getnewsparepart})(_x,_y))
  for _i=0,_ruincount-1 do
   local _a=_i/_ruincount+0.05
   add(_mapobjs,s2tmr('sw=8,sh=8,solid=true',{
    x=_x+cos(_a)*_ruincount*5,y=_y+sin(_a)*_ruincount*5,
    sx=rnd(split'15,23,31'),sy=_sy,
   }))
  end
 end

 -- add flora
 for _i=1,70 do
  local _tries,_x,_y,_tooclose=0
  repeat
   _x,_y,_tooclose=flrrnd(mapsize-_tooclosedist),flrrnd(mapsize-_tooclosedist)

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
  local _sxs=split(_obj.sx,';')
  local _idx=flrrnd(#_sxs)+1
  local _samplecolorindex0=0

  if type(_obj.samplecolor) == 'string' then
   local _samplecolors=split(_obj.samplecolor,';')
   _samplecolorindex0=flrrnd(#_samplecolors)
   _obj.samplecolor=_samplecolors[_samplecolorindex0+1]
   if rnd() > plantsamplechances[_obj.samplecolor] then
    _tries=100
   end
  end
  
  if _tries <= 10 and not contains(_planettype.wpal,_obj.samplecolor) then
   _obj.sx=split(_obj.sx,';')[_idx]
   _obj.sw=split(_obj.sw,';')[_idx]
   _obj.sh=split(_obj.sh,';')[_idx]
   _obj.sy=split(_obj.sy,';')[_idx]+_samplecolorindex0*_obj.sh
   _obj.solid=_obj.solid and split(_obj.solid,';')[_idx] == 1
   _obj.x,_obj.y=_x,_y
   add(_mapobjs,_obj)
  end
 end

 -- add fauna
 local _animals={}
 local _loops=(_planettype.animalcount and flrrnd(_planettype.animalcount)) or mid(0,flrrnd(getscorepercentage()*20),50)
 for _i=1,_loops do
   local _typ=rnd(_planettype.animaltypes)
   local _animal=clone(animaltypes[_typ])
   _animal.x,_animal.y=flrrnd(mapsize),flrrnd(mapsize)
   if dist(mapsize/2,mapsize/2,_animal.x,_animal.y) > 60 then
    _animal.targetx=_animal.x
    _animal.targety=_animal.y
    _animal.typ=_typ
    _animal.bloodtype=_animal.bloodtype or 'taurien'
    _animal.behaviour=_animal.scaredc and scaredbehaviour or sighthunting
    add(_animals,_animal)
  end
 end

 -- add aliens
 local _alientype=nil
 local _rndalientype=_planettype.alientype or rnd{'martian','taurien'}
 if (alienhostile == nil and rnd() < 0.065 and (_rndalientype == 'taurien' and #_animals > 0 or _rndalientype == 'martian')) or _planettype.alientype then
  _alientype=_rndalientype
  local _x,_y=flrrnd(mapsize-_tooclosedist),flrrnd(mapsize-_tooclosedist)
  add(_mapobjs,s2tmr('sx=42,sw=19,sh=10,solid=true',{
   sy=_alientype == 'martian' and 58 or 68,
   x=_x+15,y=_y,
  }))

  local _alien=s2tmr('sx=25,sw=6,sh=8',{
   x=_x,y=_y,
   sy=_alientype == 'martian' and 60 or 68,
   targetx=_x,
   targety=_y,
   typ=_alientype,
   bloodtype=_alientype,
   talkfunc=_alientype == 'martian' and martiantalk or taurientalk,
   talkstr=_alientype == 'martian' and 'trade us water or else' or 'help us hunt or else',
   behaviour=function (_behaviouree)
    alienhostile=_alientype
    if disttoguy(_behaviouree) < 20 then
     _behaviouree.talkfunc(_behaviouree.talkstr,_behaviouree)
     _behaviouree.behaviour=_behaviouree.behaviour2
    end
   end,
  })

  if _alientype == 'martian' then
   _alien.behaviour2=function ()
    -- pass
   end
   add(_mapobjs,s2tmr('sx=25,sy=60,sw=6,sh=8',{
    x=_x,y=_y,
    action={
     title='trade',
     func=function (_obj)
      local _waterfound=nil
      for _i=1,5 do
       if samples[_i] == 13 then
        samples[_i]=11
        dset(_i,11)
        _waterfound=true
        break
       end
      end
      if not _waterfound then
       martiantalk('you will regret this',_alien) -- note: _alien from outer scope
       sfx(46)
      else
       martiantalk('thanks, now go away',_alien)
       sfx(45)
       alienhostile=nil
      end
      del(sector[1].mapobjs,_obj)
     end,
    }
   }))

  else -- taurien
   _alien.behaviour2=function(_behaviouree)
    for _other in all(sector[1].animals) do
     if _other != _behaviouree and _other.bloodtype and dist(_behaviouree.x,_behaviouree.y,_other.x,_other.y) < 20 then
      -- kill animal
      del(sector[1].animals,_other)
      add(sector[1].mapobjs,getbloodobj(_other.x,_other.y,_other.bloodtype))
      taurienshot={x1=_behaviouree.x,y1=_behaviouree.y-5,x2=_other.x,y2=_other.y,}
      taurientalk('well done, for a human',_behaviouree)
      alienhostile=nil
      sfx(rnd{40,41})
      break
     end
    end
   end
  end

  add(_animals,_alien)
 end

 return {
  mapobjs=_mapobjs,
  wpal=_wpal,
  groundcolor=_planettype.groundcolor,
  surfacecolor=_planettype.surfacecolor,
  animals=_animals,
  haswreck=_haswreck,
  hasartifact=_hasartifact,
  alientype=_alientype,
  droidworld=_planettype.droidworld,
 }
end

function nextsector()
 sfx(-1,2)
 droidalertc,droidfiringc,droidlandingc,droidlandingx,droidlandingy,alienhostile,alienfiringc=nil
 _lastsectordroids=sector and sector.wasdroids
 sector={}
 local _ispopulatedsector=nil
 local _scorepercentage=getscorepercentage()

 for _i=1,rnd(split'1,1,2,2,2,2,3,3') do
  if _lastsectordroids == nil and _ispopulatedsector == nil and _scorepercentage > 0.1 and rnd() < _scorepercentage*0.125 then
   add(sector,createplanet(planettypes.droidworld))
   sector.wasdroids=true
   _ispopulatedsector=true
  elseif _ispopulatedsector == nil and  rnd() < 0.0675 then
   add(sector,createplanet(rnd{planettypes.martianworld,planettypes.taurienworld}))
   _ispopulatedsector=true
  else
   add(sector,createplanet(createplanettype()))
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
 guy.x,guy.y=62,65
end

function planetinit()
 lookinginsamplecase,droidlandingc=nil
 guy=mr(guy,s2tmr('sx=0,sy=83,sw=6,sh=6,walkingc=0,runningc=0,walksfx=6,samplingc=0',{x=mapsize/2,y=mapsize/2,scared=nil}))
 pal(sector[1].wpal,1)
 camera(guy.x/2,guy.y/2)

 _update,_draw=planetupdate,planetdraw
end

function planetupdate()
 local _movex,_movey,_spd=0,0,1
 guy.sx=0

 if guy.panting then
  _spd=0
 elseif guy.runningc > 0 then
  _spd=2
 end

 if guy.samplingc <= 0 then
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

 if _movex == 0 and _movey == 0 then
  guy.walkingc=0
  guy.runningc=max(0,guy.runningc-2)

  if guy.runningc == 0 then
   guy.panting=nil
  end

  lookinginsamplecase=(not guy.panting) and btn(4)

  if dget(45) != 0 and btnp(5) then
   if dget(45) == 1 then -- trap
    add(sector[1].animals,s2tmr('sx=28,sy=38,sw=7,sh=3,toolnr=1',{
     x=guy.x,y=guy.y,
     targetx=guy.x,targety=guy.y,
     behaviour=laidtrapbehaviour,
    }))
    sfx(34)

   elseif dget(45) == 2 then -- deterrer
    add(sector[1].animals,mr(clone(tools[2]),{
     c=360,
     x=guy.x,y=guy.y,
     targetx=guy.x,targety=guy.y,
     behaviour=laiddeterrerbehaviour,
    }))
    sfx(39)
    
   elseif dget(45) == 3 then -- drill
    add(sector[1].animals,mr(clone(tools[3]),{
     x=guy.x,y=guy.y,
     targetx=guy.x,targety=guy.y,
     behaviour=laiddrillbehaviour,
    }))
    sfx(42)

   elseif dget(45) == 4 then -- spare part
    add(sector[1].mapobjs,getnewsparepart(guy.x,guy.y))
   end

   dset(45,0)
  end

 else
  guy.walkingc-=1
  if guy.runningc > 0 then
   guy.walkingc-=1
  end
  if guy.walkingc <= 0 then
   guy.walkingc=6
   sfx(guy.walksfx)
  end

  if btn(5) then
   if dget(45) == 0 then
    guy.runningc+=1
   else
    guytalk('can\'t run while carrying tool')
   end
  else
   guy.runningc=0
  end

  lookinginsamplecase=nil

  if guy.runningc > 30 and not guy.panting then
   guytalk(rnd(split'*pant pant,*huff puff,*wheeeeze'))
   guy.panting=true
   sfx(2)
  end

  for _obj in all(sector[1].mapobjs) do
   if dist(guy.x-_movex,guy.y-_movey,_obj.x,_obj.y) < _obj.sw * 0.5 and (guy.runningc > 0 and _obj.solid or _obj.lava) then
    _movex*=-3
    _movey*=-3
    guy.panting=true
    guy.runningc=24
    guytalk(rnd(split'ouch,oof,argh,ow,owie,oww'))
    sfx(rnd{16,17})
   end
  end

 end

 guy.walksfx=6
 guy.action=nil
 guy.sunken=nil

 local _mapobjs=sector[1].mapobjs

 if droidlandingx then
  droidlandingx=mapwrap(droidlandingx+_movex)
  droidlandingy=mapwrap(droidlandingy+_movey)
 end

 for _animal in all(sector[1].animals) do
  _animal.x=mapwrap(_animal.x+_movex)
  _animal.y=mapwrap(_animal.y+_movey)
  _animal.targetx=mapwrap(_animal.targetx+_movex)
  _animal.targety=mapwrap(_animal.targety+_movey)
 end

 for _obj in all(_mapobjs) do
  _obj.x=mapwrap(_obj.x+_movex)
  _obj.y=mapwrap(_obj.y+_movey)

  if (_obj.action or _obj.walksfx or _obj.sunken) and dist(guy.x,guy.y,_obj.x,_obj.y) < 5 then
   guy.walksfx=_obj.walksfx or guy.walksfx
   guy.sunken=_obj.sunken

   if _obj.action then
    guy.action=_obj.action
    guy.action.target=_obj
   end
  end
 end

 if btnp(4) and guy.action and guy.action.func(guy.action.target) then
  return
 end

 guy.samplingc-=1

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

 -- update droid faction
 updatedroidalert()

 if droidalertc == 0 then
  if not droidlandingc then
   droidlandingc=180
   droidlandingx=guy.x
   droidlandingy=guy.y
  end
  if droidlandingc > 0 then
   droidlandingc-=1

   if droidlandingc == 0 then
    add(sector[1].animals,mr(clone(animaltypes.droid),{
     x=droidlandingx+16,
     y=droidlandingy+16,
     targetx=droidlandingx+16,
     targety=droidlandingy+16,
     behaviour=droidbehaviour,
    }))
   end
  end
 end

 -- update animals
 for _animal in all(sector[1].animals) do
  if _animal.behaviour(_animal) then
   return
  end
 end

end

function planetdraw()
 cls(sector[1].groundcolor)

 local _mapobjs=sector[1].mapobjs
 local _drawies=clone(_mapobjs)
 add(_drawies,guy)

 for _animal in all(sector[1].animals) do
  add(_drawies,_animal)
 end

 sortbyy(_drawies)

 for _obj in all(_drawies) do
  local _y=_obj.y-_obj.sh
  if _obj.ground then
   _y=_obj.y-flr(_obj.sh/2)
  end
  sspr(_obj.sx,_obj.sy,_obj.sw,_obj.sh,_obj.x-flr(_obj.sw/2),_y,_obj.sw,_obj.sh,_obj.flipx)
 end

 if taurienshot then
  line(taurienshot.x1,taurienshot.y1,taurienshot.x2,taurienshot.y2,7)
  circfill(taurienshot.x2,taurienshot.y2,7,7)
  taurienshot=nil
 end

 -- draw droid ship
 if droidlandingc then
  local _y=droidlandingy-droidlandingc
  local _sh=24
  if droidlandingc == 0 then
   _sh=26
  end
  sspr(32,52,10,_sh,droidlandingx,_y)
 end

 -- draw guy action
 if guy.action then
  local _strlen=#guy.action.title*4+14
  local _targetx=guy.action.target.x
  local _y=guy.action.target.y-22
  rectfill(_targetx-_strlen/2,_y,_targetx+_strlen/2,_y+8,0)
  line(_targetx,_y,_targetx,guy.action.target.y-guy.action.target.sh-2,0)
  print('\f9\014\x8e\015 '..guy.action.title,_targetx+2-_strlen/2,_y+2)
 end

 -- draw sample case
 if lookinginsamplecase or guy.samplingc > 0 then
  local _x=guy.x-10
  local _y=guy.y+10
  sspr(60,88,9,3,_x+8,_y-3)
  drawsamplecase(_x,_y)
 end

 drawtalk()
end


-- ship scene

function drawdoor(_obj)
 if _obj.inrange then
  sspr(89,85,3,6,_obj.x,_obj.y)
  _obj.c=6
 else
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
   return
  end
  local _datapos=_obj.datapos
  if dget(_datapos) != 0 and #samples < 5 then
   addtosamplecase(dget(_datapos))
   dset(_datapos,nil)
   sfx(14)
  elseif dget(_datapos) == 0 and #samples > 0 then
   dset(_datapos,removefromsamplecase(samplesel))
   sfx(14)
  else
   sfx(31)
  end
 end
end

function storagedraw(_obj)
 if _obj.inrange then
  local _datapos=_obj.datapos
  actiontitle='sample storage'
  
  if _obj.broken then
   showbrokentitle=true
   dset(_datapos,0)
   return
  end

  local _showsamplecasearrow=nil
  local _x=_obj.x1-4
  sspr(92,0,11,13,_x,98)

  if dget(_datapos) != 0 and #samples < 5 then
   actiontitle='\014\x8e\015 take sample'
   sspr(99,85,5,6,_x+3,113)
  elseif dget(_datapos) == 0 and #samples > 0 then
   actiontitle='\014\x8e\015 store sample'
   _showsamplecasearrow=true
  end

  drawsamplecase(42,98,_showsamplecasearrow)

  if dget(_obj.datapos) != 0 then
   local _lx=_x+5
   line(_lx,105,_lx,107,dget(_obj.datapos))
  end
 end
end

function toolstorageinputhandler(_obj)
 if _obj.inrange and btnp(4) then
  local _carriedtool=dget(45)
  dset(45,dget(_obj.datapos))
  dset(_obj.datapos,_carriedtool)
  if dget(45) != 0 or dget(_obj.datapos) != 0 then
   sfx(35)
  else
   sfx(31)
  end
 end
end

function toolstoragedraw(_obj)
 local _storedtool=dget(_obj.datapos)
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
  sspr(_tool.sx,_tool.sy,_tool.sw,_tool.sh,_obj.x1-1,75)
 end
end

colortohex=split'1,2,3,4,5,6,7,8,9,a,b,c,d,e,f'
samplecolorvalues={
 [13]=1, -- water
 [6]=2, -- stonish
 [15]=2, -- sandish
 [9]=2, -- orange
 [10]=2, -- bloody orange
 [8]=8, -- taurien blood
 [11]=12, -- mars blood
 [7]=12, -- droid blood
}

function getseedquality()
 local _result=0
 local _samples=clone(seed)
 local _kinds={}

 for _color=1,15 do
  local _value=samplecolorvalues[_color]
  while del(_samples,_color) do
   _result+=_value
   if count(_kinds,_color) == 0 then
    add(_kinds,_color)
   end
  end
 end

 if #_kinds == 4 then
  _result+=12
 end

 return _result,#_kinds == 4 and 12 or nil
end

function resetshipobjs()
 shipobjs={
  { -- floor 1
   -- elevator
   s2tmr('x1=60,x2=65,c=0,y=86',{
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
   }),
   -- small ship
   s2tmr('x1=29,x2=40,cantbreak=true',{
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
   }),
   -- cryo
   s2tmr('x1=50,x2=53,cantbreak=true',{
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
       print('\f9\x97 self-destruct',38,43)
      else
       actiontitle='\014\x8e\015 enter cryo'
      end
     end
    end,
   }),
   -- storage 1
   s2tmr('x1=71,x2=76,datapos=6',{
    inputhandler=storageinputhandler,
    draw=storagedraw,
   }),
   -- storage 2
   s2tmr('x1=77,x2=82,datapos=7',{
    inputhandler=storageinputhandler,
    draw=storagedraw,
   }),
   -- storage 3
   s2tmr('x1=83,x2=88,datapos=8',{
    inputhandler=storageinputhandler,
    draw=storagedraw,
   }),
   -- water converter
   s2tmr('x1=94,x2=99',{
    inputhandler=function(_obj)
     sampleselectinputhandler(_obj)
     if _obj.inputlastframe == true and not btn(4) then
      _obj.inputlastframe=nil
      if _obj.broken or #samples == 0 then
       sfx(31)
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
   }),
   -- door
   s2tmr('x1=43,x2=49,x=44,y=85,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
   -- door
   s2tmr('x1=54,x2=60,x=55,y=85,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
   -- door
   s2tmr('x1=66,x2=72,x=67,y=85,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
   -- door
   s2tmr('x1=88,x2=94,x=89,y=85,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
  },

  -- floor 2
  {
   -- engine
   s2tmr('x1=28,x2=37,c=0',{
    inputhandler=function(_obj)
     sampleselectinputhandler(_obj)
     if _obj.inputlastframe == true and not btn(4) then
      _obj.inputlastframe=nil
      if samples[samplesel] != 13 then
       guytalk('only water for fuel')
       sfx(31)
      elseif dget(9) == 5 then
       guytalk('tank is full')
       sfx(31)
      else
       dset(9,dget(9)+1)
       removefromsamplecase(samplesel)
       sfx(14)
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
   }),
   -- seed cannon
   s2tmr('x1=44,x2=49,c=0',{
     inputhandler=function(_obj)
      if _obj.c == 0 then
       sampleselectinputhandler(_obj)

       if _obj.inputlastframe == true and not btn(4) then
        _obj.inputlastframe=nil
        if #samples > 0 and #seed < 4 then
         local _sample=removefromsamplecase(samplesel)
         add(seed,_sample)
         dset(40+#seed,_sample)
         sfx(14)
        elseif #seed == 4 then
         _obj.c=90
         sfx(12)
        else
         sfx(31)
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
        travelblocked=nil

        if not (_obj.broken and rnd() > 0.675) then
         local _result,_bonus=getseedquality()
         dset(50,seed[1])
         dset(51,seed[2])
         dset(52,seed[3])
         dset(53,seed[4])
         dset(54,_bonus)
         dset(61,dget(61)+1)
         dset(62,dget(62)+_result)
         _obj.seedy=60
         clearseedcannon()
         
         if not droidalertc then
          droidalertc=300+flrrnd(300)
         else
          droidalertc=max(1,droidalertc-90)
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
   }),
   -- elevator
   s2tmr('x1=60,x2=65,c=0,y=75',{
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
   }),
   -- tool storage 1
   s2tmr('x1=72,x2=76,datapos=46,cantbreak=true',{
    inputhandler=toolstorageinputhandler,
    draw=toolstoragedraw,
   }),
   -- tool storage 1
   s2tmr('x1=78,x2=82,datapos=47,cantbreak=true',{
    inputhandler=toolstorageinputhandler,
    draw=toolstoragedraw,
   }),
   -- score tracker
   s2tmr('x1=87,x2=92,c=0',{
    draw=function(_obj)
     if _obj.inrange then
      rectfill(19,11,109,51,5)
      line(19,22,109,22,0)
      local _laststr
      if _obj.broken then
       _laststr=(_obj.broken and rnd() > 0.5 and '\n\n\nla5t: ' or '\n\n\nl4st: ')..tostr(flrrnd(9999))
      else
       _laststr='\n\n\nlast: '
       if dget(50) != 0 then
        for _i=50,53 do
         local _samplevalue=dget(_i)
         _laststr=_laststr..'\f'..tostr(colortohex[_samplevalue])..samplecolorvalues[_samplevalue]..'\f4+'
        end
        if dget(54) != 0 then
         _laststr=_laststr..'(\fc12\f4)'
        else
         _laststr=_laststr..'(0)'
        end
       end
      end
      print('\fbhighscore: '..tostr(dget(63))..'\n\ntotal score: '..tostr(dget(62)).._laststr,23,14)
      print('\fbseeds: '..tostr(dget(61)),23,35)
     end

     _obj.c-=1
     if _obj.c <= 0 then
      _obj.c=20
      _obj.blink=rnd{split'88,74,11',split'88,76,11',split'88,78,11',split'90,74,11',split'90,76,11',split'90,78,11'}
     end

     pset(unpack(_obj.blink))
    end,
   }),
   -- navcom
   s2tmr('x1=96,x2=97,c=0',{
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

      if dget(9) > 0 and not travelblocked then
       if #sector == 1 then
        traveling='warping'
       else
        traveling='orbiting'
        deli(sector, 1)
       end
       travelc=60
      else
       sfx(31)
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
     if traveling != 'orbiting' and traveling != 'warping' then
      if not _obj.broken then
       if _blink then
        if droidalertc == 0 or alienhostile or _obj.rebootingc then
         pset(103,76,8)
        elseif sector[1].haswreck or sector[1].hasartifact then
         pset(103,76,11)
        end
       end
       if dget(9) == 0 then
        pset(104,76,8)
       elseif #sector == 1 then
        pset(104,76,11)
       end
      end

      if _obj.inrange then
       line(98,74,100,74,11)
       line(98,76,99,76,11)
       rectfill(17,10,109,51,3)
 
       if _obj.rebootingc then
        print('\fbrebooting...',21,14)
        rectfill(21,23,81-_obj.rebootingc,26,11)
        return
       end

       if dget(9) == 0 then
        print('\f8no fuel',78,14)
       end
       print(_obj.broken and rnd() > 0.5 and '\fb\x81n4vcdm\x84' or '\fb\x98navcom\x98',21,14)
       print('\fborbiting planet',21,23)
       cursor(21,32)
       if _obj.broken then
        print('\f8\x96system unstable\x96')
       elseif _blink then
        if droidalertc == 0 or alienhostile then
         print('\f8hostile ship near \x88')
        elseif sector[1].haswreck then
         print('\fbdistress signal \x96')
        elseif sector[1].hasartifact then
         print('\fbsurface anomaly \x86')
        end
       end

       cursor(21,41)
       if travelblocked then
        print('\fbwait for seed cannon') -- todo: fit at the end \x93
       elseif #sector > 1 then
        print('\fb> goto next planet \x86')
       else
        print('\fb> hyper jump \x85')
       end
      end
     end
    end,
   }),
   -- door
   s2tmr('x1=38,x2=43,x=39,y=74,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
   -- door
   s2tmr('x1=54,x2=60,x=55,y=74,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
   -- door
   s2tmr('x1=66,x2=72,x=67,y=74,c=0,cantbreak=true',{
    draw=drawdoor
   }),
   -- door
   s2tmr('x1=81,x2=87,x=82,y=74,c=0,cantbreak=true',{
    draw=drawdoor,
   }),
  },
 }
end

function addbrokenparticle(_x,_y)
 if rnd() > 0.85 and #particles < 20 then
  add(particles,s2tmr('ax=0.9,ay=0.9,col=9,life=5',{
    x=_x,
    y=_y,
    vx=rnd(2)-1,
    vy=-rnd(),
   }))
 end
end

function shipinit()
 pal(split'1,130,3,133,5,6,7,8,9,137,11,12,13,14,15',1)
 stars,particles={},{}

 for i=1,30 do
  add(stars,{
   x=flrrnd(128),
   y=flrrnd(128),
   spd=mid(0.125,rnd()+0.5,1),
   col=rnd{1,13}
  })
 end

 guy.x,guy.y,guy.floor=guy.incryo and 52 or 37,91,1

 actiontitle,repairts,lookinginsamplecase,showbrokentitle,talk='',0,true

 camera()

 _update,_draw=shipupdate,shipdraw
end

function shipupdate()
 hitpos=nil
 
 if not traveling then
  actiontitle,showrepairtitle,showbrokentitle=''

  if guy.incryo == nil and not btn(4) then
   if btn(0) then
    guy.x-=1
   elseif btn(1) then
    guy.x+=1
   end
  end
  guy.x,guy.y=mid(27,guy.x,97),floorys[guy.floor]

  for _i=1,2 do
   local _floorobjs=shipobjs[_i]
   for _j,_obj in ipairs(_floorobjs) do
    _obj.floor,_obj.index,_obj.firstframe=_i,_j
    if _i == guy.floor and mid(_obj.x1,guy.x,_obj.x2) == guy.x then
     if not _obj.inrange then
      _obj.firstframe=true
     end
     _obj.inrange=true
     if dget(45) == 4 and _obj.broken and not _obj.cantbreak then -- note: 45 = carrying spare part
      showrepairtitle=true
      if btnp(4) then
       _obj.broken=nil
       dset(45,0)
       dset(floordatapos[_obj.floor]+_obj.index,0)
       sfx(36)
       repairts=t()
       goto label1
      end
     elseif _obj.inputhandler and t() - repairts > 1 then
      actiontitle=_obj.actiontitle or ''
      _obj.inputhandler(_obj)
     end
    else
     _obj.inrange=nil
    end
   end
  end
  ::label1::

  -- update alien faction
  if alienhostile then
   if not alienfiringc then
    alienfiringc=90+flrrnd(60)
   end
   alienfiringc-=1
   if alienfiringc == 0 then
    breakrandomshipobj()
    alienfiringc=nil
    sfx(rnd{19,20})
   end
  end

  -- update droid faction
  updatedroidalert()

  if droidalertc == 0 then
   if not droidfiringc then
    droidfiringc=90+flrrnd(60)
   end
   droidfiringc-=1
   if droidfiringc == 0 then
    breakrandomshipobj()
    droidfiringc=nil
    sfx(rnd{19,20})
   end
  end

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
    if sector[1].droidworld then
     droidalertc = 10
    end
   end

   if traveling == 'down' then
    travelc,traveling=0
    planetinit()
    return
   end

   travelc,traveling=0
  end
 end

 -- update broken
 for _i=1,2 do
  local _floorobjs=shipobjs[_i]
  for _obj in all(_floorobjs) do
   if _obj.broken and not _obj.cantbreak then
    addbrokenparticle(_obj.x2-3,floorys[_i])
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
   _s.x,_s.y=188,flrrnd(128)
  end
 end
end

function shipdraw()
 cls((droidfiringc == 1 or alienfiringc == 1) and 13 or 0)
 if traveling == 'warping' then
  cls(travelc == 1 and 7 or 1)
 end

 -- draw stars
 for _s in all(stars) do
  if traveling == 'warping' then
   line(_s.x,_s.y,_s.x+(travelc-60),_s.y,13)
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
  circfill(_x,318,200,sector[1].surfacecolor)
 end

 -- draw droid ship
 if droidalertc == 0 then
  sspr(79,13,49,16,74,16)
 elseif droidalertc == 1 then
  circfill(93,23,12,7)
 end

 if hitpos then
  local _x1,_y1=109,23
  if alienfiringc == 0 then
   _x1,_y1=21,26
  end
  line(109,23,hitpos.x,hitpos.y,7)
 end

 -- draw martian/taurien ship
 local _alientype=alienhostile or (sector and sector[1].alientype)
 if _alientype then
  local _x=5
  if alienhostile == nil and (traveling == 'orbiting' or traveling == 'warping') then
   _x+=travelc*2.5
  end
  sspr(79,_alientype == 'martian' and 45 or 29,49,16,_x,14)
 end

 -- draw ship
 sspr(39,91,89,37,21,57)

 -- draw shipobjs
 for _floori,_floorobjs in ipairs(shipobjs) do
  for _obj in all(_floorobjs) do
   _obj.draw(_obj)
  end
 end

 if hitpos then
  circfill(hitpos.x,hitpos.y,9,7)
 end

 -- draw guy
 if not guy.incryo then
  sspr(32,dget(45) == 0 and 41 or 46,5,5,guy.x-2,guy.y-5)
 end

 -- draw small ship
 if traveling == 'down' then
  rectfill(24,84,41,90,1)
  pset(26+(30-travelc),92+(30-travelc),6)
 elseif traveling == 'up' then
  rectfill(24,84,41,90,1)
  pset(26+travelc,92+travelc,6)
 end

 -- draw particles
 for _p in all(particles) do
  pset(_p.x,_p.y,_p.col)
 end

 -- draw actiontitle, repairtitle, and brokentitle
 if showrepairtitle then
  rectfill(46,30,83,38,0)
  print('\f9\014\x8e\015 repair',48,32)
 elseif showbrokentitle then
  print('\f8broken',52,32)
 else
  print(actiontitle,64-#actiontitle*2,32,9)
 end

 -- draw talks
 drawtalk()
end


function deadinit(_drawies)
 sfx(-1,2)
 sfx(30)
 deaddrawies=_drawies

 if dget(62) > dget(63) then -- score > highscore
  dset(63,dget(62)) -- set new highscore
 end

 dset(59,0) -- reset save
 pal(split'1,136,3,4,5,6,7,136,9,137,138,8,13,14,15',1)
 ts=t()

 _update,_draw=deadupdate,deaddraw
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
   sspr(_obj.sx,_obj.sy,_obj.sw,_obj.sh,_obj.x-flr(_obj.sw/2),_y,_obj.sw,_obj.sh,_obj.flipx)
  end
 end

 print('\fcdeceased',48,32)
 local _highscorestr='\fahighscore: '..tostr(dget(63))
 print(_highscorestr,126-#_highscorestr*4,2)
 print('\fascore: '..tostr(dget(62)),2,2)
 if t()-ts > 2 then
  print('\f9\014\x8e\015 new universe',34,118)
 end
end

-- splash
function _init()
 sfx(44)
end

function _update()
 -- update
 if btnp(4) then
  resetgame()
  shipinit()
  return
 end

 -- draw
 cls(0)
 print('\f9the\f7\^t\^w\npanspermia',26,41)
 print('\f9guy',93,58)
 print('\014\x8e\015 '..(dget(59) == 0 and 'start' or 'continue'),42,120,10)
end

__gfx__
eee0000eeeeeeeee00ee00eee0000eeeee000eee000eeee000eeeeee0eeeeee00eeeeee00000e0000eeee0000eee00000000000e00000000000000000000000e
ee099790eee0000e0f00f0ee066660eee0ccc0e08880ee04440eeee0c00ee00c0eeeee055550e05250ee057750ee055555555500ddddddddddddddddddddddd0
ee099000ee099790006660ee0656560e0ccfcc0e06000ee0f000eee0c0c00c0c00eeee057750e05220ee055550ee0ddddddddd00dd000d000d000d000d000dd0
e0e0990ee00999000656560e066666600fccc30e068880e0f4440e00c3c00c3c0c0ee0552550e05220ee075220ee0ddd000ddd00dd060d060d060d060d060dd0
090009900900999006666660e0000eee0ccc930e06060ee0f0f0e0c0c00ee00c3c0e05552220e022201e055550ee0ddd060ddd00ddddddddddddddddddddddd0
0b9999b00b9999b000ee00ee0ffff0eee0c330ee000eeee000eee0c3c0eeee0c00ee05752550ee0000ee025220ee0ddddddddd00550505050505050505050550
e0bbbb0ee0bbbb0e060060ee0f5f5f0eee000ee08880ee04440eee00c0eeee0c0eee02222550105250ee025250ee055505055500550505050505050505050550
ee0000eeee0000ee00fff0ee0ffffff0e0ccc0ee0f000ee09000eee0c0eeee0c0eeee000000ee02550ee025250ee055505055500550505050505050505050550
ee00ee00ee00ee000f5f5f0eeeeeeeee0cc9cc0e0f8880e094440ee0c0eeee0c0eee05757550e022201e055250ee055505055500550505050505050505050550
ee010010ee0100100ffffff0eeeeeeee09ccc30e0f0f0ee09090eee0000eeeee000e05755550eeeeeee05752550e055505055500555055505550555055505550
ee011110ee011110eee0eeeeeeeeeeee0ccca30e000eeee000eeee011110eeee060e05552220eeeeeee05552250e055550555500555555555555555555555550
e0117170e0117170ee0c0eeeee0eeeeee0c330e08880ee04440ee01dddd10eee000e02252550eeeeeee05252250e055555555500ddddddddddddddddddddddd0
0111111001111110ee0cc0eee0c0eeeeee000eee09000ee0a000e0dddddd0eee050e022222201eeeeee02222220100000000000e00000000000000000000000e
0111111001111110e0cc30eee0cc0eeee0ccc0ee098880e0a4440e0dddd0eeee050ee000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0111111001111110e0cc30ee0cc30eee0ccacc0e09090ee0a0a0eee0000eeeee050e05752550eeeeee1111111111111111111111111111111eeeeeeeeeeeeeee
01010010e010110ee0cc330e0cc330ee0accc30e000eeee000eeeee0000000eee0ee05555520eeee1111111111111111111111111111111111111eeeeeeeeeee
000e000eeeeeeeee0cc3330e0cc330ee0ccc83008880ee04440eee011111110eeeee05722520eee1111111111111111111111111111111111111111eeeeeeeee
0cc0cc0eee0eeeeee0c330e0cc3330eee0c330ee0a000ee08000e01ddddddd10eeee05552520eee111111111111111111111111111111111111111111eeeeeee
e0ccc0eee0c0eeeeee010eee00100eeeee000eee0a8880e0844400ddddddddd0eeee05752520eee11111111111111111111111111111111111111111111eeeee
ee0c0eee0ccc0eeeee010eeee010eeeee0ccc0ee0a0a0ee08080ee0dddddddd0eeee022222201ee1111111111111111111111111111111111111111111111eee
eee0eeee0c0c0eeeeeee00eeeeeeeeee0cc8cc0e000eeee000eeeee00ddddd0eeeeeeeeeeeeaaaa111111111111111111111111111111111111111111111111e
eeeeeeee00e00eee00e0f0ee0eeeeeee08ccc3008880ee04440eeeeee00000eeeeeeeaaeeeeeeee1111111111111111111111111111111111111111111111111
eee0000eeeeeeeee0f00c0e0f0e00eee0ccc830e0b000ee0b000eee0000000eeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
ee077770eee0000ee0cc0000c00f0eeee0c330ee0b8880e0b4440e0aaaaaaa0eeeeeeeeeeeaaaeee11111111111111111111111111111111111111111111111e
ee078780ee077770000c0f0e0cc0eeeeee000eee0b0b0ee0b0b0e0a9999999a0eeeeeeeeeeeeeeeeeeee11111111111111111111111111eeeeeeeeeeeeeeeeee
e0777770ee0787800f0cc0e0fc0eeeeee0ccc0ee000eeee000eee09999999990eeeeeeeeeee7777eeeeee11111111111111111111eeeeeeeeeeeeeeeeeeeeeee
07778880e0777770e0cc0eee00c0eeee0ccbcc008880ee04440eee0999999990eeeee77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0777888007778880ee0c0eeee0c0eeee0bccc30e07000ee07000eee00999990eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0777777007777770eeee00eeeeeeeeee0cccb30e078880e074440eeee00000eeeeeeeeeeee777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
07070070e070770e00e090ee0eeeeeeee0c330ee07070ee07070eeeee0000eeeeeeeeeeeeeeeeee111eeeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeee0900c0e090e00eeeee000eeeeeeee00e0eeee0ee0aaaa0eeeeeeeeeeeeebbbbe111eeeeeeeee1eee11eeeeeee1eeeee1eeeeeeeeeeeeeeee
ee088880eee0000ee0cc0000c0090eeee0ccc0ee0eee040040ee0400a9999a0eeeeeebbeeeeeeee11111eeeeeee1eeee111eeeeee1eeee1eee1eeeeeeeeeeeee
ee089890ee088880000c090e0cc0eeee0cc7cc0040e040ee040e02009999990eeeeeeeeeeeeeeeee11111eeee1111eee1111eee1e1ee1111ee11eeeeeeeeeeee
e0888880ee089890090cc0e09c0eeeee07ccc30e040020ee020040ee099990eeeeeeeeeeeebbbeee1111111111111111111111111111111111111eeeeeeee1ee
0888aaa0e0888880e0cc0eee00c0eeee0ccc630e02040eeee0420eeee0000eeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111eeeeee1eee
0888aaa00888aaa0ee0c0eeee0c0eeeee0c330eee020eeeeee040eeeeeeeeaeeeeeeeeeeeee8888ee11111111111111111111111111111111111111eee1111ee
0888888008888880eeeeeeeeeeeeeeeeeeeeeeeee040eeeeee040eeeeeeeaeeeeeeee88eeeeeeee1111111111111111111111111111111111111111111111111
08080080e080880eeeeeeeeeeeeeeeeeeeeeeeee04220eeee04220eeeaaaeaaeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111111111
eee0ee0eeee0ee0ee0ee0ee0ee0e00e0e00eeeeeeeeeeeee11eeeeeaaeeeeeeeeeeeeeeeee888ee1111111111111111111111111111111111111111111111111
eee0000eeee0000e0800a00700900606060eeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeeeeeeeeeeeeeeeee1111111111111111111111111111111111111111111e
0e044440ee044440060060060060055d550eeeeeeeeeeeeeeeeeeeeaaaeeaeee00eee0000eeeeeee11111111111111111111111111111111111111111111111e
e0447070004470700600600600600000e00eee00eee00eeeee111eeeeeaaeeee0d0e0aa990eeeeee1111111111111111111111111111111111111111111111ee
e0444040e044404006006006006005600ff0e0ff0e0ff0eeddeeeeeeeeeeaaee0dd0aaaaa900eeee111111111111111111111111111111111111111111111eee
e0444440e0444440eeee0000000006500ff0e0ff0e0ff0eeeeeeeeeeeeeeeea05666666666660eeeeeeee111111111111111111111111111111111111111eeee
e000000ee000000eeeee06600dd005600aa0e0aa0e0aa0eeeeeeeeeeeeeeeee05dddddddddd660eeeeeeeee111111e11111111eeeeeeeeeee1111111eeeeeeee
e0ee0e0eee00e0eeeeee0dd00660000e0aa0e0a00e00a0eeeedddeeeeeeeeeee00000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee0000eeeeeeeeeeeeee060e0d009b0e00eee00eee00eee33eeeeeeeeeeeeeee111111111111eeeeeeeeeeee11111111111111eeeeeeeeeeeeeeeeeeeeeeeee
ee0bbbb0eee00000eeeeee0eee0e09900ff0e0ff0e0ff0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111111111111111eeeeeeeeeeeeeeeeeeeee
e0bb7b7b0e0bbbbb0eeeeeeeeeee0bb00ff0e0ff0e0ff0eeeeeeeeeeeeeeee00000eeeeeeeeeeeeeee1111111111111111111111111111eeeeeeeeeeeeeeeeee
e0bbbbbb00bbb7b7b0eeeeeeeeee00000aa600aa600aa60eee333eeeeeeee0ddddd00eeeeeeeeeeee111111111111111111111111111111eeeeeeeeeeeeeeeee
e0bbbbbb00bbbbbbb0eeeeeeeeeeeeee0aa0e0a00e00a0eeeeeeeeeeeeee0d66666dd0eeeeeddeee11111111111111111111111111111111eeeeeeeeeeeeeeee
ee000000ee0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0d6d000d6dd0eeeeeeee1111111111111111111111111111111111eeeeeeeeeeeeeee
ee0000eeee0000eeee0000eeee0000eeeeeeee00eeeeeeeeeeeeeeeeee0d6d07bb0d6dd0eeeeeee1111111111111111111111111111111111eeeeeeeeeeeeeee
e0dddd0ee0dddd0ee0dddd0ee0dddd0eeeeee0dd0eeeeeeeeeeeeeeeee0dd07bbbb0d6d0eeeeeeee11111111111111111111111111111111eeeeeeeeeeeeeeee
e0d7d70ee0d7d70ee0d7d70ee0d7d70eeeee0dd50eeeeeeeeee0eeeeeeeed0bbbbb0d6d0eeeeeeeeeeeee1111111111111111111111eeeeeeeeeeeeeeeeeeeee
e00ddd0eee0ddd0eee0ddd0eee0ddd0eeee0dddd0eeeeeeee6e60eeeddeeeeeebb0dddd0eddeeeeeeeeeeeeee11111111111111eeeeeeeeeeeeeeeeeeeeeeeee
0d0000d0e000000ee000000ee000000eee0dd7d50eeeeeee06bb000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee111111111111eeeeeeeeeeeeeeeeeeeeeeeeee
050d00500d0d00d00d0d00d00d0d00d0ee0dd7dd0eeeeeee06bbddd0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111111eeeeeeeeeeeeeeeeeeeeeeeeeee
05050050050500500505005005050050e0ddd7d50eeeeeeeeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0500ee050ee0500505005005050050e0d7d7dd0eeeeeeee00000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e111e11111e1111111e11eeeeeee0eeee0d7d7dd50eeeeee0bbb770eeeeeeeeeee0000eeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
1eee1eeeee1eeeeeee1eeeeeee0000ee0dddd7ddd0eee000bbbbbb7000eeeee0e060600eee060600eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e111e11111e1111111eeee111076660e07d5d7dd50e00d60bbbbbbb06d00ee060606050ee0606050eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeeeeeeee
eee00eee00eeeeee0000eeeee06bb60e0dd5d7ddd00d6dd600000006dd6d0060606050ee0606050ee000eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0c0eeeeee0eeee
ee0220e0220eeee088880eeee06bb60e07ddd7dd500dd6dd6666666dd6dd0060606050ee0606050e02220eeeeeeeeeeeeeeeeeeeeeeee1eeee0c0eeeee0c0eee
ee02d0e0d20eeee055510000ee0dd0ee0dd7d7ddd0e00d66ddddddd66d00e0606060111e060601110d2d0eeeeeeeeeeeeeeeeeeeeeee1eeee0cc0eeeee0c0eee
e0ddd0e0ddd0eee055510ddd0e0dd0ee05d7dddd50eee0000000000000eeeeeeee0000eeeee0000e0d2d01eeeeeeeeeeeeeeeeeee111e11eee0cc0eeee0cc0ee
e0d2d0e0d2d0eee05551000d0e0dd0ee05d7d7ddd0eeee11111111111eeeeee0e0f0f00eee0f0f0000eeeeeeeeee0000eee00ee11eeeeeeeee0c30eee0ccc0ee
0dd2d0e0d2dd0ee088820e010eeeeeee05d7d7d550eeeeeeeeeeeeee0000ee0f0f0f050ee0f0f0500c0ee0000ee0c00c0e0c0eeeeeeee11eee0cc30eee0cc30e
0d22d010d22d01eeeeeee000eeeeeeee0dddddddd0eeeeeeeeeeeee08880e0f0f0f050ee0f0f050ee0c00c00c00c0ee0c0c0eee111ee1eeee0cc300eee0c300e
eee00000eee00000eeee05550000000e05d5d5d550eeeee0000000085550e0f0f0f050ee0f0f050ee0c0c0ee0c0c0ee0c0c0eeeeee11eeeee0cc330ee0cc330e
00e06060e0006060e0e0055100a88a0e0dd555dd0eeeee066d0555588880e0f0f0f0111e0f0f0111e0c0c0ee0c0c0ee0c0c0eeeeeeee11ee0ccc3330e0ccc330
07006060e07060600d0d05510e0880ee055555550eeee06ddd0588588880eeee000eeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeee1e00ccc3300ccc3300
e0665650e06656500d0d08820005500e055555550eee06dddd05555888850ee04420eeee00eeeeeee040eeeeeeeeeeeeeeeeeee0eee000eee0c3330ee0c3330e
06666660e066666001010882008dd80e055050550ee000000055000000850ee04220eee0440eeeee0420eeeeeeeeeee00eeeee040e05110e0cc333300cc33330
eeeeeeeeeeeeeeee000eeeeeee0550eee0000000ee0885555550888850850e04220eeee04220eee04220eee000eeee0440eee0420e01110e0001100000011000
eeee000eeeeeeee05550eeeeeeeeeeeeeeeeeeeeee000000000000000000eee02220ee042220eee042220e04420eee04220e04220ee0000eee0110eeee0110ee
e0e05550eeeeeee05055000eeeeeeeeee1111111eee11111111111111111eee04220ee0422240ee0422200422220e042220e042420051110eeeeee0000e0000e
0e0050500eeeeee050500ee0eeeeeeeeeeeeeeeeeeeeee00eeeee0eeeeeeee042240e04224420e0422240eeee8888888888888eeee011110eeeeee0880e0880e
0ee0000dd0eeeee0000dd0eeeeeeeeeeeeeeeeeeeeeee050eeee080eeeeee0422422004222220e0422420eeee888888eeee888eeeeeeeeecccccce0510e0510e
eeee0e09d90eeee0e009d90eeeeeeeeeeeeeeeeeeeee0850eee08880eeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee88888eeeeee88cccceeccccccc66e0510e0510e
eeee0ee0000eeee0eee000eeeeeeeeeeeeeeeeeeeee08850ee0558880eeeeeee00eeeeeeeeeeeeee040eeeeee88888eeeeee88ddddccc6c66c666e0510e0510e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee05555800eeeeee0440eeeee000eeeee040eeeeee88888eeeeee88cccceeccccccc6600500e00000
eeeeeeeeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeddee00055585050eeeeee04220eee04440eee04220eeeee88888eeeeee88ddddeeeeecccccc08008008820
ee00eeee00eeee00eee0ff0eeeeeeeeeeeeeeeeeeeeeeeddd558508850eeee042220ee042220eee04220eeeee888888eeee888cccceeeee0000ee08208208820
e0ff0ee0ff0ee0ff0ee0ff0eeeeeeeeeeee00eeeeeeeeeeedd550888850eee04220eee042220eee042240eeee101eeeeeeeee9eeee6eee06ddd0e00000000000
e0ff0ee0ff0ee0ff0ee0880eeeeeeeeeee00a0000eeeedeeeee5500000eeee042220e04224420e0422420eeee101eeeeeeee999eee6e6e06ddd0e05555555110
0daa0e0daa0e0daa0e0daa0eeeeeeeeee080885850eeeeeeeeeeeeeeeeeee0422222004242220e0422420eeee101110001199999ee6eee0dddd0e08000008220
0daa0e0da00e0d0a0e0daa0eeeeeee000000eeeeeeeeeeeedddeeeeeeeeee0000000eeeeeeeeeeeeeeeeeeeee1011099901e999ee66e6e05dd50e080ddd08220
eeeeeeeeeeeeeeeeeeeeeeeeeeeee02222220eeeeeeeeeeeeeeeeeeeeeee066666660eeeeeeeeeeeeeeeeeeee1011109990e999ee6666e055550e05000005110
eeeeeeeeeeeeeeeeeeee00eeeeee0220022220eeeeeeeeeeeeeeeeeeeeee060000060eeeeeeeeeeeeeeeeeeee1010000990eaaae455555055550e05555555110
ee00eeee00eeee00eee0ff0eeeee0d0b70ddd0e444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0ff0ee0ff0ee0ff0ee0ff0eeeee020bb0d220e42444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0ff0ee0ff0ee0ff0ee0880eeeee0dd00dddd0ee424424444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0daa600daa600daa600daa60eeee02ddddd220ee42444244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0daa0e0da00e0d0a0e0daa0eeeee0dddddddd01ee424442444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee00eee42444424444444eeeeeeeeee244444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee00000e040eeeeeeee020eeee424444244444444eeeeeeeee2222eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeee0000eeeeeeee044420e04200eeeeee020eeee42444442444444444eeeeeee2444eeeeeeee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00ee0f00f0ee00eee044420e042420eee00420eeeee424444424444444444eeeee2444eeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0f00c0ee0c00f0ee0442420e042420ee042420eeeee42444444222222222222ee222222eeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0c0c0ee0c0c0ee04442420e042420ee042420eeeee44244422444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeee
e0c0c0ee0c0c0ee04424420e042420ee042420eeeee4424224442222222222222222222222222222222222222222222444444444444444444eeeeeeeeeeeeeee
eeeee0000eeeeee022222200444222004442220eeee4444444224444444444444444444444444444444444444444444222444444222222222444eeeeeeeeeeee
00ee090090ee00eeeeeeeeee00eeeeeeeeee00eeee44222222222222244444444444444444442222222224442222222222224442200000000000444eeeeeeeee
0900c0ee0c0090eeee00000e070eeeeeeee0f0eee4422000000000002242222222222222224220000000224220000000000224220eeeeeeeeeee0000eeeeeeee
e0c0c0ee0c0c0eeee0777f0e07f00eeeeee0f0ee54220111111111110222000000000000022201111111022201dd1111dd102220eeeeeeeeeeeeeeee0eeeeeee
e0c0c0ee0c0c0eeee0777f0e07f7f0eee007f0e54420111111111111104011111111111110401111d1111040111111111111040ee00000eeeee0000000eeeeee
eeeee0000eeeeeee077f7f0e07f7f0ee07f7f0e4542011100001110110401111110000111040110000011040111111111111040e0535350eeee033330e0eeeee
00ee0a00a0ee00e0777f7f0e07f7f0ee07f7f0e55420110dddd0105010401111105555011040110555011040111111111111040e0555550eeee033330000eeee
0a00c0ee0c00a0e077f77f0e07f7f0ee07f7f0e44420110cccc0105010401111105555011040110555011040111111111111040e0535350eeee0333353300eee
e0c0c0ee0c0c0ee0ffffff00777fff00777fff055420110dddd0105010401551105555011040110555011040111111111111040e0555550ee00033335550e0ee
e0c0c0ee0c0c0eeeeeeeeeee00eeeeeeeeee00e45420110cccc0105010401551105555011040110555011040111111111111040e0535350ee05555555550222e
eeeee0000eeeeeeeee00000e070eeeeeeee060e54422010dddd0105010401111110440111040110555011040111111111111040e0555550ee044444422222222
00ee080080ee00eee077760e07600eeeeee060ee5442222222222222222222222222222222222222222222222222222222222222222222222222222244444442
0800c0ee0c0080eee077760e076760eee00760eeee44222444444444444444444222222224444444444444444444444444444444444444444444444444444422
e0c0c0ee0c0c0eee0776760e076760ee076760eeee4442222222222222222224220000002242222222222242222222222222222222224222222222444444422e
e0c0c0ee0c0c0ee07776760e076760ee076760eeee0000000000000000000022201111110222000000000222000000000000000000022200000002222222422e
eeeee0000eeeeee07767760e076760ee076760eeee50111111111111111110040110000110401111d111104011111111111111111110401151511024444422ee
00ee0b00b0ee00e066666600777666007776660eee5011111100001110011104010d6dd0104011000001104011111111111111111110401151511022224222ee
0b00c0ee0c00b0eeeeeeeeee00eeeeeeeeee00eeee501111109999010d0111040100dd0010401105550110401111111111111111111040115151102444222eee
e0c0c0ee0c0c0eeeee00000e060eeeeeeee0d0eeee50111009999990dd011104010400401040110555011040100000100000100000104010000010244222eeee
e0c0c0ee0c0c0eeee0666d0e06d00eeeeee0d0eeee501106666666666650110401044440104011055501104010ddd01055d01055d010401055501024222eeeee
eeeee0000eeeeeeee0666d0e06d6d0eee006d0eeee501066dddddddddd501104010444401040110555011040105550105d50105d501040105550102222eeeeee
00ee070070ee00ee066d6d0e06d6d0ee06d6d0eeee501000000000000001110401004400104011055501104010555010d55010d550104010555022222eeeeeee
0700c0ee0c0070e0666d6d0e06d6d0ee06d6d0eeee22222222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeee
e0c0c0ee0c0c0ee066d66d0e06d6d0ee06d6d0eeeee2222222222222222222222222222222222222222222222222222222222222222222222222eeeeeeeeeeee
e0c0c0ee0c0c0ee0dddddd00666ddd00666ddd0eeeeeeeeee22222222eee22222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222222eeeeeeeeeeeeeeeeeeee
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001000000000000000000000000000100000000000000000000000000000000000000d00000000000
00000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000
00000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d00000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000009999999090000000000000000000000000000000000010000000000000000000000000d00000000000000000000000000000000000000000
00000000000000090009000090000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000
00000000000000000009000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009000090000099000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000
00000000000000000009000099900900900000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000009000090090900900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000090000900909990000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000d0
00000000000000000009000090090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009000090090099900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007777777000000777000077700077700777777770777777700007777777707777777000777000007770777000077700000000000000000000
00000000000000007777777700007777700077770077707777777770777777770077777777707777777700777700077770777000777770000000000000000000
00000000000000007777777770077777770077777077707777777770777777777077777777707777777770777770777770777007777777000000000000000000
00000000000000007770007770777707777077777777707770000000777000777077700000007770007770777777777770777077770777700000000000000000
00000000000000007770007770777000777077777777707770000000777000777077700000007770007770777777777770777077700077700000000000000000
00000000000000007770007770777000777077777777707777000000777000777077700000007770007770777777777770777077700077700000000000000000
00000000000000007770007770777000777077707777700777700000777000777077700000007770007770777077707770777077700077700000100000000000
00100000000000007777777770777777777077700777700077770000777777777077777700007777777700777007007770777077777777700000000000000000
00000000000000007777777770777777777077700077700007777000777777777077777700007777777000777000007770777077777777700000000000000000
00000000000000007777777700777777777077700077700000777700777777770077777700007777777700777000007770777077777777700000000000000000
00000000000000007770000000777000777077700077700000077770777000000077700000007770077770777000007770777077700077700000000000000000
00000000000000007770000000777000777077700077700000007770777000000077700000007770007770777000007770777077700077700000000000000100
00000000000000007770000000777000777077700077700000007770777000000077700000007770007770777000007770777077700077700000000000000000
00000000000000007770000000777000777077700077700000007770777000000077700000007770007770777000007770777077700077700000000000000000
00000000000000007770000000777000777077700077707777777770777000000077777777707770007770777000007770777077700077700000000000000000
00000000000000007770000000777000777077700077707777777770777000000077777777707770007770777000007770777077700077700000000000000000
00000000000000007770000000777000777077700077707777777700777000000077777777707770007770777000007770777077700077700000000000000000
0000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009990000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090009000000000000000000000000000000
00000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000900000000000000000000000000010000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000009009090009000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900999909009090090000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000909009009090000000000000000000
00000000001000000000000000000000000000000000000000100000000000000000000000100000000000000000900009009009000900000000000000000000
000000000000000000001000000000000000000000000000000000000000000000000d0000000000000000000000900009009009000900000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099990000999009000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000
00000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000d0000000
000000000000000000000000000000000000ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000c77cccd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100000000000000d0000000000000c7caaacdd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000cccaaaaaddd001111111111100110000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000ccaaaaaa9dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000ccaaaaa99dd000000000000000000000000000000000000000000000000000000000100000000010000000000000000
000000000000000000000000000000000ccaaaa999dd001111111111111111111111100000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000cccaa999ddd000000000000000000000000011111110000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000ccc999ddd0000000000000000000000000000000001111100000000000000000000000000000000000000000000000
00000000000000000000000000000000000cdddddd00000000000000000000000000000000000000000100000000000000000000000000000000000000000000
000000000000000000000000000000000000ddddd000000000000000000000000000000000000000000000100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000001000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000
00000000000000000000000000d00000000000000000000000000000000000000000000000000000000000000440000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000010000000000000000000000000000002222222200000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222222220000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000044c2c2444420000010000000000000000000000000
0000000000000000000000000000000000000000000000000d000000000000000000000000000000000000002222222200000000000000000000000000000000
00000000010000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000
00000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000666660000b000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000000000000000000
0006660666660000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000666666660000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0666666666600000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0666666660000000b300000033333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666660000000000b330333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000001000000000000
666000000000000bb30033333333333333b33333333333ddd0000000066600666000000000000000000000000000000000000000000000000000000000000000
600000000003330bb3303333333333b33b333333333333333ddd0000000666666666666000000000000000000000000000001000000000000000000000000000
00000000033330bbb33303333333333b3b33333333333333333ddd00000066666666666600000000000000000000000000000000000000000000000000000000
000000333333300bb33003333333333b3b3333333333333333333333300000666666666600000000000000000000000000000000000000000000000000000000
000033333333330b33303333333333333333333333333333333333333dd000006666666600000000000000000000000000000000000000000000000000000000
00333333333330bb333303333333333333333333333333333333333333ddd0000006666600000000000000000100000000000000000000000000000000000000
333333333333300044000333333333333333333333333333b333b3333333ddd00000066666000000000000000000000000000000000000000000000000000000
3333333333333330440333333333333333333333333333333b3b33333333dddd0000006666600000000000000000000000000000000000000000000000000000
333b333b33333333333333333333333333330033003333333b3b333333333ddddd00000666600000000000000000000000000000000000000000d00000000000
3333b3b33333333333333333333333333333050050333333333333333333333dddd0000066600000000000000000000000000000000000000000000000000000
3333b3b333333333333333333333333333330555503333333333333333333333dddd000006000000000000000000000000000000000000000000000000000000
3333b3b3333333333333333b33333333333307575503333333333333333333333ddddd0000000000000000000000000000000000000000000000000000100000
333333333333333333333333b33b3333333305555550333333333330333333333dddddd000000000000000000000000000000000000000000000000000000000
333333333333333333333333b3b3333333330555555033333333330b0333333333dddddd00000000000100000000000000000000000000000000000000000000
333333333333333333333333b3b3333333330555555033333333330b03333333333dddddd0000000000000000000000000000000000000000000000000000000
333333333333333333333333333333333333050050503333333330bb03333333333ddddddd000000000000000000000000000000000000000000000000000000
3333333333033033333333333333333333333333333333333333300bb03333333333ddddddd00000000000000000000000000000000000000000000000000000
3333333333000033333333333333333333333333333333333333330b303333333333dddddddd0060000000000000000000d00000000000000000000000000000
3333333030444403333333333333333333333333333333333333330b33033333333333ddddddd00600000000000100000000000000000000000000000d000000
333333330447070333333333333333333333333333333333333330bb30033333333333333dddd500660000000000000000000000000000000000000000000000
333333330444040333333333333333333333333333333333333330bb33033333333333333333ddd0066600000000000000000000000000100000000000000000
33333333044444033333333333333333333333333333333333330bbb333033333b33333333333333006660000000000000000000000000000000000000000000
333333330000003333333333333333333333333333333333333300bb3300333333b33b3333333333000660000000000000000000000000000000000000000000
333333330330303333333333330033333333333333333333333330b33303333333b3b33333333333300066600000000000000000000000000000000000000000
33333333333333333333333330b0333333333333b333b33333330bb33330333333b3b33333333333330066660000000000000000000000000000000000000000
33333333333333333333333330b00333333333333b3b333333330004400033333333b33333333333333006660000000000000000000000000000000000000000
33333333333333333333333330bb0333333333333b3b333333333304403333333333333333333333333006600000000000000010000000000000000000000000
3333333333333333333333330bb30333333333333b3b333333333333333333333333333333333333333300000000000000000000000000000000000000000000
33333333333333333333333330bb3033333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000
3b333333333333333333333330b30033333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000
33b33b3333333333333333330bb33033333333333333333333333333333333333333333333333333333333000000000000000000000000000000001000000000
33b3b33333333333333333330bbb3303333333333333333333333333333333333333333333333333333333000000000000000000000000000000000000000000
33b3b3333333333333333330bbb33003333333333333333333333333333333333333333333333333333333300100000000000000000000000000000000000000
3333333333333333333333330b333033333333333333333333333333333333333333333333333333333333300000000000000000000000000000000000000000
333333333333333333333330bb333303333333333333330003333333333333333333333333333333333333dd0000000000000000000000000000000000000000
33333333333333333333333000440003333333333333308880333333333333333333333333b333b333333ddd0000002022200220220002202020222002202220
33333333333333333333333330440333333333333333330f000333333333333333333333333b3b3333333ddd0000002020202020202020002220220020000200
33333333333333333333333333333333333333b33333330f888033333333333333333333333b3b333333ddddd000002022002020202020002020200000200200
33333333333b333b333333333333333333b33b333333330f0f0333333333333333333333333333333333ddddd000002020202200202002202020222022200200
333333333333b3b33333333333333333333b3b3333333333333333333333333333333333333333333333dddddd00000000000000000000000000000000000000
333333333333b3b33333333333333333333b3b3333333333333333333333b333b3333333333333333333dddddd00000220022022202220022000000040000400
333333333333b3b3333333333333333333333333333333333333333333333b3b3333333333333333333ddddddd00002000202022202200200010000440004040
3333333333333333333333333333333333333333333333333333333333333b3b333333333333333333ddddddddd0002020222020202000002000000040004040
3333333333333333333333333333333333333333333333333333333333333b3b333333333333333333ddddddddd0002220202020202220222000000040400400
3333333333333333333333333333333333333333333333333333333333333333333333333333333333ddddddddd0000000000000000000000000000000000000

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
013c00002230022330223002233022300223302230000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000500003f6603565030640276401e63018620126200f6200d6200b62009620086200762007620066200662005620046200362003620036200262002620026200160000610016000061001600006100160000610
000800001f4203a4202e40033400244002b4003c4002040037400394003c4003f40009400064000540003400004000940006400074000b4000c4000b400084000040000400004000040000400004000040000400
000400003544027440304401f44024440164400f440134300c4300743000430004200040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000200002145021450204501f4501a450184500040000400094500845000400004000040001450014500245000400004000040000400004000040000400004000040000400004000040001400014000040000400
00030000214501d4501845012450154501a4501845012450004000040005450004000545007400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
000300001945023450174501e450184500000011450134500d4500f45000000114500045000450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000336503365033650336502f4502e4502e4502c4502b4502a45028450284502465024450226501f4501e6501a45015450104500b4500345005400004000065000640006400063000620006200061000620
00020000336503365033650336502e4502d4502d4502c4502a650286502745026450234501e45018450134500d4500645001450004400b4000065000640006400063000620006300065000650006400062000630
001000100606006050005600055005060050400176001750060600605000560005500506005040027600275000000000000000000000000000000000000000000000000000000000000000000000000000000000
180800001e6210f551226210f551226210f551226210f551246210f551246210f551256210f551276210f551296210f5512a6210f5512b6210f5512e6210f5512e6210f5512d6210f551296413b650146500c653
140700000361003610036200462005620076200b6200f62013620176201b6201e6202062021620226202362023620236202362021620206201d6201a6201762014620116200d6200b62009620056200362000610
000600002243022430164300d4301261012610126101161011610106100f6100d6100c6100a610086100761005610046100161000610066000560004600036000260002600006000060000600006000060000600
000600000b420174202242022420096100a6100d6100e61011610166101b6101d610256102e6103f610266002e6003c6003f60000000000000000000000000000000000000000000000000000000000000000000
001000000a1100a110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00040000286201f6201a620166201262011620106200f6200f6200f6200f6200e6200e6200d6200d6200d6200d6200c6200b6200a620096200962008620076200662005620046200462003620026200062000620
0005000000610006100061000610006100061000610006100061000610006100061000610006100061001610026100361005610056100661007610086100b6100b6100f6101161014620176201b6302264026650
000200003265029250292500545028650161501515006350063501f6501f650102501025017250162500725007250236501d65019650000000a30000000000001025010250000000430000000000001125011250
000a00002c5502d5502c5502b550275501d55017550125500e5500955006550035500255001550005500055000550005500055000550005500055000540005000050000500047500475004700047000450008700
000900001a05014050080501500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000b00001f050150500a0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500003b6503a650295502655032450324501b550185501855000000154500f4500d55005450024500150000500005000050000000000000000000000000000000000000000000000000000000000000000000
000600001514016150211500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000214201c4401c4402144021440114200340000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000180501b050240502405030050300503705037050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480300000d4502240023450224002345022400234501d400224500040022450004002145021400214501f400204501b4001f450004001f450004001e450144001d4501d4001d4500b4001c450004001b45000400
013400002765327600276002760027600276002760027600276002760028600286000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01220000361512a151361510010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00010000304512f4502f4502e4502d4502b450294502745025450234501e4501a4501745010450094500142000400004000040000400004000040000400004000040000400004000040000400004000040000400
0001000033451334503245032450314502e4502d4502a45026450224501f4501a450154500f450084500140000400004000040000400004000040000400004000040000400004000040000400004000040000400
000400000a150001000a150001000a150001000a150001000a150001000a150001000a150001000a150001000a150001000a150001000a150001000a130001000a11000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
380e0000180501805018050180501a0501a0501a0501a0501c0501c0501e050200502105021050210502105021040210302102221015000000000021050210202205022050220502204222032220222201321000
000200002d5501655012550105501255020550235502455028550255502c5502c5502d5502e55029550225502f5502f550345502f550000003a55038550385500000000000000000000000000000000000000000
00020000325503355033550235501d5501e5502b5502b5502d550325503055028550245502155033550355501b550185503355014550135501255011550255500050000500005000050000500005000050000500
