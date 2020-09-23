pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

devfog=false
devghost=false

menuitem(1, 'devfog', function() devfog=not devfog end)
menuitem(2, 'devghost', function() devghost=not devghost end)

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

function shuffle(_l)
 for _i=#_l,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end

function adjacency(_a,_b)
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

function walladjacency(_a)
 if floor[_a.y][_a.x-1] == 2 then
  return 0
 elseif floor[_a.y][_a.x+1] == 2 then
  return 1
 elseif floor[_a.y-1][_a.x] == 2 then
  return 2
 elseif floor[_a.y+1][_a.x] == 2 then
  return 3
 end
 return nil
end

floor={}
for y=1,32 do
 floor[y]={}
 for x=1,32 do
  floor[y][x]=sget(95+x,95+y) -- todo: generate
 end
end

light={}
for y=1,32 do
 light[y]={}
 for x=1,32 do
  light[y][x]=0
 end
end

fog={}
for y=1,32 do
 fog[y]={}
 for x=1,32 do
  fog[y][x]=1
 end
end

-- player states:
-- 0 - standing
-- 1 - walking
-- 2 - hiding
-- 3 - caught

players={
 {x=25,y=27,state='standing'},
 -- {x=22,y=19,state='standing'},
}

-- guard states:
-- 0 - standing
-- 1 - walking
-- 2 - turning
-- 3 - holding suspect
-- 4 - suspicious (heard something)

-- todo: change to strings
guards={
 {
  x=14,y=5,
  dx=1,dy=0,
  state='walking',
  state_c=0,
  state_c2=0,
 },
 {
  x=7,y=15,
  dx=1,dy=0,
  state='walking',
  state_c=0,
  state_c2=0,
 },
}

alertlvl=1
alertlvls={24,8} -- note: only tick time

function computer(_o)
 debug('computer!')
end

objs={
 {x=11,y=14,typ=0,light={},shadow={[0]=true,true,true,true}},
 {x=15,y=19,typ=0,light={},shadow={[0]=true,true,true,true}},
 {x=21,y=22,typ=1,light={},shadow={[0]=true,true,true,true}},
 {x=25,y=25,typ=2,light={},shadow={[0]=true,nil,nil,nil}},
 {x=26,y=25,typ=3,light={},shadow={[0]=nil,nil,nil,nil},action={[2]=computer}},
 {x=27,y=25,typ=4,light={},shadow={[0]=nil,true,nil,nil}},
}

msgs={}

t=0

function iswallclose(_x,_y,_dx,_dy)
 local _c=0
 while _y >= 1 and _y <= 32 and _x >= 1 and _x <= 32 and floor[_y][_x] != 2 do
  _x+=_dx
  _y+=_dy
  _c+=1
 end
 return _c <= 3
end

function _update()
 t-=1

 for i=1,#players do
  local _p=players[i]
  local nextx,nexty=_p.x,_p.y
  local _isinput=false
  if btnp(0,i-1) then
   nextx-=1
   _isinput=true
  elseif btnp(1,i-1) then
   nextx+=1
   _isinput=true
  elseif btnp(2,i-1) then
   nexty-=1
   _isinput=true
  elseif btnp(3,i-1) then
   nexty+=1
   _isinput=true
  end
  if nextx > 32 or nextx < 1 or nexty > 32 or nexty < 1 then
   -- todo: leave premises
   debug('player left premises',i)
  else
   for _o in all(objs) do
    if nextx == _o.x and nexty == _o.y then
     nextx,nexty=_p.x,_p.y
     local _a=adjacency(_o,_p)
     if _o.action and _o.action[_a] then
      _o.action[_a](_o)
     end
    end
   end 
   if _p.state != 'caught' and floor[nexty][nextx] != 2 then
    _p.x,_p.y=nextx,nexty
   end
  end

  -- hide behind object
  local _hiding=nil
  local _pwa=walladjacency(_p)
  for _o in all(objs) do
   local _a=adjacency(_p,_o)
   local _owa=walladjacency(_o)
   if _owa != nil and _pwa != nil and _a != nil and light[_p.y][_p.x] == 0 then
    _p.state='hiding'
    _p.adjacency=_a
    _hiding=true
   end
  end
  if _hiding == nil then
   _p.state='standing'
  end

  -- if one square from guard, get caught
  for _g in all(guards) do
   local _dx=_p.x-_g.x
   local _dy=_p.y-_g.y
   if (_p.state != 'hiding' or light[_p.y][_p.x] == 1) and _p.state != 'caught' and abs(_dx) <= 1 and abs(_dy) <= 1 then
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
  _o.light={}
 end

 -- clear light
 for y=1,32 do
  for x=1,32 do
   light[y][x]=0
  end
 end

 -- shine guards flashlights
 for _g in all(guards) do
  if _g.state == 'holding' then
   light[_g.y-2][_g.x-1]=1
   light[_g.y-2][_g.x]=1
   light[_g.y-2][_g.x+1]=1
   light[_g.y-1][_g.x-2]=1
   light[_g.y-1][_g.x-1]=1
   light[_g.y-1][_g.x]=1
   light[_g.y-1][_g.x+1]=1
   light[_g.y-1][_g.x+2]=1
   light[_g.y][_g.x-2]=1
   light[_g.y][_g.x-1]=1
   light[_g.y][_g.x]=1
   light[_g.y][_g.x+1]=1
   light[_g.y][_g.x+2]=1
   light[_g.y+1][_g.x-2]=1
   light[_g.y+1][_g.x-1]=1
   light[_g.y+1][_g.x]=1
   light[_g.y+1][_g.x+1]=1
   light[_g.y+1][_g.x+2]=1
   light[_g.y+2][_g.x-1]=1
   light[_g.y+2][_g.x]=1
   light[_g.y+2][_g.x+1]=1

  elseif _g.dx != 0 then
   local _x,_y=_g.x+_g.dx,_g.y+_g.dy
   local _l=32
   while floor[_y][_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by][_bx] != 2 and _c <= _l do
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-1})
       add(_o.light,{x=-_g.dx,y=0})
      end
     end
     light[_by][_bx]=1
     _bx+=_g.dx
     _by+=1
     _c+=1
    end
    _l=_c-1
    _x+=_g.dx
   end

   _x,_y=_g.x+_g.dx,_g.y+_g.dy
   _l=32
   while floor[_y][_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by][_bx] != 2 and _c <= _l do
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=1})
       add(_o.light,{x=-_g.dx,y=0})
      end
     end
     light[_by][_bx]=1
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
   while floor[_y][_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by][_bx] != 2 and _c <= _l do
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-_g.dy})
       add(_o.light,{x=-1,y=0})
      end
     end
     light[_by][_bx]=1
     _bx+=1
     _by+=_g.dy
     _c+=1
    end
    _l=_c-1
    _y+=_g.dy
   end

   _x,_y=_g.x+_g.dx,_g.y+_g.dy
   _l=32
   while floor[_y][_x] != 2 do
    local _c=0
    local _bx=_x
    local _by=_y
    while floor[_by][_bx] != 2 and _c <= _l do
     for _o in all(objs) do
      if (_o.x == _bx and _o.y == _by) then
       add(_o.light,{x=0,y=-_g.dy})
       add(_o.light,{x=1,y=0})
      end
     end
     light[_by][_bx]=1
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
   light[_o.y][_o.x-1]=0
  end
  if _o.shadow[1] then
   light[_o.y][_o.x+1]=0
  end
  if _o.shadow[2] then
   light[_o.y-1][_o.x]=0
  end
  if _o.shadow[3] then
   light[_o.y+1][_o.x]=0
  end
  
  for _l in all(_o.light) do
   light[_o.y+_l.y][_o.x+_l.x]=1
  end
 end

 -- light up walls
 for y=1,31 do
  for x=1,31 do
   if light[y+1][x] == 1 and floor[y][x] == 2 and floor[y+1][x] != 2 then
    light[y][x]=1
   end
  end
 end

 -- intruder alert
 if devghost == false and alertlvl == 1 then
  for _p in all(players) do
   if light[_p.y][_p.x] == 1 then
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

 -- reset fog
 for _y=1,32 do
  for _x=1,32 do
   -- if floor[_y][_x] == 2 then
    -- fog[_y][_x]=2
   -- else
    fog[_y][_x]=1
   -- end
  end
 end

 -- remove fog
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
    while floor[_y][_x] != 2 do
     local _c=0
     local _bx=_x
     local _by=_y
     while floor[_by][_bx] != 2 and _c <= _l do
      fog[_by][_bx]=0
      _bx+=_d.dx
      _by+=_d.dy
      _c+=1
     end
     fog[_by][_bx]=0
     _bx+=_d.dx
     _by+=_d.dy
     _l=_c
     _x+=_d.x
     _y+=_d.y
     fog[_y][_x]=0
    end
   end
  end
 end

 -- remove fog from holding guards
 for _g in all(guards) do
  if _g.state == 'holding' then
   fog[_g.y-2][_g.x-1]=0
   fog[_g.y-2][_g.x]=0
   fog[_g.y-2][_g.x+1]=0
   fog[_g.y-1][_g.x-2]=0
   fog[_g.y-1][_g.x-1]=0
   fog[_g.y-1][_g.x]=0
   fog[_g.y-1][_g.x+1]=0
   fog[_g.y-1][_g.x+2]=0
   fog[_g.y][_g.x-2]=0
   fog[_g.y][_g.x-1]=0
   fog[_g.y][_g.x]=0
   fog[_g.y][_g.x+1]=0
   fog[_g.y][_g.x+2]=0
   fog[_g.y+1][_g.x-2]=0
   fog[_g.y+1][_g.x-1]=0
   fog[_g.y+1][_g.x]=0
   fog[_g.y+1][_g.x+1]=0
   fog[_g.y+1][_g.x+2]=0
   fog[_g.y+2][_g.x-1]=0
   fog[_g.y+2][_g.x]=0
   fog[_g.y+2][_g.x+1]=0
  end
 end

 -- remove fog from double walls
 for _y=1,31 do
  for _x=1,32 do
   if floor[_y][_x] == 2 and floor[_y+1][_x] == 2 and fog[_y+1][_x] == 0 then
    fog[_y][_x]=0
   end
  end
 end

end

function _draw()
 cls(0)
 palt(0,false)
 palt(15,true)

 -- draw floor
 for y=1,32 do
  for x=1,32 do
   local tile=floor[y][x]
   local l=light[y][x]*4
   local sx,sy=x*4-4,y*4-4
   if tile == 0 then
    sspr(8,0+l,4,4,sx,sy)
   elseif tile == 1 then
    sspr(12,0+l,4,4,sx,sy)
   elseif tile == 2 then
    sspr(16,0+l,4,4,sx,sy)
   end
  end
 end

 -- draw walls
 for y=1,32 do
  for x=1,32 do
   local tile=floor[y][x]
   local l=light[y][x]*5
   local sx,sy=x*4-4,y*4-4
   if tile == 2 then
    if y < 32 then
     if floor[y+1][x] == 0 then
      sspr(4,0+l,4,5,sx,sy)
     elseif floor[y+1][x] == 1 then
      sspr(0,0+l,4,5,sx,sy)
     end
    end
   end
  end
 end

 for _y=1,32 do
  -- draw objs
  for _o in all(objs) do
   if _o.y == _y then
    local _l=light[_o.y][_o.x]
    sspr(40+_o.typ*4,0+_l*13,4,13,_o.x*4-4,_o.y*4-9)
   end
  end

  -- draw players
  for _p in all(players) do
   if _p.y == _y then
    -- rectfill(_p.x*4-4,_p.y*4-4-4,_p.x*4-4+3,_p.y*4-4+3,12)
    if _p.state == 'hiding' then
     if _p.adjacency == 0 then
      sspr(6,16,4,9,_p.x*4-4,_p.y*4-9)
     elseif _p.adjacency == 1 then
      sspr(10,16,4,9,_p.x*4-4,_p.y*4-9)
     elseif _p.adjacency == 2 then
      sspr(14,16,3,9,_p.x*4-3,_p.y*4-9)
     elseif _p.adjacency == 3 then
      sspr(17,16,3,9,_p.x*4-4,_p.y*4-9)
     end
    elseif _p.state == 'caught' then
     sspr(0,34,6,9,_p.x*4-4,_p.y*4-9)
    else
     local _l=light[_p.y][_p.x]
     sspr(0,16+_l*9,6,9,_p.x*4-4,_p.y*4-9)
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
     sspr(0+_dir*27+_frame*9,45,9,11,_g.x*4-6,_g.y*4-11)

    elseif _g.state == 'holding' then
     sspr(108,45,9,11,_g.x*4-6,_g.y*4-11)
    end
   end
  end
 end

 -- draw fog
 if devfog == false then
  for _y=1,32 do
   for _x=1,32 do
    if fog[_y][_x] == 1 then
     sspr(0,10,4,4,_x*4-4,_y*4-4)
    elseif fog[_y][_x] == 2 then
     sspr(4,10,4,4,_x*4-4,_y*4-4)
    end
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

 print('cpu: '..stat(2),0,0,11) -- note: cpu usage
end


function _init()
 t=0
 alertlvl=1
end


__gfx__
dddd2220000011112222fffffffffffffffffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222fffffffffffffffffffff5f56666fff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0222000011112222ffffffffffffffffffffff5f66d65ff511115fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd0000000011112222fffffffffffffffffffff5ff66d6f5f511115fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dddd22021111dddd0000fffffffffffffffffffff5ff6d66252511115222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666644451111dddd0000ffffffffffffffffffff2222f66f2d2555555222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666655551111dddd0000ffffffffffffffffffffdddd55552225d5d55222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666654441111dddd0000ffffffffffffffffffffdddd522522255d5d5252ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66665555000000000000ffffffffffffffffffff22225ff5222555555222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66664454000000000000ffffffffffffffffffffffffffff5ffffffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffff5ffffffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000ffffffffffffffffffffffffffff5ffffffffff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000202000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00002020000000000000fffffffffffffffffffff3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000fffffffffffffffffffff3f3ccccfff555555fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000000000000000000ffffffffffffffffffffff3fc7cc3ff511115fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff0fffffffffffffff0ffffffffffffffffffffff3ffccccf3f511115fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff0ffffffffffffff000fffffffffffffffffffff3ffcc7c434511115444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000fffff00ffffff000ffffffffffffffffffff4444fccf464555555444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
00000ffff00ffffff000ffffffffffffffffffff6666555544456d6d5444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
0000f0ff0000fff0f000ffffffffffffffffffff666655554445d6d65454ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f000ffff0000fff0f0f0ffffffffffffffffffff44445ff5444555555444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff000000f000fffffffffffffffffffffffffffffff2ffffffffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0fff000000f000fffffffffffffffffffffffffffffff2ffffffffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f0f0ff00f00f00000fffffffffffffffffffffffffffffff2ffffffffff2ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
3bb3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111122222222111112222222222222
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
333bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff21111111111111111111111111111112
3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222111111111111111112
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff22222222222222111111111111111112
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111111111111111112
8888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111112222222222222
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111112222222222222
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112111112111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222222111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021112222222111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00021111111111111111111111111112
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00022222222222222222222222222222
__sfx__
000100000c030110200c0100201010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
