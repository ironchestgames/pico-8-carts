pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

menuitem(1,'debug',function() _debug=not _debug end)

poke(0x5600,4)    -- char width
poke(0x5601,8)    -- char width for high cars
poke(0x5602,5)    -- char height
poke(0x5603,0)    -- draw x offset
poke(0x5604,0)    -- draw y offset

-- custom font 0x80*8+0x5600 (computer caret)
poke(0x80*8+0x5600,7)
poke(0x80*8+0x5601,7)
poke(0x80*8+0x5602,7)
poke(0x80*8+0x5603,7)
poke(0x80*8+0x5604,7)

-- custom font 0x90*8+0x5604 (better ellipsis)
poke(0x90*8+0x5604,21)

-- custom font 0x2e*8+0x5604 (better punctuation dot)
poke(0x2e*8+0x5604,1)

function flrrnd(n)
 return flr(rnd(n))
end

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

function shuffle(_t)
 for _i=#_t,2,-1 do
  local _j=flrrnd(_i)+1
  _t[_i],_t[_j]=_t[_j],_t[_i]
 end
 return _t
end

function dist(x1,y1,x2,y2)
 local dx,dy=(x2-x1)*0.1,(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

-- set palette
pal(15,140,1) -- light-peach -> true-blue
pal(9,133,1) -- orange -> darker-grey
pal(4,128,1) -- brown -> brownish-black
pal(2,141,1) -- dark-purple -> mauve
pal(1,129,1) -- dark-blue -> darker-blue

palt(0,false)
palt(14,true)

windows={}
rooms={}
loot={}

local computerstate,computerstatec,computermsg,computerlog,computertraced,computertracedmax

sirenc=nil
roomw=24
roomh=25

function _init()
 loot,rooms,windows={},{},{}

 -- set globals
 partnerroomid=nil
 partnerprevroomid=nil
 partnerwindowid=nil
 partnerxoff=5
 partneryoff=10
 partnerc=0
 partnerstate='idling'
 partnerismoving=nil
 partnerobj=nil
 partnermsg=''

 computerstate='booting'
 computerstatec=400
 computertraced=0
 computertracedmax=5
 computerlog={}
 computermsg=nil

 -- west - 1,2
 -- north - 3,4
 -- east - 5,6
 -- south - 7,8

 local _rooms={}
 for _i=0,14 do
  _rooms[_i]={
   id=_i,
   x=(_i%5)*24,
   y=flr(_i/5)*25,
   w=24,
   h=25,
   objs={{},{},{},{},{},{},{},{}},
   islit=flrrnd(2) == 1,
  }
 end

 local _stepcount=12
 local _x=flrrnd(5)
 local _y=flrrnd(3)

 local _dirs={-1,1}
 local _i=1

 local _doormapcoords={
  [1]={xoff=0,yoff=14,sx=0,sy=97,sw=5,sh=7},
  [3]={xoff=4,yoff=0,sx=0,sy=104,sw=7,sh=5},
  [6]={xoff=24,yoff=14,sx=0,sy=97,sw=5,sh=7},
  [8]={xoff=4,yoff=25,sx=0,sy=104,sw=7,sh=5},
 }

 ::continuecreaterooms::
 while _i <= _stepcount do
  local _nextx=_x
  local _nexty=_y
  if rnd() > .5 then
   _nexty+=_dirs[flrrnd(2)+1]
  else
   _nextx+=_dirs[flrrnd(2)+1]
  end

  local _curroom=_rooms[_x+_y*5]
  local _nextroom=_rooms[_nextx+_nexty*5]
  local _doorcount=0
  local _doorcountnext=0

  for _j=1,#_curroom.objs do
   if _curroom.objs[_j].typ == 'door' then
    _doorcount+=1
   end
   if _nextroom and _nextroom.objs[_j].typ == 'door' then
    _doorcountnext+=1
   end

   if _doorcount > 3 or _doorcountnext > 3 then
    _i+=1
    goto continuecreaterooms
   end
  end

  if _nextx < 5 and _nextx >= 0 and _nexty < 3 and _nexty >= 0 then
   if _nexty - _y == 1 then -- down
    _curroom.objs[8]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[8] }
    _nextroom.objs[3]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[3] }
   elseif _nexty - _y == -1 then -- up
    _curroom.objs[3]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[3] }
    _nextroom.objs[8]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[8] }
   elseif _nextx - _x == 1 then -- right
    _curroom.objs[6]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[6] }
    _nextroom.objs[1]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[1] }
   elseif _nextx - _x == -1 then -- left
    _curroom.objs[1]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[1] }
    _nextroom.objs[6]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[6] }
   end
   _x=_nextx
   _y=_nexty
  end

   _i+=1
 end

 -- add cameras
 local _pos={
  [1]={x=2,y=10,otheri=2}, -- west
  [3]={x=8,y=2,otheri=4}, -- north
  [6]={x=20,y=10,otheri=5}, -- east
  [8]={x=8,y=18,otheri=7}, -- south
 }

 local _dirs={1,3,6,8}
 local _addcampreds={}

 for _i=0,14 do
  local _room=_rooms[_i]
  for _dir in all(_dirs) do
   if _room.objs[_dir].typ != 'door' and _room.objs[_pos[_dir].otheri].typ != 'door' then
    _room.objs[_dir]={
     typ='camera',
     id=_room.id,
     mapxoff=_pos[_dir].x,
     mapyoff=_pos[_dir].y,
     ison=true,
    }
    _room.objs[_pos[_dir].otheri]={
     typ='nexttocamera',
    }
    break
   end
  end
 end

 -- add only rooms w doors
 for _i=0,14 do
  local _room=_rooms[_i]
  local _hasdoor
  for _obj in all(_room.objs) do
   if _obj.typ == 'door' then
    _hasdoor=true
   end
  end

  if _hasdoor then
   rooms[_room.id]=_room
  end
 end

 -- fix camera ids
 local _roomswithcam={}
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   for _obj in all(_room.objs) do
    if _obj.typ == 'camera' then
     add(_roomswithcam,_room)
    end
   end
  end
 end

 shuffle(_roomswithcam)

 for _i=1,#_roomswithcam do
  local _room=_roomswithcam[_i]
  if _i <= 9 then
   for _obj in all(_roomswithcam[_i].objs) do
    if _obj.typ == 'camera' then
     _obj.id=_i
    end
   end
  else
   for _j=1,#_room.objs do
    if _room.objs[_j].typ == 'camera' then
     _room.objs[_j]={}
    end
   end
  end
 end

 -- add windows
 local _windowsmapcoords={
  [2]={xoff=-1,yoff=4,sx=0,sy=109,sw=3,sh=7},
  [4]={xoff=14,yoff=-1,sx=0,sy=116,sw=7,sh=3},
  [6]={xoff=23,yoff=14,sx=0,sy=109,sw=3,sh=7},
  [8]={xoff=3,yoff=24,sx=0,sy=116,sw=7,sh=3},
 }
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   if (rooms[_i-1] == nil or _i == 5 or _i == 10) and _room.objs[1].typ != 'camera' then -- west
    _room.objs[2]={ typ='window', roomid=_room.id, mapcoords=_windowsmapcoords[2] }
    add(windows,_room.objs[2])
   elseif (rooms[_i+1] == nil or _i == 4 or _i == 9) and _room.objs[6].typ != 'camera' then -- east
    _room.objs[6]={ typ='window', roomid=_room.id, mapcoords=_windowsmapcoords[6] }
    add(windows,_room.objs[6])
   elseif (rooms[_i-5] == nil or _i <= 4) and _room.objs[3].typ != 'camera' then  -- north
    _room.objs[4]={ typ='window', roomid=_room.id, mapcoords=_windowsmapcoords[4] }
    add(windows,_room.objs[4])
   elseif (rooms[_i+5] == nil or _i >= 10) and _room.objs[8].typ != 'camera' then -- south
    _room.objs[8]={ typ='window', roomid=_room.id, mapcoords=_windowsmapcoords[8] }
    add(windows,_room.objs[8])
   end
  end
 end

 partnerstate='windowsearching'
 partnerwindowid=flrrnd(#windows-1)+1

 -- add computers
 local _pos={
  [1]={x=2,y=10}, -- west
  [2]={x=2,y=4}, -- west
  [3]={x=8,y=2}, -- north
  [4]={x=14,y=2}, -- north
  [5]={x=20,y=4}, -- east
  [6]={x=20,y=12}, -- east
  [7]={x=4,y=18}, -- south
  [8]={x=8,y=18}, -- south
 }

 local _computercount=0

 while _computercount == 0 do
  for _i=0,14 do
   if _computercount >= 2 then
    break
   end
   local _room=rooms[_i]
   if _room then
    for _j=1,#_room.objs do
     local _obj=_room.objs[_j]
     if _obj.typ == nil and rnd() < 0.5 then
      _room.objs[_j]={
       typ='computer',
       xoff=_pos[_j].x,
       yoff=_pos[_j].y,
       loot={ name='cute cat pictures', worth=5 },
      }
      _computercount+=1
      break
     end
    end
   end
  end
 end

 -- add cam coords to obj
 local _types2camcoords={
  computer={
   [0]={xoff=26+2,yoff=19,sx=107,sy=0,sw=9,sh=10,flipx=true},
   nil,nil,
   {xoff=0+2,yoff=19,sx=107,sy=0,sw=9,sh=10},
   {xoff=0+2,yoff=7,sx=107,sy=0,sw=9,sh=10},
   {xoff=10,yoff=0,sx=96,sy=0,sw=10,sh=12},
   {xoff=20,yoff=0,sx=96,sy=0,sw=10,sh=12},
   {xoff=26+2,yoff=7,sx=107,sy=0,sw=9,sh=10,flipx=true},
  },
  window={
   [0]={xoff=28,yoff=19,sx=22,sy=0,sw=10,sh=10,flipx=true},
   nil,nil,
   {xoff=0,yoff=19,sx=22,sy=0,sw=10,sh=10},
   {xoff=0,yoff=7,sx=22,sy=0,sw=10,sh=10},
   {xoff=10,yoff=0,sx=0,sy=0,sw=10,sh=12},
   {xoff=20,yoff=0,sx=0,sy=0,sw=10,sh=12},
   {xoff=28,yoff=7,sx=22,sy=0,sw=10,sh=10,flipx=true},
  },
  door={
   [0]={xoff=29,yoff=19,sx=66,sy=0,sw=9,sh=10,flipx=true},
   nil,nil,
   {xoff=0,yoff=19,sx=66,sy=0,sw=9,sh=10},
   {xoff=0,yoff=7,sx=66,sy=0,sw=9,sh=10},
   {xoff=10,yoff=0,sx=44,sy=0,sw=10,sh=12},
   {xoff=20,yoff=0,sx=44,sy=0,sw=10,sh=12},
   {xoff=29,yoff=7,sx=66,sy=0,sw=9,sh=10,flipx=true},
  },
 }

 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   local _camioffset=nil
   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]
    if _obj and (_obj.typ == 'camera' or _obj.typ == 'nexttocamera') then
     _camioffset=_j-1
     break
    end
   end

   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]

    if _camioffset and _obj and _types2camcoords[_obj.typ] then
     local _k=(_j-_camioffset)%8
     _obj.camcoords=clone(_types2camcoords[_obj.typ][_k])
    end
   end
  end
 end

end

cursels={
 [-1]=1,
 [0]=1,
 [1]=1,
}

seloffsetsmax={
 [-1]=3,
 [0]=4,
 [1]=0,
}

seloffsets={
 [-1]=0,
 [0]=0,
 [1]=0,
}

menus={
 [-1]={},
 [0]={},
 [1]={},
}

screensel=0
camerax=0

local skipstates={
 windowsearching_sneaking=true,
 breaking_in=true,
 escaped=true,
 prehiding=true,
 roomchanging=true,
 hacking=true,
 hacking_sending=true,
}

function _update60()

 -- create computer menu
 menus[-1]={}
 if computerstate == 'booting' then
  computerstatec-=1
  computermsg='booting\014\x90\015'
  if computerstatec <= 0 then
   computerstate='booted'
   add(computerlog,'booted',1)
   computermsg=nil
  end

 elseif computerstate == 'targetlocating' then
  computermsg='locating target\014\x90\015'
  computerstatec-=1

  if computerstatec <= 0 then
   local _computerfound=nil
   local _roomc=0
   for _i=0,14 do
    local _room=rooms[_i]
    if _room then
     _roomc+=1
     for _j=1,#_room.objs do
      local _obj=_room.objs[_j]
      if _obj.typ == 'computer' and not _obj.located then
       _obj.located=true
       add(computerlog,'target found in room '.._roomc,1)
       _computerfound=true
       goto computerfound
      end
     end
    end
   end
   ::computerfound::
   if not _computerfound then
    add(computerlog,'no more targets on site',1)
   end
   computertraced+=1
   if computertraced >= computertracedmax then
    add(computerlog,'you have been traced!',1)
   end
   computerstate='booted'
   computermsg=nil
  end

 elseif computerstate == 'tracechecking' then
  computermsg='checking tracing\014\x90\015'
  computerstatec-=1
  if computerstatec <= 0 then
   add(computerlog,'cyber police tracing '..computertraced..'/'..computertracedmax,1)
   computerstate='booted'
   computermsg=nil
  end

 elseif computerstate == 'tracereducing' then
  computermsg='reducing cyber trace\014\x90\015'
  computerstatec-=1
  if computerstatec <= 0 then
   computertraced=max(0,computertraced-1)
   add(computerlog,'tracing reduced',1)
   computerstate='booted'
   computermsg=nil
  end

 elseif computerstate == 'datareceiving' then
  computermsg='receiving data\014\x90\015'
  partnerstate='hacking_sending'
  partnerc=100
  computerstatec-=1
  if computerstatec <= 0 then
   add(computerlog,'data received',1)
   computerstate='booted'
   computermsg=nil
   partnerc=0
  end

 elseif computerstate == 'booted' then
  if partnerstate == 'hacking_ready' then
   add(menus[-1],{
    str='receive data',
    f=function()
     partnerstate='hacking_sending'
     partnerc=360
     computerstate='datareceiving'
     computerstatec=partnerc
     computertraced+=1
    end,
   })
  end

  add(menus[-1],{
   str='tracing status',
   f=function()
    computerstate='tracechecking'
    computerstatec=90
   end,
  })

  if computertraced > 0 then
   add(menus[-1],{
    str='reduce tracing',
    f=function()
     computerstate='tracereducing'
     computerstatec=600
    end,
   })
  end

  add(menus[-1],{
   str='locate a target',
   f=function()
    computerstate='targetlocating'
    computerstatec=120
   end,
  })
 end

 -- create blueprint menu
 menus[0]={}

 if skipstates[partnerstate] and not partnerismoving then
  -- pass

 elseif partnerismoving then
  add(menus[0],{
   str='stop',
   f=function()
    partnermsg='stopped, what\'s next?'
    partnerismoving=nil
    partnerstate='idling'
    partnerc=0
   end,
  })

 elseif partnerstate == 'windowsearching' then
  local _doorcount=0
  local _seecomputer
  for _obj in all(rooms[windows[partnerwindowid].roomid].objs) do
   if _obj.typ == 'door' then

    _doorcount+=1
   elseif _obj.typ == 'computer' then

    _seecomputer=true
   end
  end

  if _doorcount == 1 then
   partnermsg='i see 1 door'
  else
   partnermsg='i see '.._doorcount..' doors'
  end

  if _seecomputer then
   partnermsg=partnermsg..', a computer'
  end


  add(menus[0],{
   str='break in',
   f=function()
    partnerstate='breaking_in'
    partnerc=120
   end,
  })

  add(menus[0],{
   str='check next window',
   f=function()
    partnerstate='windowsearching_sneaking'
    partnerc=100
   end,
  })

 else
  local _escapeadded,_hideadded
  local _curroom=rooms[partnerroomid]

  for _i=1,#_curroom.objs do
   local _obj=_curroom.objs[_i]
   if _obj.typ == 'window' and not _escapeadded then

    add(menus[0],{
     str='escape thru window',
     f=function()
      partnerobj=_obj
      partnerstate='escaping'
      partnerc=90
      partnerismoving=true
      partnermsg='moving\014\x90\015'
     end,
    })
    _escapeadded=true

   elseif _obj.typ == 'door' then

    _str='take door'
    local _nextobj=_curroom.objs[(_i+1)%#_curroom.objs]
    local _previ=_i-1
    if _previ == 0 then
     _previ=#_curroom.objs
    end
    local _prevobj=_curroom.objs[_previ]
    if _prevobj and _prevobj.typ and _prevobj.typ != 'camera' and _prevobj.typ != 'nexttocamera' then
     _str='take door next to '.._prevobj.typ
     if _prevobj.typ == 'door' then
      _str='take door next to other door'
      if _prevobj.leadsto == partnerprevroomid then
       _str='take door next to prev room'
      end
     end
    elseif _nextobj and _nextobj.typ and _nextobj.typ != 'camera' and _prevobj.typ != 'nexttocamera' then
     _str='take door next to '.._nextobj.typ
     if _nextobj.typ == 'door' then
      _str='take door next to other door'
      if _nextobj.leadsto == partnerprevroomid then
       _str='take door next to prev room'
      end
     end
    end

    if partnerprevroomid == _obj.leadsto then
     _str='take door to prev room'
    end


    add(menus[0],{
     str=_str,
     f=function()
      partnerobj=_obj
      partnerstate='roomchanging'
      partnerc=60
      partnerismoving=true
      partnermsg='moving\014\x90\015'
     end,
    })

   elseif _obj.typ == 'computer' then

    if _obj.loot and partnerstate == 'idling' then

     add(menus[0],{
      str='hack computer',
      f=function()
       partnerobj=_obj
       partnerstate='hacking'
       partnerc=240
       partnerismoving=true
       partnermsg='moving\014\x90\015'
      end,
     })
    end

    if _hideadded == nil and partnerstate != 'prehiding' then

     add(menus[0],{
      str='hide!',
      f=function()
       partnerobj=_obj
       partnerstate='prehiding'
       partnerc=120
       partnerismoving=true
       partnermsg='moving\014\x90\015'
      end,
     })
    end

   end
  end

  if partnerstate == 'hiding' then
   menus[0]={{
    str='it\'s safe to come out',
    f=function()
     partnermsg='ok, i\'m coming out'
     partnerstate='unhiding'
     partnerc=120
    end,
   }}

  elseif partnerstate == 'unhiding' then
   menus[0]={{
    str='hide!',
    f=function()
     partnerobj=_obj
     partnerstate='prehiding'
     partnerc=120
    end,
   }}

  end
 end

 -- create cam menu
 menus[1]={}
 local _cams={}
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   local _hascam=nil
   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]
    if _obj and _obj.typ == 'camera' then
     menus[1][_obj.id]={
      ison=_obj.ison,
      f=function()
       _obj.ison=not _obj.ison
      end
     }
     _hascam=true
    end
   end
  end
 end

 -- input
 if btnp(1) then
  screensel+=1
 elseif btnp(0) then
  screensel-=1
 end
 screensel=mid(-1,screensel,1)

 if btnp(3) then
  cursels[screensel]=cursels[screensel]+1
 elseif btnp(2) then
  cursels[screensel]=cursels[screensel]-1
 end

 if screensel == 1 then
  cursels[screensel]=((cursels[screensel]-1)%#menus[screensel])+1
 else
  cursels[screensel]=mid(1,cursels[screensel],#menus[screensel])
 end

 if seloffsets[screensel] > cursels[screensel]-1 then
  seloffsets[screensel]=cursels[screensel]-1
 elseif seloffsets[screensel] < cursels[screensel]-seloffsetsmax[screensel] then
  seloffsets[screensel]=cursels[screensel]-seloffsetsmax[screensel]
 end

 local _opt=menus[screensel][cursels[screensel]]
 if btnp(4) and _opt and _opt.f then
  _opt.f()
 end

 if btnp(5) then
  -- debug(cursels[screensel])
  initpaper()
  return
 end

 -- update camera
 local _camendx=screensel*128
 if abs(_camendx-camerax) > 0 then
  camerax+=(_camendx-camerax)/4
 end
 camera(camerax,0)

 -- update partner
 if partnerismoving then
  local _a=atan2(partnerobj.camcoords.xoff-partnerxoff,partnerobj.camcoords.yoff-partneryoff)
  partnerxoff+=cos(_a)*0.1
  partneryoff+=sin(_a)*0.1

  if dist(partnerxoff,partneryoff,partnerobj.camcoords.xoff,partnerobj.camcoords.yoff) < 2 then
   partnerismoving=nil
  end

 else

  if partnerstate == 'windowsearching_sneaking' then
   partnermsg='sneaking to next window\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerwindowid+=1

    if partnerwindowid > #windows then
     partnerwindowid=1
    end
    partnerstate='windowsearching'
   end

  elseif partnerstate == 'breaking_in' then
   partnermsg='breaking in\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerroomid=windows[partnerwindowid].roomid
    partnerprevroomid=partnerroomid

    local _curroom=rooms[partnerroomid]
    for _obj in all(_curroom.objs) do
     if _obj == windows[partnerwindowid] then
      _obj.isbroken=true
      _obj.camcoords.sx+=11
      partnerxoff=_obj.camcoords.xoff
      partneryoff=_obj.camcoords.yoff
      break
     end
    end

    partnerstate='idling'
    partnermsg='i\'m in, what now?'
   end

  elseif partnerstate == 'roomchanging' then
   partnermsg='\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerprevroomid=partnerroomid
    partnerroomid=partnerobj.leadsto
    partnerobj=nil

    local _curroom=rooms[partnerroomid]
    for _obj in all(_curroom.objs) do
     if _obj.leadsto == partnerprevroomid then
      debug(_obj.typ) -- note: hard reproduce crash here
      partnerxoff=_obj.camcoords.xoff
      partneryoff=_obj.camcoords.yoff
      break
     end
    end

    partnerstate='idling'
    partnermsg='in next room, what now?'
   end

  elseif partnerstate == 'hacking' then
   partnermsg='hacking\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerstate='hacking_ready'
   end

  elseif partnerstate == 'hacking_ready' then
   partnermsg='ready to send data\014\x90\015'

  elseif partnerstate == 'hacking_sending' then
   partnermsg='sending data\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    add(loot,partnerobj.loot)
    partnerobj.loot=nil
    partnerstate='idling'
    partnermsg='sent! what\'s next?'
   end

  elseif partnerstate == 'escaping' then
   partnermsg='breaking window\014\x90\015'
   if partnerobj.isbroken == nil then
    partnerobj.isbroken=true
    partnerobj.camcoords.sx+=11
   end
   partnerc-=1

   if partnerc <= 0 then
    partnerroomid=nil
    partnerstate='escaped'
    partnerc=100
    partnermsg='i made it out!'
   end

  elseif partnerstate == 'prehiding' then
   partnermsg='i\'m squeezing in\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerstate='hiding'
    partnermsg='ok, i\'m in hiding'
   end

  elseif partnerstate == 'unhiding' then
   partnermsg='phew\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerstate='idling'
    partnermsg='next move'
   end

  elseif partnerstate == 'escaped' then
   
  end
 end

 -- update computerlog
 while #computerlog > 6 do
  deli(computerlog,7)
 end

 -- check for game over
 if sirenc == nil and computertraced >= computertracedmax then
  sirenc=time()
 end

end


function _draw()
 cls(0)
 if sirenc != nil then
  cls(8)
  if flr(sirenc - time()) % 2 == 1 then
   cls(12)
  end
 end

 -- draw screen -1
 local _menux,_menuy,_rowoff=-112,62,7

 rectfill(-124,12,-5,94,9)
 rectfill(-121,12,-8,90,5)

 rectfill(-116,4,-13,94,9)
 rectfill(-116,7,-13,90,5)

 sspr(8,91,120,37,-124,91)
 sspr(8,92,10,10,-124,4,10,10,false,true)
 sspr(8,92,10,10,-14,4,10,10,true,true)
 rectfill(-114,14,-16,86,1)
 line(-113,59,-17,59,3)

 rectfill(-113,83,-17,85,3)
 if computerstatec > 0 then
  rectfill(-113,83,-17-((computerstatec/900)*98),85,11)
 end

 if computermsg then
  print(computermsg,_menux,76,3)
 else

  if seloffsets[-1] > 0 then
   spr(176,-22,62)
  end

  if #menus[-1]-seloffsets[-1] > 3 then
   spr(160,-22,78)
  end

  for _i=1,3 do
   local _item=menus[-1][_i+seloffsets[-1]]
   if _item then
    local _y=_menuy+(_i-1)*_rowoff
    local _str=_item.str
    local _isselected=_i == cursels[-1]-seloffsets[-1]
    if _isselected and flr(time()*4) % 2 == 0 then
     _str=_item.str..'\014\x80\015'
    end
    print(_str,_menux,_y,_isselected and 11 or 3)
   end
  end
 end

 for _i=1,#computerlog do
  print(computerlog[_i],_menux,52-(_i-1)*7,3)
 end

 -- draw screen 0

 -- draw blueprint
 rectfill(1,1,126,85,15)

 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   local _x=4+_room.x
   local _y=4+_room.y
   local _x2=_x+_room.w
   local _y2=_y+_room.h

   rect(_x,_y,_x2,_y2,12)
  end
 end

 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   local _x=4+_room.x
   local _y=4+_room.y

   for _j=1,8 do
    local _obj=_room.objs[_j]
    local _mapcoords=_obj.mapcoords

    if _obj.located and _obj.loot then
     sspr(24,0,3,6,_x+11,_y+9)

    elseif _obj.typ == 'camera' then
     print(_obj.id,_x+_obj.mapxoff,_y+_obj.mapyoff,12)

    elseif _mapcoords then
     sspr(
        _mapcoords.sx,
        _mapcoords.sy,
        _mapcoords.sw,
        _mapcoords.sh,
        _x+_mapcoords.xoff,
        _y+_mapcoords.yoff,
        _mapcoords.sw,
        _mapcoords.sh,
        _mapcoords.flipx)
    end
   end
  end
 end

 -- debug draw partner in blueprint
 if _debug then
  print(partnerroomid,0,0,10)
  pset(4+rooms[partnerroomid].x+partnerxoff,4+rooms[partnerroomid].y+partneryoff,10)
 end

 -- draw menus[0]
 rectfill(3,88,124,126,7)
 line(2,89,2,125,7)
 line(125,89,125,125,7)

 -- draw partnermsg
 print(partnermsg,5,90,5)

 -- draw options
 _menux,_menuy,_rowoff=5,99,7

 if seloffsets[0] > 0 then
  spr(144,120,99)
 end

 if #menus[0]-seloffsets[0] > 4 then
  spr(128,120,123)
 end

 for _i=1,4 do
  local _item=menus[0][_i+seloffsets[0]]
  if _item then
   local _y=_menuy+(_i-1)*_rowoff
   print(_item.str,_menux,_y,_i == cursels[0]-seloffsets[0] and 12 or 15)
  end
 end

 if partnerstate == 'escaped' and partnerc <= 0 then
  print('level done!',10,10,6)
 end

 -- draw screen 1
 sspr(8,67,120,24,131,104)

 local _camcount=0

 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   local _camid,_cam,_cami=nil,nil,nil
   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]
    if _obj and _obj.typ == 'camera' then
     _camid=_obj.id-1
     _cami=_j
     _cam=_obj
     _camcount+=1
    end
   end
   if _cam == nil then
    goto continuedrawnextroom
   end

   local _x=127+3+flr(_camid/3)*42
   local _y=2+(_camid%3)*34

   if _cam.ison then
    rectfill(_x,_y,_x+37,_y+30,_room.islit and 9 or 0)
    rectfill(_x+4,_y+7,_x+33,_y+30,_room.islit and 2 or 4)

    for _j=1,#_room.objs do
     local _obj=_room.objs[_j]
     if _obj then
      local _camcoords=_obj.camcoords
      if _camcoords then
       sspr(
        _camcoords.sx,
        _room.islit and _camcoords.sy or _camcoords.sy+_camcoords.sh,
        _camcoords.sw,
        _camcoords.sh,
        _x+_camcoords.xoff,
        _y+_camcoords.yoff,
        _camcoords.sw,
        _camcoords.sh,
        _camcoords.flipx)
      end
     end
    end

    if _room.id == partnerroomid then
     local _px=_x+partnerxoff
     local _py=_y+partneryoff

     sspr(7,_room.islit and 45 or 56,7,11,_px,_py)

     if _debug then
      rect(_x-127,_y,_x+37-127,_y+30,_room.islit and 2 or 4)
      sspr(7,_room.islit and 45 or 56,7,11,_px-127,_py)
     end
    end

   else
    palt(0,true)
    if flr(time()*10) % 2 == 0 then
     fillp(0b101101001011010)
    else
     fillp(0b1010010110100101)
    end
    rectfill(_x,_y,_x+37,_y+30,0x56)
    palt(0,false)
    fillp()
   end

   if _camid+1 == cursels[1] then
    sspr(0,119,7,9,_x+31,_y+0)
   end
   rectfill(_x+33,_y+2,_x+35,_y+6,0)
   print(_camid+1,_x+33,_y+2,_camid+1 == cursels[1] and 10 or 7)
  end

  ::continuedrawnextroom::
 end

 for _i=_camcount,9 do
  local _x=127+3+flr(_i/3)*42
  local _y=2+(_i%3)*34
  rectfill(_x,_y,_x+37,_y+30,1)
 end

 if menus[1][cursels[1]].ison then
  rectfill(127+26,112,127+28,114,10)
 end

end


-- the paper
dot='\014\x2e\015'
papertitle1='game over'
papertitle2='burglars!'
_article1pt2='\f9law enforcements says one\nshowed their \f2lit up face on\ncamera\f9, and the rest was\nsteady detective work to\nlocate their hideout'..dot
paperarticle1='\f9a burglar band responsible\nfor at least \f2'..tostr(17)..'\f9 hack heists\nhas finally been caught'..dot..'\n\n'.._article1pt2
paperarticle2='\fdofficials says this band did\nnot outperform the all-time\nrecord of '..tostr(100)..' consequtive\nhack heists last fall'..dot

function initpaper()
 camera(0,-128)
 local _camendy=-128
 _update60=function()
   -- update camera
  if abs(_camendy) > 0 then
   _camendy-=_camendy/8
   camera(0,_camendy)
  end

  if btnp(4) or btnp(5) then
   camera(0,0)
   -- initheist()
  end
 end
 _draw=function()
  cls(0)
  rectfill(4,5,122,127,6)

  line(123,8,123,127,5)
  line(124,10,124,127,5)
  line(125,12,125,127,5)

  rectfill(6,7,7,8,13)
  rectfill(9,7,16,8,13)
  rectfill(101,7,106,8,13)
  rectfill(108,7,115,8,13)
  rectfill(117,7,120,8,13)

  print('\fdthe',38,9)
  sspr(0,36,35,9,50,9)

  line(6,20,120,20,13)

  print('\^w\f9'..papertitle1,62-#papertitle1*8/2,24)
  print('\^w\f9'..papertitle2,62-#papertitle2*8/2,31)

  print(paperarticle1,8,40)

  line(6,97,120,97,13)

  print(paperarticle2,8,102)
 end
end

-- _init=initpaper

__gfx__
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0edeeeeeee0e4eeeeeee0e4eeeeeee0eeeeeeeeee0eeeeeeeee000000000000
eedddddeee0eed0dddeee0eeeeeeeeee0eeeeeeeeee0eddddeeeee0ed444eeeee0eddeeeeee0e44eeeeee0e44eeeeee0ee777777ee0ee777777e000000000000
eedddddeee0eedd0d0eee0edeeeeeeee0edeeeeeeee0eddddeeeee0edd44eeeee0ed6deeeee0e444eeeee0e444eeeee0ee799997ee0ee799997e000000000000
eedddddeee0eedd000eee0eddeeeeeee0eddeeeeeee0eddddeeeee0edd44eeeee0edddeeeee0e444eeeee0e444eeeee0ee799997ee0667999976000000000000
ee22222eee0eed2222eee0eddeeeeeee0e00eeeeeee0eddd6eeeee0edd44eeeee0edddeeeee0e444eeeee0e444eeeee066799997660667777776000000000000
eeeeeeeeee0eeeeeeeeee0eddeeeeeee0ed0eeedeee0eddddeeeee0ed644eeeee0edddeeeee0eddddeeee0ed44eeeee066777777660667676776000000000000
eeeeeeeeee0eeeeeeeeee0eddeeeeeee0e00eeeeeee0eddddeeeee0edd44eeeee0eeddeeeee0eedd6deee0eed4eeeee066767677660667767676000000000000
eeeeeeeeee0eeeeedeeee0eddeeeeeee0e0deedeede0eeeeeeeeee0eedeeeeeee0eeedeeeee0eeeddddee0eeedeeeee066776767660667777776000000000000
eeeeeeeeee0eddeeedeee0eedeeeeeee0ee0eedeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeee0eeeeeeeee0eeeeeeeee066777777660edeeeeeed000000000000
eeeeeeeeee0eeeedeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeee0eeeeeeeee0eeeeeeeee0deeeeeeeed0eedeeeeed000000000000
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9eeeeeee0e4eeeeeee0e4eeeeeee0deeeeeeeed0eeeeeeeee000000000000
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e99eeeeee0e44eeeeee0e44eeeeee0deeeeeeeed0eedddddde000000000000
eeeeeeeeee0eeeeeeeeee0e9eeeeeeee0e9eeeeeeee0eeeeeeeeee0eeeeeeeeee0e9d9eeeee0e444eeeee0e444eeeee0eeeeeeeeee0eed4444de000000000000
ee99999eee0ee90999eee0e99eeeeeee0e99eeeeeee0e9999eeeee0e9444eeeee0e999eeeee0e444eeeee0e444eeeee0eeddddddee099d4444d9000000000000
ee99999eee0ee99090eee0e99eeeeeee0e44eeeeeee0e9999eeeee0e9944eeeee0e999eeeee0e444eeeee0e444eeeee0eed4444dee099dddddd9000000000000
ee99999eee0ee99000eee0e99eeeeeee0e94eee9eee0e9999eeeee0e9944eeeee0e999eeeee0e9999eeee0e944eeeee0eed4444dee099d9d9dd9000000000000
ee44444eee0ee94444eee0e99eeeeeee0e44eeeeeee0e999deeeee0e9944eeeee0ee99eeeee0ee99d9eee0ee94eeeee099d4444d99099dd9d9d9000000000000
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e49ee9ee9e0e9999eeeee0e9d44eeeee0eee9eeeee0eee9999ee0eee9eeeee099dddddd99099dddddd9000000000000
eeeeeeeeee0eeeeeeeeee0ee9eeeeeee0ee4ee9eeee0e9999eeeee0e9944eeeee0eeeeeeeee0eeeeeeee90eeeeeeee9099d9d9dd990edeeeeeed000000000000
eeeeeeeeee0eeeee9eeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0ee9eeeeeee0eeeeeeeee0eeeeeee990eeeeeee99099dd9d9d990eedeeeeed000000000000
eeeeeeeeee0e99eee9eee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9eeeeeee0edeeee9990edeeee999099dddddd990eeeeeeeee000000000000
eeeeeeeeee0eeee9eeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e99eeeeee0eddee99990eddee99990deeeeeeeed0eedddddde000000000000
eeeeeeeeee0eeeeeeeeee0e9eeeeeeee0e9eeeeeeee0eeeeeeeeee0eeeeeeeeee0e9d9eeeee0eddd999990eddd999990deeeeeeeed0eed4444de000000000000
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e99eeeeeee0eeeeeeeeee0eeeeeeeeee0e999eeeee0eddd999990eddd999990deeeeeeeed099d4444d9000000000000
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e44eeeeeee0eeeeeeeeee0eeeeeeeeee0e999eeeee0eddd999990eddd999990eeeeeeeeee099dddddd9000000000000
ee99999eee0ee90999eee0e99eeeeeee0e94eee9eee0e9999eeeee0e9dddeeeee0e999eeeee0e444499990e9dd999990eeddddddee099d9d9dd9000000000000
ee99999eee0ee99090eee0e99eeeeeee0e44eeeeeee0e9999eeeee0e99ddeeeee0ee99eeeee0ee44949990ee9d999990eed4444dee099dd9d9d9000000000000
ee99999eee0ee99000eee0e99eeeeeee0e49ee9ee9e0e9999eeeee0e99ddeeeee0eee9eeeee0eee4444990eee9eeeee0eed4444dee099dddddd9000000000000
ee44444eee0ee94444eee0ee9eeeeeee0ee4ee9eeee0e999deeeee0e99ddeeeee000000000000000000000000000000099d4444d990edeeeeeed000000000000
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9999eeeee0e9dddeeeee000000000000000000000000000000099dddddd990eedeeeeed000000000000
eeeeeeeeee0eeeeeeeeee00000000000000000000000e9999eeeee0e99ddeeeee000000000000000000000000000000099d9d9dd990000000000000000000000
eeeeeeeeee0eeeee9eeee00000000000000000000000eeeeeeeeee0ee9999eeee000000000000000000000000000000099dd9d9d990000000000000000000000
eeeeeeeeee0e99eee9eee00000000000000000000000eeeeeeeeee0eee9999eee000000000000000000000000000000099dddddd990000000000000000000000
eeeeeeeeee0eeee9eeeee00000000000000000000000eeeeeeeeee0eee99999ee0000000000000000000000000000000deeeeeeeed0000000000000000000000
eeeeeeeeee0eeeeeeeeee00000000000000000000000eeeeeeeeee0eee999999e0000000000000000000000000000000deeeeeeeed0000000000000000000000
eeeeeeeeee0eeeeeeeeee00000000000000000000000eeeeeeeeee0eee99999990000000000000000000000000000000deeeeeeeed0000000000000000000000
ddddd6666d6666ddddd66dddddd6ddddd66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd66d66d6d6666dd66d66dd66d66dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd66d66d6d6666dd66d66dd66666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd66d6dd66d666dd66d66dd6d666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dddd66dd66d666dddd666dddd666dddd66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666ddddd666dd66666dd6d666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666dd66d666dd66666dd66666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666dd66d666dd66666dd66d66dd66d600000000eedeeeeeedeeeeeedeeeee000000000000000000000000000000000000000000000000000000000000000
ddd666ddd6ddd6ddd6666dddddd6ddd66dd00000000eeddeeeeeddeeeeeddeeee000000000000000000000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0ee7eeeeee7eeeeee7eeeee000000000000000000000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeee7e7ee0ee7eeeeee7eeeeee7eeeee000000000000000000000000000000000000000000000000000000000000000
0000000eeedeeeeeedeeeeeedeeeeeeeeeeeededee0edddeeeedddeeeeddde00e000000000000000000000000000000000000000000000000000000000000000
0000000eee7eeeeee7eeeeee7eeeeeedeeeeedddee0dddddeedddddeeddddd7ee000000000000000000000000000000000000000000000000000000000000000
0000000eedddeeeedddeeeedddeeeed7deeeed7dee0d7667eed766e7ed766eeee000000000000000000000000000000000000000000000000000000000000000
0000000edddddeedddddeeedddeeeedddeeeedddee0edddeeeedddeeeedddeeee000000000000000000000000000000000000000000000000000000000000000
0000000ed7d7de7edd7deeeddddeee7d7eeeedddee0ededeeeededeeeededeeee000000000000000000000000000000000000000000000000000000000000000
0000000eedddeeeedddeeeedddeeeedddeeeedddee0ededeeeddedeeeededeeee000000000000000000000000000000000000000000000000000000000000000
0000000eededeeeededeeeededeeeededeeeededee0ededeeeeeedeeeededeeee000000000000000000000000000000000000000000000000000000000000000
0000000eededeeeddedeeeededeeeeeeeeeeededee0eeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000
0000000eededeeeeeedeeeededeeeeeeeeeeededee0ee9eeeeee9eeeeee9eeeee000000000000000000000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0ee99eeeee99eeeee99eeee000000000000000000000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeededee0eedeeeeeedeeeeeedeeeee000000000000000000000000000000000000000000000000000000000000000
0000000eee9eeeeee9eeeeee9eeeeee9eeeee9e9ee0eedeeeeeedeeeeeedeeeee000000000000000000000000000000000000000000000000000000000000000
0000000eeedeeeeeedeeeeeedeeeee9d9eeee999ee0e999eeee999eeee999e00e000000000000000000000000000000000000000000000000000000000000000
0000000ee999eeee999eeee999eeee999eeee9d9ee099999d799999eee9999dee000000000000000000000000000000000000000000000000000000000000000
0000000e99999ee99999eee999eeeed9deeee999ee09d99eee9d99ed7e999d7ee000000000000000000000000000000000000000000000000000000000000000
0000000e9d9d9ede99d9eee9999eee999eeee999ee0e999eeee999eeee999eeee000000000000000000000000000000000000000000000000000000000000000
0000000ee999eeee999eeee999eeee9e9eeee999ee0e9e9eeee9e9eeee9e9eeee000000000000000000000000000000000000000000000000000000000000000
66666eeee9e9eeee9e9eeee9e9eeeeeeeeeee9e9ee0e9e9eee99e9eeee9e9eeee000000000000000000000000000000000000000000000000000000000000000
e666eeeee9e9eee99e9eeee9e9eeeeeeeeeee9e9ee0e9e9eeeeee9eeee9e9eeee000000000000000000000000000000000000000000000000000000000000000
ee6eeeeee9e9eeeeee9eeee9e9eeeeeeeeeee9e9ee0eeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeee4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444eeee
eeeeeeeeee44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444ee
eeeeeeeee4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444e
eeeeeeeee4444449999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444444e
eeeeeeee444449999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999944444
ee6eeeee444499999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994444
e666eeee444499999444444444999999999994444444444444444444444444444444444444444444444444444444444444444444444444444444444999994444
66666eee444999994444444444499444449944999449944994499494449994444449949994999444444994994444944994999499944444999994444499999444
eeeeeeee444999994449999944499455549944494494949444944494449444444494449494999444449494949449449494944494444449944499444499999444
eeeeeeee444999994499949994499455549944494494949444944494449944444494449994949444449494949449449494994499444449949499444499999444
eeeeeeee444999994499444994499455549944494494949494949494449444444494449494949444449494949449449494944494444449944499444499999444
eeeeeeee444999994499444994499444449944494499449994999499949994444449949494949444449944949494449944944494444444999994444499999444
eeeeeeee444999994449999944499999999994444444444444444444444444444444444444444444444444444444444444444444444444444444444999999444
33333eee444999994444444444499999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444
e333eeee444999994444444444499999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444
ee3eeeee444999994449999944499999999994444444444444444444444444444444444444444444444444444444444444444499994444444444444999999444
eeeeeeee444999994499444994499999999944994499949494999444444994499494449494999499444444444444444999994449944494499494944499999444
eeeeeeee444999994499444994499999999944949494449494494444449444949494449494999494944444444444449949499449944494944494944499999444
eeeeeeee444999994499949994499999999944949499444944494444449444949494449494949494944444444444449994999449944494944499944499999444
eeeeeeee444999994449999944499999999944949494449494494444449444949494449494949494944444444444449949499449944494944494944499999444
eeeeeeee444999994444444444499999999944949499949494494444444994994499944994949494944444444444444999994449944494499494944499999444
ee3eeeee444999999444444444999999999994444444444444444444444444444444444444444444444444444444444444444499994444444444444999999444
e333eeee444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444
33333eee444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444
eeeeeeee999555555599999999999555555555555555555555555555555555555555555555555555555555555555555555555555555555999999555555555999
eeeeeeee999555555595995595959555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555555999
eeeeeeee999555555595959995959555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555555999
eeeeeeee99955555559595999555955555555555555555555555555555555555555555555555555555555555555555555555555555555955bb55955555555999
eeeeeeee999955555595995595959555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555559999
eeeeeeee999955555599999999999555555555555555555555555555555555555555555555555555555555555555555555555555555555999999555555559999
ceeeeeee999995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555599999
fceeeeeee9999995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999999e
feceeeeee9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999e
feeceeeeee99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999ee
feeeceeeeeee9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999eeee
feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeee
feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44444444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444444444444444444444444444444444444444444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeceeeeee9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999e
eeeceeee999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
eeeeceee999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
ccceeeee999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999
eceeee7e999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999
eceee777999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999
eceee77e999555599999999999999999999999999999999999999999999999955559999999999955559999999999999999999999999999955555999999555999
eceeee77999555955555555555555555555555555555555555555555555555595559599559595955595555555555555555555555555555595559555555955999
eceee77799955595555555555555555555555555555555555555555555555559555959599959595559555555555555555555559555bb55595559555555955999
ccceee7e99955595555555555555555555555555555555555555555555555559555959599955595559555555555555555555559555555559555955bb55955999
ceeeeece999555955555555555555559999999999999995555555555555555595559599559595955595555555555555555555595555555595559555555955999
ccccccce999555955599999999999999999999999999999999999999999955595559999999999955595555555555555555555595559955595555999999555999
ceeeeece999555955555555555555559999999999999995555555555555555595555555555555555595555555555555555555595595595595555555555555999
eeaaaeee999555955555555555555555555555555555555999999555555555595555555555555555595555555555555555555595959959595555999999555999
ea000aee999555955555555555555555555555555555555955559555555555595555555555555555595555555555555555555595959959595559555555955999
a00000ae99955595555555555555bb55555555555555555999999555555555595555995555599555595555555555555555555595595595595559555555955999
a00000ae999555955555555555555555555555555555555555555555555555595559999555999955595555555555555555555595559955595559555555955999
a00000ae999555955555555555555555555555555555555555555555555555595559999555999955595555555555555555555555555555595559555555955999
a00000ae999555599999999999999999999999999999999999999999999999955555995555599555559999999999999999999999999999955555999999555999
a00000ae999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999
ea000aee999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999
eeaaaeee499555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555994
