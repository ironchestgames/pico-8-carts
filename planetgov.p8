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

function shift(_t)
 local _t1=_t[1]
 del(_t,_t1)
 return _t1
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

surfacecols=s2t'2;3;6;7;8;9;10;11;12;13;14;15;'
-- 1 is only shadows
-- 4 is pollution
-- 5 is buildings
function genmap(_z,_w)
 local _q=rnd(1)
 local _d=1500+rnd(2000)
 local _v=rnd(1)
 local _j=100+rnd(200)
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
 -- discsize=45 -- biggest
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

 tyear=mapheight_2/rotationspeed

 genmap(mapheight_2,mapheight)
end

t=0
seed=rnd()
stars={}
colshade=s2t'1;1;1;2;1;13;6;2;4;4;3;13;1;2;4;'

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

function perfsel(cur,items)
 local _closestd=999
 local _closest=nil
 for _i in all(items) do
  if _i != cur then
   local _a=atan2(_i[2]-cur[2],_i[3]-cur[3])%1
   local _d=dist(_i[2],_i[3],cur[2],cur[3])
   -- if (btnp(3)) debug(_a,_d,_closestd)
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

values={
 wealth=0.1,
 man_wealth=6,
 sup_wealth=0,
 poverty=0.1,
 man_poverty=6,
 sup_poverty=5,
 pollution=0.1,
 man_pollution=6,
 sup_pollution=5,
 leftism=0.1,
 man_leftism=6,
 sup_leftism=0,
 rightism=0.1,
 man_rightism=6,
 sup_rightism=0,
 favors=0,
}

year=0
quart=1

comingevents={
 -- {
 --  q=2,
 --  t='ambassador',
 --  text='ambassador from _\nis kindly inviting you to\ncontribute to relief efforts\nfrom climate catastrophe.',
 --  effects={
 --   {t='wealth',v=0.05,text='^b+5% wealth'},
 --   {t='sup_rightism',v=-1,text='^c-1 support'},
 --   {t='favors',v=1,text='^f+1 favors'},
 --  }
 -- }
 {
  q=1,
  t='ambassador',
  text='ambassador from _\nis kindly inviting you to\nbuy waste products to\nprevent climate catastrophe',
  effects={
   {t='wealth',v=0.05,text='^b+5% wealth'},
   {t='sup_pollution',v=-1,text='^4-1 support'},
   {t='favors',v=1,text='^f+1 favors'},
  }
 }
}

ships={}

function drawbar(_xoff,_yoff,_col,_val)
 rect(_xoff,_yoff,_xoff+36,_yoff+4,_col)
 rectfill(_xoff,_yoff,_xoff+36*_val,_yoff+4,_col)
end

function drawextrem(_xoff,_yoff,_leftism,_rightism)
 rect(_xoff,_yoff,_xoff+17,_yoff+4,8)
 rectfill(_xoff,_yoff,_xoff+17*_leftism,_yoff+4,8)

 rect(_xoff+19,_yoff,_xoff+20+16,_yoff+4,12)
 rectfill(_xoff+19,_yoff,_xoff+20+16*_rightism,_yoff+4,12)
end

dialogs={
 planet={
  name='planet',
  selitems={
   {function() setdialog('overview') end,0,1,'overview'},
   {function() debug('new project') end,0,2,'new project'},
   {function() debug('projects') end,0,3,'projects'},
   {function() debug('relations') end,0,4,'relations'},
   {function() debug('budget') end,0,5,'budget'},
  },
  r={5,41,58,83},
 },
 overview={
  name='overview',
  selitems={},
  r={4,16,123,123},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print(planetname,64-#planetname*2,_yoff,13)
   
   _yoff+=5+7
   _xoff=123-5-37
   print('wealth',4+3,_yoff,13)
   drawbar(_xoff,_yoff,11,values.wealth)
   
   _yoff+=5+3
   print('poverty',4+3,_yoff,13)
   drawbar(_xoff,_yoff,9,values.poverty)

   _yoff+=5+3
   print('pollution',4+3,_yoff,13)
   drawbar(_xoff,_yoff,4,values.pollution)

   _yoff+=5+3
   print('extremism',4+3,_yoff,13)
   drawextrem(_xoff,_yoff,values.leftism,values.rightism)

   _yoff+=5+3
   print('congress',4+3,_yoff,13)
   local _s='^b'..values.sup_wealth..' ^9'..values.sup_poverty..' ^4'..values.sup_pollution..' ^8'..values.sup_leftism..' ^c'..values.sup_rightism
   printc(_s,123-4-(#_s-10)*4,_yoff)

   _yoff+=5+4
   local _man=values.man_wealth
   local _mans={values.man_poverty,values.man_pollution,values.man_leftism,values.man_rightism,10}
   local _sup=values.sup_wealth
   local _sups={values.sup_poverty,values.sup_pollution,values.sup_leftism,values.sup_rightism,0}
   local _col=11
   local _cols={9,4,8,12,5}
   for _i=1,33 do
    local _i1=_i-1
    local _x,_y=123-38+flr(_i1/3)*3,_yoff+(_i1%3)*3

    if _man <= 0 then
     _man=shift(_mans)
     _sup=shift(_sups)
     _col=shift(_cols)
    end

    if _sup > 0 then
     rectfill(_x-1,_y-1,_x+1,_y+1,13)
    end

    pset(_x,_y,_col)

    _man-=1
    _sup-=1
   end

   _yoff+=11
   print('favors',4+3,_yoff,13)
   print(values.favors,_xoff,_yoff,15)

   _yoff+=5+3
   print('military',4+3,_yoff,13)
   -- draw military icons
  end,
 },
 ambassador={
  name='ambassador',
  selitems={
   {function(_dialog)
     for _i=1,#_dialog.obj.effects do
      local _e=_dialog.obj.effects[_i]
      values[_e.t]+=_e.v
     end
    end,0,1,'agree'},
   {function() debug('refuse') end,0,2,'refuse'},
  },
  r={4,16,123,123},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print(_dialog.obj.text,4+3,_yoff,13)
   
   _yoff+=23+7
   for _i=1,#_dialog.obj.effects do
    local _e=_dialog.obj.effects[_i]
    printc(_e.text,4+3,_yoff)
    -- local _prefix=sub(_e,1,3)
    -- if _prefix != 'sup' then
    --  drawbar(_xoff,_yoff,11,_e.v)
    -- end

    _yoff+=5+3
   end

  end,
 }
}

dialog=nil

function setdialog(name,obj)
 dialog=dialogs[name]
 dialog.sel=dialog.selitems[1]
 dialog.obj=obj
end

sel=nil
function gameupdate()
 if dialog then
  if dialog.sel then
   dialog.sel=perfsel(dialog.sel,dialog.selitems)
   if btnp(4) then
    dialog.sel[1](dialog)
   end
  end
  if btnp(5) then
   dialog=nil
  end
 else
  sel=perfsel(sel,selitems)
  if btnp(4) then
   sel[4]()
  end
  -- todo: x to quick-select planet?
 end

 if ispaused then
  return
 end
 updatestars()

 t+=1
 t=t%tyear

 if t <= 1 then
  year+=1
  if year%4 == 0 then
   local _b8=values.wealth+values.poverty+values.pollution+values.leftism+values.rightism
   local _mandates=function(_max, _value) return max(_max,flr(_value/_b8*33)) end

   values.man_wealth=_mandates(1,values.wealth)
   values.sup_wealth=flr(values.man_wealth*values.wealth)

   values.man_poverty=_mandates(1,values.poverty)
   values.sup_poverty=flr(values.man_poverty*(1-values.poverty))

   values.man_pollution=_mandates(1,values.pollution)
   values.sup_pollution=flr(values.man_pollution*(1-values.pollution))

   values.man_leftism=_mandates(2,values.leftism)
   values.sup_leftism=flr(values.man_leftism*values.leftism)

   values.man_rightism=_mandates(2,values.rightism)
   values.sup_rightism=flr(values.man_rightism*values.rightism)

   -- todo: open new-budget dialog
   
   -- ispaused=true
  end
 end
 quart=ceil((t%tyear)/(tyear/4))

 local _event
 for _e in all(comingevents) do
  if _e.q == quart then
   del(comingevents,_e)
   if _e.t == 'ambassador' then
    _e[1]=6
    _e[2]=16
    _e[3]=30
    _e[4]=function() setdialog('ambassador',_e) end
    add(ships,_e)
    add(selitems,_e)
   end

   break -- only one event each quart
  end
 end
 
end

function gamedraw()
 cls()
 drawstarsplanet()

 printc('^dy^6'..year..'^dq^6'..quart,2,1)
 local _s='^b'..values.sup_wealth..' ^9'..values.sup_poverty..' ^4'..values.sup_pollution..' ^8'..values.sup_leftism..' ^c'..values.sup_rightism..' ^f'..values.favors
 printc(_s,127-(#_s-12)*4,1)
    
 circ(sel[2],sel[3],sel[1],7)

 if dialog then
  print('\x97',dialog.r[1],dialog.r[2]-6,13)
  rectfill(dialog.r[1],dialog.r[2],dialog.r[3],dialog.r[4],1)

  if dialog.draw then
   dialog.draw(dialog)
  end

  for _i in all(dialog.selitems) do
   local _c=13
   local y=dialog.r[4]-(#dialog.selitems-_i[3]+1)*8+1
   if dialog.sel==_i then
    rectfill(dialog.r[1]+3,y-1,dialog.r[3]-3,y+5,_c)
    _c=7
   end
   print(_i[4],10+_i[2],y,_c)


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
 end

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end
end

function gameinit()
 t=0
 _update,_draw=gameupdate,gamedraw
 selitems={
  {discsize_h,left_ds-discsize_h,top_ds-discsize_h,curry(setdialog,'planet')},
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
  gameinit()
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
 local _cols={[false]=6,[true]=7}
 print('\x8b',10,62,_cols[leftd])
 print('\x91',111,62,_cols[rightd])
end

function startinit()
 t=0
 newplanet(seed)
 _update,_draw=startupdate,startdraw
end

_init=function()
 startinit()
end
