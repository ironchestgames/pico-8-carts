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

debugaistates=function(s)
 -- debug(s)
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
 end

 return dx,dy
end

function collideaabbs(aabb,other,_dx,_dy)

 -- set up result
 local dx,dy=_dx,_dy

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
 end

 -- todo: next pos along x and y together
 --       to test when moving from any corner quadrant

 return dx,dy
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
vfxs={} -- visual effects

-- todo: this is only convenience dev function
function createactor(params) -- note: mutates params

 -- state
 params.state_counter=0

 -- movement
 params.dx=0
 params.dy=0

 -- remove me
 params.removeme=false

 return params
end

-- todo: this is only convenience dev function
function createattack(params)

 -- remove me
 params.removeme=false

 return params
end


-- items
sword={
 frames={
  currentframe=1,
  idling={{9,9,5,5, -2,-3}},
  moving={{9,9,5,5, -2,-3}},
  attacking={{14,9,5,5, -2,-3},{18,9,7,5, -3,-3}},
  recovering={{9,9,5,5, -2,-3}},
 },
}


-- skills
swordattackskill={
 preperformdur=15,
 postperformdur=28,
 perform=function(skill,user)
  local x=user.x+cos(user.a)*4
  local y=user.y+sin(user.a)*4

  add(attacks,createattack({
   x=x,
   y=y,
   halfw=2,
   halfh=2,
   state_counter=1,
   isknockback=true,
   knockbackangle=user.a,
   damage=1,
   targetcount=1000,
  }))

  -- add vfx
  angletofx={
   [0]={0,20,4,7, -1,-5}, -- right
   [0.125]={8,20,6,4, -3,-2}, -- right/up
   [0.25]={20,20,9,3, -3,-1}, -- up
   [0.375]={14,20,6,4, -2,-2}, -- up/left
   [0.5]={4,20,4,7, -2,-5}, -- left
   [0.625]={29,20,4,7, -3,-6}, -- left/down
   [0.75]={20,23,9,3, -4,-2}, -- down
   [0.875]={33,20,4,7, 0,-6}, -- down/right
  }

  local vfx=angletofx[user.a]
  vfx[5]=x+vfx[5]
  vfx[6]=y+vfx[6]
  vfx.counter=skill.postperformdur

  add(vfxs,vfx)
 end,
}

-- fireboltskill={
--  preperformdur=40,
--  postperformdur=0,
--  counter=30,
--  hasinput=false,
--  update=function(skill,user)
--   if skill.counter > 0 then
--    skill.counter-=1
--   end
--   if skill.hasinput and skill.counter <= 0 then
--    add(attacks,createattack({
--     x=user.x+cos(user.a)*4,
--     y=user.y+sin(user.a)*4,
--     halfw=1,
--     halfh=1,
--     dx=cos(user.a)*2,
--     dy=sin(user.a)*2,
--     damage=2,
--     targetcount=1,
--     -- todo: add effect
--    }))

--    -- reset skill
--    skill.hasinput=false

--    -- set user to recover
--    user.state='recovering'
--    user.state_counter=skill.postperformdur
--   end
--  end,
-- }


curenemyidx=1

function _init()

 -- reset vars
 curenemyidx=1

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
     state='idling',
     skill1=swordattackskill,
     skill2=fireboltskill,
     ispreperform=false,
     frames={
      currentframe=1,
      idling={{0,10,3,4, -1,-2}},
      moving={{0,10,3,4, -1,-2},{3,10,3,4, -1,-2}},
      attacking={{6,10,3,4, -1,-2},{0,10,3,4, -1,-2}},
      recovering={{0,10,3,4, -1,-2}},
     },
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
     frames={
      currentframe=1,
      idling={{0,16,3,4, -1,-2}},
      moving={animspd=0.18,{0,16,3,4, -1,-2},{3,16,3,4, -1,-2}},
      attacking={{0,16,3,4, -1,-2}},
      recovering={{0,16,3,4, -1,-2}},
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

function _update60()

 --note: devkit debug
 if stat(30)==true then
  c=stat(31)
  if c == 'd' then
   isdebug=not isdebug
   debug('isdebug',isdebug)
  end
 end

 -- consider dpad input
 local angle=btnmasktoangle[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle != nil then
  if avatar.state != 'recovering' and
     avatar.state != 'attacking' then
   avatar.a=angle
   avatar.dx=normalize(cos(avatar.a))
   avatar.dy=normalize(sin(avatar.a))
  end
 else
  avatar.dx=0
  avatar.dy=0
 end

 -- consider skill button input
 if btn(4) and
    (avatar.state == 'idling' or
     avatar.state == 'moving') then

  avatar.state='attacking'
  avatar.ispreperform=true

  avatar.state_counter=avatar.skill1.preperformdur

  avatar.frames.currentframe=1
  sword.frames.currentframe=1
 end

 -- if btn(5) and
 --    (avatar.state == 'idling' or
 --     avatar.state == 'moving') then
 --  avatar.skill2.hasinput=true
 --  avatar.skill2.counter=avatar.skill2.preperformdur

 --  avatar.state_counter=avatar.skill2.counter
 --  avatar.state='attacking'
 -- end

 -- consider avatar current state
 do
  local actor=avatar
  local skill=avatar.skill1

  -- count down
  if actor.state_counter > 0 then
   actor.state_counter-=1
  end

  -- is recovering
  if actor.state == 'recovering' then
   actor.dx=0
   actor.dy=0

  -- is attacking
  elseif actor.state == 'attacking' then
   actor.dx=0
   actor.dy=0

   -- update skills
   if actor.state_counter <= 0 then
    if actor.ispreperform == true then
     skill.perform(skill,actor)

     -- set actor to postperform
     actor.state_counter=skill.postperformdur
     actor.ispreperform=false

     -- set next attacking frame
     actor.frames.currentframe=2
     sword.frames.currentframe=2

    else -- note: done performing
     actor.state='idling'
     actor.frames.currentframe=1
     sword.frames.currentframe=1
    end
   end

  -- is moving
  elseif actor.dx != 0 or actor.dy != 0 then -- note: this feels like a hack...
   actor.state='moving'
   actor.state_counter=2

  -- go to idling
  elseif actor.state_counter <= 0 then
   actor.state='idling'
   actor.recovertype=nil
  end
 end


 -- debug('avatar state', avatar.state)


 -- todo: check for avatar death

 -- ai to make decisions
 curenemyidx+=1
 if curenemyidx > #actors then
  curenemyidx=1
 end
 do
  local enemy=actors[curenemyidx]
  if enemy.ai then

   -- resolving effect vars
   local isresolvingeffect=enemy.ai.state=='recovering'

   -- todo: ai should have aggravator instead of
   --       avatar hard-coded

   -- aggression vars
   local distancetoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)
   local withinattackdistance=distancetoavatar <= 7
   local haslostoavatar=haslos(floormap,enemy.x,enemy.y,avatar.x,avatar.y)
   local isswinging=enemy.ai.state == 'attacking' and enemy.ai.state_counter > 0

   -- movement vars
   local ismovingoutofcollision=enemy.ai.ismovingoutofcollision
   local collidedwithwall=enemy.ai.wallcollisiondx != nil
   local hastoocloseto=#enemy.ai.toocloseto > 0
   local hastarget=enemy.ai.targetx!=nil
   -- todo: maybe move away from avatar if too close?
   --       or at least stop


   if isresolvingeffect then
    debugaistates('isresolvingeffect')

    -- pass

   -- continue to move out of collision
   elseif ismovingoutofcollision then
    debugaistates('ismovingoutofcollision')

    enemy.ai.state='moving'

   -- attack
   elseif isswinging or withinattackdistance and haslostoavatar then
    debugaistates('withinattackdistance and haslostoavatar')

    enemy.ai.state='attacking'
    enemy.ai.targetx=avatar.x
    enemy.ai.targety=avatar.y
    -- todo: swing timer

   -- colliding w wall, move out of
   elseif collidedwithwall then
    debugaistates('collidedwithwall')

    enemy.ai.state='moving'
    local a=atan2(
      enemy.x+enemy.ai.wallcollisiondx-enemy.x,
      enemy.y+enemy.ai.wallcollisiondy-enemy.y)
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.ai.ismovingoutofcollision=true
    enemy.ai.state_counter=60

   -- colliding w other, move out of
   elseif hastoocloseto then
    debugaistates('hastoocloseto')

    enemy.ai.state='moving'
    local collidedwith=enemy.ai.toocloseto[1]
    local a=atan2(
      collidedwith.x-enemy.x,
      collidedwith.y-enemy.y)+0.5 -- note: go the other way
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.ai.ismovingoutofcollision=true
    enemy.ai.state_counter=60

   -- set avatar position as target, move there
   elseif haslostoavatar then
    debugaistates('haslostoavatar')

    enemy.ai.state='moving'
    enemy.ai.targetx=avatar.x
    enemy.ai.targety=avatar.y
    enemy.spd=enemy.runspd

   -- continue to move to target
   elseif hastarget then
    debugaistates('hastarget')

    enemy.ai.state='moving'

   -- roam
   elseif not hastarget then
    debugaistates('not hastarget')

    enemy.ai.state='moving'
    local a=rnd()
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.spd=enemy.runspd*0.5

   end
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
      x=enemy.x+cos(a)*4,
      y=enemy.y+sin(a)*4,
      halfw=2,
      halfh=2,
      state_counter=1,
      isknockback=true,
      knockbackangle=a,
      damage=1,
      targetcount=1000,
     }))

     enemy.ai.state='idling'
    end

   elseif enemy.ai.state == 'recovering' then
    enemy.ai.state_counter-=1
    if enemy.ai.state_counter <= 0 then
     enemy.ai.state='idling'
     enemy.recovertype=nil
    end

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
    attack.targetcount-=1

    -- knockback effect
    if attack.isknockback then
     actor.dx=cos(attack.knockbackangle)*5
     actor.dy=sin(attack.knockbackangle)*5
    end

    -- damage
    actor.hp-=attack.damage

    -- go into recovering
    if actor.ai then
     actor.ai.state='recovering'
     actor.ai.state_counter=30
     actor.recovertype='damage'
    else
     actor.state='recovering'
     actor.state_counter=30
     actor.recovertype='damage'
    end

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
   local _dx,_dy=collideaabbs(
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
  local _dx,_dy=floormapcollision(
    floormap,
    actor,
    actor.dx,
    actor.dy)

  if actor.ai then
   actor.ai.wallcollisiondx=nil
   actor.ai.wallcollisiondy=nil
   if _dx != actor.dx or
      _dy != actor.dy then
    actor.ai.wallcollisiondx=_dx
    actor.ai.wallcollisiondy=_dy
   end
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
   if attack.state_counter <= 0 or
      attack.targetcount <= 0 then
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

 -- update actor animation frames
 for actor in all(actors) do
  local state=actor.state
  if actor.ai then
   state=actor.ai.state
  end
  local stateframes=actor.frames[state]

  if state == 'moving' then
   local animspd=0.25
   if stateframes.animspd then
    animspd=stateframes.animspd
   end
   actor.frames.currentframe+=animspd*actor.spd
  end

  if actor.frames.currentframe >= #stateframes+1 then
   actor.frames.currentframe=1
  end
 end

 -- update vfx
 for vfx in all(vfxs) do
  vfx.counter-=1
  if vfx.counter <= 0 then
   vfx.removeme=true
  end
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

 -- draw attacks, note: this is only for debug
 if isdebug then
  for attack in all(attacks) do
   rectfill(
    attack.x-attack.halfw,
    attack.y-attack.halfh,
    attack.x+attack.halfw,
    attack.y+attack.halfh,
    9)
  end
 end

 -- todo: sort on y and z
 --       maybe z can be layers?
 --       per z add 128 (plus margin)
 --       to y when sorting

 -- draw actors
 for actor in all(actors) do

  if isdebug then
   local col=13

   local obj=actor
   if actor.ai then
    obj=actor.ai
   end

   if obj.state == 'recovering' then
    col=8
   elseif obj.state == 'attacking' then
    col=9
   end

   rectfill(
    actor.x-actor.halfw,
    actor.y-actor.halfh,
    actor.x+actor.halfw,
    actor.y+actor.halfh,
    col)
  end

  -- draw actor frame
  local state=actor.state
  if actor.ai then
   state=actor.ai.state
  end
  local stateframes=actor.frames[state]
  local frame=stateframes[flr(actor.frames.currentframe)]
  local flipx=false
  if actor.a != nil and actor.a >= 0.25 and actor.a <= 0.75 then
   flipx=true
  end
  if actor.recovertype == 'damage' then
   for i=1,15 do
    pal(i,8,0)
   end
  end
  sspr(
    frame[1],
    frame[2],
    frame[3],
    frame[4],
    actor.x+frame[5],
    actor.y+frame[6],
    frame[3],
    frame[4],
    flipx)

  -- draw items
  if actor == avatar then
   item=sword
   local stateframes=sword.frames[state]
   local currentframe=min(
     flr(item.frames.currentframe),
     #stateframes)
   local frame=stateframes[currentframe]
   palt(1,true)
   sspr(
    frame[1],
    frame[2],
    frame[3],
    frame[4],
    actor.x+frame[5],
    actor.y+frame[6],
    frame[3],
    frame[4],
    flipx)
   palt(1,false)
  end

  -- reset colors
  for i=1,15 do
   pal(i,i,0)
  end

  if isdebug then
   if actor.ai and actor.ai.targetx then
    haslos(floormap,actor.x,actor.y,actor.ai.targetx,actor.ai.targety)
   end

   pset(actor.x,actor.y,12)
  end
 end

 -- draw vfx
 for vfx in all(vfxs) do
  sspr(vfx[1],vfx[2],vfx[3],vfx[4],vfx[5],vfx[6])
 end

 -- dev stats
 print(avatar.hp .. ' hp',110,0,8)

 if avatar.ispreperform then
  color(10)
 else
  color(9)
 end
 print(avatar.state_counter, 70,0)


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
00000000011111116611111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00f00f511116111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555011116111111111660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05005005011111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050511111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070777700007777077777000070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007770077700777777770700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000777777000700000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000770077000700000007770000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000777777770777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000077777000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
10000000000000011000600600060001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
106000000f001111106000600f001111106000000f00111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000011111000000000001111100000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000011111006060000001111100000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000011000000000000001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10006011006000011006001100606001100000110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000011000000011000001100000001100000110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000011000111111060001100011111100000110001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10010000000111111001060000011111100100000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10010000060111111001000006011111100100000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000
10011110000000011001111000000001100111100000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000060000011060000006060001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000011000000000000001100000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
