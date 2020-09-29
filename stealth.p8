pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- sneaky stealers
-- sneak n steal
-- sneaky stealy

devfog=false
devghost=false
devvalues=false

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

local msgs={}

local playerinventory={}

local function playerloots(_p,_o)
 if _o.loot == nil then
  add(msgs,{x=_o.x,y=_o.y,s='(nothing)',t=2})
 elseif _o.loot[2] != nil then
  add(msgs,{x=_o.x,y=_o.y,s=_o.loot[1],t=2})
  _p.loot[#_p.loot+1]=_o.loot
 else
  add(msgs,{x=_o.x,y=_o.y,s=_o.loot[1],t=2})
  playerinventory[#playerinventory+1]=_o.loot
 end
 _o.loot=nil
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
 {i=0,x=8,y=30,state='standing',workingstate='hacking',loot={}},
 {i=1,x=6,y=29,state='standing',workingstate='hacking',loot={}},
}

local guards={
 {
  x=27,y=4,
  dx=0,dy=1,
  state='patrolling',
  state_c=0,
  state_c2=0,
 },
 {
  x=6,y=14,
  dx=1,dy=0,
  state='patrolling',
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
 {i=1,x=30,y=24,state=0,},
 {i=2,x=1,y=7,state=0,},
 {i=3,x=30,y=2,state=0,},
}

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
    sspr(0,102,4,3,_o.x*4,_o.y*4-3)

   elseif _tmp.state == 'success' then
    sspr(0,114,4,3,_o.x*4,_o.y*4-3)

   elseif _tmp.state == 'fail' then
    sspr(0,117,4,3,_o.x*4,_o.y*4-3)

   else
    sspr(0,105+_tmp.seq[1]*3,4,3,_o.x*4,_o.y*4-3)
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


local function camcontrol(_p,_o,_tmp)
 _p.workingstate='hacking'
 if _tmp.sel == nil then
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
     pset(_o.x*4+5,_o.y*4-3,8)
    elseif _o.isopen != true and _tmp.unlocked == true then
     pset(_o.x*4+5,_o.y*4-3,11)
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
   for _other in all(objs) do
    if _other.y == _o.y and _other.x == _o.x+1 then
     _other.typ+=2
     _o.typ+=2
    end
   end
   -- change typ to draw open sprite
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

objs={
 {x=10,y=13,typ=0,light={},shadow={[0]=true,true,true,true}},

 {x=14,y=18,typ=0,light={},shadow={[0]=true,true,true,true}},

 {x=20,y=21,typ=1,light={},shadow={[0]=true,true,true,true}},

 {x=24,y=24,typ=2,light={},shadow={[0]=true,nil,nil,nil}},
 {x=25,y=24,typ=3,light={},shadow={[0]=nil,nil,nil,nil},action={[2]=computer},loot={'door access code'}},
 {x=26,y=24,typ=4,light={},shadow={[0]=nil,true,nil,nil}},

 {x=6,y=19,typ=5,light={},shadow={[0]=true,nil,nil,nil}},
 {x=8,y=19,typ=7,light={},shadow={[0]=nil,true,nil,nil}},
 {x=7,y=19,typ=6,light={},shadow={[0]=nil,nil,nil,nil},action={[2]=camcontrol}}, -- note: draw last

 {x=11,y=28,typ=9,light={},shadow={[0]=nil,true,nil,nil}},
 {x=10,y=28,typ=8,light={},shadow={[0]=true,nil,nil,nil},action={[2]=safe},loot={'diamonds',14000}},
}

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

  if _p.state == 'working' then
   _p.workingstate='hacking'
   _p.action()

  else
   local nextx,nexty=_p.x,_p.y
   local _isinput
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
       _p.state='working'
       _p.action=curry3(_o.action[_a],_p,_o,{})
      end
     end
    end 
    if _p.state != 'caught' and floor[nexty*32+nextx] != 2 then
     _p.x,_p.y=nextx,nexty

     -- hide behind object
     if _p.state != 'working' then
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
    add(msgs,{x=_g.x,y=_g.y,s='suspect caught!',t=4})
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

 if t <= 0 then

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

     -- remove fog if selected in camcontrol
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

     -- remove fog if selected in camcontrol
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
     add(msgs,{x=_g.x,y=_g.y,s='intruder alert!',t=4})
     _g.state='patrolling'
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
    local _l=light[_p.y*32+_p.x]
    if _p.state == 'hiding' then
     sspr(12+_p.adjacency*4,72,4,9,_p.x*4,_p.y*4-5)
    elseif _p.state == 'working' then
     if _p.workingstate == 'hacking' then
      sspr(27,72+_l*9,5,9,_p.x*4,_p.y*4-5)
     elseif _p.workingstate == 'cracking' then
      sspr(32,72+_l*9,5,9,_p.x*4,_p.y*4-5)
     end
     if #_p.loot > 0 then
      sspr(5,91+_l*4,8,4,_p.x*4,_p.y*4)
     end
    elseif _p.state == 'caught' then
     sspr(0,90,6,9,_p.x*4,_p.y*4-5)
    else
     if #_p.loot > 0 then
      sspr(6,72+_l*9,6,9,_p.x*4,_p.y*4-5)
     else
      sspr(0,72+_l*9,6,9,_p.x*4,_p.y*4-5)
     end
    end
   end
  end

  -- draw guards
  for _g in all(guards) do
   if _g.y == _y then
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
      if t < alertlvls[alertlvl]/2 then
       _frame=2
      end
     end
     sspr(0+_dir*27+_frame*9,31,9,11,_g.x*4-2,_g.y*4-7)

    elseif _g.state == 'holding' then
     sspr(109,31,7,11,_g.x*4-2,_g.y*4-7)
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
  local _hw=#_m.s*2
  local _x=max(min(_m.x*4-_hw,127-_hw*2),0)
  local _y=max(_m.y*4-13,0)
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

function _init()
 t=0
 alertlvl=1
 palt(0,false)
 palt(15,true)
end


__gfx__
dddd2220000011112222ffffff4ff4fffffffffff5ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222fffff551155ffffffffff5f5ccccfff555555fff2511155111525111111551111125ffffffffffffffffffffffffffffffffffffffff
dddd0222000011112222ffff5ffffff5ffffffffff5fcc1c5ff511115fff251115511152511d111551555225ffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222ffffff8ff8fffffffffff5ffcc1cf5f511115fff25555555555251111115555552d5ffffffffffffffffffffffffffffffffffffffff
dddd22021111dddd0000fffff551155ffffffffff5ffc1cc25251111522225111551115251dd111551111225ffffffffffffffffffffffffffffffffffffffff
666644451111dddd0000ffff5ffffff5ffffffff2222fccf2d255555522255111551115551d11115511112d5ffffffffffffffffffffffffffffffffffffffff
666655551111dddd0000ffffffbffbffffffffffdddd55552225d5d552225555555555555111111551555225ffffffffffffffffffffffffffffffffffffffff
666654441111dddd0000fffff551155fffffffffdddd522522255d5d52522255d15d55225555555555555255ffffffffffffffffffffffffffffffffffffffff
66665555000000000000ffff5ffffff5ffffffff22225ff522255555522222255555522255ffff5555ffff55ffffffffffffffffffffffffffffffffffffffff
66664454000000000000ffffffffffffffffffffffffffff5ffffffffff5552222222255ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffff5ffffffffff5ff52222225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000ffffffffffffffffffffffffffff5ffffffffff5fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000fffffffffffffffffffff3ffffffffffffffffff5555555555555555555555555555ffffffffffffffffffffffffffffffffffffffff
00000000000000000000fffffffffffffffffffff3f3ccccfff555555fffd5111551115d5222222551111125ffffffffffffffffffffffffffffffffffffffff
00000000000000000000ffffffffffffffffffffff3fc7cc3ff511115fffd5111551115d5226222551444225ffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffff3ffccccf3f511115fffd5555555555d5222222555555265ffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffff3ffcc7c434511115444d5111551115d5266222551111225ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff4444fccf4645555554445511155111555262222551111265ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff6666555544456d6d54445555555555555222222551444225ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff666654454445d6d6545422556d5655225555555555555255ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffff44445ff544455555544422255555522255ffff5555ffff55ffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffff2552222222255ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffff2ff52222225ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffff2ffffffffff2fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
ff0fffff0ffffffffffffffffffff0ffff0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff0fffff0ffffffffffffffff0fff0ffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000fff0000ffff00fffffff000f000ff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000f000000fff00fffffff000f0000f00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0000f0000000ff0000ffff0f000f000ff00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000fff00000ff0000ffff0f000f000ff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff0f0fff000000ff0000f0f0f0f00f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff0f0fff000000ff000ffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff0f0ff00f00f00f000ffff0f0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffff1ffff1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff1fffff1ffffffffffffffff1fffeffffef9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1e1fff1e22ffff11fffffff1e1f111ff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
11111f111922fffeefffffff111f1119f11fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1911f9191122ff1111ffff1f919f111ff11fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f111fff11122ff1111ffffef111f111ff111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1fff1f1fff111111ff1111f1f1f1f11f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1fff1f1fff111111ff111ffff1f1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1fff1f1ff11f99f11f111ffff1f1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1e1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
11111ffffff00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
15151fffff000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f151ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f1f1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
f1f1fffffff22fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222222222222222222222
f1f1ffffff222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
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
000500001d76000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001b73000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
