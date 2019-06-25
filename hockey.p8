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
 -- for player in all(players) do
 --  if player != p1player and
 --     player.team==p1player.team then

 --   if puck.player==p1player then
 --    player.ai.targetposx=200
 --    player.ai.targetposy=64
 --   elseif puck.player==nil then
 --    player.ai.targetposx=puck.x
 --    player.ai.targetposy=puck.y
 --   end

 --   local a=atan2(
 --     player.ai.targetposx-player.x,
 --     player.ai.targetposy-player.y)
 --   player.a=a
 --   player.spd=1
 --   if distance(player.ai.targetposx,
 --      player.ai.targetposy,
 --      player.x,
 --      player.y) < 5 then
 --    player.spd=0
 --   end
 --  end
 -- end

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
   puck.a=puck.player.a
   puck.player.isshooting=false
   puck.player.shootingspd=0

   puck.player.state=state_idle
   puck.player=nil

  -- pass
  elseif puck.player.state==state_do_pass then
   puck.spd=4.5
   puck.a=puck.player.a

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
 palt(0,false)
 palt(11,true)
 sspr(96,32,16,24,8,8)
 sspr(112,32,16,24,232,8)
 palt(11,false)
 palt(0,true)

 -- set ice color to transparent
 palt(0, false)
 palt(6, true)

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

 -- reset sprite ice color transparency
 palt()

 -- rounded corners bottom
 palt(0,false)
 palt(11,true)
 sspr(96,56,16,24,8,104)
 sspr(112,56,16,24,232,104)
 palt(11,false)
 palt(0,true)

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
   rect(c[1],c[2],c[3],c[4],11)
   circ(c[5],c[6],cornerr,10)
  end
 end

end

__gfx__
11666666666666666666666666666666666666666666666666666666666666666666666666666666666666666667777266677772666777726667777266677772
66666666668866666677666666dd66666633666666556666661166666600666666226666661166666600666662767672627676726276767262767672627eeee2
66666666668f6666667f666666df6666663f6666665f6666661f6666660f6666662f6666661f6666660f6666276776722767767227677672276776722eeeeee2
666666666aa86666655766666333666667736666688866666cc166666aa0666667726666699a66666cc3666626767772267677e8267677728e7677722eeeeee2
6666666668848666677476666334d66663343666688486666114166660040666622426666aa4a666633436662767767227677ee8276776728ee7767227eeee72
66666666688846666000466662224666611146666000466661114666600046666ddd466661114666600046662677777226788ee8267887728ee8277226722772
6666666668686466656564666363646663636466656564666161646660606466626264666d6d6466636364662776767227728ee8277886728ee8267227722672
666666666a6a6644676766446d6d664467676644686866446c6c66446a6a6644676766446a6a66446c6c66442767777227677ee827eeee728ee7777227677772
000000006666666666666666666666666666666666666666666666666666666666666666666666666666666626777672267776e82eeeeee22e77767226777672
00000000468866664677666646dd66664633666646556666461166664600666646226666461166664600666627767672277676722eeeeee22776767227767672
00000000468f6666467f666646df6666463f6666465f6666461f6666460f6666462f6666461f6666460f6666276777722767777227eee7722767777227677772
6777777764a866666457666664336666647366666488666664c1666664a0666664726666649a666664c366662677676226776762267767622677676226776762
6777777768486666674766666343666663436666684866666141666660406666624266666a4a6666634366662776767227767672277676722776767227767672
67777777688466666004666662246666611466666004666661146666600466666dd4666661146666600466666267676262676762626767626267676262676762
6777777768686666656566666363666663636666656566666161666660606666626266666d6d6666636366666622222266222222662222226622222266222222
dddddddd6a6a6666676766666d6d666667676666686866666c6c66666a6a6666676766666a6a66666c6c66666666666666666666666666666666666666666666
0000000066666666666666666666666666666666666666666666666666666666666666666666666666666666dd00dd00dd00dd00dd0dd0200000000000000000
00000000668866666677666666dd666666336666665566666611666666006666662266666611666666006666dd00dd00dd00dd00dd0dd0200000000000000000
00000000668f6666667f666666df6666663f6666665f6666661f6666660f6666662f6666661f6666660f66665552222555522225555222050000000000000000
000000006aa86666655766666333666667736666688866666cc166666aa0666667726666699a66666cc366665552222555dd2225555222050000000000000000
0000000068848666677476666334d66663343666688486666114166660040666622426666aa4a6666334366600dd00dd00dd00dd00dd00dd0000000000000000
00000000688846666000466662224666611146666000466661114666600046666ddd4666611146666000466600dd00dd011110dd00dd00dd0000000000000000
00000000a868646675656466d36364667363646685656466c1616466a060646672626466ad6d6466c36364665111155551111555511115550000000000000000
00000000666a664466676644666d66446667664466686644666c6644666a664466676644666a6644666c66445111155551111555511115550000000000000000
00000000666666666666666666666666666666666666666666666666666666666666666666666666666666660000000700000000000000000000000000000000
00000000668866666677666666dd6666663366666655666666116666660066666622666666116666660066660000000700000000000000000000000000000000
00000000668f6666667f666666df6666663f6666665f6666661f6666660f6666662f6666661f6666660f66660000000700000000000000000000000000000000
000000006aa86666655766666333666667736666688866666cc166666aa0666667726666699a66666cc366660000000700000000000000000000000000000000
0000000068848666677476666334d66663343666688486666114166660040666622426666aa4a666633436660000000700000000000000000000000000000000
00000000688846666000466662224666611146666000466661114666600046666ddd466661114666600046660000000700000000000000000000000000000000
0000000068a864666575646663d36466637364666585646661c1646660a06466627264666dad646663c364660000000700000000000000000000000000000000
000000006a666644676666446d66664467666644686666446c6666446a666644676666446a6666446c6666447777777777777777000000000000000000000000
000000006666666666666666666666666666666666666666666666666666666666666666666666666666666600000000dd00dd00dd00dd00dd00dd00dd00dd00
000000006666666666666666666666666666666666666666666666666666666666666666666666666666666600000000dd00dd00dd00dd00dd00dd00dd00dd00
00000000666666666666666666666666666666666666666666666666666666666666666666666666666666660000000055522225555222255552222555522225
0000000066668866666677666666dd66666633666666556666661166666600666666226666661166666600660000000055522225555277776777222555522225
0000000066888f6466077f646623df6466133f6466085f6466111f6466000f6466d22f64661a1f6466030f640000000000dd00dd067777776777777000dd00dd
00000000a888a88475075774d3233dd47313733485088884c111c114a000a00472d27224ad1a9aa4c303c3340000000000dd00d7767777776777777670dd00dd
00000000666664466666644666666446666664466666644666666446666664466666644666666446666664460000000051111577767777776777777677111555
000000006664466666644666666446666664466666644666666446666664466666644666666446666664466600000000511116777677dddddddd777677711dd5
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
