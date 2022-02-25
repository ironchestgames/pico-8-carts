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

guards={}
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
 isgameover=nil
 partnerroomid=nil
 partnerprevroomid=nil
 partnerwindowid=nil
 partnerxoff=5
 partneryoff=10
 partnerflipx=nil
 partnerc=0
 partnerstate='idling'
 partnerismoving=nil
 partnervisible=true
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

 -- map room w: 24, h: 25
 -- cam room w: 37, h: 30

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
    _nextroom.objs[3]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[3], inward=true }
   elseif _nexty - _y == -1 then -- up
    _curroom.objs[3]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[3] }
    _nextroom.objs[8]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[8], inward=true }
   elseif _nextx - _x == 1 then -- right
    _curroom.objs[6]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[6] }
    _nextroom.objs[1]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[1], inward=true }
   elseif _nextx - _x == -1 then -- left
    _curroom.objs[1]={ typ='door', leadsto=_nextroom.id, mapcoords=_doormapcoords[1] }
    _nextroom.objs[6]={ typ='door', leadsto=_curroom.id, mapcoords=_doormapcoords[6], inward=true }
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

 -- count rooms
 local _roomcount=0
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   _roomcount+=1
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

 -- add computers
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
       loot={ name='cute cat pictures', worth=5 },
       hideinside=true,
      }
      _computercount+=1

      for _k=1,#_room.objs do
       local _window=_room.objs[_k]
       if _window.typ == 'window' then
        _room.objs[_k]={}
        del(windows,_window)
       end
      end

      break
     end
    end
   end

  end
 end

 -- add wardrobes
 local _camoppositespos={
  [1]=5,
  [3]=7,
  [6]=1,
  [8]=3,
 }
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]
    local _oppositei=_camoppositespos[_j]
    if _obj.typ == 'camera' and _room.objs[_oppositei].typ == nil and rnd() < 0.33 then
     _room.objs[_oppositei]={
      typ='wardrobe',
      hideinside=true,
     }
    end
   end
  end
 end

 -- add plants
 for _i=0,14 do
  local _room=rooms[_i]
  if _room then
   for _j=1,#_room.objs do
    local _obj=_room.objs[_j]
    if _obj.typ == nil and rnd() < 0.2 then
     _room.objs[_j]={
      typ='plant',
     }
    end
   end
  end
 end

 -- add cam coords to obj
 local _types2camcoords={
  computer={
   [0]={xoff=28,yoff=19,sx=119,sy=0,sw=9,sh=10,cx=4,cy=11,flipx=true},
   nil,nil,
   {xoff=2,yoff=19,sx=119,sy=0,sw=9,sh=10,cx=6,cy=11},
   {xoff=2,yoff=7,sx=119,sy=0,sw=9,sh=10,cx=6,cy=11},
   {xoff=10,yoff=0,sx=108,sy=0,sw=10,sh=12,cx=6,cy=13},
   {xoff=20,yoff=0,sx=108,sy=0,sw=10,sh=12,cx=6,cy=13},
   {xoff=28,yoff=7,sx=119,sy=0,sw=9,sh=10,cx=4,cy=11,flipx=true},
  },
  window={
   [0]={xoff=28,yoff=19,sx=22,sy=0,sw=10,sh=10,cx=6,cy=8,flipx=true},
   nil,nil,
   {xoff=0,yoff=19,sx=22,sy=0,sw=10,sh=10,cx=5,cy=8},
   {xoff=0,yoff=7,sx=22,sy=0,sw=10,sh=10,cx=5,cy=8},
   {xoff=10,yoff=0,sx=0,sy=0,sw=10,sh=12,cx=4,cy=8},
   {xoff=20,yoff=0,sx=0,sy=0,sw=10,sh=12,cx=4,cy=8},
   {xoff=28,yoff=7,sx=22,sy=0,sw=10,sh=10,cx=6,cy=8,flipx=true},
  },
  door={
   [0]={xoff=29,yoff=19,sx=77,sy=0,sw=9,sh=10,cx=4,cy=8,flipx=true},
   nil,nil,
   {xoff=0,yoff=19,sx=77,sy=0,sw=9,sh=10,cx=5,cy=8},
   {xoff=0,yoff=7,sx=77,sy=0,sw=9,sh=10,cx=5,cy=8},
   {xoff=10,yoff=0,sx=44,sy=0,sw=10,sh=12,cx=4,cy=8},
   {xoff=20,yoff=0,sx=44,sy=0,sw=10,sh=12,cx=4,cy=8},
   {xoff=29,yoff=7,sx=77,sy=0,sw=9,sh=10,cx=4,cy=8,flipx=true},
  },
  wardrobe={
   [5]={xoff=12,yoff=1,sx=116,sy=25,sw=7,sh=9,cx=4,cy=10},
   [6]={xoff=20,yoff=1,sx=116,sy=25,sw=7,sh=9,cx=4,cy=10},
  },
  plant={
   [0]={xoff=30,yoff=18,sx=124,sy=29,sw=4,sh=10,cx=2,cy=11,flipx=true},
   nil,nil,
   {xoff=4,yoff=18,sx=124,sy=29,sw=4,sh=10,cx=2,cy=11},
   {xoff=4,yoff=6,sx=124,sy=29,sw=4,sh=10,cx=2,cy=11},
   {xoff=10,yoff=1,sx=124,sy=49,sw=4,sh=9,cx=2,cy=10},
   {xoff=25,yoff=1,sx=124,sy=49,sw=4,sh=9,cx=2,cy=10},
   {xoff=30,yoff=7,sx=124,sy=29,sw=4,sh=10,cx=2,cy=11,flipx=true},
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

    if _camioffset and _types2camcoords[_obj.typ] then
     local _k=(_j-_camioffset)%8
     debug('camioffsets: '.._k..', _obj.typ: '.._obj.typ)
     _obj.camcoords=clone(_types2camcoords[_obj.typ][_k])
    end
   end
  end
 end

 -- set partner state
 partnerstate='windowsearching'
 partnerwindowid=flrrnd(#windows-1)+1

 -- add guards
 local _guardcount=0
 for _i=0,14 do
  local _room=rooms[_i]
  if _room and (_guardcount == 0 or rnd() < 0.33) then
   add(guards,{
    roomid=_room.id,
    xoff=17,
    yoff=18,
    targetx=17,
    targety=18,
    state='idling',
    c=180,
   })
   _guardcount+=1
  end
  if _guardcount == 1 then
  -- if _guardcount >= _roomcount/2 then
   break
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
 escaping=true,
 prehiding=true,
 roomchanging=true,
 hacking=true,
 hacking_sending=true,
 arrested=true,
 unhiding=true,
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
  local _seeplant
  local _seewardrobe
  local _str='i see '
  local _room=rooms[windows[partnerwindowid].roomid]
  for _obj in all(_room.objs) do
   if _obj.typ == 'door' then
    _doorcount+=1
   elseif _obj.typ == 'computer' then
    _seecomputer=true
   elseif _obj.typ == 'wardrobe' then
    _seewardrobe=true
   elseif _obj.typ == 'plant' then
    _seeplant=true
   end
  end

  if _room.islit then
   _str='room is lit, '
  end

  if _doorcount == 1 then
   partnermsg=_str..'1 door'
  else
   partnermsg=_str.._doorcount..' doors'
  end

  if _seeplant then
   partnermsg=partnermsg..', a plant'
  elseif _seewardrobe then
   partnermsg=partnermsg..', a wardrobe'
  end

  for _g in all(guards) do
   if _g.roomid == _room.id then
    partnermsg='i see a guard'
   end
  end


  add(menus[0],{
   str='break in',
   f=function()
    partnerstate='breaking_in'
    partnerc=120
   end,
  })

  if #windows > 1 then
   add(menus[0],{
    str='check next window',
    f=function()
     partnerstate='windowsearching_sneaking'
     partnerc=100
    end,
   })
  end

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

   elseif _obj.typ == 'wardrobe' or _obj.typ == 'plant' then

    if _hideadded == nil then
     _hideadded=true
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

    if _hideadded == nil then
     _hideadded=true
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
     partnermsg='ok, i\'m out, what\'s next?'
     partnervisible=true
     partnerstate='idling'
     partnerc=0
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

 if (isleveldone or isgameover) and btnp(5) then
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
  local _a=atan2(
    partnerobj.camcoords.xoff+partnerobj.camcoords.cx-partnerxoff,
    partnerobj.camcoords.yoff+partnerobj.camcoords.cy-partneryoff)
  local _dx=cos(_a)*0.1
  partnerflipx=_dx < 0
  partnerxoff+=_dx
  partneryoff+=sin(_a)*0.1

  if dist(
    partnerxoff,
    partneryoff,
    partnerobj.camcoords.xoff+partnerobj.camcoords.cx,
    partnerobj.camcoords.yoff+partnerobj.camcoords.cy) < 2 then
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
      partnerxoff=_obj.camcoords.xoff+_obj.camcoords.cx
      partneryoff=_obj.camcoords.yoff+_obj.camcoords.cy
      break
     end
    end

    partnerstate='idling'

    if _curroom.islit then
     partnermsg='room is lit, is cam off?'
    else
     partnermsg='i\'m in, what now?'
    end
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
      debug('875, '.._obj.typ) -- note: hard reproduce crash here
      partnerxoff=_obj.camcoords.xoff+_obj.camcoords.cx
      partneryoff=_obj.camcoords.yoff+_obj.camcoords.cy
      break
     end
    end

    partnerstate='idling'
    if _curroom.islit then
     partnermsg='room is lit, is cam off?'
    else
     partnermsg='in next room, what now?'
    end
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
    partnerc=150
    partnermsg='i made it out!'
   end

  elseif partnerstate == 'prehiding' then
   partnermsg='i\'m squeezing in\014\x90\015'
   partnerc-=1

   if partnerc <= 0 then
    partnerstate='hiding'
    partnermsg='ok, i\'m in hiding'
    partnervisible=not partnerobj.hideinside
   end

  elseif partnerstate == 'arrested' then
   partnermsg='i\'m caught!'
   isgameover=true

  elseif partnerstate == 'escaped' then
   partnerc-=1
   isleveldone=true

  end
 end

 -- update guards
 for _g in all(guards) do
  _g.flashlightx=_g.xoff+cos(_a)*9*(_g.flipx and -1 or 1)
  _g.flashlighty=_g.yoff-2+sin(_a)*9

  if _g.roomid == partnerroomid and 
     partnerstate != 'hiding' and
     (rooms[partnerroomid].islit or dist(_g.flashlightx,_g.flashlighty,partnerxoff,partneryoff) < 9) then
   if partnerstate != 'arrested' then
    partnerc=240
    partnerstate='arrested'
   end

   partnerismoving=nil
   _g.flashlightx=partnerxoff
   _g.flashlighty=partneryoff
   _g.a=atan2(partnerxoff-_g.xoff,partneryoff-_g.yoff)
   _g.flipx=cos(_g.a) < 0
   _g.ismoving=nil
   _g.state='arresting'
   _g.c=0

  elseif _g.ismoving then
   local _a=atan2(_g.targetx-_g.xoff,_g.targety-_g.yoff)
   local _dx=cos(_a)*0.1
   _g.flipx=_dx < 0
   _g.a=_a
   _g.xoff+=_dx
   _g.yoff+=sin(_a)*0.1

   if dist(_g.xoff,_g.yoff,_g.targetx,_g.targety) < 2 then
    _g.ismoving=nil
   end

  else
   _g.c-=1

   if _g.state == 'idling' then
    if _g.c <= 0 then
     local _curroom=rooms[_g.roomid]
     for _obj in all(_curroom.objs) do
      if _obj.typ == 'door' then
       _g.state='roomchanging'
       _g.c=100
       _g.targetx=_obj.camcoords.xoff+_obj.camcoords.cx
       _g.targety=_obj.camcoords.yoff+_obj.camcoords.cy
       _g.target=_obj
       _g.ismoving=true
      end
     end
    end

   elseif _g.state == 'roomchanging' then
    local _nextroom=rooms[_g.target.leadsto]
    local _nextroomdoor=nil
    for _obj in all(_nextroom.objs) do
     if _obj.leadsto == _g.roomid then
      _nextroomdoor=_obj
     end
    end
    _g.target.isopen=true
    _nextroomdoor.isopen=true

    if _g.c <= 0 then
     debug('1015, '.._nextroomdoor.typ) -- note: hard crash here
     _g.xoff=_nextroomdoor.camcoords.xoff+_nextroomdoor.camcoords.cx
     _g.yoff=_nextroomdoor.camcoords.yoff+_nextroomdoor.camcoords.cy
     _g.roomid=_nextroom.id
     _g.state='idling'
     _g.c=480+flrrnd(8)*60
     _g.ismoving=true
     _g.targetx=20
     _g.targety=22

     _g.target.isopen=nil
     _nextroomdoor.isopen=nil
     _g.target=nil
    end

   elseif _g.state == 'arresting' then
    -- pass
   end

  end
 end

 -- update computerlog
 while #computerlog > 6 do
  deli(computerlog,7)
 end

 -- check for game over
 if computertraced >= computertracedmax then
  isgameover=true 
 end

 if sirenc == nil and isgameover then
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

 rectfill(-115,13,-15,87,15)
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
     sspr(5,110,3,6,_x+11,_y+9)

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

 -- draw screen 1
 rectfill(137,10,245,128,0)
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

   local _guardsinroom={}
   for _g in all(guards) do
    if _room.id == _g.roomid then
     add(_guardsinroom,_g)
    end
   end

   local _x=127+3+flr(_camid/3)*42
   local _y=2+(_camid%3)*34

   if _cam.ison then
    rectfill(_x,_y,_x+37,_y+30,_room.islit and 9 or 0)

    for _g in all(_guardsinroom) do
     if not _room.islit then
      clip(_x-127,_y,37,31)
      circfill(_x+_g.flashlightx,_y+_g.flashlighty,5,4)
      clip()
     end
    end

    rectfill(_x+4,_y+7,_x+33,_y+30,_room.islit and 2 or 4)

    for _g in all(_guardsinroom) do
     if not _room.islit then
      clip(_x-127+4,_y+7,30,24)
      circfill(_x+_g.flashlightx,_y+_g.flashlighty,5,9)
      clip()
     end
    end

    -- draw obj
    for _j=1,#_room.objs do
     local _obj=_room.objs[_j]
     if _obj then
      local _camcoords=_obj.camcoords
      local _framexoff=0
      local _frameyoff=0
      if _camcoords then
       local _islit=_room.islit
       for _g in all(_guardsinroom) do
        if dist(_camcoords.xoff+_camcoords.cx,_camcoords.yoff+_camcoords.cy,_g.flashlightx,_g.flashlighty) < 7 then
         _islit=true
        end
       end

       if not _islit then
        _frameyoff=_camcoords.sh
       end

       -- draw doors
       if _obj.isopen then
        _framexoff=_camcoords.sw+1
        if _obj.inward then
         _framexoff+=_camcoords.sw+1
        end
        if not _islit and rooms[_obj.leadsto].islit then
         _frameyoff+=_camcoords.sh
        end
       end

       sspr(
        _camcoords.sx+_framexoff,
        _camcoords.sy+_frameyoff,
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

    -- draw partner
    if _room.id == partnerroomid and partnervisible then
     local _px=_x+partnerxoff
     local _py=_y+partneryoff
     local _frameoff=0

     if partnerismoving then
      _frameoff=7
      if flr(time()*5) % 2 == 0 then
       _frameoff=14
      end
     elseif partnerstate == 'hiding' then
      _frameoff=28
     elseif partnerstate == 'arrested' then
      _frameoff=35
     elseif partnerstate != 'idling' then
      _frameoff=21
     end

     sspr(7+_frameoff,(_room.islit or partnerstate == 'arrested') and 45 or 56,7,11,_px-3,_py-10,7,11,partnerflipx)
    end

    -- draw guards in room
    for _g in all(guards) do
     if _g.roomid == _room.id then

      local _frameoff=0
      if _g.ismoving then
       _frameoff=8
       if flr(time()*5) % 2 == 0 then
        _frameoff=16
       end
      elseif _g.state == 'arresting' then
       _frameoff=24
      end

      sspr(50+_frameoff,_room.islit and 45 or 56,8,11,_x+_g.xoff-3,_y+_g.yoff-10,8,11,_g.flipx)
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

 -- continue message
 if isgameover or isleveldone then
  local _x=camerax+36
  rectfill(_x-4,0,_x+58,8,0)
  rect(_x-4,0,_x+58,8,10)
  print('\x97 to continue',_x,2,10)
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
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0edeeeeeee0e4eeeeeee0e4eeeeeee0eeeeeeeeee0eeeeeeeee0dddddddeede
eedddddeee0eed0dddeee0eeeeeeeeee0eeeeeeeeee0eddddeeeee0ed444eeeee0eddeeeeee0e44eeeeee0e44eeeeee0ee777777ee0ee777777e0ddddddddede
eedddddeee0eedd0d0eee0edeeeeeeee0edeeeeeeee0eddddeeeee0edd44eeeee0ed6deeeee0e444eeeee0e444eeeee0ee799997ee0ee799997e0d66d66dedee
eedddddeee0eedd000eee0eddeeeeeee0eddeeeeeee0eddddeeeee0edd44eeeee0edddeeeee0e444eeeee0e444eeeee0ee799997ee06679999760d66d66deede
ee22222eee0eed2222eee0eddeeeeeee0e00eeeeeee0eddd6eeeee0edd44eeeee0edddeeeee0e444eeeee0e444eeeee0667999976606677777760d66d66d77d7
eeeeeeeeee0eeeeeeeeee0eddeeeeeee0ed0eeedeee0eddddeeeee0ed644eeeee0edddeeeee0eddddeeee0ed44eeeee0667777776606676767760d66d66d79d7
eeeeeeeeee0eeeeeeeeee0eddeeeeeee0e00eeeeeee0eddddeeeee0edd44eeeee0eeddeeeee0eedd6deee0eed4eeeee0667676776606677676760d67d76d7997
eeeeeeeeee0eeeeedeeee0eddeeeeeee0e0deedeede0eeeeeeeeee0eedeeeeeee0eeedeeeee0eeeddddee0eeedeeeee0667767676606677777760d66d66d7777
eeeeeeeeee0eddeeedeee0eedeeeeeee0ee0eedeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeee0eeeeeeeee0eeeeeeeee066777777660edeeeeeed0d66d66d6666
eeeeeeeeee0eeeedeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeee0eeeeeeeee0eeeeeeeee0deeeeeeeed0eedeeeeed044444446666
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9eeeeeee0e4eeeeeee0e4eeeeeee0deeeeeeeed0eeeeeeeee04444444ee9e
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e99eeeeee0e44eeeeee0e44eeeeee0deeeeeeeed0eedddddde049949949e9e
eeeeeeeeee0eeeeeeeeee0e9eeeeeeee0e9eeeeeeee0eeeeeeeeee0eeeeeeeeee0e9d9eeeee0e444eeeee0e444eeeee0eeeeeeeeee0eed4444de04994994e9ee
ee99999eee0ee90999eee0e99eeeeeee0e99eeeeeee0e9999eeeee0e9444eeeee0e999eeeee0e444eeeee0e444eeeee0eeddddddee099d4444d904994994ee9e
ee99999eee0ee99090eee0e99eeeeeee0e44eeeeeee0e9999eeeee0e9944eeeee0e999eeeee0e444eeeee0e444eeeee0eed4444dee099dddddd904994994dd9d
ee99999eee0ee99000eee0e99eeeeeee0e94eee9eee0e9999eeeee0e9944eeeee0e999eeeee0e9999eeee0e944eeeee0eed4444dee099d9d9dd9049d4d94d49d
ee44444eee0ee94444eee0e99eeeeeee0e44eeeeeee0e999deeeee0e9944eeeee0ee99eeeee0ee99d9eee0ee94eeeee099d4444d99099dd9d9d904994994d44d
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e49ee9ee9e0e9999eeeee0e9d44eeeee0eee9eeeee0eee9999ee0eee9eeeee099dddddd99099dddddd904994994dddd
eeeeeeeeee0eeeeeeeeee0ee9eeeeeee0ee4ee9eeee0e9999eeeee0e9944eeeee0eeeeeeeee0eeeeeeee90eeeeeeee9099d9d9dd990edeeeeeed000000009999
eeeeeeeeee0eeeee9eeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0ee9eeeeeee0eeeeeeeee0eeeeeee990eeeeeee99099dd9d9d990eedeeeeed000000009999
eeeeeeeeee0e99eee9eee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9eeeeeee0edeeee9990edeeee999099dddddd99000000000000000000eede
eeeeeeeeee0eeee9eeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e99eeeeee0eddee99990eddee99990deeeeeeeed000000000000000000dede
eeeeeeeeee0eeeeeeeeee0e9eeeeeeee0e9eeeeeeee0eeeeeeeeee0eeeeeeeeee0e9d9eeeee0eddd999990eddd999990deeeeeeeed000000000000000000edee
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e99eeeeeee0eeeeeeeeee0eeeeeeeeee0e999eeeee0eddd999990eddd999990deeeeeeeed000000000000000000eede
eeeeeeeeee0eeeeeeeeee0e99eeeeeee0e44eeeeeee0eeeeeeeeee0eeeeeeeeee0e999eeeee0eddd999990eddd999990000000000000000000000000000077d7
ee99999eee0ee90999eee0e99eeeeeee0e94eee9eee0e9999eeeee0e9dddeeeee0e999eeeee0e444499990e9dd999990000000000000000000000000000079d7
ee99999eee0ee99090eee0e99eeeeeee0e44eeeeeee0e9999eeeee0e99ddeeeee0ee99eeeee0ee44949990ee9d99999000000000000000000000000000007777
ee99999eee0ee99000eee0e99eeeeeee0e49ee9ee9e0e9999eeeee0e99ddeeeee0eee9eeeee0eee4444990eee9eeeee000000000000000000000000000006666
ee44444eee0ee94444eee0ee9eeeeeee0ee4ee9eeee0e999deeeee0e99ddeeeee000000000000000000000000000000000000000000000000000000000006666
eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0eeeeeeeeee0e9999eeeee0e9dddeeeee00000000000000000000000000000000000000000000000000000000000ee9e
eeeeeeeeee0eeeeeeeeee00000000000000000000000e9999eeeee0e99ddeeeee000000000000000000000000000000000000000000000000000000000009e9e
eeeeeeeeee0eeeee9eeee00000000000000000000000eeeeeeeeee0ee9999eeee00000000000000000000000000000000000000000000000000000000000e9ee
eeeeeeeeee0e99eee9eee00000000000000000000000eeeeeeeeee0eee9999eee00000000000000000000000000000000000000000000000000000000000ee9e
eeeeeeeeee0eeee9eeeee00000000000000000000000eeeeeeeeee0eee99999ee00000000000000000000000000000000000000000000000000000000000dd9d
eeeeeeeeee0eeeeeeeeee00000000000000000000000eeeeeeeeee0eee999999e00000000000000000000000000000000000000000000000000000000000d49d
eeeeeeeeee0eeeeeeeeee00000000000000000000000eeeeeeeeee0eee999999900000000000000000000000000000000000000000000000000000000000dddd
ddddd6666d6666ddddd66dddddd6ddddd66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999
6dd66d66d6d6666dd66d66dd66d66dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999
6dd66d66d6d6666dd66d66dd66666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd66d6dd66d666dd66d66dd6d666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dddd66dd66d666dddd666dddd666dddd66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666ddddd666dd66666dd6d666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666dd66d666dd66666dd66666dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6dd6666dd66d666dd66666dd66d66dd66d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd666ddd6ddd6ddd6666dddddd6ddd66dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeedeeeeeeedeeeeeeedeeeeeeedeeeee000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7e7ee0eeeddeeeeeeddeeeeeeddeeeeeeddeeee000000000000000000000000000000000000000000000
0000000eeedeeeeeedeeeeeedeeeeeedeeeeeeeeeeeededee0eee7eeeeeee7eeeeeee7eeeeeee7eeeee000000000000000000000000000000000000000000000
0000000eee7eeeeee7eeeeee7eeeeee7eeeeeedeeeeedddee0eee7eeeeeee7eeeeeee7eeeeeee7eeeee000000000000000000000000000000000000000000000
0000000eedddeeeedddeeeedddeeeedddeeeed7deeeed7dee0eedddeeeeedddeeeeedddeeeeeddde00e000000000000000000000000000000000000000000000
0000000edddddeedddddeedddddeeedddeeeedddeeeedddee0edddddeeedddddeeedddddeeeddddd7ee000000000000000000000000000000000000000000000
0000000ed7d7deed7dd7e7edd7deeeddddeee7d7eeeedddee0ed7667eeed7667ee7e667deeed766eeee000000000000000000000000000000000000000000000
0000000eedddeeeedddeeeedddeeeedddeeeedddeeeedddee0eedddeeeeedddeeeeedddeeeeedddeeee000000000000000000000000000000000000000000000
0000000eededeeeededeeeeeddeeeededeeeededeeeededee0eededeeeeededeeeeeeddeeeeededeeee000000000000000000000000000000000000000000000
0000000eededeeeddedeeeeedeeeeededeeeeeeeeeeededee0eededeeeeddedeeeeeedeeeeeededeeee000000000000000000000000000000000000000000000
0000000eededeeeeeedeeeeedeeeeededeeeeeeeeeeededee0eededeeeeeeedeeeeeedeeeeeededeeee000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eee9eeeeeee9eeeeeee9eeeeeee9eeeee000000000000000000000000000000000000000000000
0000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeededee0eee99eeeeee99eeeeee99eeeeee99eeee000000000000000000000000000000000000000000000
0000000eee9eeeeee9eeeeee9eeeeee9eeeeee9eeeee9e9ee0eeedeeeeeeedeeeeeeedeeeeeeedeeeee000000000000000000000000000000000000000000000
0000000eeedeeeeeedeeeeeedeeeeeedeeeee9d9eeee999ee0eeedeeeeeeedeeeeeeedeeeeeeedeeeee000000000000000000000000000000000000000000000
0000000ee999eeee999eeee999eeee999eeee999eeee9d9ee0ee999eeeee999eeeee999eeeee999e00e000000000000000000000000000000000000000000000
0000000e99999ee99999ee99999eee999eeeed9deeee999ee0e99999d7e99999eee99999eeee9999dee000000000000000000000000000000000000000000000
0000000e9d9d9ee9d99dede99d9eee9999eee999eeee999ee0e9d99eeee9d99ed7de999ed7ee999d7ee000000000000000000000000000000000000000000000
0000000ee999eeee999eeee999eeee999eeee9e9eeee999ee0ee999eeeee999eeeee999eeeee999eeee000000000000000000000000000000000000000000000
66666eeee9e9eeee9e9eeeee99eeee9e9eeeeeeeeeee9e9ee0ee9e9eeeee9e9eeeeee99eeeee9e9eeee000000000000000000000000000000000000000000000
e666eeeee9e9eee99e9eeeee9eeeee9e9eeeeeeeeeee9e9ee0ee9e9eeee99e9eeeeee9eeeeee9e9eeee000000000000000000000000000000000000000000000
ee6eeeeee9e9eeeeee9eeeee9eeeee9e9eeeeeeeeeee9e9ee0ee9e9eeeeeee9eeeeee9eeeeee9e9eeee000000000000000000000000000000000000000000000
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
eeeeeeee444999994499444994499999999944499449949994949444449494999499949494999499944444444444444444444449944494499494944499999444
eeeeeeee444999994499444994499999999944944494444944949444449494494494449494944494944444444444444444444449944494944494944499999444
eeeeeeee444999994499949994499999999944944494444944949444449494494499449494994499444444444444444444444449944494944499944499999444
eeeeeeee444999994449999944499999999944944494444944999444449994494494449994944494944444444444444444444449944494944494944499999444
eeeeeeee444999994444444444499999999944499449944944494444444944999499949994999494944444444444444444444449944494499494944499999444
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
