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

function genmap(z,w)
 ::o::
 q=rnd(1)
 d=1500+rnd(2000)
 v=rnd(1)
 j=100+rnd(250)
 h={}
 for x=0,w*2 do
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
  x=1+flrrnd((w*2)-1)
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
 k=mid(3,flrrnd(6),6)
 c={}
 while k > 0 do
  c[k]=flrrnd(15)+1
  k=k-1
 end
 for x=0,w*2 do
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

newplanet=function(_seed)
 srand(_seed)

 planetname=''
 local namelen=flrrnd(5)+2
 while #planetname <= namelen do
  local cpos=flrrnd(#cons)+1
  local vpos=flrrnd(#vocs)+1
  local l=sub(cons,cpos,cpos)
  if #planetname%2 == 0 then
   l=sub(vocs,vpos,vpos)
  end
  planetname=planetname..l
 end
 if rnd() > 0.25 then
  local n=planetname
  planetname=''
  for l=#n,1,-1 do
   planetname=planetname..sub(n,l,l)
  end
 end
 if rnd() > 0.8 then
  local l=flrrnd(#planetname-1)+1
  planetname=sub(planetname,1,l-1)..sub(planetname,l+1,#planetname)
 end
 if rnd() > 0.65 then
  planetname=planetname..'-'..flrrnd(12)+1
  if rnd() > 0.8 then
   local cpos=flrrnd(#cons)+1
   planetname=planetname..sub(cons,cpos,cpos)
  end
 end

 local c=20
 local starspeed=max(0.03,rnd(0.3))
 while c > 0 do
  stars[c]={flr(rnd(128)),rnd(128),starspeed}
  c=c-1
 end

 discsize=flr((flrrnd(22)+22)/2)*2+1
 -- discsize=32 -- 0.4326
 discsize_h=discsize/2
 discsize_2d=2/discsize
 rotationspeed=rnd(0.11)+0.04
 left=64-discsize_h
 top=left
 shadeleft=64+discsize_h-discsize_h/8
 shadetop=shadeleft
 shadesize=discsize_h-discsize_h/12
 left_ds=left+discsize
 top_ds=top+discsize

 mapheight=discsize
 mapheight_h=mapheight/2
 mapheight_2=mapheight*2

 genmap(mapheight_2,mapheight)
end

updatestars=function()
 for star in all(stars) do
  star[1]=star[1]+star[3]
  if star[1] < 0 then
   star[1]=128
  elseif star[1] > 128 then
   star[1]=0
  end
 end
end

drawstarsplanet=function()
 for star in all(stars) do
  pset(star[1],star[2],1)
 end

 -- iterate over each pixel in the discsize x discsize bounding square
 for x=left,left_ds do
  for y=top,top_ds do

   -- convert pixel position into a vector relative to the center,
   -- normalized into the range -1...1
   local px=(x-left)*discsize_2d-1
   local py=(y-top)*discsize_2d-1
   local pypy=py*py

   -- if we're outside the circle, draw black/background and skip ahead
   if px*px+pypy <= 1 then

    -- warp our local offset vector px py to imitate 3d bulge
    widthatheight=sqrt(1-pypy)
    px=asin(px/widthatheight)*4

    -- convert our local offsets into lookup coordinates into our map texture
    u=t*rotationspeed+(px+1)*mapheight_h
    v=(py+1)*mapheight_h
    -- wrap the horizontal coordinate around our map when it goes off the edge
    u=u%mapheight_2

    -- look up the corresponding colour from the map texture & plot it
    c=sget(u,v)

    -- shade it
    if dist(x+discsize_h,y+discsize_h,shadeleft,shadetop) > shadesize then
     c=colshade[c]
    end

    pset(x,y,c)
   end
  end
 end
end

pop=1000
projects={}

function updategame()
 for p in all(projects) do
  -- todo
 end
end

seed=rnd()
t=0
stars={}
colshade={1,1,1,2,1,13,6,2,4,4,3,13,1,2,4}

selcols={13,13,13}

planetupdate=function()
 t=t+1

 selcols[sel]=13
 if btnp(2) then
  sel=min(sel-1,3)
 elseif btnp(3) then
  sel=max(sel+1,1)
 end
 if btnp(4) then
  if sel == 1 then
   surfaceinit()
  end
 end
 selcols[sel]=7
 
 updatestars()
end

selmar=8
planetdraw=function()
 cls()
 drawstarsplanet()
 print(planetname,64-#planetname*2,2,5)

 print('> surface',8,16,selcols[1])
 print('> ambassador',8,16+7,selcols[2])
 print('> war fleet',8,16+14,selcols[3])
end

planetinit=function()
 _update,_draw,sel,selt=planetupdate,planetdraw,1,75
end


surfaceupdate=function()
 selcols[sel]=13
 if btnp(2) then
  sel=min(sel-1,3)
 elseif btnp(3) then
  sel=max(sel+1,1)
 end
 if btnp(4) then
  if sel == 3 then
   planetinit()
  end
 end
 selcols[sel]=7
end

surfacedraw=function()
 cls(1)

 print(planetname,64-#planetname*2,2,13)
 rect(mapx-1,12-1,mapx+mapheight_2,mapheight+12,0)
 sspr(0,0,mapheight_2,mapheight,mapx,12)
 local offy=mapheight+12+6
 print('> start project',34,offy,selcols[1])
 print('> overview',34,offy+7,selcols[2])
 print('> cancel',34,offy+14,selcols[3])
end

surfaceinit=function()
 _update,_draw=surfaceupdate,surfacedraw
 mapx=(128-mapheight_2)/2
 sel=1
end


startupdate=function()
 t=t+1

 rightd=btn(1)
 leftd=btn(0)

 if btnp(1) then
  seed=seed+1
  newplanet(seed)
 end
 if btnp(0) then
  seed=seed-1
  newplanet(seed)
 end
 if btnp(4) or btnp(5) then
  planetinit()
 end

 updatestars()
end

startdraw=function()
 cls()

 drawstarsplanet()

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end

 print(planetname,64-#planetname*2,16,7)
 print('\x8b',10,62,({[false]=6,[true]=7})[leftd])
 print('\x91',111,62,({[false]=6,[true]=7})[rightd])
 print('')
end

startinit=function()
 newplanet(seed)
 _update,_draw=startupdate,startdraw
end

_init=function()
 startinit()
end

