pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function clone(_t)
 local _tc={}
 for _k,_v in pairs(_t) do
  _tc[_k]=_v
 end
 return _tc
end

function concat(_t1,_t2)
 local _t={}
 for _v in all(_t1) do
  add(_t,_v)
 end
 for _v in all(_t2) do
  add(_t,_v)
 end
 return _t
end

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*0.1
 local dy=(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

function perfselect(_cur,_items)
 local _closestd=999
 local _closest=nil
 for _item in all(_items) do
  if _item != _cur then
   local _a=atan2(_item.x-_cur.x,_item.y-_cur.y)%1
   local _d=dist(_item.x,_item.y,_cur.x,_cur.y)
   if _d < _closestd and
      -- ((btnp(0) and _a >= 0.3125 and _a <= 0.6875) or -- left
      --  (btnp(1) and (_a >= 0.8125 or _a <= 0.1875)) or -- right
      -- (btnp(3) and _a >= 0.5625 and _a <= 0.9375) or -- down
      --  (btnp(2) and _a >= 0.0625 and _a <= 0.4375)) then -- up
      ((btnp(0) and _a >= 0.375 and _a <= 0.625) or -- left
       (btnp(1) and (_a >= 0.875 or _a <= 0.125)) or -- right
      (btnp(3) and _a >= 0.625 and _a <= 0.875) or -- down
       (btnp(2) and _a >= 0.125 and _a <= 0.375)) then -- up
      -- (btnp(3) and _a >= 0.55 and _a <= 0.95) or -- down
       -- (btnp(2) and _a >= 0.05 and _a <= 0.45)) then -- up
    _closestd=_d
    _closest=_item
   end
  end
 end
 return _closest or _cur
end

function shipgoto(_ship,_target)
 _ship.targetx=_target.x
 _ship.targety=_target.y
 _ship.target=_target
end

planets={
 {
  x=8+flr(rnd(14))*8,y=8+flr(rnd(14))*8,
 },
 {
  x=8+flr(rnd(14))*8,y=8+flr(rnd(14))*8,
 },
 {
  x=8+flr(rnd(14))*8,y=8+flr(rnd(14))*8,
 },
 {
  x=8+flr(rnd(14))*8,y=8+flr(rnd(14))*8,
 },
}

for _p in all(planets) do
 _p.isplanet=true
end


function getitems1(_pl)
 _pl.sel2=nil
 local _items={}

 -- add player ships
 for _ship in all(_pl.ships) do
  _ship.text=nil
  _ship.action=function()
   _pl.curlevel=2
  end
 end
 _items=clone(_pl.ships)

 -- add player planets
 for _planet in all(planets) do
  if _planet.owner == _pl.owner then
   _planet.text='build'
   _planet.action=function()
    _pl.curlevel=2
   end
   add(_items,_planet)
  end
 end

 if not _pl.sel1 then
  _pl.sel1=_items[1]
 end

 return _items
end

local shiptypeoffsets={
 {x=-11,y=-11},
 {x=11,y=-11},
 {x=-11,y=11},
 {x=11,y=11},
}

function getitems2(_pl)
 local _items={}

 -- add shiptypes
 if _pl.sel1.isplanet then
  local _planet=_pl.sel1
  for _i=1,#_pl.shiptypes do
   local _offset=shiptypeoffsets[_i]
   local _shiptype=_pl.shiptypes[_i]
   local _item={
    x=_planet.x+_offset.x,
    y=_planet.y+_offset.y,
    sprite=_shiptype.sprite,
    text=_shiptype.name,
    action=function()
     _planet.orders=_shiptype.name
     _planet.duration=_shiptype.duration
     _planet.c=0
     _pl.curlevel=1
    end
   }
   if _pl.sel2 and _pl.sel2.x == _item.x and _pl.sel2.y == _item.y then
    _pl.sel2=_item
   end
   add(_items,_item)
  end

 else
  -- add this ship for toggle free move
  _pl.sel1.text='toggle free move'
  add(_items,_pl.sel1)

  -- add free/enemy planets
  for _planet in all(planets) do
   _planet.text=nil
   if _planet.owner == _pl.owner then
    _planet.text='go to'
    _planet.action=function()
     shipgoto(_pl.sel1,_planet)
     _pl.sel1.orders=nil
     _pl.curlevel=1
    end
   elseif not _planet.owner then
    _planet.text='colonize'
    _planet.action=function()
     shipgoto(_pl.sel1,_planet)
     _pl.sel1.orders='colonize'
     _pl.curlevel=1
    end
   end
   add(_items,_planet)
  end

  -- add enemy ships

 end

 if not _pl.sel2 then
  _pl.sel2=_items[1]
 end

 return _items
end

players={
 [1]={
  owner=1,
  col=13,
  shiptypes={
   {
    name='fighters',
    sprite=0,
    duration=320,
   },
   {
    name='corvettes',
    sprite=1,
    duration=320,
   },
   {
    name='destroyer',
    sprite=2,
    duration=320,
   },
  },
  ships={},
  curlevel=1,
  sel1=nil,
  getitems1=getitems1,
  sel2=nil,
  getitems2=getitems2,
 }
}

players[1].ships={
 {
  x=rnd(128),y=rnd(128),
 },
 {
  x=rnd(128),y=rnd(128),
 },
}

for _ship in all(players[1].ships) do
 _ship.targetx,_ship.targety=_ship.x,_ship.y
 _ship.spd=0.05
 _ship.owner=players[1].owner
 _ship.name='destroyer'
end

function _update60()

 for _i=1,#players do
  local _player=players[_i]
  local _btnpi=_i-1
  if _player.curlevel == 0 then
   if btnp(4,_btnpi) then
    _player.curlevel=1
   end
  else
  
   local _selkey='sel'.._player.curlevel
   local _items=_player['getitems'.._player.curlevel](_player)
   _player.items=_items

   if btnp(0,_btnpi) or btnp(1,_btnpi) or btnp(2,_btnpi) or btnp(3,_btnpi) then
    _player[_selkey]=perfselect(_player[_selkey],_items)
   elseif btnp(4,_btnpi) then
    _player[_selkey].action()
   elseif btnp(5,_btnpi) then
    _player.curlevel=mid(0,_player.curlevel-1,2)
   end

  end
 end

 -- update planets
 for _planet in all(planets) do
  if _planet.duration then
   _planet.c+=1
   if _planet.c >= _planet.duration then
    -- todo: add ship
   end
  end
 end

 -- move ships
 for _player in all(players) do
  for _ship in all(_player.ships) do
   if dist(_ship.x,_ship.y,_ship.targetx,_ship.targety) < 4 then
    _ship.targetx,_ship.targety=_ship.x,_ship.y
    if _ship.target then
     if _ship.orders == 'colonize' then
      if _ship.target.owner then
       -- todo: fail message
      else
       _ship.target.owner=_ship.owner
      end
     end
    end
   else
    local _a=atan2(_ship.targetx-_ship.x,_ship.targety-_ship.y)
    _ship.x+=cos(_a)*_ship.spd
    _ship.y+=sin(_a)*_ship.spd
   end
  end
 end
end

function _draw()
 cls(0)

 -- draw planets
 for _p in all(planets) do
  local _x,_y=_p.x-3,_p.y-3
  spr(5,_x,_y)
  if _p.owner then
   local _y2=_y+9
   line(_x,_y2,_x+7,_y2,1)
   if _p.c then
    line(_x,_y2,_x+(_p.c/_p.duration)*7,_y2,players[_p.owner].col)
   end
   pset(_x,_y2,players[_p.owner].col)
  end
 end

 -- draw ships
 for _player in all(players) do
  for _ship in all(_player.ships) do
   pal(1,players[_ship.owner].col)
   spr(2,_ship.x-3,_ship.y-3)
  end
  pal(1,1)
 end

 -- draw selection
 for _player in all(players) do
  if _player.curlevel > 0 then
   pal(1,_player.col)
   for _item in all(_player.items) do
    if _item.sprite then
     spr(_item.sprite,_item.x-3,_item.y-3)
    end
   end
   local _cursel=_player['sel'.._player.curlevel]
   if _cursel then
    sspr(40,8,12,12,_cursel.x-5,_cursel.y-5)
    local _str=_cursel.text or _cursel.name or ''
    local _x=mid(0,_cursel.x-(#_str*2)+1,128-(#_str*4))
    print(_str,_x,_cursel.y-11,1)
   end
   pal(1,1)
  end
 end
end

__gfx__
00000000000010000000000000000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000111000001100000000000000000000666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000011000011100000000000000000005666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000111110000000000000000005666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110000100000111110000000000000000005566666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000001110000001110000000000000000005556666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000110000000000000000000000000000555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000100000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000010000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000100000000100000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010000001000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000
