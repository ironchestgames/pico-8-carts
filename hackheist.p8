pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
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
  walls={
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
  walls={
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
  walls={
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

function _init()
 local _maxtotw,_maxtoth=122,48
 -- init rooms
 rooms={}

 local _totw,_toth=0,0
 local _prevroom=nil
 local _roomi=1

 while true do
  -- determine room(s) width
  local _roomw=24
  _totw+=_roomw

  -- determine room count
  local _roomcount=1

  -- determine room(s) height 
  local _roomh=24

  -- if mansion would be too big, stop
  if _totw > _maxtotw then
   break
  end

  -- create west
  local _west={{},{}}
  -- create doors to previous column
  if _prevroom then
   _west[1]={ typ='door', leadsto=_prevroom.id, relative='to the right', xoff=2, yoff=6 }
   _prevroom.walls[3][1]={ typ='door', leadsto=_roomi, relative='to the left', xoff=24, yoff=6 }
  end

  -- create north
  local _north={{},{}}

  -- create east
  local _east={{},{}}

  -- create south
  local _south={{},{}}

  -- create door to same column
  -- todo

  -- create camera
  _north[1]={ typ='camera', id=_roomi, xoff=12, yoff=2 }

  -- create windows
  _south[1]={ typ='window', xoff=14, yoff=23 }

  -- create room
  local _room={
   id=_roomi,
   x=_totw-_roomw,
   y=0,
   w=_roomw,
   h=_roomh,
   walls={
    _west,
    _north,
    _east,
    _south,
   },
  }

  rooms[_roomi]=_room

  _roomi+=1
  _prevroom=_room

 end

 -- randomize camera ids

end


partner={
 room=1,
 xoff=5,
 yoff=10,
 c=0,
 state='idling',
}

msgstr='ok, i\'m in! what now?'

cursel=1
menu={}



function _update60()

 -- create menu
 menu={}
 local _escapeadded,_hideadded
 local _curroom=rooms[partner.room]
 for _wall in all(_curroom.walls) do
  for _item in all(_wall) do
   if _item.typ == 'window' and not _escapeadded then
    add(menu,{
     str='escape thru window',
     f=function()
      partner.item=_item
      partner.state='escaping'
      partner.c=120
      partner.ismoving=true
      msgstr='moving...'
     end,
    })
    _escapeadded=true

   elseif _item.typ == 'door' then
    add(menu,{
     str='go thru door '.._item.relative,
     f=function()
      partner.item=_item
      partner.state='roomchanging'
      partner.c=60
      partner.ismoving=true
      msgstr='moving...'
     end,
    })

   elseif _item.typ == 'computer' then

    if _item.loot and partner.state != 'hacking' then
     add(menu,{
      str='hack computer',
      f=function()
       partner.item=_item
       partner.state='hacking'
       partner.c=240
       partner.ismoving=true
       msgstr='moving...'
      end,
     })
    end

    if _hideadded == nil and partner.state != 'prehiding' then
     add(menu,{
      str='hide!',
      f=function()
       partner.item=_item
       partner.state='prehiding'
       partner.c=120
       partner.ismoving=true
       msgstr='moving...'
      end,
     })
    end
   end
  end
 end

 if partner.state == 'hiding' then
  menu={{
   str='it\'s safe to come out',
   f=function()
    msgstr='ok, i\'m coming out'
    partner.state='unhiding'
    partner.c=120
   end,
  }}

 elseif partner.state == 'unhiding' then
  menu={{
   str='hide!',
   f=function()
    partner.item=_item
    partner.state='prehiding'
    partner.c=120
   end,
  }}

 elseif partner.state == 'prehiding' and not partner.ismoving then
  menu={}
 elseif partner.state == 'roomchanging' and not partner.ismoving then
  menu={}
 end

 -- input
 if btnp(3) then
  cursel+=1
 elseif btnp(2) then
  cursel-=1
 end
 cursel=mid(1,cursel,#menu)

 if btnp(4) and menu[cursel] and menu[cursel].f then
  menu[cursel].f()
 end

 -- update partner
 if partner.ismoving then
  local _a=atan2(partner.item.xoff-partner.xoff,partner.item.yoff-partner.yoff)
  partner.xoff+=cos(_a)*0.1
  partner.yoff+=sin(_a)*0.1
  if dist(partner.xoff,partner.yoff,partner.item.xoff,partner.item.yoff) < 2 then
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
    local _oldroom=partner.room
    partner.room=partner.item.leadsto
    local _curroom=rooms[partner.room]
    for _wall in all(_curroom.walls) do
     for _item in all(_wall) do
      if _item.leadsto == _oldroom then
       partner.item=nil
       partner.xoff=_item.xoff
       partner.yoff=_item.yoff
      end
     end
    end

    partner.state='idling'
    msgstr='in next room, what now?'

   elseif partner.state == 'hacking' then
    add(partner.loot,partner.item.loot)
    partner.item.loot=nil

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

pal(15,140,1) -- flesh -> blueprint blue
pal(2,131,1) -- wine -> dark green

function _draw()
 cls(0)

 -- draw blueprint
 rectfill(1,34,126,86,15)

 for _room in all(rooms) do
  local _x=3+_room.x
  local _y=36+_room.y
  local _x2=_x+_room.w
  local _y2=_y+_room.h

  rect(_x,_y,_x2,_y2,12)
 end


 for _room in all(rooms) do
  local _x=3+_room.x
  local _y=36+_room.y

  for _i=1,4 do
   local _wall=_room.walls[_i]
   local _horiz=_i%2 == 0
   -- local _offsetfactor=_i > 2 and 1 or 0

   for _item in all(_wall) do
    if _item.worth then
     print('?',_x+_item.xoff,_y+_item.yoff,7)

    elseif _item.typ == 'camera' then
     print(_item.id,_x+_item.xoff,_y+_item.yoff,12)

    elseif _item.typ == 'window' then
     if _horiz then
      sspr(0,0,7,3,_x+_item.xoff,_y+_item.yoff)
     else
      sspr(7,0,3,7,_x+_item.xoff,_y+_item.yoff)
     end

    elseif _item.typ == 'door' then
     if _horiz then
      sspr(15,0,7,5,_x+_item.xoff,_y+_item.yoff)
     else
      sspr(10,0,5,7,_x+_item.xoff,_y+_item.yoff)
     end
    end

    -- for _j=1,2 do
    -- local _item=_wall[_j]
    -- local _itemx=_room.w/5+(_room.w/5)*(_j-1)*2
    -- local _itemy=_room.h/5+(_room.h/5)*(_j-1)*2

    -- if _item.typ == 'camera' then
    --  if _horiz then
    --   print(_item.id,_x+2+(_j-1)*(_room.w-6),_y+2+_offsetfactor*(_room.h-8),12)
    --  else
    --   print(_item.id,_x+2+_offsetfactor*(_room.w-6),_y+2+(_j-1)*(_room.h-8),12)
    --  end

    -- elseif _item.typ == 'window' then
    --  if _horiz then
    --   sspr(0,0,7,3,_x+_itemx,_y-1+(_offsetfactor*_room.h))
    --  else
    --   sspr(7,0,3,7,_x-1+(_offsetfactor*_room.w),_y+_itemy)
    --  end

    -- elseif _item.typ == 'door' then
    --  if _horiz then
    --   sspr(15,0,7,5,_x+_itemx,_y+(_offsetfactor*_room.h))
    --  else
    --   sspr(10,0,5,7,_x+(_offsetfactor*_room.w),_y+_itemy)
    --  end
    -- end
   end
  end
 end

 -- debug draw partner in blueprint
 print(partner.room,1,1,10)
 pset(3+rooms[partner.room].x+partner.xoff,36+rooms[partner.room].y+partner.yoff,10)

 -- draw menu
 rectfill(2,88,125,126,2)

 -- draw partner message
 print(msgstr,5,90,7)

 -- draw options
 local _menux,_menuy,_rowoff=5,99,7

 for _i=1,#menu do
  local _item=menu[_i]
  local _y=_menuy+(_i-1)*_rowoff
  print(_item.str,_menux,_y,_i == cursel and 11 or 3)
 end

 if partner.state == 'escaped' and partner.c <= 0 then
  print('level done!',10,10,6)
 end

end

__gfx__
c00000ccccc0000cffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccc0c0fc0000c000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c00000c0c0f0c0000c00000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c0f00c0000c0000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c0f000c0000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c0f000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000cccf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
