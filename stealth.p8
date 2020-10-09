pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- sneaky stealy

-- notes:
-- - any _i is the position, where the part before *32 is the y-axis, and the the one after *32+ is the x-axis

--[[

- map generation

- add outside hacking sprite

- filing drawers
 - search (up/down?)

- bug if suspect seen and caught same tick (came out of hiding for ex)

- bug fog wrapping

- map picker scene
 - left/right scrolling blueprints
 - up selects and enters the map
 - see possible loot??

- loot scene
 - print out, row by row what the loot was
 - add it up
 - pressing next -> show total cash

- guard behaviour
 - go towards player if lighted

- wantedness
 - increase wantedness if spending too much time in light
 - change number of officers in police scene
 - if wantedness is more than 3, send armored truck, and game over

- armed guards
 - if player is within 10 squares in guard dir then he is caught, only horizontally

- guard behaviour
 - go towards player if lighted
 - standing guard
 - standing/listening
 - changing dir if heard something

- cabinet
 - search (how? just open?)

- fix generic loot sound
 - play in player loots
 - remove from action functions

- locked doors
 - sfx

- table???
 - hide under

- busting out of jail???

- window broken glass

- doorfromunder from outside - player is hard to see

- message for when switching controls

- names: johnny, jimmy, tommy, benny

--]]

devfog=false
devvalues=not false

menuitem(1, 'devfog', function() devfog=not devfog end)
menuitem(2, 'devvalues', function() devvalues=not devvalues end)

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end


function testme_calib(name, func, calibrate_func, ...)
 -- based on https://www.lexaloffle.com/bbs/?pid=60198#p
 local n = 1024
 local nd = 128/n*256/60*256

 -- calibrate
 flip()
 local unused -- i am not sure why this helps give better results, but it does, so.

 local x,t=stat(1),stat(2)
 for i=1,n do
   calibrate_func(...)
 end
 local y,u=stat(1),stat(2)

 -- measure
 for i=1,n do
   func(...)
 end
 local z,v=stat(1),stat(2)

 -- report
 local function c(t0,t1,t2)
  return(t0+t2-2*t1)*nd*2 end -- *2 for 0.2.x

 local s=name.." :"
 local lc=c(x-t,y-u,z-v)
 if (lc != 0) s..=" lua="..lc
 local sc=c(t,u,v)
 if (sc != 0) s..=" sys="..sc

 print(s) -- no paging, so not very useful, but.
 debug(s)
end

function testme(name, func, ...)
 func()
 -- return testme_calib(name, func, function() end, ...)
end

-- set auto-repeat delay for btnp
poke(0x5f5c, 5)

local diropposites={[0]=1,0,3,2,}
local arslen=32*32-1

local adjdeltas={[0]=-1,1,-32,32,}

local fogdirs={
 {x=1,y=0,dx=1,dy=1},
 {x=1,y=0,dx=1,dy=-1},
 {x=-1,y=0,dx=-1,dy=1},
 {x=-1,y=0,dx=-1,dy=-1},
 {x=0,y=1,dx=1,dy=1},
 {x=0,y=1,dx=-1,dy=1},
 {x=0,y=-1,dx=1,dy=-1},
 {x=0,y=-1,dx=-1,dy=-1},
}

local guardsholdingdeltas={-65,-64,-63,-34,-33,-32,-31,-30,-2,-1,0,1,2,30,31,32,33,34,63,64,65}

local tick=0

local msgs={}
local msgcols={{6,13},{9,10}}

local floor
local objs
local light={}
local fog={}
local cameras={}

local alertlvl=1
local alertlvls={24,8} -- note: only tick time
local policet=0

local escapedplayers={}
local playerinventory={}


local players={
 {},
 {},
}

local guards={
 -- {
 --  x=12,y=12,
 --  dx=-1,dy=0,
 --  state='patrolling',
 --  state_c=0,
 --  state_c2=0,
 -- },
 -- {
 --  x=16,y=30,
 --  dx=-1,dy=0,
 --  state='patrolling',
 --  state_c=0,
 --  state_c2=0,
 -- },
}

local initpolice


-- helper funcs

local function curry3(_f,_a,_b,_c)
 return function()
  _f(_a,_b,_c)
 end
end

local function shuffle(_l)
 for _i=#_l,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end

function clone(_t)
 local _tc={}
 for _k,_v in pairs(_t) do
  _tc[_k]=_v
 end
 return _tc
end

local function sortonx(_t)
 for _i=1,#_t do
  local _j = _i
  while _j > 1 and _t[_j-1].x > _t[_j].x do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end


local function adjacency(_x1,_y1,_x2,_y2)
 if _x1 == _x2-1 and _y1 == _y2 then
  return 0
 elseif _x1 == _x2+1 and _y1 == _y2 then
  return 1
 elseif _x1 == _x2 and _y1 == _y2-1 then
  return 2
 elseif _x1 == _x2 and _y1 == _y2+1 then
  return 3
 end
 -- return nil
end

local function walladjacency(_a)
 -- todo: fix for out of bounds
 if floor[_a.y*32+_a.x-1] == 2 then
  return 0
 elseif floor[_a.y*32+_a.x+1] == 2 then
  return 1
 elseif floor[(_a.y-1)*32+_a.x] == 2 then
  return 2
 elseif floor[(_a.y+1)*32+_a.x] == 2 then
  return 3
 end
 -- return nil
end



local function playerloots(_p,_o)
 local _m='(nothing)'
 if _o.loot != nil then
  _m=_o.loot[1]
  if _o.loot[2] != nil then -- has value, then it's a thing, take it
   _p.loot[#_p.loot+1]=_o.loot
  else
   playerinventory[#playerinventory+1]=_o.loot -- no value, it's information
  end
 end
 add(msgs,{x=_p.x,y=_p.y-1,s=_m,t=3})
 _o.loot=nil
end



for _i=0,arslen do
 light[_i]=0
end

for _i=1,#players do
 local _p=players[_i]
 _p.i=_i-1
 _p.origi=_p.i
 _p.dir=1
 _p.state='standing'
 _p.workingstate='hacking'
 _p.loot={}
end





local function setalertlvl2(_m)
 if alertlvl == 1 then
  alertlvl=2
  tick=60
  policet=120
  for _g in all(guards) do
   add(msgs,{x=_g.x,y=_g.y,s=_m,t=4,colset=2})
   _g.state='patrolling'
  end
  if #guards == 0 then
   add(msgs,{x=16,y=16,s=_m,t=4,colset=2})
  end
 end
end










local function computer(_p,_o,_tmp)
 _p.workingstate='hacking'
 if _tmp.action_c == nil then
  _tmp.action_c=0
  _tmp.state='booting'
  sfx(11)
  local _l=14 -- note: change this if good at computers
  _tmp.seq={}
  for _i=1,_l do
   local _n=0
   repeat
    _n=flr(rnd(3))
   until _n != _tmp.seq[_i-1]
   _tmp.seq[_i]=_n
  end
  _o.draw=function()
   if _tmp.state == 'booting' then
    sspr(0,102,4,3,_tmp.ox*4,_tmp.oy*4-3)

   elseif _tmp.state == 'success' then
    sspr(0,114,4,3,_tmp.ox*4,_tmp.oy*4-3)

   elseif _tmp.state == 'fail' then
    sspr(0,117,4,3,_tmp.ox*4,_tmp.oy*4-3)

   else
    sspr(0,105+_tmp.seq[1]*3,4,3,_tmp.ox*4,_tmp.oy*4-3)
   end
  end
 end

 _tmp.action_c+=1

 if _tmp.action_c == 30 then
  _tmp.state='ready'
  sfx(12)
 end

 if _tmp.state == 'ready' then
  local _input=nil
  if btnp(0,_p.i) then
   _input=0
  elseif btnp(1,_p.i) then
   _input=1
  elseif btnp(2,_p.i) then
   _input=2
  end

  if _input != nil then
   if _input == _tmp.seq[1] then
    del(_tmp.seq,_input)
    if #_tmp.seq == 0 then
     _tmp.state='success'
     sfx(10)
     playerloots(_p,_o)
    end
   else
    _tmp.state='fail'
    sfx(9)
   end
  end
 end

 if btnp(3,_p.i) then
  -- reset player
  _p.action=nil
  _p.state='standing'

  -- reset obj
  _o.draw=nil
 end
end


-- states:
-- 0 - off
-- 1 - on
-- 2 - selected/on (camcontrol)
-- 3 - system alarm (camcontrol)
local function camcontrol(_p,_o,_tmp)
 _p.workingstate='hacking'
 if not _tmp.sel then
  _tmp.sel=1
  _tmp.pos={
   {x=-2,y=-4},
   {x=3,y=-4},
   {x=-2,y=-1},
   {x=3,y=-1},
  }

  -- start all cameras
  for _i=1,4 do
   local _c=cameras[_i]
   _tmp.pos[_i].state=1
   if _c then
    _c.state=1
   end
  end

  _tmp.pos[1].state=2

  _o.draw=function()
   for _i=1,#_tmp.pos do
    local _p=_tmp.pos[_i]
    local _x=_tmp.ox*4+_p.x
    local _y=_tmp.oy*4+_p.y
    sspr(0,120+_p.state*2,3,2,_x,_y)
   end
  end
 end

 if _tmp.pos[1].state != 3 then

  _tmp.pos[_tmp.sel].state=1

  if btnp(0,_p.i) then
   _tmp.sel-=1
  elseif btnp(1,_p.i) then
   _tmp.sel+=1
  end

  if _tmp.sel > 4 then
   _tmp.sel=1
  elseif _tmp.sel < 1 then
   _tmp.sel=4
  end

  _tmp.pos[_tmp.sel].state=2

  if btnp(2,_p.i) then
   _tmp.pos[_tmp.sel].state=0
   _tmp.sel+=1
   if _tmp.sel > 4 then
    _tmp.sel=1
   elseif _tmp.sel < 1 then
    _tmp.sel=4
   end
   _tmp.pos[_tmp.sel].state=2
  end

  for _c in all(cameras) do
   _c.state=_tmp.pos[_c.i].state
  end

  local _c=0
  for _p in all(_tmp.pos) do
   if _p.state == 0 then
    _c+=1
   end
  end

  if _c > 1 then
   _tmp.pos[1].state=3
   _tmp.pos[2].state=3
   _tmp.pos[3].state=3
   _tmp.pos[4].state=3
   sfx(13)
   setalertlvl2('cctv compromised!')
  end
 end

 if btnp(3,_p.i) then
  -- reset player
  _p.action=nil
  _p.state='standing'

  -- reset cameras
  local _c=cameras[_tmp.sel]
  if _c then
   _c.state=1
  end
  _tmp={}

  -- reset obj
  _o.draw=nil
 end
end


local function safe(_p,_o,_tmp)
 _p.workingstate='cracking'
 if _o.isopen != true then

  -- generate new code
  if _o.code == nil then
   _o.code={flr(rnd(8))+1,flr(rnd(8))+1,flr(rnd(8))+1,flr(rnd(8))+1,flr(rnd(8))+1}
  end

  -- reset for this try
  if _tmp.code == nil then
   _tmp.code=_o.code
   _tmp.codei=1
   _tmp.codetick=0
   _tmp.unlocked=nil

   _o.draw=function()
    if _tmp.iserror == true then
     pset(_tmp.ox*4+5,_tmp.oy*4-3,8)
    elseif _o.isopen != true and _tmp.unlocked == true then
     pset(_tmp.ox*4+5,_tmp.oy*4-3,11)
    end
   end
  end

  local _dir=_tmp.codei%2
  for _i=0,1 do
   if btnp(_i,_p.i) then
    local _snd=nil
    if _dir == _i then
     _tmp.codetick+=1
     if _tmp.iserror != true and _tmp.codetick == _tmp.code[_tmp.codei] then
      if _tmp.codei == #_tmp.code then
       _tmp.unlocked=true
      end
      _tmp.codei+=1
      _tmp.codetick=0
      sfx(14) -- high click
      _snd=true
     end
    else
     _tmp.iserror=true
    end
    if _snd != true then
     sfx(15) -- click
    end
   end
  end

  if _tmp.unlocked and btnp(2,_p.i) then
   _o.isopen=true
   objs[_tmp.oi].typ+=2
   objs[_tmp.oi+1].typ+=2
   sfx(10) -- creek open
   playerloots(_p,_o)
  end
 end
 
 if btnp(3,_p.i) then
  -- reset player
  _p.action=nil
  _p.state='standing'

  -- reset obj
  _o.draw=nil
 end

end



local function resetdoor(_p,_o)
 -- reset player
 _p.action=nil
 _p.state='standing'

 -- reset obj
 _o.typ-=2
end

local function doorfromunder(_p,_o,_tmp)
 if _tmp.opened == nil then
  _o.typ+=2
  _tmp.opened=true
 end

 if light[(_tmp.oy-2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!')
 end

 for _y=_tmp.oy-2,0,-1 do
  fog[_y*32+_tmp.ox]=0
  if floor[_y*32+_tmp.ox] == 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  _p.y-=3
  resetdoor(_p,_o)
 end

 if btnp(3,_p.i) then
  resetdoor(_p,_o)
 end
end

local function doorpeekfromunder(_p,_o,_tmp)
 fog[(_tmp.oy-2)*32+_tmp.ox]=0
end

local function doorfromabove(_p,_o,_tmp)
 if _tmp.opened == nil then
  _tmp.o2=objs[_tmp.oi+32]
  _tmp.o2.typ+=2
  _tmp.opened=true
 end

 if light[(_tmp.oy+2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!')
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2,32 do
  fog[_y*32+_tmp.ox]=0
  if floor[_y*32+_tmp.ox] == 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  resetdoor(_p,_tmp.o2)
 end

 if btnp(3,_p.i) then
  _p.y+=3
  resetdoor(_p,_tmp.o2)
 end
end

local function doorpeekfromabove(_p,_o,_tmp)
 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 fog[(_tmp.oy+2)*32+_tmp.ox]=0
end


local function lockeddoorfrombelow(_p,_o,_tmp)
 if _o.typ == 16 then
  for _l in all(playerinventory) do
   if _l[1] ==  'door access code' then
    _o.typ+=2
    _p.action=nil
    _p.state='standing'
    -- todo: sfx
    return
   end
  end
  _p.action=nil
  _p.state='standing'
  return
 end

 if _tmp.opened == nil then
  _o.typ+=2
  _tmp.opened=true
 end

 if light[(_tmp.oy-2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!')
 end

 for _y=_tmp.oy-2,0,-1 do
  fog[_y*32+_tmp.ox]=0
  if floor[_y*32+_tmp.ox] == 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  _p.y-=3
  resetdoor(_p,_o)
 end

 if btnp(3,_p.i) then
  resetdoor(_p,_o)
 end
end

local function lockeddoorfromabove(_p,_o,_tmp)
 local _o2=objs[_tmp.oi+32]
 if _o2.typ == 16 then
  for _l in all(playerinventory) do
   if _l[1] ==  'door access code' then
    _o2.typ+=2
    _p.action=nil
    _p.state='standing'
    -- todo: sfx
    return
   end
  end
  _p.action=nil
  _p.state='standing'
  return
 end

 if _tmp.opened == nil then
  _o2.typ+=2
  _tmp.opened=true
 end

 if light[(_tmp.oy+2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!')
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2,32 do
  fog[_y*32+_tmp.ox]=0
  if floor[_y*32+_tmp.ox] == 2 then
   break
  end
 end

 if btnp(2,_p.i) then
  resetdoor(_p,_o2)
 end

 if btnp(3,_p.i) then
  _p.y+=3
  resetdoor(_p,_o2)
 end
end


local function windowpeekfromleft(_p,_o)
 for _x=_p.x+2,32 do
  fog[_p.y*32+_x]=0
  if floor[_p.y*32+_x] == 2 then
   break
  end
 end
end

local function windowpeekfromright(_p,_o)
 for _x=_p.x-2,0,-1 do
  fog[_p.y*32+_x]=0
  if floor[_p.y*32+_x] == 2 then
   break
  end
 end
end

local function breakwindowfromleft(_p,_o)
 if _o.typ == 22 then
  _o.typ+=1
  -- todo: play sound
 elseif _o.typ == 23 then
  _p.x+=2
 end

 -- reset player
 _p.action=nil
 _p.state='standing'
end

local function breakwindowfromright(_p,_o)
 if _o.typ == 22 then
  _o.typ+=1
  -- todo: play sound
 elseif _o.typ == 23 then
  _p.x-=2
 end

 -- reset player
 _p.action=nil
 _p.state='standing'
end

local function iswallclose(_x,_y,_dx,_dy)
 local _c=0
 while _y >= 1 and _y <= 32 and _x >= 1 and _x <= 32 and floor[_y*32+_x] != 2 do
  _x+=_dx
  _y+=_dy
  _c+=1
 end
 return _c <= 3
end












local seed=flr(rnd()*10000)
-- seed=5008
-- seed=2685
-- seed=227
-- seed=9399
-- seed=4199
-- seed=4403
-- seed=9737
-- seed=7594
-- seed=6590
-- seed=210
-- seed=8986
-- seed=6124
-- seed=1857
debug('seed',seed)

function mapgen()
 srand(seed)
 floor={}
 objs={}

 local _r=rnd()
 local _x,_y=30,30
 if _r < 0.25 then
  _x,_y=0,2
 elseif _r < 0.5 then
  _y=2
 elseif _r < 0.75 then
  _x=0
 end
 for _p in all(players) do
  _p.x,_p.y=_x+_p.i,_y+_p.i
 end

 for _i=0,arslen do
  -- local _x,_y=_i&31,_i\32
  floor[_i]=0
 end

 local function floorcount(_x,_y)
  local _c=0
  if floor[_y*32+_x-1] == 1 then
   _c+=1
  end
  if floor[_y*32+_x+1] == 1 then
   _c+=1
  end
  if floor[(_y-1)*32+_x] == 1 then
   _c+=1
  end
  if floor[(_y+1)*32+_x] == 1 then
   _c+=1
  end
  return _c
 end

 -- add rooms
 local _xmin=2
 local _ymin=3
 local _ystart=3

 repeat
  local _w=flr(rnd(19))+10
  local _h=flr(rnd(5))+6
  local _xstart=2+flr(rnd(28-_w))

  for _y=0,_h-1 do
   for _x=0,_w-1 do
    local _i=(_ystart+_y)*32+_xstart+_x
    if _y == 0 or _y == _h-1 or _x == 0 or _x == _w-1 then
     floor[_i]=2
     floor[(_ystart+_y-1)*32+_xstart+_x]=2
    else
     floor[_i]=1
    end
   end
  end

  -- add left window
  objs[(_ystart+2+flr(rnd(_h-5)))*32+_xstart]={
   typ=22,
   action={[0]=breakwindowfromright,[1]=breakwindowfromleft},
   adjaction={[0]=windowpeekfromright,[1]=windowpeekfromleft},
  }

  -- add right window
  objs[(_ystart+2+flr(rnd(_h-5)))*32+_xstart+_w-1]={
   typ=22,
   action={[0]=breakwindowfromright,[1]=breakwindowfromleft},
   adjaction={[0]=windowpeekfromright,[1]=windowpeekfromleft},
  }

  -- add top door
  objs[(_ystart*32)+_xstart+2+flr(rnd(_w-5))]={
   typ=12,
   action={[2]=doorfromunder},
   adjaction={[2]=doorpeekfromunder}
  }

  -- -- add camera
  local _c={x=_xstart+1,y=_ystart+1,state=1,}
  if rnd() < 0.5 then
   _c.x=_xstart+_w-2
  end

  if rnd() > 0.5 then
   if rnd() > 0.8 then
    _c.state=0
   end
   add(cameras,_c)
  end

  -- bottom wall
  _ystart+=_h-1

  -- add bottom door
  objs[_ystart*32+_xstart+2+flr(rnd(_w-5))]={
   typ=12,
   action={[2]=doorfromunder},
   adjaction={[2]=doorpeekfromunder}
  }

 until _ystart+_h-1 > 27

 -- add corridor
 local _w=flr(rnd(5))+6
 local _h=flr(rnd(19))+10
 local _xstart=2+flr(rnd(28-_w))
 local _ystart=3

 for _y=0,_h-1 do
  for _x=0,_w-1 do
   local _i=(_ystart+_y)*32+_xstart+_x
   local _fc=floorcount(_xstart+_x,_ystart+_y)
   if _y == 0 or _y == _h-1 then
    floor[(_ystart+_y)*32+_xstart+_x]=2
    floor[(_ystart+_y-1)*32+_xstart+_x]=2
   end
   if _y == 0 or _y == _h-1 or _x == 0 or _x == _w-1 then
    local _current=floor[_i]
    if _current == 2 then
     floor[_i]=2
    elseif _current == 1 and _fc > 1 then
     floor[_i]=1
    else
     floor[_i]=2
    end
   else
    floor[_i]=1
   end
  end
 end

 -- fix cameras
 for _j=#cameras,1,-1 do
  local _c=cameras[_j]
  local _i=_c.y*32+_c.x
  if objs[_i-32-1] or
     objs[_i-1] or
     objs[_i+1] or
     objs[_i-32] or
     objs[_i+32] or
     floor[_i] == 2 or
     floor[_i-32] != 2 or
     not (floor[_i+1] == 2 or floor[_i-1] == 2) then
   del(cameras,_c)
  end
 end

 shuffle(cameras)

 while #cameras > 4 do
  deli(cameras,1)
 end

 -- add i for cameras
 for _i=1,#cameras do
  cameras[_i].i=_i
 end

 -- create objs positions
 local _pos={}
 for _y=2,29 do
  local _x=flr(rnd(4))+2
  while _x < 29 do
   local _i=_y*32+_x
   local _remove=false
   for _c in all(cameras) do
    if _c.x == _x and _c.y == _y or adjacency(_c.x,_c.y,_x,_y) then
     _remove=true
     break
    end
   end
   if _remove == false and
      objs[_i-32-1] == nil and
      objs[_i-32] == nil and
      objs[_i-32+1] == nil and
      objs[_i-32+2] == nil and
      objs[_i-1] == nil and
      objs[_i] == nil and
      objs[_i+1] == nil and
      objs[_i+2] == nil and
      floor[_i-32] == 2 and
      floor[_i-32+1] == 2 and
      floor[_i-32+2] == 2 and
      floor[_i] == 1 and
      floor[_i+1] == 1 and
      floor[_i+2] == 1 and
      floor[_i+32] == 1 and
      floor[_i+32+1] == 1 and
      floor[_i+32+2] == 1 and
      floor[_i+64] == 1 and
      floor[_i+64+1] == 1 and
      floor[_i+64+2] == 1 then
    add(_pos,_i)
    _x+=5
   elseif _remove == true then
    _x+=2
   else
    _x+=flr(rnd(6))+1
   end
  end
 end

 shuffle(_pos)

-- add objects

 -- 0 - plant
 -- 1 - watercooler
 -- 2 - computer
 -- 5 - camcontrol
 -- 8 - safe

 local _types={0,1,2,8}

 if #cameras > 0 then
  add(_types,5)
 end

 for _i in all(_pos) do
  local _typ=_types[flr(rnd(#_types))+1]
  if _typ == 8 or _typ == 5 then
   del(_types,_typ)
  end

  local _o={typ=_typ,shadow={[0]=true,true,nil,nil},}
  objs[_i]=_o

  if _typ == 2 then
   _o.shadow={[0]=true,nil,nil,nil}
   objs[_i+1]={typ=3,action={[2]=computer},loot={'door access code'},shadow={[0]=nil,nil,nil,nil}}
   objs[_i+2]={typ=4,shadow={[0]=nil,true,nil,nil}}

  elseif _typ == 5 then
   _o.shadow={[0]=true,nil,nil,nil}
   objs[_i+1]={typ=6,action={[2]=camcontrol},shadow={[0]=nil,nil,nil,nil}}
   objs[_i+2]={typ=7,shadow={[0]=nil,true,nil,nil}}

  elseif _typ == 8 then
   _o.shadow={[0]=true,nil,nil,nil}
   _o.action={[2]=safe}
   _o.loot={'diamonds',14000}

   objs[_i+1]={typ=9,shadow={[0]=nil,true,nil,nil}}
  end
 end

 -- fix objs
 for _i=0,arslen do
  local _o=objs[_i]
  if _o then
   _o.light={}
  end

  -- remove windows
  if _o and _o.typ == 22 then
   if not (floor[_i] == 2 and floor[_i-1] != 2 and floor[_i+1] != 2) then
    objs[_i]=nil
   end
  end

  -- fix doors
  if _o and _o.typ == 12 then
   if objs[_i+1] or not (floor[_i] == 2 and floor[_i-1] == 2 and floor[_i+1] == 2 and floor[_i+32] != 2 and floor[_i-64] != 2) then
    objs[_i]=nil
   else
    objs[_i-32]={action={[3]=doorfromabove},adjaction={[3]=doorpeekfromabove}}
    objs[_i+1]={typ=13}

    -- switch to locked
    if rnd() > 0.75 then
     objs[_i].typ=16
     objs[_i].action[2]=lockeddoorfrombelow

     objs[_i-32].action[3]=lockeddoorfromabove

     objs[_i+1].typ=17
    end
   end
  end
 end

end




function _init()
 tick=0
 alertlvl=1
 mapgen()
end

function gameupdate()
 tick-=1

 -- reset fog
 fog={}

 -- update players
 for _p in all(players) do

  -- switch player control
  if btnp(4) or btnp(5) then
   _p.i=_p.i^^1
  end

  -- input
  if _p.state == 'working' then
   _p.workingstate='hacking'
   _p.action()

  else
   local _isinput
   _p.dx=0
   _p.dy=0
   if btnp(0,_p.i) then
    _p.dx=-1
    _p.dir=0
    _isinput=true
   elseif btnp(1,_p.i) then
    _p.dx=1
    _p.dir=1
    _isinput=true
   elseif btnp(2,_p.i) then
    _p.dy=-1
    _isinput=true
   elseif btnp(3,_p.i) then
    _p.dy=1
    _isinput=true
   end
   local _nextx,_nexty=_p.x+_p.dx,_p.y+_p.dy
   if _nextx > 31 or _nextx < 0 or _nexty > 31 or _nexty < 0 then
    add(escapedplayers,_p)
    del(players,_p)
    add(msgs,{x=_p.x,y=_p.y,s='escaped',t=2})
   else

    local _ni=_nexty*32+_nextx
    local _nexto=objs[_ni]
    if _nexto != nil then
     local _a=adjacency(_nextx,_nexty,_p.x,_p.y)
     _nextx,_nexty=_p.x,_p.y
     if _nexto.action and _nexto.action[_a] then
      _p.state='working'
      _p.action=curry3(_nexto.action[_a],_p,_nexto,{ox=_ni&31,oy=_ni\32,oi=_ni})
     end
    end

    if _p.state != 'working' then
     local _i=_p.y*32+_p.x
     for _a=0,3 do
      local _oi=_i+adjdeltas[_a]
      local _adjo=objs[_oi]
      if _adjo and _adjo.adjaction and _adjo.adjaction[_a] then
       _adjo.adjaction[_a](_p,_adjo,{ox=_oi&31,oy=_oi\32,oi=_oi})
      end
     end
    end


    if _p.state != 'caught' and floor[_nexty*32+_nextx] != 2 then
     _p.x,_p.y=_nextx,_nexty

     -- hide behind object
     if _p.state != 'working' then
      local _hiding=nil
      local _pwa=walladjacency(_p)
      local _i=_p.y*32+_p.x
      for _a=0,3 do
       local _oi=_i+adjdeltas[_a]
       local _o=objs[_oi]
       if _o then
        local _ox,_oy=_oi&31,_oi\32
        local _a=adjacency(_p.x,_p.y,_ox,_oy)
        local _owa=walladjacency({x=_ox,y=_oy})
        if _o.shadow and _o.shadow[_a] and _owa != nil and _pwa != nil and _a != nil and light[_p.y*32+_p.x] == 0 then
         _p.state='hiding'
         _p.adjacency=_a
         _hiding=true
        end
       end
      end
      if _hiding == nil then
       _p.state='standing'
      end
     end

    end
   end
  end

  -- if one square from guard, get caught
  for _g in all(guards) do
   local _dx=_p.x-_g.x
   local _dy=_p.y-_g.y
   if (_p.state != 'hiding' or light[_p.y*32+_p.x] == 1) and _p.state != 'caught' and abs(_dx) <= 1 and abs(_dy) <= 1 then
    _p.state='caught'
    _g.state='holding'
    add(msgs,{x=_g.x,y=_g.y,s='suspect caught!',t=4,colset=2})
   end
  end

  -- any input near a guard makes noise and they get suspicious
  -- if _isinput then
  --  for _g in all(guards) do
  --   local _dx=_p.x-_g.x
  --   local _dy=_p.y-_g.y
  --   local _h=sqrt(_dx*_dx+_dy*_dy)
  --   if _g.state != 'holding' and _h <= 5 then
  --    sfx(0)
  --    _g.state='listening'
  --    _g.state_c=7
  --    _g.state_c2=3
  --    add(msgs,{x=_g.x,y=_g.y,s='?',t=4})
  --   end
  --  end
  -- end
 end

 if tick <= 0 then

  -- update guards
  for _g in all(guards) do

   -- handle state
   if _g.state == 'standing' then
    _g.state_c-=1
    -- set to patrolling
    if _g.state_c <= 0 then
     _g.state='patrolling'
    end

   elseif _g.state == 'patrolling' then

    -- turn when close to wall
    if iswallclose(_g.x,_g.y,_g.dx,_g.dy) then
     local _turns=shuffle{
      {dx=_g.dy,dy=_g.dx},
      {dx=-_g.dy,dy=-_g.dx},
     }
     add(_turns,{dx=-_g.dx,dy=-_g.dy})
     for _t in all(_turns) do
      if not iswallclose(_g.x,_g.y,_t.dx,_t.dy) then
       _g.dx=_t.dx
       _g.dy=_t.dy
       break
      end
     end
    end

    -- move
    local _gwa=walladjacency({x=_g.x+_g.dx,y=_g.y+_g.dy}) -- todo: do this better
    if _gwa == 0 then
     _g.x+=1
    elseif _gwa == 1 then
     _g.x-=1
    elseif _gwa == 2 then
     _g.y+=1
    elseif _gwa == 3 then
     _g.y-=1
    else
     _g.x+=_g.dx
     _g.y+=_g.dy
    end

   elseif _g.state == 'holding' then
    -- is holding suspect

   elseif _g.state == 'listening' then
    _g.state_c-=1
    _g.state_c2-=1

    if _g.state_c2 <= 0 then
     local _action=flr(rnd(2))+1
     -- turns 180
     if _action == 1 then
      _g.dx*=-1
      _g.dy*=-1
      _g.state_c2=3

     -- decides to walk
     elseif _action == 2 then
      _g.state_c=0
     end
    end

    -- set to patrolling
    if _g.state_c <= 0 then
     _g.state='patrolling'
    end
   end
  end

  -- update messages
  for _m in all(msgs) do
   _m.t-=1
   if _m.t <= 0 then
    del(msgs,_m)
   end
  end

  -- set new tick
  if alertlvl == 2 and policet > 0 then
   policet-=1
   if policet == 64 then
    sfx(16)
   end
   if policet <= 0 then
    initpolice()
   end
  end
  if #guards > 0 and t == 0 then
   if alertlvl == 2 then
    sfx(18)
   else
    sfx(19)
   end
  end
  tick=alertlvls[alertlvl]
 end

 -- clear light
 for _i=0,arslen do
  local _o=objs[_i]
  if _o then
   _o.light={}
  end
  light[_i]=0
 end

 -- add cameras light
 for _c in all(cameras) do
  if _c.state != 0 then
   local _dx=1
   if floor[_c.y*32+_c.x+1] == 2 then
    _dx=-1
   end
   local _x,_y=_c.x,_c.y
   local _ldown,_lside=32,32
   repeat
    local _bx,_by=_x,_y
    local _bydown=_by
    local _bldown=1
    while floor[_bydown*32+_bx] != 2 and _bldown <= _ldown do
     local _o=objs[_bydown*32+_bx]
     if _o then
      add(_o.light,{x=0,y=-1})
     end

     light[_bydown*32+_bx]=1

     -- remove fog if selected in camcontrol
     if _c.state == 2 then
      fog[_bydown*32+_bx]=0

      local _i=(_bydown+1)*32+_bx
      if floor[_i] == 2 then
       fog[_i]=0
      end

      _i=_bydown*32+_bx+1
      if floor[_i] == 2 then
       fog[_i]=0
      end

      _i=_i-2
      if floor[_i] == 2 then
       fog[_i]=0
      end
     end

     _bydown+=1
     _bldown+=1
    end

    local _bxside=_bx
    local _blside=1
    while floor[_by*32+_bxside] != 2 and _blside <= _lside do
     local _o=objs[_by*32+_bxside]
     if _o then
      add(_o.light,{x=-_dx,y=0})
     end

     light[_by*32+_bxside]=1

     -- remove fog if selected in camcontrol
     if _c.state == 2 then
      if _by == _y then
       fog[(_by-1)*32+_bxside]=0
      end

      fog[_by*32+_bxside]=0

      local _i=(_by+1)*32+_bxside
      if floor[_i] == 2 then
       fog[_i]=0
      end

      _i=_by*32+_bxside+_dx
      if floor[_i] == 2 then
       fog[_i]=0
      end
     end

     _bxside+=_dx
     _blside+=1
    end
    _lside=_blside-2
    _ldown=_bldown-2
    _y+=1
    _x+=_dx
   until floor[_y*32+_x] == 2 or
         floor[(_y-1)*32+_x] == 2 or
         floor[_y*32+_x-_dx] == 2
  end
 end

 -- shine guards flashlights
 for _g in all(guards) do
  if _g.state == 'holding' then
   local _i=_g.y*32+_g.x
   for _ghd in all(guardsholdingdeltas) do
    light[_i+_ghd]=1
   end

  elseif _g.dx != 0 then
   local _x,_y=_g.x+_g.dx,_g.y+_g.dy
   local _l=32
   while floor[_y*32+_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by*32+_bx] != 2 and _c <= _l do
     local _o=objs[_by*32+_bx]
     if _o then
      add(_o.light,{x=0,y=-1})
      add(_o.light,{x=-_g.dx,y=0})
     end
     light[_by*32+_bx]=1
     _bx+=_g.dx
     _by+=1
     _c+=1
    end
    _l=_c-1
    _x+=_g.dx
   end

   _x,_y=_g.x+_g.dx,_g.y+_g.dy
   _l=32
   while floor[_y*32+_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by*32+_bx] != 2 and _c <= _l do
     local _o=objs[_by*32+_bx]
     if _o then
      add(_o.light,{x=0,y=1})
      add(_o.light,{x=-_g.dx,y=0})
     end
     light[_by*32+_bx]=1
     _bx+=_g.dx
     _by-=1
     _c+=1
    end
    _l=_c-1
    _x+=_g.dx
   end

  elseif _g.dy != 0 then
   local _x,_y=_g.x+_g.dx,_g.y+_g.dy
   local _l=32
   while floor[_y*32+_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by*32+_bx] != 2 and _c <= _l do
     local _o=objs[_by*32+_bx]
     if _o then
      add(_o.light,{x=0,y=-_g.dy})
      add(_o.light,{x=-1,y=0})
     end
     light[_by*32+_bx]=1
     _bx+=1
     _by+=_g.dy
     _c+=1
    end
    _l=_c-1
    _y+=_g.dy
   end

   _x,_y=_g.x+_g.dx,_g.y+_g.dy
   _l=32
   while floor[_y*32+_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by*32+_bx] != 2 and _c <= _l do
     local _o=objs[_by*32+_bx]
     if _o then
      add(_o.light,{x=0,y=-_g.dy})
      add(_o.light,{x=1,y=0})
     end
     light[_by*32+_bx]=1
     _bx-=1
     _by+=_g.dy
     _c+=1
    end
    _l=_c-1
    _y+=_g.dy
   end
  end
 end

 -- add shadow around objects
 for _i=0,arslen do
  local _o=objs[_i]
  if _o and _o.shadow then
   local _ox,_oy=_i&31,_i\32
   if _o.shadow[0] then
    light[_oy*32+_ox-1]=0
   end
   if _o.shadow[1] then
    light[_oy*32+_ox+1]=0
   end
   if _o.shadow[2] then
    light[(_oy-1)*32+_ox]=0
   end
   if _o.shadow[3] then
    light[(_oy+1)*32+_ox]=0
   end

   for _l in all(_o.light) do
    light[(_oy+_l.y)*32+_ox+_l.x]=1
   end
  end
 end


 for _i=0,arslen do

  -- light up walls
  local _x,_y=_i&31,_i\32
  if light[(_y+1)*32+_x] == 1 and floor[_y*32+_x] == 2 and floor[(_y+1)*32+_x] != 2 then
   light[_y*32+_x]=1
  end

  -- light up windows
  local _o=objs[_i]
  if _o and (_o.typ == 22 or _o.typ == 23) and
     (light[_i-1] == 1 or light[_i+1] == 1) then
   light[_i]=1
   if _o.typ == 23 then
    setalertlvl2('broken window!')
   end
  end
 end

 -- intruder alert
 if alertlvl == 1 then
  for _p in all(players) do
   if light[_p.y*32+_p.x] == 1 then
    setalertlvl2('intruder alert!')
   end
  end
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.typ == 10 and light[_i] == 1 then
    setalertlvl2('safe opened!')
   end
  end
 end

 -- remove fog
 for _p in all(players) do
  if _p.state == 'caught' then
   -- do nothing
  else
   for _d in all(fogdirs) do
    local _x,_y=_p.x,_p.y
    local _l=32
    while floor[_y*32+_x] != 2 and floor[_y*32+_x] != nil do
     local _c=0
     local _bx=_x
     local _by=_y
     while _by < 32 and _by >= 0 and _bx < 32 and _bx >= 0 and floor[_by*32+_bx] != 2 and floor[_by*32+_bx] != nil and _c <= _l do
      fog[_by*32+_bx]=0
      _bx+=_d.dx
      _by+=_d.dy
      _c+=1
     end
     if _by < 32 and _by >= 0 and _bx < 32 and _bx >= 0 then
      fog[_by*32+_bx]=0
     end
     _bx+=_d.dx
     _by+=_d.dy
     _l=_c
     _x+=_d.x
     _y+=_d.y
     if _y < 32 and _y >= 0 and _x < 32 and _x >= 0 then
      fog[_y*32+_x]=0
     else
      break
     end
    end
   end
  end
 end

 -- remove fog from holding guards
 for _g in all(guards) do
  if _g.state == 'holding' then
   local _i=_g.y*32+_g.x
   for _ghd in all(guardsholdingdeltas) do
    fog[_i+_ghd]=0
   end
  end
 end

 -- remove fog from walls
 for _i=0,arslen do
  if fog[_i+32] == 0 and floor[_i] == 2 and floor[_i+32] == 2 then
   fog[_i]=0
  end
 end

end


function _update()
 testme('gameupdate', gameupdate)
 -- gameupdate()
end

function _draw()
 testme('gamedraw', gamedraw)
end

function gamedraw()
 gupd=stat(1)
 gupdmax=max(gupd,gupdmax)

 if alertlvl == 2 and policet <= 64 then
  if policet%8 >= 4 then
   pal(0,8)
  else
   pal(0,12)
  end
 end

 local _lightcols={[0]=1,13,2}
 for _i=arslen,0,-1 do

  -- draw floor
  local _tile=floor[_i]
  local _l=light[_i]
  local _x,_y=_i&31,_i\32
  local _sx,_sy=_x*4,_y*4

  local _col=_tile
  if _l == 1 then
   _col=_lightcols[_col]
  end
  rectfill(_sx,_sy,_sx+3,_sy+3,_col)
  
  -- draw walls
  if _tile == 2 then
   local _tilebelow=floor[_i+32]
   if _tilebelow == 0 then -- todo: maybe remove this, maybe it shouldn't be possible to have light outside
    sspr(12,104+_l*5,4,5,_sx,_sy)
   elseif _tilebelow == 1 then
    rectfill(_sx,_sy,_sx+3,_sy+4,13-7*_l)
   end
  end
 end

 -- add border of premises
 fillp(0b1010010110100101)
 rect(0,0,127,127,3)
 fillp()

 pal()
 palt(0,false)
 palt(15,true)

 -- draw objs
 for _i=0,arslen do
  local _o=objs[_i]
  if _o and _o.typ then
   local _x,_y=_i&31,_i\32
   local _l=light[_i]
   sspr(_o.typ*4,_l*13,4,13,_x*4,_y*4-5)
  end
  _o=objs[_i-1]
  if _o and _o.draw then
   _o.draw()
  end
 end

 -- draw cameras
 for _c in all(cameras) do
  local _sx=8
  if floor[_c.y*32+_c.x+1] == 2 then -- todo: make so cameras can be set anywhere on wall
   _sx=12
  end
  sspr(_sx,116+_c.state*3,4,3,_c.x*4,_c.y*4-4)
 end

 -- draw players
 for _p in all(players) do
  local _i=_p.y*32+_p.x
  local _l=light[_i]
  local _floor=floor[_i]
  local _px,_py=_p.x*4,_p.y*4-5
  if _p.state == 'hiding' then
   sspr(36+_p.adjacency*4,72,4,9,_px,_py)
  elseif _p.state == 'working' then
   if _p.workingstate == 'hacking' then
    sspr(12+_floor*18,72+_l*9,5,9,_px,_py)
   elseif _p.workingstate == 'cracking' then
    sspr(52,72+_l*9,5,9,_px,_py)
   end
   if #_p.loot > 0 then
    sspr(5,91+_l*4,8,4,_px,_py+5)
   end
  elseif _p.state == 'caught' then
   sspr(0,90,6,9,_px,_py)
  else
   local _flipx=false
   if _p.dir == 1 then
    _flipx=true
   end
   if #_p.loot > 0 then
    sspr(6+_floor*18,72+_l*9,6,9,_px-_p.dir*2,_py,6,9,_flipx)
   else
    sspr(0+_floor*18,72+_l*9,6,9,_px-_p.dir*2,_py,6,9,_flipx)
   end
  end

  -- todo: draw objs[(_p.y+1)*32+_p.x] here again
 end

 -- draw guards
 for _g in all(guards) do
  if _g.state == 'patrolling' then
   local _dir=0
   if _g.dx == 1 then
    _dir=1
   elseif _g.dy == -1 then
    _dir=2
   elseif _g.dy == 1 then
    _dir=3
   end
   local _frame=0
   if _g.state == 'patrolling' then
    _frame=1
    if tick < alertlvls[alertlvl]/2 then
     _frame=2
    end
   end
   sspr(0+_dir*27+_frame*9,31,9,11,_g.x*4-2,_g.y*4-7)

  elseif _g.state == 'holding' then
   sspr(109,31,7,11,_g.x*4-2,_g.y*4-7)
  end

  -- todo: draw objs[(_p.y+1)*32+_p.x] here again
 end


 -- draw fog
 if devfog == false then
  for _i=0,arslen do
   local _f=fog[_i]
   if _f == nil then
    local _x,_y=_i&31,_i\32
    rectfill(_x*4,_y*4,_x*4+3,_y*4+3,0)
   end
  end
 end

 -- draw messages
 local _coli=1
 if tick%8 >= 4 then
  _coli=2
 end
 for _m in all(msgs) do
  local _hw=#_m.s*2
  local _x=max(min(_m.x*4-_hw,127-_hw*2),0)
  local _y=max(_m.y*4-13,0)
  local _col=msgcols[_m.colset or 1][_coli]
  print(_m.s,_x,_y,_col)
 end

 if devvalues then

  print('upd: '..gupd,0,122-54,11)
  print(' max '..gupdmax,0,122-48,11)
  print('fps: '..stat(7),0,122-42,11) -- note: fps
  -- print(' min '..gfps,0,122-36,11) -- note: fps min
  -- print('sys: '..stat(2),0,122-30,11) -- note: system calls
  -- print(' max '..gsys,0,122-24,11) -- note: system calls max
  print('cyc: '..stat(1),0,122-18,11) -- note: lua calls
  print(' max '..gcyc,0,122-12,11) -- note: lua calls max
  -- print('mem: '..stat(0),0,122-6,11) -- note: memory
  -- print(' max '..gmem,0,122,11) -- note: memory max

  -- gfps=min(gfps,stat(7))
  -- gsys=max(gsys,stat(2))
  gcyc=max(gcyc,stat(1))
  -- gmem=max(gmem,stat(0))
 end
end

gupd=0
gupdmax=0
gmem=0
gcyc=0
gsys=0
gfps=30

initpolice=function()
 local _pt=8
 sfx(16,-2)
 sfx(17)
 palt(0,false)
 palt(15,false)
 palt(11,true)

 _update=function()
  _pt-=1
  if _pt < 0 then
   _pt=64
  end
 end

 _draw=function()
  if _pt%64 >= 32 then
   cls(8)
  else
   cls(12)
  end

  -- draw players
  local _playersbyx=clone(players)
  sortonx(_playersbyx)
  for _i=1,#_playersbyx do
   local _p=_playersbyx[_i]
   local _x=mid(24,_p.x*4,127-24)
   local _y=mid(16,_p.y*4,127-42)
   sspr(89,86,3,10,_x,_y)
   if #_p.loot > 0 then
    sspr(81,86,8,10,_x,_y)
   end

   -- draw officers
   local _dx=1
   local _flipx=true
   if _i%2 == 1 then
    _dx=-1
    _flipx=false
   end
   sspr(92,63,8,11,_x+16*_dx,_y+15,8,11,_flipx)
   sspr(92,63+11,8,11,_x+18*_dx,_y-1,8,11,_flipx)
   sspr(92,63+22,8,11,_x+16*_dx,_y-15,8,11,_flipx)
  end

  -- draw car
  sspr(100,61,28,17,80,107)

  -- todo: add wantedness and draw extra police
  -- todo: draw armored truck for game over
 end
end


__gfx__
f5ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f5f5ccccfff555555fff2511155111525111111551111125ffffffffffffffffffffffffffffffffffffffff5dd55dd5ffffffffffffffffffffffffffffffff
ff5fcc1c5ff511115fff251115511152511d111551555225222222ff222222ff222222ff222222ff222222ff5dd55d15ffffffffffffffffffffffffffffffff
f5ffcc1cf5f511115fff25555555555251111115555552d5255552ff211152ff2dddd2ff2dddd2ff2111d2ff5dd55115ffffffffffffffffffffffffffffffff
f5ffc1cc25251111522225111551115251dd111551111225255552ff211552ff2dddd2ff2dddd2ff211dd2ff5dd55115ffffffffffffffffffffffffffffffff
2222fccf2d255555522255111551115551d11115511112d5255552ff211552ff2dddd2ff2dddd2ff211dd2ff5dd55dd5ffffffffffffffffffffffffffffffff
dddd55552225d5d552225555555555555111111551555225255552ff211552ff28ddd2ff2bddd2ff211dd2ffffffffffffffffffffffffffffffffffffffffff
dddd522522255d5d52522255d15d552255555555555552552d5552ff211552ff25ddd2ff25ddd2ff211dd2ffffffffffffffffffffffffffffffffffffffffff
22225ff522255555522222255555522255ffff5555ffff55255552ff211d52ff2dddd2ff2dddd2ff2115d2ffffffffffffffffffffffffffffffffffffffffff
ffffffff5ffffffffff5552222222255ffffffffffffffff255552ff211552ff2dddd2ff2dddd2ff211dd2ffffffffffffffffffffffffffffffffffffffffff
ffffffff5ffffffffff5ff52222225fffffffffffffffffffffffffffff5fffffffffffffffffffffffdffffffffffffffffffffffffffffffffffffffffffff
ffffffff5ffffffffff5fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f3ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f3f3ccccfff555555fffd5111551115d5222222551111125ffffffffffffffffffffffffffffffffffffffff46744674ffffffffffffffffffffffffffffffff
ff3fcc7c3ff511115fffd5111551115d5226222551444225222222ff222222ff222222ff222222ff222222ff47644714ffffffffffffffffffffffffffffffff
f3ffcc7cf3f511115fffd5555555555d5222222555555265244442ff211142ff266662ff266662ff211162ff46644114ffffffffffffffffffffffffffffffff
f3ffc7cc434511115444d5111551115d5266222551111225244442ff211442ff266662ff266662ff211662ff46744114ffffffffffffffffffffffffffffffff
4444fccf4645555554445511155111555262222551111265244442ff211442ff266662ff266662ff211662ff47644764ffffffffffffffffffffffffffffffff
6666555544456d6d54445555555555555222222551444225244442ff211442ff286662ff2b6662ff211662ffffffffffffffffffffffffffffffffffffffffff
666654454445d6d6545422556d5655225555555555555255294442ff211442ff2d6662ff2d6662ff211662ffffffffffffffffffffffffffffffffffffffffff
44445ff544455555544422255555522255ffff5555ffff55244442ff211942ff266662ff266662ff211d62ffffffffffffffffffffffffffffffffffffffffff
ffffffff2ffffffffff2552222222255ffffffffffffffff244442ff211442ff266662ff266662ff211662ffffffffffffffffffffffffffffffffffffffffff
ffffffff2ffffffffff2ff52222225fffffffffffffffffffffffffffff4fffffffffffffffffffffff6ffffffffffffffffffffffffffffffffffffffffffff
ffffffff2ffffffffff2fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff4ffffffff4fffffffffffffff4ffffffff4ffffffffffffffffff4ffffffff4fffffffffffffffff4ffffffff4fffffffffffffffff4fffffffffffffff
ffff44fffffff44ffffffff4ffffff44fffffff44fffffff4ffffffff44fffffff44ffffffff4ffffffff44fffffff44fffffff4ffffffff44ffffffffffffff
fffff9ffffffff9fffffff44ffffff9ffffffff9ffffffff44ffffffff9ffffffff9fffffff44ffffffff9ffffffff9ffffffff44fffffff9fffffffffffffff
fffff9ffffffff9ffffffff9ffffff9ffffffff9ffffffff9fffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9fffffffffffffff
ffff444ffffff444fffffff9fffff444ffffff444fffffff9ffffffff444ffffff444fffffff9fffffff444ffffff444fffffff9fffffff444ffffffffffffff
fff44444ffff44444fffff444fff44444ffff44444fffff444ffffff44444ffff44444fffff444fffff44444ffff44444fffff444fffff44444fffffffffffff
759f5554f759f555f4fff44444ff4555f9574f555f957f44444fffff45554ffff4555f9fff44444ffff95554ffff9555f9fff44444fff4f555f9ffffffffffff
ffff4449fffff444f9759f5594ff9444ffff9f444fffff4955f957fff4449fffff444fffff45554ffff54449ffff5444fffff95559fff9f444ffffffffffffff
ffff4f4ffffff4f4ffffff444ffff4f4ffffff4f4ffffff444fffffff4f4ffffff4f4ffffff444fffff74f4fffff74f4fffff5444ffffff4f4ffffffffffffff
ffff4f4ffffff444ffffff4f44fff4f4ffffff444fffff44f4fffffff4f4ffffff4ffffffff4f4ffffff4f4ffffffff4fffff74f4ffffff4f4ffffffffffffff
ffff4f4ffffffff4ffffff4ffffff4f4ffffff4ffffffffff4fffffff4f4ffffff4ffffffffff4ffffff4f4ffffffff4ffffff4ffffffff4f4ffffffffffffff
fffff5ffffffff5fffffffffffffff5ffffffff5ffffffffffffffffff5ffffffff5fffffffffffffffff5ffffffff5fffffffffffffffff5fffffff5fffffff
ffff55fffffff55ffffffff5ffffff55fffffff55fffffff5ffffffff55fffffff55ffffffff5ffffffff55fffffff55fffffff5ffffffff55ffffff55ffffff
fffff9ffffffff9fffffff55ffffff9ffffffff9ffffffff55ffffffff9ffffffff9fffffff55ffffffff9ffffffff9ffffffff55fffffff9fffffff9fffffff
fffff9ffffffff9ffffffff9ffffff9ffffffff9ffffffff9fffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9ffffffff9fffffff9fffffff
ffff555ffffff555fffffff9fffff555ffffff555fffffff9ffffffff555ffffff555fffffff9fffffff555ffffff555fffffff9fffffff555fffff555f00fff
fff55555ffff55555fffff555fff55555ffff55555fffff555ffffff55555ffff55555fffff555fffff55555ffff55555fffff555fffff55555ffff55559ffff
759f4445f759f444f5fff55555ff5444f9575f444f957f55555fffff54445ffff5444f9fff55555ffff94445ffff9444f9fff55555fff5f444f9fff445957fff
ffff5549fffff554f9759f4495ff9455ffff9f455fffff5944f957fff4559fffff455fffff54445ffff55549ffff5554fffff94449fff9f554fffff455ffffff
ffff5f5ffffff5f5ffffff554ffff5f5ffffff5f5ffffff455fffffff5f5ffffff5f5ffffff455fffff75f5fffff75f5fffff5554ffffff5f5fffff5f5ffffff
ffff5f5ffffff555ffffff5f55fff5f5ffffff555fffff55f5fffffff5f5ffffff5ffffffff5f5ffffff5f5ffffffff5fffff75f5ffffff5f5fffff5f5ffffff
ffff5f5ffffffff5ffffff5ffffff5f5ffffff5ffffffffff5fffffff5f5ffffff5ffffffffff5ffffff5f5ffffffff5ffffff5ffffffff5f5fffff5f5ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbb88bbbbbbbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb7777788777bbbbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbb777777667777bbbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb1bbbbbbbbbbb7f77777cc777f7bbbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb11bb5bbbddddf777777cc7777f7bbbbbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb9bb5bbbddddd7f77777dd777f7fdddddbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb9bb9bbbddddd7f6666666666f77ddddddb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb11111bbbdddddf649446449446f7dddddd7
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb1111bbb5ddddd64449464449446fdddddd7
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbdddbbbb5d111164444964444944ddddddd5
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb1111bbb511110dd6666d6666666600011d7
ff1fffff1ffff1ffffff0fffff0ffff0ffffffffffffffffffffff0fffffffffffffffffffffffffffffffffffffb1bb1bbb51110166d666d6666666d1110117
ff1fffff1ffff1ffffff0fffff0ffff0fffffffffffffffff0ffff0f0fffffffffffffffffffffffffffffffffff11bb1bbb588110006666d666666d60001115
f111fff1111f111ffff000fff0000f000ffffff00fffffff000ff000ffffffffffffffffffffffffffffffffffffbb1bbbbb511100000666d666666600000115
11111f1111111111ff00000f0000000000fffff00fffffff000ff00fffffffffffffffffffffffffffffffffffffbb11bbbbb51100100666666666660010015b
1111f1111111111fff0000f0000000000fffff0000ffff0f000ff00fffffffffffffffffffffffffffffffffffffbb9bbbbbbbbb00001bbbbbbbbbbb00001bbb
f111fff11111111ffff000fff00000000fffff0000ffff0f000ff000ffffffffffffffffffffffffffffffffffffbb9bbb55bbbbb111bbbbbbbbbbbbb111bbbb
f1f1fff1f1ff1f1ffff0f0fff0f0ff0f0ffff000000ff0000f0f00f0ffffffffffffffffffffffffffffffffffffb111119bbbbddddddddddddddddddbbbbbbb
f1f1fff1f1ff1f1ffff0f0fff0f0ff0f0ffff000000ff000ffffffffffffffffffffffffffffffffffffffffffff1111bbbbbbdddddddddddddd88ddddbbbbbb
f1f1fff1f1ff1f1ffff0f0fff0f0ff0f0fff00f00f00f000ffffffffffffffffffffffffffffffffffffffffffff19ddbbbbbbdddddddddddddd11ddd6dbbbbb
fffffffffffff1fffffffffffffffff1ffffffffffffffffffffff1fffffffffffffffffffffffffffffffffffffb111bbbbbbddddddddddddddddddd76dbbbb
ff1fffff1ffffeffffff1fffff1ffffefffffffffffffffff1ffffefefffffffffffffffffffffffffffffffffffb1b1bbbbbb1dddddddddddddddddd676ddbb
f1e1fff1e22f111ffff1e1fff1e22f111ffffff11fffffff1e1ff111ffffffffffffffffffffffffffffffffffffb1b1bbbbbb1111111111111111111677dddb
11111f111e22111eff11111f111e22111efffffeefffffff111ff11fffffffffffffffffffffffffffffffffffffb1b1bbbbbb110101011010111d555167dddb
1e11fe1e1122111fff1e11fe1e1122111fffff1111ffff1fe1eff11fffffffffffffffffffffffffffffffffffffbbbbbbbbbb1101010110101115d55516dddb
f111fff11122111ffff111fff11122111fffff1111ffffef111ff111fffffffffffffffffffffffffbbbbbbbbebebb1bbbbbbb11010101101011155d5551ddd7
f1f1fff1f1ff1f1ffff1f1fff1f1ff1f1ffff111111ff1111f1f11f1fffffffffffffffffffffffffbbbbbbbb1b1bb11bbbbb5110101011010111111111111d7
f1f1fff1f1ff1f1ffff1f1fff1f1ff1f1ffff111111ff111fffffffffffffffffffffffffffffffffbbbbbbbb111bb9bbbbbb511111111111111111111111115
f1f1fff1f1ff1f1ffff1f1fff1f1ff1f1fff11feef11f111fffffffffffffffffffffffffffffffffbbbbbbbb1e1bb9bbbbbb511110001111111111110001117
fffffffffffffefefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb111b111bbbbb581101110111111111101110117
ff1ffffffffff1f1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb111b1111b5bb581110001111111111110001115
f1e1fffffffff111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb111bdd119b5b511100000111111111100000115
11111ffffff001e1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbb1b1b111bbbbbb5550010055555555550010055b
15151fffff000111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbb221b1b1bb1bbbbbbbb00001bbbbbbbbbb00001bbb
f151fffffffff111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbb2221b111bb1bbbbbbbbb111bbbbbbbbbbbb111bbbb
f1f1fffffffff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1fffffff221f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffff2221f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111fffffffff1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd22200000111122220202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd00000000111122222020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b333ffffdddd02220000111122220202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd00000000111122222020ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffffdddd22021111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
333bffff666644451111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff666655551111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3bb3ffff666654441111dddd0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff66665555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff66664454ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffff4ff4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888fffff551155fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888ffff5ffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888ffffff8ff8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
111ffffff551155fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
111fffff5ffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
777fffffffbffbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
777ffffff551155fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbfffff5ffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__sfx__
000100000c030110200c0100201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018030190200c0100201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002900001404013040110000f000070001b0001800016000160001300016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000050100a0200f020180201f0202e0201f00030020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001300000f0300f0000f00000000000000f0000f0000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002702000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002f00000c3300c3000c320003000c330003000c320003000c330003000c320003000c3300c3000c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000500001d76000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001b73000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
018001051d711257111d711257111d711007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01800000257711d771257711d77100700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
010800000473000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010800000072000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
