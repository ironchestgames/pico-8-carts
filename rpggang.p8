pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

function dist(x1,y1,x2,y2)
 local dx,dy=(x2-x1)*0.1,(y2-y1)*0.1
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

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

actortempl={
 x=0,
 y=0,
 a=0,
 nextx=0,
 nexty=0,
 spd=0.15,
 -- ismoving=nil,
}

btnmasktoa={
 [0x0002]=0, -- right
 [0x0006]=0.125, -- right/up
 [0x0004]=0.25, -- up
 [0x0005]=0.375, -- up/left
 [0x0001]=0.5, -- left
 [0x0009]=0.625, -- left/down
 [0x0008]=0.75, -- down
 [0x000a]=0.875, -- down/right
}

function _init()
 actors={}
 gang={}
 enemies={}

 wizard=clone(actortempl)
 wizard.x=64
 wizard.y=64
 wizard.spd=0.2

 add(actors,wizard)

 for _i=1,1 do
  local _enemy=clone(actortempl)
  _enemy.x=100
  _enemy.y=10

  add(actors,_enemy)
  add(enemies,_enemy)
 end

 local _ganger=clone(actortempl)
 _ganger.x=10
 _ganger.y=100
 _ganger.order='defend'

 add(actors,_ganger)
 add(gang,_ganger)

end


function _update60()
 local _angle=btnmasktoa[band(btn(),0b1111)] -- note: filter out o/x buttons from dpad input
 wizard.ismoving=nil

 if _angle then
  wizard.a=_angle
  wizard.ismoving=true
 end

 btn4=btn(4)
 btn5=btn(5)

 if btn4 or btn5 then
  wizard.ismoving=nil
 end

 if btn4 then
  -- show orders
 end

 if btn5 then
  -- show spells
 end

 -- update gang
 for _g in all(gang) do
  local _disttowizard=dist(_g.x,_g.y,wizard.x,wizard.y)
  if _g.order == 'defend' then
   if _disttowizard > 10 then
    _g.a=atan2(wizard.x-_g.x,wizard.y-_g.y)
    _g.ismoving=true
   else
    _g.ismoving=nil
   end
  end
 end

 -- update enemies
 for _e in all(enemies) do
  _e.a=atan2(wizard.x-_e.x,wizard.y-_e.y)
  _e.ismoving=true
 end

 -- update all actors
 for _a in all(actors) do
  _a.nextx,_a.nexty=_a.x+cos(_a.a)*_a.spd,_a.y+sin(_a.a)*_a.spd
 end

 for _a in all(actors) do
  if _a.ismoving then
   _a.x=_a.nextx
   _a.y=_a.nexty
  end
 end

end


function _draw()
 cls(0)

 sortony(actors)

 for _i=1,#actors do
  local _a=actors[_i]
  local _c=2
  if _a == wizard then
   _c=7
  end
  if _a.order then
   _c=10
  end
  circfill(_a.x,_a.y,3,_c)
 end
 
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
