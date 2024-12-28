pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

cartdata'ironchestgames_tritri_v1'

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

function getpxcolor(_px)
 return _px.colors[flr(#_px.colors*((_px.dur-_px.durc)/_px.dur))+1]
end

pxcolors={7,10,7,6,10,6,13}

blocktypes={
 {{x=0,y=0,c=8},{x=1,y=0,c=8},{x=0,y=1,c=8}},
 {{x=0,y=0,c=12},{x=1,y=0,c=12},{x=1,y=1,c=12}},
 {{x=0,y=0,c=11},{x=0,y=1,c=11},{x=1,y=1,c=11}},
 {{x=1,y=0,c=9},{x=0,y=1,c=9},{x=1,y=1,c=9}},
}


function getnewblocks()
 local _newblocks=clone(rnd(blocktypes))
 for _k,_v in ipairs(_newblocks) do
  _newblocks[_k]=clone(_v)
 end
 return _newblocks
end

function resetgame()
 rowcount=23
 blinkrow={}
 frame=0
 isgameover=nil
 blocks={}
 pxs={}
 rowscore=0
 skipcountdown=0
 comingblocks={
  getnewblocks(),
 }
 while #comingblocks < 2 do
  local _newb=getnewblocks()
  if _newb[1].c != comingblocks[#comingblocks][1].c then
   add(comingblocks,_newb)
  end
 end
end

_init=resetgame

function getminy()
 local _miny=rowcount
 for _b in all(blocks) do
  if _b.y < _miny then
   _miny=_b.y
  end
 end
 return _miny
end

function iscurblockscolliding(_y)
 for _curb in all(comingblocks[1]) do
  if _curb.y+_y == rowcount then
   return true
  end
  for _b in all(blocks) do
   if _curb.x+fallingblockxoff == _b.x and _curb.y+_y == _b.y then
    return true
   end
  end
 end
end

function _update60()

 frame+=1

 if isgameover then
  if btnp(5) then
   resetgame()
  end
  return
 end

 local _keypressed=nil
 if btnp(0) then
  _keypressed,fallingblockxoff=true,0
 end
 if btnp(3) then
  _keypressed,fallingblockxoff=true,1
 end
 if btnp(1) then
  _keypressed,fallingblockxoff=true,2
 end

 if btnp(2) and skipcountdown <= 0 then
  comingblocks[1],comingblocks[2]=comingblocks[2],comingblocks[1]
  skipcountdown=2
 end

 local _colly=-1
 if _keypressed then
  skipcountdown-=1

  while not iscurblockscolliding(_colly) do
   _colly+=1
  end
  
  for _curb in all(comingblocks[1]) do
   local _newb=clone(_curb)
   _newb.y+=_colly-1
   _newb.x+=fallingblockxoff
   add(blocks,_newb)
  end

  comingblocks[1]=comingblocks[2]
  repeat
   comingblocks[2]=getnewblocks()
  until comingblocks[2][1].c != comingblocks[1][1].c

  local _pxs={}

  for _y=0,rowcount-1 do
   local blockrow = {}
   for _b in all(blocks) do
    if _b.y == _y then
     add(blockrow,_b)
    end
   end
   if #blockrow == 4 then

    rowscore+=1

    for _b in all(blockrow) do
     del(blocks,_b)
     _b.durc=2
     add(blinkrow,_b)
    end

    _pxs={}

    for _i=1,18 do
     add(_pxs,{
      x=96,
      y=22+_y*6,
      dur=20,
      durc=20,
      vx=3-rnd(6),
      vy=0,
      colors=pxcolors,
     })
    end

    -- move them down one row
    for _b in all(blocks) do
     if _b.y < _y then
      _b.y=_b.y+1
     end
    end
   end
  end

  for _px in all(_pxs) do
   add(pxs,_px)
  end

  -- check for game over
  for _b in all(blocks) do
   if _b.y < 0 then
    _b.outofbounds = true
    isgameover = true
   end
  end
 end

 -- update particles
 for _p in all(pxs) do
  _p.durc-=1
  if _p.durc <= 0 then
   del(pxs,_p)
  else
   _p.x+=_p.vx
   _p.y+=_p.vy
   _p.vx*=.9
   _p.vy*=.9
  end
 end

 -- update blinkrow
 for _b in all(blinkrow) do
  _b.durc-=1
  if _b.durc <= 0 then
   del(blinkrow,_b)
  end
 end

 if dget(63) < rowscore then
  dset(63,rowscore)
 end
end

function _draw()
 cls()

 local _miny=getminy()
 local _blinkcolor=band(frame,16) != 0 and 7 or 14

 rectfill(84,16,84+23,123,5)
 
 for _i=1,skipcountdown do
  circfill(10+_i*8,18,3,10)
 end

 local _blocksize=4
 for _b in all(blocks) do
  local _screenx,_screeny=84+_b.x*_blocksize,16+_b.y*_blocksize
  rectfill(_screenx,_screeny,_screenx+_blocksize-1,_screeny+_blocksize-1,_b.outofbounds and _blinkcolor or _b.c)
 end

 function drawcomingblocks(_x,_y,_blocks)
  for _b in all(_blocks) do
   local _bx,_by=_x+_b.x*_blocksize,_y+_b.y*_blocksize
   rectfill(_bx,_by,_bx+_blocksize-1,_by+_blocksize-1,_b.c)
  end
 end
 
 for _i,_blocks in ipairs(comingblocks) do
  drawcomingblocks(90+_i*-34,8+_miny*6,_blocks)
 end

 for _b in all(blinkrow) do
  local _screenx,_screeny=84+_b.x*_blocksize,16+_b.y*_blocksize
  rectfill(_screenx,_screeny,_screenx+_blocksize-1,_screeny+_blocksize-1,7)
 end

 for _p in all(pxs) do
  pset(_p.x,_p.y,getpxcolor(_p))
 end

 ?dget(63)..'\n'..rowscore,1,1,10

 if isgameover then
  ?'  game over\n❎ to restart',30,64,_blinkcolor
 end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
