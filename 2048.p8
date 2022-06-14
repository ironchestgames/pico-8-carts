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
 for _y=0,3 do
  grid[_y]={}
  for _x=0,3 do
   grid[_y][_x]=0
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

 grid[0][0]=2
 grid[0][1]=2
 grid[0][2]=2
 grid[0][3]=2
 grid[1][3]=2

end

function rungrid(_dx,_dy)

 if _dx == -1 then
  for _y=0,3,1 do
   for _x=0,2,1 do
    for _x2=_x+1,3,1 do
     if grid[_y][_x] == 0 then
      grid[_y][_x]=grid[_y][_x2]
      grid[_y][_x2]=0
     elseif grid[_y][_x] == grid[_y][_x2] then
      grid[_y][_x]*=2
      grid[_y][_x2]=0
     end
    end
   end
  end

 elseif _dx == 1 then
  for _y=0,3,1 do
   for _x=3,1,-1 do
    for _x2=_x-1,0,-1 do
     if grid[_y][_x] == 0 then
      grid[_y][_x]=grid[_y][_x2]
      grid[_y][_x2]=0
      elseif grid[_y][_x] == grid[_y][_x2] then
      grid[_y][_x]*=2
      grid[_y][_x2]=0
     end
    end
   end
  end

 elseif _dy == -1 then
  for _y=0,2,1 do
   for _x=0,3,1 do
    for _y2=_y+1,3,1 do
     if grid[_y][_x] == 0 then
      grid[_y][_x]=grid[_y2][_x]
      grid[_y2][_x]=0
     elseif grid[_y][_x] == grid[_y2][_x] then
      grid[_y][_x]*=2
      grid[_y2][_x]=0
     end
    end
   end
  end

 elseif _dy == 1 then
  for _y=3,1,-1 do
   for _x=0,3,1 do
    for _y2=_y-1,0,-1 do
     if grid[_y][_x] == 0 then
      grid[_y][_x]=grid[_y2][_x]
      grid[_y2][_x]=0
      elseif grid[_y][_x] == grid[_y2][_x] then
      grid[_y][_x]*=2
      grid[_y2][_x]=0
     end
    end
   end
  end
 end
end

function _update()
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
 for _y=0,3 do
  for _x=0,3 do
   local _v=grid[_y][_x]
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
