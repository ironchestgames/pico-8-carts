pico-8 cartridge // http://www.pico-8.com
version 38
__lua__


printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

pal(0,129,1)
pal(split'1,2,139,141,5,6,7,8,9,10,138,12,13,14,136',1)

-- utils
local function shuffle(_l,_len)
 for _i=_len,2,-1 do
  local _j=flr(rnd(_i))+1
  _l[_i],_l[_j]=_l[_j],_l[_i]
 end
 return _l
end

local function dist(_x1,_y1,_x2,_y2)
 local _dx,_dy=(_x2-_x1)*.1,(_y2-_y1)*.1
 return sqrt(_dx*_dx+_dy*_dy)*10
end


-- helpers
local function drawcloak(_ship)
 palt(0,false)
 fillp(rnd()*32767)
 circfill(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,1)
 circfill(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,0)
 fillp()
 palt(0,true)
end

local function drawshield(_ship)
 circ(_ship.x,_ship.y,6,1)
 fillp(rnd()*32767)
 circ(_ship.x+rnd()*2-1,_ship.y+rnd()*2-1,6,12)
 fillp()
end

local function getclosest(_x,_y,_list)
 local _closest=_list[1]
 local _closestlen=300
 for _obj in all(_list) do
  local _dist=dist(_x,_y,_obj.x,_obj.y)
  if _dist < _closestlen then
   _closestlen=_dist
   _closest=_obj
  end
 end
 return _closest
end

local function updateship(_ship)
 local _playerindex=_ship.playerindex
 local _newx,_newy=_ship.x,_ship.y

 _ship.spd=1
 if _ship.boost then
  _ship.spd=2
 end
 
 if btn(0,_playerindex) then
  _newx+=-_ship.spd
 end
 if btn(1,_playerindex) then
  _newx+=_ship.spd
 end
 if btn(2,_playerindex) then
  _newy+=-_ship.spd
 end
 if btn(3,_playerindex) then
  _newy+=_ship.spd
 end
 
 _ship.x=mid(4,_newx,124)
 _ship.y=mid(4,_newy,119)
 
 -- _ship fire
 _ship.frame=0
 if btn(4,_playerindex) then
  _ship.firetim-=1

  _ship.passivecount+=0.125
  _ship[_ship.passive]=nil

  if _ship.firetim <= 1 then
   add(bullets,{x=_ship.x+_ship.boffs[1],y=_ship.y+_ship.boffs[3],spdx=0,spdy=-3,s=45,friendly=true})
   add(bullets,{x=_ship.x+_ship.boffs[2],y=_ship.y+_ship.boffs[3],spdx=0,spdy=-3,s=45,friendly=true})
   _ship.firetim=_ship.firespd
   _ship.frame=1
  end
 else
  _ship.firetim=0

  if _ship.hp > 1 and _ship.passivecount > 0 then
   _ship[_ship.passive]=true
   _ship.passivecount-=0.5
  else
   _ship[_ship.passive]=nil
  end
 end

 _ship.passivecount=mid(0,_ship.passivecount,120)
end

ships={}
bullets={}

local enemyupdate={
 [16]=function(_e)
  newenemyexhaustp(_e.x-3,_e.y-3)
  newenemyexhaustp(_e.x-2,_e.y-3)
  newenemyexhaustp(_e.x+1,_e.y-3)
  newenemyexhaustp(_e.x+2,_e.y-3)

  _e.c+=1

  _e.dx+=mid(-1,_e.target.x-_e.x,1)*0.025*(_e.ifactor*0.5)
  _e.dx*=0.98

  if _e.c >= 80 then
   add(bullets,{x=_e.x,y=_e.y+4,spdx=0,spdy=2,s=46})
   _e.c=0
  end
  if _e.y > _e.target.y then
   _e.dy*=1.04
  end
 end,
 [18]=function(_e)
  newenemyexhaustp(_e.x-1,_e.y-2)

  _e.c+=1

  local _a=atan2(_e.target.x-_e.x,_e.target.y-_e.y)
  _e.dx=cos(_a)*0.5
  _e.dy+=0.011+(_e.ifactor*0.003)

  if _e.y < -8 then
   _e.dy=0.5
  end
 end,
 [32]=function(_e)
  newenemyexhaustp(_e.x-3,_e.y-8)
  newenemyexhaustp(_e.x-2,_e.y-8)
  newenemyexhaustp(_e.x+1,_e.y-8)
  newenemyexhaustp(_e.x+2,_e.y-8)

  if not _e.gx then
   _e.gx=_e.target.x
   _e.gy=_e.target.y
  end

  local _dx=_e.x-_e.gx
  local _dy=_e.y-_e.gy
  if sqrt(_dx^2+_dy^2) < 8 then
   _e.dx=0
   _e.dy=0
   if _e.c == 10 then
    local _a=atan2(_e.target.x-_e.x,_e.target.y-_e.y)
    add(bullets,{x=_e.x,y=_e.y,spdx=cos(_a),spdy=sin(_a),s=47})
   end
  end

  if _e.c <= 0 then
   _e.gx=8+rnd()*120
   _e.gy=8+rnd()*110
   local _a=atan2(_e.gx-_e.x,_e.gy-_e.y)
   _e.dx=cos(_a)*0.75
   _e.dy=sin(_a)*0.75
   _e.c=60+flr(rnd()*100)
  end

  _e.c-=1

 end,
}

local spawnqueue={}
local types={18,16,18,18,18}
local enemyhps={[16]=14,[18]=4,[20]=36}

local enemies={}

local stars={}
for i=1,100 do
 add(stars,{
  x=flr(rnd()*128),
  y=flr(rnd()*128),
  spd=rnd()*2+0.5,
 })
end

local ps={}

local bulletcolors={9,4}
local enemybulletcolors={11,3}

local enemyexhaustcolors={7,10,11}
function newenemyexhaustp(_x,_y)
 local _life=rnd()*2+1
 add(ps,{
  x=_x,
  y=_y,
  r=0.1,
  spdx=0,
  spdy=-rnd(),
  spdr=0,
  colors=enemyexhaustcolors,
  life=_life,
  lifec=_life,
 })
end

local exhaustcolors={7,12,1}
local boostexhaustcolors={10,9,8}
function newexhaustp(_x,_y,_colors)
 local _life=rnd()*2+3
 add(ps,{
  x=_x,
  y=_y,
  r=0.1,
  spdx=(rnd()-0.5)*0.01,
  spdy=0.1+rnd()-0.1,
  spdr=0,
  colors=_colors or exhaustcolors,
  life=_life,
  lifec=_life,
 })
end

local smokecolors={5}
local function explosionsmoke(_x,_y)
 local _life=rnd()*10+25
 add(ps,{
  x=_x,
  y=_y,
  r=8,
  spdx=(rnd()-0.5),
  spdy=rnd()-1.22,
  spdr=-0.28,
  colors=smokecolors,
  life=_life,
  lifec=_life,
 })
end

local explosioncolors={7,7,10,9,8}
local function newexplosion(_x,_y)
 for _i=1,7 do
  local _life=11
  add(ps,{
   x=_x,
   y=_y,
   r=rnd()*5,
   spdx=(rnd()-0.5),
   spdy=rnd()-1,
   spdr=rnd()*0.2+0.5,
   colors=explosioncolors,
   life=_life,
   lifec=_life,
   ondeath=explosionsmoke,
  })
 end
end

local hitcolors={7,7,10}
local function newhit(_x,_y)
 for _i=1,7 do
  local _life=4
  add(ps,{
   x=_x+(rnd()-0.5)*5,
   y=_y+(rnd()-0.5)*5,
   r=rnd()*5,
   spdx=(rnd()-0.5)*2,
   spdy=rnd()-0.5,
   spdr=-0.2,
   colors=hitcolors,
   life=_life,
   lifec=_life,
  })
 end
end

local burningcolors={10,9,5}
local function newburningp(_x,_y,_ydir)
 local _life=8+rnd()*4
 add(ps,{
  x=_x,
  y=_y,
  r=0.5,
  spdx=(rnd()-0.5)*0.125,
  spdy=(rnd()*0.25+1)*_ydir,
  spdr=0.25*rnd(),
  colors=burningcolors,
  life=_life,
  lifec=_life,
 })
end

local isgameover
local function gamescene()
 _update60=function()

  -- spawn new
  if #enemies == 0 and spawnqueue[60] == nil then
   for _i=1,25 do
    local _typ=shuffle(types,#types)[1]
    add(spawnqueue,{
     typ=_typ,
     x=rnd()*128,y=-16,
     dy=0.5,dx=0,
     c=0,
     hp=enemyhps[_typ],
     f=enemyupdate[_typ],
     ifactor=rnd(),
    })
   end

   shuffle(spawnqueue,60)

   -- boss
   spawnqueue[60]={
    typ=1,
    isboss=true,
    x=rnd()*128,y=-16,
    dy=0.5,dx=0,
    c=0,
    hp=100,
    f=enemyupdate[32],
    ifactor=rnd(),
   }
  end

  -- update particles
  shuffle(ps,#ps)
  for _p in all(ps) do
   _p.x+=_p.spdx
   _p.y+=_p.spdy
   _p.r+=_p.spdr
   _p.lifec-=1
   _p.col=_p.colors[flr(#_p.colors*((_p.life-_p.lifec)/_p.life))+1]
   if _p.lifec<0 then
    del(ps,_p)
    if _p.ondeath then
     _p.ondeath(_p.x,_p.y)
    end
   end
  end
  
  if isgameover then
   return
  end

  -- stars
  for _s in all(stars) do
   _s.y+=_s.spd
   if _s.y>130 then
    _s.y=-3
    _s.x=flr(rnd()*128)
   end
  end

  -- spawn enemies
  local _flrt=flr(t()*3)
  if spawnqueue[_flrt] then
   add(enemies,spawnqueue[_flrt])
   spawnqueue[_flrt]=nil
  end
  
  -- ship moving
  for _ship in all(ships) do
   updateship(_ship)
  end

  -- bullets
  for _b in all(bullets) do
   _b.x+=_b.spdx
   _b.y+=_b.spdy

   if _b.friendly then
    local _life=rnd()*4+4
    add(ps,{
     x=_b.x,
     y=_b.y+4,
     r=0.1,
     spdx=0,
     spdy=rnd()*-0.1,
     spdr=0,
     colors=bulletcolors,
     life=_life,
     lifec=_life,
    })
   elseif _b.s == 46 then
    for _i=-1,1 do
     local _life=rnd()*4+4
     add(ps,{
      x=_b.x+_i,
      y=_b.y+4,
      r=0.1,
      spdx=0,
      spdy=rnd()*-0.1,
      spdr=0,
      colors=enemybulletcolors,
      life=_life,
      lifec=_life,
     })
    end
   end

   if _b.friendly then
    for _e in all(enemies) do
     local _dx=_e.x-_b.x
     local _dy=_e.y-_b.y
     if sqrt(_dx^2+_dy^2) < 6 then
      _e.hp-=1
      newhit(_e.x,_e.y)
      del(bullets,_b)
     end
    end
   else
    for _ship in all(ships) do
     local _dx=_ship.x-_b.x
     local _dy=_ship.y-_b.y
     if sqrt(_dx^2+_dy^2) < 6 then
      newexplosion(_ship.x,_ship.y)
      if not _ship.shield then
       _ship.hp-=1
      end
      del(bullets,_b)
     end
    end
   end

   if _b.x<0 or _b.x>128 or _b.y<0 or _b.y>128 then
    del(bullets,_b)
   end
  end

  -- enemies
  for _e in all(enemies) do
   if _e.y == -16 then
    _e.target=getclosest(_e.x,_e.y,ships)
    debug('_e.target')
    debug(_e.target)
   end

   _e.f(_e)
   _e.x+=_e.dx
   _e.y+=_e.dy

   if _e.hp <= 0 then
    newexplosion(_e.x,_e.y)
    del(enemies,_e)
    if _e.isboss then
     newexplosion(_e.x+10,_e.y+10)
     newexplosion(_e.x-10,_e.y+10)
     newexplosion(_e.x-10,_e.y-10)
     newexplosion(_e.x+10,_e.y-10)
    end
   elseif _e.typ == 16 and _e.hp <= 2 then
    newburningp(_e.x,_e.y,-1)
   end

   for _ship in all(ships) do
    local _dx=_ship.x-_e.x
    local _dy=_ship.y-_e.y
    if sqrt(_dx^2+_dy^2) < 6 and not _ship.cloak then
     newexplosion(_ship.x,_ship.y)
     _ship.hp=0
     del(enemies,_e)
    end
   end

   if _e.y > 132 then
    _e.y=-16
    _e.dy=0.25
    _e.x+=(rnd()-0.5)*5
    _e.c=0
   end
  end

  for _ship in all(ships) do
   if _ship.boost then
    newexhaustp(_ship.x,_ship.y+4,boostexhaustcolors)
    newexhaustp(_ship.x,_ship.y+4,boostexhaustcolors)
   elseif _ship.passive == 'cloak' then
    newexhaustp(_ship.x+2,_ship.y+4)
    newexhaustp(_ship.x+2,_ship.y+4)
    newexhaustp(_ship.x-2,_ship.y+4)
    newexhaustp(_ship.x-2,_ship.y+4)
   else
    newexhaustp(_ship.x,_ship.y+4)
    newexhaustp(_ship.x,_ship.y+4)
   end

   if _ship.hp == 1 then
    newburningp(_ship.x-2,_ship.y+2,1)
   elseif _ship.hp <= 0 then
    del(ships,_ship)
   end
  end

  if #ships == 0 then
   isgameover=true
  end
 end

 _draw=function()
  cls(0)
  
  -- draw stars
  for _s in all(stars) do
   if _s.spd<=1 then
    pset(_s.x,_s.y,1)
   end
  end

  -- draw ships
  for _ship in all(ships) do
   if _ship.frame == 1 then
    -- todo: fix the thing
    spr(_ship.s,_ship.x-4,_ship.y-4)
   else
    spr(_ship.s,_ship.x-4,_ship.y-4)
   end

   if _ship.cloak then
    drawcloak(_ship)

   elseif _ship.shield then
    drawshield(_ship)
   end
  end

  -- draw enemies
  for _e in all(enemies) do
   if _e.isboss then
    sspr(0,_e.typ*16,16,16,_e.x-8,_e.y-8)
   else
    spr(_e.typ,_e.x-4,_e.y-4)
   end
  end
  
  -- draw bullets
  for _b in all(bullets) do
   spr(_b.s,_b.x-3,_b.y)
  end

  -- draw particles
  for _p in all(ps) do
   circfill(_p.x,_p.y,_p.r,_p.col)
  end

  -- draw gui
  for _i=1,#ships do
   local _ship=ships[_i]
   local _xoff=(_i-1)*62
   if _ship.hp == 1 then
    rect(_xoff+3,123,_xoff+63,127,2)
    print('warning',_xoff+35,123,8+flr(t()*2)%2)

   else
    rectfill(_xoff+3,123,_xoff+63,127,1)
    if _ship.passivecount > 0 then
     rectfill(_xoff+3,123,_xoff+3+(_ship.passivecount/2),127,3)
    end
    local _col=7
    if _ship.cloak or _ship.shield or _ship.boost then
     _col=3+(flr(t()*12)%2)*8
    end
    print(_ship.passive,_xoff+5,123,_col)
   end
  end
 end
end

pickerscene=function()
 local _sel1i=1
 local _sel2i=2
 local _passives={'shield','boost','cloak','phase'}
 ships={}
 _update60=function()
  if btnp(0,0) then
   _sel1i-=1
  elseif btnp(1,0) then
   _sel1i+=1
  end
  _sel1i=mid(1,_sel1i,4)

  if btnp(4,0) then

   local _ship1={x=64,y=110,spd=1,frame=0,firespd=10,firetim=0,passivecount=60,hp=2,passive=_passives[_sel1i],playerindex=0}

   if _ship1.passive == 'shield' then
    _ship1.s=0
    _ship1.boffs={-4,3,-1}
   elseif _ship1.passive == 'boost' then
    _ship1.s=2
    _ship1.boffs={-3,2,-6}
   elseif _ship1.passive == 'cloak' then
    _ship1.s=4
    _ship1.boffs={-2,1,-4}
   elseif _ship1.passive == 'phase' then
    _ship1.s=6
    _ship1.boffs={-3,2,-6}
   end

   add(ships,_ship1)
  end

  if btnp(0,1) then
   _sel2i-=1
  elseif btnp(1,1) then
   _sel2i+=1
  end
  _sel2i=mid(1,_sel2i,4)

  if btnp(4,1) then

   local _ship2={x=64,y=110,spd=1,frame=0,firespd=10,firetim=0,passivecount=60,hp=2,passive=_passives[_sel2i],playerindex=1}

   if _ship2.passive == 'shield' then
    _ship2.s=0
    _ship2.boffs={-4,3,-1}
   elseif _ship2.passive == 'boost' then
    _ship2.s=2
    _ship2.boffs={-3,2,-6}
   elseif _ship2.passive == 'cloak' then
    _ship2.s=4
    _ship2.boffs={-2,1,-4}
   elseif _ship2.passive == 'phase' then
    _ship2.s=6
    _ship2.boffs={-3,2,-6}
   end

   add(ships,_ship2)
  end

  if #ships == 2 then
   gamescene()
  end
 end

 _draw=function()
  cls()
  for _i=0,3 do
   spr(_i*2,32+_i*27,64)
   if _i+1 == _sel1i then
    pset(36+_i*27,60,10)
   end
   if _i+1 == _sel2i then
    pset(36+_i*27,58,11)
   end
   local _s=_passives[_i+1]
   print(_s,26+_i*28,90,10)
  end
 end
end

_init=pickerscene


__gfx__
00099000000770000700007007000070000660000007700000033000000770000000000000000000000000000000000000000000000000000000000000000000
00099000000770007f0000f77700007700d66d0000777700006ab600007777000000000000000000000000000000000000000000000000000000000000000000
000bc000000770007f0000f77700007700defd0000777700073bb370077777700000000000000000000000000000000000000000000000000000000000000000
006cc600007777007f0a90f77707707707dffd7007777770736bb637777777770000000000000000000000000000000000000000000000000000000000000000
006cc600007777007f0990f77707707776dffd6777777777763dd367777777770000000000000000000000000000000000000000000000000000000000000000
7069960770777707ff4994ff7767767776d66d6777777777733dd337777777770000000000000000000000000000000000000000000000000000000000000000
79699697777777776f4ff4f677677677776666777777777773055037770660770000000000000000000000000000000000000000000000000000000000000000
6969969677777777660ff06677077077044004400660066070000007700000070000000000000000000000000000000000000000000000000000000000000000
0005500000055000d000000dd000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0dd0d00d0dd0d0d405504dd405504d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d4dd4d44d4dd4d4d44dd44dd44dd44d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd4dd4dddd4dd4ddd44dd44dd44dd44d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d0bc0d44d0bc0d4d44a944dd44a944d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d0cc0d44d0cc0d40d4994d00d4994d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0000d00d0000d000d99d0000d99d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0000d00d0000d00004400000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000550055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000
000042444424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000bb000
00042424424240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000baab00
0042424224242400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000ba77ab0
002422422422420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0b0000ba77ab0
422422444422422400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aba00000baab00
0424244444424240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007a7000000bb000
04242444444242400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000
0022b444444322000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40042bb4433240040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
224422bb332244220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044b4223322434400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004bb222222334000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004bb220022334000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004b200002340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004400004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
