pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end


pal(3,139,1) -- dark-green -> medium-green
pal(12,140,1) -- blue -> true-blue

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*.1
 local dy=(y2-y1)*.1
 return sqrt(dx*dx+dy*dy)*10
end

function sortony(_t)
 for _i=1,#_t do
  local _j = _i
  while _j > 1 and _t[_j-1].y > _t[_j].y do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

local players={
 {},
 {},
 -- {ai=true},
}

function mybtn(_i,_p)
 if players[_p+1].ai then
  return nil -- todo: ai here
 else
  return btn(_i,_p)
 end
end

function drawteam1(_guy)
 circfill(_guy.x,_guy.y,2,8)
end

function drawteam2(_guy)
 circfill(_guy.x,_guy.y,2,12)
end

function drawball(_ball)
 rectfill(_ball.x-1,_ball.y-1,_ball.x,_ball.y,7)
end


courtw=240
courth=114

local teams={
 {
  a=.5,
  targetx=16,
  {x=0,y=0,a=.5,draw=drawteam1},
  {x=56,y=0,a=.5,draw=drawteam1},
  {x=56,y=56,a=.5,draw=drawteam1},
  {x=0,y=56,a=.5,draw=drawteam1},
 },
 {
  a=.5,
  targetx=16+courtw,
  {x=0,y=0,a=.5,draw=drawteam2},
  {x=56,y=0,a=.5,draw=drawteam2},
  {x=56,y=56,a=.5,draw=drawteam2},
  {x=0,y=56,a=.5,draw=drawteam2},
 } 
}

targety=65

for _guy in all(teams[1]) do
 _guy.x+=110
 _guy.y+=38
end

for _guy in all(teams[2]) do
 _guy.x+=48
 _guy.y+=38
end

defaultspd=1.25

ball={
 x=32,
 y=32,
 a=0,
 spd=1,
 draw=drawball,
}


function _update60()

 -- input
 for _player=0,1 do
  local _team=teams[_player+1]
  local _teamdx,_teamdy=0,0
  _team.curspd=0

  if mybtn(0,_player) then
   _teamdx=-1
   _team.curspd=defaultspd
  elseif mybtn(1,_player) then
   _teamdx=1
   _team.curspd=defaultspd
  end

  if mybtn(2,_player) then
   _teamdy=-1
   _team.curspd=defaultspd
  elseif mybtn(3,_player) then
   _teamdy=1
   _team.curspd=defaultspd
  end

  if _team.curspd != 0 then
   _team.a=atan2(_teamdx,_teamdy)
  end

  -- pass
  local _passbtndown=mybtn(5,_player)
  if _passbtndown and not _team.ballsprinting then
   for _guy in all(_team) do
    if _guy.hasball then
     _team.ballsprinting=true
    end
   end
  elseif _team.ballsprinting and not _passbtndown then
   _team.ballsprinting=nil
   for _guy in all(_team) do
    if _guy.hasball then
     ball.spd=6
     ball.x=_guy.x+cos(_team.a)*8
     ball.y=_guy.y+sin(_team.a)*8
     
     local _px=cos(_team.a)*52
     local _py=sin(_team.a)*52
     local _nearestlen=999
     local _nearestguy=nil
     for _other in all(_team) do
      local _dist=dist(_guy.x+_px,_guy.y+_py,_other.x,_other.y)
      if _other != _guy and _dist < _nearestlen then
       _nearestlen=_dist
       _nearestguy=_other
      end
     end
     _team.passpoint={x=_px,y=_py}
     ball.a=atan2(_nearestguy.x-ball.x,_nearestguy.y-ball.y)
     _guy.hasball=nil
    end
   end
  end

  -- shoot/tackle
  local _shootbtndown=mybtn(4,_player)
  if _shootbtndown and not _team.chargingshot then
   for _guy in all(_team) do
    if _guy.hasball then
     _team.chargingshot=true
     break
    end
   end
   if not _team.chargingshot then
    for _guy in all(_team) do
     -- todo: tackle
    end
   end
  elseif _team.chargingshot and not _shootbtndown then
   _team.chargingshot=nil
   for _guy in all(_team) do
    if _guy.hasball then
     ball.a=atan2(_team.targetx-ball.x,targety-ball.y)
     ball.spd=8
     ball.x=_guy.x+cos(ball.a)*8
     ball.y=_guy.y+sin(ball.a)*8
     _guy.hasball=nil
     break
    end
   end
  end

 end

 -- move teams
 for _player=1,2 do
  local _team=teams[_player]
  for _guy in all(_team) do
   local _spd=_team.curspd
   if _guy.hasball then
    if _team.chargingshot then
     _spd=0
    elseif _team.ballsprinting then
     _spd=_spd*1.2
    else
     _spd=_spd*0.8
    end
   end
   local _nextx=_guy.x+cos(_team.a)*_spd
   local _nexty=_guy.y+sin(_team.a)*_spd
   for _other in all(_team) do
    if _guy != _other and dist(_guy.x,_guy.y,_other.x,_other.y) < 4 then
     local _a=atan2(_guy.x-_other.x,_guy.y-_other.y)
     _nextx+=cos(_a)*5
     _nexty+=sin(_a)*5
     break
    end
   end
   _guy.x=mid(16,_nextx,16+courtw)
   _guy.y=mid(8,_nexty,8+courth)

   _guy.a=atan2(_dx,_dy)
  end
 end

 -- update ball
 local _ballowner=nil
 for _player=1,2 do
  local _team=teams[_player]
  for _guy in all(_team) do
   if _guy.hasball then
    ball.x=_guy.x
    ball.y=_guy.y
    _ballowner=_guy
   end
  end
 end

 if not _ballowner then
  ball.x+=cos(ball.a)*ball.spd
  ball.y+=sin(ball.a)*ball.spd
  ball.spd=ball.spd*.95
  if ball.spd < .1 then
   ball.spd=0
  end
 end

 ball.x=mid(16,ball.x,16+courtw)
 ball.y=mid(8,ball.y,8+courth)

 camera(mid(0,ball.x-64,16+courtw-(128-16)),0)

 if not _ballowner then
  for _player=1,2 do
   local _team=teams[_player]
   for _guy in all(_team) do
    if dist(_guy.x,_guy.y,ball.x,ball.y) < 3 then
     _guy.hasball=true
     break
    end
   end
  end
 end

end

function _draw()
 cls(3)

 -- draw court
 local _courtcenter=16+courtw/2
 local _penaltyboxw=56
 rect(16,8,16+courtw,122,7)
 line(_courtcenter,8,_courtcenter,122,7)
 circ(_courtcenter,64,15,7)
 rect(16,25,16+_penaltyboxw,105,7)
 rect(16+courtw,25,16+courtw-_penaltyboxw,105,7)

 -- draw teams and ball
 local _drawables={}

 for _player=1,2 do
  local _team=teams[_player]
  for _guy in all(_team) do
   add(_drawables,_guy)
   if _guy.hasball then
    if _team.passpoint then
     pset(_guy.x+_team.passpoint.x,_guy.y+_team.passpoint.y,15)
    end
   end
  end
 end

 add(_drawables,ball)
 sortony(_drawables)

 for _drawable in all(_drawables) do
  _drawable.draw(_drawable)
 end



end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
