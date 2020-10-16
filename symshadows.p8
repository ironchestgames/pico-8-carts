pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end



-- set auto-repeat delay for btnp
poke(0x5f5c, 5)


_p={x=16,y=16}

floor={}
fog={}
arslen=1023

for _i=0,arslen do
 fog[_i]=1
 floor[_i]=1
 if rnd() > 0.75 then
  floor[_i]=2
 end
end
floor[_p.y*32+_p.x]=1

function _update()
 
 for _i=0,arslen do
  fog[_i]=1
 end

 if btnp(0) then
  _p.x-=1
 end
 if btnp(1) then
  _p.x+=1
 end
 if btnp(2) then
  _p.y-=1
 end
 if btnp(3) then
  _p.y+=1
 end

 -- class quadrant:

 --   north = 0
 --   east  = 1
 --   south = 2
 --   west  = 3

 --   def __init__(self, cardinal, origin):
 --       self.cardinal = cardinal
 --       self.ox, self.oy = origin
 --   def transform(self, tile):
 --       row, col = tile
 --       if self.cardinal == north:
 --           return (self.ox + col, self.oy - row)
 --       if self.cardinal == south:
 --           return (self.ox + col, self.oy + row)
 --       if self.cardinal == east:
 --           return (self.ox + row, self.oy + col)
 --       if self.cardinal == west:
 --           return (self.ox - row, self.oy + col)

 local function getdirtransform(_dir,_tile)
  -- todo: change to pico dirs
  local _c,_r=_tile.col,_tile.row
  if _dir == 0 then
   return _p.x+_c,_p.y-_r
  elseif _dir == 1 then
   return _p.x+_r,_p.y+_c
  elseif _dir == 2 then
   return _p.x+_c,_p.y+_r
  elseif _dir == 3 then
   return _p.x-_r,_p.y+_c
  end
 end

  -- def round_ties_up(n):
  --  return math.floor(n + 0.5)
 local function roundtiesup(_n)
  return flr(_n+0.5)
 end

  -- def round_ties_down(n):
  --  return math.ceil(n - 0.5)
 local function roundtiesdown(_n)
  return -flr(-(_n-0.5))
 end

  -- class row:

  --  def __init__(self, depth, start_slope, end_slope):
  --      self.depth = depth
  --      self.start_slope = start_slope
  --      self.end_slope = end_slope
  --  def tiles(self):
  --      min_col = round_ties_up(self.depth * self.start_slope)
  --      max_col = round_ties_down(self.depth * self.end_slope)
  --      for col in range(min_col, max_col + 1):
  --          yield (self.depth, col)

  --  def next(self):
  --      return row(
  --          self.depth + 1,
  --          self.start_slope,
  --          self.end_slope)
 local function newrow(_depth,_startslope,_endslope)
  return {
   depth=_depth,
   startslope=_startslope,
   endslope=_endslope,
  }
 end

 local function gettiles(_row)
  local _mincol=roundtiesup(_row.depth*_row.startslope)
  local _maxcol=roundtiesdown(_row.depth*_row.endslope)
  local _tiles={}
  for _col=_mincol,_maxcol do
   add(_tiles,{row=_row.depth,col=_col})
  end
  return _tiles
 end

 local function nextrow(_row)
  return newrow(_row.depth+1,_row.startslope,_row.endslope)
 end

 -- my own
 local function isnotoffpremises(_x,_y)
  return _x < 32 and _x >= 0 and _y < 32 and _x >= 0
 end

  -- local function compute_fov(origin, is_blocking, mark_visible)
  -- not needed

   -- mark_visible(*origin)
 fog[_p.y*32+_p.x]=0

   -- for i in range(4):
 for _dir=0,3 do

    -- quadrant = quadrant(i, origin)
    -- not needed

    -- def reveal(tile):
    --     x, y = quadrant.transform(tile)
    --     mark_visible(x, y)
  local function reveal(_tile)
   local _x,_y=getdirtransform(_dir,_tile)
   if isnotoffpremises(_x,_y) then
   -- debug('reveal',_x,_y,'til',_dir,_tile.row,_tile.col)
    fog[_y*32+_x]=0
   end
  end
    
    -- def is_wall(tile):
    --     if tile is none:
    --         return false
    --     x, y = quadrant.transform(tile)
    --     return is_blocking(x, y)
  local function iswall(_tile)
   if _tile then
    local _x,_y=getdirtransform(_dir,_tile)
    return floor[_y*32+_x] == 2
   end
   -- return nil
  end

    -- def is_floor(tile):
    --     if tile is none:
    --         return false
    --     x, y = quadrant.transform(tile)
    --     return not is_blocking(x, y)
  local function isfloor(_tile)
   if _tile then
    local _x,_y=getdirtransform(_dir,_tile)
    local _f=floor[_y*32+_x]
    return _f == 0 or _f == 1
   end
   -- return nil
  end

   --  def slope(tile):
   -- row_depth, col = tile
   -- return fraction(2 * col - 1, 2 * row_depth)
  local function slope(_tile)
   return (2*_tile.col-1)/(2*_tile.row)
  end

-- def is_symmetric(row, tile):
--     row_depth, col = tile
--     return (col >= row.depth * row.start_slope
--         and col <= row.depth * row.end_slope)
  local function issymmetric(_row,_tile)
   return _tile.col >= _row.depth * _row.startslope and _tile.col <= _row.depth * _row.endslope
  end

    -- def scan_iterative(row):
    --     rows = [row]
    --     while rows:
    --         row = rows.pop()
    --         prev_tile = none
    --         for tile in row.tiles():
    --             if is_wall(tile) or is_symmetric(row, tile):
    --                 reveal(tile)
    --             if is_wall(prev_tile) and is_floor(tile):
    --                 row.start_slope = slope(tile)
    --             if is_floor(prev_tile) and is_wall(tile):
    --                 next_row = row.next()
    --                 next_row.end_slope = slope(tile)
    --                 rows.append(next_row)
    --             prev_tile = tile
    --         if is_floor(prev_tile):
    --             rows.append(row.next())

  local function scan(_row1)
   local _rows={_row1}
   while #_rows > 0 do
    local _row=deli(_rows,#_rows)
    local _prevtile
    local _tiles=gettiles(_row)
    for _tile in all(_tiles) do
     if iswall(_tile) or issymmetric(_row,_tile) then
      reveal(_tile)
     end
     if iswall(_prevtile) and isfloor(_tile) then
      _row.startslope=slope(_tile)
     end
     if isfloor(_prevtile) and iswall(_tile) then
      local _nextrow=nextrow(_row)
      _nextrow.endslope=slope(_tile)
      add(_rows,_nextrow)
     end
     _prevtile=_tile
    end
    if isfloor(_prevtile) then
     local _nextrow=nextrow(_row)
     add(_rows,_nextrow)
    end
   end
  end


  -- def scan(row):
  --           prev_tile = none
  --           for tile in row.tiles():
  --               if is_wall(tile) or is_symmetric(row, tile):
  --                   reveal(tile)
  --               if is_wall(prev_tile) and is_floor(tile):
  --                   row.start_slope = slope(tile)
  --               if is_floor(prev_tile) and is_wall(tile):
  --                   next_row = row.next()
  --                   next_row.end_slope = slope(tile)
  --                   scan(next_row)
  --               prev_tile = tile
  --           if is_floor(prev_tile):
  --               scan(row.next())

  -- local function scan(_row)
  --  local _prevtile
  --  local _tiles=gettiles(_row)
  --  for _tile in all (_tiles) do
  --   if iswall(_tile) or issymmetric(_row,_tile) do
  --    reveal(_tile)
  --   end
  --   if iswall()
  --  end
  -- end

  --   first_row = row(1, fraction(-1), fraction(1))
  local _firstrow=newrow(1,-1,1)

   --   scan(first_row)
  scan(_firstrow)
 end
end

function _draw()
 cls(0)
 for _i=0,arslen do
  local _x,_y=_i&31,_i\32
  local _f=floor[_i]
  rectfill(_x*4,_y*4,_x*4+3,_y*4+3,_f)
 end
 rectfill(_p.x*4,_p.y*4,_p.x*4+3,_p.y*4+3,15)

 for _i=0,arslen do
  local _x,_y=_i&31,_i\32
  if fog[_i] == 1 then
   rectfill(_x*4,_y*4,_x*4+3,_y*4+3,0)
  end
 end
end


__gfx__
13300442133004420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
81156229011562200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80575609005756000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70756505007565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50575606000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
