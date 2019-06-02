pico-8 cartridge // http://www.pico-8.com
version 18
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

dungeonlevel=1 -- current dungeon depth
dungeonthemes={0,3}
dungeontheme=1 -- 1 tower, 2 cave
floormap={} -- the current map
exitdoor={} -- the exitdoor
actors={} -- actors
attacks={} -- attack objects
vfxs={} -- visual effects
pemitters={} -- particle emitters

dmgfxdur=20

-- todo: this is only convenience dev function
function createactor(params) -- note: mutates params

 -- state
 params.state_counter=0

 -- movement
 params.dx=0
 params.dy=0

 -- damage indicator
 params.dmgfxcounter=0

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

function createpemitter(params)
 
 -- start counter
 params.counter=params.prate[1]

 -- defaults
 params.removeme=false

 -- particles
 params.particles={}

 return params
end

-- skills
swordattackskill={
 sprite=15,
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
   isphysical=true,
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

  local frame=angletofx[user.a]
  frame[5]=x+frame[5]
  frame[6]=y+frame[6]
  frame.counter=skill.postperformdur
  local vfx={frame}

  add(vfxs,vfx)
 end,
}

bowattackskill={
 sprite=14,
 preperformdur=26,
 postperformdur=6,
 perform=function(skill,user)
  local x=user.x+cos(user.a)*4
  local y=user.y+sin(user.a)*4

  -- arrow frame
  local angletoframe={
   [0]={50,20,2,1, -1,-0.5}, -- right
   [0.125]={52,20,2,2, -1,-1}, -- right/up
   [0.25]={54,20,1,2, -0.5,-1}, -- up
   [0.375]={55,20,2,2, -1,-1}, -- up/left
   [0.5]={50,20,2,1, -1,-0.5}, -- left
   [0.625]={52,20,2,2, -1,-1}, -- left/down
   [0.75]={54,20,1,2, -0.5,-1}, -- down
   [0.875]={55,20,2,2, -1,-1}, -- down/right
  }

  local frame=angletoframe[user.a]

  local attack=createattack({
   x=x-0.5,
   y=y-0.5,
   halfw=1,
   halfh=1,
   state_counter=1000,
   dx=cos(user.a)*1.6,
   dy=sin(user.a)*1.6,
   damage=1,
   targetcount=1,
   frames={
    currentframe=1,
    frame,
   }
  })

  add(attacks,attack)

  -- add vfx
  angletofx={
   [0]={0,27,6,7, -3,-5}, -- right
   [0.125]={17,32,7,7, -4,-3}, -- right/up
   [0.25]={10,31,7,6, -3,-3}, -- up
   [0.375]={34,32,7,7, -3,-3}, -- up/left
   [0.5]={4,27,6,7, -2,-5}, -- left
   [0.625]={22,27,7,7, -2,-5}, -- left/down
   [0.75]={10,27,7,6, -3,-4}, -- down
   [0.875]={29,27,7,7, -4,-4}, -- down/right
  }

  local frame=angletofx[user.a]
  frame[5]=x+frame[5]
  frame[6]=y+frame[6]
  frame.counter=skill.postperformdur
  local vfx={frame}

  add(vfxs,vfx)
 end,
}

fireboltskill={
 sprite=13,
 preperformdur=40,
 postperformdur=0,
 startpemitter=function(user,life)
  add(pemitters,createpemitter({
   follow=user,
   life=life,
   prate={2,4},
   plife={15,25},
   poffsets={-2,0.5,2,0.5},
   dx={0,0},
   dy={-0.3,0},
   pcolors={8,14},
  }))
 end,
 perform=function(skill,user)
  local x=user.x+cos(user.a)*4
  local y=user.y+sin(user.a)*4

  local attack=createattack({
   x=x,
   y=y,
   halfw=1,
   halfh=1,
   state_counter=1000,
   dx=cos(user.a)*1.2,
   dy=sin(user.a)*1.2,
   damage=2,
   targetcount=1,
   frames={
    currentframe=1,
    {47,20,3,3, -0.5,-0.5},
   }
  })

  add(attacks,attack)

  add(pemitters,createpemitter({
   follow=attack,
   life=1000,
   prate={0,1},
   plife={3,5},
   poffsets={-1,-1,1,1},
   dx={0,0},
   dy={0,0},
   -- pcolors={9,8},
   -- pcolors={8,2},
   pcolors={14,8},
  }))

 end,
}


-- items
sword={
 sprite=15,
 skill=swordattackskill,
 frames={
  currentframe=1,
  idling={{9,9,5,5, -2,-3}},
  moving={{9,9,5,5, -2,-3}},
  attacking={{14,9,5,5, -2,-3},{18,9,7,5, -3,-3}},
  recovering={{9,9,5,5, -2,-3}},
 },
}

bow={
 sprite=14,
 skill=bowattackskill,
 frames={
  currentframe=1,
  idling={{25,9,5,5, -2,-3}},
  moving={{25,9,5,5, -2,-3}},
  attacking={{30,9,5,5, -2,-3},{25,9,1,1, -2,-3}},
  recovering={{25,9,5,5, -2,-3}},
 },
}

fireboltbook={
 sprite=13,
 skill=fireboltskill,
 frames={
  currentframe=1,
  idling={{9,9,1,1, 0,0}},
  moving={{9,9,1,1, 0,0}},
  attacking={{9,9,1,1, 0,0},{9,9,1,1, 0,0}},
  recovering={{9,9,1,1, 0,0}},
 },
}

avatar=createactor({
 x=0,
 y=0,
 halfw=1.5,
 halfh=2,
 a=0,
 spd=0.5,
 hp=3,
 armor=1,
 state='idling',
 primaryitem=bow,
 secondaryitem=fireboltbook,
 skill1=nil,
 skill2=nil,
 currentskill=nil,
 ispreperform=false,
 frames={
  currentframe=1,
  idling={{0,10,3,4, -1,-2}},
  moving={{0,10,3,4, -1,-2},{3,10,3,4, -1,-2}},
  attacking={animspd=0,{6,10,3,4, -1,-2},{0,10,3,4, -1,-2}},
  recovering={{0,10,3,4, -1,-2}},
 },
})


function nextfloor()
 dungeonlevel+=1
 dungeoninit()
end

curenemyidx=1

function dungeoninit()

 -- set callbacks
 _update60=dungeonupdate
 _draw=dungeondraw

 -- reset vars
 curenemyidx=1

 -- reset collections
 floormap={}
 actors={}
 attacks={}
 pemitters={}

 local basemap={}

 -- create base map (on spritesheet)
 do
  local getnewdeltaangle=function()
   local angles={-0.25,0.25}
   return angles[flr(rnd(#angles)+1)]
  end

  for y=0,15 do
   for x=0,15 do
    sset(x,y+64,1)
   end
  end

  local avatarx=flr(rnd(14))+1
  local avatary=flr(rnd(14))+1

  if avatar != nil then
   avatarx=mid(2,flr(avatar.x/8),14)
   avatary=mid(2,flr(avatar.y/8),14)
   debug(avatar.x,avatar.y,avatarx,avatary)
  end

  local curx=avatarx
  local cury=avatary
  local angle=0
  local steps=500
  local stepcount=steps
  local enemycount=10
  local enemytypes={5,6,7}
  local enemies={}

  while stepcount > 0 do

   local nextx=curx+cos(angle)
   local nexty=cury+sin(angle)

   if flr(rnd(3)) == 0 or
      nextx <= 0 or
      nextx > 14 or
      nexty <= 0 or
      nexty > 14 then
    angle+=getnewdeltaangle()
   elseif stepcount != 0 and stepcount % (steps / enemycount) == 0 then
    add(enemies,{
     x=curx,
     y=cury,
     typ=enemytypes[flr(rnd(#enemytypes)+1)],
    })
   else
    curx=nextx
    cury=nexty
    sset(curx,cury+64,0)
   end
   stepcount-=1
  end

  -- enemies
  for enemy in all(enemies) do
   sset(enemy.x,enemy.y+64,enemy.typ)
  end
  -- local enemy=enemies[1]
  -- sset(enemy.x,enemy.y+64,enemy.typ)

  -- exitdoor
  sset(curx,cury+64,2)

  -- avatar
  sset(avatarx,avatary+64,15)

 end

 -- init floormap and objects
 for _y=0,15 do
  floormap[_y]={}
  for _x=0,16 do
   local _col=sget(_x,64+_y)

   -- create avatar
   if _col == 15 then
    avatar=createactor(avatar)
    avatar.x=_x*8+4
    avatar.y=_y*8+4
    avatar.armor=1

    add(actors,avatar)

    _col=0 -- note: make tile ground
   end

   -- create bat enemy
   if _col == 5 then
    local enemy=createactor({
     isenemy=true,
     isghost=true,
     x=_x*8+4,
     y=_y*8+4,
     a=0,
     halfw=1.5,
     halfh=2,
     runspd=0.75,
     spd=0.75,
     hp=1,
     attack={
      typ='melee',
      spd=30,
     },
     ai={
      state='idling',
      laststate='idling',
      state_counter=0,
      ismovingoutofcollision=false,
      toocloseto={},
     },
     frames={
      currentframe=1,
      idling={{36,15,3,3, -1.5,-1.5}},
      moving={animspd=0.21,{36,15,3,3, -1.5,-1.5},{39,15,3,3, -1.5,-1.5}},
      attacking={animspd=0.32,{36,15,3,3, -1.5,-1.5},{39,15,3,3, -1.5,-1.5}},
      recovering={{36,15,3,3, -1.5,-1.5}},
     },
    })

    add(actors,enemy)
    _col=0 -- note: make tile ground
   end

   -- create sword skeleton enemy
   if _col == 6 then
    local enemy=createactor({
     isenemy=true,
     x=_x*8+4,
     y=_y*8+4,
     a=0,
     halfw=1.5,
     halfh=2,
     runspd=0.5,
     spd=0.5,
     hp=3,
     attack={
      typ='melee',
      spd=50,
     },
     ai={
      state='idling',
      laststate='idling',
      state_counter=0,
      ismovingoutofcollision=false,
      toocloseto={},
     },
     frames={
      currentframe=1,
      idling={{0,15,4,5, -2,-3}},
      moving={animspd=0.18,{0,15,4,5, -2,-3},{4,15,4,5, -2,-3}},
      attacking={{8,15,4,5, -2,-3}},--,{11,15,5,5, -2,-3}},
      recovering={{0,15,4,5, -2,-3}},
     },
    })

    add(actors,enemy)
    _col=0 -- note: make tile ground
   end

   -- create bow skeleton enemy
   if _col == 7 then
    local enemy=createactor({
     isenemy=true,
     x=_x*8+4,
     y=_y*8+4,
     a=0,
     halfw=1.5,
     halfh=2,
     runspd=0.5,
     spd=0.5,
     hp=2,
     attack={
      typ='ranged',
      spd=70,
     },
     ai={
      state='idling',
      laststate='idling',
      state_counter=0,
      ismovingoutofcollision=false,
      toocloseto={},
     },
     frames={
      currentframe=1,
      idling={{18,15,4,5, -2,-3}},
      moving={animspd=0.18,{18,15,4,5, -2,-3},{22,15,4,5, -2,-3}},
      attacking={{26,15,4,5, -2,-3}},--,{11,15,5,5, -2,-3}},
      recovering={{18,15,4,5, -2,-3}},
     },
    })

    add(actors,enemy)
    _col=0 -- note: make tile ground

   -- create exitdoor
   elseif _col == 2 then
    exitdoor={
     x=_x*8+4,
     y=_y*8+4,
     halfw=4,
     halfh=4,
     isopen=false,
    }
    _col=0
   end

   -- set floormap value
   floormap[_y][_x]=_col
  end
 end
end


function dungeonupdate()

 --note: devkit debug
 if stat(30)==true then
  c=stat(31)
  if c == 'd' then
   isdebug=not isdebug
   debug('isdebug',isdebug)
  end
  if c == '1' then
   avatar.primaryitem=sword
  end
  if c == '2' then
   avatar.primaryitem=bow
  end
 end

 if avatar.hp <= 0 then
  return nil
 end

 -- update skills from items
 avatar.skill1=avatar.primaryitem.skill
 avatar.skill2=avatar.secondaryitem.skill

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
 local skillbuttondown=0
 if btn(4) then
  skillbuttondown=1
 elseif btn(5) then
  skillbuttondown=2
 end

 if skillbuttondown != 0 and
    (avatar.state == 'idling' or
     avatar.state == 'moving') then

  local skill=avatar['skill'..skillbuttondown]

  avatar.state='attacking'
  avatar.currentskill=skill
  avatar.ispreperform=true

  avatar.state_counter=skill.preperformdur

  avatar.frames.currentframe=1
  avatar.primaryitem.frames.currentframe=1

  if avatar.currentskill.startpemitter then
   avatar.currentskill.startpemitter(avatar,skill.preperformdur)
  end
 end

 -- consider avatar current state
 do
  local actor=avatar

  -- count down
  if actor.state_counter > 0 then
   actor.state_counter-=1
  end

  -- is recovering
  if actor.state == 'recovering' then
   actor.dx=0
   actor.dy=0

   if actor.state_counter <= 0 then
    actor.state='idling'
   end

  -- is attacking
  elseif actor.state == 'attacking' then
   actor.dx=0
   actor.dy=0

   -- update skills
   if actor.state_counter <= 0 then
    if actor.ispreperform == true then

     local skill=avatar.currentskill
     skill.perform(skill,actor)

     -- set actor to postperform
     actor.state_counter=skill.postperformdur
     actor.ispreperform=false

     -- set next attacking frame
     actor.frames.currentframe=2
     avatar.primaryitem.frames.currentframe=2

    else -- note: done performing
     actor.state='idling'
     actor.frames.currentframe=1
     avatar.primaryitem.frames.currentframe=1
    end
   end

  -- is moving
  elseif actor.dx != 0 or actor.dy != 0 then -- note: this feels like a hack...
   actor.state='moving'
   actor.state_counter=2

  -- go to idling
  elseif actor.state_counter <= 0 then
   actor.state='idling'
   avatar.currentskill=nil
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
  if avatar.hp > 0 and enemy.ai then

   -- resolving effect vars
   local isresolvingeffect=enemy.ai.state=='recovering'

   -- todo: ai should have aggravator instead of
   --       avatar hard-coded

   -- aggression vars
   local distancetoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)
   local withinattackdistance=distancetoavatar <= 7
   if enemy.attack.typ == 'ranged' then
    withinattackdistance=distancetoavatar <= 40
   end
   local haslostoavatar=haslos(floormap,enemy.x,enemy.y,avatar.x,avatar.y)
   local isswinging=enemy.ai.state == 'attacking' and enemy.ai.state_counter > 0

   -- movement vars
   local ismovingoutofcollision=enemy.ai.ismovingoutofcollision
   local collidedwithwall=enemy.ai.wallcollisiondx != nil
   local istooclosetoavatar=distancetoavatar <= 1
   if enemy.attack.typ == 'ranged' then
    istooclosetoavatar=distancetoavatar <= 20
   end
   local hastoocloseto=#enemy.ai.toocloseto > 0
   local hastarget=enemy.ai.targetx!=nil


   if isresolvingeffect then
    debugaistates('isresolvingeffect')

    -- pass

   -- continue to move out of collision
   elseif ismovingoutofcollision then
    debugaistates('ismovingoutofcollision')

    enemy.ai.state='moving'

   -- too close to avatar, note: collidedwithwall not working here?
   elseif istooclosetoavatar and (not isswinging) and (not collidedwithwall) then
    debugaistates('istooclosetoavatar and not swinging')

    enemy.ai.state='moving'
    local a=atan2(
      avatar.x-enemy.x,
      avatar.y-enemy.y)+0.5 -- note: go the other way
    enemy.ai.targetx=enemy.x+cos(a)*10
    enemy.ai.targety=enemy.y+sin(a)*10
    enemy.ai.ismovingoutofcollision=true
    enemy.ai.state_counter=60
    enemy.spd=enemy.runspd

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
      enemy.y+enemy.ai.wallcollisiondy-enemy.y)+rnd(0.2)-0.1
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
 local enemycount=0
 for enemy in all(actors) do
  if enemy.ai then

   enemycount+=1

   -- perform end of state action
   if enemy.ai.state == 'idling' then

    -- reset target etc
    enemy.ai.targetx=nil
    enemy.ai.targety=nil
    enemy.ai.ismovingoutofcollision=false

   elseif enemy.ai.state == 'attacking' then

    if enemy.ai.laststate != 'attacking' then

     enemy.ai.state_counter=enemy.attack.spd
    end

    enemy.ai.state_counter-=1
    if enemy.ai.state_counter <= 0 then

     if enemy.attack.typ == 'melee' then
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
       isphysical=true,
       knockbackangle=a,
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
       [1]={0,20,4,7, -1,-5}, -- right (wrapped)
      }

      local x=enemy.x+cos(enemy.a)*4
      local y=enemy.y+sin(enemy.a)*4

      local a=min(flr((enemy.a+0.0625)*8)/8,1)

      debug(enemy.a,a)

      local frame=angletofx[a]
      frame[5]=x+frame[5]
      frame[6]=y+frame[6]
      frame.counter=10
      local vfx={frame}

      add(vfxs,vfx)



     elseif enemy.attack.typ == 'ranged' then

      local a=atan2(
       enemy.ai.targetx-enemy.x,
       enemy.ai.targety-enemy.y)

      a=min(flr((a+0.0625)*8)/8,1)

      -- arrow frame
      local angletoframe={
       [0]={50,20,2,1, -1,-0.5}, -- right
       [0.125]={52,20,2,2, -1,-1}, -- right/up
       [0.25]={54,20,1,2, -0.5,-1}, -- up
       [0.375]={55,20,2,2, -1,-1}, -- up/left
       [0.5]={50,20,2,1, -1,-0.5}, -- left
       [0.625]={52,20,2,2, -1,-1}, -- left/down
       [0.75]={54,20,1,2, -0.5,-1}, -- down
       [0.875]={55,20,2,2, -1,-1}, -- down/right
       [1]={50,20,2,1, -1,-0.5}, -- right (wrapped)
      }

      local frame=angletoframe[a]

      local attack=createattack({
       isenemy=true,
       x=enemy.x-0.5,
       y=enemy.y-0.5,
       halfw=1,
       halfh=1,
       state_counter=1000,
       dx=cos(a)*1.6,
       dy=sin(a)*1.6,
       damage=1,
       targetcount=1,
       frames={
        currentframe=1,
        frame,
       }
      })

      add(attacks,attack)
     end

     enemy.ai.state='idling'
    end

   elseif enemy.ai.state == 'recovering' then
    enemy.ai.state_counter-=1
    if enemy.ai.state_counter <= 0 then
     enemy.ai.state='idling'
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

 -- update exitdoor
 if enemycount == 0 then
  floormap[(exitdoor.y-4)/8][(exitdoor.x-4)/8]=0
  exitdoor.isopen=true
 end

 -- update the next-position
 for actor in all(actors) do

  -- note: after this deltas should not change by input
  actor.dx=actor.dx*actor.spd
  actor.dy=actor.dy*actor.spd
 end

 -- collide avatar against door
 if exitdoor.isopen and
    isaabbscolliding(avatar,exitdoor) then
  nextfloor()
  return
 end

 -- collide against attacks
 for attack in all(attacks) do
  for actor in all(actors) do
   if attack.removeme == false and
      actor.removeme == false and
      attack.isenemy != actor.isenemy and
      isaabbscolliding(attack,actor) then

    -- count hit
    attack.targetcount-=1

    -- do damage
    if actor.armor != nil and actor.armor > 0 then
     actor.armor-=attack.damage
     if actor.armor < 0 then
      actor.hp+=actor.armor
      actor.armor=0
     end
    else
     actor.hp-=attack.damage
    end

    -- go into recovering
    if actor.ai then
     actor.ai.state='recovering'
     actor.ai.state_counter=0
    else
     actor.state='recovering'
     actor.state_counter=0
    end

    -- check if actor dead
    if actor.hp <= 0 then
     actor.removeme=true

     -- todo: add death vfx here
    end

    -- effects

    -- physical knockback effect
    if attack.isphysical then
     actor.dx=cos(attack.knockbackangle)*5
     actor.dy=sin(attack.knockbackangle)*5
    end

    -- vfx

    -- start damage indication
    actor.dmgfxcounter=dmgfxdur

    -- hit flash
    local x=actor.x+actor.dx/2
    local y=actor.y+actor.dy/2
    add(vfxs,{
     {37,20,5,5,x-2.5,y-2.5,counter=4},
     {42,20,5,5,x-2.5,y-2.5,counter=5},
    })

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
  if actor != avatar and not actor.isghost then
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

 -- update damage indicator
 for actor in all(actors) do
  if actor.dmgfxcounter > 0 then
   actor.dmgfxcounter-=1
  end
 end

 -- update actor animation frames
 for actor in all(actors) do
  local state=actor.state
  if actor.ai then
   state=actor.ai.state
  end
  local stateframes=actor.frames[state]

  local animspd=0.25 -- note: default
  if stateframes.animspd then
   animspd=stateframes.animspd
  end
  actor.frames.currentframe+=animspd*actor.spd

  if actor.frames.currentframe >= #stateframes+1 then
   actor.frames.currentframe=1
  end
 end

 -- update vfx
 for vfx in all(vfxs) do
  vfx[1].counter-=1
  if vfx[1].counter <= 0 then
   del(vfx,vfx[1])
  end

  if not(#vfx > 0) then
   vfx.removeme=true
  end
 end

 -- update pemitters
 for pemitter in all(pemitters) do
  pemitter.counter-=1
  if pemitter.counter <= 0 then
   local x=pemitter.follow.x
   local y=pemitter.follow.y
   local poffsets=pemitter.poffsets
   local pdx=pemitter.dx
   local pdy=pemitter.dy

   x+=poffsets[1]+rnd(poffsets[3]+abs(poffsets[1]))
   y+=poffsets[2]+rnd(poffsets[4]+abs(poffsets[2]))

   local dx=pdx[1]+rnd(pdx[2]+abs(pdx[1]))
   local dy=pdy[1]+rnd(pdy[2]+abs(pdy[1]))

   add(pemitter.particles,{
    counter=
      pemitter.plife[1]+rnd(pemitter.plife[2]),
    x=x,
    y=y,
    dx=dx,
    dy=dy,
   })

   pemitter.counter=
     pemitter.prate[1]+rnd(pemitter.prate[2])
  end

  pemitter.life-=1
  if pemitter.life <= 0 then
   pemitter.removeme=true
  end

  -- update this pemitters particles
  for particle in all(pemitter.particles) do
   particle.counter-=1
   particle.col=pemitter.pcolors[1]
   particle.x+=particle.dx
   particle.y+=particle.dy
   if particle.counter <= pemitter.plife[1] then
    particle.col=pemitter.pcolors[2]
   end

   if particle.counter <= 0 then
    del(pemitter.particles,particle)
   end
  end

 end

 -- remove pemitters
 for pemitter in all(pemitters) do
  if pemitter.removeme or
     pemitter.follow.removeme then
   del(pemitters,pemitter)
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


function dungeondraw()
 cls(0)

 -- get theme offset
 local themeoffset=dungeonthemes[dungeontheme]

 -- draw walls
 for _y=0,#floormap do
  for _x=0,#floormap[_y] do
   local mapval=floormap[_y][_x]
   if mapval != 0 then

    if floormap[_y+1] and floormap[_y+1][_x] != 0 then
     spr(themeoffset+1,_x*8,_y*8)
    else
     spr(themeoffset+0,_x*8,_y*8)
    end

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

 -- draw exitdoor
 if exitdoor.isopen then
  spr(
   themeoffset+2,
   exitdoor.x-exitdoor.halfw,
   exitdoor.y-exitdoor.halfh)

  if isdebug then
   rectfill(
    exitdoor.x-exitdoor.halfw,
    exitdoor.y-exitdoor.halfh,
    exitdoor.x+exitdoor.halfw,
    exitdoor.y+exitdoor.halfh,
    9)
  end
 end

 -- draw attacks
 for attack in all(attacks) do

  if attack.frames then
   local frame=attack.frames[attack.frames.currentframe]
   sspr(
    frame[1],
    frame[2],
    frame[3],
    frame[4],
    attack.x+frame[5],
    attack.y+frame[6],
    frame[3],
    frame[4])
  end

  if isdebug then
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
  if actor.dmgfxcounter > 0 then
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
   item=avatar.primaryitem
   local stateframes=item.frames[state]
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
  local frame=vfx[1]
  sspr(frame[1],frame[2],frame[3],frame[4],frame[5],frame[6])
 end

 -- draw particles
 for pemitter in all(pemitters) do
  for particle in all(pemitter.particles) do
   pset(
     particle.x,
     particle.y,
     particle.col)
  end
 end

 -- dev stats
 print(avatar.hp .. ' hp',110,0,8)
 print(avatar.armor .. ' a',90,0,6)
 if avatar.hp <= 0 then
  print('dead',60,60,8)
 end

 if avatar.ispreperform then
  color(10)
 else
  color(9)
 end
 print(avatar.state_counter,70,0)

 local enemycount=0
 for actor in all(actors) do
  if actor.ai then
   enemycount+=1
  end
 end
 print(enemycount,50,0,6)

 print(dungeonlevel,120,122,13)

 -- prints debug stats
 -- if isdebug then
 print(stat(1),0,0,7)
 print(stat(7),0,6,7)
 -- end
end




-- equip scene

local inventorycur=1 -- todo: make curs dynamic
local equippedcur=1
local availableskillscur=1
local sectioncur=1
local inventory={}
local equipped={}
local availableskills={}

function equipinit()
 _update60=equipupdate
 _draw=equipdraw

end

function equipupdate()

 -- init inventory
 inventory={
  sword,
  bow,
  fireboltbook,
 }

 -- init equipped items
 equipped={}
 if avatar.primaryitem then
  add(equipped,avatar.primaryitem)
 end

 if avatar.secondaryitem then
  add(equipped,avatar.secondaryitem)
 end

 -- init available skills
 availableskills={}
 for item in all(equipped) do
  if item.skill then
   add(availableskills,item.skill)
  end
 end

 -- changing sections
 if btnp(2) then
  sectioncur=mid(1,sectioncur-1,4)
 elseif btnp(3) then
  sectioncur=mid(1,sectioncur+1,4)
 end

 -- inventory
 if sectioncur == 1 then
  if btnp(0) then
   inventorycur=mid(1,inventorycur-1,#inventory)
  elseif btnp(1) then
   inventorycur=mid(1,inventorycur+1,#inventory)
  end

  if btnp(4) or btnp(5) then
   avatar.primaryitem=inventory[inventorycur]
  end

 -- equipped
 elseif sectioncur == 2 then
  if btnp(0) then
   equippedcur=mid(1,equippedcur-1,#equipped)
  elseif btnp(1) then
   equippedcur=mid(1,equippedcur+1,#equipped)
  end

  if btnp(4) or btnp(5) then
   avatar.primaryitem=nil
  end

 -- available skills
 elseif sectioncur == 3 then
  if btnp(0) then
   availableskillscur=mid(1,availableskillscur-1,#availableskills)
  elseif btnp(1) then
   availableskillscur=mid(1,availableskillscur+1,#availableskills)
  end

  if btnp(4) then
   avatar.primaryitem,avatar.secondaryitem=
     avatar.secondaryitem,avatar.primaryitem
  elseif btnp(5) then
   avatar.primaryitem,avatar.secondaryitem=
     avatar.secondaryitem,avatar.primaryitem
  end

 -- exit
 elseif sectioncur == 4 then
  if btnp(4) or btnp(5) then
   dungeoninit()
  end
 end

end

function equipdraw()

 cls(0)

 -- draw inventory section
 local offsetx=0
 local y=17
 local i=1
 if sectioncur == 1 then
  print('saddlebags',7,y-9,10)
 else
  print('saddlebags',7,y-9,4)
 end
 for item in all(inventory) do
  spr(item.sprite,9+offsetx,y)
  if sectioncur == 1 and i == inventorycur then
   rect(
    9+offsetx-2,
    y-2,
    9+offsetx+9,
    y+9,
    10)
  end

  offsetx+=12
  i+=1
 end

 -- draw equipped section
 offsetx=0
 y=52
 i=1
 if sectioncur == 2 then
  print('equipped',7,y-9,10)
 else
  print('equipped',7,y-9,4)
 end
 for item in all(equipped) do
  spr(item.sprite,9+offsetx,y)
  if sectioncur == 2 and i == equippedcur then
   rect(
    9+offsetx-2,
    y-2,
    9+offsetx+9,
    y+9,
    10)
  end

  offsetx+=12
  i+=1
 end

 -- draw availableskills section
 offsetx=0
 y=89
 i=1
 if sectioncur == 3 then
  print('skills',7,y-9,10)
 else
  print('skills',7,y-9,4)
 end
 for skill in all(availableskills) do
  spr(skill.sprite,9+offsetx,y)
  if sectioncur == 3 and i == availableskillscur then
   rect(
    9+offsetx-2,
    y-2,
    9+offsetx+9,
    y+9,
    10)
  end

  if skill == avatar.primaryitem.skill then
   print('\x8e',9+offsetx,y+12,12)
  elseif skill == avatar.secondaryitem.skill then
   print('\x97',9+offsetx,y+12,11)
  end

  offsetx+=12
  i+=1
 end

 -- draw exit button
 if sectioncur == 4 then
  print('exit',57,117,10)
 else
  print('exit',57,117,4)
 end


end








function _init()
 equipinit()
end




__gfx__
11111111111111110000005501111000011110000000000000000000000000000000000000000000000000000000000000000000008888800000004200000066
1111111111111111000551551111111111111111005005000000000000000000000000000000000000000000000000000000000008ffff40000006400000066d
000000001111111155155155110000111100001100555500000000000000000000000000000000000000000000000000000000000222224000006040000067d0
01101111111111115515515500111100001111000050050000000000000000000000000000000000000000000000000000000000022822400006004000067d00
0100110011111111551551111101011011111111015555100000000000000000000000000000000000000000000000000000000002288240006005000f67d000
00000000111111115511111111010110000000111050050100000000000000000000000000000000000000000000000000000000028e824006005000009d0000
11011011111111111111111110110101111111000111111000000000000000000000000000000000000000000000000000000000028e82404444000002090000
10010011111111110000000010101101100001110000000000000000000000000000000000000000000000000000000000000000022222002000000090000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111116611111111114111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00f00f511116111111111111111411141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555011116111111111661111411114000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05005005011111111111111111114111141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050511111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000dd000000000200020000000020050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
060d060d066006000006020602062000602055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666d666d6600666dd006620662666206662005050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000600060006000006200620062000602000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600600606060600060600600606006060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070777700007777077777000070000700888007770ee0440444000000000000000000000000000000000000000000000000000000000000000000000000
00700700007770077700777777770700000078888877777ee0004040400000000000000000000000000000000000000000000000000000000000000000000000
00700700000777777000700000007700000078888877777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000770077000700000007770000778888877777000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000777777770777777770888007770000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000077777000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000077777777000000070000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000000770777770000000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700007770077700000000077700007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77707707770000000000000077770077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700007770007000000000007777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000000770007000000000700000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000070000000000007000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000077700777700000000000000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777770077770000000000000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777777007770000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000070000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000000001100000000000000110000000000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000000001100060060006000110000000000000010000000000000000000000000000000000000000000000000000000000000000
1111111111111111106000000f001111106000600f001111106000000f0011110000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000001111100000000000111110000000000011110000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000001111100606000000111110000000000011110000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000000001100000000000000110000000000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000601100600001100600110060600110000011000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000001100000001100000110000000110000011000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000701100011111106000110001111110000011000111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111001000000011111100106000001111110010000000111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111001000006011111100100000601111110010000000111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111001111000000001100111100000000110011110000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000007000001106000000606000110000000000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111000000000000001100000000000000110000000000000010000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
