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

function curry(f,a)
 return function()
  f(a)
 end
end

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
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

function genmap(z,w)
 ::o::
 q=rnd(1)
 d=1500+rnd(2000)
 v=rnd(1)
 j=100+rnd(250)
 h={}
 w2=w*2
 for x=0,w2 do
  for y=0,w do
   h[x+y*z]=0
  end
 end
 for i=0,j do
  x=flrrnd(z)
  y=flrrnd(z)
  h[x+y*z]=1
 end
 for i=0,d do
  x=1+flrrnd((w2)-1)
  y=1+flrrnd(w-1)
  p=y+1
  k=y-1   
  m=x+1
  n=x-1
  if h[x+y*z] > 0 then
   h[x+y*z]+=v
   h[n+y*z]+=q
   h[m+y*z]+=q
   h[x+k*z]+=q
   h[x+p*z]+=q
   h[m+p*z]+=q
   h[m+k*z]+=q
   h[n+p*z]+=q
   h[n+k*z]+=q
  end
 end
 u=0
 u+=1
 k=mid(3,flrrnd(5),5)
 c={}
 while k > 0 do
  c[k]=flrrnd(14)+2
  k-=1
 end
 for x=0,w2 do
  for y=0,w do
  i=mid(1,flr(h[x+y*z])+1,#c)
  col=c[i]
  sset(x,y,col)
  end
 end
 if (u>7) goto o
end

vocs='\97\101\105\111\117\121'
cons='\98\99\100\102\103\104\106\107\108\109\110\112\114\115\116\118\119\120\122'

function newplanet(_seed)
 srand(_seed)

 planetname=''
 local length=flrrnd(5)+2
 while #planetname <= length do
  local cpos=flrrnd(#cons)+1
  local vpos=flrrnd(#vocs)+1
  local _l=sub(cons,cpos,cpos)
  if #planetname%2 == 0 then
   _l=sub(vocs,vpos,vpos)
  end
  planetname=planetname.._l
 end
 if rnd() > 0.25 then
  local n=planetname
  planetname=''
  for _l=#n,1,-1 do
   planetname=planetname..sub(n,_l,_l)
  end
 end
 if rnd() > 0.9 then
  local _l=flrrnd(#planetname-1)+1
  planetname=sub(planetname,1,_l-1)..sub(planetname,_l+1,#planetname)
 end
 if rnd() > 0.65 then
  planetname=planetname..'-'..flrrnd(12)+1
  if rnd() > 0.8 then
   local cpos=flrrnd(#cons)+1
   planetname=planetname..sub(cons,cpos,cpos)
  end
 end

 local starc=20
 local starspeed=max(0.03,rnd(0.3))
 while starc > 0 do
  stars[starc]={x=flr(rnd(128)),y=rnd(128),dx=starspeed}
  starc-=1
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
colshade={1,1,1,2,1,13,6,2,4,4,3,13,1,2,4}

function overviewupdate()
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

 selitems={}
 for _p in all(projects) do

 end
 add(selitems,{'< back',surfaceinit})

 updategame()
end

function overviewdraw()
 cls(1)
 print(planetname,64-#planetname*2,6,14-1)
 local offy=16
 local s='pop: '..tostr(pop)..' '..getsgn(pop_gr)..tostr(abs(pop_gr))
 print(s,4,offy,13)
 print(' '..getsgn(pop_agr)..tostr(abs(pop_agr)),4+#s*4,offy,6)

 offy+=12
 for _p in all(projects) do
  print(_p[1],4,offy,13)
  print(_p[2],4+#_p[1]*4,offy,6)
  offy+=7
 end

 offy=121
 for selitem in all(selitems) do
  print(selitem[1],4,offy,selitem[3] or 13)
  offy+=7
 end
end

function overviewinit()
 _update,_draw=overviewupdate,overviewdraw
 sel=1
 selitems={{}}
end

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


function planetupdate()
 selitems[max(sel,1)][5]=13
 if btnp(2) then
  sel=max(sel-2,0)
 elseif btnp(3) then
  sel=min(sel+2,5)
 end
 if btnp(0) then
  sel=flr(sel/2)*2
 elseif btnp(1) then
  sel=flr(sel/2)*2+1
 end
 if btnp(4) then
  selitems[max(sel,1)][2]()
 end
 selitems[max(sel,1)][5]=7
 
 updategame()
 updatestars()
end

selmar=8
function planetdraw()
 cls()
 drawstarsplanet()
 print(planetname,64-#planetname*2,2,5)

 for selitem in all(selitems) do
  print(selitem[1],selitem[2],selitem[3],selitem[5] or 13)
 end

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end
end

function planetinit()
 _update,_draw=planetupdate,planetdraw
 sel=1
 selitems={
  {'surface',51,25,surfaceinit},
  {'ambassador',4,47,function() end},
  {'war fleet',88,47,function() end},
  {'updates',8,120,function() end},
  {'problems',74,120,function() end},
 }
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
