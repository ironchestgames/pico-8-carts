pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- epic evil ender (v1.0)
-- by ironchest games

poke(24365,1) -- note: enable devkit
isdebug=false

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

debugb=function(n)
 outputstr=''
 local mask=0x0000.0001
 for i=0,31 do
  local bit=shr(band(shl(mask,i),n),i)
  if(bit!=0) bit=1
  outputstr=tostr(bit)..outputstr
 end
 debug(outputstr)
end

debugh=function(n)
 debug(tostr(n,true))
end

function isaabbscolliding(aabb1,aabb2)
 return aabb1.x - aabb1.halfw < aabb2.x + aabb2.halfw and
        aabb1.x + aabb1.halfw > aabb2.x - aabb2.halfw and
        aabb1.y - aabb1.halfh < aabb2.y + aabb2.halfh and
        aabb1.y + aabb1.halfh > aabb2.y - aabb2.halfh
end

wallaabb={
 x=0,
 y=0,
 halfw=4,
 halfh=4,
}
function isinsidewall(_floormap,aabb)
 local x1=aabb.x-aabb.halfw
 local y1=aabb.y-aabb.halfh
 local x2=aabb.x+aabb.halfw
 local y2=aabb.y+aabb.halfh

 local points={
  {x1,y1},
  {x2,y1},
  {x2,y2},
  {x1,y2},
 }

 for point in all(points) do
  local mapx=flr(point[1]/8)
  local mapy=flr(point[2]/8)
  wallaabb.x=mapx*8+wallaabb.halfw
  wallaabb.y=mapy*8+wallaabb.halfh

  -- note: hitboxes should not be larger than 8x8
  if _floormap[mapy][mapx] == 1 and
     isaabbscolliding(aabb,wallaabb) then
   return wallaabb
  end
 end

 return false
end

function haslos(_floormap,x0,y0,x1,y1) -- todo: refactor names to start at index 1
 local result={}
 local dx=abs(x1-x0)
 local dy=abs(y1-y0)
 local x=x0
 local y=y0
 local n=1+dx+dy
 local x_inc=-1
 if x1 > x0 then
  x_inc=1
 end

 local y_inc=-1
 if y1 > y0 then
  y_inc=1
 end

 local error=dx-dy
 dx*=2
 dy*=2

 while (n > 0) do
  n-=1

  if _floormap[flr(y/8)][flr(x/8)] == 1 then
   return false
  end

  if isdebug == true then
   pset(x,y,3)
  end

  if error > 0 then
   x+=x_inc
   error-=dy
  else
   y+=y_inc
   error+=dx
  end
 end
 return true
end

function dist(x1,y1,x2,y2)
 local dx=x2-x1
 local dy=y2-y1
 return sqrt(dx*dx+dy*dy)
end

function normalize(n)
 if n > 0 then
  return 1
 elseif n < 0 then
  return -1
 end
 return 0
end

function copytable(t)
 local newt={}
 for key,value in pairs(t) do
  newt[key]=value
 end
 return newt
end

newaabb={} -- note: used internally in collision funcs

function floormapcollision(_floormap,aabb,_dx,_dy)
 local dx,dy=_dx,_dy
 local hascollided=false

 -- set halfs
 newaabb.halfw=aabb.halfw
 newaabb.halfh=aabb.halfh

 -- next pos with new x
 newaabb.x=aabb.x+dx
 newaabb.y=aabb.y

 -- is it inside wall?
 local wallaabb=isinsidewall(_floormap,newaabb)
 if wallaabb then
  local idealdistx=aabb.halfw+wallaabb.halfw
  local curdistx=abs(aabb.x-wallaabb.x)
  if _dx > 0 then
   dx=(idealdistx-curdistx)*-1
  elseif _dx < 0 then
   dx=(idealdistx-curdistx)
  end
  hascollided=true
 end

 -- reset x and set new y
 newaabb.x=aabb.x
 newaabb.y=aabb.y+dy

 -- is it inside wall?
 local wallaabb=isinsidewall(_floormap,newaabb)
 if wallaabb then
  local idealdisty=aabb.halfh+wallaabb.halfh
  local curdisty=abs(aabb.y-wallaabb.y)
  if _dy > 0 then
   dy=(idealdisty-curdisty)*-1
  elseif _dy < 0 then
   dy=(idealdisty-curdisty)
  end
  hascollided=true
 end

 return dx,dy,hascollided
end

function collideaabbs(aabb,other,_dx,_dy)

 -- set up result
 local dx,dy=_dx,_dy
 local hascollided=false

 -- set aabb halfs
 newaabb.halfw=aabb.halfw
 newaabb.halfh=aabb.halfh

 -- set next pos along x
 newaabb.x=aabb.x+_dx
 newaabb.y=aabb.y

 -- is it colliding w other
 if isaabbscolliding(newaabb,other) then
  local idealdistx=aabb.halfw+other.halfw
  local curdistx=abs(aabb.x-other.x)
  if _dx > 0 then
   dx=(idealdistx-curdistx)*-1
  elseif dx < 0 then
   dx=(idealdistx-curdistx)
  end
  hascollided=true
 end

 -- set next pos along y
 newaabb.x=aabb.x
 newaabb.y=aabb.y+_dy

 -- is it colliding w other
 if isaabbscolliding(newaabb,other) then
  local idealdisty=aabb.halfh+other.halfh
  local curdisty=abs(aabb.y-other.y)
  if _dy > 0 then
   dy=(idealdisty-curdisty)*-1
  elseif _dy < 0 then
   dy=(idealdisty-curdisty)
  end
  hascollided=true
 end

 return dx,dy,hascollided
end

btnmasktoangle={
 [0x0002]=0, -- right
 [0x0006]=0.125, -- right/up
 [0x0004]=0.25, -- up
 [0x0005]=0.375, -- up/left
 [0x0001]=0.5, -- left
 [0x0009]=0.625, -- left/down
 [0x0008]=0.75, -- down
 [0x000a]=0.875, -- down/right
}

floormap={} -- the current map
avatar={} -- avatar actor handle
actors={} -- actors
attacks={} -- attack objects

function createactor(params) -- note: mutates params

 -- state
 params.state='idling'
 params.state_counter=0

 -- movement
 params.dx=0
 params.dy=0

 -- remove me
 params.removeme=false

 return params
end

function createattack(params)

 -- remove me
 params.removeme=false

 return params
end

function updateavatarstate(avatar)
 if avatar.state_counter > 0 then
  avatar.state_counter-=1
  if avatar.state_counter <= 0 then
   if avatar.state == 'attacking' or
      avatar.state == 'recovering' then
    avatar.state='idling'
   end
  end
 end

 if avatar.state == 'recovering' then
  avatar.dx=0
  avatar.dy=0
 end

 if avatar.state != 'charging' then
  avatar.charge=0
 end

 if avatar.state == 'attacking' then
  avatar.dx=0
  avatar.dy=0
 end
end


-- from={to,{prereqs},{ontransition}}

-- function updatestate(actor)
--  debug(actor.state)
--  local currenttransitions=actor.ai[actor.state].transitions
--  local nexttransition=nil
--  for transition in all(currenttransitions) do
--   local allprereqs=true
--   for prereq in all(transition[2]) do
--    if prereq(actor) == false then
--     allprereqs=false
--     break
--    end
--   end
--   if allprereqs then
--    nexttransition=transition
--   end
--  end

--  if nexttransition then
--   actor.state=nexttransition[1]
--   for predicate in all(nexttransition[3]) do
--    predicate(actor)
--   end
--  end
-- end

-- onstatecounterzero=function(actor)
--  return actor.state_counter <= 0
-- end

-- haslostotarget=function(actor)
--  if haslos(floormap,actor.x,actor.y,avatar.x,avatar.y) then

--   -- note: these are evil side effects,
--   --       because of performance
--   actor.ai.targetx=avatar.x
--   actor.ai.targety=avatar.y
--   return true
--  end
--  return false
-- end

-- nothaslostotarget=function(actor)
--  return not haslostotarget(actor)
-- end

-- debugme=function(actor)
--  debug(actor.state)
-- end

-- aimodes={ -- these perform state transitions
--  normal=function(actor)
--   local ai=actor.ai

--   if actor.state == 'recovering' then
--    actor.state_counter-=1
--    if actor.state_counter <= 0 then
--     actor.state='idling'
--    end

--   elseif actor.state == 'waiting' then
--    actor.state_counter-=1
--    if actor.state_counter <= 0 then
--     actor.state='idling'
--    end

--   elseif actor.state == 'attacking' then
--    actor.state_counter-=1
--    if actor.state_counter <= 0 then
--     local a=atan2(ai.targetx-actor.x,ai.targety-actor.y)

--     add(attacks,createattack({
--      isenemy=true,
--      x=actor.x+cos(a)*3,
--      y=actor.y+sin(a)*3,
--      halfw=2,
--      halfh=2,
--      state_counter=1,
--      isknockback=true,
--      knockbackangle=a,
--      damage=1,
--     }))

--     actor.state='idling'
--    end

--   elseif actor.state == 'idling' then
--    actor.state='searching'

--   elseif actor.state == 'searching' then
--    if ai.targetx != nil then -- note: implies targety is set too
--     actor.state='moving'
--    end

--   elseif actor.state == 'moving' then
  
--   else
--    ai.targetx=nil
--    ai.targety=nil
--    actor.state='idling'
--   end

--   -- update state
--   ai[actor.state](actor)

--  end,
-- }

-- aistates={

--  standingstill=function(actor)
--   actor.dx=0
--   actor.dy=0
--  end,

 -- searchingfortarget=function(actor)
 --  if haslos(floormap,actor.x,actor.y,avatar.x,avatar.y) then
 --   actor.ai.targetx=avatar.x
 --   actor.ai.targety=avatar.y

 --   -- if dist(actor.x,actor.y,ai.targetx,ai.targety) < 7 then
 --   --  actor.state='attacking'
 --   --  actor.state_counter=30
 --   -- end
 --  end
 -- end,

 -- movingtotarget=function(actor)
 --  local a=atan2(actor.ai.targetx-actor.x,actor.ai.targety-actor.y)
 --  actor.dx=cos(a)*actor.spd
 --  actor.dy=sin(a)*actor.spd
 -- end,

 -- recoveringfromhit=function(actor)
 --  actor.dx=0
 --  actor.dy=0
 -- end,

 -- normalattack=function(actor)
 --  actor.dx=0
 --  actor.dy=0
 -- end,
-- }

ai={
 curenemyidx=1,
 turnaroundbb={}, -- note: erased when curenemyidx resets
}

function _init()

 -- reset collections
 floormap={}
 actors={}
 attacks={}

 -- init floormap
 for _y=0,15 do
  floormap[_y]={}
  for _x=0,16 do
   local _col=sget(_x,64+_y)

   -- create avatar
   if _col == 15 then
    avatar=createactor({
     x=_x*8,
     y=_y*8,
     halfw=1.5,
     halfh=2,
     a=0,
     spd=0.5,
     hp=3,
     charge=0,
    })
    add(actors,avatar)

    _col=0 -- note: make tile ground
   end

   -- create skeleton enemy
   if _col == 6 then
    local enemy=createactor({
     isenemy=true,
     x=_x*8,
     y=_y*8,
     halfw=1.5,
     halfh=2,
     runspd=0.5,
     spd=0.5,
     hp=3,
     ai={
      state='idling',
      laststate='idling',
      state_counter=0,
      ismovingoutofcollision=false,
      toocloseto={},
     },
    })

    add(actors,enemy)
    _col=0 -- note: make tile ground
   end

   -- set floormap value
   floormap[_y][_x]=_col
  end
 end
end

btn4down=false
btn4pressed=false

function _update60()

 --note: devkit debug
 if stat(30)==true then
  c=stat(31)
  if c == 'd' then
   isdebug=not isdebug
   debug('isdebug',isdebug)
  end
 end

 -- massage input
 btn4pressed=false
 if btn(4) then
  if btn4down != true then
   btn4pressed=true
  end
  btn4down=true
 else
  btn4down=false
 end

 -- consider input
 local angle=btnmasktoangle[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle != nil then
  avatar.a=angle
  avatar.dx=normalize(cos(avatar.a))
  avatar.dy=normalize(sin(avatar.a))
 else
  avatar.dx=0
  avatar.dy=0
 end

 -- consider attack input
 if btn4pressed and
    (avatar.state == 'idling' or
     avatar.state == 'moving') then

  -- attack duration
  avatar.state='attacking'
  avatar.state_counter=16

  add(attacks,createattack({
   x=avatar.x+cos(avatar.a)*4,
   y=avatar.y+sin(avatar.a)*4,
   halfw=2,
   halfh=2,
   state_counter=1,
   isknockback=true,
   knockbackangle=avatar.a,
   damage=1,
  }))
 end

 if btn(5) and
    (avatar.state == 'idling' or
     avatar.state == 'moving' or
     avatar.state == 'charging') then
  avatar.state='charging'
  avatar.charge+=1
 elseif (not btn(5)) and
        avatar.state == 'charging' and
        avatar.charge > 60 then
  avatar.charge=0
  avatar.state='attacking'
  avatar.state_counter=1
  add(attacks,createattack({
   x=avatar.x+cos(avatar.a)*4,
   y=avatar.y+sin(avatar.a)*4,
   halfw=1,
   halfh=1,
   dx=cos(avatar.a)*2,
   dy=sin(avatar.a)*2,
   damage=2,
  }))
 end

 -- update current state counter
 updateavatarstate(avatar)

 -- ai to make decisions
 ai.curenemyidx+=1
 if ai.curenemyidx > #actors then
  ai.curenemyidx=1
 end
 do
  local enemy=actors[ai.curenemyidx]
  if enemy.ai then

   local distancetoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)

   local ismovingoutofcollision=enemy.ai.ismovingoutofcollision

   -- is colliding w other stuff
   local collidedwithwall=enemy.ai.iscollidingwithwall
   local hastoocloseto=#enemy.ai.toocloseto > 0
   -- todo: maybe move away from avatar if too close?

   -- has los to avatar
   -- todo: make this has los to aggravator
   local haslostoavatar=haslos(floormap,enemy.x,enemy.y,avatar.x,avatar.y)

   -- within attack distance to avatar
   -- todo: ...aggravator
   local withinattackdistance=distancetoavatar <= 7

   -- has target
   local hastarget=enemy.ai.targetx!=nil

   -- decision tree
   if ismovingoutofcollision then
    -- continue to move out of collision
    -- debug('ismovingoutofcollision')

    enemy.ai.state='moving'

   elseif withinattackdistance and haslostoavatar then
    -- attack
    -- debug('withinattackdistance and haslostoavatar')

    enemy.ai.state='attacking'
    -- todo: swing timer

   elseif collidedwithwall then
    -- colliding w wall, move out of
    -- debug('collidedwithwall')

    enemy.ai.state='moving'
    -- todo: get knowledge of what wall
    enemy.ai.ismovingoutofcollision=true
    enemy.ai.state_counter=60

   elseif hastoocloseto then
    -- colliding w other, move out of
    -- debug('hastoocloseto')

    enemy.ai.state='moving'
    local collidedwith=enemy.ai.toocloseto[1]
    local a=atan2(
      collidedwith.x-enemy.x,
      collidedwith.y-enemy.y)+0.5 -- note: go the other way
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.ai.ismovingoutofcollision=true
    enemy.ai.state_counter=60

   elseif haslostoavatar then
    -- set avatar position as target, move there
    -- debug('haslostoavatar')

    enemy.ai.state='moving'
    enemy.ai.targetx=avatar.x
    enemy.ai.targety=avatar.y
    enemy.spd=enemy.runspd

   elseif hastarget then
    -- continue to move to target
    -- debug('hastarget')

    enemy.ai.state='moving'

   elseif not hastarget then
    -- roam
    -- debug('not hastarget')

    enemy.ai.state='moving'
    local a=rnd()
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.spd=enemy.runspd*0.5

   end

   -- reset collided props
   enemy.ai.iscollidingwithwall=false
  end
 end

 -- update enemies
 for enemy in all(actors) do
  if enemy.ai then

   -- perform end of state action
   if enemy.ai.state == 'idling' then

    -- reset target etc
    enemy.ai.targetx=nil
    enemy.ai.targety=nil
    enemy.ai.ismovingoutofcollision=false

   elseif enemy.ai.state == 'attacking' then

    if enemy.ai.laststate != 'attacking' then

     enemy.ai.state_counter=50
    end

    enemy.ai.state_counter-=1
    if enemy.ai.state_counter <= 0 then

     local a=atan2(
      enemy.ai.targetx-enemy.x,
      enemy.ai.targety-enemy.y)

     add(attacks,createattack({
      isenemy=true,
      x=enemy.x+cos(a)*3,
      y=enemy.y+sin(a)*3,
      halfw=2,
      halfh=2,
      state_counter=1,
      isknockback=true,
      knockbackangle=a,
      damage=1,
     }))

     enemy.ai.state='idling'
    end

   elseif enemy.ai.state == 'recovering' then
    -- todo

   elseif enemy.ai.state == 'moving' then

    if enemy.ai.ismovingoutofcollision then
     enemy.ai.state_counter-=1
     if enemy.ai.state_counter <= 0 then
      enemy.ai.ismovingoutofcollision=false
     end
    end

    enemy.a=atan2(
      enemy.ai.targetx-enemy.x,
      enemy.ai.targety-enemy.y)
    enemy.dx=cos(enemy.a)*enemy.spd
    enemy.dy=sin(enemy.a)*enemy.spd

    if dist(
         enemy.x,
         enemy.y,
         enemy.ai.targetx,
         enemy.ai.targety) <= enemy.spd + 0.1 then
     enemy.ai.state='idling'
    end

   end

   enemy.ai.laststate=enemy.ai.state
  end
 end

 -- update the next-position
 for actor in all(actors) do

  -- note: after this deltas should not change by input
  actor.dx=actor.dx*actor.spd
  actor.dy=actor.dy*actor.spd
 end

 -- collide against attacks
 for attack in all(attacks) do
  for actor in all(actors) do
   if attack.removeme == false and
      actor.removeme == false and
      attack.isenemy != actor.isenemy and
      isaabbscolliding(attack,actor) then

    -- remove attack
    -- note: if attack has several hits,
    --       maybe just use one attack per hit?
    attack.removeme=true

    -- knockback effect
    if attack.isknockback then
     actor.dx=cos(attack.knockbackangle)*5
     actor.dy=sin(attack.knockbackangle)*5
    end

    -- damage
    actor.hp-=attack.damage

    -- go into recovering
    actor.state='recovering'
    actor.state_counter=20

    -- check if actor dead
    if actor.hp <= 0 then
     actor.removeme=true
    end
   end
  end
 end

 -- reset toocloseto
 for actor in all(actors) do
  if actor.ai then
   actor.ai.toocloseto={}
  end
 end

 -- enemies movement check against others
 for i=1,#actors-1 do
  for j=i+1,#actors do
   local enemy=actors[i]
   local other=actors[j]
   if enemy != other and
      enemy != avatar and
      other != avatar and
      enemy.ai and -- todo: also check for other.ai?
      dist(
        enemy.x,
        enemy.y,
        other.x,
        other.y) < enemy.halfh + other.halfh then
    add(enemy.ai.toocloseto,other)
    add(other.ai.toocloseto,enemy)
   end
  end
 end

 -- avatar movement check against other actors
 for actor in all(actors) do
  if actor != avatar then
   local _dx,_dy,hascollided=collideaabbs(
     avatar,
     actor,
     avatar.dx,
     avatar.dy)

   avatar.dx=_dx
   avatar.dy=_dy
  end
 end

 -- movement check against floormap
 for actor in all(actors) do

  -- collide against floor and get possible movement
  local _dx,_dy,hascollided=floormapcollision(
    floormap,
    actor,
    actor.dx,
    actor.dy)

  if actor.ai then
   actor.ai.iscollidingwithwall=hascollided
  end

  -- set actor pos based on possible movement
  actor.x+=_dx
  actor.y+=_dy
  actor.dx=0
  actor.dy=0
 end

 -- update attacks
 for attack in all(attacks) do
  if attack.state_counter != nil then
   attack.state_counter-=1
   if attack.state_counter <= 0 then
    attack.removeme=true
   end
  end

  if attack.dx != nil then
   attack.x+=attack.dx
  end

  if attack.dy != nil then
   attack.y+=attack.dy
  end

  if attack.x > 128 or
     attack.x < 0 or
     attack.y > 128 or
     attack.y < 0 or
     isinsidewall(floormap,attack) then
   attack.removeme=true
  end
 end

 -- update vfx
 for vfx in all(vfxs) do
  vfx.update()
 end

 -- remove actors
 for actor in all(actors) do
  if actor.removeme then
   del(actors,actor)
  end
 end

 -- remove attacks
 for attack in all(attacks) do
  if attack.removeme then
   del(attacks,attack)
  end
 end

 -- remove vfxs
 for vfx in all(vfxs) do
  if vfx.removeme then
   del(vfxs,vfx)
  end
 end
end


function _draw()
 cls()

 -- draw walls
 for _y=0,#floormap do
  for _x=0,#floormap[_y] do
   local mapval=floormap[_y][_x]
   if mapval != 0 then
    spr(0,_x*8,_y*8)

    if isdebug then
     rect(
       _x*8,
       _y*8,
       _x*8+wallaabb.halfw*2,
       _y*8+wallaabb.halfw*2,
       5)
    end
   end
  end
 end

 -- todo: sort on y and z
 --       maybe z can be layers?
 --       per z add 128 (plus margin)
 --       to y when sorting

 -- draw actors
 for actor in all(actors) do
  local col=6
  if actor == avatar then
   col=15
  end

  local obj=actor
  if actor.ai then
   obj=actor.ai
  end

  if obj.state == 'recovering' then
   col=8
  elseif obj.state == 'attacking' then
   col=7
  elseif obj.state == 'charging' then
   col=14
   if actor.charge > 60 then
    col=7
   end
  end

  rectfill(
   actor.x-actor.halfw,
   actor.y-actor.halfh,
   actor.x+actor.halfw,
   actor.y+actor.halfh,
   col)

  if isdebug then
   if actor.ai and actor.ai.targetx then
    haslos(floormap,actor.x,actor.y,actor.ai.targetx,actor.ai.targety)
   end

   pset(actor.x,actor.y,12)
  end
 end

 -- draw attacks
 for attack in all(attacks) do
  rectfill(
   attack.x-attack.halfw,
   attack.y-attack.halfh,
   attack.x+attack.halfw,
   attack.y+attack.halfh,
   9)
 end

 print(avatar.hp .. ' hp',110,0,8)

 -- prints debug stats
 -- if isdebug then
 print(stat(1),0,0,7)
 print(stat(7),0,6,7)
 -- end
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10010011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00f000000000000000000700000000777700000007777700000007777000000007000000000000000000000000000000000000000000000000000000000000
55555500000000000000000070000000007770000077777777000077700000000070000000000000000000000000000000000000000000000000000000000000
05005000000000000000000070000000000777000070000000700777000000000070000000000000000000000000000000000000000000000000000000000000
5050500000000000000f000077000000f007700000000f000000007700f000000770000f000000700000f000000000000f000000000000f00000700000000000
00000000000000000665566077000066556600000066555600000006655660000770665566000070066556600000006655660000000066556600700000000000
00000000000000000665000777000066500000000000056600000000005660000777000566000077000056600000000005660000000066500007700000000000
06006000000000000050507777000005050000000000505000000000050500000777705050000077770505000000000050500000000005050777700000000000
66666600000000000000000000000000000000000000000000000000000000000000000000000007770000000000070000000700000000000777000000000000
06006000000000000000000000000000000000000000000000000000000000000000000000000000700000000000077777777000000000000070000000000000
60606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000011000000000000001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10006006000600011000600600060001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
106000600f001111106000600f001111106000000f00111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000011111000000000001111100000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10060600000011111006060000001111100000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000011000000000000001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10060011006060011006001100606001100000110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000011000000011000001100000001100000110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10600011000111111060001100011111100000110001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10010600000111111001060000011111100100000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10010000060111111001000006011111100100000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10011110000000011001111000000001100111100000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10600000060600011060000006060001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000011000000000000001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
