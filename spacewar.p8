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
   local _a=atan2(_item.follow.x-_cur.follow.x,_item.follow.y-_cur.follow.y)%1
   local _d=dist(_item.follow.x,_item.follow.y,_cur.follow.x,_cur.follow.y)
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

function addperfmenu(_player,_items)
 local _plperfmenu=perfmenus[_player]
 _plperfmenu[#_plperfmenu+1]={
  sel=_items[1],
  items=_items,
 }
end

function setshiptarget(_ship,_target)
 _ship.targetx=_target.x
 _ship.targety=_target.y
 -- todo: check for free move mode
 _ship.target=_target
end

function colonize(_perfmenu,_shipitem,_planetitem)
 add(_perfmenu.items,_planetitem)
 _planetitem.action=function(_perfmenu)
  local _items={
   {x=10,y=100},
   {x=100,y=100},
   {x=100,y=10},
  }
  add(_perfmenu,{
   sel=_items[1],
   items=_items,
  })
 end
 _planetitem.item.owner=_shipitem.item.owner
 return true
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

perfmenus={
 [1]={},
}

pl1ships={
 {
  x=rnd(128),y=rnd(128),
 },
 {
  x=rnd(128),y=rnd(128),
 },
}
-- perfmenus[1][1].sel.item=pl1ships[1]
-- local _items={}
-- for _ship in all(pl1ships) do
--  local _action=function(_perfmenus)
--   local _cursel=_perfmenus[#_perfmenus]
--   local _items={}
--   add(_items,{
--    item=_ship,
--    text='toggle free move',
--    action=function(_perfmenus)

--    end,
--   })
--   for _p in all(planets) do
--    add(_items,{
--     item=_p,
--     action=function(_perfmenus)
--      _ship.targetx=_p.x
--      _ship.targety=_p.y
--      _ship.target=_p
--      deli(_perfmenus,#_perfmenus)
--      _ship.order=function()
--       colonize(_perfmenus,_cursel.sel,{
--        item=_p,
--        })
--      end
--     end,
--    })
--   end
--   add(_perfmenus,{
--    source=_cursel.sel,
--    sel=_cursel.sel,
--    text='',
--    items=_items,
--   })
--  end

--  add(_items,{
--   item=_ship,
--   action=_action,
--  })
-- end
-- perfmenus[1][1].items=_items

for _ship in all(pl1ships) do
 _ship.targetx,_ship.targety=_ship.x,_ship.y
 _ship.spd=0.02
 _ship.owner=13
 _ship.name='destroyer'
end

function newplperfmenu(_player)
 local _items={}
 for _ship in all(pl1ships) do
  add(_items,{
   follow=_ship,
   text=_ship.name,
   action=function()
    -- get legal targets and their possible action
    local _targets=concat({_ship},clone(planets))

    local _items={}
    for _target in all(_targets) do
     local _text='toggle free move'
     local _action=function()
      -- todo: toggle free move
     end
     if _target.isplanet then
      _text='colonize'
      _action=function()
       setshiptarget(_ship,_target)
       _ship.order=function()
        -- todo: show message
        _target.owner=_ship.owner
       end
       perfmenus[_player]={newplperfmenu(_player)}
      end
     end
     add(_items,{
      follow=_target,
      text=_text,
      action=_action,
     })
    end
    addperfmenu(_player,_items)
   end,
  })
 end
 return {
  sel=_items[1],
  items=_items,
 }
end

perfmenus[1][1]=newplperfmenu(1)


function _update60()

 local _curperfmenu=perfmenus[1][#perfmenus[1]]
 if band(btnp(),0b1111) != 0 then
  _curperfmenu.sel=perfselect(_curperfmenu.sel,_curperfmenu.items)
 elseif btnp(4) then
  _curperfmenu.sel.action()
 elseif btnp(5) and #perfmenus[1] > 1 then
  deli(perfmenus[1],#perfmenus[1])
 end

 -- move ships
 for _ship in all(pl1ships) do
  if dist(_ship.x,_ship.y,_ship.targetx,_ship.targety) < 4 then
   _ship.targetx,_ship.targety=_ship.x,_ship.y
   if _ship.target then
    if _ship.order(_ship,_ship.target) then
     -- todo: message
    end
   end
  else
   local _a=atan2(_ship.targetx-_ship.x,_ship.targety-_ship.y)
   _ship.x+=cos(_a)*_ship.spd
   _ship.y+=sin(_a)*_ship.spd
  end
 end
end

function _draw()
 cls(0)

 -- draw planets
 for _p in all(planets) do
  spr(5,_p.x,_p.y)
  if _p.owner then
   local _y=_p.y+9
   line(_p.x,_y,_p.x+7,_y,1)
   pset(_p.x,_y,_p.owner)
  end
 end

 -- -- draw ships
 for _ship in all(pl1ships) do
  pal(1,_ship.owner)
  spr(2,_ship.x,_ship.y)
 end
 pal(1,1)

 -- draw perfmenus
 pal(1,13)
 local _cursel=perfmenus[1][#perfmenus[1]].sel
 sspr(40,8,12,12,_cursel.follow.x-3,_cursel.follow.y-1)
 print(_cursel.text or '',_cursel.follow.x-3,_cursel.follow.y-7,1)
 pal(1,1)
end

__gfx__
00000000000010000000000000000000000000000066660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000111000000000000000000000000000666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000011000001100000000000000000005666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000011100000000000000000005666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110000100000111110000000000000000005566666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000001110000111110000000000000000005556666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00110000000110000001110000000000000000000555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
