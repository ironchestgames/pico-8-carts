pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

function sortonx(_t)
 for _i=1,#_t do
  local _j = _i
  while _j > 1 and _t[_j-1].x > _t[_j].x do
   _t[_j],_t[_j-1]=_t[_j-1],_t[_j]
   _j=_j-1
  end
 end
end

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*0.1
 local dy=(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

intmask=0b1111111111111111.0000000000000000

wmap={}
mapw,maph=116,74
halfmapw,halfmaph=mapw/2,maph/2
ports={}
offers={}
contracts={}
days={}

dayfuncs={
 ['shoot one\nof the crew']=function()
  debug('shoot one of the crew')
 end,
 ['bribe crew\nwith more\ndubloons']=function()
  debug('bribe crew with more dubloons')
 end,
}

cameray=0
menusel=1
menupos={0,123,200}
menubtnps={
 function()
  if btnp(0) then
   portsel-=1
  end
  if btnp(1) then
   portsel+=1
  end

  portsel=mid(1,portsel,#ports)
 end,

 function()
  if btnp(0) then
   offersel-=1
  end
  if btnp(1) then
   offersel+=1
  end

  offersel=mid(1,offersel,#offers)

  if btnp(4) then
   -- sign contract
  end
 end,

 function()
  if btnp(4) then
   debug('sailinit')
   sailinit()
  end
 end,
}

pal(1,140,1) -- dark blue -> true-blue
pal(2,130,1) -- dark-purple -> darker-purple
pal(5,132,1) -- dark grey -> dark brown
pal(11,131,1) -- green -> blue green
pal(13,141,1) -- lavender -> mauve
pal(14,134,1) -- pink -> medium-grey

function createmap()
 -- srand(1)

 function noiser(_map)
  for x=1,#_map do
   for y=1,#_map[x] do
    local _v=_map[x][y]
    if x > 1 and x < #_map and y > 1 and y < #_map[x] then
     local _nv=_map[x-1][y-1]+_map[x][y-1]+_map[x+1][y-1]+_map[x-1][y]+_map[x+1][y]+_map[x-1][y+1]+_map[x][y+1]+_map[x+1][y+1]
     if _nv == 1 or _nv < 4 then
      _v=0
     elseif _nv >= 5 then
      _v=1
     end
    else
     _v=0
    end

    _map[x][y]=_v
   end
  end
 end

 function bp(_x1,_y1,_xp,_yp,_x2,_y2,_t)
  return _x1*_t^2+_xp*2*_t*(1-_t)+_x2*(1-_t)^2,
         _y1*_t^2+_yp*2*_t*(1-_t)+_y2*(1-_t)^2
 end

 -- generate noise
 local _opensea=rnd(16)+16
 for _x=1,mapw do
  wmap[_x]={}
  local _lvar=flr(rnd(4)+4)
  for _y=1,maph do
   local _v=flr(rnd(2))
   if _x < _lvar or _x > mapw - _lvar then
    _v=1
   elseif _y < _lvar or _y > maph - _lvar then
    _v=0
   end
   if dist(_x,_y,halfmapw,halfmaph) < _opensea then
    _v=0
   end
   wmap[_x][_y]=_v
  end
 end

 for _i=1,7 do
  noiser(wmap)
 end

 -- generate ports
 _portcount=flr(rnd(4)+6)
 while #ports < _portcount do
  local _x,_y=halfmapw,halfmaph
  local _a=rnd()
  local _dx,_dy=cos(_a),sin(_a)
  local _v=wmap[_x][_y]
  while _v == 0 do
   _x+=_dx
   _y+=_dy
   _flrx=flr(_x)
   _flry=flr(_y)
   if wmap[_flrx] then
    _v=wmap[_flrx][_flry]
    if _v == nil then
     -- no port
     break
    end
    if _v == 1 then
     local _tooclose=nil
     for _p in all(ports) do
      if dist(_p.x,_p.y,_x,_y) < 16 then
       _tooclose=true
      end
     end
     if _x > 5 and _x < mapw - 5 and _y > 5 and _y < maph - 5 and not _tooclose then
      add(ports,{
       x=_flrx,
       y=_flry,
       name='port '..#ports,
      })
     end
     break
    end
   end
  end
 end

 for _port in all(ports) do
  for _other in all(ports) do
   if _port != _other then
    _port[_other]={}
    _d=dist(_port.x,_port.y,_other.x,_other.y)
    local _stepsize=mid(0.05,1/(_d/4.5),0.15)
    local _t=0.05
    while _t <= 0.95 do
     local _x,_y=bp(_port.x,_port.y,halfmapw,halfmaph,_other.x,_other.y,_t)
     if wmap[flr(_x)][flr(_y)] == 1 then
      wmap[flr(_x)][flr(_y)]=0
     end
     add(_port[_other],{x=_x,y=_y})
     _t+=_stepsize
    end
   end
  end
 end

 sortonx(ports)
end

function createoffers()
 local _ports=clone(ports)
 del(_ports,ports[shipport])
 for _p in all(_ports) do
  local _dest=rnd(_ports)
  local _reward=flr(rnd(200))
  add(offers,{
   text='take me and my '..flr(rnd(300))..' sheep\nto '.._dest.name..'.\ni offer '.._reward..' dubloons.',
   dest=_dest,
   reward=_reward,
  })
 end
end

function gameinit()
 createmap()
 shipport=1
 portsel=1

 portinit()
end

function portinit()
 _update=portupdate
 _draw=portdraw

 menusel=1

 offers={}
 createoffers()
 offersel=1

 day=1
 days={
  {
   title='\^wmutiny!',
   text='some of the crew are\ntired of weak leadership.',
   left='shoot one\nof the crew',
   right='bribe crew\nwith more\ndubloons',
  }
 }
end

function portupdate()

 if btnp(2) then
  menusel=mid(1,menusel-1,#menupos)
 end
 if btnp(3) then
  menusel=mid(1,menusel+1,#menupos)
 end

 menubtnps[menusel]()


 -- update camera
 local _camendy=menupos[menusel]
 if abs(_camendy-cameray) > 0 then
  cameray+=(_camendy-cameray)/4
 end
 camera(0,cameray)
 if _update ~= portupdate then
  camera(0,0)
 end

end

function portdraw()
 cls(2)

 -- map
 local _offy=menupos[1]+6
 print('map',_offy,6,9)

 local _mapoffx,_mapoffy=5,_offy+8
 for x=1,mapw do
  for y=1,maph do
   pset(_mapoffx+x,_mapoffy+y,wmap[x][y] > 0 and 14 or 15)
  end
 end

 for _i=1,#ports do
  local _p=ports[_i]
  local _sx=0
  if _i == portsel then
   _sx=4
  end
  if _i == shipport then
   _sx=8
  end
  sspr(_sx,0,4,5,_mapoffx+_p.x-2,_mapoffy+_p.y-2)
 end

 local _path=ports[shipport][ports[portsel]]
 for _p in all(_path) do
  pset(_p.x+_mapoffx,_p.y+_mapoffy,9)
 end

 print(ports[shipport].name..' to '..ports[portsel].name,6,_offy+90,9)
 print(#(_path or {})..' days',6,_offy+100,9)


 -- offers
 _offy=menupos[2]+5
 print('offers',6,_offy,9)

 for _i=1,#offers do
  local _x=8+(_i-1)*12
  rectfill(_x,_offy+12,_x+8,_offy+20,3)
 end

 rect(6+(offersel-1)*12,_offy+10,6+(offersel-1)*12+12,_offy+22,9)

 rectfill(6,_offy+30,122,_offy+100,15)
 print(offers[offersel].text,12,_offy+51,4)

end

function sailinit()
 _update=sailupdate
 _draw=saildraw
end

function sailupdate()
 if btnp(0) then
  dayfuncs[days[day].left]()
  day+=1
 end

 if btnp(1) then
  dayfuncs[days[day].right]()
  day+=1
 end

 if day > #days then
  portinit()
 end
end

function saildraw()
 cls(1)
 rectfill(0,0,128,32,12)

 rectfill(6,5,121,84,15)
 print('day '..day,10,9,14)
 print(days[day].title,64-#days[day].title*3,17,5)
 print(days[day].text,12,26,5)
 print(days[day].left,12,48,4)
 print(days[day].right,70,48,4)
 print('\x8b',30,73,4)
 print('\x91',90,73,4)
end

_init=gameinit

__gfx__
09900990077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94499aa977aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
94499aa97aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
499449949aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04400440099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
