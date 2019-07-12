pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- epic evil ender (v1.0)
-- by ironchest games

-- poke(24365,1) -- note: enable devkit
-- isdebug=false

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5)
 printh(
  tostr(_s1)..', '..
  tostr(_s2)..', '..
  tostr(_s3)..', '..
  tostr(_s4)..', '..
  tostr(_s5)
  ,'debug',false)
end

function clone(t)
 local result={}
 for key,value in pairs(t) do
  result[key]=value
 end
 return result
end

-- note: last character in s needs to be ','
function parseflat(s)
 local result,part={},''
 while #s > 0 do
  local d=sub(s,1,1)
  if d != ',' then
   part=part..d
  else
   add(result,tonum(part))
   part=''
  end
  s=sub(s,2)
 end
 return result
end

function isaabbscolliding(aabb1,aabb2)
 if aabb1.x - aabb1.halfw < aabb2.x + aabb2.halfw and
    aabb1.x + aabb1.halfw > aabb2.x - aabb2.halfw and
    aabb1.y - aabb1.halfh < aabb2.y + aabb2.halfh and
    aabb1.y + aabb1.halfh > aabb2.y - aabb2.halfh then
  return aabb2
 end
 -- return nil
end

wallaabb={
 x=0,
 y=0,
 halfw=4,
 halfh=4,
}
function isinsidewall(aabb)
 local x1,y1,x2,y2=
   aabb.x-aabb.halfw,
   aabb.y-aabb.halfh,
   aabb.x+aabb.halfw,
   aabb.y+aabb.halfh

 for point in all({
    {x1,y1},
    {x2,y1},
    {x2,y2},
    {x1,y2},
   }) do
  local mapx,mapy=flr(point[1]/8),flr(point[2]/8)
  wallaabb.x=mapx*8+wallaabb.halfw
  wallaabb.y=mapy*8+wallaabb.halfh

  -- note: hitboxes should not be larger than 8x8
  if floormap[mapy][mapx] == 1 and
     isaabbscolliding(aabb,wallaabb) then
   return wallaabb
  end
 end
 -- return nil
end

function haslos(_x1,_y1,_x2,_y2)
 local dx,dy,x,y,x_inc,y_inc=
   abs(_x2-_x1),
   abs(_y2-_y1),
   _x1,
   _y1,
   sgn(_x2-_x1),
   sgn(_y2-_y1)

 local n,error=1+dx+dy,dx-dy
 dx*=2
 dy*=2

 while (n > 0) do
  n-=1

  if floormap[flr(y/8)][flr(x/8)] == 1 then
   return
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
 local dx,dy=x2-x1,y2-y1
 return sqrt(dx*dx+dy*dy)
end

function normalize(n)
 if n == 0 then
  return 0
 end
 return sgn(n)
end

newaabb={}
function collideaabbs(collisionfunc,aabb,other,_dx,_dy)
 local dx,dy=_dx,_dy

 -- set aabb halfs
 newaabb.halfw,newaabb.halfh=aabb.halfw,aabb.halfh

 -- set next pos along x
 newaabb.x,newaabb.y=aabb.x+_dx,aabb.y

 -- is it colliding w other
 local collidedwith=collisionfunc(newaabb,other)
 if collidedwith then
  dx=(aabb.halfw+collidedwith.halfw-abs(aabb.x-collidedwith.x))*-sgn(_dx)
 end

 -- set next pos along y
 newaabb.x,newaabb.y=aabb.x,aabb.y+_dy

 -- is it colliding w other
 local collidedwith=collisionfunc(newaabb,other)
 if collidedwith then
  dy=(aabb.halfh+collidedwith.halfh-abs(aabb.y-collidedwith.y))*-sgn(_dy)
 end

 return dx,dy
end

function findemptyfloor(origx,origy)
 local a,d=rnd(),1

 repeat
  a+=0.05
  d+=0.02
  x,y=
    mid(1,flr(origx/8+cos(a)*2),14),
    mid(1,flr(origy/8+sin(a)*2),14)
 until floormap[y] and floormap[y][x] == 0

 return x*8+4,y*8+4
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

meleevfxframes={
 [0]=parseflat'0,20,4,7,-1,-5,', -- right
 [0.125]=parseflat'8,20,6,4,-3,-2,', -- right/up
 [0.25]=parseflat'20,20,9,3,-3,-1,', -- up
 [0.375]=parseflat'14,20,6,4,-2,-2,', -- up/left
 [0.5]=parseflat'4,20,4,7,-2,-5,', -- left
 [0.625]=parseflat'29,20,4,7,-3,-6,', -- left/down
 [0.75]=parseflat'20,23,9,3,-4,-2,', -- down
 [0.875]=parseflat'33,20,4,7,0,-6,', -- down/right
 [1]=parseflat'0,20,4,7,-1,-5,', -- right (wrapped)
}

bowvfxframes={
 [0]=parseflat'0,27,6,7,-3,-5,', -- right
 [0.125]=parseflat'17,32,7,7,-4,-3,', -- right/up
 [0.25]=parseflat'10,31,7,6,-3,-3,', -- up
 [0.375]=parseflat'34,32,7,7,-3,-3,', -- up/left
 [0.5]=parseflat'4,27,6,7, -2,-5,', -- left
 [0.625]=parseflat'22,27,7,7,-2,-5,', -- left/down
 [0.75]=parseflat'10,27,7,6,-3,-4,', -- down
 [0.875]=parseflat'29,27,7,7,-4,-4,', -- down/right
 [1]=parseflat'0,27,6,7,-3,-5,', -- right (wrapped)
}

arrowframes={
 [0]=parseflat'50,20,2,1,-1,-0.5,', -- right
 [0.125]=parseflat'52,20,2,2,-1,-1,', -- right/up
 [0.25]=parseflat'54,20,1,2,-0.5,-1,', -- up
 [0.375]=parseflat'55,20,2,2,-1,-1,', -- up/left
 [0.5]=parseflat'50,20,2,1,-1,-0.5,', -- left
 [0.625]=parseflat'52,20,2,2,-1,-1,', -- left/down
 [0.75]=parseflat'54,20,1,2,-0.5,-1,', -- down
 [0.875]=parseflat'55,20,2,2,-1,-1,', -- down/right
 [1]=parseflat'50,20,2,1,-1,-0.5,', -- right (wrapped)
}

function getvfxframeindex(angle)
 return min(flr((angle+0.0625)*8)/8,1)
end

-- todo: this is only convenience dev function
function actorfactory(actor)
 actor.state='idling'
 actor.state_counter=0
 actor.currentframe=1
 actor.dx=0
 actor.dy=0
 actor.runspd=actor.spd
 actor.dmgfxcounter=0
 actor.comfydist=actor.comfydist or 1
 actor.toocloseto={}

 return actor
end

function performenemymelee(enemy)
 local a=atan2(
  enemy.targetx-enemy.x,
  enemy.targety-enemy.y)

 add(attacks,{
  isenemy=true,
  x=enemy.x+cos(a)*4,
  y=enemy.y+sin(a)*4,
  halfw=2,
  halfh=2,
  state_counter=1,
  typ='phys',
  knockbackangle=a,
  damage=1,
  targetcount=1000,
 })

 local x,y=
   enemy.x+cos(enemy.a)*4,
   enemy.y+sin(enemy.a)*4

 local frame=clone(meleevfxframes[getvfxframeindex(enemy.a)])
 frame[5]=x+frame[5]
 frame[6]=y+frame[6]
 frame.counter=10
 frame.col=7

 add(vfxs,{frame})

 sfx(4)
end

function performenemybow(enemy)
 local a=getvfxframeindex(atan2(
  enemy.targetx-enemy.x,
  enemy.targety-enemy.y))

 add(attacks,{
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
   clone(arrowframes[a]),
  },
  col=2,
 })

 sfx(5)
end


-- enemy factories

function newmeleeskeleton(x,y)
 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  halfw=1.5,
  halfh=2,
  spd=0.5,
  hp=3,
  attack_preperformdur=40,
  attack_postperformdur=10,
  attack_range=7,
  performattack=performenemymelee,
  idling={parseflat'0,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   parseflat'0,15,4,5,-2,-3,',
   parseflat'4,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   parseflat'8,15,4,5,-2,-3,',
   parseflat'11,15,6,5,-3,-3,',
  },
  recovering={parseflat'0,15,4,5,-2,-3,'},
 })
end

function newbatenemy(x,y)
 return actorfactory({
  isenemy=true,
  isghost=true,
  x=x,
  y=y,
  a=0,
  halfw=1.5,
  halfh=2,
  spd=0.75,
  hp=1,
  attack_preperformdur=30,
  attack_postperformdur=0,
  attack_range=7,
  performattack=performenemymelee,
  idling={parseflat'36,15,3,3,-1.5,-1.5,'},
  moving={
   animspd=0.21,
   parseflat'36,15,3,3,-1.5,-1.5,',
   parseflat'39,15,3,3,-1.5,-1.5,'
  },
  attacking={
   animspd=0.32,
   parseflat'36,15,3,3,-1.5,-1.5,',
   parseflat'39,15,3,3,-1.5,-1.5,'
  },
  recovering={parseflat'36,15,3,3,-1.5,-1.5,'},
 })
end

function newbowskeleton(x,y)
 return actorfactory({
  isenemy=true,
  x=x,
  y=y,
  a=0,
  halfw=1.5,
  halfh=2,
  spd=0.5,
  hp=2,
  attack_preperformdur=60,
  attack_postperformdur=4,
  attack_range=40,
  performattack=performenemybow,
  comfydist=20,
  idling={parseflat'18,15,4,5,-2,-3,'},
  moving={
   animspd=0.18,
   parseflat'18,15,4,5,-2,-3,',
   parseflat'22,15,4,5,-2,-3,'
  },
  attacking={
   animspd=0,
   parseflat'26,15,4,5,-2,-3,',
   parseflat'31,15,4,5,-2,-3,'
  },
  recovering={parseflat'18,15,4,5,-2,-3,'},
 })
end

function newskeletonking(x,y)

 function setupmelee(boss)
  boss.islosindependent=nil
  boss.attack_range=7
  boss.attack_preperformdur=30
  boss.attack_postperformdur=60
  boss.attacking={
   animspd=0,
   parseflat'0,40,15,18,-7,-13,',
   parseflat'0,58,20,18,-10,-13,',
  }
  boss.onpreperform=nil
  boss.performattack=performmelee
  boss.afterpostperform=setupmagic
 end

 function performmelee(boss)
  add(attacks,{
   isenemy=true,
   throughwalls=true,
   x=boss.x+cos(boss.a)*2,
   y=boss.y-3,
   halfw=7,
   halfh=8,
   state_counter=2,
   typ='phys',
   knockbackangle=boss.a,
   damage=1,
   targetcount=1,
  })

  sfx(4)
 end

 function setupmagic(boss)
  boss.islosindependent=true
  boss.attack_range=60
  boss.attack_preperformdur=110
  boss.attack_postperformdur=0
  boss.attacking={
   animspd=0,
   parseflat'24,58,15,18,-7,-13,',
   parseflat'24,58,15,18,-7,-13,',
  }
  boss.onpreperform=magicpreperform
  boss.performattack=performmagic
  boss.afterpostperform=setupmelee
 end

 function magicpreperform(boss)
  boss.attack_x,boss.attack_y=findemptyfloor(boss.x,boss.y)
  add(pemitters,{
   follow={
    x=boss.attack_x,
    y=boss.attack_y,
   },
   life=140,
   prate={1,2},
   plife={10,15},
   poffsets={-2,0.5,1,0.5},
   dx={0,0},
   dy={-0.3,0},
   pcolors={11,3,1},
  })

  sfx(9)
 end

 function performmagic(boss)
  local enemy=newmeleeskeleton(boss.attack_x,boss.attack_y)

  -- summoning sickness
  enemy.state='recovering'
  enemy.laststate='recovering'
  enemy.state_counter=50

  add(actors,enemy)
 end

 boss=actorfactory({
  isenemy=true,
  isbig=true,
  x=x,
  y=y,
  a=0,
  halfw=1.5,
  halfh=3,
  spd=0.4,
  hp=10,
  idling={parseflat'0,40,15,18,-7,-13,'},
  moving={
   animspd=0.24,
   parseflat'16,40,15,18,-7,-13,',
   parseflat'32,40,15,18,-7,-13,'
  },
  recovering={parseflat'0,40,15,18,-7,-13,'},
  onroam=setupmagic,
 })

 setupmagic(boss)

 return boss
end


-- effects

function burningeffect(actor)
 if actor.effect.counter == nil then
  actor.effect.counter=0
  add(pemitters,{
   follow=actor,
   life=120,
   prate={2,4},
   plife={15,25},
   poffsets={-2,0.5,2,0.5},
   dx={0,0},
   dy={-0.3,0},
   pcolors={8,14},
  })
 end

 actor.effect.counter-=1

 if actor.effect.counter <= 0 then
  actor.effect.counter=12

  actor.a=rnd()
 end

 actor.dx=cos(actor.a)*actor.spd
 actor.dy=sin(actor.a)*actor.spd

end

function freezeeffect(actor)
 add(vfxs,{
  {
   57,18,8,7,
   actor.x-4,actor.y-3.5,
   counter=2,
  },
 })

 actor.dx=0
 actor.dy=0
end

function stunningeffect(actor)
 if actor.effect.counter == nil or
    actor.effect.counter <= 0 then
  local t,x,y=
    5,
    actor.x-1.5,
    actor.y-actor.halfh*2-1

  actor.effect.counter=t*3
  add(vfxs,{
   {42,13,3,2, x,y, counter=t,col=7},
   {42,15,3,2, x,y, counter=t,col=7},
   {42,17,3,2, x,y, counter=t,col=7},
  })
 end

 actor.effect.counter-=1

 actor.dx,actor.dy=0,0
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
   local x,y=
     user.x+cos(user.a)*4,
     user.y+sin(user.a)*4

   add(attacks,{
    x=x,
    y=y,
    halfw=2,
    halfh=2,
    state_counter=1,
    typ='phys',
    knockbackangle=user.a,
    damage=damage,
    targetcount=targetcount,
   })

   local frame=clone(meleevfxframes[user.a])
   frame[5]=x+frame[5]
   frame[6]=y+frame[6]
   frame.counter=skill.postperformdur
   frame.col=attackcol

   add(vfxs,{frame})

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
   local x,y=
     user.x+cos(user.a)*4,
     user.y+sin(user.a)*4

   add(attacks,{
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
     clone(arrowframes[user.a]),
    },
    col=arrowcol,
   })

   local frame=clone(bowvfxframes[user.a])
   frame[5]=x+frame[5]
   frame[6]=y+frame[6]
   frame.counter=skill.postperformdur
   frame.col=attackcol

   add(vfxs,{frame})

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
  effecttype,
  attackcol,
  castingpemittercols,
  boltpemittercols)
 return {
  sprite=29,
  preperformdur=preperformdur,
  postperformdur=postperformdur,
  startpemitter=function(user,life)
   add(pemitters,{
    follow=user,
    life=life,
    prate={2,4},
    plife={15,25},
    poffsets={-2,0.5,2,0.5},
    dx={0,0},
    dy={-0.3,0},
    pcolors=castingpemittercols,
   })
   sfx(9)
  end,
  perform=function(skill,user)
   local x,y=
     user.x+cos(user.a)*4,
     user.y+sin(user.a)*4

   local attack={
    x=x,
    y=y,
    halfw=1,
    halfh=1,
    state_counter=1000,
    dx=cos(user.a)*1.2,
    dy=sin(user.a)*1.2,
    damage=damage,
    typ=effecttype,
    recovertime=recovertime,
    targetcount=targetcount,
    frames={
     currentframe=1,
     {47,20,3,3, -0.5,-0.5},
    },
    col=attackcol,
   }

   add(attacks,attack)

   add(pemitters,{
    follow=attack,
    life=1000,
    prate={0,1},
    plife={3,5},
    poffsets={-1,-1,1,1},
    dx={0,0},
    dy={0,0},
    pcolors=boltpemittercols,
   })
   sfx(32)
  end,
 }
end

-- passive skills
function phasing(actor)
 local x,y=findemptyfloor(actor.x,actor.y)
 actor.x,actor.y=x,y
 add(vfxs,{
  {9,9,1,1, 0,0, counter=2},
  {
   draw=function(frame)
    circ(x,y,frame.counter*1.5,12)
   end,
   counter=12,
  },
 })
end

antiframe=parseflat'9,9,1,1,0,0,'

-- items
sword={
 name='steel sword, 1 dmg knockback',
 class='weapon',
 sprite=47,
 col=6,
 skill=swordattackskillfactory(1,15,28,1000,7),
 currentframe=1,
 idling={parseflat'9,9,5,5,-2,-3,'},
 moving={parseflat'9,9,5,5,-2,-3,'},
 attacking={
  parseflat'14,9,5,5,-2,-3,',
  parseflat'18,9,7,5,-3,-3,'
 },
 recovering={parseflat'9,9,5,5,-2,-3,'},
}

bow={
 name='cedar bow, 1 dmg',
 class='weapon',
 twohand=true,
 sprite=46,
 col=4,
 skill=bowattackskillfactory(1,26,6,1,7,3),
 currentframe=1,
 idling={parseflat'25,9,5,5,-2,-3,'},
 moving={parseflat'25,9,5,5,-2,-3,'},
 attacking={
  parseflat'30,9,5,5,-2,-3,',
  parseflat'25,9,1,1,-2,-3,',
 },
 recovering={parseflat'25,9,5,5,-2,-3,'},
}

fireboltbook={
 name='book of firebolt',
 class='book',
 sprite=45,
 skill=boltskillfactory(1,50,0,120,1,'fire',14,parseflat'8,14,',parseflat'14,8,'),
 currentframe=1,
 idling={antiframe},
 moving={antiframe},
 attacking={antiframe,antiframe},
 recovering={antiframe},
}

iceboltbook={
 name='book of icebolt',
 class='book',
 sprite=63,
 skill=boltskillfactory(0,40,0,150,1,'ice',7,parseflat'12,12,',parseflat'12,12,'),
 currentframe=1,
 idling={antiframe},
 moving={antiframe},
 attacking={antiframe,antiframe},
 recovering={antiframe},
}

shieldframe=parseflat'35,9,5,5,-2,-3,'
shield={
 name='steel shield, +1 armor',
 class='offhand',
 sprite=44,
 col=13,
 armor=1,
 currentframe=1,
 idling={shieldframe},
 moving={shieldframe},
 attacking={shieldframe},
 recovering={shieldframe},
}

ringmail={
 name='ringmail, +1 armor',
 class='armor',
 sprite=43,
 col=5,
 armor=1,
 currentframe=1,
 idling={antiframe},
 moving={antiframe},
 attacking={antiframe,antiframe},
 recovering={antiframe},
}

cloakidling=parseflat'0,6,3,4,-1,-2,'

cloakofphasing={
 name='cloak of phasing',
 class='armor',
 iscloak=true,
 sprite=62,
 col=2,
 col2=1,
 armor=0,
 skill={onhit=phasing},
 currentframe=1,
 idling={cloakidling},
 moving={cloakidling},
 attacking={cloakidling},
 recovering={cloakidling},
}

ironhelmet={
 name='iron helmet, +1 armor',
 class='helmet',
 sprite=42,
 col=13,
 armor=1,
 currentframe=1,
 idling={antiframe},
 moving={antiframe},
 attacking={antiframe,antiframe},
 recovering={antiframe},
}

leatherboots={
 name='boots of haste, +10% speed',
 class='boots',
 sprite=41,
 col=4,
 spdfactor=0.1,
 currentframe=1,
 idling={antiframe},
 moving={antiframe},
 attacking={antiframe,antiframe},
 recovering={antiframe},
}

allitems={
 sword,
 bow,
 fireboltbook,
 iceboltbook,
 cloakofphasing,
 ringmail,
 shield,
 ironhelmet,
 leatherboots,
}

dungeonthemes={
 { -- forest
  spr1=240,
  musicstart=0,
  enemytypes={
   newbatenemy,
   newmeleeskeleton,
   newbowskeleton,
   newskeletonking,
  }
 },
 { -- cave
  spr1=224,
  musicstart=0,
  enemytypes={
   newbatenemy,
   newmeleeskeleton,
   newbowskeleton,
   newskeletonking,
  }
 },
 { --  catacombs
  spr1=208,
  musicstart=0,
  enemytypes={
   newbatenemy,
   newmeleeskeleton,
   newbowskeleton,
   newskeletonking,
  }
 },
}


function dungeoninit()
 _update60,_draw=
   dungeonupdate,
   dungeondraw

 avatar=actorfactory({
  x=64,
  y=56,
  halfw=1.5,
  halfh=2,
  a=0,
  spdfactor=1,
  spd=0.5,
  hp=3,
  startarmor=0,
  armor=0,
  items={
   weapon=sword,
   -- offhand=nil,
   -- armor=nil,
   -- boots=nil,
   -- helmet=nil,
   -- book=nil,
   -- amulet=nil,
  },
  inventory={sword},
  skill1=sword.skill,
  -- skill2=nil,
  -- currentskill=nil,
  passiveskills={},
  idling={parseflat'0,10,3,4,-1,-2,'},
  moving={
   parseflat'0,10,3,4,-1,-2,',
   parseflat'3,10,3,4,-1,-2,'
  },
  attacking={
   animspd=0,
   parseflat'6,10,3,4,-1,-2,',
   parseflat'0,10,3,4,-1,-2,'
  },
  recovering={parseflat'0,10,3,4,-1,-2,'},
 })

 dungeonlevel=1
 dungeontheme=1
 nexttheme=1
 mapinit()
end

function nextfloor()
 dungeontheme=nexttheme
 dungeonlevel+=1
 mapinit()
end

curenemyidx=1
gametick=0

function mapinit()

 local basemap={}

 for _y=0,15 do
  basemap[_y]={}
  for _x=0,15 do
   basemap[_y][_x]=1
  end
 end

 local avatarx,avatary=flr(avatar.x/8),flr(avatar.y/8)

 if dungeontheme == 1 and door then
  local doorx,doory=flr(door.x/8),flr(door.y/8)
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

 local curx,cury=avatarx,avatary
 local angle=0
 local steps=500
 local stepcount=steps
 local enemycount=10
 local enemytypes={5,6,7}
 local enemies={}

 while stepcount > 0 do

  local nextx,nexty=curx+cos(angle),cury+sin(angle)

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

 for enemy in all(enemies) do
  basemap[enemy.y][enemy.x]=enemy.typ
 end

 if dungeonlevel % 3 == 2 then
  nexttheme+=1
 end

 if dungeonlevel % 3 == 0 then
  local enemy=enemies[#enemies]
  basemap[enemy.y][enemy.x]=8
 end

 -- door
 if nexttheme == 1 then
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

 basemap[avatary][avatarx]=15



 -- reset
 curenemyidx,
 gametick,
 isdoorspawned,
 boss,
 floormap,
 actors,
 attacks,
 pemitters,
 vfxs,
 interactables=
   1,
   0,
   nil,
   nil,
   {},
   {},
   {},
   {},
   {},
   {}

 for _y=0,15 do
  floormap[_y]={}
  for _x=0,15 do
   local _col,ax,ay=
     basemap[_y][_x],
     _x*8+4,
     _y*8+4

   -- create avatar
   if _col == 15 then
    avatar=actorfactory(avatar)
    avatar.x,avatar.y=ax,ay
    avatar.armor=avatar.startarmor

    add(actors,avatar)

    -- add mule
    add(interactables,{
     x=avatar.x,
     y=avatar.y,
     halfw=4,
     halfh=2.5,
     sprite=2,
     text='\x8e inventory',
     enter=function ()
      if btnp(4) then
       equipinit()
      end
     end,
    })

    _col=0
   end

   -- create enemy
   if _col >= 5 and _col <= 8 then
    add(actors,
      dungeonthemes[dungeontheme].enemytypes[_col-4](ax,ay))
    _col=0
   end

   -- create door
   if _col == 2 then

    door={
     x=ax,
     y=ay,
     halfw=4,
     halfh=4,
     sprite=dungeonthemes[nexttheme].spr1+2,
     text='',
     enter=nextfloor,
    }

    add(interactables,door)

    _col=0
    if dungeontheme == 1 then
     _col=1
    end
   end

   -- set floormap value
   floormap[_y][_x]=_col
  end
 end

 -- start theme music
 music(dungeonthemes[dungeontheme].musicstart,0,0b0011)

end

function dungeonupdate()

 --note: devkit debug
 -- if stat(30)==true then
 --  c=stat(31)
 --  if c == 'd' then
 --   isdebug=not isdebug
 --   debug('isdebug',isdebug)
 --  end
 -- end

 gametick+=1

 if gametick < 120 then
  return
 end

 if avatar.hp <= 0 then
  if gametick-deathts > 150 and btnp(4) then
   dungeoninit()
  end
  return
 end

 local angle=btnmasktoangle[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 if angle then
  if avatar.state != 'recovering' and
     avatar.state != 'attacking' then
   avatar.a=angle
   avatar.dx=normalize(cos(avatar.a))
   avatar.dy=normalize(sin(avatar.a))
   avatar.state='moving'
   avatar.state_counter=2
  end
 else
  avatar.dx,avatar.dy=0,0
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

  if skill then
   avatar.state='attacking'
   avatar.currentskill=skill
   avatar.ispreperform=true

   avatar.state_counter=skill.preperformdur

   avatar.currentframe=1
   avatar.items.weapon.currentframe=1

   if avatar.currentskill.startpemitter then
    avatar.currentskill.startpemitter(avatar,skill.preperformdur)
   end
  end
 end

 -- update actors
 local enemycount=0
 for actor in all(actors) do
  if actor.isenemy then
   enemycount+=1
  end

  if actor.state_counter > 0 then
   actor.state_counter-=1
  end

  -- handle states
  if actor.state == 'idling' then

   -- reset enemy specifics
   actor.targetx,actor.targety=nil,nil
   actor.ismovingoutofcollision=nil

  elseif actor.state == 'attacking' then

   if actor == avatar then

    -- update skills
    if avatar.state_counter <= 0 then
     if avatar.ispreperform then

      local skill=avatar.currentskill
      skill.perform(skill,avatar)

      -- set avatar to postperform
      avatar.state_counter=skill.postperformdur
      avatar.ispreperform=false

      -- set next attacking frame
      avatar.currentframe=2
      avatar.items.weapon.currentframe=2

     else -- note: done performing
      avatar.state='idling'
      avatar.items.weapon.currentframe=1
     end
    end


   else -- enemies

    if actor.laststate != 'attacking' then
     actor.ispreperform=true
     actor.currentframe=1
     actor.state_counter=actor.attack_preperformdur

     if actor.onpreperform then
      actor.onpreperform(actor)
     end
    end

    if actor.ispreperform and actor.state_counter <= 0 then
     actor.performattack(actor)
     actor.ispreperform=false
     actor.state_counter=actor.attack_postperformdur
     actor.currentframe=2

    elseif actor.state_counter <= 0 then
     if actor.afterpostperform then
      actor.afterpostperform(actor)
     end
     actor.state='idling'
    end
   end

  elseif actor.state == 'recovering' then

   if actor.effect then
    actor.effect.func(actor)
   end

   if actor.state_counter <= 0 then
    actor.state='idling'
    actor.effect=nil
   end

  elseif actor.state == 'moving' and
         actor.isenemy then

   if actor.state_counter <= 0 then
    actor.ismovingoutofcollision=nil
   end

   actor.a=atan2(
     actor.targetx-actor.x,
     actor.targety-actor.y)

   if dist(
       actor.x,
       actor.y,
       actor.targetx,
       actor.targety) <= actor.spd + 0.1 then
    actor.state='idling'
   end

   actor.dx=cos(actor.a)*actor.spd
   actor.dy=sin(actor.a)*actor.spd

  end

  if actor == avatar and
     actor.state_counter <= 0 then
   actor.state='idling'
   actor.currentskill=nil
  end

  actor.laststate=actor.state
 end


 -- ai to make decisions
 curenemyidx+=1
 if curenemyidx > #actors then
  curenemyidx=1
 end
 do
  local enemy=actors[curenemyidx]
  if enemy and enemy.isenemy then

   -- resolving effect vars
   local isresolvingeffect=enemy.state=='recovering'

   -- todo: ai should have aggravator instead of
   --       avatar hard-coded

   -- aggression vars
   local distancetoavatar=dist(enemy.x,enemy.y,avatar.x,avatar.y)
   local withinattackdistance=distancetoavatar <= enemy.attack_range
   local haslostoavatar=haslos(enemy.x,enemy.y,avatar.x,avatar.y)
   local isswinging=enemy.state == 'attacking'

   -- movement vars
   local ismovingoutofcollision=enemy.ismovingoutofcollision
   local collidedwithwall=enemy.wallcollisiondx != nil
   local istooclosetoavatar=distancetoavatar <= enemy.comfydist
   local hastoocloseto=#enemy.toocloseto > 0
   local hastarget=enemy.targetx!=nil


   if isresolvingeffect then
    -- resolving effect

   -- continue to move out of collision
   elseif ismovingoutofcollision then

    enemy.state='moving'

   -- too close to avatar, note: collidedwithwall not working here?
   elseif istooclosetoavatar and (not isswinging) and (not collidedwithwall) then

    enemy.state='moving'
    enemy.a=atan2(
      avatar.x-enemy.x,
      avatar.y-enemy.y)+0.5 -- note: go the other way
    enemy.targetx=enemy.x+cos(enemy.a)*10
    enemy.targety=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_counter=60
    enemy.spd=enemy.runspd

   -- attack
   elseif isswinging or withinattackdistance and
         (haslostoavatar or enemy.islosindependent) then

    if enemy.laststate != 'attacking' then
     enemy.currentframe=1
    end

    enemy.state='attacking'
    enemy.targetx=avatar.x
    enemy.targety=avatar.y
    -- todo: swing timer

   -- colliding w wall, move out of
   elseif collidedwithwall then

    enemy.state='moving'
    enemy.a=atan2(
      enemy.x+enemy.wallcollisiondx-enemy.x,
      enemy.y+enemy.wallcollisiondy-enemy.y)+rnd(0.2)-0.1
    enemy.targetx=enemy.x+cos(enemy.a)*10
    enemy.targety=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_counter=60

   -- colliding w other, move out of
   elseif hastoocloseto then

    enemy.state='moving'
    local collidedwith=enemy.toocloseto[1]
    enemy.a=atan2(
      collidedwith.x-enemy.x,
      collidedwith.y-enemy.y)+0.5 -- note: go the other way
    enemy.targetx=enemy.x+cos(enemy.a)*10
    enemy.targety=enemy.y+sin(enemy.a)*10
    enemy.ismovingoutofcollision=true
    enemy.state_counter=60

   -- set avatar position as target, move there
   elseif haslostoavatar then

    enemy.state='moving'
    enemy.targetx=avatar.x
    enemy.targety=avatar.y
    enemy.a=atan2(
      enemy.targetx-enemy.x,
      enemy.targety-enemy.y)
    enemy.spd=enemy.runspd

   -- continue to move to target
   elseif hastarget then

    enemy.state='moving'

   -- roam
   elseif not hastarget then

    enemy.state='moving'
    enemy.a=rnd()
    enemy.targetx=enemy.x+cos(enemy.a)*10
    enemy.targety=enemy.y+sin(enemy.a)*10
    enemy.spd=enemy.runspd*0.5

    if enemy.onroam then
     enemy.onroam(enemy)
    end

   end
  end
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

 -- check level cleared
 if enemycount <= 0 and not isdoorspawned then
  isdoorspawned=true
  floormap[(door.y-4)/8][(door.x-4)/8]=0
  sfx(19)
 end

 -- collide against interactables
 currentinteractable=nil
 if isdoorspawned then
  for i in all(interactables) do
   if isaabbscolliding(avatar,i) then
    i.enter(i)
    currentinteractable=i
   end
  end
 end

 -- collide against attacks
 for attack in all(attacks) do
  for actor in all(actors) do
   if (not attack.removeme) and
      (not actor.removeme) and
      attack.isenemy != actor.isenemy and
      isaabbscolliding(attack,actor) then

    attack.targetcount-=1

    local hitsfx=6

    -- special case if ice and already frozen
    if attack.typ == 'ice' and
       actor.effect and
       actor.effect.func == freezeeffect then
     attack.damage+=1
    end

    -- do damage
    if actor.armor and actor.armor > 0 then
     actor.armor-=attack.damage
     if actor.armor < 0 then
      actor.hp+=actor.armor
      actor.armor=0
     end
    else
     actor.hp-=attack.damage
    end

    -- go into recovering
    actor.state='recovering'
    if attack.recovertime then
     actor.state_counter=attack.recovertime
    else
     actor.state_counter=0
    end

    -- check if actor dead
    if actor.hp <= 0 then
     actor.removeme=true
     hitsfx=3

     -- add chest
     if actor == boss then
      add(interactables,{
       x=boss.x,
       y=boss.y,
       halfw=4,
       halfh=4,
       sprite=22,
       text='\x8e open',
       enter=function(i)
        if btnp(4) and not i.isopen then
         i.isopen=true
         i.text='empty'
         i.sprite=23
         local item=allitems[flr(rnd(#allitems))+1]
         del(allitems,item)
         add(avatar.inventory,item)
         sfx(20)
        end
       end,
      })
     end

     -- todo: add death vfx here
    end

    -- effects

    actor.dmgfxcolor=8 -- note: red is default color

    if attack.typ == 'phys' and not actor.isbig then
     actor.dx=cos(attack.knockbackangle)*5
     actor.dy=sin(attack.knockbackangle)*5

    elseif attack.typ == 'fire' then
     actor.effect={func=burningeffect}

    elseif attack.typ == 'stun' then
     actor.effect={func=stunningeffect}

    elseif attack.typ == 'ice' then
     actor.effect={func=freezeeffect}
     actor.dmgfxcolor=12
    end

    sfx(hitsfx)

    -- vfx

    -- start damage indication
    actor.dmgfxcounter=20

    -- hit flash
    local x,y=
      actor.x+actor.dx/2,
      actor.y+actor.dy/2
    add(vfxs,{
     {42,20,5,5,x-2.5,y-2.5,counter=4,col=actor.dmgfxcolor},
     {42,20,5,5,x-2.5,y-2.5,counter=5,col=7},
    })

    -- on hit handling
    for skill in all(actor.passiveskills) do
     if skill.onhit then
      skill.onhit(actor)
     end
    end
   end
  end
 end

 -- reset toocloseto
 for actor in all(actors) do
  actor.toocloseto={}
 end

 -- enemies movement check against others
 for i=1,#actors-1 do
  for j=i+1,#actors do
   local enemy=actors[i]
   local other=actors[j]
   if enemy != other and
      enemy != avatar and
      other != avatar and
      enemy.isenemy and
      dist(
        enemy.x,
        enemy.y,
        other.x,
        other.y) < enemy.halfh + other.halfh then
    add(enemy.toocloseto,other)
    add(other.toocloseto,enemy)
   end
  end
 end

 -- avatar movement check against other actors
 for actor in all(actors) do
  if actor != avatar and not actor.isghost then
   local _dx,_dy=collideaabbs(
     isaabbscolliding,
     avatar,
     actor,
     avatar.dx,
     avatar.dy)

   avatar.dx,avatar.dy=_dx,_dy
  end
 end

 -- movement check against floormap
 for actor in all(actors) do
  local _dx,_dy=collideaabbs(
    isinsidewall,
    actor,
    nil,
    actor.dx,
    actor.dy)

  if actor.isenemy then
   actor.wallcollisiondx=nil
   actor.wallcollisiondy=nil
   if _dx != actor.dx or
      _dy != actor.dy then
    actor.wallcollisiondx=_dx
    actor.wallcollisiondy=_dy
   end
  end

  actor.x+=_dx
  actor.y+=_dy
  actor.dx,actor.dy=0,0
 end

 -- update attacks
 for attack in all(attacks) do
  if attack.state_counter then
   attack.state_counter-=1
   if attack.state_counter <= 0 or
      attack.targetcount <= 0 then
    attack.removeme=true
   end
  end

  if attack.dx then
   attack.x+=attack.dx
  end

  if attack.dy then
   attack.y+=attack.dy
  end

  if attack.x > 128 or
     attack.x < 0 or
     attack.y > 128 or
     attack.y < 0 then
   attack.removeme=true
  end

  if not attack.throughwalls and
     isinsidewall(attack) then
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
  local stateframes=actor[actor.state]

  local animspd=0.25 -- note: default
  if stateframes.animspd then
   animspd=stateframes.animspd
  end
  actor.currentframe+=animspd*actor.spd

  if actor.currentframe >= #stateframes+1 then
   actor.currentframe=1
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
  if not pemitter.counter then
   pemitter.counter=pemitter.prate[1]
  end
  if not pemitter.particles then
   pemitter.particles={}
  end
  pemitter.counter-=1
  if pemitter.counter <= 0 then
   local x,y,poffsets,pdx,pdy=
     pemitter.follow.x,
     pemitter.follow.y,
     pemitter.poffsets,
     pemitter.dx,
     pemitter.dy

   x+=poffsets[1]+rnd(poffsets[3]+abs(poffsets[1]))
   y+=poffsets[2]+rnd(poffsets[4]+abs(poffsets[2]))

   local dx,dy=
     pdx[1]+rnd(pdx[2]+abs(pdx[1])),
     pdy[1]+rnd(pdy[2]+abs(pdy[1]))

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
  music(-1)
  deathts=gametick
  sfx(2)
 end
end


function dungeondraw()
 cls(0)

 -- get theme start sprite
 local spr1=dungeonthemes[dungeontheme].spr1

 -- draw walls
 for _y=0,#floormap do
  for _x=0,#floormap[_y] do
   if floormap[_y][_x] != 0 then
    if _y == #floormap or floormap[_y+1] and floormap[_y+1][_x] != 0 then
     spr(spr1+1,_x*8,_y*8)
    else
     spr(spr1,_x*8,_y*8)
    end
   end
  end
 end

 -- draw interactables
 if isdoorspawned then
  for i in all(interactables) do
   spr(
    i.sprite,
    i.x-i.halfw,
    i.y-i.halfh)
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
 end

 -- todo: sort on y and z
 --       maybe z can be layers?
 --       per z add 128 (plus margin)
 --       to y when sorting

 -- draw actors
 for actor in all(actors) do

  -- draw actor frame
  local state,flipx=actor.state,false
  local frame=actor[state][flr(actor.currentframe)]
  if actor.a and actor.a >= 0.25 and actor.a <= 0.75 then
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
    pal(i,actor.dmgfxcolor,0)
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
   local stateframes=item[state]
   local frame=stateframes[min(
     flr(item.currentframe),
     #stateframes)]
   pal(6,item.col,0)
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
  end

  -- draw offhand
  if actor == avatar and
     avatar.items.offhand then
   item=avatar.items.offhand
   local stateframes=item[state]
   local frame=stateframes[min(
     flr(item.currentframe),
     #stateframes)]
   pal(6,item.col,0)
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
  end

  -- draw cloak
  if actor == avatar and
     avatar.items.armor and
     avatar.items.armor.iscloak then
   item=avatar.items.armor
   local stateframes=item[state]
   local frame=stateframes[min(
     flr(item.currentframe),
     #stateframes)]
   pal(1,item.col,0)
   pal(3,item.col2,0)
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
  end

  -- reset colors
  for i=1,15 do
   pal(i,i,0)
  end

 end

 -- draw vfx
 for vfx in all(vfxs) do
  local frame=vfx[1]
  if frame.draw then
   frame.draw(frame)
  else
   pal(7,frame.col,0)
   sspr(
     frame[1],
     frame[2],
     frame[3],
     frame[4],
     frame[5],
     frame[6])
   pal(7,7,0)
  end
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

 -- draw interactable text
 if currentinteractable then
  print(
   currentinteractable.text,
   mid(
     0,
     currentinteractable.x-#currentinteractable.text*2,
     124-#currentinteractable.text*4),
   max(8,currentinteractable.y-8),
   10)
 end

 -- draw gui
 if dungeonlevel > 0 then
  print('level '..dungeonlevel,3,1,13)
 end
 print(avatar.armor..'/'..avatar.startarmor..' a',82,1,6)
 print(avatar.hp..' hp',110,1,8)
 if avatar.hp <= 0 then
  print('a deadly blow',40,60,8)
  if gametick-deathts > 150 then
   print('press \x8e to continue',26,68,8)
  end
 end

 -- draw boss hp
 if boss and boss.hp > 0 then
  local halfw=boss.hp*6/2
  rectfill(64-halfw,122,64+halfw,125,8)
 end

end




-- equip scene

inventorycur,
equippedcur,
availableskillscur,
sectioncur,
equipped,
availableskills,
equipslots=
  1,
  1,
  1,
  4,
  {},
  {},
  {
   {'helmet',10},
   {'armor',11},
   {'amulet',8},
   {'boots',9},
   {'book',13},
   {'offhand',12},
   {'weapon',15},
  }

function equipinit()
 _update60=equipupdate
 _draw=equipdraw
 poke(0x5f43,0b0011) -- note: undocumented lopass
end

function equipupdate()

 -- mute melody channel
 -- sfx(18,0)

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
 for item in all(avatar.inventory) do
  if avatar.items[item.class] == item then
   del(avatar.inventory,item)
  end
 end

 -- inventory
 if sectioncur == 1 then
  if btnp(0) then
   inventorycur=mid(1,inventorycur-1,#avatar.inventory)
   sfx(7)
  elseif btnp(1) then
   inventorycur=mid(1,inventorycur+1,#avatar.inventory)
   sfx(7)
  end

  if #avatar.inventory > 0 and (btnp(4) or btnp(5)) then
   local selecteditem=avatar.inventory[inventorycur]

   avatar.skill1,avatar.skill2=nil,nil

   if avatar.items[selecteditem.class] then
    add(avatar.inventory,avatar.items[selecteditem.class])
   end

   avatar.items[selecteditem.class]=selecteditem

   if selecteditem.twohand then
    add(avatar.inventory,avatar.items.offhand)
    avatar.items.offhand=nil
   end

   if selecteditem.class == 'offhand' and
      avatar.items.weapon and
      avatar.items.weapon.twohand then
    add(avatar.inventory,avatar.items.weapon)
    avatar.items.weapon=nil
   end

   inventorycur=mid(1,inventorycur,#avatar.inventory-1)

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
   if selecteditem then
    avatar.items[selecteditem.class]=nil
    add(avatar.inventory,selecteditem)
    avatar.skill1,avatar.skill2=nil,nil
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
   _draw=dungeondraw
   _update60=dungeonupdate
   poke(0x5f43,0)
  end
 end

end

function equipdraw()

 cls(0)

 fillp(0b1010000110000101)
 rectfill(0,0,128,3,1)
 rectfill(0,124,128,128,1)
 fillp()

 -- draw inventory section
 local offsetx,y,i,col=0,17,1,0
 if sectioncur == 1 then
  col=10
 else
  col=4
 end
 print('saddlebags',4,y-9,col)
 for item in all(avatar.inventory) do
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
 offsetx,y,i=0,52,1
 if sectioncur == 2 then
  col=10
 else
  col=4
 end
 print('equipped',4,y-9,col)
 for slot in all(equipslots) do
  local item=avatar.items[slot[1]]
  if not item then
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
 offsetx,y,i=0,88,1
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


_init=function()
 gametick=0
 _update60=function()
  gametick+=1
  if btnp(4) then
   dungeoninit()
  end
 end
 _draw=function()
  cls(0)
  sspr(41,56,87,72,21,20)
  col=13
  if gametick % 60 <= 30 then
   col=6
  end
  print('\x8e to start',42,118,col)
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000555550000000000055555000550055005555550005555500000005500000055
00000000000000000000054000000000000000000000000000000000000000005000005055505500555555505555555505555550050000000000055000000555
00000000000000000022544400000000000000000000000000000000000000005000005055505500555555505055550505555550055555000000505000005550
00000000000000000544440000000000000000000000000000000000000000000550050055505500500500505055550505555550055555000005005050055500
00000000000000005040040000000000000000000000000000000000000000000005500055505500550005500055550005555550055555000050050005555000
00000000000000000050050000000000000000000000000000000000000000000055550055550550550005500055550005555550055555000500500000550000
0f000000000000000000000000000000000000000000000000000000000000000055550055555055550005500055550000555500055555005555000005050000
11100000000000000000000000000000000000000000000000000000000000000005500005555055050005000000000000055000055555005000000050005000
1310000000000000000000000000000000000000000000000000000000000000011111100000000000000000000000000000000011111111111111dd111111dd
131000000000000066000000000060000000000000000000000000000000000011111111000000000000000000000000000000001111111111111dd111111ddd
0f00f00f40000600000000000000060006000000000000000000000000000000111111110000000000000000000000000000000011dd1dd11111d1d11111ddd1
44444444000006000000000660000600006660000000000000000000024224201111111100000000000000000000000000000000d111dddd111d11d1d11ddd11
0400400400000000000000000000600006066000000000000242242001111110011111100000000000000000000000000000000011d1dddd11d11d111dddd111
2020202020000000000000000000000000000000000060000229922002299220000000000000000000000000000000000000000011111dd11d11d11111dd1111
0000000000000000000000000000000000000000007000000244442002444420000000000000000000000000000000000000000011111111dddd11d11d1d1111
000000000dd00000000020002000000002005050506000000222222002222220000000000000000000000000000000000000000011111111d111111dd111d111
060d060d0660060000060206020620006020555555007000000000000000000000000000000000000006d00005600d500666ddd0008888800000004200000066
666d666d6600666dd0066206626662066620050505060000000000000000000000000000444420200066d500d556d55d06dd11d008ffff40000006400000066d
060006000600060000062006200620006020000000070000000000000000cc00000000004422202006d6d55050d55d0506d6d1d00222224000006040000067d0
60600600606060600060600600606006060000000000000000000000000ccccc0000000004440400d6d6d555d024920d06d6d1d0022822400006004000067d00
0700007077770000777707777700007000070088800777022022022200cc00ccc00000000a9909006766dddd00d55d000d1dd1d002288240006005000f67d000
007007000077700777007777777707000000788888777772200020202cc0000cc0000000044440400006d0000056d5000d1111d0028e824006005000009d0000
0070070000077777700070000000770000007888887777700000000000cc00cc0000000002444404d000000d00d55d0000d11d00028e82404444000002090000
00777700000770077000700000007770000778888877777000000000000cccc000000000002222025000000500000000000dd000022222002000000090000000
007777000000000000007777777707777777708880077700000000000000cc000000000000000000000000000000000000000000000000000020010000666660
07777770000000000000077777000077777700000000000000000000000000000000000000000000000000000000000000000000000000000e2221d0067777d0
777777770000000000000000000000070070000000000000000000000000000000000000000000000000000000000000000000000000000002eeed100cccccd0
7000000007777777700000007000000007000000000000000000000000000000000000000000000000000000000000000000000000000000022002100c7c7cd0
7700000077077777000000007700000077000000000000000000000000000000000000000000000000000000000000000000000000000000022002100cc7ccd0
7770000777007770000000007770000777000000000000000000000000000000000000000000000000000000000000000000000000000000022002100c7c7cd0
7770770777000000000000007777007777000000000000000000000000000000000000000000000000000000000000000000000000000000022002100cccccd0
7770000777000700000000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000220000210ccccc00
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
00000000f000000000000000f000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ff00000000000000ff00000000000000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006600000000000000660000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000600b000000000000600b000000000000600b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066600000000000006660000000000000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000606066000000000060606600000000006060660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00406066600000000040606660000000004060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040006000000000004000600000000000400060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d040606000000000d040606000000000d040606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000060600000000d000060600000000d000060600000000000000000000000000000000000000000000000000150000000005155d551500000000000000000
d000006060000000d000006000000000d00000006000000000000000000000000000000000000000000000000015100000055dd6677766665510000000000000
00000077777770000000000000000000000000000000000000000000000000000000000000000000000000000155100015dd7777777777777665100000000000
00007777777777700000000000000000000000000000000000000000000000000000000000000000000000000555000556777777777777777777d50000000000
007777777777777770000000000000000000000000000000000000000000000000000000000000000000000055d000556777777777777777777776d100000000
07777777777777777700000000000000000000000000000000000000000000000000000000000000000000055d1015d777777777777777777777777610000000
d777777777000777770000000000000000000000000000000000000000000000000000770000000000000055d501567777777777777777777777777761000000
0d7777700000000077700000000000000000000000000000000000000000000000000067000000000000015d5115d7777777777777777777777777776d100000
00d777000f0000000770000000000000f00000000000000000000000000000000000006740000000000015d5505d77777777777777777777777776666d510000
000d7400ff000000007700000000000ff00b0000000000000000000000000000000000762000000000001d5d0557777777777777777777777777776ddd550000
000040006600000000770000000000066000000000000000000000000000000000000574400000000001d5d15567777777777777777777777777776ddd655000
000406006600000000070000000000066006000000000050000000000d77d000000007740000000000155d515d77777777777777777777777777777666dd5100
00000060600000000007000000000006006000000000077d000000057765100000005762205000000055d51156777777777777777777777777777777766dd100
000000066600000000070000000000666600000000006750000000677702220000006742067d0000055d5505577777777777777777777777777777777766d500
00000000600000000007000000000606000000000000774220000d7664400057776576400077500055d550156777777777777777777777777777777777766510
000000066600000000700000004060666000000000057d200000675224200d775d677720005750015d5d10156777777777777777777777777777777777776610
0000000060000000007000000004000600000000000d7440000d7d22257757602247677767774005d5d100557777777777777777777777777777777777777650
00000006060000000700000000d040606000000000067400001764220777777422d7644d67d2201d5d50015d7777777777777777777777777777777777777651
0000006000600007700000000d0000606000000000077200007744605777654000764046752461d5677501d777777777777777777777777777777777777777d1
000000060006077000000000d00000606000000000077400067627750777447d0576220774077d5d7777157777777777744777777777777777777777777777d5
0000000000000000000000000000000000000000001770001772476006776775067420d760d765d77d77d5774677477764477777777777777777777777777761
00000000000000000000000000000000000000000017620067546744077777640764007744774467d477467647764f7764f777777777777777777777777777d5
00000000000000000000000000000000000000000057600176427740574267d2d7622d7645764477447747744774477774777777777777777777777777777761
0000000000000000000000000000000000000000005742067424762576247742774207740674277624777764476467477d77777744f7777777777777777777d5
000000000000000000000000000000000000000000d740576226742d70457645774067744774d7744077774277447746746677764477777777777777777777d1
000000000000000000000000000000000000000000d7426754077457540674277625776477647774057477467747762674467774467777777777777777777755
0000000000000000000000000000000000000000006745764507747d220777777747776777477d745762776776777447744d6774477777777777777777777651
000000000000000000000000000000000000000000672774771777d020d7777577765777d77754777704777d77767777644d6744677777777777777777777d50
00000000000000000000000000000000000000000076d7d771007d22577674424760447444754247d04057454747766644dd77446d6666777777777777777550
000000000000000000000000000000000000000001767747640024257762242404240524242420042400042454247424245677445d66d666677777777777d510
000000000000000000000000000000000000000001777567420000577522222000200542555000004000002051444245455d7d45d5dddd6d66777777767d5100
00000000000000000000000000000000000000000777547742000077d422000000001d5d550000000000000011155455111774255d5d5d5ddd777766d6d51100
00000000000000000000000000000000000000000774427640000d76420000000001d5d5d00000000000000010115567511774455555d5d5d7777dd5d5515000
0000000000000000000000000000000000000000000425760000176426755d001616765d106700d50710060006111d7771576477555557765776745515110000
000000000000000000000000000000000000000000220576200076d277777750677777d5067776766760676057700d774067477765557777d777427651100000
000000000000000000000000000000000000000000000d76000d76247657760077767751d7d477d2764076506740077d247777d7455776274d77477601000000
000000000000000000000000000000000000000000000d74200774477447744d776d74407744774d7d4d7d457640d77445777577456762674677777441100000
00000000000000000000000000000000000000000000066400d7d457644764077727740776267627740774077d2077760d774476247744762774476407700000
00000000000000000000000000000000000000000000067420764067d2674267744762577447746762476247742d75775676467446777765774267d257500000
00000000000000000000000000000000000000000000077406762276447644776477427764577477446744777407746747744774477744547524774276220000
000000000000000000000000000000000000000000000775577425764676477744774477d277647744774d7742774267676267d2777442476545764670400000
00000000000000000000000000000000000000000000076267440d76477d77742d76476747774777477747d7477744777744674776742d76040d744754000000
00000000000000000000000000000000000000000000076576400577767776724d777567777767777d7775477756777774407777547777604005777522000000
0000000000000000000000000000000000000000000017467422007742d7444455d7422774777427d2276226750446674420077524d765040000775220000000
00000000000000000000000000000000000000000000576762200022424242425002422044767042422242204240224242000042402242400000224200000000
00000000000000000000000000000000000000000000d77754000002220425551002220027774400220002000400020220000024000222000000022200000000
00000000000000000000000000000000000000000000777540000000005555d50000000007772000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001774420000000055555510488888887742828888888888000048888888888888888088888888400000000
111111111111111111111111000000000000000000000242510000001555555028888888e7722888888888888000288888888888888888888888888880000000
111111111111111100000001000000000000000000000420011100015d5555002888888877448888888888880000488888888888888888888888888882000000
000000001111111155011001000000000000000000000000001150115155d100088888887f428888888888800000088888888888888882888888888880000000
01101111111111115500001100000000000000000000000000001515111d10000008888e74288888288888400000088888800008888800288888888200000000
01001110111111115515500100000000000000000000000000000151115500000002888772204888088884800000088888200008888800088888800000000000
00000000111111115515500100000000000000000000000000000115151100000002888744000020048888880000088888000008888800028888800000000000
11011011111111115515515100000000000000000000000000000011515100044002887740000000008888880000888880000008888820008888800000000000
10010011111111111111111100000000000000000000000000000001151511420002877822028000004888882002888880000008888800028888800000000000
11111111111111110000000000000000000000000000000000000000000011400004888248888800000888888008888800000008888820028888800000000000
11111111111111110050050000000000000000000000000000000000000001250008884288888800000288888228888800000008888820048888200000000000
11011111111111110055550000000000000000000000000000000000000424425118888888888800000088888888888000000008888880028888200000000000
10110101111111110050050000000000000000000000000001000000004424000118888888888800000088888888884000000008888880088888200000000000
10101001111111110155551000000000000000000000000001510000000042000008888800288200000028888888882000000008888880088888200000002000
10101010111111111050050100000000000000000000000000151100040004000008888800000000000008888888880000000008888820088888200000048820
00100010111111110111111000000000000000000000000000001000025204000008888820000020000000888888820000000008888820088888200000888820
01000100111111110000000000000000000000000000000000000000044004000004888820024888000000888888800000000008888800088888820288888800
00000d0000000d000000000000000000000000000000000000000000000002000028888288888888000000488888800000000008888882888884888888888200
00d00d0000d00d000000000000000000000000000000000000000000000002002888888888888882000000088888200000000088888888888888888888888000
00d0d11000d0d1100000000000000000000000000000011000000000004040008888888888888880000000088888000000000888888888888888888888882000
0ddd01100ddd01100000000000000000000000000000155500000000044400028888888888888800000000048888000000000888888888888888888888880000
0dd101100dd101100000000000000000000000000001115510000000000000004884442000002000000000008888000000000282002228428840002020000000
ddd11011ddd110110000000000000000000000000005111500000000000000000000000000000000000000000882000000000000000000000000000000000000
dd111011dd1110110000000000000000000000000011511100000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010b00001a7421a7401a7301a735000000000000000007001c7421c7321c7301c7301c73500000000000000019750197501974219742197421974219732197401973500700000000000000000000000000000000
010800001a85000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000250402604028040290402b0402d0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001d1522115024150291502d150001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000
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
00 114b4344
01 0a0b4344
00 0c0b4344
00 0d0e4344
02 0f104344
01 0e424344
02 10424344

