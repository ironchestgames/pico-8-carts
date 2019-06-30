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

-- debugb=function(n)
--  outputstr=''
--  local mask=0x0000.0001
--  for i=0,31 do
--   local bit=shr(band(shl(mask,i),n),i)
--   if(bit!=0) bit=1
--   outputstr=tostr(bit)..outputstr
--  end
--  debug(outputstr)
-- end

-- debugh=function(n)
--  debug(tostr(n,true))
-- end

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

-- function copytable(t)
--  local newt={}
--  for key,value in pairs(t) do
--   newt[key]=value
--  end
--  return newt
-- end

curmusic=nil
function playmusic(pattern)
 if pattern != curmusic then
  music(pattern,0,3)
 end
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
dungeonthemes={0,3,6}
dungeontheme=1 -- 1 magical forest, 2 cave, 3 catacombs
floormap={} -- the current map
door=nil -- the exit door to next floor
actors={} -- actors
boss=nil -- current boss (if any)
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

function burningeffect(actor)
 if actor.effect.counter == nil then
  actor.effect.counter=0
  add(pemitters,createpemitter({
   follow=actor,
   life=120,
   prate={2,4},
   plife={15,25},
   poffsets={-2,0.5,2,0.5},
   dx={0,0},
   dy={-0.3,0},
   pcolors={8,14},
  }))
 end

 actor.effect.counter-=1

 if actor.effect.counter <= 0 then
  actor.effect.counter=3

  actor.a=rnd()
  actor.spd=1.25
 end

 actor.dx=cos(actor.a)*actor.spd
 actor.dy=sin(actor.a)*actor.spd

end

-- skills
swordattackskillfactory=function(
  damage,
  preperformdur,
  postperformdur,
  targetcount,
  attackcol)
 return {
  sprite=31,
  preperformdur=preperformdur,
  postperformdur=postperformdur,
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
    damage=damage,
    targetcount=targetcount,
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
   local vfx={frame,col=attackcol}

   add(vfxs,vfx)

   sfx(4)
  end,
 }
end

bowattackskillfactory=function(
  damage,
  preperformdur,
  postperformdur,
  targetcount,
  attackcol,
  arrowcol)
 return {
  sprite=30,
  preperformdur=preperformdur,
  postperformdur=postperformdur,
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
    damage=damage,
    targetcount=targetcount,
    frames={
     currentframe=1,
     frame,
    },
    col=arrowcol,
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
   local vfx={frame,col=attackcol}

   add(vfxs,vfx)

   sfx(5)
  end,
 }
end

boltskillfactory=function(
  damage,
  preperformdur,
  postperformdur,
  recovertime,
  targetcount,
  attackcol,
  castingpemittercols,
  boltpemittercols)
 return {
  sprite=29,
  preperformdur=preperformdur,
  postperformdur=postperformdur,
  startpemitter=function(user,life)
   add(pemitters,createpemitter({
    follow=user,
    life=life,
    prate={2,4},
    plife={15,25},
    poffsets={-2,0.5,2,0.5},
    dx={0,0},
    dy={-0.3,0},
    pcolors=castingpemittercols,
   }))
   sfx(9)
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
    damage=damage,
    typ='fire',
    recovertime=recovertime,
    targetcount=targetcount,
    frames={
     currentframe=1,
     {47,20,3,3, -0.5,-0.5},
    },
    col=attackcol,
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
    pcolors=boltpemittercols,
   }))
   sfx(32)
  end,
 }
end

antiframe={9,9,1,1, 0,0}

-- items
swordidleframe={9,9,5,5, -2,-3}
sword={
 name='steel sword, 1 dmg knockback',
 class='weapon',
 sprite=47,
 col=6,
 skill=swordattackskillfactory(1,15,28,1000,7),
 frames={
  currentframe=1,
  idling={swordidleframe},
  moving={swordidleframe},
  attacking={{14,9,5,5, -2,-3},{18,9,7,5, -3,-3}},
  recovering={swordidleframe},
 },
}

bowidleframe={25,9,5,5, -2,-3}
bow={
 name='cedar bow, 1 dmg',
 class='weapon',
 twohand=true,
 sprite=46,
 col=4,
 skill=bowattackskillfactory(1,26,6,1,7,3),
 frames={
  currentframe=1,
  idling={bowidleframe},
  moving={bowidleframe},
  attacking={{30,9,5,5, -2,-3},{25,9,1,1, -2,-3}},
  recovering={bowidleframe},
 },
}

fireboltbook={
 name='book of firebolt',
 class='book',
 sprite=45,
 skill=boltskillfactory(1,50,0,120,1,14,{8,14},{14,8}),
 frames={
  currentframe=1,
  idling={antiframe},
  moving={antiframe},
  attacking={antiframe,antiframe},
  recovering={antiframe},
 },
}

shieldframe={35,9,5,5, -2,-3}
shield={
 name='steel shield, +1 armor',
 class='offhand',
 sprite=44,
 col=13,
 armor=1,
 frames={
  currentframe=1,
  idling={shieldframe},
  moving={shieldframe},
  attacking={shieldframe},
  recovering={shieldframe},
 },
}

ringmail={
 name='ringmail, +1 armor',
 class='armor',
 sprite=43,
 col=5,
 armor=1,
 frames={
  currentframe=1,
  idling={antiframe},
  moving={antiframe},
  attacking={antiframe,antiframe},
  recovering={antiframe},
 },
}

ironhelmet={
 name='iron helmet, +1 armor',
 class='helmet',
 sprite=42,
 col=13,
 armor=1,
 frames={
  currentframe=1,
  idling={antiframe},
  moving={antiframe},
  attacking={antiframe,antiframe},
  recovering={antiframe},
 },
}

leatherboots={
 name='boots of haste, +10% speed',
 class='boots',
 sprite=41,
 col=4,
 spdfactor=0.1,
 frames={
  currentframe=1,
  idling={antiframe},
  moving={antiframe},
  attacking={antiframe,antiframe},
  recovering={antiframe},
 },
}

avatar=createactor({
 x=64,
 y=12,
 halfw=1.5,
 halfh=2,
 a=0,
 spdfactor=1,
 spd=0.5,
 hp=3,
 startarmor=0,
 armor=0,
 state='idling',
 items={
  weapon=nil,
  offhand=nil,
  armor=nil,
  boots=nil,
  helmet=nil,
  book=nil,
  amulet=nil,
 },
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




-- dungeon scene
function dungeoninit()

 -- set callbacks
 _update60=dungeonupdate
 _draw=dungeondraw

 dungeonlevel=1
 dungeontheme=1
 mapinit(getbasemap())

end

function getbasemap()
 local basemap={}

 -- create basemap
 for _y=0,15 do
  basemap[_y]={}
  for _x=0,15 do
   basemap[_y][_x]=1
  end
 end


 local avatarx=flr(avatar.x/8)
 local avatary=flr(avatar.y/8)
 if dungeontheme == 1 and door then
  local doorx=flr(door.x/8)
  local doory=flr(door.y/8)
  if doorx == 0 then
   avatarx=14
  elseif doorx == 15 then
   avatarx=1
  elseif doory == 0 then
   avatary=14
  elseif doory == 15 then
   avatary=1
  end
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
   local angles={-0.25,0.25}
   angle+=angles[flr(rnd(#angles)+1)]
  elseif stepcount != 0 and stepcount % (steps / enemycount) == 0 then
   add(enemies,{
    x=curx,
    y=cury,
    typ=enemytypes[flr(rnd(#enemytypes)+1)],
   })
  else
   curx=nextx
   cury=nexty
   basemap[cury][curx]=0
  end
  stepcount-=1
 end

 -- enemies
 for enemy in all(enemies) do
  basemap[enemy.y][enemy.x]=enemy.typ
 end

 -- add boss on every 5 levels
 if dungeonlevel % 5 == 0 then
  local enemy=enemies[#enemies]
  basemap[enemy.y][enemy.x]=8
 end

 -- door
 if dungeontheme == 1 then
  if abs(angle%1) == 0.25 then
   angle=0.75
  end
  while curx > 0 and
     curx < 15 and
     cury > 0 and
     cury < 15 do
   basemap[cury][curx]=0
   curx+=cos(angle)
   cury+=sin(angle)
  end
 end
 basemap[cury][curx]=2

 -- avatar
 basemap[avatary][avatarx]=15

 return basemap
end

function nextfloor()
 if dungeonlevel == 0 then
  dungeontheme=1
 end
 dungeonlevel+=1

 mapinit(getbasemap())
end

curenemyidx=1

function mapinit(basemap)

 -- start map music
 playmusic(0)

 -- reset vars
 curenemyidx=1
 boss=nil

 -- reset collections
 floormap={}
 actors={}
 attacks={}
 pemitters={}

 -- init floormap and objects
 for _y=0,15 do
  floormap[_y]={}
  for _x=0,15 do
   local _col=basemap[_y][_x]

   -- create avatar
   if _col == 15 then
    avatar=createactor(avatar)
    avatar.x=_x*8+4
    avatar.y=_y*8+4
    avatar.armor=avatar.startarmor

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
   end

   -- create skeleton king
   if _col == 8 then
    local enemy=createactor({
     isenemy=true,
     isbig=true,
     x=_x*8+4,
     y=_y*8+4,
     a=0,
     halfw=1.5,
     halfh=3,
     runspd=0.4,
     spd=0.4,
     hp=10,
     attack={
      typ='magic',
      x=nil,
      y=nil,
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
      idling={{0,40,15,18, -7,-13}},
      moving={animspd=0.24,{16,40,15,18, -7,-13},{32,40,15,18, -7,-13}},
      attacking={animspd=0,{0,40,15,18, -7,-13},{48,40,20,18, -10,-13},{72,40,15,18, -7,-13}},
      recovering={{0,40,15,18, -7,-13}},
     },
     performattack=function(boss)

      if boss.attack.typ == 'melee' then
       if boss.ai.laststate != 'attacking' then
        boss.frames.currentframe=1
        boss.ai.state_counter=90
       else
        boss.ai.state_counter-=1
       end

       if boss.ai.state_counter == 60 then
        boss.frames.currentframe=2
        add(attacks,createattack({
         isenemy=true,
         throughwalls=true,
         x=boss.x+cos(boss.a)*2,
         y=boss.y-3,
         halfw=7,
         halfh=8,
         state_counter=2,
         isphysical=true,
         knockbackangle=boss.a,
         damage=1,
         targetcount=100,
         col=7,
        }))

        sfx(4)
       end

       if boss.ai.state_counter <= 0 then
        boss.x-=cos(boss.a)*3
        boss.attack.typ='magic'
        boss.ai.state='idling'
       end

      elseif boss.attack.typ == 'magic' then
       if boss.ai.laststate != 'attacking' then
        boss.frames.currentframe=3
        boss.ai.state_counter=110

        local a=rnd()
        local d=1
        local x,y

        repeat
         a+=0.05
         d+=0.02
         x=flr(boss.x/8+cos(a)*2)
         y=flr(boss.y/8+sin(a)*2)
         x=mid(1,x,14)
         y=mid(1,y,14)
        until floormap[y] and floormap[y][x] == 0

        boss.attack.x=x*8+4
        boss.attack.y=y*8+4

        add(pemitters,createpemitter({
         follow={
          x=boss.attack.x,
          y=boss.attack.y,
         },
         life=110+30,
         prate={1,2},
         plife={10,15},
         poffsets={-2,0.5,1,0.5},
         dx={0,0},
         dy={-0.3,0},
         pcolors={11,3,1},
        }))

        sfx(9)

       else
        boss.ai.state_counter-=1
       end

       if boss.ai.state_counter <= 0 then

        local enemy=createactor({
         isenemy=true,
         x=boss.attack.x,
         y=boss.attack.y,
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
          state='recovering',
          laststate='recovering',
          state_counter=50,
          ismovingoutofcollision=false,
          toocloseto={},
         },
         frames={
          currentframe=1,
          idling={{0,15,4,5, -2,-3}},
          moving={animspd=0.18,{0,15,4,5, -2,-3},{4,15,4,5, -2,-3}},
          attacking={{8,15,4,5, -2,-3}},
          recovering={{0,15,4,5, -2,-3}},
         },
        })

        add(actors,enemy)

        boss.attack.typ='melee'
        boss.ai.state='idling'
       end

      end
     end,
    })

    add(actors,enemy)
    boss=enemy
    _col=0 -- note: make tile ground
   end

   -- create door
   if _col == 2 then
    door={
     x=_x*8+4,
     y=_y*8+4,
     halfw=4,
     halfh=4,
     isopen=false
    }

    _col=0
    if dungeontheme == 1 then
     _col=1
    end
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
 end

 if avatar.hp <= 0 then
  return nil
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

  if skill != nil then
   avatar.state='attacking'
   avatar.currentskill=skill
   avatar.ispreperform=true

   avatar.state_counter=skill.preperformdur

   avatar.frames.currentframe=1
   avatar.items.weapon.frames.currentframe=1

   if avatar.currentskill.startpemitter then
    avatar.currentskill.startpemitter(avatar,skill.preperformdur)
   end
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
     avatar.items.weapon.frames.currentframe=2

    else -- note: done performing
     actor.state='idling'
     actor.frames.currentframe=1
     avatar.items.weapon.frames.currentframe=1
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
  if avatar.hp > 0 and enemy and enemy.ai then

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
   if enemy.attack.typ == 'magic' then
    withinattackdistance=distancetoavatar <= 60
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

    if enemy.effect then
     enemy.effect.func(enemy)
    end

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
   elseif isswinging or withinattackdistance and
         (haslostoavatar or enemy.attack.typ == 'magic') then
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

    if enemy == boss then
     enemy.attack.typ='magic'
    end

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

    if enemy == boss then

     boss.performattack(boss)

    else

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
        col=7,
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

       local frame=angletofx[a]
       frame[5]=x+frame[5]
       frame[6]=y+frame[6]
       frame.counter=10
       local vfx={frame,col=7}

       add(vfxs,vfx)

       sfx(4)

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
        },
        col=2,
       })

       add(attacks,attack)

       sfx(5)
      end

      enemy.ai.state='idling'
     end
    end

   elseif enemy.ai.state == 'recovering' then
    enemy.ai.state_counter-=1
    if enemy.ai.state_counter <= 0 then
     enemy.ai.state='idling'
     enemy.effect=nil
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

 -- update door
 if enemycount == 0 and not door.isopen then
  floormap[(door.y-4)/8][(door.x-4)/8]=0
  door.isopen=true
  sfx(0)
 end

 -- update the next-position
 for actor in all(actors) do

  local spdfactor=1
  if actor.spdfactor then
   spdfactor=actor.spdfactor
  end
  actor.dx=actor.dx*(actor.spd*spdfactor)
  actor.dy=actor.dy*(actor.spd*spdfactor)

  -- note: after this deltas should not change by input
 end

 -- collide avatar against door
 if door.isopen and
    isaabbscolliding(avatar,door) then
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

    local hitsfx=6

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
     actor.ai.state_counter=attack.recovertime
     if actor.ai.state_counter == nil then
      actor.ai.state_counter=0
     end
    else
     actor.state='recovering'
     actor.state_counter=0
    end

    -- check if actor dead
    if actor.hp <= 0 then
     actor.removeme=true
     hitsfx=3
     -- todo: add death vfx here
    end

    -- effects

    -- physical knockback effect
    if attack.isphysical and actor.isbig != true then
     actor.dx=cos(attack.knockbackangle)*5
     actor.dy=sin(attack.knockbackangle)*5

    elseif attack.typ == 'fire' then
     actor.effect={func=burningeffect}
    end

    -- vfx

    sfx(hitsfx)

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
     attack.y < 0 then
   attack.removeme=true
  end

  if attack.throughwalls != true and
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

 -- play death sound
 if avatar.hp <= 0 then
  playmusic(-1)
  sfx(2)
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

    local x8,y8=_x*8,_y*8

    if _y == #floormap or floormap[_y+1] and floormap[_y+1][_x] != 0 then
     spr(themeoffset+1,x8,y8)
    else
     spr(themeoffset+0,x8,y8)
    end

    -- if isdebug then
    --  rect(
    --    x8,
    --    y8,
    --    x8+wallaabb.halfw*2,
    --    y8+wallaabb.halfw*2,
    --    5)
    -- end
   end
  end
 end

 -- draw door
 if door.isopen then
  spr(
   themeoffset+2,
   door.x-door.halfw,
   door.y-door.halfh)

  if isdebug then
   rectfill(
    door.x-door.halfw,
    door.y-door.halfh,
    door.x+door.halfw,
    door.y+door.halfh,
    9)
  end
 end

 -- draw attacks
 for attack in all(attacks) do

  if attack.frames then
   local frame=attack.frames[attack.frames.currentframe]
   if attack.col then
    pal(2,attack.col,0)
   end
   sspr(
    frame[1],
    frame[2],
    frame[3],
    frame[4],
    attack.x+frame[5],
    attack.y+frame[6],
    frame[3],
    frame[4])

   pal(2,2,0)
  end

  -- if isdebug then
  --  rectfill(
  --   attack.x-attack.halfw,
  --   attack.y-attack.halfh,
  --   attack.x+attack.halfw,
  --   attack.y+attack.halfh,
  --   9)
  -- end
 end

 -- todo: sort on y and z
 --       maybe z can be layers?
 --       per z add 128 (plus margin)
 --       to y when sorting

 -- draw actors
 for actor in all(actors) do

  -- if isdebug then
  --  local col=13

  --  local obj=actor
  --  if actor.ai then
  --   obj=actor.ai
  --  end

  --  if obj.state == 'recovering' then
  --   col=8
  --  elseif obj.state == 'attacking' then
  --   col=9
  --  end

  --  rectfill(
  --   actor.x-actor.halfw,
  --   actor.y-actor.halfh,
  --   actor.x+actor.halfw,
  --   actor.y+actor.halfh,
  --   col)
  -- end

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

  -- draw item colors
  if actor == avatar then
   if avatar.items.helmet then
    pal(15,avatar.items.helmet.col,0)
   end
   if avatar.items.armor then
    pal(4,avatar.items.armor.col,0)
   end
   if avatar.items.boots then
    pal(2,avatar.items.boots.col,0)
   end
  end

  -- draw damage overlay color
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

  -- draw weapon
  if actor == avatar and
     avatar.items.weapon then
   item=avatar.items.weapon
   local stateframes=item.frames[state]
   local currentframe=min(
     flr(item.frames.currentframe),
     #stateframes)
   local frame=stateframes[currentframe]
   pal(6,item.col,0)
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

  -- draw offhand
  if actor == avatar and
     avatar.items.offhand then
   item=avatar.items.offhand
   local stateframes=item.frames[state]
   local currentframe=min(
     flr(item.frames.currentframe),
     #stateframes)
   local frame=stateframes[currentframe]
   pal(6,item.col,0)
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

  -- if isdebug then
  --  if actor.ai and actor.ai.targetx then
  --   haslos(floormap,actor.x,actor.y,actor.ai.targetx,actor.ai.targety)
  --  end

  --  pset(actor.x,actor.y,12)
  -- end
 end

 -- draw vfx
 for vfx in all(vfxs) do
  local frame=vfx[1]
  pal(7,vfx.col,0)
  sspr(frame[1],frame[2],frame[3],frame[4],frame[5],frame[6])
  pal(7,7,0)
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

 if dungeonlevel > 0 then
  print('level '..dungeonlevel,3,1,13)
 end
 print(avatar.armor..'/'..avatar.startarmor..' a',82,1,6)
 print(avatar.hp..' hp',110,1,8)
 if avatar.hp <= 0 then
  print('dead',60,60,8)
 end

 -- prints debug stats
 -- if isdebug then
 --  local enemycount=0
 --  for actor in all(actors) do
 --   if actor.ai then
 --    enemycount+=1
 --   end
 --  end
 --  print(enemycount,60,123,8)
 --  if avatar.ispreperform then
 --   color(10)
 --  else
 --   color(9)
 --  end
 --  print(avatar.state_counter,80,123)
 --  print(stat(1),20,123,7)
 --  print(stat(7),0,123,7)
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
local equipslots={
 {'helmet',10},
 {'armor',11},
 {'boots',9},
 {'book',13},
 {'offhand',12},
 {'weapon',15},
}

function equipinit()
 _update60=equipupdate
 _draw=equipdraw

 playmusic(4)
end

function equipupdate()

 -- init equipped items
 avatar.startarmor=0
 avatar.spdfactor=1
 equipped={}
 for _,item in pairs(avatar.items) do
  add(equipped,item)
  if item.armor then
   avatar.startarmor+=item.armor
  end
  if item.spdfactor then
   avatar.spdfactor+=item.spdfactor
  end
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
  sfx(7)
 elseif btnp(3) then
  sectioncur=mid(1,sectioncur+1,4)
  sfx(7)
 end

 -- init inventory
 inventory={}

 local allitems={
  leatherboots,
  ironhelmet,
  ringmail,
  sword,
  bow,
  shield,
  fireboltbook,
 }

 for item in all(allitems) do
  if avatar.items[item.class] != item then
   add(inventory,item)
  end
 end

 -- inventory
 if sectioncur == 1 then
  if btnp(0) then
   inventorycur=mid(1,inventorycur-1,#inventory)
   sfx(7)
  elseif btnp(1) then
   inventorycur=mid(1,inventorycur+1,#inventory)
   sfx(7)
  end

  if btnp(4) or btnp(5) then
   local selecteditem=inventory[inventorycur]

   avatar.skill1=nil
   avatar.skill2=nil

   avatar.items[selecteditem.class]=selecteditem

   if selecteditem.twohand then
    avatar.items.offhand=nil
   end

   if selecteditem.class == 'offhand' and
      avatar.items.weapon and
      avatar.items.weapon.twohand then
    avatar.items.weapon=nil
   end

   inventorycur=mid(1,inventorycur,#inventory-1)

   sfx(8)
  end

 -- equipped
 elseif sectioncur == 2 then
  if btnp(0) then
   equippedcur=mid(1,equippedcur-1,#equipslots)
   sfx(7)
  elseif btnp(1) then
   equippedcur=mid(1,equippedcur+1,#equipslots)
   sfx(7)
  end

  if btnp(4) or btnp(5) then
   local selectedclass=equipslots[equippedcur][1]
   local selecteditem=avatar.items[selectedclass]
   if selecteditem != nil then
    avatar.items[selecteditem.class]=nil
    avatar.skill1=nil
    avatar.skill2=nil
   end
   sfx(8)
  end

 -- available skills
 elseif sectioncur == 3 then
  if btnp(0) then
   availableskillscur=mid(1,availableskillscur-1,#availableskills)
   sfx(7)
  elseif btnp(1) then
   availableskillscur=mid(1,availableskillscur+1,#availableskills)
   sfx(7)
  end

  if btnp(4) then
   avatar.skill1=availableskills[availableskillscur]
   if avatar.skill2 == avatar.skill1 then
    avatar.skill2=nil
   end
   sfx(8)
  end
  if btnp(5) then
   avatar.skill2=availableskills[availableskillscur]
   if avatar.skill1 == avatar.skill2 then
    avatar.skill1=nil
   end
   sfx(8)
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

 fillp(0b1010000110000101)
 rectfill(0,0,128,3,1)
 rectfill(0,124,128,128,1)
 fillp()

 local col=0

 -- draw inventory section
 local offsetx=0
 local y=17
 local i=1
 if sectioncur == 1 then
  col=10
 else
  col=4
 end
 print('saddlebags',4,y-9,col)
 for item in all(inventory) do
  spr(item.sprite,6+offsetx,y)
  if sectioncur == 1 and i == inventorycur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)

   print(
    item.name,
    4,
    y+12,
    7)
  end

  offsetx+=12
  i+=1
 end

 -- draw equipped section
 offsetx=0
 y=52
 i=1
 if sectioncur == 2 then
  col=10
 else
  col=4
 end
 print('equipped',4,y-9,col)
 for slot in all(equipslots) do
  local item=avatar.items[slot[1]]
  if item == nil then
   spr(slot[2],6+offsetx,y)
  else
   spr(item.sprite,6+offsetx,y)
  end

  if sectioncur == 2 and i == equippedcur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)

   if item then
    print(
     item.name,
     4,
     y+12,
     7)
   end
  end

  offsetx+=12
  i+=1
 end

 -- draw availableskills section
 offsetx=0
 y=88
 i=1
 if sectioncur == 3 then
  col=10
 else
  col=4
 end
 print('skills',4,y-9,col)
 for skill in all(availableskills) do
  spr(skill.sprite,6+offsetx,y)
  if sectioncur == 3 and i == availableskillscur then
   rect(
    6+offsetx-2,
    y-2,
    6+offsetx+9,
    y+9,
    10)
  end

  if skill == avatar.skill1 then
   spr(24,6+offsetx,y+12)
   print('\x8e',6+offsetx+1,y+12,11)
  end
  if skill == avatar.skill2 then
   spr(24,6+offsetx,y+12)
   print('\x97',6+offsetx+1,y+12,8)
  end

  offsetx+=12
  i+=1
 end

 -- draw exit button
 if sectioncur == 4 then
  col=10
 else
  col=4
 end
 print('exit',57,115,col)

end






function _init()
 equipinit()
end




__gfx__
00000d0000000d000000000001111000011110000000000011111111111111111111111100000000055555000550055005555550005555500000005500000055
00d00d0000d00d000000000011111111111111110050050011111111111111110000000155505500555555505555555505555550050000000000055000000555
00d0d11000d0d1100000000011000011110000110055550000000000111111115501100155505500555555505055550505555550055555000000505000005550
0ddd01100ddd01100000000000111100001111000050050001101111111111115500001155505500500500505055550505555550055555000005005050055500
0dd101100dd101100000000011010110111111110155551001001110111111115515500155505500550005500055550005555550055555000050050005555000
ddd11011ddd110110000000011010110000000111050050100000000111111115515500155550550550005500055550005555550055555000500500000550000
dd111011dd1110110000000010110101111111000111111011011011111111115515515155555055550005500055550000555500055555005555000005050000
00100100001001000000000010101101100001110000000010010011111111111111111105555055050005000000000000055000055555005000000050005000
0000000000000000000000000000000000000000000000000000000000000000011111100000000000000000000000000000000011111111111111dd111111dd
000000000111111166111111111161111111111100000000000000000000000011111111000000000000000000000000000000001111111111111dd111111ddd
0f00f00f41111611111111111111161116111111000000000000000000000000111111110000000000000000000000000000000011dd1dd11111d1d11111ddd1
44444444011116111111111661111611116661110000000000000000000000001111111100000000000000000000000000000000d111dddd111d11d1d11ddd11
0400400401111111111111111111611116166111000000000000000000000000011111100000000000000000000000000000000011d1dddd11d11d111dddd111
2020202021111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000011111dd11d11d11111dd1111
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111dddd11d11d1d1111
000000000dd00000000020002000000002005050500000000000000000000000000000000000000000000000000000000000000011111111d111111dd111d111
060d060d0660060000060206020620006020555555000000000000000000000000000000000000000006d00005600d500666ddd0008888800000004200000066
666d666d6600666dd0066206626662066620050505000000000000000000000000000000444420200066d500d556d55d06dd11d008ffff40000006400000066d
0600060006000600000620062006200060200000000000000000000000000000000000004422202006d6d55050d55d0506d6d1d00222224000006040000067d0
60600600606060600060600600606006060000000000000000000000000000000000000004440400d6d6d555d024920d06d6d1d0022822400006004000067d00
0700007077770000777707777700007000070088800777022022022200000000000000000a9909006766dddd00d55d000d1dd1d002288240006005000f67d000
007007000077700777007777777707000000788888777772200020202000000000000000044440400006d0000056d5000d1111d0028e824006005000009d0000
00700700000777777000700000007700000078888877777000000000000000000000000002444404d000000d00d55d0000d11d00028e82404444000002090000
007777000007700770007000000077700007788888777770000000000000000000000000002222025000000500000000000dd000022222002000000090000000
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
00000000000000000000000000000000000000000000000000000077777770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007777777777700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777777777777777000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007777777777777777700000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d7777777770007777700000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d777770000000007770000000000000000000000000000000000000000000000000000000000000
00000000f000000000000000f000000000000000f000000000d777000f0000000770000000000000f00000000000000000000000000000000000000000000000
0000000ff00000000000000ff00000000000000ff0000000000d7400ff000000007700000000000ff00b00000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000004000660000000077000000000006600000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000040600660000000007000000000006600600000000000000000000000000000000000000000000
0000000600b000000000000600b000000000000600b0000000000060600000000007000000000006006000000000000000000000000000000000000000000000
00000066600000000000006660000000000000666000000000000006660000000007000000000066660000000000000000000000000000000000000000000000
00000606066000000000060606600000000006060660000000000000600000000007000000000606000000000000000000000000000000000000000000000000
00406066600000000040606660000000004060666000000000000006660000000070000000406066600000000000000000000000000000000000000000000000
00040006000000000004000600000000000400060000000000000000600000000070000000040006000000000000000000000000000000000000000000000000
00d040606000000000d040606000000000d040606000000000000006060000000700000000d04060600000000000000000000000000000000000000000000000
0d000060600000000d000060600000000d000060600000000000006000600007700000000d000060600000000000000000000000000000000000000000000000
d000006060000000d000006000000000d000000060000000000000060006077000000000d0000060600000000000000000000000000000000000000000000000
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
22222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000000000002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000033330000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000034430000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2200003e330000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
220000f0000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22020000002000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000200022200550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22002200002000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22022000000000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d0050dd50d550d550d505555055055550550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d00d00000000000050050005551051055005510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d110dd50dd50d500005000511051050000510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd0110000000000500005000000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd1011050dd50dd5500005d55505550550000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd11011000000000500005055105510550000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd111011dd50dd50d500005051100510550000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000000000555555000000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01080000250402604028040290402b0402d0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001361513625136151361500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0116000021040210451f0401f0451d0401d0451c0401c0451a0401a0421a0421a0451800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400002115300100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000
010a00003261432613000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010700003133300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00000914102121001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010200000e05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002602100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
014000000063400600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600001a7501a7421a7421a73500700007001c91000700007000070000700007001d7521d7451a7521a7501c7501c7421c7421c735007000070000700007001575015752157421573500700000000070005910
011600000e7540e750021100c7000e7540e750021100c7000e7540e750021100c7000e7540e750021100c70009754097500911000700097540975009110007000975409750091100070009754097500111000700
011600001a7501a7421a7421a73500700000000000000700007000070000700007001d7521d7421a7521a7501c7501c7421c7421c73501920007001d7521d7451575015752157421573500700007001373213725
01160000137501374213742137350070000700157541575116751167550000000000187521874218735000001a7501a7421a7421a735007000070000700007000d93200700007000070000700007000070000700
011600000775407750071100c70007754077500711000700077540775000000007000775407750007000070002754027500211000700027540275002110007000275402750021100070002754027500511000700
01160000137501374213742137350070000700157541575116751167550000000000187501874218735000001a7421a73500700007001c7421c7321c735007001975019742197421973219735007000275000000
011600000775407750071100c7000775407750007000070007754077500711000700077540775000700007000e7540e75002110007000e7540e75000000007000975409750000000070009754097500111000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100002b6202a6202962033620286202762031620256202463022630226301f6301b630196401464012640106400a6400563003630016300063000620006200062000620006300163002630036300463005620
000200002f62027620236202c6201a62021620146301c6300d6300b6300a6301c63009630006401a6401a640006401a64000630006301d6200165001650016500065000600006000060000600006000060000600
010e00001361500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
__music__
01 0a0b4344
00 0c0b4344
00 0d0e4344
02 0f104344
01 0e424344
02 10424344

