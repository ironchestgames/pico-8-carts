pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

pal(3,129,1) -- green -> darker-blue
pal(2,141,1) -- dark red -> mauve

-- set auto-repeat delay for btnp
poke(0x5f5c, 5)

function getdirtransform(_dir,_tile,_origin)
 -- todo: change to pico dirs
 local _c,_r=_tile.col,_tile.row
 if _dir == 0 then
  return _origin.x+_c,_origin.y-_r
 elseif _dir == 1 then
  return _origin.x+_r,_origin.y+_c
 elseif _dir == 2 then
  return _origin.x+_c,_origin.y+_r
 elseif _dir == 3 then
  return _origin.x-_r,_origin.y+_c
 end
end

function roundtiesup(_n)
 return flr(_n+0.5)
end

function roundtiesdown(_n)
 return -flr(-(_n-0.5))
end

function gettiles(_row)
 local _mincol=roundtiesup(_row.depth*_row.startslope)
 local _maxcol=roundtiesdown(_row.depth*_row.endslope)
 local _tiles={}
 for _col=_mincol,_maxcol do
  add(_tiles,{row=_row.depth,col=_col})
 end
 return _tiles
end

function nextrow(_row)
 return {
  depth=_row.depth+1,
  startslope=_row.startslope,
  endslope=_row.endslope,
 }
end

function isnotoffpremises(_x,_y)
 return _x < 16 and _x >= 0 and _y < 16 and _x >= 0
end

function reveal(_tile,_dir,_origin)
 local _x,_y=getdirtransform(_dir,_tile,_origin)
 if isnotoffpremises(_x,_y) then
  fog[_y*16+_x]=0
  unlit[_y*16+_x]=0
 end
end

function iswall(_tile,_dir,_origin)
 if _tile then
  local _x,_y=getdirtransform(_dir,_tile,_origin)
  return floor[_y*16+_x] == 2
 end
end

function isfloor(_tile,_dir,_origin)
 if _tile then
  local _x,_y=getdirtransform(_dir,_tile,_origin)
  local _f=floor[_y*16+_x]
  return _f == 0 or _f == 1
 end
end

function slope(_tile)
 return (2*_tile.col-1)/(2*_tile.row)
end

function issymmetric(_row,_tile)
 return _tile.col >= _row.depth * _row.startslope and _tile.col <= _row.depth * _row.endslope
end

function scan(_row1,_dir,_origin)
 local _rows={_row1}
 while #_rows > 0 do
  local _row=deli(_rows,#_rows)
  local _prevtile=nil
  local _tiles=gettiles(_row)
  for _tile in all(_tiles) do
   if iswall(_tile,_dir,_origin) or issymmetric(_row,_tile) then
    reveal(_tile,_dir,_origin)
   end
   if iswall(_prevtile,_dir,_origin) and isfloor(_tile,_dir,_origin) then
    _row.startslope=slope(_tile)
   end
   if isfloor(_prevtile,_dir,_origin) and iswall(_tile,_dir,_origin) then
    local _nextrow=nextrow(_row)
    _nextrow.endslope=slope(_tile)
    add(_rows,_nextrow)
   end
   _prevtile=_tile
  end
  if isfloor(_prevtile,_dir,_origin) then
   local _nextrow=nextrow(_row)
   add(_rows,_nextrow)
  end
 end
end

function symshadows(_origin)
 for _dir=0,3 do
  local _firstrow={
   depth=1,
   startslope=-1,
   endslope=1,
  }
  scan(_firstrow,_dir,_origin)
 end
end

_p={x=8,y=8}

sneakp=nil
headp=nil

floor={}
fog={}
unlit={}
arslen=255

for _i=0,arslen do
 fog[_i]=1
 unlit[_i]=1
 floor[_i]=1
 local _x,_y=_i&15,_i\16

 if rnd() > 0.75 or _x == 0 or _x == 15 or _y == 0 or _y == 15 then
  floor[_i]=2
 end
end
floor[_p.y*16+_p.x]=1
_playerpos=_p.y*16+_p.x

ais={}

while #ais < 2 do
 local _pos=flr(rnd(arslen))
 if floor[_pos] == 1 and _pos != _playerpos then
  local _x,_y=_pos&15,_pos\16
  add(ais,{
   x=_x,
   y=_y,
   typ='stationary',
   })
 end
end

for _i=0,arslen do
 fog[_i]=1
end

for _i=0,arslen do
 unlit[_i]=1
end


function _update()

 for _i=0,arslen do
  unlit[_i]=1
 end

 local _nextx,_nexty=_p.x,_p.y

 sneakp=nil
 if btn(4) then
  if btn(0) then
   _nextx-=1
  end
  if btn(1) then
   _nextx+=1
  end
  if btn(2) then
   _nexty-=1
  end
  if btn(3) then
   _nexty+=1
  end

  sneakp={
   x=_nextx,
   y=_nexty,
  }

 else
  if btnp(0) then
   _nextx-=1
  end
  if btnp(1) then
   _nextx+=1
  end
  if btnp(2) then
   _nexty-=1
  end
  if btnp(3) then
   _nexty+=1
  end
  if floor[_nexty*16+_nextx] == 2 then
   _nextx=_p.x
   _nexty=_p.y
  end

  _p.x,_p.y=_nextx,_nexty
 end

 headp={
  x=_p.x,
  y=_p.y,
 }

 fog[headp.y*16+headp.x]=0
 unlit[headp.y*16+headp.x]=0

 symshadows(headp)
 if sneakp then
  if floor[sneakp.y*16+sneakp.x] == 2 then
   sneakp=nil
  else
   symshadows(sneakp)
  end
 end
end

function _draw()
 cls(0)

 -- draw floor
 for _i=0,arslen do
  local _x,_y=_i&15,_i\16
  local _f=floor[_i]
  if unlit[_i] == 1 then
   _f+=2
  end
  rectfill(_x*8,_y*8,_x*8+7,_y*8+7,({1,13,3,2})[_f])
 end

 -- draw ais
 for _ai in all(ais) do
  local _i=_ai.y*16+_ai.x
  if unlit[_i] == 0 then
   rectfill(_ai.x*8,_ai.y*8,_ai.x*8+7,_ai.y*8+7,14)
  end
 end

 -- draw avatar
 rectfill(_p.x*8,_p.y*8,_p.x*8+7,_p.y*8+7,15)

 -- draw fog
 for _i=0,arslen do
  local _x,_y=_i&15,_i\16
  if fog[_i] == 1 then
   rectfill(_x*8,_y*8,_x*8+7,_y*8+7,0)
  end
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
