pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- agility (v1)
-- by ironchest games

cartdata('ironchestgames_agility_v1')

debugdraw=false
-- debugdraw=true

maxint=32767

-- printh('debug started','debug',true)
-- function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
--  local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
--  local result=tostr(_s1)
--  for s in all(ss) do
--   result=result..', '..tostr(s)
--  end
--  printh(result,'debug',false)
-- end

-- _music=music
-- music=function (a,b,c)
--  debug('music',a,b,c)
--  _music(a,b,c)
-- end

ismusicplaying=false
function playmusic(_startpattern)
 if ismusicplaying == false then
  -- debug('play pattern', _startpattern)
  ismusicplaying=true
  music(_startpattern)
 end
end

function stopmusic()
 -- debug('stopmusic')
 ismusicplaying=false
 music(-1,0)
end

function ticktotimestr(tick)
 local d=flr(tick*1/60*100)
 local s=flr(tick/60)
 local m=tostr(flr(s/60))
 d=tostr(d%100)
 s=tostr(s%60)
 if #m<2 then
  m='0'..m
 end
 if #s<2 then
  s='0'..s
 end
 if #d<2 then
  d='0'..d
 end

 return m..':'..s..'.'..d
end

function copy(t)
 local result={}
 for key,value in pairs(t) do
  result[key]=value
 end
 return result
end

function concat(a1,a2)
 local result={}
 for value in all(a1) do
  add(result,value)
 end
 for value in all(a2) do
  add(result,value)
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
 return sqrt((x2-x1)^2+(y2-y1)^2)
end

function getangle(x1,y1,x2,y2)
 return atan2(x2-x1,y2-y1)
end

function getnormveccomps(angle)
 return cos(angle),sin(angle)
end

function globaltolocal(x,y,lx,ly,la)
 local a=getangle(lx,ly,x,y)-la
 local d=distance(x,y,lx,ly)
 local xcomp,ycomp=getnormveccomps(a)
 xcomp*=d
 ycomp*=d
 return xcomp,ycomp
end

function rotatepoint(x,y,a,originx,originy)
 local dx=x-originx
 local dy=y-originy
 local _x=dx*cos(a)-dy*sin(a)
 local _y=dx*sin(a)+dy*cos(a)
 local resultx=_x+originx
 local resulty=_y+originy
 return resultx,resulty
end

function initrotatedrect(_rect,a,originx,originy)

 -- init drawing points
 local xw=_rect.x+_rect.w
 local yh=_rect.y+_rect.h
 local x1,y1=rotatepoint(_rect.x,_rect.y,a,0,0)
 local x2,y2=rotatepoint(xw,_rect.y,a,0,0)
 local x3,y3=rotatepoint(xw,yh,a,0,0)
 local x4,y4=rotatepoint(_rect.x,yh,a,0,0)
 _rect.x1=x1+originx
 _rect.y1=y1+originy
 _rect.x2=x2+originx
 _rect.y2=y2+originy
 _rect.x3=x3+originx
 _rect.y3=y3+originy
 _rect.x4=x4+originx
 _rect.y4=y4+originy

 -- save the aabb, angle and origin for collision detection
 _rect.aabb={ -- note: coords in local space
  x=_rect.x,
  y=_rect.y,
  w=_rect.w,
  h=_rect.h,
 }
 _rect.a=a
 _rect.x=originx
 _rect.y=originy

 return _rect
end

function isinsideaabb(x,y,aabb)
 return x>aabb.x and
        x<aabb.x+aabb.w and
        y>aabb.y and
        y<aabb.y+aabb.h
end

function isinsiderotatedrect(x,y,_rect)
 local rotx,roty=globaltolocal(x,y,_rect.x,_rect.y,_rect.a)
 return isinsideaabb(rotx,roty,_rect.aabb)
end

function newphysobj(x,y,a)
 return {
  x=x,
  y=y,
  a=a,
  spd=0,
  targetx=x,
  targety=y,
  isflipped=false,
 }
end

state_idle=0
state_follow=1
state_totarget=2
state_clearing=3

state_running=10
state_sending=11
state_disqualified=12
state_coursecleared=13

function newdog(conf,x,y)
 local d=newphysobj(x,y,0)

 d.attentioncount=0
 d.state=state_idle
 d.targetentry=nil

 d.id=conf.id

 d.attentionr=conf.attentionr
 d.runspd=conf.runspd
 d.sendrange=conf.sendrange
 d.sendspd=conf.sendspd
 d.name=conf.name
 d.sprstart=conf.sprstart

 d.exclamationcounter=0
 d.questioncounter=0

 return d
end

function newhandler(x,y)
 local h=newphysobj(x,y,0)
 h.isflipped=true
 h.state=state_idle
 h.handlingx=0 -- note: additional pos for sending
 h.handlingy=0
 h.iscalling=false
 return h
end

-- obstacle types
obstacle_pole=0
obstacle_bar=1
obstacle_slalom=2
obstacle_tunnel=3

function initdisqs(disqs,x,y,a)

 -- rotate and place disqualifiers
 local xcomp,ycomp=getnormveccomps(a)

 for disq in all(disqs) do

  if disq.t==circ then
   disq.x=disq.x*xcomp+x
   disq.y=disq.y*ycomp+y

  elseif disq.t==rect then
   disq=initrotatedrect(disq,a,x,y)
  end
 end

 return disqs
end

function newjump(x,y,a)
 
 local halflen=6
 local poleradius=2

 -- disqualifiers
 local _disqs={ -- note: these are configs
  {
   t=circ,
   x=halflen,
   y=halflen,
   r=poleradius,
   obstacle=obstacle_pole,
  },
  {
   t=circ,
   x=-halflen,
   y=-halflen,
   r=poleradius,
   obstacle=obstacle_pole,
  },
  {
   t=rect,
   x=-halflen,
   y=-2,
   w=halflen*2,
   h=4,
   obstacle=obstacle_bar,
  }
 }

 -- init disqs
 _disqs=initdisqs(_disqs,x,y,a)

 -- init handler send area
 local _sendarea=initrotatedrect({
  t=rect,
  x=-18,
  y=-12,
  w=36,
  h=25,
  obstacle=obstacle_bar,
 },a,x,y)

 -- init entry
 local _entry=initrotatedrect({
  t=rect,
  x=-halflen,
  y=2,
  w=halflen*2,
  h=10,
  obstacle=obstacle_bar,
  arrowx=x,
  arrowy=y,
  nrs='',
 },a,x,y)

 -- init misc/props for extra graphics
 local _props={
  {
   f=line,
   x=_disqs[1].x,
   y=_disqs[1].y,
   x1=_disqs[1].x,
   y1=_disqs[1].y-2,
   x2=_disqs[2].x,
   y2=_disqs[2].y-2,
   col=7,
   disq=_disqs[3],
  },
 }

 return _disqs,_entry,_sendarea,_props
end

function newslalom(x,y,a)

 -- disqualifiers
 local _disqs={ -- note: these are configs
  {
   t=rect,
   x=0,
   y=-2,
   w=8*4,
   h=4,
   obstacle=obstacle_slalom,
  },
 }

 -- init disqs
 _disqs=initdisqs(_disqs,x,y,a)

 -- init handler send area
 local _sendarea=initrotatedrect({
  t=rect,
  x=-12,
  y=-10,
  w=18,
  h=20,
  obstacle=obstacle_slalom,
 },a,x,y)

 -- init entry
 local _entry=initrotatedrect({
  t=rect,
  x=-5,
  y=-7,
  w=8,
  h=14,
  obstacle=obstacle_slalom,
  arrowx=x,
  arrowy=y,
  nrs='',
 },a,x,y)

 -- init misc/props for extra graphics
 local _props={
  {
   f=line,
   x=x,
   y=y,
   x1=x,
   y1=y,
   x2=x+cos(a)*32,
   y2=y+sin(a)*32,
   col=6,
   disq=_disqs[1],
  },
 }

 for i=0,7 do
  local col=10
  local offy=0
  if i%2 == 1 then
   col=8
   offy=-1
  end
  local _x=x+cos(a)*(i*4)
  local _y=y+sin(a)*(i*4)
  add(_props,{
   f=line,
   x=_x,
   y=_y+offy,
   x1=_x,
   y1=_y,
   x2=_x,
   y2=_y-7,
   col=col,
   disq=_disqs[1],
  })
 end

 return _disqs,_entry,_sendarea,_props
end

function newtunnel(x,y,a)

 -- disqualifiers
 local _disqs={ -- note: these are configs
  {
   t=rect,
   x=0,
   y=-1,
   w=8*4+5,
   h=2,
   obstacle=obstacle_tunnel,
  }
 }

 -- init disqs
 _disqs=initdisqs(_disqs,x,y,a)

 -- init handler send area
 local _sendarea=initrotatedrect({
  t=rect,
  x=-20,
  y=-18,
  w=30,
  h=36,
  obstacle=obstacle_tunnel,
 },a,x,y)

 -- init entry
 local _entry=initrotatedrect({
  t=rect,
  x=-6,
  y=-4,
  w=8,
  h=8,
  obstacle=obstacle_tunnel,
  arrowx=x,
  arrowy=y,
  nrs='',
 },a,x,y)

 -- init misc/props for extra graphics
 local _props={}

 local inc=1
 local starti=0
 local endi=11
 local col1=10
 local col2=8
 local holeofffactor=1
 if a > 0 and a < 0.5 then
  inc=-1
  starti=11
  endi=0
  col1,col2=col2,col1
  holeofffactor=-1
 end
 for i=starti,endi,inc do
  local col=col1
  if i%2 == 1 then
   col=col2
  end
  local _x=x+cos(a)*(i*3)
  local _y=y+sin(a)*(i*3)

  add(_props,{
   f=circfill,
   x=_x,
   y=_y,
   r=3,
   col=col,
   disq=_disqs[1],
  })
  if i == endi then
   local _x=x+cos(a)*(i*3+2*holeofffactor)
   local _y=y+sin(a)*(i*3+2*holeofffactor)
   add(_props,{
    f=circfill,
    x=_x,
    y=_y,
    r=3,
    col=col,
    disq=_disqs[1],
   })
   add(_props,{
    f=circfill,
    x=_x,
    y=_y,
    r=2,
    col=2,
    disq='bogus', -- note: never blink hole
   })

  end
 end

 return _disqs,_entry,_sendarea,_props
end

function createcontact(disq,actor)
 return {
  obstacle=disq,
  actor=actor,
 }
end

function sethandlerskinpals(skin)
 if skin == 2 then
  pal(12,14,0)
  pal(1,5,0)
 elseif skin == 3 then
  pal(12,5,0)
  pal(1,4,0)
 elseif skin == 4 then
  pal(12,13,0)
  pal(1,6,0)
 end
 -- note: dont forget to reset it with pal()
end

-- app vars
scene=nil

-- game objects and arrays
handler=nil
dog=nil
obstaclecontact=nil

currentplayerconf=nil
playerconfs={
 {
  skin=1,
  dog=1,
  isplaying=true,
  coursedone=false,
 },
 {
  skin=2,
  dog=2,
  isplaying=false,
  coursedone=false,
 },
 {
  skin=3,
  dog=3,
  isplaying=false,
  coursedone=false,
 },
 {
  skin=4,
  dog=4,
  isplaying=false,
  coursedone=false,
 },
}

breeds={
 { -- bc
  sprstart=16,
  attentionr=34,
  runspd=0.5,
  sendrange=12,
  sendspd=1.38,
  name='blizz',
  id=1,
 },
 { -- corgi
  sprstart=32,
  attentionr=52,
  runspd=0.5,
  sendrange=10,
  sendspd=1.2,
  name='bonnie',
  id=2,
 },
 { -- jack russel
  sprstart=23,
  attentionr=38,
  runspd=0.82,
  sendrange=10,
  sendspd=1.0,
  name='jack',
  id=3,
 },
 { -- papillon
  sprstart=48,
  attentionr=80,
  runspd=0.55,
  sendrange=18,
  sendspd=1.1,
  name='pixie',
  id=5,
 },
 { -- belgian
  sprstart=55,
  attentionr=48,
  runspd=0.5,
  sendrange=14,
  sendspd=1.1,
  name='arjen',
  id=6,
 },
 { -- poodle
  sprstart=112,
  attentionr=32,
  runspd=0.6,
  sendrange=17,
  sendspd=1.2,
  name='pootch',
  id=7,
 },
 { -- sheltie
  sprstart=119,
  attentionr=52,
  runspd=0.6,
  sendrange=10,
  sendspd=1.2,
  name='sheela',
  id=8,
 },
 { -- collie (beginners dog, slower)
  sprstart=39,
  attentionr=52,
  runspd=0.5,
  sendrange=10,
  sendspd=0.9,
  name='lassie',
  id=4,
 },
}

-- load course data
function loadcourse(_courseid)
 local _obstacles={}
 local _handlerpos={}
 local _dogpos={}
 local _course={}

 local coltotype={
  [1]=newjump, -- dark blue
  [2]=newslalom, -- burgundy
  [3]=newtunnel, -- forest green
 }

 local courseidtoname={
  [1]='jumps 1',
  [2]='jumps 2',
  [3]='jumps 3',
  [4]='tight',
  [5]='around',
  [6]='faster',
  [7]='super g',
  [8]='the loop',
  [9]='hoola',
  [10]='needle',
  [11]='git gud',
  [12]='runner',
  [13]='the call',
  [14]='zig-zag',
  [15]='slalom',
 }

 -- to have lightblue angle pixel placed as entrance
 local typetoadditionalangle={
  [1]=0.25,
  [2]=0.5,
  [3]=0.5,
 }

 local offx=((_courseid-1)%8)*16
 local offy=8*4*2+flr((_courseid-1)/8)*16

 -- go through 16x15 pixels to create course
 for i=0,239 do
  local x=i%16
  local y=flr(i/16)
  local v=sget(offx+x,offy+y)
  if v != 0 and v <= #coltotype then
   local a=0
   local additionala=0
   local additionalx=0
   local additionaly=0

   -- get angle from surrounding pixels
   for _x=-1,1 do
    for _y=-1,1 do
     local _surv=sget(offx+x+_x,offy+y+_y)

     -- lightblue is main angle
     if _surv == 12 then
      a=getangle(0,0,_x,_y)

     -- lilac is angle fine-tuning
     -- (add an angle step per lilac around obstacle)
     elseif _surv == 13 then
      additionala+=0.125/7

     -- yellow fine-tunes x position
     elseif _surv == 10 then
      additionalx+=2

     -- light green fine-tunes y position
     elseif _surv == 11 then
      additionaly+=2
     end
    end
   end

   a+=additionala

   add(
     _obstacles,
     {
      f=coltotype[v],
      x*8+additionalx,
      y*8+additionaly,
      (a+typetoadditionalangle[v])%1,
     })

  -- skin color is handler starting position
  elseif v == 15 then
   _handlerpos={x*8,y*8}
   _dogpos={x*8-8,y*8}
  end
 end

 -- get obstacle order from lowest row
 -- going from top-left, first obstacle is 1 (dark blue)
 -- next obstacle is 2 (burgundy)
 -- same obstacle can be passed twice, just use same
 -- color again
 for x=0,15 do -- note: courses can only be of length 16
  local v=sget(offx+x,offy+15)

  -- stop at black
  if v == 0 then
   break

  else
   add(_course,v)
  end
 end

 return {
  handlerpos=_handlerpos,
  dogpos=_dogpos,
  course=_course,
  obstacles=_obstacles,
  coursenr=_courseid, -- note: used for times
  name=courseidtoname[_courseid],
 }
end

-- course structure 
--[[
  courses={
   {
    -- starting position
    handlerpos={64,100},

    -- starting position
    dogpos={74,110},

    -- obstacle configs (f=type, x, y, angle)
    obstacles={
     {f=newtunnel,22,105,0.3},
     {f=newtunnel,24,54,0.8},
     {f=newjump,64,64,0},
     {f=newslalom,75,32,0.1},
     {f=newjump,100,100,0.55},
     {f=newjump,24,14,0.03},
    },

    -- the obstacle order
    course={1,2,3,4,5,3,6},
   }
  }
--]]

courses={ -- note: the order is the difficulty order (not the order in the spritesheet)
 loadcourse(1),
 loadcourse(2),
 loadcourse(3),
 loadcourse(15),
 loadcourse(5),
 loadcourse(4),
 loadcourse(6),
 loadcourse(7),
 loadcourse(8),
 loadcourse(9),
 loadcourse(10),
 loadcourse(11),
 loadcourse(12),
 loadcourse(13),
 loadcourse(14),
}

currentcourseidx=1

coursesummary={} -- note: player standings in current course

physobjs=nil
obstacles=nil
disqs=nil
entries=nil
sendareas=nil
props=nil
course=nil
obstacleindex=1
coursecleared=false
timertick=0
gameover=false -- note: course done
attentionrdrawcount=0

exclamationtime=16

tick=0

_delays={}
function delay(f,ticks)
 add(
  _delays,
  {
   f=f,
   counter=ticks,
  })
end





--------------------





function gameinit()

 scene=gameupdate

 tick=0
 timertick=0
 attentionrdrawcount=0

 -- load courses
 local _courseconf=courses[currentcourseidx]

 -- init handler and dog
 handler=newhandler(
   _courseconf.handlerpos[1],
   _courseconf.handlerpos[2])

 dog=newdog(
   breeds[currentplayerconf.dog],
   _courseconf.dogpos[1],
   _courseconf.dogpos[2])

 -- init game over condition
 gameover=false
 obstaclecontact=nil

 -- init global arrays
 physobjs={handler,dog}
 disqs={}
 props={}
 entries={}
 sendareas={}
 course={}

 -- obstacle configs
 local _obstacles=courses[currentcourseidx].obstacles

 -- init obstacles
 for config in all(_obstacles) do

  -- get objects from obstacle config
  local _disqs,_entry,_sendarea,_props=config.f(
    config[1],
    config[2],
    config[3],
    config[4]) -- note: arg 4 not always used
  _sendarea.entry=_entry

  -- add to global arrays
  for disq in all(_disqs) do
   add(disqs,disq)
  end
  add(entries,_entry)
  add(sendareas,_sendarea)
  for prop in all(_props) do
   add(props,prop)
  end
 end

 -- init course (entry indeces)
 course=courses[currentcourseidx].course
 obstacleindex=1
 coursecleared=false

 local i=1
 for entryindex in all(course) do
  local entry=entries[entryindex]
  if #entry.nrs >= 1 then
   entry.nrs=entry.nrs..','..i
  else
   entry.nrs=''..i
  end
  i+=1
 end

 sfx(5)

 stopmusic()
end

function gameupdate()

 tick+=1

 -- wait a bit so btn from last scene prolly wont interfere
 if tick < 20 then
  return
 end

 -- is course cleared
 if gameover == true then
  if btnp(4) then

   -- all competing players are done
   if currentplayerconf == competingplayers[#competingplayers] then
    coursesummaryinit()

   -- ready next competing player
   else
    readyplayerinit()
   end
  end

  -- dont do anything else
  return
 end

 -- tick timer
 if obstacleindex > 1 then
  timertick+=1
 end

 -- tick timers
 dog.exclamationcounter=max(0,dog.exclamationcounter-1)
 dog.questioncounter=max(0,dog.questioncounter-1)
 attentionrdrawcount=max(0,attentionrdrawcount-1)

 -- reset handler
 local spd=0
 local previoushandlerstate=handler.state
 handler.state=state_idle

 -- aim handler and set speed
 local handlerxcomp,handlerycomp=0,0

 if btn(0) then
  handlerxcomp=-1
  handler.isflipped=true
 elseif btn(1) then
  handlerxcomp=1
  handler.isflipped=false
 end

 if btn(2) then
  handlerycomp=-1
 elseif btn(3) then
  handlerycomp=1
 end

 if btn(0) or btn(1) or btn(2) or btn(3) then
  spd=1
  handler.state=state_running

  -- start running sound
  if previoushandlerstate != state_running then
   sfx(7,2)
  end
 end

 handler.a=getangle(
   0,
   0,
   handlerxcomp,
   handlerycomp)
 handler.spd=spd

 -- set handling pos
 if handlerxcomp != 0 or
    handlerycomp != 0 then
  handler.handlingx=handler.x+cos(handler.a)*dog.sendrange
  handler.handlingy=handler.y+sin(handler.a)*dog.sendrange
 else
  handler.handlingx=handler.x
  handler.handlingy=handler.y
 end

 -- call to follow
 if btn(4) then
  handler.iscalling=true
  if distance(
     handler.x,
     handler.y,
     dog.x,
     dog.y) <= dog.attentionr and
    (dog.state == state_totarget or
     dog.state == state_follow or
     dog.state == state_idle) then
   dog.state=state_follow
  end
 else
  handler.iscalling=false
 end

 -- send to obstacle
 if btn(5) then
  handler.spd=0
  handler.state=state_sending

  -- only if dog is within attention radius and not doing anything else
  if distance(
      handler.x,
      handler.y,
      dog.x,
      dog.y) > dog.attentionr then

   attentionrdrawcount=60

  elseif dog.state != state_totarget and
     dog.state != state_clearing then
   local sendarea=nil

   attentionrdrawcount=0

   -- first test handling pos inside entries
   for _entry in all (entries) do
    if isinsiderotatedrect(
       handler.handlingx,
       handler.handlingy,
       _entry) then
     for _sendarea in all(sendareas) do
      if _sendarea.entry == _entry then
       sendarea=_sendarea
       break
      end
     end
     break
    end
   end

   -- then handling pos inside sendareas
   if not sendarea then
    for _sendarea in all(sendareas) do
     if isinsiderotatedrect(
          handler.handlingx,
          handler.handlingy,
          _sendarea) then
      sendarea=_sendarea
      break
     end
    end
   end

   -- last handler pos if no sendarea found
   if not sendarea then
    for _sendarea in all(sendareas) do
     if isinsiderotatedrect(
          handler.x,
          handler.y,
          _sendarea) then
      sendarea=_sendarea
      break
     end
    end
   end

   -- sendarea found, target it
   if sendarea then
    dog.state=state_totarget
    dog.targetx=sendarea.entry.x
    dog.targety=sendarea.entry.y
    dog.targetentry=sendarea.entry
    dog.spd=dog.sendspd
    dog.exclamationcounter=exclamationtime
    sfx(6)
    delay(function()
     sfx(6)
    end,5+flr(rnd(8)))
   end

   if dog.exclamationcounter <= 0 then
    dog.questioncounter=exclamationtime
   end
  end
 end

 -- dog ai
 if dog.state == state_idle then
  dog.spd=0

 elseif dog.state == state_follow then
  dog.targetx=handler.x
  dog.targety=handler.y
  if distance(
    dog.x,
    dog.y,
    dog.targetx,
    dog.targety) < 8 then
   dog.spd=0
  else
   dog.spd=dog.runspd
  end

 elseif dog.state == state_totarget then
  if isinsiderotatedrect(
      dog.x,
      dog.y,
      dog.targetentry) then

   dog.state=state_clearing

   -- init clearing positions
   local a=getangle(
     dog.x,
     dog.y,
     dog.targetentry.x,
     dog.targetentry.y)
   local d=distance(
     dog.x,
     dog.y,
     dog.targetentry.x,
     dog.targetentry.y)

   if dog.targetentry.obstacle == obstacle_bar then
    dog.clearingpos={
     {
      x=dog.targetentry.x,
      y=dog.targetentry.y,
     },
     {
      x=dog.targetentry.x-d*cos(a+0.5),
      y=dog.targetentry.y-d*sin(a+0.5),
     }
    }

   elseif dog.targetentry.obstacle == obstacle_slalom then
    dog.clearingpos={}

    -- slalom is always 8 pins
    for i=0,7 do
     -- create slalom position
     local _x=dog.targetentry.x+cos(dog.targetentry.a)*(i*4)
     local _y=dog.targetentry.y+sin(dog.targetentry.a)*(i*4)

     -- angle offset
     local aoff=-0.25 -- 90 deg out from slalom angle
     -- every other should be on opposite side
     if i%2 == 1 then
      aoff=-aoff
     end

     -- distance from slalom middle
     local _h=3
     if i == 7 then
      _h=7 -- note: get out of disq zone on last pos
      aoff=0.125
     end

     -- add the position
     add(
       dog.clearingpos,
       {
        x=_x+cos(dog.targetentry.a+aoff)*_h,
        y=_y+sin(dog.targetentry.a+aoff)*_h,
       })
    end

   elseif dog.targetentry.obstacle == obstacle_tunnel then
    dog.clearingpos={
     {
      x=dog.targetentry.x+cos(dog.targetentry.a)*(8*4+7),
      y=dog.targetentry.y+sin(dog.targetentry.a)*(8*4+7),
     },
    }
   end
  end

 elseif dog.state == state_clearing then
  if distance(
      dog.x,
      dog.y,
      dog.clearingpos[1].x,
      dog.clearingpos[1].y) < dog.spd+0.5 then
   del(
     dog.clearingpos,
     dog.clearingpos[1])
  else
   dog.targetx=dog.clearingpos[1].x
   dog.targety=dog.clearingpos[1].y
  end

  if #dog.clearingpos <= 0 then

   if dog.targetentry == entries[course[obstacleindex]] then
    obstacleindex+=1
    dog.targetentry=nil
    dog.clearingpos=nil
    dog.state=state_idle

    if obstacleindex > #course then
     coursecleared=true
    end

   else
    obstaclecontact=createcontact(nil,nil)
   end
  end
 end

 -- update dog angle
 if dog.state != state_idle then
  local a=getangle(
    dog.x,
    dog.y,
    dog.targetx,
    dog.targety)
  dog.a=a
 end

 -- move physobjs
 for physobj in all(physobjs) do
  local xcomp,ycomp=getnormveccomps(physobj.a)
  physobj.x+=xcomp*physobj.spd
  physobj.y+=ycomp*physobj.spd
 end

 -- set dog flipped
 dog.isflipped=false
 local xcomp,ycomp=getnormveccomps(dog.a)
 if xcomp < 0 then
  dog.isflipped=true
 end

 -- check for disqualification
 for disq in all(disqs) do

  -- check handler disqualify
  if disq.t == circ and 
     distance(
       handler.x,
       handler.y,
       disq.x,
       disq.y) < disq.r then
   obstaclecontact=createcontact(disq,handler)
   
  elseif disq.t == rect and
         isinsiderotatedrect(
            handler.x,
            handler.y,
            disq) then
   obstaclecontact=createcontact(disq,handler)
  end

  -- check dog disqualify
  if dog.state != state_clearing then
   if disq.t == circ and 
       distance(
         dog.x,
         dog.y,
         disq.x,
         disq.y) < disq.r then
    obstaclecontact=createcontact(disq,dog)
    
   elseif disq.t == rect and
          isinsiderotatedrect(
           dog.x,
           dog.y,
           disq) then
    obstaclecontact=createcontact(disq,dog)
   end
  end
 end

 -- stop running sound
 if handler.state != state_running then
  sfx(-2,2)
 end
 
 -- time's up
 if timertick >= 3600 then
  obstaclecontact=createcontact(nil,nil)
  obstaclecontact.timesup=true
 end

 -- set game over
 if obstaclecontact != nil then
  handler.state=state_disqualified
  dog.state=state_disqualified

  gameover=true

  add(coursesummary,{
   player=currentplayerconf,
   disqualified=true,
  })

  sfx(3)

 elseif coursecleared == true then
  handler.state=state_coursecleared
  dog.state=state_coursecleared

  gameover=true

  local obj={
   player=currentplayerconf,
   coursetime=timertick,
  }

  -- persist time and dog
  local currentcourseconf=courses[currentcourseidx]
  if dget(currentcourseconf.coursenr) == 0 or
     dget(currentcourseconf.coursenr) > timertick then
   dset(currentcourseconf.coursenr,timertick)
   local i=0
   while i <= #breeds do
    i+=1
    if breeds[i].id == dog.id then
     break
    end
   end
   dset(currentcourseconf.coursenr+24,i)
   obj.ishighscore=true
  end

  add(coursesummary,obj)

  playmusic(0)
 end

 -- game over cleanup
 if gameover then
  sfx(-2,2) -- stop running sound loop
  handler.iscalling=false
  currentplayerconf.coursedone=true
 end
 
end


function drawsign(s)
 rectfill(0,38,128,68,14)
 print(s,64-#s*2,45,7)
end

function gamedraw()

 -- offsets
 local handleroffx=-4
 local handleroffy=-7
 local dogoffx=-4
 local dogoffy=-7

 -- the field is green
 cls(3)

 -- draw call circle
 if handler.iscalling and
    distance(
      handler.x,
      handler.y,
      dog.x,
      dog.y) > dog.attentionr or
   attentionrdrawcount > 42 then
  color(7)
  if tick%10 > 5 then
   color(12)
  end
  circ(dog.x,dog.y,dog.attentionr)
 end

 -- draw handling dot
 if handler.state == state_sending and
    (handler.handlingx != handler.x or
    handler.handlingy != handler.y) then
  circ(handler.handlingx,handler.handlingy,0.5,11)
 end

 -- sort objects based on depth (y)
 local objs=concat(disqs,props)
 objs=concat(objs,physobjs)
 objs=sortbyy(objs)

 -- draw physobjs
 for obj in all(objs) do

  -- draw handler
  if obj==handler then

   sethandlerskinpals(currentplayerconf.skin)

   -- standing
   if handler.state==state_idle then
    spr(
      0,
      handler.x+handleroffx,
      handler.y+handleroffy,
      1,1,handler.isflipped)

   elseif handler.state==state_sending then
    spr(
      4,
      handler.x+handleroffx,
      handler.y+handleroffy,
      1,1,handler.isflipped)

   -- running
   elseif handler.state==state_running then
    spr(
      1+tick%18/6,
      handler.x+handleroffx,
      handler.y+handleroffy,
      1,1,handler.isflipped)

   -- course cleared
   elseif handler.state==state_coursecleared then
    handler.isflipped=false
    if tick%48 > 23 then
     handler.isflipped=true
    end
    spr(
      7+tick%24/12,
      handler.x+handleroffx,
      handler.y+handleroffy,
      1,1,handler.isflipped)

   -- disqualified
   elseif handler.state==state_disqualified then
    spr(
      5+tick%24/12,
      handler.x+handleroffx,
      handler.y+handleroffy,
      1,1,handler.isflipped)
   end

   -- reset skin pal calls
   pal()

  -- draw dog
  elseif obj==dog then

   -- clearing obstacles
   if dog.state == state_clearing then
   
    if dog.targetentry.obstacle == obstacle_bar then
     spr(
       dog.sprstart+3,
       dog.x+dogoffx,
       dog.y+dogoffy,
       1,1,dog.isflipped)

    elseif dog.targetentry.obstacle == obstacle_tunnel then
     local a=dog.targetentry.a
     if a > 0.125 and
        a < 0.375 then
      spr(
        31,
        dog.x+dogoffx+8,
        dog.y+dogoffy)
     else
      spr(
        30,
        dog.x+dogoffx,
        dog.y+dogoffy-4)
     end

    else -- running
     spr(
      dog.sprstart+1+tick%14/7,
      dog.x+dogoffx,
      dog.y+dogoffy,
      1,1,dog.isflipped)
    end

   -- celebrating :)
   elseif dog.state == state_disqualified or
          dog.state == state_coursecleared then

    spr(
      dog.sprstart+5+tick%14/7,
      dog.x+dogoffx,
      dog.y+dogoffy,
      1,1,dog.isflipped)

   -- running
   elseif dog.spd>0 then
    spr(
      dog.sprstart+1+tick%14/7,
      dog.x+dogoffx,
      dog.y+dogoffy,
      1,1,dog.isflipped)

   -- standing
   else
    spr(
      dog.sprstart,
      dog.x+dogoffx,
      dog.y+dogoffy,
      1,1,dog.isflipped)
   end

  -- draw obstacle jump pole
  elseif obj.obstacle == obstacle_pole then
   color(8)
   if obstaclecontact and
      obstaclecontact.obstacle == obj and
      tick%8 > 4 then
    color(14)
   end
   line(
     obj.x,
     obj.y,
     obj.x,
     obj.y-8)

  -- draw props
  else
   if obj.f == line then
    color(obj.col)
    if obstaclecontact and
      obstaclecontact.obstacle == obj.disq and
      tick%8 > 4 then
     color(14)
    end
    line(
      obj.x1,
      obj.y1,
      obj.x2,
      obj.y2)

   elseif obj.f == circfill then
    color(obj.col)
    if obstaclecontact and
      obstaclecontact.obstacle == obj.disq and
      tick%8 > 4 then
     color(14)
    end
    circfill(
      obj.x,
      obj.y,
      obj.r)
   end
  end
 end

 -- draw course numbers if not started
 if obstacleindex == 1 then

  for entry in all(entries) do
   print(
     entry.nrs,
     entry.x-cos(entry.a+0.25)*8,
     entry.y-sin(entry.a+0.25)*8-4,
     11)
  end

  -- blink nr 1 if first entry was something else
  if obstaclecontact and
     obstaclecontact.obstacle == nil then
   color(11)
   if tick%8 > 4 then
    color(14)
   end
   local firstentry=entries[
     courses[currentcourseidx].course[obstacleindex]]
   print(
     '1',
     firstentry.x-cos(firstentry.a+0.25)*8,
     firstentry.y-sin(firstentry.a+0.25)*8-4)
  end

 -- only draw marker on next entry if already started
 else
  local currententry=entries[course[obstacleindex]]
  color(11)
  if obstaclecontact and
    obstaclecontact.obstacle == nil and
    tick%8 > 4 then
   color(14)
  end

  if currententry then
   circ(
     currententry.x-cos(currententry.a+0.25)*5,
     currententry.y-sin(currententry.a+0.25)*5,
     1.5)
  end
 end

 -- draw handler calling
 if handler.iscalling then
  if tick%10 > 5 then
   spr(
    13,
    handler.x+handleroffx,
    handler.y+handleroffy-5,
    1,1,handler.isflipped)
  end
 end

 -- draw dog exclamation and question mark
 if dog.exclamationcounter > 0 then
  color(7)
  if tick%12 > 6 then
   color(10)
  end
  print(
    '!',
    dog.x-1,
    dog.y-12)
 elseif dog.questioncounter > 0 then
  color(9)
  if tick%12 > 6 then
   color(10)
  end
  print(
    '?',
    dog.x-1,
    dog.y-12)
 end

 -- draw gui bg
 rectfill(0,119,128,128,14)
 local textcol=7

 -- disqualified
 if handler.state == state_disqualified or
    dog.state == state_disqualified then
  rectfill(0,119,128,128,8)
  local s='disqualified'
  color(7)
  if tick%8 > 4 then
   color(14)
  end
  print(s,64-#s*2,121)

  textcol=14
 end

 -- dog name
 local s='p'..currentplayerconf.skin
 if not obstaclecontact then
  s=s..' with '..dog.name
 end
 print(s,3,121,textcol)

 -- draw timer
 local s=ticktotimestr(timertick)
 if obstaclecontact and
    obstaclecontact.timesup == true then
  color(7)
  if tick%8 > 4 then
   color(14)
  end
  print(s,126-#s*4,121)
  drawsign('time\'s up')
 else
  print(s,126-#s*4,121,textcol)
 end

 -- course cleared
 if coursecleared == true then
  drawsign('course cleared')
 end

 -- debug draw
 if debugdraw == true then

  local col=0

  for disq in all(disqs) do
   if disq.t == circ then
    circ(disq.x,disq.y,disq.r,14)
   elseif disq.t == rect then
    line(disq.x1,disq.y1,disq.x2,disq.y2,14)
    line(disq.x2,disq.y2,disq.x3,disq.y3,14)
    line(disq.x3,disq.y3,disq.x4,disq.y4,14)
    line(disq.x4,disq.y4,disq.x1,disq.y1,14)
   end
  end

  for entry in all(entries) do
   if entry.t == circ then
    circ(entry.x,entry.y,entry.r,10)
   elseif entry.t == rect then
    col=10
    if isinsiderotatedrect(handler.x,handler.y,entry) or
       isinsiderotatedrect(dog.x,dog.y,entry) then
     col=9
    end
    line(entry.x1,entry.y1,entry.x2,entry.y2,col)
    line(entry.x2,entry.y2,entry.x3,entry.y3,col)
    line(entry.x3,entry.y3,entry.x4,entry.y4,col)
    line(entry.x4,entry.y4,entry.x1,entry.y1,col)
   end
  end

  for sendarea in all(sendareas) do
   if sendarea.t == circ then
    circ(sendarea.x,sendarea.y,sendarea.r,11)
   elseif sendarea.t == rect then
    col=11
    if isinsiderotatedrect(handler.x,handler.y,sendarea) or
       isinsiderotatedrect(dog.x,dog.y,sendarea) then
     col=12
    end
    line(sendarea.x1,sendarea.y1,sendarea.x2,sendarea.y2,col)
    line(sendarea.x2,sendarea.y2,sendarea.x3,sendarea.y3,col)
    line(sendarea.x3,sendarea.y3,sendarea.x4,sendarea.y4,col)
    line(sendarea.x4,sendarea.y4,sendarea.x1,sendarea.y1,col)
   end
  end

  circ(handler.x,handler.y,1.5,10)

  circ(handler.handlingx,handler.handlingy,1,10)

  if dog.clearingpos then
   for pos in all(dog.clearingpos) do
    circ(pos.x,pos.y,2,10)
   end
  end

 end

end





--------------------





competingplayers={}
competingplayerstart=false

function readyplayerinit()
 scene=readyplayerupdate

 -- go to course selection if all players are done
 if competingplayers[#competingplayers].coursedone then
  courseselectioninit()
 end

 -- set current player
 for competingplayer in all(competingplayers) do
  if competingplayer.coursedone == false then
   currentplayerconf=competingplayer
   break
  end
 end

 blinkfast=true
 competingplayerstart=false

 tick=0

end

function readyplayerupdate()

 tick+=1

 if btnp(4) then
  delay(gameinit,30)
  competingplayerstart=true
 end
end

function readyplayerdraw()
 cls(14)

 -- title texts
 local s='course start'
 print(s,64-#s*2,10,7)
 s='player '..currentplayerconf.skin..' ready!'
 print(s,64-#s*2,24,7)

 -- press to start
 if competingplayerstart == true and
    blink() then
  color(14)
 else
  color(7)
 end
 s='press \x8e to start'
 print(s,64-#s*2,121)

 -- handler and dog bg
 rectfill(0,40,128,40+48,3)

 -- handler
 sethandlerskinpals(currentplayerconf.skin)
 spr(0,56,61)
 pal() -- reset handler skin pals

 -- dog
 spr(
   breeds[currentplayerconf.dog].sprstart,
   65,
   61,
   1,
   1,
   true,
   false)
end




--------------------




function coursesummaryinit()
 scene=coursesummaryupdate

 tick=0

 blinkfast=false

 -- set course times for disqualified to be able to sort it
 for obj in all(coursesummary) do
  if obj.disqualified then
   obj.coursetime=maxint
  end
 end

 -- sort players by course time
 for i=1,#coursesummary do
  local j=i
  while 
    j > 1 and
    coursesummary[j-1].coursetime >
      coursesummary[j].coursetime do
   coursesummary[j],coursesummary[j-1] =
     coursesummary[j-1],coursesummary[j]
   j=j-1
  end
 end

 -- only 1st will blink for highscore
 if #coursesummary >= 2 and
    coursesummary[1].ishighscore == true then
  for i=2, #coursesummary do
   coursesummary[i].ishighscore=false
  end
 end

 -- stopmusic()
 playmusic(0)
end

function coursesummaryupdate()
 
 tick+=1

 if btnp(4) then
  courseselectioninit()
  -- stopmusic()
  -- playmusic(0)
 end
end

function coursesummarydraw()

 cls(14)

 -- draw podium bg
 rectfill(0,64,128,128,3)

 -- draw title
 local s='course summary'
 print(s,64-#s*2,8,7)

 s=courses[currentcourseidx].name
 print(s,64-#s*2,16,7)
 
 -- draw all competing players results
 local i=0
 for obj in all(coursesummary) do
  local ps='p'..obj.player.skin..' '
  local s=ps..'disqualified'
  color(7)

  if not (obj.disqualified == true) then
   s=ps..ticktotimestr(obj.coursetime)
   if obj.ishighscore then
    blinkfast=true
    if blink() then
     color(15)
    end
   end
  end

  print(s,64-11*2,27+i*8)

  i+=1
 end

 -- draw podium
 local offy=80
 rectfill(64-8,offy+8,64+8,offy+24,2)
 print('1',64,offy+8+2,10)

 rectfill(48-8,offy+8+5,48+8,offy+24,2)
 print('2',48,offy+8+2+5,6)

 rectfill(80-8,offy+8+7,80+8,offy+24,2)
 print('3',80,offy+8+2+7,9)

 -- draw handlers and dogs on podium
 if coursesummary[1].disqualified != true then
  local flipped=false
  if tick%48 > 23 then
   flipped=true
  end
  sethandlerskinpals(coursesummary[1].player.skin)
  spr(7+tick%24/12,64,offy,1,1,flipped)
  pal()

  spr(
    breeds[coursesummary[1].player.dog].sprstart+5+tick%14/7,
    64-8,
    offy)
 end

 if coursesummary[2] and
    coursesummary[2].disqualified != true then
  sethandlerskinpals(coursesummary[2].player.skin)
  spr(0,48,offy+5)
  pal()

  spr(
    breeds[coursesummary[2].player.dog].sprstart+5+tick%14/7,
    48-8,
    offy+5)
 end

 if coursesummary[3] and
    coursesummary[3].disqualified != true then
  sethandlerskinpals(coursesummary[3].player.skin)
  spr(0,80+1,offy+7)
  pal()

  spr(
    breeds[coursesummary[3].player.dog].sprstart+5+tick%14/7,
    80+1-8,
    offy+7)
 end

 -- draw competing players not on the podium
 local xpos={10,28,90,108}
 local y=107
 for i=1,#coursesummary do
  local _result=coursesummary[i]
  if _result.disqualified or i == 4 then
   local _x=xpos[i]
   local _flipped=false
   local _dogxoff=-7
   if i >= 3 then
    _flipped=true
    _dogxoff=-_dogxoff
   end
   sethandlerskinpals(coursesummary[i].player.skin)
   spr(0,xpos[i],y,1,1,_flipped)
   pal()

   spr(
     breeds[coursesummary[i].player.dog].sprstart+5+tick%14/7,
     xpos[i]-_dogxoff,
     y,1,1,_flipped)
  end
 end

 -- if only one player, show no podium
 if #coursesummary == 1 then
  rectfill(0,64,128,128,14)
 end

end




--------------------





menux=1
menuy=1
playersetupdone=false
showinginstructions=false

function playersetupinit()
 scene=playersetupupdate
 playersetupdone=false
 showinginstructions=false
 tick=0
 menux=1
 menuy=1
 blinkfast=false
end

function playersetupupdate()

 tick+=1

 if playersetupdone == true then
  return
 end

 -- instructions are showing
 if showinginstructions then
  if btnp(5) then
   showinginstructions=false
   sfx(12)
  end
  return
 end

 -- show instructions
 if btnp(5) then
  showinginstructions=true
  sfx(8)
  return
 end

 -- make selection
 if btnp(4) then

  -- toggle players
  if menuy == 1 then
   playerconfs[menux].isplaying=not playerconfs[menux].isplaying
   sfx(9)

  -- selection player dogs
  elseif menuy == 2 then
   playerconfs[menux].dog+=1
   if playerconfs[menux].dog > #breeds then
    playerconfs[menux].dog=1
   end
   sfx(9)

  -- go to course selection
  elseif menuy == 3 then

   -- reset the competing players
   competingplayers={}

   -- ...but only if at least one player is selected
   for playerconf in all(playerconfs) do
    if playerconf.isplaying then
     blinkfast=true
     playersetupdone=true
     sfx(4)

     -- set competing players
     for playerconf in all(playerconfs) do
      if playerconf.isplaying then
       add(competingplayers,playerconf)
      end
     end

     delay(courseselectioninit,30)
     -- playmusic(0)
     return
    end
   end
  end
 end

 -- move selection
 if btnp(2) then
  menuy=mid(menuy-1,1,3)
  sfx(8)
 elseif btnp(3) then
  menuy=mid(menuy+1,1,3)
  sfx(8)
 elseif btnp(0) then
  menux=mid(menux-1,1,4)
  sfx(8)
 elseif btnp(1) then
  menux=mid(menux+1,1,4)
  sfx(8)
 end

end

blinkfast=false
function blink()
 if blinkfast == true then
  return tick%8 < 4
 end
 return tick%30 < 15
end

function playersetupdraw()

 cls(7)
 
 -- draw ironchest banner
 local s='ironchest games 2018'
 local x=32-#s/4-1
 local y=2
 fillp(0b0110100110010110)
 rectfill(0,0,128,8,0x67)
 fillp(0b1100001100111100)
 rectfill(x,0,128,8,0x67)
 fillp()

 rectfill(x-1,0,x+#s*4-1,8,6)
 print(s,x,y,7)

 -- draw game logo
 sspr(0,32,74,20,28,18)

 -- show instructions
 if showinginstructions then
  color(14)
  cursor(6,48)
  print('         instructions\n\n')
  print('\x8b\x91\x94\x83 - move, send-aim\n')
  print('      \x8e - call dog to')
  print('           follow you\n')
  print('      \x97 - send dog to')
  print('           clear obstacle')
  print('\x97 back',3,121,14)
  return
 end

 -- draw selection bg
 rectfill(0,46,128,116,3)

 -- init selection vars
 local offx=32
 local offy=62

 -- draw players and dogs
 local i=1
 for playerconf in all(playerconfs) do
  local _x=offx+(i-1)*16
  local _y=offy
  color(11)

  -- draw player number
  if playerconf.isplaying == false then
   color(1)
  end
  print('p'..i,offx+(i-1)*16+6,offy-9)

  -- player sprite
  if playerconf.isplaying == false then
   pal(12,1,0)
   pal(15,1,0)
  else
   sethandlerskinpals(playerconf.skin)
  end
  spr(0,_x+5,_y+5)
  pal()

  -- dog sprite
  _y+=16
  if playerconf.isplaying == false then
   pal(7,1,0)
   pal(4,1,0)
   pal(9,1,0)
   pal(5,1,0)
   pal(15,1,0)
   pal(6,1,0)
  end
  spr(breeds[playerconf.dog].sprstart,_x+5,_y+6)
  pal()

  i+=1
 end

 -- draw done button
 local donestr='done'
 print(donestr,58,offy+42,11)

 -- draw selection rect
 local x=offx+(menux-1)*16
 local y=offy+(menuy-1)*16
 local col=11
 if blink() then
  col=7
 end
 if menuy < 3 then
  rect(x,y,x+16,y+16,col)

  -- draw dog name
  if menuy == 2 then
   rect(x,y,x+16,y+5,3)
   local s=breeds[playerconfs[menux].dog].name
   print(s,x+9-#s*2,y,col)
  end

 else
  local _offy=offy+38
  rect(offx,_offy,offx+16*4,_offy+12,col)
  print(donestr,58,offy+42,col)
 end

 -- draw instructions text
 print('\x97 instructions',34,120,14)

end





--------------------




courseselectiondone=false
listoffy=0
courseblinktick=0
courseblinkindex=1

function courseselectioninit()
 scene=courseselectionupdate

 blinkfast=false
 courseselectiondone=false
end

function courseselectionupdate()

 tick+=1

 if courseselectiondone then
  return
 end

 -- go back
 if btnp(5) then
  playersetupinit()
  sfx(12)
 end

 -- start course
 if btnp(4) then
  courseselectiondone=true
  blinkfast=true
  sfx(4)
  stopmusic()

  -- reset playerconf
  for playerconf in all(playerconfs) do
   playerconf.coursedone=false
  end

  -- reset course summary
  coursesummary={}

  delay(readyplayerinit,30)
  return
 end

 -- select course
 if btnp(2) then
  currentcourseidx=mid(currentcourseidx-1,1,#courses)
  courseblinkindex=1
  sfx(8)
 elseif btnp(3) then
  currentcourseidx=mid(currentcourseidx+1,1,#courses)
  courseblinkindex=1
  sfx(8)
 end

 -- blink obstacle order
 courseblinktick+=1
 if courseblinktick > 30 then
  courseblinkindex+=1
  courseblinktick=0
  if courseblinkindex > #courses[currentcourseidx].course then
   courseblinkindex=1
  end
 end
end

function courseselectiondraw()
 cls(7)

 -- scene title
 rectfill(0,0,128,8,14)
 local s='course selection'
 print(s,64-#s*2,2,7)

 -- action text bg
 rectfill(0,119,128,128,14)

 -- back text
 print('\x97 back',3,121,7)

 -- start text
 print('\x8e start',93,121,7)

 -- calc list offset
 if currentcourseidx-1 < listoffy then
  listoffy=currentcourseidx-1
 end
 if currentcourseidx > 7+listoffy then
  listoffy=currentcourseidx-7
 end

 -- draw course list
 local offx=5
 local offy=21-listoffy*12

 for i=listoffy+1,listoffy+7 do  
  color(3)
  if i == currentcourseidx then
   color(11)
   if courseselectiondone and
      blink() then
    color(3)
   end
  end

  local _course=courses[i]

  local _y=offy+12*(i-1)
  local s=_course.name
  rectfill(
    offx,
    _y,
    offx+46,
    _y+8)
  print(
    i..'.',
    offx+2,
    _y+2,
    7)
  print(
    s,
    offx+30-#s*2,
    _y+2,
    7)
 end

 -- draw course list arrows
 if listoffy > 0 then
  spr(46,23,13)
 end
 if listoffy < #courses-7 then
  spr(46,23,102,1,1,false,true)
 end

 -- draw course map
 local offx=58
 local offy=21
 rectfill(offx,offy,offx+64,offy+64,3)

 -- draw course line
 local lastexitx=offx+courses[currentcourseidx].handlerpos[1]/2
 local lastexity=offy+courses[currentcourseidx].handlerpos[2]/2
 local obstacleindexpasses={0,0,0,0,0,0,0,0}
 local i=1

 for obstacleindex in all(courses[currentcourseidx].course) do
  local obstacleconf=courses[currentcourseidx].obstacles[obstacleindex]
  local _x=
    offx+
    obstacleconf[1]/2+
    obstacleindexpasses[obstacleindex]
  local _y=
    offy+
    obstacleconf[2]/2+
    obstacleindexpasses[obstacleindex]
  color(11)

  -- blink course order
  if i == courseblinkindex then
   color(7)
  end

  -- draw course line
  line(lastexitx,lastexity,_x,_y)

  -- save exits
  if obstacleconf.f == newjump then
   lastexitx=_x
   lastexity=_y

  elseif obstacleconf.f == newslalom or
         obstacleconf.f == newtunnel then
   lastexitx=_x+cos(obstacleconf[3])*18
   lastexity=_y+sin(obstacleconf[3])*18
  end

  obstacleindexpasses[obstacleindex]+=1

  i+=1
 end

 -- draw map obstacles
 for obstacleconf in all(courses[currentcourseidx].obstacles) do
  local _x=offx+obstacleconf[1]/2
  local _y=offy+obstacleconf[2]/2

  if obstacleconf.f == newjump then
   line(
     _x-2,
     _y-2,
     _x-2,
     _y+1,
     8)
   line(
     _x+2,
     _y-2,
     _x+2,
     _y+1,
     8)
   line(
     _x-2,
     _y,
     _x+2,
     _y,
     6)

  elseif obstacleconf.f == newslalom then
   local _a=obstacleconf[3]
   line(
    _x,
    _y,
    _x+cos(_a)*16,
    _y+sin(_a)*16,
    6)
   for i=0,6 do
    local _px=_x+cos(_a)*(i*3)
    local _py=_y+sin(_a)*(i*3)
    color(8)
    if i%2 == 1 then
     color(10)
    end
    line(
     _px,
     _py,
     _px,
     _py-3)
   end

  elseif obstacleconf.f == newtunnel then
   local _a=obstacleconf[3]
   for i=0,6 do
    local _px=_x+cos(_a)*(i*3)
    local _py=_y+sin(_a)*(i*3)
    color(8)
    if i%2 == 1 then
     color(10)
    end
    circfill(
     _px,
     _py,
     2)
   end
  end
 end

 -- draw player starting position
 spr(
   9,
   offx+courses[currentcourseidx].handlerpos[1]/2,
   offy+courses[currentcourseidx].handlerpos[2]/2)

 -- draw best time for current course
 local coursenr=courses[currentcourseidx].coursenr
 local besttime=dget(coursenr)
 local s='--:--.--'
 if besttime != 0 then
  local dogidx=dget(coursenr+24)
  s=ticktotimestr(besttime)..' ('..breeds[dogidx].name..')'
 end
 print('best time:',58,90,14)
 print(s,58,100,14)

end





--------------------




-- draw how the .p8.png cover should look
--[[
function _draw()
 cls(7)

 -- draw game logo
 sspr(0,32,74,20,28,18)

 -- draw selection bg
 rectfill(0,46,128,116,3)

 -- draw big handler and dog
 sspr(64,0,8,8,21,63,48,48)
 sspr(0,16,8,8,70,79,32,32,true,false)
end
--]]

function _init()
 playersetupinit()
 playmusic(0)
end

function _update60()

 -- update delayed calls
 for delayed in all(_delays) do
  delayed.counter-=1
  if delayed.counter <= 0 then
   delayed.f()
   del(_delays,delayed)
  end
 end

 -- scene handling
 if scene == gameupdate then
  gameupdate()
  _draw=gamedraw
 elseif scene == playersetupupdate then
  playersetupupdate()
  _draw=playersetupdraw
 elseif scene == courseselectionupdate then
  courseselectionupdate()
  _draw=courseselectiondraw
 elseif scene == readyplayerupdate then
  readyplayerupdate()
  _draw=readyplayerdraw
 elseif scene == coursesummaryupdate then
  coursesummaryupdate()
  _draw=coursesummarydraw
 end
end

__gfx__
000ff000000ff000000ff000000ff00000000000000ff00000000000f00ff0f0000000000f000000000000000000000000000000000000070000000000000000
000ff000000ff000000ff00f000ff0000000ff00000ff000000ff000c00ff0c0000ff000ccc00000000000000000000000000070000000700000000000000000
00ccc00000ccc0000cccccc000ccc0000cccff0000ccc000f0cffcf00ccccc00f00ff00f01000000000000000000000000000000000000000000000000000000
0ccccc0000cfc000f0ccc00000ccccf0f0cccc00fcccccf00ccccc0000ccc0000cccccc010100000000000000000000000000070000000770000000000000000
0f111f00001110000011110000111100001110c000111000001110000111100000ccc00000000000000000000000000000000000000000000000000000000000
001010000010010000100010011110000010100f0010100000101000010010000011100000000000000000000000000000000000000000000000000000000000
00101000001001001100000100010000010010000010100000101000000010000010010000000000000000000000000000000000000000000000000000000000
00101000001000000000000000010000010010000010100000101000000000000010010000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbb00000bb0000
0000010000000000000000007000011000000000000001000000010000000000000000000000000000000000000000000000000000000000bbbbb0000bbb0000
70000110000000000000000001001111000000000000011000000110000000000000000000000000000040000000000000000000000000000bbb0000bbbb0000
100011117000000000000000001111700000000000000111000001110000000000000000000000000700440000000000000000000000000000b000000bbb0000
0111117001000110000001100117711700000000000011700000117e000040000000000000000000007777000000000000004000000040000000000000bb0000
01777100001111117111111170000000000000000000117000001170070044000700400000004000007000000000000000704400070044000000000000000000
0100010000111100001111000000000000000000000011100070111000777000007744000777440000000000000000000077700000777e000000000000000000
07000700070000700007700000000000000000000711111000111110007070000700070000770000000000000000000000707000007070000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003300000000000
00000000000000000000000000000900000000000000000000000000000004000000000000000000700004400000000000000400000004000033330000000000
00000000000000000000000070000990000000000000090000000000700004400000000000000000090044990000000000000440000004400333333000000000
70000900000000000000000090009997000000007000099007000900900044997000000000000000004449700000000000000499000004993333333300000000
900009907000090000000900099999000000000090099997090009900444497009000440000004400499977700000000000044700000447e3333333300000000
09999997090009900000099009999970000000000999990009999997049999700044449979444499700000000000000000004970000049700000000000000000
09999900009999977999999770000000000000000990070009999900099097000099970000999700000000000000000000004990007049900000000000000000
07000700079999700097790000000000000000000700000007000700070007000700097000077000000000000000000007994970009949700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000005000000000000000000900009500000000000000500000005000000000000000000
0000000000000000000000000001100000000000000000000000000090000950000000000000000009009f550000000000000950000009500000000000000000
0000000000000000000000007700110000000000000000000000000090009f55900000000000000000999f000000000000000955000009550000000000000000
000110000001000000000000007777000000000000011000000110000999ff0009000550000005500f9ff99900000000000099f0000099fe0000000000000000
0700110077001000000110000070000000000000007011000700110009fff9000099f5559999f555900000000000000000009ff000009ff00000000000000000
00777000007711007777110000000000000000000077700000777e0009000900009ff90000f99f00000000000000000000009ff000909ff00000000000000000
00707000070007000077000000000000000000000070700000707000090009000900009000099000000000000000000009999990009999900000000000000000
77722222222777772222222277722227222277777772222722222222222272222777722227000000000000000000000000000000000000000000000000000000
77277777777277727777777727277772777727777727777277777777777727777277277772000000000000000000000000000000000000000000000000000000
72fffffffff7272fffffffff722fff72fff72777772fff72fffffffffff72fff72772fff72000000000000000000000000000000000000000000000000000000
2fffff22ffff72fffff2222ff72ffff2ffff2777772ffff22222ffff22222ffff2772ffff2000000000000000000000000000000000000000000000000000000
2ffff2772ffff2ffff277772ff2ffff2ffff2777772ffff27772ffff27772ffff2772ffff2000000000000000000000000000000000000000000000000000000
2ffff2772ffff2ffff277777222ffff2ffff2777772ffff27772ffff27772ffff2772ffff2000000000000000000000000000000000000000000000000000000
2ffff2772ffff2ffff277777772ffff2ffff2777772ffff27772ffff27772ffff2772ffff2000000000000000000000000000000000000000000000000000000
29999277299992999927777777299992999927777729999277729999277729999277299992000000000000000000000000000000000000000000000000000000
29999222299992999927722227299992999927777729999277729999277729999922999992000000000000000000000000000000000000000000000000000000
29999999999992999927299992299992999927777729999277729999277772999999999927000000000000000000000000000000000000000000000000000000
29999999999992999927299999299992999927777729999277729999277777299999999277000000000000000000000000000000000000000000000000000000
29999222299992999927299999299992999927777729999277729999277777722999922777000000000000000000000000000000000000000000000000000000
29999277299992999927729999299992999927777729999277729999277777772999927777000000000000000000000000000000000000000000000000000000
2eeee2772eeee2eeee2772eeee2eeee2eeee2777772eeee27772eeee277777772eeee27777000000000000000000000000000000000000000000000000000000
29999277299992999927729999299992999927777729999277729999277777772999927777000000000000000000000000000000000000000000000000000000
2eeee2772eeee2eeee2772eeee2eeee2eeee2777772eeee27772eeee277777772eeee27777000000000000000000000000000000000000000000000000000000
2eeee2772eeee2eeeee22eeeee2eeee2eeee2222222eeee27772eeee277777772eeee27777000000000000000000000000000000000000000000000000000000
2eeee2772eeee22eeeeeeeeee22eeee2eeeeeeeeee2eeee27772eeee277777772eeee27777000000000000000000000000000000000000000000000000000000
2eeee2772eeee272eeeeeeee272eeee2eeeeeeeeee2eeee27772eeee277777772eeee27777000000000000000000000000000000000000000000000000000000
72222777722227772222222277722227222222222272222777772222777777777222277777000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000
00000000000000000000000000006000000000000000000000000000000000000000000000000000000071900000000000000000000000000000000000000000
00000000000000000000000006006600000000000000000000000000000001000000000000000000006177000000000000000100000001000000000000000000
00006000000000000000000000666600000000000000600000006000000071900000010000000100069997700000000000000190000001900000000000000000
06006600060060000000600000600000000000000000660000006600006117007661719006617190707000000000000000001770000017e00000000000000000
00666000006666000666660000000000000000000060600000006e00069997000099970070999700070000000000000000706970000069700000000000000000
00606000060006000066000000000000000000000006600000666000707007000700007000077000000000000000000000669970076699700000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd000000000
00000000000000000ddd0000000000000bdd00000000000000000000000000000000000000000000000000000000000000000ddb00dda00000f00b1000000000
000c1d00000cdd000d1000000dda00000a1d000000000000000000ddd0000000000dd00000cdb000000000c30000caa0000f0c1000c10000000c0bbc00000000
000fdd00000b1d000dc000000d1a00000cdd000000001000000000d1d00000000001d00000d1b0000000000d0000d1a000000000000000000001d0000ddb0000
000000000000a000000000000c0000000000000000000c0000000000c0000000000cd00000ddd000000100000000dd000000000000000000000000000c3b0000
0000000000000000000000000000000000000000000000000000bdc000000000000000000000000000c00000000bac00000000dd00ddb000000c00000dab0000
0000000000000000000000000000000000000000c00000000000d1d00000001d000000000000000000f00000000b1d000000001c00c1000000b30a1000000000
000000dd00000000000100000000ddc000000000100000000d00d00000000cdd000000000000000000000000000bdd000000000000000000000000c000000000
0000001c0000000000c000001d00d10000000000000000000c100c2000000000010000000dd0000000000000000dc0000000dd00000000000000000000000c00
0000000000000000000000000c000d00000000000000c0000f000000000000000c00000002d000000000000000b3d00000001c00000000000000000000000100
00000000000000000000000000000000000000000000d1000000000000000cd00000000000c000000000dd00000dd00000000000000000000000000000000000
000000000cb000000dd00000000000000000000dca00dd0000000000000001d00000c0000000000000001d000000000000000000000010000000000000000000
000000000d1d00000d100000000000000010000d100000000000000000000dd0000100000000100000000c0000000000000dd000000c000000000bb000ddc000
000000000ddd000000c000000000000000c000000000000000000d1c000000000000000000000c000000000000000000000c30000000000000000d3000d10000
000000000000000000f0000000000000000f00000000000000000ddd000000000000000000000f0000000000000000000000000000000000000000c000000000
12340000000000006325410000000000513423600000000045312670000000006412530000000000312456000000000012345760000000002475368751000000
0000000bd0000000000000000000000000000000000000000ddb000ddb00bd0000dba0cdd00000000000b0000000000000000000000000000000000000000000
0000000b3c0000000000dd000000bb000000d0000000da000c1b000c1b00c1b000c1a003d0000cdd0000b10ddd00000000f00000000000000000000000000000
dc00000000aa00000000c1000000b1000000c1000000c10000bb000bbb00bb0000dbb00bd000001b0f00c00c3b0000c0000cd0000000c1000000000000000000
d200000000d1000000000000ddd00c0000000000add000000f000000000000cd00f000000000000b00000000bb000200000100000000ddd00000000000000000
dd00000000ddc0000000bdd001d0000000000000d2c000000000000000000d2b0000000000000000000c00000000000000000000000000000000000000000000
0000000000000000000001c000cf000000000000dd0000000000cd00000000bb000000000000bca00001000000000000000000000d1000000000000000000000
00000000000000000adc0000000000000ddd0000000000000000b300000000000000000bb000b3000000000000000000000000000c0000000000000000000000
0000000000000aa00a2d0000000000000d3d000c000000000000000000000000000000010000d0000000000000000000000000dd000000000000000000000000
000000000cdd0d300d000000000000000c0d001000000000000000000003d0000000000dc0000000000000000000000000dcb0d1000000000000000000000000
00000000001000c00000000ca000000000000000000ac000000000000000c0000000000000000000000000000000000000d2000c000000000000000000000000
000ddd0000000000000000003000bba000000000000100000000000000000000000000000000b0000000000000cdd00000dd0000000000000000000000000000
00fc1d0000000000000000000000a3a000100000000000000000000000000000000c00000000bc0000dc00000001d0000000000000ddd0000000000000000000
0000000000000c00000c1d0000000c0000c000ddc0000000000ddd0000000000001000000000100000d10000000000000000000000d100c00000000000000000
0000000000000d10000ddd000000000000f0000100000000000d1c00000000000000000002c00000000000000000000000000000000c00100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65431257000000003414586720000000741354126800000012346257000000001234785600000000142354600000000025643170000000000000000000000000
__label__
76677667766776677667766776666666666666666666666666666666666666666666666666666666666666666666666666666666667766776677667766776677
67766776677667766776677666666666666666666666666666666666666666666666666666666666666666666666666666666666666677667766776677667766
67766776677667766776677666777677766776776667767676777667767776666667767776777677766776666677767776776677766677667766776677667766
76677667766776677667766776676676767676767676667676766676666766666676667676777676667666666666767676676676767766776677667766776677
76677667766776677667766776676677667676767676667776776677766766666676667776767677667776666677767676676677767766776677667766776677
67766776677667766776677666676676767676767676667676766666766766666676767676767676666676666676667676676676766677667766776677667766
67766776677667766776677666777676767766767667767676777677666766666677767676767677767766666677767776777677766677667766776677667766
76677667766776677667766776666666666666666666666666666666666666666666666666666666666666666666666666666666667766776677667766776677
76677667766776677667766776666666666666666666666666666666666666666666666666666666666666666666666666666666667766776677667766776677
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777772222222277777222222227772222722227777777222272222222222227222277772222777777777777777777777777777
77777777777777777777777777777727777777727772777777772727777277772777772777727777777777772777727727777277777777777777777777777777
777777777777777777777777777772fffffffff7272fffffffff722fff72fff72777772fff72fffffffffff72fff72772fff7277777777777777777777777777
77777777777777777777777777772fffff22ffff72fffff2222ff72ffff2ffff2777772ffff22222ffff22222ffff2772ffff277777777777777777777777777
77777777777777777777777777772ffff2772ffff2ffff277772ff2ffff2ffff2777772ffff27772ffff27772ffff2772ffff277777777777777777777777777
77777777777777777777777777772ffff2772ffff2ffff277777222ffff2ffff2777772ffff27772ffff27772ffff2772ffff277777777777777777777777777
77777777777777777777777777772ffff2772ffff2ffff277777772ffff2ffff2777772ffff27772ffff27772ffff2772ffff277777777777777777777777777
77777777777777777777777777772999927729999299992777777729999299992777772999927772999927772999927729999277777777777777777777777777
77777777777777777777777777772999922229999299992772222729999299992777772999927772999927772999992299999277777777777777777777777777
77777777777777777777777777772999999999999299992729999229999299992777772999927772999927777299999999992777777777777777777777777777
77777777777777777777777777772999999999999299992729999929999299992777772999927772999927777729999999927777777777777777777777777777
77777777777777777777777777772999922229999299992729999929999299992777772999927772999927777772299992277777777777777777777777777777
77777777777777777777777777772999927729999299992772999929999299992777772999927772999927777777299992777777777777777777777777777777
77777777777777777777777777772eeee2772eeee2eeee2772eeee2eeee2eeee2777772eeee27772eeee277777772eeee2777777777777777777777777777777
77777777777777777777777777772999927729999299992772999929999299992777772999927772999927777777299992777777777777777777777777777777
77777777777777777777777777772eeee2772eeee2eeee2772eeee2eeee2eeee2777772eeee27772eeee277777772eeee2777777777777777777777777777777
77777777777777777777777777772eeee2772eeee2eeeee22eeeee2eeee2eeee2222222eeee27772eeee277777772eeee2777777777777777777777777777777
77777777777777777777777777772eeee2772eeee22eeeeeeeeee22eeee2eeeeeeeeee2eeee27772eeee277777772eeee2777777777777777777777777777777
77777777777777777777777777772eeee2772eeee272eeeeeeee272eeee2eeeeeeeeee2eeee27772eeee277777772eeee2777777777777777777777777777777
77777777777777777777777777777222277772222777222222227772222722222222227222277777222277777777722227777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333bbb3bb333333333311131113333333331113111333333333111313133333333333333333333333333333333333
33333333333333333333333333333333333333b3b33b333333333313133313333333331313331333333333131313133333333333333333333333333333333333
33333333333333333333333333333333333333bbb33b333333333311131113333333331113311333333333111311133333333333333333333333333333333333
33333333333333333333333333333333333333b3333b333333333313331333333333331333331333333333133333133333333333333333333333333333333333
33333333333333333333333333333333333333b333bbb33333333313331113333333331333111333333333133333133333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333777777777777777773333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333373333333ff33333373333333113333333333333311333333333333331133333333333333333333333333333333333333
3333333333333333333333333333333373333333ff33333373333333113333333333333311333333333333331133333333333333333333333333333333333333
333333333333333333333333333333337333333ccc33333373333331113333333333333111333333333333311133333333333333333333333333333333333333
33333333333333333333333333333333733333ccccc3333373333311111333333333331111133333333333111113333333333333333333333333333333333333
33333333333333333333333333333333733333f111f3333373333311111333333333331111133333333333111113333333333333333333333333333333333333
33333333333333333333333333333333733333313133333373333331313333333333333131333333333333313133333333333333333333333333333333333333
33333333333333333333333333333333733333313133333373333331313333333333333131333333333333313133333333333333333333333333333333333333
33333333333333333333333333333333733333313133333373333331313333333333333131333333333333313133333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333733333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333777777777777777773333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333313333333333333333333333333333333333333333333333313333333333333333333333333333333333333
33333333333333333333333333333333333337333311333333333333333333333333333333333333333331333311333333333333333333333333333333333333
33333333333333333333333333333333333331333111133333333133331333333333333333333333333331333111133333333333333333333333333333333333
33333333333333333333333333333333333333111117333333333133331133333333333331333333333333111111333333333333333333333333333333333333
33333333333333333333333333333333333333177713333333333311111113333333331331133333333333111111333333333333333333333333333333333333
33333333333333333333333333333333333333133313333333333311111333333333333111333333333333113113333333333333333333333333333333333333
33333333333333333333333333333333333333733373333333333313331333333333333131333333333333133313333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333bb333bb3bb33bbb3333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b3b3b3b3b3b3b333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b3b3b3b3b3b3bb33333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b3b3b3b3b3b3b333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333bbb3bb33b3b3bbb3333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777eeeee777777eee7ee777ee7eee7eee7e7e77ee7eee7eee77ee7ee777ee77777777777777777777777777777777777
7777777777777777777777777777777777ee7e7ee777777e77e7e7e7777e77e7e7e7e7e7777e777e77e7e7e7e7e7777777777777777777777777777777777777
7777777777777777777777777777777777eee7eee777777e77e7e7eee77e77ee77e7e7e7777e777e77e7e7e7e7eee77777777777777777777777777777777777
7777777777777777777777777777777777ee7e7ee777777e77e7e777e77e77e7e7e7e7e7777e777e77e7e7e7e777e77777777777777777777777777777777777
77777777777777777777777777777777777eeeee777777eee7e7e7ee777e77e7e77ee77ee77e77eee7ee77e7e7ee777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

__sfx__
001000201d073000030c0230000318635000030e413000000c063000030c01300003186350000037415000000c06300003180130000318635374150e413000030c06300003374150000018635286140c0630e413
001000201f0201f0211f0211f02500000002200c220002101d0201d0211d0211d0250000000000180200c7301c0201c0211c0211c0250000000000180200c7301d0201d0211d0211d025000000c7301802000000
00020000373503735037350333503035037300333002e3003e3003d3003c300113000c3000c300283000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000000035450374503545030450274501d450184501645013450114500f4500f4500a4500a4500745007450054500345003450034500000000000000000000000000000000000000000000000000000000
0002000022350223502235024350273502735027350293502e3503035033350373503a3503f350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001f450164500f4500f4501d450244502945029450034002e450304503045033450354503a4503f40000400004000040000400004000040000400004000040000400004000040000400004000040000400
010400000c531005350c5030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300500005000050000500005000050000500
000700040c61500503006150050300503005030050300503005030050300503005030050300503005030050300503005030050000500005000050000500005000000000000000000000000000000000000000000
000100002f0202f0002f0002200003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000320202e0202f0203701000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100020270301b030180301b04024040270302b0402b0402b0402b0302903029040290300000000000000000000000000000001f03022030290302b030220301f0301f030240302403027040270302903000000
00100020270301b030180401b04024030270302b0302b0402c0302b03027030290302e0402e040000001d0001d0001d000030001d0301d030180301800013030220301f020240001104027000160401804000000
0002000022040220401f0401b0401b040180401604011030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00014344
01 00010a44
02 00010b44

