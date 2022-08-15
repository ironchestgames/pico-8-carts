pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

pal(12,140,1) -- blue -> true-blue
pal(9,137,1) -- orange -> dark-orange

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*.1
 local dy=(y2-y1)*.1
 return sqrt(dx*dx+dy*dy)*10
end

function sorton(_t,_key)
 for _i=1,#_t do
  local _j = _i
  while _j > 1 and _t[_j-1][_key] > _t[_j][_key] do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

function reverse(_t)
 for _i=1,flr(#_t/2) do
  local _i2=#_t-(_i-1)
  _t[_i],_t[_i2]=_t[_i2],_t[_i]
 end
end

function getteamballowner(_team)
 for _guy in all(_team) do
  if _guy.hasball then
   return _guy
  end
 end
end

function getballowner()
 for _team in all(teams) do
  for _guy in all(_teams) do
   if _guy.hasball then
    return _guy
   end
  end
 end
end

function drawteam1(_guy)
 circfill(_guy.x,_guy.y,2,8)
 circ(_guy.x,_guy.y,5,7)
end

function drawteam2(_guy)
 circfill(_guy.x,_guy.y,2,12)
end

function drawball(_ball)
 rectfill(_ball.x-1,_ball.y-1,_ball.x,_ball.y,9)
end


courtw=240
courth=112
courttop=8
courtleft=16
courtright=courtleft+courtw
courtbottom=courttop+courth

local teams={
 {
  a=.5,
  targetx=courtleft,
  {x=0,y=0,a=.5,draw=drawteam1},
  {x=56,y=0,a=.5,draw=drawteam1},
  {x=56,y=56,a=.5,draw=drawteam1},
  {x=0,y=56,a=.5,draw=drawteam1},
 },
 {
  a=.5,
  targetx=courtright,
  {x=0,y=0,a=.5,draw=drawteam2},
  {x=56,y=0,a=.5,draw=drawteam2},
  {x=56,y=56,a=.5,draw=drawteam2},
  {x=0,y=56,a=.5,draw=drawteam2},
 } 
}

targety=65

for _guy in all(teams[1]) do
 _guy.x+=120
 _guy.y+=55
end

for _guy in all(teams[2]) do
 _guy.x+=18
 _guy.y+=28
end

defaultspd=1.2

ball={
 x=128,
 y=64,
 a=0,
 spd=0,
 draw=drawball,
}

local players={
 {},
 {
  ai=function(_player,_btn,_teamid)
   local _team=teams[_teamid]
   local _ballowner=getteamballowner(_team)
   local _ballownerdisttogoal=999
   local _ballchaser=nil

   if _ballowner then
    _ballownerdisttogoal=dist(_ballowner.x,_ballowner.y,_team.targetx,targety)

   else
    _ballchaser=nil
    local _nearestlen=999
    for _guy in all(_team) do
     local _dist=dist(ball.x,ball.y,_guy.x,_guy.y)
     if _dist < _nearestlen then
      _nearestlen=_dist
      _ballchaser=_guy
     end
    end
   end

   if _btn == 4 and _ballowner and _ballownerdisttogoal < 42 then
    if not _team.chargingshot then
     return true
    else
     return nil
    end
   end

   if _btn == 1 and _ballowner and _ballownerdisttogoal > 16 then
    return true
   end

   if _ballchaser then
    if _btn == 0 and _ballchaser.x > ball.x then
     return true
    end

    if _btn == 1 and _ballchaser.x < ball.x then
     return true
    end

    if _btn == 2 and _ballchaser.y > ball.y then
     return true
    end

    if _btn == 3 and _ballchaser.y < ball.y then
     return true
    end
   end

  end,
 },
}

function mybtn(_i,_p)
 local _player=players[_p]
 if _player.ai then
  return _player.ai(_player,_i,_p)
 else
  return btn(_i,_p-1)
 end
end


function _update60()

 -- input
 for _player=1,2 do
  local _team=teams[_player]
  local _teamdx,_teamdy=0,0
  local _lastskating=_team.skating
  _team.skating=nil

  if mybtn(0,_player) then
   _teamdx=-1
   _team.skating=true
  elseif mybtn(1,_player) then
   _teamdx=1
   _team.skating=true
  end

  if mybtn(2,_player) then
   _teamdy=-1
   _team.skating=true
  elseif mybtn(3,_player) then
   _teamdy=1
   _team.skating=true
  end

  if _team.skating then
   _team.a=atan2(_teamdx,_teamdy)
  end

  if _lastskating and not _team.skating then
   for _guy in all(_team) do
    _guy.x=flr(_guy.x)
   end
  end

  -- pass
  local _passbtndown=mybtn(5,_player)
  local _ballowner=getteamballowner(_team)
  if _ballowner then
   if _passbtndown and not _team.ballsprinting then
    _team.ballsprinting=true
   elseif _team.ballsprinting and not _passbtndown then
    _team.ballsprinting=nil

    ball.spd=6
    ball.x=_ballowner.x+cos(_team.a)*8
    ball.y=_ballowner.y+sin(_team.a)*8
    
    local _px=cos(_team.a)*52
    local _py=sin(_team.a)*52
    local _nearestlen=999
    local _nearestguy=nil
    for _other in all(_team) do
     local _dist=dist(_ballowner.x+_px,_ballowner.y+_py,_other.x,_other.y)
     if _other != _ballowner and _dist < _nearestlen then
      _nearestlen=_dist
      _nearestguy=_other
     end
    end
    _team.passpoint={x=_px,y=_py}
    ball.a=atan2(_nearestguy.x-ball.x,_nearestguy.y-ball.y)
    _ballowner.hasball=nil
   end

  else
   _team.spreadsprinting=_passbtndown
  end

  -- shoot/steal
  local _shootbtndown=mybtn(4,_player)
  local _ballowner=getteamballowner(_team)
  if _ballowner then
   if _shootbtndown and not _team.chargingshot then
    _team.chargingshot=true

   elseif _team.chargingshot and not _shootbtndown then
    _team.chargingshot=nil
    local _ballowner=getteamballowner(_team)
    if _ballowner then
     ball.a=atan2(_team.targetx-ball.x,targety-ball.y)
     ball.spd=5
     ball.x=_ballowner.x+cos(ball.a)*8
     ball.y=_ballowner.y+sin(ball.a)*8
     _ballowner.hasball=nil
    end
   else

    if _shootbtndown then
     local _opponentballowner=getballowner()
     if _opponentballowner then
      _team.steal=true
      for _guy in all(_team) do
       if dist(_guy.x,_guy.y,_opponentballowner.x,_opponentballowner.y) < 5 then
        _guy.hasball=true
        _opponentballowner.hasball=nil
       end
      end
     end

    else
     _team.steal=nil
    end

   end
  end
 end

 -- move teams
 for _player=1,2 do
  local _team=teams[_player]
  if _team.spreadsprinting then
   sorton(_team,'x')

   if _team.targetx > ball.x then
    reverse(_team)
   end
  end

  for _i=1,#_team do
   local _guy=_team[_i]
   local _spd

   if _guy.hasball then
    if _team.chargingshot then
     _spd=0
    elseif _team.ballsprinting then
     _spd=1.75
    elseif _team.skating then
     _spd=1
    else
     _spd=0.25
    end

   else
    if _team.skating then
     _spd=1.25
    else
     _spd=0.25
    end
   end

   if _team.spreadsprinting then
    _spd=_spd*(_i/10+1)
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
   _guy.x=mid(courtleft,_nextx,courtright)
   _guy.y=mid(courttop,_nexty,courtbottom-1)

   _guy.a=atan2(_dx,_dy)
  end
 end

 -- update ball
 local _ballowner=nil
 for _player=1,2 do
  _ballowner=getteamballowner(teams[_player])
  if _ballowner then
   ball.x=_ballowner.x
   ball.y=_ballowner.y
   break
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

 ball.x=mid(courtleft,ball.x,courtright)
 ball.y=mid(courttop,ball.y,courtbottom)

 camera(mid(0,ball.x-64,courtright-(128-courtleft)),0)

 if not _ballowner then
  for _player=1,2 do
   local _team=teams[_player]
   for _guy in all(_team) do
    if dist(_guy.x,_guy.y,ball.x,ball.y) < 5 then
     _guy.hasball=true
     break
    end
   end
  end
 end

end

function _draw()
 cls(6)

 -- draw court
 local _courtcenter=16+courtw/2

 line(courtleft,courttop,courtleft,courtbottom+1,14)
 line(courtright,courttop,courtright,courtbottom+1,14)

 line(_courtcenter,courttop,_courtcenter,courtbottom,14)
 circ(_courtcenter,64,15,14)

 circ(16,65,25,14)
 rectfill(0,0,15,128,6)

 circ(courtright,65,25,14)
 rectfill(courtright+1,0,courtright+16,128,6)

 line(18,7,courtright,7,5)
 line(17,8,courtright-1,8,7)

 -- draw teams and ball
 local _drawables={}

 for _player=1,2 do
  local _team=teams[_player]
  for _guy in all(_team) do
   add(_drawables,_guy)
  end
 end

 add(_drawables,ball)
 sorton(_drawables,'y')

 for _drawable in all(_drawables) do
  _drawable.draw(_drawable)
 end

 -- draw closest barrier
 line(18,120,courtright,120,5)
 line(17,121,courtright-1,121,5)

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
