pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

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

function ticktotimestr(tick)
 local s=flr(tick/60)
 local m=tostr(flr(s/60))
 s=tostr(s%60)
 if #m<2 then
  m='0'..m
 end
 if #s<2 then
  s='0'..s
 end

 return m..':'..s
end

function clamp(n,mini,maxi)
 return min(max(n,mini),maxi)
end

function copy(t)
 local result={}
 for key,value in pairs(t) do
  result[key]=value
 end
 return result
end

function sortbyy(a)
 for i=1,#a do
  local j = i
  while j > 1 and a[j-1].y > a[j].y do
   a[j],a[j-1] = a[j-1],a[j]
   j = j - 1
  end
 end
 return a
end

function distance(x1,y1,x2,y2)
 local dx=(x2-x1)*0.1
 local dy=(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

function distanceobjs(physobj1,physobj2)
 return distance(
   physobj1.x,
   physobj1.y,
   physobj2.x,
   physobj2.y)
end

function isinside(x,y,x1,y1,x2,y2)
 return x>x1 and x<x2 and y>y1 and y<y2
end

function getnormveccomps(physobj)
 local xcomp=cos(physobj.a)
 local ycomp=sin(physobj.a)
 return xcomp,ycomp
end

function newphysobj(x,y,w,h,r)
 return {
  x=x,
  y=y,
  w=w,
  h=h,
  r=r,
  a=0,
  spd=0.2,
 }
end

-- todo: maybe only should be point-aabb instead,
--       and use different statics for players,
--       one with larger goals.
function movephys(physobj,statics)
 physobj.oldx=physobj.x
 physobj.oldy=physobj.y
 local newx=physobj.x+cos(physobj.a)*physobj.spd
 local newy=physobj.y+sin(physobj.a)*physobj.spd
 local newa=physobj.a
 local xcomp,ycomp=getnormveccomps(physobj)
 local hasbounced=false
 local iscornercollision=false

 -- corner bounce
 for corner in all(corners) do
  local offsetx,offsety=0,0

  -- collision point should be closest corner of the physobj
  if corner == corners[1] then
   offsetx=0
   offsety=0
  elseif corner == corners[2] then
   offsetx=0
   offsety=physobj.h
  elseif corner == corners[3] then
   offsetx=physobj.w
   offsety=0
  elseif corner == corners[4] then
   offsetx=physobj.w
   offsety=physobj.h
  end

  local _newx=newx+offsetx
  local _newy=newy+offsety

  if isinside(
      _newx,
      _newy,
      corner[1],
      corner[2],
      corner[3],
      corner[4]) then
   local circx=corner[5]
   local circy=corner[6]
   local dx=_newx-circx
   local dy=_newy-circy
   if distance(circx,circy,_newx,_newy) > cornerr then

    -- where on the circ the collision occurred
    local anglecollisiontocircpos=atan2(dx,dy)

    -- move out of collision
    newx=cos(anglecollisiontocircpos)*cornerr+circx-offsetx
    newy=sin(anglecollisiontocircpos)*cornerr+circy-offsety

    -- angle diff from where the collision occurred
    local a1=anglecollisiontocircpos-physobj.a

    -- deflect
    newa=anglecollisiontocircpos+a1+0.5

    -- only bounce if angle delta is more than threshold
    local ad=newa-physobj.a
    ad=(ad+0.5)%1-0.5
    ad*=sgn(ad)
    debug('ad',ad)
    if ad > 0.1338 then
     hasbounced=true
    end

   end

   iscornercollision=true
  end
 end

 if not iscornercollision then

  for static in all(statics) do
   local x1=static.x
   local y1=static.y
   local x2=static.x+static.w
   local y2=static.y+static.h

   if isinside(newx,physobj.y,x1,y1,x2,y2) or
      isinside(newx+physobj.w,physobj.y,x1,y1,x2,y2) or
      isinside(newx,physobj.y+physobj.h,x1,y1,x2,y2) or
      isinside(newx+physobj.w,physobj.y+physobj.h,x1,y1,x2,y2) then
    newx=physobj.x
    if physobj.isbouncy then
     xcomp=-xcomp
     hasbounced=true
    else
     xcomp=0
    end
   end
   if isinside(physobj.x,newy,x1,y1,x2,y2) or
      isinside(physobj.x+physobj.w,newy,x1,y1,x2,y2) or
      isinside(physobj.x,newy+physobj.h,x1,y1,x2,y2) or
      isinside(physobj.x+physobj.w,newy+physobj.h,x1,y1,x2,y2) then
    newy=physobj.y
    if physobj.isbouncy then
     ycomp=-ycomp
     hasbounced=true
    else
     ycomp=0
    end
   end
  end

  newa=atan2(xcomp,ycomp)
 end

 physobj.x=newx
 physobj.y=newy
 physobj.a=newa
 if hasbounced==true then
  physobj.spd*=0.6
 end
end

function newpuck(x,y)
 local p=newphysobj(x,y,1,2,1)
 p.isbouncy=true
 p.player=nil
 return p
end

ai_scorer=0
ai_ass=1
ai_def1=2
ai_def2=3

teamcounters={
 [1]=0,
 [2]=0,
}

state_idle=0
state_begin_shooting=1
state_shooting=2
state_release_shot=3
state_do_pass=4
state_begin_tackle=5
state_tackling=6

function newplayer(x,y,team)
 local p=newphysobj(x,y,2,3,4)
 p.isbouncy=false
 p.state=state_idle
 p.team=team
 p.flipped=false
 p.stick=newphysobj(4,0,2,2,2)
 p.isshooting=false
 p.shootingspd=0
 p.shootingspdmax=5
 p.fallencounter=0
 p.tacklecounter=0
 p.ai={
  tactic=0+teamcounters[team],
  targetposx=x,
  targetposy=y,
 }
 teamcounters[team]+=1
 return p
end

function findplayerbytactic(players,tactic,team)
 for player in all(players) do
  if player.team==team and
     player.ai.tactic==tactic then
   return player
  end
 end
end

function findadjopponent(players,player)
 for p in all(players) do
  if p.team != player.team and
     distanceobjs(player,p) < p.r+player.r then
   return p
  end
 end
 return nil
end

function findteamplayerclosesttopuck(players,team,puck)
 local closest=nil
 local dist=1000

 -- init vars
 for player in all(players) do
  if player.team==team then
   closest=player
   dist=distance(player.x,player.y,puck.x,puck.y)
   break
  end
 end

 -- find closest
 for player in all(players) do
  if player.team==team then
   local thisdist=distance(player.x,player.y,puck.x,puck.y)
   if thisdist<dist then
    closest=player
    dist=thisdist
   end
  end
 end

 return closest
end

rinkx1=8
rinky1=16
rinkx2=256-8
rinky2=128-8
rinkmidy=(rinky2-rinky1)/2
rinkgoaloffx=20
rinkgoaly=(rinky2-rinky1)/2+rinky1
rinkgoalr=12
goalw=8
goalh=15

cornerr=16
corners={ -- todo: fix 2,3,4, maybe need player/puck tables?
 {0,0,rinkx1+cornerr,rinky1+cornerr, rinkx1+cornerr,rinky1+cornerr},
 {0,rinky2-cornerr,rinkx1+cornerr,128, rinkx1+cornerr,rinky2-cornerr},
 {rinkx2-cornerr,0,256,rinky1+cornerr, rinkx2-cornerr,rinky1+cornerr},
 {rinkx2-cornerr,rinky2-cornerr,256,256 ,rinkx2-cornerr,rinky2-cornerr},
}

goal1x1=rinkx1+rinkgoaloffx-7
goal1x2=rinkx1+rinkgoaloffx
goal1y1=rinkgoaly-7
goal1y2=rinkgoaly+6

goal2x1=rinkx2-rinkgoaloffx
goal2x2=rinkx2-rinkgoaloffx+7
goal2y1=rinkgoaly-7
goal2y2=rinkgoaly+6

goal1=newphysobj(
  goal1x1,
  goal1y1,
  goal1x2-goal1x1,
  goal1y2-goal1y1)

goal2=newphysobj(
  goal2x1,
  goal2y1,
  goal2x2-goal2x1,
  goal2y2-goal2y1)

-- note; for aiming
goal1x=goal1x2
goal1upperpost=goal1y1
goal1lowerpost=goal1y2

goal2x=goal2x1
goal2upperpost=goal2y1
goal2lowerpost=goal2y2

puckstatics={
 newphysobj(
   rinkx1-8,
   rinky1-8,
   256,
   8),
 newphysobj(
   rinkx1-8,
   rinky2,
   256,
   8),
 newphysobj(
   rinkx1-8,
   rinky1,
   8,
   120-15),
 newphysobj(
   rinkx2,
   rinky1,
   8,
   120-15),
 newphysobj(
   goal1.x,
   goal1.y,
   2,
   goal1.h),
 newphysobj(
   goal1.x+2,
   goal1.y,
   goal1.w-2,
   2),
 newphysobj(
   goal1.x+2,
   goal1.y+goal1.h-2,
   goal1.w-2,
   2),
 newphysobj(
   goal2.x+6,
   goal2.y,
   2,
   goal2.h),
 newphysobj(
   goal2.x,
   goal2.y,
   goal2.w-2,
   2),
 newphysobj(
   goal2.x,
   goal2.y+goal2.h-2,
   goal2.w-2,
   2),
}

playerstatics={
 puckstatics[1],
 puckstatics[2],
 puckstatics[3],
 puckstatics[4],
 newphysobj(
   goal1.x-6,
   goal1.y,
   goal1.w+6,
   goal1.h),
 newphysobj(
   goal2.x,
   goal2.y,
   goal2.w+6,
   goal2.h),
}

players={}
puck=nil

scoreteam1=0
scoreteam2=0

function _init()
 reset()
end

function reset()

 players={}

 -- init players
 startingposteam1={
  {50,30},
  {50,100},
 }
 for pos in all(startingposteam1) do
  add(players,newplayer(pos[1],pos[2],1))
 end

 startingposteam2={
  {140,100},
  {190,50},
 }
 for pos in all(startingposteam2) do
  add(players,newplayer(pos[1],pos[2],2))
 end

 -- init puck
 puck=newpuck(128,64)

 -- choose avatar
 p1player=players[1]

end

tick=0
hockeytick=0 -- hockey playtime

celebratets=0
iscelebrategoal=false

function _update60()
 --note: devkit debug
 if stat(30)==true then
  local c=stat(31)
  if c == 'd' then
   isdebug=not isdebug
   debug('isdebug',isdebug)
  end
 end

 tick+=1

 if iscelebrategoal then
  if tick - celebratets > 300 then
   iscelebrategoal=false
   puck.x=128
   puck.y=64
   puck.spd=0
   puck.player=nil
  end
  return
 end

 hockeytick+=1

 local xcomp,ycomp=getnormveccomps(p1player)

 if btn(0) then
  xcomp=-1
 elseif btn(1) then
  xcomp=1
 end

 if btn(2) then
  ycomp=-1
 elseif btn(3) then
  ycomp=1
 end

 -- set player angle
 if btn(0) or btn(1) or btn(2) or btn(3) then
  p1player.a=atan2(xcomp,ycomp)
  if p1player.isshooting==false then
   p1player.spd=max(1,p1player.spd)
  end
 end

 -- p1player has the puck
 if p1player==puck.player then

  -- raise stick to shoot
  if btn(4) and
     p1player.state==state_idle then
   p1player.state=state_begin_shooting

  -- release shot
  elseif not btn(4) and
         p1player.state==state_shooting then
   p1player.state=state_release_shot

  -- pass
  elseif btn(5) then
   p1player.state=state_do_pass
  end

 -- p1player does not have the puck
 else

  -- tackle
  if btn(4) and
     p1player.state==state_idle then
   p1player.state=state_begin_tackle
  end

  -- change selected player
  if btnp(5) then
   local closestplayer=findteamplayerclosesttopuck(players,1,puck)
   p1player=closestplayer
  end
 end

 -- friendly ai
 for player in all(players) do
  if player != p1player and
     player.team==p1player.team then

   if puck.player==p1player then
    player.ai.targetposx=200
    player.ai.targetposy=64
   elseif puck.player==nil then
    player.ai.targetposx=puck.x
    player.ai.targetposy=puck.y
   end

   local a=atan2(
     player.ai.targetposx-player.x,
     player.ai.targetposy-player.y)
   player.a=a
   player.spd=1
   if distance(player.ai.targetposx,
      player.ai.targetposy,
      player.x,
      player.y) < 5 then
    player.spd=0
   end
  end
 end

 -- move players
 for player in all(players) do
  if player.fallencounter>0 then
   player.fallencounter-=1
  else
   player.spd=max(player.spd,0)
   movephys(player,playerstatics)
   player.spd*=0.89 --  todo: move this outside else

   -- set player flipped
   player.flipped=true
   if player.a<0.25 or
      player.a>0.75 then
    player.flipped=false
   end

   -- move stick with the player
   if player.flipped==false then
    player.stick.x=player.x+5
    player.stick.y=player.y
   else
    player.stick.x=player.x-5
    player.stick.y=player.y
   end

   -- begin tackled ignored if recent tackle
   if player.tacklecounter>0 then
    player.tacklecounter-=1
    if player.state==state_begin_tackle then
     player.state=state_idle
    end
   end

   -- initiate tackle
   if player.state==state_begin_tackle then
    player.spd+=1.8
    player.tacklecounter=60
    player.state=state_tackling
   end

   -- tackling
   if player.state==state_tackling then

    -- if speed is over normal
    if player.spd>1 then

     -- tackle adjacent opponent 
     local adjopponent = findadjopponent(players,player)
     if adjopponent != nil and
        adjopponent.fallencounter<=0 then
      adjopponent.fallencounter=130
      adjopponent.isshooting=false
      if puck.player==adjopponent then
       puck.player=nil
       puck.a=rnd(1)
       puck.spd=1
      end
     end

    -- go back to idle
    else
     player.state=state_idle
    end
   end
  end
 end

 -- handle puck owner states
 if puck.player != nil then

  -- raise stick to shoot
  if puck.player.state==state_begin_shooting then
   puck.player.isshooting=true

   puck.player.state=state_shooting

  -- shooting
  elseif puck.player.state==state_shooting then
   puck.player.shootingspd=clamp(
     puck.player.shootingspd+0.09,
     2.9,
     puck.player.shootingspdmax)

  -- release shot
  elseif puck.player.state==state_release_shot then
   if puck.player.shootingspd==puck.player.shootingspdmax then
    puck.spd=puck.player.shootingspd+3
   else
    puck.spd=puck.player.shootingspd
   end
   puck.player.isshooting=false
   puck.player.shootingspd=0

   if puck.player.team == 1 and
      (puck.player.a < 0.25 or puck.player.a > 0.75) then
    puck.a=atan2(
      goal2x-puck.x,
      (goal2upperpost+4)-puck.y)
   end

   puck.player.state=state_idle
   puck.player=nil

  -- pass
  elseif puck.player.state==state_do_pass then
   puck.spd=4.5

   local _dist=256
   local _closestp=nil
   for _p in all(players) do
    local _d=distanceobjs(_p,puck.player)
    if _p != puck.player and
       _p.team == puck.player.team and
       _d < _dist then
     _dist=_d
     _closestp=_p
    end
   end

   local newa=atan2(_closestp.x-puck.player.x,
     _closestp.y-puck.player.y)

   debug(abs(newa-puck.player.a))
   if abs(newa-puck.player.a) < .25 then
    puck.a=newa
   else
    puck.a=puck.player.a
   end

   puck.player.state=state_idle
   puck.player=nil
  end
 end

 -- move puck
 if puck.player != nil then
  puck.x=puck.player.stick.x
  puck.y=puck.player.stick.y

 else
  -- note: divide to prevent tunneling
  puck.spd/=4
  movephys(puck,puckstatics)
  movephys(puck,puckstatics)
  movephys(puck,puckstatics)
  movephys(puck,puckstatics)

  -- check goal1
  if isinside(
     puck.x,
     puck.y,
     goal1x1,
     goal1y1,
     goal1x2,
     goal1y2) then
   celebratets=tick
   iscelebrategoal=true
   scoreteam2+=1

  -- check goal2
  elseif isinside(
     puck.x,
     puck.y,
     goal2x1,
     goal2y1,
     goal2x2,
     goal2y2) then
   celebratets=tick
   iscelebrategoal=true
   scoreteam1+=1
  end

  puck.spd*=4
  puck.spd=max(0,puck.spd*0.97)
 end

 -- catch puck
 if puck.player==nil then
  for player in all(players) do

   if player.fallencounter<=0 and
      player.state!=state_tackling and
      (distanceobjs(player,puck) <= puck.r+player.r or
      distanceobjs(player.stick,puck) <= puck.r+player.stick.r) then
    puck.player=player

    -- puck catcher becomes p1
    if player.team==1 then
     p1player=player
     if p1player.ai.tactic==ai_scorer then
      local ass=findplayerbytactic(players,ai_ass,p1player.team)
      p1player.ai.tactic,ass.ai.tactic=ass.ai.tactic,p1player.ai.tactic
     end
    end
    break
   end
  end
 end
end

function _draw()

 -- set camera position
 local camerax=0
 if puck.player==nil then
  camerax=clamp(puck.x-64,0,128)
 else
  camerax=clamp(puck.player.x-64,0,128)
 end
 camera(camerax,0)

 cls(0)

 palt(0,false)
 palt(11,true)

 -- draw ice
 rectfill(rinkx1,rinky1,rinkx2-1,rinky2,6)

 -- draw lines
 line(128,rinky1,128,rinky2,14) -- mid
 circ(128,68,32,14)
 circfill(128,68,1,14)

 line(rinkx1+rinkgoaloffx,rinky1,rinkx1+rinkgoaloffx,rinky2,14) -- goal 1
 circ(rinkx1+rinkgoaloffx,rinkgoaly,rinkgoalr,14)
 rectfill(rinkx1,rinky1,rinkx1+rinkgoaloffx-1,rinky2,6)

 line(rinkx2-rinkgoaloffx,rinky1,rinkx2-rinkgoaloffx,rinky2,14) -- goal 2
 circ(rinkx2-rinkgoaloffx,rinkgoaly,rinkgoalr,14)
 rectfill(rinkx2-rinkgoaloffx+1,rinky1,rinkx2-1,rinky2,6)

 -- draw spectators
 for i=0,31 do
  spr(43,i*8,0)
  spr(43,i*8,8)
 end
 for i=1,15 do
  spr(43,0,i*8)
  spr(43,248,i*8)
 end

 -- draw boards
 for i=3,28 do
  spr(16,i*8,8)
 end

 -- goal side boards
 line(8,32,8,103,7)
 line(247,32,247,103,7)

 -- rounded corners top
 
 sspr(96,32,16,24,8,8)
 sspr(112,32,16,24,232,8)

 -- draw front side of goals
 if iscelebrategoal then
  local offset=tick%28
  if offset < 7 then
   offset=1
  elseif offset < 14 then
   offset=2
  elseif offset < 21 then
   offset=3
  else
   offset=4
  end
  spr(27+offset,rinkx1+rinkgoaloffx-8+1,rinky1+rinkmidy)
  spr(27+offset,rinkx2-rinkgoaloffx,rinky1+rinkmidy,1,1,true)
 else
  spr(27,rinkx1+rinkgoaloffx-8+1,rinky1+rinkmidy)
  spr(27,rinkx2-rinkgoaloffx,rinky1+rinkmidy,1,1,true)
 end

 -- draw players
 local playersinzorder=sortbyy(copy(players))

 for player in all(playersinzorder) do

  -- set y offset
  local offy=-7

  -- set x offset
  local offx=-1
  if player.flipped then
   offx=-5
  end

  -- draw p1 selection
  if player==p1player then
   circ(
    player.x,
    player.y,
    5,
    15)
  end

  -- set sprite
  local s=player.team
  if player.isshooting==true then
   s+=16
  elseif player.fallencounter>0 then
   s+=64
   offy+=1
  elseif player.spd>1 then
   s+=16
  elseif player.spd>0.6 then
   if tick%24<12 then
    s+=32
   else
    s+=48
   end
  end

  -- blink stick if shooting max spd
  if player.isshooting and
    player.shootingspd==player.shootingspdmax and
    tick%8<4 then
   pal(4,9,0)
  end

  -- draw player
  spr(
    s,
    player.x+offx,
    player.y+offy,
    1,1,
    player.flipped)

  -- reset blink
  pal(4,4,0)
 end

 -- draw backside of goals
 if iscelebrategoal then
  local offset=tick%28
  if offset < 7 then
   offset=1
  elseif offset < 14 then
   offset=2
  elseif offset < 21 then
   offset=3
  else
   offset=4
  end
  spr(11+offset,rinkx1+rinkgoaloffx-8+1,rinky1+rinkmidy-8)
  spr(11+offset,rinkx2-rinkgoaloffx,rinky1+rinkmidy-8,1,1,true)
 else
  spr(11,rinkx1+rinkgoaloffx-8+1,rinky1+rinkmidy-8)
  spr(11,rinkx2-rinkgoaloffx,rinky1+rinkmidy-8,1,1,true)
 end

 -- draw puck
 if puck.player != nil then
  spr(0,puck.x,puck.y-1)
 else
  spr(0,puck.x,puck.y)
 end

 -- rounded corners bottom
 sspr(96,56,16,24,8,104)
 sspr(112,56,16,24,232,104)

 -- draw closest spectators
 for i=3,28 do
  spr(59+i%2,i*8,114)
 end

 -- draw plexi
 for i=1,30 do
  spr(43,i*8,120)
 end

 -- draw gui
 local prompthalfw=32
 rectfill(
   camerax+64-prompthalfw,
   0,
   camerax+64+prompthalfw,
   9,
   0)
 rect(
   camerax+64-prompthalfw,
   -1,
   camerax+64+prompthalfw,
   9,
   5)
 
 print(scoreteam1..'  '..ticktotimestr(hockeytick)..'  '..scoreteam2,
   camerax+40,
   1,
   9)

 -- debug draw
 if isdebug then
  for static in all(playerstatics) do
   rect(static.x,static.y,static.x+static.w,static.y+static.h,4)
  end

  for static in all(puckstatics) do
   rect(static.x,static.y,static.x+static.w,static.y+static.h,5)
  end

  for player in all(playersinzorder) do
   circ(player.x,player.y,player.r,3)
   circ(player.stick.x,player.stick.y,player.stick.r,11)
   rect(player.x,player.y,player.x+player.w,player.y+player.h,12)
   print(player.ai.tactic, player.x-3, player.y-12, 2)
  end

  for c in all(corners) do
   rect(c[1],c[2],c[3],c[4],12)
   circ(c[5],c[6],cornerr,10)
  end
 end

end

__gfx__
11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77772bbb77772bbb77772bbb77772bbb77772
bbbbbbbbbb88bbbbbb77bbbbbbddbbbbbb33bbbbbb55bbbbbb11bbbbbb00bbbbbb22bbbbbb11bbbbbb00bbbbb2767672b2767672b2767672b2767672b27eeee2
bbbbbbbbbb8fbbbbbb7fbbbbbbdfbbbbbb3fbbbbbb5fbbbbbb1fbbbbbb0fbbbbbb2fbbbbbb1fbbbbbb0fbbbb276776722767767227677672276776722eeeeee2
bbbbbbbbbaa8bbbbb557bbbbb333bbbbb773bbbbb888bbbbbcc1bbbbbaa0bbbbb772bbbbb99abbbbbcc3bbbb26767772267677e8267677728e7677722eeeeee2
bbbbbbbbb8848bbbb7747bbbb334dbbbb3343bbbb8848bbbb1141bbbb0040bbbb2242bbbbaa4abbbb3343bbb2767767227677ee8276776728ee7767227eeee72
bbbbbbbbb8884bbbb0004bbbb2224bbbb1114bbbb0004bbbb1114bbbb0004bbbbddd4bbbb1114bbbb0004bbb2677777226788ee8267887728ee8277226722772
bbbbbbbbb8b8b4bbb5b5b4bbb3b3b4bbb3b3b4bbb5b5b4bbb1b1b4bbb0b0b4bbb2b2b4bbbdbdb4bbb3b3b4bb2776767227728ee8277886728ee8267227722672
bbbbbbbbbababb44b7b7bb44bdbdbb44b7b7bb44b8b8bb44bcbcbb44bababb44b7b7bb44bababb44bcbcbb442767777227677ee827eeee728ee7777227677772
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb26777672267776e82eeeeee22e77767226777672
bbbbbbbb4b88bbbb4b77bbbb4bddbbbb4b33bbbb4b55bbbb4b11bbbb4b00bbbb4b22bbbb4b11bbbb4b00bbbb27767672277676722eeeeee22776767227767672
bbbbbbbb4b8fbbbb4b7fbbbb4bdfbbbb4b3fbbbb4b5fbbbb4b1fbbbb4b0fbbbb4b2fbbbb4b1fbbbb4b0fbbbb276777722767777227eee7722767777227677772
67777777b4a8bbbbb457bbbbb433bbbbb473bbbbb488bbbbb4c1bbbbb4a0bbbbb472bbbbb49abbbbb4c3bbbb2677676226776762267767622677676226776762
67777777b848bbbbb747bbbbb343bbbbb343bbbbb848bbbbb141bbbbb040bbbbb242bbbbba4abbbbb343bbbb2776767227767672277676722776767227767672
67777777b884bbbbb004bbbbb224bbbbb114bbbbb004bbbbb114bbbbb004bbbbbdd4bbbbb114bbbbb004bbbbb2676762b2676762b2676762b2676762b2676762
67777777b8b8bbbbb5b5bbbbb3b3bbbbb3b3bbbbb5b5bbbbb1b1bbbbb0b0bbbbb2b2bbbbbdbdbbbbb3b3bbbbbb222222bb222222bb222222bb222222bb222222
ddddddddbababbbbb7b7bbbbbdbdbbbbb7b7bbbbb8b8bbbbbcbcbbbbbababbbbb7b7bbbbbababbbbbcbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddbbddbbddbbddbbddbddb2b0000000000000000
00000000bb88bbbbbb77bbbbbbddbbbbbb33bbbbbb55bbbbbb11bbbbbb00bbbbbb22bbbbbb11bbbbbb00bbbbddbbddbbddbbddbbddbddb2b0000000000000000
00000000bb8fbbbbbb7fbbbbbbdfbbbbbb3fbbbbbb5fbbbbbb1fbbbbbb0fbbbbbb2fbbbbbb1fbbbbbb0fbbbb5552222555522225555222b50000000000000000
00000000baa8bbbbb557bbbbb333bbbbb773bbbbb888bbbbbcc1bbbbbaa0bbbbb772bbbbb99abbbbbcc3bbbb5552222555dd2225555222b50000000000000000
00000000b8848bbbb7747bbbb334dbbbb3343bbbb8848bbbb1141bbbb0040bbbb2242bbbbaa4abbbb3343bbbbbddbbddbbddbbddbbddbbdd0000000000000000
00000000b8884bbbb0004bbbb2224bbbb1114bbbb0004bbbb1114bbbb0004bbbbddd4bbbb1114bbbb0004bbbbbddbbddb1111bddbbddbbdd0000000000000000
00000000a8b8b4bb75b5b4bbd3b3b4bb73b3b4bb85b5b4bbc1b1b4bba0b0b4bb72b2b4bbadbdb4bbc3b3b4bb5111155551111555511115550000000000000000
00000000bbbabb44bbb7bb44bbbdbb44bbb7bb44bbb8bb44bbbcbb44bbbabb44bbb7bb44bbbabb44bbbcbb445111155551111555511115550000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000bb88bbbbbb77bbbbbbddbbbbbb33bbbbbb55bbbbbb11bbbbbb00bbbbbb22bbbbbb11bbbbbb00bbbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000bb8fbbbbbb7fbbbbbbdfbbbbbb3fbbbbbb5fbbbbbb1fbbbbbb0fbbbbbb2fbbbbbb1fbbbbbb0fbbbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000baa8bbbbb557bbbbb333bbbbb773bbbbb888bbbbbcc1bbbbbaa0bbbbb772bbbbb99abbbbbcc3bbbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000b8848bbbb7747bbbb334dbbbb3343bbbb8848bbbb1141bbbb0040bbbb2242bbbbaa4abbbb3343bbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000b8884bbbb0004bbbb2224bbbb1114bbbb0004bbbb1114bbbb0004bbbbddd4bbbb1114bbbb0004bbbbbbbbbb7bbbbbbbb000000000000000000000000
00000000b8a8b4bbb575b4bbb3d3b4bbb373b4bbb585b4bbb1c1b4bbb0a0b4bbb272b4bbbdadb4bbb3c3b4bbbbbbbbb7bbbbbbbb000000000000000000000000
00000000babbbb44b7bbbb44bdbbbb44b7bbbb44b8bbbb44bcbbbb44babbbb44b7bbbb44babbbb44bcbbbb447777777777777777000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000dd00dd00dd00dd00dd00dd00dd00dd00
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000dd00dd00dd00dd00dd00dd00dd00dd00
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000055522225555222255552222555522225
00000000bbbb88bbbbbb77bbbbbbddbbbbbb33bbbbbb55bbbbbb11bbbbbb00bbbbbb22bbbbbb11bbbbbb00bb0000000055522225555277776777222555522225
00000000bb888fb4bb077fb4bb23dfb4bb133fb4bb085fb4bb111fb4bb000fb4bbd22fb4bb1a1fb4bb030fb40000000000dd00dd067777776777777000dd00dd
00000000a888a88475075774d3233dd47313733485088884c111c114a000a00472d27224ad1a9aa4c303c3340000000000dd00d7767777776777777670dd00dd
00000000bbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44b0000000051111577767777776777777677111555
00000000bbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbbbbb44bbb00000000511116777677dddddddd777677711dd5
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd1176777dddbbbbbbbbddd677760dd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd17767ddbbbbbbbbbbbbbbdd7767220
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556776dbbbbbbbbbbbbbbbbbbd767725
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055677dbbbbbbbbbbbbbbbbbbbbd67725
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000767dbbbbbbbbbbbbbbbbbbbbbbd7760
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000076dbbbbbbbbbbbbbbbbbbbbbbbbd760
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057dbbbbbbbbbbbbbbbbbbbbbbbbbbd65
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077dbbbbbbbbbbbbbbbbbbbbbbbbbbd67
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007dbbbbbbbbbbbbbbbbbbbbbbbbbbbbd7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007dbbbbbbbbbbbbbbbbbbbbbbbbbbbbd7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbbbbbbbbbbbbbbbbbbbbbbbbbbbdd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007bbb7bbbbbbbbbbbbbbbbbbbbbbbbdd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057bbb7bbbbbbbbbbbbbbbbbbb7bbbb55
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000057bbb7bbbbbbbbbbbbbbbbbbb7bbb755
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd7bb7bbbbbbbbbbbbbbbbbbb7bbdd00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd7bb7bbbbbbbbbbbbbbbbbbb7bbdd00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005557b7bbbbbbbbb7bbbbbbbbb7bb2225
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005557b7bbbbbbbbb7bbbbbbbbb7b72225
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd77bbbbbbbbb7bbbbbbbbb7dd00dd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd07bbbbbbbbb7bbbbbbbbb7dd00dd
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005111107bbbbbbbb7bbbbbbbb71111555
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005111100777bbbbb7bbbbbb7771111555
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00dd00dd77ddb7dd77dd00dd00dd00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00dd00dd00dd77dd00dd00dd00dd00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055522225555222255552222555522225
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055522225555222255552222555522225
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00dd00dd00dd00dd00dd00dd00dd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00dd00dd00dd00dd00dd00dd00dd
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111555511115555111155551111555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051111555511115555111155551111555
