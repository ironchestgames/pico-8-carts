pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

dev=false
menuitem(1, 'debug', function() dev=not dev end)

printh('debug started','debug',true)
function debug(_s1,_s2,_s3,_s4,_s5,_s6,_s7,_s8)
 local ss={_s2,_s3,_s4,_s5,_s6,_s7,_s8}
 local result=tostr(_s1)
 for s in all(ss) do
  result=result..', '..tostr(s)
 end
 printh(result,'debug',false)
end

-- s2t usage:
-- t=s2t'1;2;3;4;5;6;7;hej pa dig din gamle gries;'
-- t=s2t'.x;1;.y;2;'
function s2t(s)
 local _t,_i,_s,_d={},1,''
 repeat
  _d,s=sub(s,1,1),sub(s,2)
  if _d != ';' then
   _s=_s.._d
  else
   _t[_i]=tonum(_s) or _s
   if (_s == '') _t[_i]=nil
   _i+=1
   _s=''
  end
 until #s == 0
 for _i=2,#_t,2 do
  local _tib=_t[_i-1]
  if sub(tostr(_tib),1,1) == '.' then
   _t[sub(_tib,2)],_t[_i-1],_t[_i]=_t[_i]
  end
 end
 return _t
end

function curry(f,a)
 return function()
  f(a)
 end
end

function clone(_t)
 local _tc={}
 for _k,_v in pairs(_t) do
  _tc[_k]=_v
 end
 return _tc
end

function dist(x1,y1,x2,y2)
 local dx=(x2-x1)*0.1
 local dy=(y2-y1)*0.1
 return sqrt(dx*dx+dy*dy)*10
end

function acos(x)
 return atan2(x,-sqrt(1-x*x))
end

function asin(y)
 return atan2(sqrt(1-y*y),-y)
end

function flrrnd(x)
 return flr(rnd(x))
end

function getnormdist()
 return (rnd()+rnd()+rnd())/3
end

function getsgn(_a)
 if (_a >= 0) return '+'
 return '-'
end

surfacecols=s2t'2;3;5;6;7;8;9;10;11;12;13;14;15;'
function genmap(_z,_w)
 local _q=rnd(1)
 local _d=1500+rnd(2000)
 local _v=rnd(1)
 local _j=100+rnd(250)
 local _h={}
 local _w2=_w*2
 for _x=0,_w2 do
  for _y=0,_w do
   _h[_x+_y*_z]=0
  end
 end
 for _i=0,_j do
  local _x=flrrnd(_z)
  local _y=flrrnd(_z)
  _h[_x+_y*_z]=1
 end
 for _i=0,_d do
  local _x,y=1+flrrnd((_w2)-1),1+flrrnd(_w-1)
  local _m=_x+1
  local _n=_x-1
  local _yz=y*_z
  local _kz=(y-1)*_z
  local _pz=(y+1)*_z
  if _h[_x+_yz] > 0 then
   _h[_x+_yz]+=_v
   _h[_n+_yz]+=_q
   _h[_m+_yz]+=_q
   _h[_x+_kz]+=_q
   _h[_x+_pz]+=_q
   _h[_m+_pz]+=_q
   _h[_m+_kz]+=_q
   _h[_n+_pz]+=_q
   _h[_n+_kz]+=_q
  end
 end
 local _k=mid(3,flrrnd(5),5)
 local _c={}
 repeat
  _c[_k]=surfacecols[flrrnd(#surfacecols)+1]
  _k-=1
 until _k == 0
 for _x=0,_w2 do
  for _y=0,_w do
   local _i=mid(1,flr(_h[_x+_y*_z])+1,#_c)
   local _col=_c[_i]
   sset(_x,_y,_col)
  end
 end
end

vocs='\97\101\105\111\117\121'
cons='\98\99\100\102\103\104\106\107\108\109\110\112\114\115\116\118\119\120\122'
function newplanetname(_seed)
 srand(_seed)
 local _pname=''
 local _l=flrrnd(5)+2
 while #_pname <= _l do
  local _cpos,_vpos=flrrnd(#cons)+1,flrrnd(#vocs)+1
  local _l=sub(cons,_cpos,_cpos)
  if #_pname%2 == 0 then
   _l=sub(vocs,_vpos,_vpos)
  end
  _pname=_pname.._l
 end
 if rnd() > 0.25 then
  local _n=_pname
  _pname=''
  for _l=#_n,1,-1 do
   _pname=_pname..sub(_n,_l,_l)
  end
 end
 if rnd() > 0.9 then
  local _l=flrrnd(#_pname-1)+1
  _pname=sub(_pname,1,_l-1)..sub(_pname,_l+1,#_pname)
 end
 if rnd() > 0.65 then
  _pname=_pname..'-'..flrrnd(12)+1
  if rnd() > 0.8 then
   local _cpos=flrrnd(#cons)+1
   _pname=_pname..sub(cons,_cpos,_cpos)
  end
 end
 return _pname
end

function newplanet(_seed)
 srand(_seed)

 planetname=newplanetname(_seed)

 local _starc=20
 local _starspeed=max(0.04,rnd(0.32))
 while _starc > 0 do
  stars[_starc]={x=flr(rnd(128)),y=rnd(128),dx=_starspeed}
  _starc-=1
 end

 discsize=flr((flrrnd(22)+22)/2)*2+1
 -- discsize=32 -- 0.4326, 0.4187
 discsize_h=discsize/2
 discsize_2d=2/discsize
 rotationspeed=rnd(0.11)+0.04
 left=64-discsize_h
 top=left
 shadeleft=64-discsize_h*0.4
 shadetop=64
 shadesize=discsize*0.58
 left_ds=left+discsize
 top_ds=top+discsize

 mapheight=discsize
 mapheight_h=mapheight/2
 mapheight_2=mapheight*2

 genmap(mapheight_2,mapheight)
end

function updatestars()
 for _s in all(stars) do
  _s.x+=_s.dx
  if _s.x < 0 then
   _s.x=128
  elseif _s.x > 128 then
   _s.x=0
  end
 end
end

function drawstarsplanet()
 for _s in all(stars) do
  pset(_s.x,_s.y,1)
 end

 -- iterate over each pixel in the discsize x discsize bounding square
 for _x=left,left_ds do
  for _y=top,top_ds do

   -- convert pixel position into a vector relative to the center,
   -- normalized into the range -1...1
   local _px=(_x-left)*discsize_2d-1
   local _py=(_y-top)*discsize_2d-1
   local _pypy=_py*_py

   -- if we're outside the circle, draw black/background and skip ahead
   if _px*_px+_pypy <= 1 then

    -- warp our local offset vector _px _py to imitate 3d bulge
    widthatheight=sqrt(1-_pypy)
    _px=asin(_px/widthatheight)*4

    -- convert our local offsets into lookup coordinates into our map texture
    _u=t*rotationspeed+(_px+1)*mapheight_h
    _v=(_py+1)*mapheight_h
    -- wrap the horizontal coordinate around our map when it goes off the edge
    _u=_u%mapheight_2

    -- look up the corresponding colour from the map texture & plot it
    _c=sget(_u,_v)

    -- shade it
    if dist(_x,_y,shadeleft,shadetop) > shadesize then
     _c=colshade[_c]
    end

    pset(_x,_y,_c)
   end
  end
 end

 if dev then
  pset(shadeleft,shadetop,9)
  circ(shadeleft,shadetop,shadesize,10)
 end
end

printc_c='0123456789abcdef'
function printc(t,x,y)
 local l,s,o,i,n=x,7,1,1,#t+1
 while i <=n  do
  local c=sub(t,i,i)
  if c == '^' or c == '' then
   i+=1
   local p=sub(t,o,i-2)
   print(p,l,y,s)
   l+=4*#p
   o=i+1
   c=sub(t,i,i)
   if c=='l' then
    l=x
    y+=6
   else
    for k=1,16 do
     if c==sub(printc_c,k,k) then
      s=k-1
      break
     end
    end
   end
  end
  i+=1
 end
end

projectconfs={
 {
  'social services ',
  t=5,
  update=function(p)
   if p.t >= 0 then
    local v=flr(max(1,pop*0.001))
    p[2]=getsgn(v)..abs(v)..' pop'
    pop_agr+=v
   else
    p.removeme=true
   end
  end,
 }
}

pop=1000
pop_gr=0
pop_agr=0
projects={}

function startproject(_pconf)
 add(projects,clone(_pconf))
 surfaceinit()
end

function updategame()
 t+=1
 if t % 30 != 0 then
  return
 end

 -- organic pop growth
 pop+=pop_gr+pop_agr
 pop_gr=flr((getnormdist()-0.49)*max(1,pop*0.006)+0.5)
 pop_agr=0

 -- update projects
 for _p in all(projects) do
  if _p.hasproblem then
   -- todo
  else
   _p.t-=1
   _p.update(_p)
  end
 end
 for _p in all(projects) do
  if _p.removeme then
   del(projects,_p)
  end
 end
end

seed=rnd()
t=0
stars={}
colshade=s2t'1;1;1;2;1;13;6;2;4;4;3;13;1;2;4;'

function surfaceupdate()
 selitems[sel][3]=nil
 if btnp(2) then
  sel=max(sel-1,1)
 elseif btnp(3) then
  sel=min(sel+1,#selitems)
 end
 if btnp(4) then
  selitems[sel][2]()
 end
 selitems[sel][3]=7

 updategame()
end

function surfacedraw()
 cls(1)
 print(planetname,64-#planetname*2,6,14-1)
 rect(mapx-1,14-1,mapx+mapheight_2,mapheight+14,0)
 sspr(0,0,mapheight_2,mapheight,mapx,14)
 local offy=mapheight+14+6
 for selitem in all(selitems) do
  print(selitem[1],34,offy,selitem[3] or 13)
  offy+=7
 end
end

function surfaceinit()
 _update,_draw=surfaceupdate,surfacedraw
 mapx=(128-mapheight_2)/2
 sel=1
 selitems={
  {'> start project',function()
   sel=1
   selitems={
    {'> '..projectconfs[1][1],curry(startproject,projectconfs[1])},
    {'< back',surfaceinit},
   }
  end},
  {'> overview',overviewinit},
  {'< back',planetinit},
 }
end


sel=nil
function perfsel(cur,items)
 local _closestd=999
 local _closest=nil
 for _i in all(items) do
  if _i != cur then
   local _a=atan2(_i[2]-cur[2],_i[3]-cur[3])%1
   local _d=dist(_i[2],_i[3],cur[2],cur[3])
   if (btnp(3)) debug(_a,_d,_closestd)
   if _d < _closestd and
      ((btnp(0) and _a >= 0.375 and _a <= 0.625) or
       (btnp(1) and (_a >= 0.875 or _a <= 0.125)) or
       (btnp(3) and _a >= 0.55 and _a <= 0.95) or
       (btnp(2) and _a >= 0.05 and _a <= 0.45)) then
    _closestd=_d
    _closest=_i
   end
  end
 end
 return _closest or cur
end

function planetupdate()
 sel=perfsel(sel,selitems)
 if btnp(4) then
  sel[4]()
 end
 
 updategame()
 updatestars()
end

selmar=8
function planetdraw()
 cls()
 drawstarsplanet()
 print(planetname,64-#planetname*2,2,5)

 for _i in all(selitems) do
  local _c=13
  if (sel==_i) _c=7
  print(_i[1],_i[2]-#_i[1]*2,_i[3],_c)

  -- debug draw
  -- pset(_i[2],_i[3],12)

  -- local h=64
  -- local _a=0.05
  -- line(_i[2],_i[3],_i[2]+cos(_a)*h,_i[3]-sin(_a)*h,11)
  -- _a=0.45
  -- line(_i[2],_i[3],_i[2]+cos(_a)*h,_i[3]-sin(_a)*h,11)

  -- _a=0.55
  -- line(_i[2],_i[3],_i[2]+cos(_a)*h,_i[3]-sin(_a)*h,10)
  -- _a=0.95
  -- line(_i[2],_i[3],_i[2]+cos(_a)*h,_i[3]-sin(_a)*h,10)
 end

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end
end

function planetinit()
 _update,_draw=planetupdate,planetdraw
 selitems={
  {'surface',64,25,surfaceinit},
  {'ambassador',22,47,function() end},
  {'war fleet',105,47,function() end},
  {'updates',24,120,function() end},
  {'problems',98,120,function() end},
 }
 sel=selitems[1]
end


function startupdate()
 t+=1

 rightd=btn(1)
 leftd=btn(0)

 if btnp(1) then
  seed+=1
  newplanet(seed)
 end
 if btnp(0) then
  seed-=1
  newplanet(seed)
 end
 if btnp(4) or btnp(5) then
  planetinit()
 end

 updatestars()
end

function startdraw()
 cls()

 drawstarsplanet()

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end

 print(planetname,64-#planetname*2,16,7)
 print('\x8b',10,62,({[false]=6,[true]=7})[leftd])
 print('\x91',111,62,({[false]=6,[true]=7})[rightd])
end

function startinit()
 t=0
 newplanet(seed)
 _update,_draw=startupdate,startdraw
end

_init=function()
 startinit()
end
