pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- simpli city 1.0-alpha
-- by ironchest games

-- https://github.com/morgan3d/misc/blob/master/p8pathfinder/pathfinder.p8

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

-- 112*88=9856

roads={}



-- buildings={
--  -- land
--  {
--   s=1,
--   propose=function()

--   end,
--  },

--  -- hq
--  {
--   s=2,
--   text='this is your hq',
--   -- approve=function()
--  },

--  -- 

-- }

function _init()

 for _y=1,88 do
  roads[_y]={}
  for _x=1,112 do
   roads[_y][_x]=
  end
 end

 -- cury,curx,citymap=5,8,{
 --  split'0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0',
 --  split'0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0',
 --  split'0,0,0,0,1,0,1,1,1,1,0,0,0,0,0,0',
 --  split'0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0',
 --  split'0,0,0,0,0,1,1,2,1,1,1,0,0,0,0,0',
 --  split'0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0',
 --  split'0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0',
 --  split'0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0',
 --  split'0,0,0,0,1,1,0,0,0,0,1,1,1,0,0,0',
 --  split'0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0',
 --  split'0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0',
 -- }

 -- for _y=1,11 do
 --  for _x=1,16 do
 --   if citymap[_y][_x] > 0 then
 --    citymap[_y][_x]=clone(buildings[citymap[_y][_x]])
 --   end
 --  end
 -- end
end

function _update60()
 -- local _nextx,_nexty=curx,cury
 -- if btnp(0) then
 --  _nextx-=1
 -- end
 -- if btnp(1) then
 --  _nextx+=1
 -- end
 -- if btnp(2) then
 --  _nexty-=1
 -- end
 -- if btnp(3) then
 --  _nexty+=1
 -- end

 -- if citymap[_nexty][_nextx] != 0 then
 --  curx,cury=_nextx,_nexty
 -- end
end

function _draw()
 pal(15,-4,1)
 pal(3,-5,1)
 cls(3)

 -- local _yoff=8

 -- for _y=1,11 do
 --  for _x=1,16 do
 --   local _screenx,_screeny=_x*8,_yoff+_y*8
 --   if citymap[_y][_x] != 0 then
 --    rectfill(_screenx-1,_screeny+1,_screenx+8,_screeny+9,7)
 --   end
 --  end
 -- end

 -- for _y=1,11 do
 --  for _x=1,16 do
 --   local _screenx,_screeny=_x*8,_yoff+_y*8
 --   if citymap[_y][_x] != 0 then
 --    line(_screenx,_screeny+8,_screenx+7,_screeny+8,4)
 --   end
 --  end
 -- end

 -- for _y=1,11 do
 --  for _x=1,16 do
 --   local _screenx,_screeny=_x*8,_yoff+_y*8
 --   if citymap[_y][_x] != 0 then
 --    spr(citymap[_y][_x].s,_screenx,_screeny)
 --   end
 --  end
 -- end

 -- rect(curx*8,_yoff+cury*8,curx*8+7,_yoff+cury*8+7,7)

 -- if citymap[cury][curx] != 0 then
 --  if citymap[cury][curx].text then
 --   rectfill(0,99,127,127,7)
 --   print(citymap[cury][curx].text,2,101,5)
 --  end

 --  if citymap[cury][curx].text then
 --   rectfill(76,119,120,128,3)
 --   print('🅾️ approve',79,121,10)
 --  end
 -- end
end

__gfx__
00000000bbbbbbbbbbb99bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbbb99bbbbbb3bbbbbbb777bbbb777bbbb77bbbbb000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbb9449bbbbb5bbbbbbb667dbbb766bbbb66bb77b000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbd9449dbbbbbb3bbbb6dd6dbbb755ddbb66dd66b000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbb9999bbbb77b5bbbb6c63bbbb777ddbb33bd66b000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbd4444dbbd66bbbbbb666bbbbb666bbbb33bb33b000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbb3553bbbb33bbbbbbbbbbbbbb333bbbbbbbb33b000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
