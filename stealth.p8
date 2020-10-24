pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- sneaky stealy

-- notes:
-- - any _i is the position, where the part before *32 is the y-axis, and the the one after *32+ is the x-axis
-- - local _x,_y=_i&31,_i\32

--[[

- filing drawers
 - search (up/down?)

- bug if suspect seen and caught same tick (came out of hiding for ex)

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

- cabinet
 - search (how? just open?)

- fix generic loot sound
 - play in player loots
 - remove from action functions

- table???
 - hide under

- busting out of jail???

- window broken glass

- names: johnny, jimmy, tommy, timmy, benny, lenny, ray, jay, donny, sonny, fred, ted, zed, tony, vince, roy

--]]

cartdata'ironchestgames_sneakystealy_v1_dev2'


printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end






-- s2t usage:
-- t=s2t'1;2;3;4;5;6;7;hej pa dig din gamle gries;'
-- t=s2t'.x;1;.y;2;'
function s2t(s)
 local _t,_i,_s,_d={},1,''
 repeat
  _d,s=sub(s,1,1),sub(s,2)
  if _d != ';' then
   _s=_s.._d
  else
   if sub(_s,1,1) != '.' then
    _s=tonum(_s) or _s
   end
   _t[_i]=_s
   if (_s == '') _t[_i]=nil
   _i+=1
   _s=''
  end
 until #s == 0
 for _i=2,#_t,2 do
  local _tib=_t[_i-1]
  if sub(tostr(_tib),1,1) == '.' then
   _s=sub(_tib,2)
   _s=tonum(_s) or _s
   _t[_s],_t[_i-1],_t[_i]=_t[_i]
  end
 end
 return _t
end

local floorlightcols=s2t'.0;1;.1;13;.2;2;'

local arslen=32*32-1 -- todo: 1023

local adjdeltas=s2t'.0;-1;.1;1;.2;-32;.3;32;'

local fogdirs={
 s2t'.x;1;.y;0;.dx;1;.dy;1;',
 s2t'.x;1;.y;0;.dx;1;.dy;-1;',
 s2t'.x;-1;.y;0;.dx;-1;.dy;1;',
 s2t'.x;-1;.y;0;.dx;-1;.dy;-1;',
 s2t'.x;0;.y;1;.dx;1;.dy;1;',
 s2t'.x;0;.y;1;.dx;-1;.dy;1;',
 s2t'.x;0;.y;-1;.dx;1;.dy;-1;',
 s2t'.x;0;.y;-1;.dx;-1;.dy;-1;',
}

local windowpeekdys=s2t'-64;-32;0;32;'

local guardsholdingdeltas=s2t'-65;-64;-63;-34;-33;-32;-31;-30;-2;-1;0;1;2;30;31;32;33;34;63;64;65;'
local guarddxdeltas=s2t'.0;1;.1;-1;.2;0;.3;0;'
local guarddydeltas=s2t'.0;0;.1;0;.2;1;.3;-1;'

local camcontrolscreenpos={
 s2t'.x;-2;.y;-4;',
 s2t'.x;3;.y;-4;',
 s2t'.x;-2;.y;-1;',
 s2t'.x;3;.y;-1;',
}

local tick=0

local msgs
local msgcols={s2t'6;13;',s2t'9;10;'}

local floor
local objs
local light={}
local fog={}
local cameras={}

local alertlvl=1
local alertlvls=s2t'24;8;' -- note: only tick time
local policet=0

local players
local escapedplayers={}
local playerinventory={}

local guards

local seli=1
local ispoweron
local mapthings

local initpolice
local initstatus
local initsplash

-- init light
for _i=0,arslen do
 light[_i]=0
end


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

local function clone(_t)
 local _tc={}
 for _k,_v in pairs(_t) do
  _tc[_k]=_v
 end
 return _tc
end

local function sortonx(_t)
 for _i=1,#_t do
  local _j=_i
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
 local _i=_a.y*32+_a.x
 for _j=0,3 do
  if floor[_i+adjdeltas[_j]] == 2 then
   return _j
  end
 end
 -- return nil
end



local function playerloots(_p,_o)
 local _m='(nothing of value)'
 if _o.loot then
  _m=_o.loot[1]
  if _o.loot[2] then -- has value, then it's a thing, take it
   add(_p.loot,_o.loot)
  else
   add(playerinventory,_o.loot) -- no value, it's information
  end
 end
 add(msgs,{x=_p.x,y=_p.y-1,s=_m,t=40})
 _o.loot=nil
end





local function setalertlvl2(_m,_x,_y)
 if alertlvl == 1 then
  sfx(21)
  alertlvl,tick,policet=2,60,90
  local _i=0
  for _g in all(guards) do
   add(msgs,{x=_g.x,y=_g.y,s=_m,delay=_i*15,colset=2})
   _i+=1
   _g.state='patrolling'
   _g.state_c=0
  end
  add(msgs,{x=_x,y=_y,s=_m,colset=2})
 end
end


local function makesound(_p,_sfx)
 sfx(_sfx)
 for _g in all(guards) do
  local _dx,_dy=_g.x-_p.x,_g.y-_p.y
  local _h=sqrt(_dx*_dx+_dy*_dy)
  if _h < 6 then
   local _newdir=flr(rnd(4))
   _g.dx=guarddxdeltas[_newdir]
   _g.dy=guarddydeltas[_newdir]
   local _m='!'
   if alertlvl == 1 then
    _g.state='listening'
    _g.state_c+=flr(rnd(5))+3
    _m='?'
   end
   add(msgs,{x=_g.x,y=_g.y,s=_m,colset=2,t=30})
  end
 end
end




local function computer(_p,_o,_tmp)
 _p.workingstate='hacking'
 if ispoweron then
  if not _tmp.action_c then
   _tmp.seq,_tmp.action_c,_tmp.state={},0,'booting'
   makesound(_p,11)
   local _l=14
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
   makesound(_p,12)
  end

  if _tmp.state == 'ready' then
   local _input
   if btnp(0,_p.i) then
    _input=0
   elseif btnp(1,_p.i) then
    _input=1
   elseif btnp(2,_p.i) then
    _input=2
   end

   if _input then
    if _input == _tmp.seq[1] then
     del(_tmp.seq,_input)
     if #_tmp.seq == 0 then
      _tmp.state='success'
      makesound(_p,10)
      playerloots(_p,_o)
     end
    else
     _tmp.state='fail'
     makesound(_p,9)
    end
   end
  end

 else
  _tmp.action_c,_o.draw=nil
 end

 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'
 end
end


-- states:
-- 0 - off
-- 1 - on
-- 2 - selected/on (camcontrol)
-- 3 - system alarm (camcontrol) (not used)
local function camcontrol(_p,_o,_tmp)
 _p.workingstate='hacking'
 if ispoweron then
  if not _tmp.sel then
   _tmp.sel,_tmp.pos=1,camcontrolscreenpos

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
     sspr(0,120+_p.state*2,3,2,_tmp.ox*4+_p.x,_tmp.oy*4+_p.y)
    end
   end

   makesound(_p,11)
  end

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
   for _i=1,4 do
    _tmp.pos[_i].state=1
   end
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

  local _count=0
  for _p in all(_tmp.pos) do
   if _p.state == 0 then
    _count+=1
   end
  end

 else
  _tmp.sel,_o.draw=nil
 end

 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'

  -- reset all cameras
  if _tmp.pos then
   for _i=1,4 do
    _tmp.pos[_i].state=1
    local _c=cameras[_i]
    if _c then
     _c.state=1
    end
   end
  end
 end
end


local function safe(_p,_o,_tmp)
 _p.workingstate='cracking'
 if not _o.isopen then

  -- generate new code
  if not _o.code then
   _o.code={}
   for _i=1,5 do
    add(_o.code,flr(rnd(8))+1)
   end
  end

  -- reset for this try
  if not _tmp.code then
   _tmp.code,_tmp.codei,_tmp.codetick,_tmp.unlocked=_o.code,1,0

   _o.draw=function()
    local _x,_y=_tmp.ox*4+5,_tmp.oy*4-3
    if _tmp.iserror then
     pset(_x,_y,8)
    elseif _tmp.unlocked and not _o.isopen then
     pset(_x,_y,11)
    end
   end
  end

  local _dir=_tmp.codei%2
  for _i=0,1 do
   if btnp(_i,_p.i) then
    local _snd
    if _dir == _i then
     _tmp.codetick+=1
     if _tmp.codetick == _tmp.code[_tmp.codei] and not _tmp.iserror then
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
    if not _snd then -- todo: token hunt, maybe order sfx so you can do sfx(14+_sfxi)
     sfx(15) -- click
    end
   end
  end

  if _tmp.unlocked and btnp(2,_p.i) then
   _o.isopen=true
   objs[_tmp.oi].typ+=2
   objs[_tmp.oi+1].typ+=2
   makesound(_p,10) -- creek open
   playerloots(_p,_o)
  end
 end
 
 if btnp(3,_p.i) then
  -- reset player and obj
  _p.state,_p.action,_o.draw='standing'
 end

end



local function resetdoor(_p,_o)
 -- reset player
 _p.state,_p.action='standing'

 -- reset obj
 _o.typ-=2
end

local function doorfromunder(_p,_o,_tmp)
 if not _tmp.opened then
  _o.typ+=2
  _tmp.opened=true
  makesound(_p,23)
 end

 if light[(_tmp.oy-2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!',_tmp.ox,_tmp.oy)
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
 if not _tmp.opened then
  _tmp.o2=objs[_tmp.oi+32]
  _tmp.o2.typ+=2
  _tmp.opened=true
  makesound(_p,23)
 end

 if light[(_tmp.oy+2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!',_tmp.ox,_tmp.oy)
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2,32 do
  local _i=_y*32+_tmp.ox
  fog[_i]=0
  if floor[_i] == 2 then
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
 local _i=_tmp.oy*32+_tmp.ox
 fog[_i+32]=0
 fog[_i+64]=0
end


local function lockeddoorfrombelow(_p,_o,_tmp)
 if ispoweron then
  if _o.typ == 16 then
   for _l in all(playerinventory) do
    if _l[1] == 'door access code' then
     _o.typ+=2
     _p.state,_p.action='standing'
     makesound(_p,24)
     return
    end
   end
   makesound(_p,25)
   _p.state,_p.action='standing'
   return
  end

  if not _tmp.opened then
   _o.typ+=2
   _tmp.opened=true
   makesound(_p,23)
  end

  if light[(_tmp.oy-2)*32+_tmp.ox] == 1 then
   setalertlvl2('intruder alert!',_tmp.ox,_tmp.oy)
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

 else
  _p.state,_p.action='standing'
 end
end

local function lockeddoorfromabove(_p,_o,_tmp)
 local _o2=objs[_tmp.oi+32]
 if _o2.typ == 16 then
  for _l in all(playerinventory) do
   if _l[1] ==  'door access code' then
    _o2.typ+=2
    _p.state,_p.action='standing'
    makesound(_p,24)
    return
   end
  end
  makesound(_p,25)
  _p.state,_p.action='standing'
  return
 end

 if not _tmp.opened then
  _o2.typ+=2
  _tmp.opened=true
  makesound(_p,23)
 end

 if light[(_tmp.oy+2)*32+_tmp.ox] == 1 then
  setalertlvl2('intruder alert!',_tmp.ox,_tmp.oy)
 end

 fog[(_tmp.oy+1)*32+_tmp.ox]=0
 for _y=_tmp.oy+2,32 do
  local _i=_y*32+_tmp.ox
  fog[_i]=0
  if floor[_i] == 2 then
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


local function fusebox(_p,_o,_tmp)
 _o.typ,_p.workingstate,ispoweron=25,'cracking'
 if not _tmp.tick then
  _tmp.tick=0

  _o.draw=function()
   local _col=0
   if _tmp.tick%12 > 6 then
    _col=9
   end
   if ispoweron then
    _col=11
   end
   pset(_tmp.ox*4+3,_tmp.oy*4,_col)
  end
 end

 _tmp.tick+=1

 if btn(3,_p.i) then
  -- reset player and obj and ispoweron
  ispoweron,_p.state,_o.typ,_p.action,_o.draw=true,'standing',24
 end
end


local function getwindowpeekfunc(_startoff,_end,_di)
 return function(_p,_o)
  for _dy in all(windowpeekdys) do
   local _y=_p.y*32+_dy
   for _x=_p.x+_startoff,_end,_di do
    fog[_y+_x]=0
    if floor[_y+_x] == 2 then
     break
    end
   end
  end
 end
end

local function getbreakwindowfunc(_xmod)
 return function(_p,_o)
  if _o.typ == 22 then
   _o.typ+=1
   makesound(_p,22)
  elseif _o.typ == 23 then
   _p.x+=2*_xmod
  end

  -- reset player
  _p.state,_p.action='standing'
 end
end

local function soundaction(_p)
 makesound(_p,0)
  _p.state,_p.action='standing'
end



local function newwindow()
 return {
  typ=22,
  action={[0]=getbreakwindowfunc(-1),[1]=getbreakwindowfunc(1)},
  adjaction={[0]=getwindowpeekfunc(-2,0,-1),[1]=getwindowpeekfunc(2,32,1)},
 }
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












function mapgen()
 floor,objs,guards,cameras,mapthings,ispoweron={},{},{},{},{},true
 local computercount=0

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
  floor[_i]=0
 end

 local function floorcount(_x,_y)
  local _c,_i=0,_y*32+_x
  for _j=0,3 do
   if floor[_i+adjdeltas[_j]] == 1 then
    _c+=1
   end
  end
  return _c
 end

 -- add rooms
 local _xmin,_ymin,_ystart=2,3,3

 repeat
  local _w,_h=flr(rnd(19))+10, flr(rnd(5))+6
  local _xstart=2+flr(rnd(28-_w))

  for _y=0,_h-1 do
   for _x=0,_w-1 do
    local _i=(_ystart+_y)*32+_xstart+_x
    if _y == 0 or _y == _h-1 or _x == 0 or _x == _w-1 then
     floor[_i],floor[(_ystart+_y-1)*32+_xstart+_x]=2,2
    else
     floor[_i]=1
    end
   end
  end

  -- add window
  local _xoff=0
  if rnd() > 0.5 then
   _xoff=_w-1
  end
  objs[(_ystart+2+flr(rnd(_h-5)))*32+_xstart+_xoff]=newwindow()

  -- add top door
  objs[_ystart*32+_xstart+2+flr(rnd(_w-5))]={
   typ=12,
   action={[2]=doorfromunder},
   adjaction={[2]=doorpeekfromunder}
  }

  -- add camera
  local _c={x=_xstart+1,y=_ystart+1,state=1}
  if rnd() < 0.5 then
   _c.x=_xstart+_w-2
  end

  if rnd() > 0.5 then
   if rnd() > 0.8 then
    _c.state=0
   end
   add(cameras,_c)
  end

  -- add guard
  local _gx,_gy=flr(_xstart+_w/2),flr(_ystart+_h/2)
  if _h > 6 and #guards < 3 and rnd() > 0.5 then
   local _g=s2t'.dx;-1;.dy;0;.state;patrolling;.state_c;0;'
   _g.x,_g.y=_gx,_gy
   add(guards,_g)
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
 local _w,_h=flr(rnd(5))+6, flr(rnd(18))+10
 local _xstart,_ystart=2+flr(rnd(28-_w)),3

 for _y=0,_h-1 do
  for _x=0,_w-1 do
   local _i=(_ystart+_y)*32+_xstart+_x
   local _fc=floorcount(_xstart+_x,_ystart+_y)
   if _y == 0 or _y == _h-1 then
    floor[(_ystart+_y)*32+_xstart+_x],floor[(_ystart+_y-1)*32+_xstart+_x]=2,2
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

 -- add outside fusebox
 local _fbi=(_ystart+_h-1)*32+_xstart+2
 if rnd(0.3) and floor[_fbi+32] != 2 then
  local _o={typ=24,shadow={},action={[2]=fusebox}}
  objs[_fbi]=_o
 end

 -- fix cameras
 for _j=#cameras,1,-1 do
  local _c=cameras[_j]
  local _i=_c.y*32+_c.x
  if objs[_i-31] or
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
   local _i,_remove=_y*32+_x
   for _c in all(cameras) do
    if _c.x == _x and _c.y == _y or adjacency(_c.x,_c.y,_x,_y) then
     _remove=true
     break
    end
   end
   if (not _remove) and
      objs[_i-32-1] == nil and -- todo: token hunt?
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

 local _types=s2t'0;1;2;8;'

 if #cameras > 0 then
  add(_types,5)
 end

 for _i in all(_pos) do
  local _typ=_types[flr(rnd(#_types))+1]
  if _typ == 8 or _typ == 5 then
   del(_types,_typ)
  end

  local _o={typ=_typ,shadow={[0]=true,true}}
  objs[_i]=_o

  if _typ == 2 then
   _o.shadow={[0]=true}
   objs[_i+1]={
    typ=3,
    action={[2]=computer},
    loot=shuffle({nil,nil,
     {'door access code'},
     {'blueprint'},
     {'company secrets',flr(rnd(1000))},
     {'classified files',flr(rnd(2000))},
     })[1],
    shadow={},
   }
   objs[_i+2]={typ=4,shadow={true}}

   computercount+=1
   if computercount == 2 then
    add(mapthings,'hackable computers')
   end

  elseif _typ == 5 then
   _o.shadow={[0]=true}
   objs[_i+1]={typ=6,action={[0]=soundaction,[2]=camcontrol},shadow={}}
   objs[_i+2]={typ=7,shadow={true}}

  elseif _typ == 8 then
   _o.shadow={[0]=true}
   _o.action={[1]=soundaction,[2]=safe}
   local _c=flr(rnd(1000)+500)
   _o.loot=shuffle({
    {'a little cash',flr(rnd(600))},
    {'some cash',_c},
    {'some cash',_c},
    {'some cash',_c},
    {'some cash',_c},
    {'good cash',flr(rnd()+rnd()+2)*100},
    {'classified docs',flr(rnd()+rnd()+rnd()+rnd())*200},
    {'gold bars',flr(((rnd()+rnd()+rnd())/3)*3000)},
    {'diamonds',flr(((rnd()+rnd()+rnd())/3)*10000)},
   })[1]

   objs[_i+1]={typ=9,shadow={true}}

   add(mapthings,'crackable safe')
  end
 end

 -- add plants and watercoolers vertically
 for _x=2,29 do
  for _j=1,3 do
   local _y=flr(rnd(29))+2
   local _i=_y*32+_x
   if objs[_i] == nil and
      objs[_i-32] == nil and
      objs[_i-1] == nil and
      objs[_i+1] == nil and
      objs[_i+32] == nil and
      floor[_i] == 1 and
      floor[_i-32] == 1 and
      floor[_i+32] == 1 and
      (floor[_i+1] == 1 or floor[_i-1] == 1) and
      (floor[_i+1] == 2 or floor[_i-1] == 2) then
    local _typ=flr(rnd(2))
    local _o={typ=_typ,shadow={[2]=true,[3]=true}}
    objs[_i]=_o
   end
  end
 end


 -- fix objs
 for _i=0,arslen do
  local _o=objs[_i]
  if _o then
   _o.light={}

   _o.action=_o.action or {
    [0]=soundaction,
    [1]=soundaction,
    [2]=soundaction,
    [3]=soundaction,
   }

   -- remove windows
   if _o.typ == 22 then
    if not (floor[_i] == 2 and floor[_i-1] != 2 and floor[_i+1] != 2) then
     objs[_i]=nil
    end

   -- fix doors
   elseif _o.typ == 12 then
    if objs[_i+1] or not (floor[_i] == 2 and floor[_i-1] == 2 and floor[_i+1] == 2 and floor[_i+32] != 2 and floor[_i-64] != 2) then
     objs[_i]=nil
    else
     objs[_i-32]={action={[3]=doorfromabove},adjaction={[3]=doorpeekfromabove}}
     objs[_i+1]={typ=13}

     -- switch to locked
     if rnd() > 0.70 then
      objs[_i].typ=16
      objs[_i].action[2]=lockeddoorfrombelow

      objs[_i-32].action[3]=lockeddoorfromabove

      objs[_i+1].typ=17
     end
    end
   end
  end
 end

 if #cameras > 1 then
  add(mapthings, 'many cameras')
 end

 if #guards > 1 then
  add(mapthings, 'many guards')
 end

end











local function gameinit()
 -- set auto-repeat delay for btnp
 poke(0x5f5c,5)
 msgs,tick,alertlvl={},0,1
 local _playwalksfx
 _update=function()
  tick-=1

  -- reset fog
  fog={}

  -- update players
  for _p in all(players) do

   -- switch player control
   if btnp(4) then
    _p.i=_p.i^^1
   end
   if (btnp(4) or btnp(5)) and _p.i == 0 then
    add(msgs,{x=_p.x,y=_p.y,s='.',t=15})
   end

   -- input
   if _p.state == 'working' then
    local waspoweron=ispoweron
    _p.workingstate='hacking'
    _p.action()

    -- update from ispoweron
    if ispoweron and not waspoweron then
     for _c in all(cameras) do
      _c.state=1
     end
    elseif waspoweron and not ispoweron then
     for _c in all(cameras) do
      _c.state=0
     end

     for _i=0,arslen do
      local _o=objs[_i]
      if _o and _o.typ == 18 then
       _o.typ=16
      end
     end
    end

   else
    _p.dx,_p.dy=0,0
    if btnp(0,_p.i) then
     _p.dx,_p.dir=-1,0
    elseif btnp(1,_p.i) then
     _p.dx,_p.dir=1,1
    elseif btnp(2,_p.i) then
     _p.dy=-1
    elseif btnp(3,_p.i) then
     _p.dy=1
    end
    local _nextx,_nexty,_otherp=_p.x+_p.dx,_p.y+_p.dy,players[1]
    if _otherp == _p then
     _otherp=players[2]
    end
    if _otherp and _nextx == _otherp.x and _nexty == _otherp.y then
     makesound(_p,20)
    else
     if _nextx > 31 or _nextx < 0 or _nexty > 31 or _nexty < 0 then
      add(escapedplayers,del(players,_p))
      add(msgs,{x=_p.x,y=_p.y,s='escaped',t=30})

      if #players <= 0 then
       initstatus()
       return
      end
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
        local _i,_pwa,_hiding=_p.y*32+_p.x, walladjacency(_p)
        for _a=0,3 do
         local _oi=_i+adjdeltas[_a]
         local _o=objs[_oi]
         if _o then
          local _ox,_oy=_oi&31,_oi\32
          local _a,_owa=adjacency(_p.x,_p.y,_ox,_oy), walladjacency{x=_ox,y=_oy}
          if _o.shadow and _o.shadow[_a] and _owa and _pwa and _a and light[_i] == 0 then
           _p.state,_p.adjacency,_hiding='hiding',_a,true
          end
         end
        end
        if not _hiding then
         _p.state='standing'
        end
       end

      end
     end
    end
   end

   -- if one square from guard, get caught
   for _g in all(guards) do
    local _dx,_dy=_p.x-_g.x,_p.y-_g.y
    if (_p.state != 'hiding' or light[_p.y*32+_p.x] == 1) and _p.state != 'caught' and abs(_dx) <= 1 and abs(_dy) <= 1 then
     _p.state='caught'
     setalertlvl2('suspect caught!',_g.x,_g.y)
     _g.state='holding'
    end
   end
  end

  if tick <= 0 then

   -- update guards
   for _g in all(guards) do

    -- handle state
    if _g.state == 'standing' then
    -- todo: remove??
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
     local _gwa=walladjacency{x=_g.x+_g.dx,y=_g.y+_g.dy} -- todo: do this better
     _g.x+=guarddxdeltas[_gwa] or _g.dx
     _g.y+=guarddydeltas[_gwa] or _g.dy

    elseif _g.state == 'holding' then
     -- is holding suspect

    elseif _g.state == 'listening' then
     _g.state_c-=1

     if _g.state_c <= 0 or _g.state_c % 10 == 1 then
      local _newdir=flr(rnd(4))
      _g.dx=guarddxdeltas[_newdir]
      _g.dy=guarddydeltas[_newdir]
      _g.state='patrolling'
     elseif _g.state_c > 30 then
      setalertlvl2('heard someone!',_g.x,_g.y)
     end
    end
   end

   -- set new tick
   _playwalksfx=not _playwalksfx
   if _playwalksfx then
    if alertlvl == 2 then
     sfx(18)
    else
     sfx(19)
    end
   end
   if alertlvl == 2 and policet > 0 then
    policet-=1
    if policet == 64 then
     sfx(16)
    end
    if policet <= 0 then
     local _f
     if #players == 1 then
      _f=function()
       add(escapedplayers[1].loot,{'bail',-2000}) -- todo: base on wantedness
       initstatus()
      end
     end
     initpolice(_f)
    end
   end
   tick=alertlvls[alertlvl]
  end

  -- update messages
  for _m in all(msgs) do
   if not _m.t then
    _m.t=90
   end
   if _m.delay then
    _m.delay-=1
    if _m.delay < 0 then
     _m.delay=nil
    end
   else
    _m.t-=1
    if _m.t <= 0 then
     del(msgs,_m)
    end
   end
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
  -- todo: token hunt???
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
     local _bydown,_bldown=_by,1
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

     local _bxside,_blside=_bx,1
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
     _lside,_ldown=_blside-2,_bldown-2
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
    for _i=1,-1,-2 do
     local _x,_y,_l=_g.x+_g.dx,_g.y+_g.dy,32
     while floor[_y*32+_x] != 2 do
      local _c,_bx,_by=0,_x,_y
      while floor[_by*32+_bx] != 2 and _c <= _l do
       local _o=objs[_by*32+_bx]
       if _o then
        add(_o.light,{x=0,y=-(_i)})
        add(_o.light,{x=-_g.dx,y=0})
       end
       light[_by*32+_bx]=1
       _bx+=_g.dx
       _by+=_i
       _c+=1
      end
      _l=_c-1
      _x+=_g.dx
     end
    end

   elseif _g.dy != 0 then

    for _i=1,-1,-2 do
     local _x,_y,_l=_g.x+_g.dx,_g.y+_g.dy,32
     while floor[_y*32+_x] != 2 do
      local _c,_bx,_by=0,_x,_y
      while floor[_by*32+_bx] != 2 and _c <= _l do
       local _o=objs[_by*32+_bx]
       if _o then
        add(_o.light,{x=0,y=-_g.dy})
        add(_o.light,{x=-(_i),y=0})
       end
       light[_by*32+_bx]=1
       _bx+=_i
       _by+=_g.dy
       _c+=1
      end
      _l=_c-1
      _y+=_g.dy
     end
    end
   end
  end

  -- add shadow around objects
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.shadow then
    for _j=0,3 do
     if _o.shadow[_j] then
      light[_i+adjdeltas[_j]]=0
     end
    end

    local _ox,_oy=_i&31,_i\32
    for _l in all(_o.light) do
     light[(_oy+_l.y)*32+_ox+_l.x]=1
    end
   end
  end


  for _i=0,arslen do

   -- light up walls
   if light[_i+32] == 1 and
      floor[_i] == 2 and
      floor[_i+32] != 2 then
    light[_i]=1
   end

   -- light up windows
   local _o=objs[_i]
   if _o and (_o.typ == 22 or _o.typ == 23) and
      (light[_i-1] == 1 or light[_i+1] == 1) then
    light[_i]=1
    if _o.typ == 23 then
     setalertlvl2('broken window!',_i&31,_i\32)
    end
   end
  end

  -- intruder alert
  if alertlvl == 1 then
   for _p in all(players) do
    if light[_p.y*32+_p.x] == 1 then
     setalertlvl2('intruder alert!',_p.x,_p.y)
    end
   end
   for _i=0,arslen do
    local _o=objs[_i]
    if _o and _o.typ == 10 and light[_i] == 1 then
     setalertlvl2('safe opened!',_i&31,_i\32)
    end
   end
  end




  -- remove fog
  for _p in all(players) do
   if _p.state != 'caught' then
    for _d in all(fogdirs) do
     local _x,_y,_l=_p.x,_p.y,32
     while floor[_y*32+_x] != 2 and floor[_y*32+_x] do
      local _c,_bx,_by=0,_x,_y
      while _by < 32 and
            _by >= 0 and
            _bx < 32 and
            _bx >= 0 and
            floor[_by*32+_bx] != 2 and
            floor[_by*32+_bx] and
            _c <= _l do
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

 _draw=function()
  if alertlvl == 2 and policet <= 64 then
   if policet%8 >= 4 then
    pal(0,8)
   else
    pal(0,12)
   end
  end

  for _i=arslen,0,-1 do

   -- draw floor
   local _tile,_l,_x,_y=floor[_i],light[_i],_i&31,_i\32
   local _sx,_sy,_col=_x*4,_y*4,_tile

   if _l == 1 then
    _col=floorlightcols[_col]
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
  rect(0,0,127,127,1)
  fillp()

  pal()
  palt(0,false)
  palt(15,true)

  -- draw objs
  for _i=0,arslen do
   local _o=objs[_i]
   if _o and _o.typ then
    local _x,_y,_l=_i&31,_i\32,light[_i]
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
   if floor[_c.y*32+_c.x+1] == 2 then
    _sx=12
   end
   sspr(_sx,116+_c.state*3,4,3,_c.x*4,_c.y*4-4)
  end

  -- draw players
  for _p in all(players) do
   local _i=_p.y*32+_p.x
   local _l,_floor,_px,_py=light[_i],floor[_i],_p.x*4,_p.y*4-5
   if _p.state == 'hiding' then
    sspr(46+_p.adjacency*4,72,4,9,_px,_py)
   elseif _p.state == 'working' then
    if _p.workingstate == 'hacking' then
     sspr(12+_floor*23,72+_l*9,5,9,_px,_py)
    elseif _p.workingstate == 'cracking' then
     sspr(17+_floor*23,72+_l*9,5,9,_px,_py)
    end
    if #_p.loot > 0 then
     sspr(5,91+_l*4,8,4,_px,_py+5)
    end
   elseif _p.state == 'caught' then
    sspr(0,90,6,9,_px,_py)
   else
    local _flipx=_p.dir == 1
    if #_p.loot > 0 then
     sspr(6+_floor*23,72+_l*9,6,9,_px-_p.dir*2,_py,6,9,_flipx)
    else
     sspr(0+_floor*23,72+_l*9,6,9,_px-_p.dir*2,_py,6,9,_flipx)
    end
   end

   local _o=objs[_i+32]
   if _o and _o.typ then
    local _l=light[_i+32]
    sspr(_o.typ*4,_l*13,4,13,_px,_py+4)
   end
  end

  -- draw guards
  for _g in all(guards) do
   local _dir=0
   for _j=1,3 do
    if adjdeltas[_j] == _g.dy*32+_g.dx then
     _dir=_j
    end
   end
   if _g.state == 'patrolling' then
    local _frame=2
    if tick < alertlvls[alertlvl]/2 then
     _frame=1
    end
    sspr(_dir*27+_frame*9,31,9,11,_g.x*4-2,_g.y*4-7)

   elseif _g.state == 'holding' then
    sspr(109,31,7,11,_g.x*4-2,_g.y*4-7)

   elseif _g.state == 'listening' then
    sspr(_dir*27,31,9,11,_g.x*4-2,_g.y*4-7)
   end
  end


  -- draw fog
  for _i=0,arslen do
   if not fog[_i] then
    local _x,_y=(_i&31)*4,(_i\32)*4
    rectfill(_x,_y,_x+3,_y+3,0)
   end
  end

  -- draw messages
  local _coli=1
  if tick%8 >= 4 then
   _coli=2
  end
  for _m in all(msgs) do
   if _m.delay == nil then
    local _hw=#_m.s*2
    local _x,_y,_col=max(min(_m.x*4-_hw,127-_hw*2),0), max(_m.y*4-13,0), msgcols[_m.colset or 1][_coli]
    print(_m.s,_x,_y,_col)
   end
  end
 end
end













initpolice=function(_onpress)
 sfx(16,-2)
 sfx(17)
 palt(0,false)
 palt(15,false)
 palt(11,true)

 _update=function()
  if btnp(4) then
   if _onpress then
    _onpress()
   else
    dset(61,0)
    initsplash()
   end
  end
 end

 _draw=function()
  if flr(t())%2 == 1 then
   cls(8)
  else
   cls(12)
  end

  -- draw players
  local _playersbyx=clone(players)
  sortonx(_playersbyx)
  for _i=1,#_playersbyx do
   local _p=_playersbyx[_i]
   local _x,_y=mid(24,_p.x*4,127-24), mid(16,_p.y*4,127-42)
   sspr(89,86,3,10,_x,_y)
   if #_p.loot > 0 then
    sspr(81,86,8,10,_x,_y)
   end

   -- draw officers
   local _dx,_flipx=-1,_i%2 == 1
   if _flipx then
    _dx=1
   end
   local _tmp=_x+16*_dx
   sspr(92,63,8,11,_tmp,_y+15,8,11,_flipx)
   sspr(92,74,8,11,_x+18*_dx,_y-1,8,11,_flipx)
   sspr(92,85,8,11,_tmp,_y-15,8,11,_flipx)
  end

  -- draw police car
  sspr(100,61,28,17,80,104)

  -- draw armored truck for game over
  if not _onpress then
   sspr(100,78,28,18,15,102)
   print('caught!  \x8e to start over',16,122,10)
  end

 end
end










local function initmapselect()
 poke(0x5f5c,-1)
 palt()
 srand(dget(61)+seli)
 mapgen()
 local _reconcost
 _update=function()
  local _cash,_nextbuyi,_oldseli=dget(62),dget(63),seli
  _reconcost=flr(_nextbuyi*8)
  if btnp(1) then
   seli+=1
  elseif btnp(0) then
   seli-=1
  end
  seli=min(seli,60)
  if seli != _oldseli then
   seli=mid(1,seli,_nextbuyi)
   srand(dget(61)+seli)
   mapgen()
  end
  if btnp(2) or btnp(4) then
   if seli == _nextbuyi then
    if _cash >= _reconcost then
     _cash-=_reconcost
     dset(62,_cash)
     dset(63,_nextbuyi+1)
    end
   elseif dget(seli) != 1 then
    dset(seli,1)
    gameinit()
   end
  end
 end

 _draw=function()
  local _cash,_nextbuyi=dget(62),dget(63)
  cls()
  rectfill(0,0,46,6,3)
  print('$'.._cash,2,1,11)
  rectfill(15,15,114,104,5)
  if seli > 1 then
   spr(243,9,54)
  end
  if seli < _nextbuyi then
   spr(242,117,54)
  end

  print('hit target '..seli,19,18,15)
  if seli == _nextbuyi then
   local _col=8
   if _cash >= _reconcost then
    _col=11
    spr(226,61,104)
   end
   print('pay scout $'.._reconcost,28,37,_col)
  elseif dget(seli) == 1 then
   print('(already visited)',28,37,6)
  else
   print('scouted:',28,37,6)
   for _i=1,#mapthings do
    print(mapthings[_i],28,37+_i*7,7)
   end
   if #mapthings == 0 then
    print('(not much)',28,44,7)
   end
   spr(226,61,104)
  end
 end
end








initstatus=function(_msg)
 sfx(16,-2)
 sfx(17,-2)
 poke(0x5f5c,-1)
 local _rows={{'ingoing',dget(62)}}
 for _p in all(escapedplayers) do
  for _l in all(_p.loot) do
   add(_rows,_l)
  end
 end
 add(_rows,{'daily expenses',-80})
 local _cash=0
 for _r in all(_rows) do
  _cash+=_r[2]
 end
 dset(62,_cash)

 for _p in all(escapedplayers) do
  _p.i,_p.loot,players[_p.origi+1]=_p.origi,{},_p
 end

 -- init msg
 _msg=_msg or ''
 if dget(62) < 0 then
  _msg='no cash! \x8e to start over'
 end

 -- init players
 players={{},{}}
 for _i=1,2 do
  players[_i]={
   i=_i-1,
   x=10+6*(_i-1),
   y=8,
   origi=_i-1,
   dir=1,
   state='standing',
   workingstate='hacking',
   loot={},
  }
 end

 for _l in all(playerinventory) do
  if _l[1] == 'blueprint' and dget(63) < 60 then
   dset(63,dget(63)+1)
  end
 end

 escapedplayers,playerinventory={},{}

 _update=function()
  if btnp(4) then
   if _cash < 0 then
    dset(61,0)
    initsplash()
   else
    initmapselect()
   end
  end
 end

 _draw=function()
  cls()

  local _offy=29
  for _r in all(_rows) do
   print(_r[1],10,_offy,6)
   local _r2,_col,_offx='$'.._r[2],11,0
   if _r[2] < 0 then
    _r2,_col,_offx='-$'..abs(_r[2]),14,4
   end
   print(_r2,88-_offx,_offy,_col)
   _offy+=7
  end

  print('total',10,110,5)

  local _col=11
  if _cash < 0 then
   _col=14
  end
  local _s='$'.._cash
  print(_s,98-#_s*2,110,_col)

  print(_msg,64-#_msg*2,119,10)
 end
end








-- splash
function initsplash()
 sfx(16,-2)
 sfx(17,-2)
 sfx(62)
 local _msg='continuing saved "career"'
 seli=dget(63)-1
 while dget(61) == 0 do

  -- 1-60 is unlocked status if corresponding maps
  -- 61 is seed
  -- 62 is cash
  -- 63 is current maxseli
  for _i=0,60 do
   dset(_i,0)
  end

  dset(61,rnd())
  dset(62,1000)
  dset(63,6)
  seli,_msg=1,'started new "career"'
  debug('new seed',dget(61))
 end

 _update=function()
  if btnp(4) then
   menuitem(1, 'rat on eachother', function()
    for _p in all(escapedplayers) do
     add(players,del(escapedplayers,_p))
    end
    initpolice()
   end)
   initstatus(_msg)
  end
 end
 _draw=function()
  cls()
  print('sneaky stealy',39,46,2)
  print('sneaky stealy',38,45,7)
  print('\x8e to start/continue game',13,119,10)
 end
end


_init=initsplash


__gfx__
f5ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f5f5ccccfff555555fff2511155111525111111551111125ffffffffffffffffffffffffffffffffffffffff5dd55dd5ffffffffffffffffffffffffffffffff
ff5fcc1c5ff511115fff251115511152511d111551555225222222ff222222ff222222ff222222ff222222ff5dd55d15ffffffffffffffffffffffffffffffff
f5ffcc1cf5f511115fff25555555555251111115555552d5255552ff211152ff2dddd2ff2dddd2ff2111d2ff5dd55115ffffff55ffffffffffffffffffffffff
f5ffc1cc25251111522225111551115251dd111551111225255552ff211552ff2dddd2ff2dddd2ff211dd2ff5dd55115ffffff55ffffffffffffffffffffffff
2222fccf2d255555522255111551115551d11115511112d5255552ff211552ff2dddd2ff2dddd2ff211dd2ff5dd55dd54fff4f55ffffffffffffffffffffffff
dddd55552225d5d552225555555555555111111551555225255552ff211552ff28ddd2ff2bddd2ff211dd2ffffffffff4f554fddffffffffffffffffffffffff
dddd522522255d5d52522255d15d552255555555555552552d5552ff211552ff25ddd2ff25ddd2ff211dd2ffffffffff442244ddffffffffffffffffffffffff
22225ff522255555522222255555522255ffff5555ffff55255552ff211d52ff2dddd2ff2dddd2ff2115d2ffffffffffff22ffddffffffffffffffffffffffff
ffffffff5ffffffffff5552222222255ffffffffffffffff255552ff211552ff2dddd2ff2dddd2ff211dd2ffffffffffffffffffffffffffffffffffffffffff
ffffffff5ffffffffff5ff52222225fffffffffffffffffffffffffffff5fffffffffffffffffffffffdffffffffffffffffffffffffffffffffffffffffffff
ffffffff5ffffffffff5fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f3ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f3f3ccccfff555555fffd5111551115d5222222551111125ffffffffffffffffffffffffffffffffffffffff46744674ffffffffffffffffffffffffffffffff
ff3fcc7c3ff511115fffd5111551115d5226222551444225222222ff222222ff222222ff222222ff222222ff47644714ffffffffffffffffffffffffffffffff
f3ffcc7cf3f511115fffd5555555555d5222222555555265244442ff211142ff266662ff266662ff211162ff46644114ffffff55ffffffffffffffffffffffff
f3ffc7cc434511115444d5111551115d5266222551111225244442ff211442ff266662ff266662ff211662ff46744114ffffff55ffffffffffffffffffffffff
4444fccf4645555554445511155111555262222551111265244442ff211442ff266662ff266662ff211662ff476447644fff4f55ffffffffffffffffffffffff
6666555544456d6d54445555555555555222222551444225244442ff211442ff286662ff2b6662ff211662ffffffffff4fdd4fddffffffffffffffffffffffff
666654454445d6d6545422556d5655225555555555555255294442ff211442ff2d6662ff2d6662ff211662ffffffffff445544ddffffffffffffffffffffffff
44445ff544455555544422255555522255ffff5555ffff55244442ff211942ff266662ff266662ff211d62ffffffffffff55ffddffffffffffffffffffffffff
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
ff1fffff1ffff1fffff1fffff0fffff0ffff0fffff0fffffffffffffffffffffffffffffffffffffffffffffffffb1bb1bbb51110166d666d6666666d1110117
ff1fffff1ffff1fffff1f1fff0fffff0ffff0fffff0f0ffffffffffffff0ffffffffffffffffffffffffffffffff11bb1bbb588110006666d666666d60001115
f111fff1111f111fff111fff000fff0000f000fff000fffff00fffffff000fffffffffffffffffffffffffffffffbb1bbbbb511100000666d666666600000115
11111f1111111111ff11fff00000f0000000000ff00ffffff00fffffff000fffffffffffffffffffffffffffffffbb11bbbbb51100100666666666660010015b
1111f1111111111fff11fff0000f0000000000fff00fffff0000ffff0f000fffffffffffffffffffffffffffffffbb9bbbbbbbbb00001bbbbbbbbbbb00001bbb
f111fff11111111fff111fff000fff00000000fff000ffff0000ffff0f000fffffffffffffffffffffffffffffffbb9bbb55bbbbb111bbbbbbbbbbbbb111bbbb
f1f1fff1f1ff1f1ff11f1fff0f0fff0f0ff0f0ff00f0fff000000ff0000f0fffffffffffffffffffffffffffffffb111119bbbbddddddddddddddddddbbbbbbb
f1f1fff1f1ff1f1fffffffff0f0fff0f0ff0f0fffffffff000000ff000ffffffffffffffffffffffffffffffffff1111bbbbbbdddddddddddddd88ddddbbbbbb
f1f1fff1f1ff1f1fffffffff0f0fff0f0ff0f0ffffffff00f00f00f000ffffffffffffffffffffffffffffffffff19ddbbbbbbdddddddddddddd11ddd6dbbbbb
fffffffffffff1fffff1ffffffffffffffff1fffff1fffffffffffffffffffffffffffffffffffffffffffffffffb111bbbbbbddddddddddddddddddd76dbbbb
ff1fffff1ffffefffffefefff1fffff1ffffefffffefeffffffffffffff1ffffffffffffffffffffffffffffffffb1b1bbbbbb1dddddddddddddddddd676ddbb
f1e1fff1e22f111fff111fff1e1fff1e22f111fff111fffff11fffffff1e1fffffffffffffffffffffffffffffffb1b1bbbbbb1111111111111111111677dddb
11111f111e22111eff11fff11111f111e22111eff11ffffffeefffffff111fffffffffffffffffffffffffffffffb1b1bbbbbb110101011010111d555167dddb
1e11fe1e1122111fff11fff1e11fe1e1122111fff11fffff1111ffff1fe1efffffffffffffffffffffffffffffffbbbbbbbbbb1101010110101115d55516dddb
f111fff11122111fff111fff111fff11122111fff111ffff1111ffffef111ffffffffffffffffffffbbbbbbbbebebb1bbbbbbb11010101101011155d5551ddd7
f1f1fff1f1ff1f1ff11f1fff1f1fff1f1ff1f1ff11f1fff111111ff1111f1ffffffffffffffffffffbbbbbbbb1b1bb11bbbbb5110101011010111111111111d7
f1f1fff1f1ff1f1fffffffff1f1fff1f1ff1f1fffffffff111111ff111fffffffffffffffffffffffbbbbbbbb111bb9bbbbbb511111111111111111111111115
f1f1fff1f1ff1f1fffffffff1f1fff1f1ff1f1ffffffff11feef11f111fffffffffffffffffffffffbbbbbbbb1e1bb9bbbbbb511110001111111111110001117
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
3333ffff6666555500000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
3333ffff6666445400000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbbffffff4ff4ff000a0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888fffff551155f00aaa000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888ffff5ffffff50aaaaa00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
8888ffffff8ff8ffaaaaaaa0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
111ffffff551155fa0000000000a0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
111fffff5ffffff5aa00000000aa0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
777fffffffbffbffaaa000000aaa0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
777ffffff551155faaaa0000aaaa0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbfffff5ffffff5aaa000000aaa0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbfffffffffffffaa00000000aa0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
888fffffffffffffa0000000000a0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
888fffffffffffff0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__sfx__
000100001d050110400c0400204010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018050190400c0400204010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002900001405013050110000f000070001b0001800016000160001300016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000050500a0500f050180501f0502e0501f00030050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d00000f0501b0501300000000000000f0000f0000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002f00000c3300c3000c320003000c330003000c320003000c330003000c320003000c3300c3000c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000600001d0601c0001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008001051d711257111d711257111d711007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00800000257711d771257711d77100700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
001000000c122031020b1220010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102
003000000502503005000250000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000524007200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
000900001045110451004011145111451004011245112451004011345113451004011445114451004011545115451394013a4013a4013a4013a40139401004013c40100401004010040100401004010040100401
002700002262303603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603
0001000017131171211813118131191311b1311d1311f121261312f13138131001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
000b0000211552a155361550010537105301052910500105001050010523105211052710522105211052110500105001050010500105001050010500105001050010500105001050010500105001050010500105
0015000002160021000d1000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011500000405300003000030000300003000030000300003040530000300003000030000300003000030000304053000030000300003000030000300003000030405300003000030000300003000030000300003
012a0020041100611507115041100b114041150a11204115041100611507115041100a11204115091140411504110061150711504110091140411507114041150411506110071150611504110011100211503110
011100000b1300a135081300512405120051200513005130051420514205142051520515500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011100000142002425004000342004425000000d6230d1330c40006420074250c4000d623084200000004424094200c4000d1330a4220c400044440b4220c4000c4000c4000c4000c4000c400004000040000000
__music__
00 3c3d4344

