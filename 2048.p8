pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

function flrrnd(x)
 return flr(rnd(x))
end

-- palette
pal(0,134,1)

function _init()
 score=0

 grid={}

 for _y=1,4 do
  grid[_y]={}
  for _x=1,4 do
   grid[_y][_x]={v=0}
  end
 end
 
 -- grid[flrrnd(3)][flrrnd(3)]=2
 -- local _hastwo=nil
 -- while not _hastwo do
 --  local _x=flrrnd(3)
 --  local _y=flrrnd(3)
 --  if grid[_y][_x] == 0 then
 --   _hastwo=true
 --   grid[_y][_x]=2
 --  end
 -- end
 
 grid[1][1].v=2
 grid[3][2].v=2
 grid[2][4].v=2
 grid[2][1].v=2
 grid[3][1].v=2

end

function reverserow(_row)
 _row[1],_row[2],_row[3],_row[4]=_row[4],_row[3],_row[2],_row[1]
 return _row
end

function collapse(_row)
 local _newrow={}
 for _i=1,#_row,1 do
  if _row[_i].v > 0 then
   add(_newrow,_row[_i])
  end
 end
 return _newrow
end

function mergeneighbors(_row)
 for _i=1,#_row-1,1 do
  if _row[_i].v == _row[_i+1].v then
   _row[_i].v+=_row[_i+1].v
   _row[_i+1].v=0
  end
 end
end

function extendwith0(_row)
 while #_row <= 4 do
  add(_row,{v=0})
 end
 return _row
end

function dorow(_row)
 local _newrow=collapse(_row)
 mergeneighbors(_newrow)
 _newrow=collapse(_newrow)
 _row=extendwith0(_newrow)
 return _newrow
end

local ts=0

function rungrid(_dx,_dy)
 ts=t()

 if _dx == -1 then
  for _y=1,4 do
   grid[_y]=dorow(grid[_y])
  end

 elseif _dx == 1 then
  for _y=1,4 do
   local _row=reverserow(grid[_y])
   grid[_y]=reverserow(dorow(_row))
  end

 elseif _dy == -1 then
  for _y=1,4 do
   local _row={}
   for _x=1,4 do
    _row[_x]=grid[_x][_y]
   end
   _row=dorow(_row)
   for _x=1,4 do
    grid[_x][_y]=_row[_x]
   end
  end

 elseif _dy == 1 then
  for _y=1,4 do
   local _row={}
   for _x=1,4 do
    _row[_x]=grid[_x][_y]
   end
   _row=reverserow(dorow(reverserow(_row)))
   for _x=1,4 do
    grid[_x][_y]=_row[_x]
   end
  end
 end

 

 -- add new
 

end

function _update()
 tiles={}

 for _y=1,4 do
  for _x=1,4 do
   local _id=_y*10+_x
   grid[_y][_x].id=_id
   add(tiles,{
    x=_x,
    y=_y,
    id=_id,
    v=grid[_y][_x].v,
   })
  end
 end

 if btnp(0) then
  rungrid(-1,0)
 elseif btnp(1) then
  rungrid(1,0)
 elseif btnp(2) then
  rungrid(0,-1)
 elseif btnp(3) then
  rungrid(0,1)
 end
end

colors={
 [0]=15,
 [2]=15,
 [4]=5,
 [8]=6,
}

function _draw()
 cls(0)

 local _offx,_offy=9,14
 local _dt=min(t()-ts,2)

 for _tile in all(tiles) do
  local _v=_tile.v
  local _x=_tile.x
  local _y=_tile.y

  local _f=rect
  if _v != 0 then
   _f=rectfill
  end

  _f(
   _offx+_x*8,
   _offy+_y*8,
   _offx+_x*8+7,
   _offy+_y*8+7,
   colors[_v])
 
 end

 print(score,5,1,7)


end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
