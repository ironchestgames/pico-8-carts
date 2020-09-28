pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- sneaky stealers
-- sneak n steal
-- sneaky stealy

devfog=false
devghost=false
devvalues=true

menuitem(1, 'devfog', function() devfog=not devfog end)
menuitem(2, 'devghost', function() devghost=not devghost end)
menuitem(3, 'devvalues', function() devvalues=not devvalues end)

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

local function adjacency(_a,_b)
 if _a.x == _b.x-1 and _a.y == _b.y then
  return 0
 elseif _a.x == _b.x+1 and _a.y == _b.y then
  return 1
 elseif _a.x == _b.x and _a.y == _b.y-1 then
  return 2
 elseif _a.x == _b.x and _a.y == _b.y+1 then
  return 3
 end
 return nil
end

local floor={}

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
 return nil
end

local diropposites={[0]=1,0,3,2,}
local arslen=32*32-1

for _i=0,arslen do
 local _x,_y=_i&31,_i\32
 floor[_i]=sget(96+_x,96+_y) -- todo: generate instead
end

local light={}
for _i=0,arslen do
 light[_i]=0
end

local fog={}
for _i=0,arslen do
 fog[_i]=1
end

local players={
 {i=0,x=6,y=25,state='standing'},
 {i=1,x=6,y=29,state='standing'},
}

local guards={
 {
  x=27,y=4,
  dx=0,dy=1,
  state='walking',
  state_c=0,
  state_c2=0,
 },
 {
  x=6,y=14,
  dx=1,dy=0,
  state='walking',
  state_c=0,
  state_c2=0,
 },
}

local alertlvl=1
local alertlvls={24,8} -- note: only tick time

-- states:
-- 0 - off
-- 1 - on
-- 2 - selected/on (camcontrol)
-- 3 - system alarm (camcontrol)
local cameras={ -- note: camcontrol will crash with more than 4
 {i=1,x=30,y=24,state=1,},
 {i=2,x=1,y=7,state=1,},
 {i=3,x=30,y=2,state=1,},
}

local function computer(_p,_o,_tmp)
 if _tmp.action_c == nil then
  _tmp.action_c=0
  _tmp.state='booting'
  sfx(11)
  _tmp.seq={0,1,2,1,0,2,1,0,1,2,0}
  _o.draw=function()
   if _tmp.state == 'booting' then
    sspr(0,102,4,3,_o.x*4-4,_o.y*4-7)

   elseif _tmp.state == 'success' then
    sspr(0,114,4,3,_o.x*4-4,_o.y*4-7)

   elseif _tmp.state == 'fail' then
    sspr(0,117,4,3,_o.x*4-4,_o.y*4-7)

   else
    sspr(0,105+_tmp.seq[1]*3,4,3,_o.x*4-4,_o.y*4-7)
   end
  end
 end

 _tmp.action_c+=1

 if _tmp.action_c == 120 then
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
     -- todo: add whatever the hacking did
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
  _p.y+=1

  -- reset obj
  _o.draw=nil
 end
end

local function camcontrol(_p,_o,_tmp)
 if _tmp.sel == nil then
  _tmp.sel=1
  _tmp.pos={
   {x=-2,y=-4},
   {x=3,y=-4},
   {x=-2,y=-1},
   {x=3,y=-1},
  }
  for _i=1,4 do
   local _c=cameras[_i]
   _tmp.pos[_i].state=1
   if _c then
    _tmp.pos[_c.i].state=_c.state
   end
  end

  _tmp.pos[1].state=2

  _o.draw=function()
   for _i=1,#_tmp.pos do
    local _p=_tmp.pos[_i]
    local _x=_o.x*4+_p.x
    local _y=_o.y*4+_p.y
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
   -- todo: intruder alert
  end
 end

 if btnp(3,_p.i) then
  -- reset player
  _p.action=nil
  _p.state='standing'
  _p.y+=1

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

local objs={
 {x=10,y=13,typ=0,light={},shadow={[0]=true,true,true,true}},

 {x=14,y=18,typ=0,light={},shadow={[0]=true,true,true,true}},

 {x=20,y=21,typ=1,light={},shadow={[0]=true,true,true,true}},

 {x=24,y=24,typ=2,light={},shadow={[0]=true,nil,nil,nil}},
 {x=25,y=24,typ=3,light={},shadow={[0]=nil,nil,nil,nil},action={[2]=computer}},
 {x=26,y=24,typ=4,light={},shadow={[0]=nil,true,nil,nil}},

 {x=6,y=19,typ=5,light={},shadow={[0]=true,nil,nil,nil}},
 {x=8,y=19,typ=7,light={},shadow={[0]=nil,true,nil,nil}},
 {x=7,y=19,typ=6,light={},shadow={[0]=nil,nil,nil,nil},action={[2]=camcontrol}}, -- note: draw last
}

local msgs={}

local function iswallclose(_x,_y,_dx,_dy)
 local _c=0
 while _y >= 1 and _y <= 32 and _x >= 1 and _x <= 32 and floor[_y*32+_x] != 2 do
  _x+=_dx
  _y+=_dy
  _c+=1
 end
 return _c <= 3
end

local t=0

function gameupdate()
 t-=1

 -- reset fog
 for _i=0,arslen do
  -- if floor[_i] == 2 then
   -- fog[_i]=2
  -- else
   fog[_i]=1
  -- end
 end

 for _p in all(players) do

  if _p.state == 'hacking' then
   _p.action()

  else
   local nextx,nexty=_p.x,_p.y
   local _isinput=false
   if btnp(0,_p.i) then
    nextx-=1
    _isinput=true
   elseif btnp(1,_p.i) then
    nextx+=1
    _isinput=true
   elseif btnp(2,_p.i) then
    nexty-=1
    _isinput=true
   elseif btnp(3,_p.i) then
    nexty+=1
    _isinput=true
   end
   if nextx > 31 or nextx < 0 or nexty > 31 or nexty < 0 then
    -- todo: leave premises
    debug('player left premises',_p.i)
   else
    for _o in all(objs) do
     if nextx == _o.x and nexty == _o.y then
      nextx,nexty=_p.x,_p.y
      local _a=adjacency(_o,_p)
      if _o.action and _o.action[_a] then
       _p.state='hacking'
       _p.action=curry3(_o.action[_a],_p,_o,{})
      end
     end
    end 
    if _p.state != 'caught' and floor[nexty*32+nextx] != 2 then
     _p.x,_p.y=nextx,nexty

     -- hide behind object
     if _p.state != 'hacking' then
      local _hiding=nil
      local _pwa=walladjacency(_p)
      for _o in all(objs) do
       local _a=adjacency(_p,_o)
       local _owa=walladjacency(_o)
       if _owa != nil and _pwa != nil and _a != nil and light[_p.y*32+_p.x] == 0 then
        _p.state='hiding'
        _p.adjacency=_a
        _hiding=true
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
    add(msgs,{x=_g.x*4+1,y=_g.y*4-13,s='suspect caught!',t=4})
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
  --    add(msgs,{x=_g.x*4+1,y=_g.y*4-13,s='?',t=4})
  --   end
  --  end
  -- end
 end

 if t <= 0 then

  -- update guards
  for _g in all(guards) do

   -- handle state
   if _g.state == 'standing' then
    _g.state_c-=1
    -- set to walking
    if _g.state_c <= 0 then
     _g.state='walking'
    end

   elseif _g.state == 'walking' then
    -- move
    local _gwa=walladjacency({x=_g.x+_g.dx,y=_g.y+_g.dy})
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

   elseif _g.state == 'turning' then
    -- turn and set to standing
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
    _g.state='walking'

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

    -- set to walking
    if _g.state_c <= 0 then
     _g.state='turning'
    end
   end

   -- set up next state
   if iswallclose(_g.x,_g.y,_g.dx,_g.dy) then
    _g.state='turning'
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
  t=alertlvls[alertlvl]
 end

 -- clear objects light
 for _o in all(objs) do
  _o.light={} -- todo: optimize
 end

 -- clear light
 for _i=0,arslen do
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
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _bydown) then
       add(_o.light,{x=0,y=-1})
      end
     end
     light[_bydown*32+_bx]=1
     if _c.state == 2 then
      fog[_bydown*32+_bx]=0
      if _by == _y then
       fog[(_bydown-1)*32+_bx]=0
      end
     end
     _bydown+=1
     _bldown+=1
    end
    local _bxside=_bx
    local _blside=1
    while floor[_by*32+_bxside] != 2 and _blside <= _lside do
     for _o in all(objs) do
      if (_o.x == _bxside and _o.y == _by) then
       add(_o.light,{x=-_dx,y=0})
      end
     end
     if _c.state == 2 then
      fog[_by*32+_bxside]=0
      if _by == _y then
       fog[(_by-1)*32+_bxside]=0
      end
     end
     light[_by*32+_bxside]=1
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

 -- -- shine guards flashlights
 for _g in all(guards) do
  if _g.state == 'holding' then
   light[(_g.y-2)*32+_g.x-1]=1
   light[(_g.y-2)*32+_g.x]=1
   light[(_g.y-2)*32+_g.x+1]=1
   light[(_g.y-1)*32+_g.x-2]=1
   light[(_g.y-1)*32+_g.x-1]=1
   light[(_g.y-1)*32+_g.x]=1
   light[(_g.y-1)*32+_g.x+1]=1
   light[(_g.y-1)*32+_g.x+2]=1
   light[_g.y*32+_g.x-2]=1
   light[_g.y*32+_g.x-1]=1
   light[_g.y*32+_g.x]=1
   light[_g.y*32+_g.x+1]=1
   light[_g.y*32+_g.x+2]=1
   light[(_g.y+1)*32+_g.x-2]=1
   light[(_g.y+1)*32+_g.x-1]=1
   light[(_g.y+1)*32+_g.x]=1
   light[(_g.y+1)*32+_g.x+1]=1
   light[(_g.y+1)*32+_g.x+2]=1
   light[(_g.y+2)*32+_g.x-1]=1
   light[(_g.y+2)*32+_g.x]=1
   light[(_g.y+2)*32+_g.x+1]=1

  elseif _g.dx != 0 then
   local _x,_y=_g.x+_g.dx,_g.y+_g.dy
   local _l=32
   while floor[_y*32+_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by*32+_bx] != 2 and _c <= _l do
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-1})
       add(_o.light,{x=-_g.dx,y=0})
      end
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
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=1})
       add(_o.light,{x=-_g.dx,y=0})
      end
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
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-_g.dy})
       add(_o.light,{x=-1,y=0})
      end
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
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-_g.dy})
       add(_o.light,{x=1,y=0})
      end
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
 for _o in all(objs) do
  if _o.shadow[0] then
   light[_o.y*32+_o.x-1]=0
  end
  if _o.shadow[1] then
   light[_o.y*32+_o.x+1]=0
  end
  if _o.shadow[2] then
   light[(_o.y-1)*32+_o.x]=0
  end
  if _o.shadow[3] then
   light[(_o.y+1)*32+_o.x]=0
  end
  
  for _l in all(_o.light) do
   light[(_o.y+_l.y)*32+_o.x+_l.x]=1
  end
 end

 -- light up walls
 for _i=0,arslen do
  local _x,_y=_i&31,_i\32
  if light[(_y+1)*32+_x] == 1 and floor[_y*32+_x] == 2 and floor[(_y+1)*32+_x] != 2 then
   light[_y*32+_x]=1
  end
 end

 -- intruder alert
 if devghost == false and alertlvl == 1 then
  for _p in all(players) do
   if light[_p.y*32+_p.x] == 1 then
    -- todo: start police countdown
    alertlvl=2
    for _g in all(guards) do
     add(msgs,{x=_g.x*4,y=_g.y*4-13,s='intruder alert!',t=4})
     _g.state='walking'
    end
    t=60
   end
  end
 end

 -- -- remove fog
 for _p in all(players) do
  if _p.state == 'caught' then
   -- do nothing
  else
   local _dirs={
    {x=1,y=0,dx=1,dy=1},
    {x=1,y=0,dx=1,dy=-1},
    {x=-1,y=0,dx=-1,dy=1},
    {x=-1,y=0,dx=-1,dy=-1},
    {x=0,y=1,dx=1,dy=1},
    {x=0,y=1,dx=-1,dy=1},
    {x=0,y=-1,dx=1,dy=-1},
    {x=0,y=-1,dx=-1,dy=-1},
   }
   for _d in all(_dirs) do
    local _x,_y=_p.x,_p.y
    local _l=32
    while floor[_y*32+_x] != 2 do
     local _c=0
     local _bx=_x
     local _by=_y
     while floor[_by*32+_bx] != 2 and _c <= _l do
      fog[_by*32+_bx]=0
      _bx+=_d.dx
      _by+=_d.dy
      _c+=1
     end
     fog[_by*32+_bx]=0
     _bx+=_d.dx
     _by+=_d.dy
     _l=_c
     _x+=_d.x
     _y+=_d.y
     fog[_y*32+_x]=0
    end
   end
  end
 end

 -- remove fog from holding guards
 for _g in all(guards) do
  if _g.state == 'holding' then
   fog[(_g.y-2)*32+_g.x-1]=0
   fog[(_g.y-2)*32+_g.x]=0
   fog[(_g.y-2)*32+_g.x+1]=0
   fog[(_g.y-1)*32+_g.x-2]=0
   fog[(_g.y-1)*32+_g.x-1]=0
   fog[(_g.y-1)*32+_g.x]=0
   fog[(_g.y-1)*32+_g.x+1]=0
   fog[(_g.y-1)*32+_g.x+2]=0
   fog[_g.y*32+_g.x-2]=0
   fog[_g.y*32+_g.x-1]=0
   fog[_g.y*32+_g.x]=0
   fog[_g.y*32+_g.x+1]=0
   fog[_g.y*32+_g.x+2]=0
   fog[(_g.y+1)*32+_g.x-2]=0
   fog[(_g.y+1)*32+_g.x-1]=0
   fog[(_g.y+1)*32+_g.x]=0
   fog[(_g.y+1)*32+_g.x+1]=0
   fog[(_g.y+1)*32+_g.x+2]=0
   fog[(_g.y+2)*32+_g.x-1]=0
   fog[(_g.y+2)*32+_g.x]=0
   fog[(_g.y+2)*32+_g.x+1]=0
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
end


function _draw()
 gupd=stat(1)
 gupdmax=max(gupd,gupdmax)

 local _lightcols={[0]=1,13,2}
 for _i=32*32,0,-1 do

  -- draw floor
  local _tile=floor[_i]
  local _x,_y=_i&31,_i\32
  local _l=light[_y*32+_x]
  local _sx,_sy=_x*4,_y*4

  local _col=_tile
  if _l == 1 then
   _col=_lightcols[_col]
  end
  rectfill(_sx,_sy,_sx+3,_sy+3,_col)
  
  -- -- draw walls
  local _y1=_y+1
  if _tile == 2 then
   if _y < 32 then
    local _tilebelow=floor[_y1*32+_x]
    if _tilebelow == 0 then
     sspr(4,0+_l*5,4,5,_sx,_sy)
    elseif _tilebelow == 1 then
     rectfill(_sx,_sy,_sx+3,_sy+4,13-7*_l)
    end
   end
  end
 end

 for _y=1,32 do

  -- draw cameras
  for _c in all(cameras) do
   local _sx=24
   if floor[_c.y*32+_c.x+1] == 2 then -- todo: make so cameras can be set anywhere on wall
    _sx=28
   end 
   sspr(_sx,0+_c.state*3,4,3,_c.x*4,_c.y*4-4)
  end

  -- draw objs
  for _o in all(objs) do
   if _o.y == _y then
    local _l=light[_o.y*32+_o.x]
    sspr(40+_o.typ*4,0+_l*13,4,13,_o.x*4,_o.y*4-5)
    if _o.draw then
     _o.draw()
    end
   end
  end

  -- draw players
  for _p in all(players) do
   if _p.y == _y then
    if _p.state == 'hiding' then
     if _p.adjacency == 0 then
      sspr(6,16,4,9,_p.x*4,_p.y*4-5)
     elseif _p.adjacency == 1 then
      sspr(10,16,4,9,_p.x*4,_p.y*4-5)
     elseif _p.adjacency == 2 then
      sspr(14,16,3,9,_p.x*4,_p.y*4-5)
     elseif _p.adjacency == 3 then
      sspr(17,16,3,9,_p.x*4,_p.y*4-5)
     end
    elseif _p.state == 'hacking' then
     sspr(20,16,6,9,_p.x*4,_p.y*4-5)
    elseif _p.state == 'caught' then
     sspr(0,34,6,9,_p.x*4,_p.y*4-5)
    else
     local _l=light[_p.y*32+_p.x]
     sspr(0,16+_l*9,6,9,_p.x*4,_p.y*4-5)
    end
   end
  end

  -- draw guards
  for _g in all(guards) do
   if _g.y == _y then
    if _g.state == 'walking' or _g.state == 'turning' then
     local _dir=0
     if _g.dx == 1 then
      _dir=1
     elseif _g.dy == -1 then
      _dir=2
     elseif _g.dy == 1 then
      _dir=3
     end
     local _frame=0
     if _g.state == 'walking' or _g.state == 'turning' then
      _frame=1
      if t < alertlvls[alertlvl]/2 then
       _frame=2
      end
     end
     sspr(0+_dir*27+_frame*9,45,9,11,_g.x*4-2,_g.y*4-7)

    elseif _g.state == 'holding' then
     sspr(108,45,9,11,_g.x*4-2,_g.y*4-7)
    end
   end
  end
 end

 -- draw fog
 if devfog == false then
  for _i=0,arslen do
   local _f=fog[_i]
   if _f == 1 then
    local _x,_y=_i&31,_i\32
    rectfill(_x*4,_y*4,_x*4+3,_y*4+3,0)
   elseif _f == 2 then
    sspr(4,10,4,4,_x*4-4,_y*4-4)
   end
  end
 end

 -- draw messages
 local _col=10
 if t%8 >= 4 then
  _col=9
 end
 for _m in all(msgs) do
  print(_m.s,_m.x-(#_m.s*2),_m.y,_col)
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

function _init()
 t=0
 alertlvl=1
 palt(0,false)
 palt(15,true)
end


__gfx__
dddd2220000011112222ffffff4ff4fffffffffff5ffffffffffffffffff555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222fffff551155ffffffffff5f56666fff555555fff251115511152ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0222000011112222ffff5ffffff5ffffffffff5f66d65ff511115fff251115511152ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222ffffff8ff8fffffffffff5ff66d6f5f511115fff255555555552ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd22021111dddd0000fffff551155ffffffffff5ff6d66252511115222251115511152ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666644451111dddd0000ffff5ffffff5ffffffff2222f66f2d2555555222551115511155ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666655551111dddd0000ffffffbffbffffffffffdddd55552225d5d55222555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666654441111dddd0000fffff551155fffffffffdddd522522255d5d52522255d15d5522ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66665555000000000000ffff5ffffff5ffffffff22225ff5222555555222222555555222ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66664454000000000000ffffffffffffffffffffffffffff5ffffffffff5552222222255ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffff5ffffffffff5ff52222225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000ffffffffffffffffffffffffffff5ffffffffff5fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000fffffffffffffffffffff3ffffffffffffffffff555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000fffffffffffffffffffff3f3ccccfff555555fffd5111551115dffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000ffffffffffffffffffffff3fc7cc3ff511115fffd5111551115dffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff0fffffffffffffff0fff0ffffffffffffffffff3ffccccf3f511115fffd5555555555dffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff0ffffffffffffff000ff0ffffffffffffffffff3ffcc7c434511115444d5111551115dffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000fffff00ffffff000f000ffffffffffffffff4444fccf464555555444551115511155ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000ffff00ffffff000f0000fffffffffffffff6666555544456d6d5444555555555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0000f0ff0000fff0f000f000ffffffffffffffff666655554445d6d6545422556d565522ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000ffff0000fff0f0f0f000ffffffffffffffff44445ff5444555555444222555555222ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff000000f000ffff0f0ffffffffffffffffffffffff2ffffffffff2552222222255ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff000000f000ffff0f0ffffffffffffffffffffffff2ffffffffff2ff52222225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0ff00f00f00000ffff0f0ffffffffffffffffffffffff2ffffffffff2fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffefffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
11111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1911f9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1e1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
11111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
15151fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f151ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
1111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222221111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222221111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
b333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111122222222111112222222222222
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111122222222111112222222222222
333bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3bb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222111111111111111112
bbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222111111111111111112
bbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111112112111111111111111112
bbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111112112111111111111111112
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111112112111111111111111112
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111112112111112222222222222
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111112112111112222222222222
111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222112111111111111111112
111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222112111111111111111112
777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222222111111111111111112
777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222222111111111111111112
bbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
bbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00022222222222222222222222222222
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
002900001405013050110000f000070001b0001800016000160001300016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0000050200a0300f030180301f0302e0301f00030030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001300000f0300f0000f00000000000000f0000f0000f0000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002703000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002f00000c3500c3000c350003000c350003000c350003000c350003000c350003000c3500c3000c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
