pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

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

function dist(x1,y1,x2,y2)
 local dx,dy=(x2-x1)*0.1,(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end


-- create rooms

rooms={
 {
  x=0,y=0,
  w=24,h=48,
  objs={
   { -- west
    {},
    {},
   },
   { -- north
    { typ='camera', id=1, xoff=12, yoff=2 },
    {},
   },
   { -- east
    { typ='door', leadsto=2, relative='to the left', xoff=24, yoff=6 },
    {},
   },
   { -- south
    { typ='window', xoff=14, yoff=47 },
    {},
   },
  },
 },
 {
  x=24,y=0,
  w=24,h=24,
  objs={
   { -- west
    { typ='door', leadsto=1, relative='at the back', xoff=0, yoff=6 },
    {},
   },
   { -- north
    {},
    { typ='window', xoff=4, yoff=-1 },
   },
   { -- east
    { typ='camera', id=2, xoff=20, yoff=10 },
    {},
   },
   { -- south
    { typ='door', leadsto=3, relative='to the left', xoff=6, yoff=24 },
    {},
   },
  },
 },
 {
  x=24,y=24,
  w=24,h=24,
  objs={
   { -- west
    { typ='computer', loot={ 'cute cat pictures', worth=5 }, xoff=2, yoff=3 },
    {},
   },
   { -- north
    { typ='door', leadsto=2, relative='to the right', xoff=6, yoff=0 },
    {},
   },
   { -- east
    -- { typ='window', xoff=23, yoff=3 },
    -- { typ='window', xoff=23, yoff=15 },
    {},
    { typ='camera', id=3, xoff=20, yoff=10 },
   },
   { -- south
    {},
    {},
   },
  },
 },
}


partner={
 room=1,
 lastroom=1,
 xoff=5,
 yoff=10,
 c=0,
 state='idling',
}

msgstr='ok, i\'m in! what now?'


function _init()
 rooms={}

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
   objs={{},{},{},{},{},{},{},{},},
  }
 end

 local _stepcount=20
 local _x=flrrnd(5)
 local _y=flrrnd(3)

 partner.room=_x+_y*5

 local _dirs={-1,1}
 local _i=1
 while _i <= _stepcount do
  ::continue::
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

  for _j=1,8 do
   if _curroom.objs[_j].typ == 'door' then
    _doorcount+=1
   end
   if _nextroom and _nextroom.objs[_j].typ == 'door' then
    _doorcountnext+=1
   end

   if _doorcount > 3 or _doorcountnext > 3 then
    _i+=1
    goto continue
   end
  end

  if _nextx < 5 and _nextx >= 0 and _nexty < 3 and _nexty >= 0 then
   if _nexty - _y == 1 then -- down
    _curroom.objs[7]={ typ='door', leadsto=_nextroom.id, xoff=4, yoff=25 }
    _nextroom.objs[3]={ typ='door', leadsto=_curroom.id, xoff=4, yoff=0 }
   elseif _nexty - _y == -1 then -- up
    _curroom.objs[3]={ typ='door', leadsto=_nextroom.id, xoff=4, yoff=0 }
    _nextroom.objs[7]={ typ='door', leadsto=_curroom.id, xoff=4, yoff=25 }
   elseif _nextx - _x == 1 then -- right
    _curroom.objs[5]={ typ='door', leadsto=_nextroom.id, xoff=24, yoff=4 }
    _nextroom.objs[1]={ typ='door', leadsto=_curroom.id, xoff=0, yoff=4 }
   elseif _nextx - _x == -1 then -- left
    _curroom.objs[1]={ typ='door', leadsto=_nextroom.id, xoff=0, yoff=4 }
    _nextroom.objs[5]={ typ='door', leadsto=_curroom.id, xoff=24, yoff=4 }
   end

   _x=_nextx
   _y=_nexty
   _i+=1
  end
 end

 -- put camera on doorless wall
 local _camrelstrs={
  [1]={ -- west
   nil, -- west
   nil, -- west
   'go thru door to the left', -- north
   'go thru door to the left', -- north
   'go thru door at the back', -- east
   'go thru door at the back', -- east
   'go thru door to the right', -- south
   'go thru door to the right', -- south
  },
  [3]={ -- north
   'go thru door to the right', -- west
   'go thru door to the right', -- west
   nil, -- north
   nil, -- north
   'go thru door to the left', -- east
   'go thru door to the left', -- east
   'go thru door at the back', -- south
   'go thru door at the back', -- south
  },
  [5]={ -- east
   'go thru door at the back', -- west
   'go thru door at the back', -- west
   'go thru door to the right', -- north
   'go thru door to the right', -- north
   nil, -- east
   nil, -- east
   'go thru door to the left', -- south
   'go thru door to the left', -- south
  },
  [7]={ -- south
   'go thru door to the left', -- west
   'go thru door to the left', -- west
   'go thru door at the back', -- north
   'go thru door at the back', -- north
   'go thru door to the right', -- east
   'go thru door to the right', -- east
   nil, -- south
   nil, -- south
  },
 }

 local _pos={
  [1]={x=2,y=10}, -- west
  [3]={x=8,y=2}, -- north
  [5]={x=20,y=10}, -- east
  [7]={x=8,y=18}, -- south
 }

 local _dirs={1,3,5,7}

 for _i=0,14 do
  local _room=_rooms[_i]
  for _dir in all(_dirs) do
   if _room.objs[_dir].typ != 'door' then
    _room.objs[_dir]={ typ='camera', id=_room.id, xoff=_pos[_dir].x, yoff=_pos[_dir].y }

    -- add string to doors
    for _k=1,8 do
     local _obj=_room.objs[_k]
     if _obj.typ == 'door' then
      _obj.str=_camrelstrs[_dir][_k]
     end
    end

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
    break
   end
  end

  if _hasdoor then
   rooms[_room.id]=_room
  end
 end

 -- add windows
 local _min1window
 for _i=0,14 do
  local _room=rooms[_i]
  if _room and (rnd() > .5 or not _min1window) then
   if _i == 5 or _i == 10 or rooms[_i-1] == nil and _room.objs[1].typ != 'camera' then -- west
    _room.objs[1]={ typ='window', xoff=-1, yoff=8 }
   elseif (_i == 4 or _i == 9 or rooms[_i+1] == nil) and _room.objs[5].typ != 'camera' then -- east
    _room.objs[5]={ typ='window', xoff=23, yoff=8 }
   elseif (_i <= 5 or rooms[_i-5] == nil) and _room.objs[3].typ != 'camera' then  -- north
    _room.objs[3]={ typ='window', xoff=8, yoff=-1 }
   elseif (_i >= 10 or rooms[_i+5] == nil) and _room.objs[7].typ != 'camera' then -- south
    _room.objs[7]={ typ='window', xoff=8, yoff=24 }
   --  _min1window=true
   end
  end
 end

end

cursels={
 [-1]=1,
 [0]=1,
 [1]=1,
}

menus={
 [-1]={},
 [0]={},
 [1]={},
}

screensel=0
camerax=0

function _update60()

 -- create computer menu


 -- create blueprint menu
 menus[0]={}
 local _escapeadded,_hideadded
 local _curroom=rooms[partner.room]
 for _obj in all(_curroom.objs) do
  if _obj.typ == 'window' and not _escapeadded then
   add(menus[0],{
    str='escape thru window',
    f=function()
     partner.obj=_obj
     partner.state='escaping'
     partner.c=120
     partner.ismoving=true
     msgstr='moving...'
    end,
   })
   _escapeadded=true

  elseif _obj.typ == 'door' then
   add(menus[0],{
    str=_obj.str,
    f=function()
     partner.obj=_obj
     partner.state='roomchanging'
     partner.c=60
     partner.ismoving=true
     msgstr='moving...'
    end,
   })

  elseif _obj.typ == 'computer' then

   if _obj.loot and partner.state != 'hacking' then
    add(menus[0],{
     str='hack computer',
     f=function()
      partner.obj=_obj
      partner.state='hacking'
      partner.c=240
      partner.ismoving=true
      msgstr='moving...'
     end,
    })
   end

   if _hideadded == nil and partner.state != 'prehiding' then
    add(menus[0],{
     str='hide!',
     f=function()
      partner.obj=_obj
      partner.state='prehiding'
      partner.c=120
      partner.ismoving=true
      msgstr='moving...'
     end,
    })
   end
  end
 end

 if partner.state == 'hiding' then
  menus[0]={{
   str='it\'s safe to come out',
   f=function()
    msgstr='ok, i\'m coming out'
    partner.state='unhiding'
    partner.c=120
   end,
  }}

 elseif partner.state == 'unhiding' then
  menus[0]={{
   str='hide!',
   f=function()
    partner.obj=_obj
    partner.state='prehiding'
    partner.c=120
   end,
  }}

 elseif partner.state == 'prehiding' and not partner.ismoving then
  menus[0]={}
 elseif partner.state == 'roomchanging' and not partner.ismoving then
  menus[0]={}
 end

 -- create cam menu


 -- input
 if btnp(1) then
  screensel+=1
 elseif btnp(0) then
  screensel-=1
 end
 screensel=mid(-1,screensel,1)

 if btnp(3) then
  cursels[screensel]+=1
 elseif btnp(2) then
  cursels[screensel]-=1
 end

 cursels[screensel]=mid(1,cursels[screensel],#menus[screensel])

 local _opt=menus[screensel][cursels[screensel]]
 if btnp(4) and _opt and _opt.f then
  _opt.f()
 end

 -- update camera
 local _camendx=screensel*128
 if abs(_camendx-camerax) > 0 then
  camerax+=(_camendx-camerax)/4
 end
 camera(camerax,0)

 -- update partner
 if partner.ismoving then
  local _a=atan2(partner.obj.xoff-partner.xoff,partner.obj.yoff-partner.yoff)
  partner.xoff+=cos(_a)*0.1
  partner.yoff+=sin(_a)*0.1
  if dist(partner.xoff,partner.yoff,partner.obj.xoff,partner.obj.yoff) < 2 then
   partner.ismoving=nil
  end

 else
  partner.c-=1

  if partner.state == 'escaping' then
   msgstr='breaking window...'
  elseif partner.state == 'roomchanging' then
   msgstr='...'
  elseif partner.state == 'hacking' then
   msgstr='hacking...'
  elseif partner.state == 'prehiding' then
   msgstr='i\'m squeezing in...'
  elseif partner.state == 'unhiding' then
   msgstr='phew...'
  end

  if partner.c <= 0 then

   if partner.state == 'roomchanging' then
    partner.lastroom=partner.room
    partner.room=partner.obj.leadsto
    local _curroom=rooms[partner.room]
    for _obj in all(_curroom.objs) do
     if _obj.leadsto == partner.lastroom then
      partner.obj=nil
      partner.xoff=_obj.xoff
      partner.yoff=_obj.yoff
     end
    end

    partner.state='idling'
    msgstr='in next room, what now?'

   elseif partner.state == 'hacking' then
    add(partner.loot,partner.obj.loot)
    partner.obj.loot=nil

    msgstr='got the goods!'
    partner.state='idling'

   elseif partner.state == 'escaping' then
    partner.state='escaped'
    partner.c=100
    msgstr='i made it out!'

   elseif partner.state == 'prehiding' then
    partner.state='hiding'
    msgstr='ok, i\'m in hiding'

   elseif partner.state == 'unhiding' then
    partner.state='idling'
    msgstr='next move'

   elseif partner.state == 'escaped' then
    
   end
  end
 end

end

pal(15,140,1) -- light-peach -> true-blue
pal(9,133,1) -- orange -> darker-grey
pal(4,128,1) -- brown -> brownish-black
pal(1,129,1) -- dark-blue -> darker-blue
palt(0,false)
palt(14,true)

function _draw()
 cls(0)

 -- draw screen -1
 rectfill(-124,4,-5,94,9)
 rectfill(-121,7,-8,90,5)
 sspr(0,91,128,37,-128,91)
 sspr(0,91,12,11,-128,4,12,11,false,true)
 sspr(0,91,12,11,-12,4,12,11,true,true)
 rectfill(-115,13,-14,88,1)

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
    local _horiz=-flr(-(_j/2))%2 == 0

    if _obj.worth then
     print('?',_x+_obj.xoff,_y+_obj.yoff,7)

    elseif _obj.typ == 'camera' then
     print(_obj.id,_x+_obj.xoff,_y+_obj.yoff,12)

    elseif _obj.typ == 'window' then
     if _horiz then
      sspr(0,0,7,3,_x+_obj.xoff,_y+_obj.yoff)
     else
      sspr(7,0,3,7,_x+_obj.xoff,_y+_obj.yoff)
     end

    elseif _obj.typ == 'door' then
     if _horiz then
      sspr(15,0,7,5,_x+_obj.xoff,_y+_obj.yoff)
     else
      sspr(10,0,5,7,_x+_obj.xoff,_y+_obj.yoff)
     end
    end
   end
  end
 end

 -- debug draw partner in blueprint
 print(partner.room,0,0,10)
 pset(4+rooms[partner.room].x+partner.xoff,4+rooms[partner.room].y+partner.yoff,10)

 -- draw menus[0]
 rectfill(2,88,125,126,7)
 pset(2,88,0)
 pset(2,126,0)
 pset(125,88,0)
 pset(125,126,0)

 -- draw partner message
 print(msgstr,5,90,5)

 -- draw options
 local _menux,_menuy,_rowoff=5,99,7

 for _i=1,#menus[0] do
  local _item=menus[0][_i]
  local _y=_menuy+(_i-1)*_rowoff
  print(_item.str,_menux,_y,_i == cursels[0] and 12 or 15)
 end

 if partner.state == 'escaped' and partner.c <= 0 then
  print('level done!',10,10,6)
 end

 -- draw screen 1
 sspr(0,67,128,24,128,104)

end

__gfx__
ceeeeeccccceeeecffffffeee7e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccecefceeeeceeeeeee77700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ceeeeececefeceeeeceeeeee77e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ecefeeceeeeceeeeee7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ecefeeeceeeeceeee77700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ecefeeee0000000eee7e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000cccfeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044444eee44444eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000041114eee4aaa4eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeaaaee041114eee4aaa4eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eaeeeae041114eee4aaa4eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeeeeea044444eee44444eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeeeeea0eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeeeeea0eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeeeeea0eeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aeeeeea0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eaeeeae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeaaaee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444400000000
00000044444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444000000
00000444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444400000
00000444444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999944444400000
00004444499999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444440000
00004444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999944440000
00004444999994444444449999999999944444444444444444444444444444444444444444444444444444444444444444444444444444444449999944440000
00004449999944444444444994444499449994499449944994944499944444499499949994444449949944449449949994999444449999944444999994440000
00004449999944499999444994111499444944949494449444944494444444944494949994444494949494494494949444944444499444994444999994440000
00004449999944999499944994111499444944949494449444944499444444944499949494444494949494494494949944994444499494994444999994440000
00004449999944994449944994111499444944949494949494944494444444944494949494444494949494494494949444944444499444994444999994440000
00004449999944994449944994444499444944994499949994999499944444499494949494444499449494944499449444944444449999944444999994440000
00004449999944499999444999999999944444444444444444444444444444444444444444444444444444444444444444444444444444444449999994440000
00004449999944444444444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994440000
00004449999944444444444999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994440000
00004449999944499999444999999999944444444444444444444444444444444444444444444444444444444444444444999944444444444449999994440000
00004449999944994449944999999999449944999494949994444449944994944494949994994444444444444449999944499444944994949444999994440000
00004449999944994449944999999999449494944494944944444494449494944494949994949444444444444499494994499444949444949444999994440000
00004449999944999499944999999999449494994449444944444494449494944494949494949444444444444499949994499444949494999444999994440000
00004449999944499999444999999999449494944494944944444494449494944494949494949444444444444499494994499444949494949444999994440000
00004449999944444444444999999999449494999494944944444449949944999449949494949444444444444449999944499444944994949444999994440000
00004449999994444444449999999999944444444444444444444444444444444444444444444444444444444444444444999944444444444449999994440000
00004449999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994440000
00004449999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994440000
00009995555559999999999955555555555555555555555555555555555555555555555555555555555555555555555555555555555999999555555559990000
00009995555559599559595955555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555559990000
00009995555559595999595955555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555559990000
0000999555555959595955595555555555555555555555555555555555555555555555555555555555555555555555555555555555955bb55955555559990000
00009999555559599559595955555555555555555555555555555555555555555555555555555555555555555555555555555555559555555955555599990000
00009999555559999999999955555555555555555555555555555555555555555555555555555555555555555555555555555555555999999555555599990000
00009999955555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555999990000
00000999999555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555599999900000
00000999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999900000
00000099999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999000000
00000000999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000444444444444444444444444444444444444444444444444444444444400000000000000000000000000000000000
00000000000000000000000000000000000044444444444444444444444444444444444444444444444444444444000000000000000000000000000000000000
00000000000000000000000000000000000004444444444444444444444444444444444444444444444444444440000000000000000000000000000000000000
00000999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999900000
00009999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999990000
00009999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999990000
00009995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559990000
00009995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559990000
00009995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559990000
00009995555999999999999999999999999999999999999999999999999555599999999999555599999999999999999999999999999555559999995559990000
00009995559555555555555555555555555555555555555555555555555955595995595959555955555555555555555555555555555955595555559559990000
000099955595555555555555555555555555555555555555555555555559555959599959595559555555555555555555559555bb555955595555559559990000
000099955595555555555555555555555555555555555555555555555559555959595955595559555555555555555555559555555559555955bb559559990000
00009995559555555555555555599999999999999955555555555555555955595995595959555955555555555555555555955555555955595555559559990000
00009995559555999999999999999999999999999999999999999999555955599999999999555955555555555555555555955599555955559999995559990000
00009995559555555555555555599999999999999955555555555555555955555555555555555955555555555555555555955955955955555555555559990000
00009995559555555555555555555555555555555559999995555555555955555555555555555955555555555555555555959599595955559999995559990000
00009995559555555555555555555555555555555559555595555555555955555555555555555955555555555555555555959599595955595555559559990000
000099955595555555555555bb555555555555555559999995555555555955559955555995555955555555555555555555955955955955595555559559990000
00009995559555555555555555555555555555555555555555555555555955599995559999555955555555555555555555955599555955595555559559990000
00009995559555555555555555555555555555555555555555555555555955599995559999555955555555555555555555555555555955595555559559990000
00009995555999999999999999999999999999999999999999999999999555559955555995555599999999999999999999999999999555559999995559990000
00009995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559990000
00009995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559990000
00004995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559940000