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

window={
 typ='window'
}

-- max mansion total: w: 122, h: 48

-- create rooms

rooms={
 {
  x=0,y=0,
  w=24,h=48,
  walls={
   { -- west
    { typ='camera', id=1 },
    {},
   },
   { -- north
    {},
    clone(window),
   },
   { -- east
    { typ='door', leadsto=2 },
    {},
   },
   { -- south
    clone(window),
    {},
   },
  },
 },
 {
  x=24,y=0,
  w=24,h=24,
  walls={
   { -- west
    { typ='camera', id=2 },
    { typ='door', leadsto=1 },
   },
   { -- north
    {},
    clone(window),
   },
   { -- east
    {},
    {},
   },
   { -- south
    {},
    {},
   },
  },
 },
}



function _update60()
end

pal(15,140,1) -- flesh -> blueprint blue

function _draw()
 cls(1)

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
   local _offsetfactor=_i > 2 and 1 or 0

   for _j=1,2 do
    local _item=_wall[_j]
    local _itemx=_room.w/5+(_room.w/5)*(_j-1)*2
    local _itemy=_room.h/5+(_room.h/5)*(_j-1)*2

    if _item.typ == 'camera' then
     if _horiz then
      print(_item.id,_x+2+(_j-1)*(_room.w-6),_y+2+_offsetfactor*(_room.h-8),12)
     else
      print(_item.id,_x+2+_offsetfactor*(_room.w-6),_y+2+(_j-1)*(_room.h-8),12)
     end

    elseif _item.typ == 'window' then
     if _horiz then
      sspr(0,0,7,3,_x+_itemx,_y-1+(_offsetfactor*_room.h))
     else
      sspr(7,0,3,7,_x-1+(_offsetfactor*_room.w),_y+_itemy)
     end

    elseif _item.typ == 'door' then
     if _horiz then
      sspr(15,0,7,5,_x+_itemx,_y+(_offsetfactor*_room.h))
     else
      sspr(10,0,5,7,_x+(_offsetfactor*_room.w),_y+_itemy)
     end
    end
   end
  end
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
