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

function createtiles()
 tiles={}

 for _i=1,16 do
  local _id=_i
  local _v=grid[_i].v
  _i-=1
  add(tiles,{
   x=_i&3,
   y=_i\4,
   id=_id,
   v=_v,
  })
 end
end

function reverserow(_row)
 _row[1],_row[2],_row[3],_row[4]=_row[4],_row[3],_row[2],_row[1]
 return _row
end

function collapse(_row)
 local _newrow={}
 for _i=1,#_row do
  if _row[_i].v > 0 then
   add(_newrow,_row[_i])
  end
 end
 return _newrow
end

function mergeneighbors(_row)
 for _i=1,#_row-1 do
  if _row[_i].v == _row[_i+1].v then
   _row[_i].v+=_row[_i+1].v
   _row[_i+1].v=0
  end
 end
end

function extendwith0(_row)
 while #_row <= 4 do
  add(_row,{v=0}) -- note: no id
 end
 return _row
end

function updatetiles(_row)
 for _i=1,#_row do
  local _id=_row[_i].id
  local _t=tiles[_id]
  -- _t.endx=(_id-1)&3
  -- _t.endy=(_id-1)\4
  _t.x=(_id-1)&3
  _t.y=(_id-1)\4
 end
end

function dorow(_row)
 local _newrow=collapse(_row)
 updatetiles(_newrow)

 -- mergeneighbors(_newrow)

 _newrow=collapse(_newrow)
 updatetiles(_newrow)

 return extendwith0(_newrow)
end

function getgridrow(_i)
 _i=(_i-1)*4
 return {
  grid[1+_i],
  grid[2+_i],
  grid[3+_i],
  grid[4+_i],
 }
end

function setgridrow(_i,_row)
 _i=(_i-1)*4
 grid[1+_i]=_row[1]
 grid[2+_i]=_row[2]
 grid[3+_i]=_row[3]
 grid[4+_i]=_row[4]
end

function getgridcol(_i)
 return {
  grid[_i],
  grid[_i+4],
  grid[_i+8],
  grid[_i+12],
 }
end

function setgridcol(_i,_row)
 grid[_i]=_row[1]
 grid[_i+4]=_row[2]
 grid[_i+8]=_row[3]
 grid[_i+12]=_row[4]
end

local ts=0

function rungrid(_dir)
 ts=t()

 -- reset grid id
 for _i=1,16 do
  grid[_i].id=_i
 end

 -- add new tiles
 createtiles()

 -- update logic
 if _dir == 0 then
  for _r=1,4 do
   local _row=getgridrow(_r)
   _row=dorow(_row)
   setgridrow(_r,_row)
  end

 elseif _dir == 1 then
  for _r=1,4 do
   local _row=reverserow(getgridrow(_r))
   _row=dorow(_row)
   setgridrow(_r,reverserow(_row))
  end

 elseif _dir == 2 then
  for _c=1,4 do
   local _row=getgridcol(_c)
   _row=dorow(_row)
   setgridcol(_c,_row)
  end

 elseif _dir == 3 then
  for _c=1,4 do
   local _row=reverserow(getgridcol(_c))
   _row=dorow(_row)
   setgridcol(_c,reverserow(_row))
  end

 end

 -- set animation targets for tiles
 -- for _i=1,16 do
 --  local _id=grid[_i].id
 --  local _x,_y=(_i-1)&3,(_i-1)\4
 --  if _id then
 --   local _t=tiles[grid[_i].id]
 --   _t.endx=_x
 --   _t.endy=_y
 --   debug(_t.x)
 --   -- _t.v=grid[_id].v

 --  else
 --   tiles[_i].x=_x
 --   tiles[_i].y=_y
 --   tiles[_i].v=grid[_i].v
 --  end
 -- end

 -- check for game over

end

function _init()
 score=0

 grid={}

 for _i=1,16 do
  grid[_i]={v=0,id=_i}
 end
 
 grid[1].v=2
 grid[3].v=2
 grid[7].v=2
 grid[8].v=2
 grid[9].v=2

 createtiles()

end

function _update()

 for _i=0,3 do
  if btnp(_i) then
   rungrid(_i)
   break
  end
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
 local _dt=min(t()-ts,1)

 for _tile in all(tiles) do
  local _v=_tile.v
  local _x=_tile.x
  local _y=_tile.y

  local _f=rect
  if _v != 0 then
   _f=rectfill
  end

  -- if _tile.endx then
  --  _x=_tile.x+(_tile.endx-_tile.x)/_tile.endx*_dt
  -- end

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
