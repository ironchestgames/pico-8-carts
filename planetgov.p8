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

function inspect(_t)
 local _s='{\n'
 for _k,_v in pairs(_t) do
  _s=_s..'  '.._k..'='..tostr(_v)..',\n'
 end
 debug(_s..'}')
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
   sset(_x,_y+_w,_col)
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
 -- discsize=44 -- biggest
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
 mapx=64-mapheight_2/2

 tyear=mapheight_2/rotationspeed

 genmap(mapheight_2,mapheight)
end

ts=0
uits=0
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
    _u=ts*rotationspeed+(_px+1)*mapheight_h
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
function printc(_t,_x,_y)
 local l,s,o,i,n=_x,7,1,1,#_t+1
 while i <=n  do
  local c=sub(_t,i,i)
  if c == '^' or c == '' then
   i+=1
   local p=sub(_t,o,i-2)
   print(p,l,_y,s)
   l+=4*#p
   o=i+1
   c=sub(_t,i,i)
   if c=='l' then
    l=_x
    _y+=6
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

function perfsel(_cur,_items)
 local _closestd=999
 local _closest=nil
 for _i in all(_items) do
  if _i != _cur then
   local _a=atan2(_i[1]-_cur[1],_i[2]-_cur[2])%1
   local _d=dist(_i[1],_i[2],_cur[1],_cur[2])
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
 return _closest or _cur
end

valcols={
 wealth=11,
 man_wealth=11,
 sup_wealth=11,
 poverty=9,
 man_poverty=9,
 sup_poverty=9,
 pollution=4,
 man_pollution=4,
 sup_pollution=4,
 leftism=8,
 man_leftism=8,
 sup_leftism=8,
 rightism=12,
 man_rightism=12,
 sup_rightism=12,
 favors=15,
}

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

function canpay(_e)
 local _vtot,_costtot=0,0
 for _v in all(_e) do
  _vtot+=values[_v.t]
  _costtot+=_v.v
 end
 return _vtot+values.favors+_costtot >= 0
end

year=0
quart=1

comingevents={
 --  text='ambassador from _\nis kindly inviting you to\ncontribute to relief efforts\nfrom climate catastrophe.',
 {
  q=1,
  t='ambassador',
  data={
   ships={{0,0,5},{4,4,1},{-6,-8,1},col=6},
   planet='klendathu',
   text='\nis kindly inviting you to\nrelieve his planet of some\nnuclear waste products',
   effects={
    {t='wealth',v=0.05,text='^b+5% wealth'},
    {t='pollution',v=0.02,text='^4+2% pollution'},
    {t='sup_pollution',v=-2,text='^4-2 support'},
    {t='favors',v=1,text='^f+1 favors'},
   },
  },
 },
 {
  t='project',
  q=4,
  data={
   name='interplanetary trading center',
   effects={
    wealth={v=0.01,text='^b+1% wealth'},
    leftism={v=0.01,text='^8+1% leftism'},
   },
   cost={
    {t='sup_leftism',v=-1,text='^8-1 support'},
   },
   cancelcost={
    {t='sup_wealth',v=-3,text='^b-3 support'},
    {t='sup_rightism',v=-2,text='^c-2 support'},
   },
  },
 },
}

opportunites={
 {
  t='project',
  name='rare earth mining complex',
  effects={
   wealth={v=0.03,text='^b+3% wealth'},
   pollution={v=0.04,text='^4+4% pollution'},
  },
  cost={
   {t='sup_pollution',v=-4,text='^4-4 support'},
  },
  cancelcost={
   {t='sup_wealth',v=-4,text='^b-4 support'},
   {t='sup_rightism',v=-1,text='^c-1 support'},
  },
 },
}

projects={}

armadas={}

animating={}

function animatetoclosestcorner(_an)
 local _a=atan2(_an[1],-(_an[2]))
 _a=squareangle(_a)-0.125
 local _dx=cos(_a)
 local _dy=sin(_a)
 _an[1]-=_dx
 _an[2]-=_dy
end

shipsprites={
 {126,126,2},
 {124,126,2},
 {121,125,3},
 {118,125,3},
 {114,124,4},
 {110,124,4},
 {106,124,4},
 {102,124,4},
 {98,124,4},
 {93,123,5},
}

function drawship(_xoff,_yoff,_a,_s,_col)
 local _spr=shipsprites[_s[3]]
 local _sw=_spr[3]
 local _sw_h=_sw/2
 local _fx=false
 local _fy=false
 if _a > 0 and _a <= 0.25 then
  _fx=false
  _fy=false
 elseif _a > 0.25 and _a <= 0.5 then
  _fx=true
  _fy=false
 elseif _a > 0.5 and _a <= 0.75 then
  _fx=true
  _fy=true
 elseif _a > 0.75 and _a <= 1 then
  _fx=false
  _fy=true
 end
 pal(15,_col)
 sspr(
  _spr[1],
  _spr[2],
  _sw,
  _sw,
  _xoff+_s[1]-_sw_h,
  _yoff+_s[2]-_sw_h,
  _sw,_sw,_fx,_fy)
 pal()
end

function drawbar(_xoff,_yoff,_t,_inc)
 local _val=values[_t]
 local _col=valcols[_t]
 local _x2=_xoff+36*_val
 rect(_xoff,_yoff,_xoff+36,_yoff+4,_col)
 rectfill(_xoff,_yoff,_x2,_yoff+4,_col)
 if _inc > 0 then
  rectfill(_x2+1,_yoff+1,max(_x2+1,_x2+36*_inc),_yoff+3,7)
  print('+',_xoff+32,_yoff,6)
 elseif _inc < 0 then
  rectfill(min(_x2,_x2+36*_inc),_yoff+1,_x2,_yoff+3,7)
  print('-',_xoff+2,_yoff,6)
 end
end

function drawextrem(_xoff,_yoff,_leftinc,_rightinc)
 -- todo: do more accurate
 local _lxoff=_xoff+16
 local _x2=_lxoff-16*values.leftism
 rect(_lxoff-16,_yoff,_lxoff+1,_yoff+4,8)
 rectfill(_x2,_yoff,_lxoff,_yoff+4,8)
 if _leftinc > 0 then
  rectfill(min(_x2,_x2-16*_leftinc)-1,_yoff+1,_x2-1,_yoff+3,7)
  print('+',_lxoff-14,_yoff,6)
 elseif _leftinc < 0 then
  rectfill(_x2,_yoff+1,max(_x2,_x2-16*_leftinc),_yoff+2,7)
  print('-',_xoff+11,_yoff,6)
 end

 _xoff+=19
 _x2=_xoff+16*values.rightism
 rect(_xoff,_yoff,_xoff+17,_yoff+4,12)
 rectfill(_xoff+1,_yoff,_x2,_yoff+4,12)
 if _rightinc > 0 then
  rectfill(_x2+1,_yoff+1,max(_x2+1,_x2+16*_rightinc),_yoff+3,7)
  print('+',_xoff+13,_yoff,6)
 elseif _rightinc < 0 then
  rectfill(min(_x2,_x2+16*_rightinc),_yoff+1,_x2,_yoff+3,7)
  print('-',_xoff+2,_yoff,6)
 end

 -- rect(_xoff,_yoff,_xoff+17,_yoff+4,8)
 -- rectfill(_xoff,_yoff,_xoff+17*_leftism,_yoff+4,8)

 -- rect(_xoff+19,_yoff,_xoff+20+16,_yoff+4,12)
 -- rectfill(_xoff+19,_yoff,_xoff+20+16*_rightism,_yoff+4,12)
end

function draweffects(_e,_yoff)
 drawbar(7,_yoff,'wealth',_e.wealth and _e.wealth.v or 0)
 drawbar(7,_yoff+8,'poverty',_e.poverty and _e.poverty.v or 0)
 drawbar(48 ,_yoff,'pollution',_e.pollution and _e.pollution.v or 0)
 drawextrem(48,_yoff+8,_e.leftism and _e.leftism.v or 0,_e.rightism and _e.rightism.v or 0)
end

function drawmenuopt(_t,_r1,_r3,_y,_selected,_disabled)
 local _precol,_pre,_fillcol,_selcol='^d','   ',13,'^7'
 if _disabled then
  _fillcol=5
  _selcol='^1'
 end
 if _selected then
  rectfill(_r1+3,_y-1,_r3-3,_y+5,_fillcol)
  _precol=_selcol
  _pre='\x8e '
 end
 printc(_precol.._pre.._t,_r1+5,_y)
end

function drawmenu(_dialog)
 for _i in all(_dialog.selitems) do
   local _y=_dialog.r[4]-(#_dialog.selitems-_i[2]+1)*8+1
   -- debug(_i[1],_i[2],_i[3])
   drawmenuopt(
    _i[3],
    dialog.r[1],
    dialog.r[3],
    _y,
    _dialog.sel==_i)
   -- if _dialog.sel==_i then
   --  rectfill(_dialog.r[1]+3,_y-1,_dialog.r[3]-3,_y+5,13)
   --  _pre='^7\x8e '
   -- end
   -- printc(_pre.._i[3],10+_i[1],_y)


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

dialogs={

 planet={
  isplay=true,
  selitems={
   {0,1,'overview', onp=function() setdialog('overview') end},
   {0,2,'new project', onp=function()
    local _t={}
    for _i=1,#opportunites do
     local _tmp={_i,0,onp=function(_dialog)
      local _sel=opportunites[_dialog.sel[1]]
      for _i=1,#_sel.cost do
       local _e=_sel.cost[_i]
       local _d=values[_e.t]+_e.v
       if _d < 0 then
        values.favors+=_d
        values[_e.t]=0
       else
        values[_e.t]+=_e.v
       end
      end
      local _selitems={}
      for _x=0,mapheight_2-1 do
       for _y=0,mapheight-1 do
        local _taken=false
        for _p in all(projects) do
         if _p[1] == _x and _p[2] == _y then
          _taken=true
          break
         end
        end
        if not _taken then
         add(_selitems,{_x,_y,onp=function()
          local _o=opportunites[dialogs.newproject.sel[1]]
          _o[1]=_x
          _o[2]=_y
          sset(_x,_y,5)
          del(opportunites,_o)
          _o.onp=function(_dialog) -- note: selitems in projects
           del(projects,_o)
           sset(_x,_y,sget(_x,_y+mapheight))
           dialog=nil
          end
          add(projects,_o)
          dialog=nil
         end})
        end
       end
      end
      dialogs.placehq.selitems=_selitems
      setdialog('placehq')
      dialog.sel=dialog.selitems[flr(#dialog.selitems/3)]
     end}
     _tmp.iscantpay=nil
     if not canpay(opportunites[_i].cost) then
      _tmp.iscantpay=true
      _tmp.onp=function()end
     end
     add(_t,_tmp)
    end
    dialogs.newproject.selitems=_t
    setdialog('newproject')
   end},
   {0,3,'projects', onp=function()
    dialogs.projects.selitems=projects
    setdialog('projects')
   end},
   {0,4,'relations', onp=function() debug('relations') end},
   {0,5,'budget', onp=function() debug('budget') end},
  },
  r={5,41,69,83},
  draw=drawmenu,
 },

 overview={
  isplay=true,
  selitems={},
  r={4,16,123,123},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print(planetname,64-#planetname*2,_yoff,13)

   local _weainc,_povinc,_polinc,_lefinc,_riginc=0,0,0,0,0

   for _p in all(projects) do
    if _p.effects.wealth then
     _weainc+=_p.effects.wealth.v
    end
    if _p.effects.poverty then
     _povinc+=_p.effects.poverty.v
    end
    if _p.effects.pollution then
     _polinc+=_p.effects.pollution.v
    end
    if _p.effects.leftism then
     _lefinc+=_p.effects.leftism.v
    end
    if _p.effects.rightism then
     _riginc+=_p.effects.rightism.v
    end
   end
   
   _yoff+=5+7
   _x1off=4+3
   _x2off=123-5-37
   print('wealth',_x1off,_yoff,13)
   drawbar(_x2off,_yoff,'wealth',_weainc)
   
   _yoff+=5+3
   print('poverty',_x1off,_yoff,13)
   drawbar(_x2off,_yoff,'poverty',_povinc)

   _yoff+=5+3
   print('pollution',_x1off,_yoff,13)
   drawbar(_x2off,_yoff,'pollution',_polinc)

   _yoff+=5+3
   print('extremism',_x1off,_yoff,13)
   drawextrem(_x2off,_yoff,_lefinc,_riginc)

   _yoff+=5+3
   print('congress support',_x1off,_yoff,13)
   local _s='^b'..values.sup_wealth..' ^9'..values.sup_poverty..' ^4'..values.sup_pollution..' ^8'..values.sup_leftism..' ^c'..values.sup_rightism
   printc(_s,123-4-(#_s-10)*4,_yoff)

   _yoff+=5+4
   local _man,_mans=values.man_wealth,{values.man_poverty,values.man_pollution,values.man_leftism,values.man_rightism,33}
   local _sup,_sups=values.sup_wealth,{values.sup_poverty,values.sup_pollution,values.sup_leftism,values.sup_rightism,0}
   local _col,_cols=11,{9,4,8,12,5}
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
   print('favors',_x1off,_yoff,13)
   print(values.favors,_x2off,_yoff,15)

   _yoff+=5+3
   print('military',_x1off,_yoff,13)
   -- todo: draw military icons
  end,
 },

 ambassador={
  selitems={
   {0,1,'agree',onp=function(_dialog)
     if not canpay(sel.effects) then
      debug('not enough support')
      return
     end
     for _i=1,#sel.effects do
      local _e=sel.effects[_i]
      values[_e.t]+=_e.v
     end
     sel.at=60
     sel.animate=animatetoclosestcorner
     del(selitems,sel)
     del(armadas,sel)
     add(animating,sel)
     sel=selitems[1]
     dialog=nil
    end},
   {0,2,'refuse',onp=function() debug('refuse') end},
  },
  r={4,22,123,118},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print('ambassador from '..sel.planet..sel.text,4+3,_yoff,13)
   
   _yoff+=23+7
   for _i=1,#sel.effects do
    local _e=sel.effects[_i]
    printc(_e.text,4+3,_yoff)
    _yoff+=5+3
   end

   drawmenu(_dialog)
  end,
 },

 newproject={
  -- note: selitems in menu onp
  r={4,16,123,123},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print('new project opportunites',4+3,_yoff,13)
   if #opportunites == 0 then
    print('(no opportunites available)',4+3,_yoff+16,13)
    return
   end

   _yoff+=11
   spr(240,7,_yoff)
   spr(241,113,_yoff)

   local _xoff=20
   _yoff+=1
   for _i=1,#opportunites do
    local _x=_xoff+(_i-1)*12
    print(_i,_x,_yoff,13)
    if _dialog.sel[1] == _i then
     rectfill(_x-4,_yoff-1,_x+6,_yoff+5,13)
     print(_i,_x,_yoff,7)
    end
   end

   _yoff+=5+8
   local _o=opportunites[_dialog.sel[1]]
   print(_o.name,4+3,_yoff,13)

   _yoff+=5+7
   local _tmp=_yoff
   print('one-time cost:',4+3,_yoff,13)
   for _i=1,#_o.cost do
    local _c=_o.cost[_i]
    printc(_c.text,72,_yoff)
    _yoff+=5+3
   end
   _yoff=_tmp+16

   print('effects (yearly):',4+3,_yoff,13)

   _yoff+=5+3
   draweffects(_o.effects,_yoff)

   _yoff+=16
   print('cost to cancel:',4+3,_yoff,13)
   for _k,_c in pairs(_o.cancelcost) do
    printc(_c.text,72,_yoff)
    _yoff+=5+3
   end

   local _s='place project hq'
   if _dialog.sel.iscantpay then
    _s='(not enough support)'
   end

   drawmenuopt(
    _s,
    _dialog.r[1],
    _dialog.r[3],
    _dialog.r[4]-7,
    true,
    _dialog.sel.iscantpay)

  end,
 },

 projects={
  r={4,16,123,126},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print('implemented projects',25,_yoff,13)

   _yoff+=3+5+1
   rect(mapx-1,_yoff-1,mapx+mapheight_2,mapheight+_yoff,0)
   sspr(0,0,mapheight_2,mapheight,mapx,_yoff)

   if #projects > 0 then
    pset(mapx+_dialog.sel[1],_yoff-1,7)
    pset(mapx-1,_yoff+_dialog.sel[2],7)
    if uits % 8 > 4 then
     pset(mapx+_dialog.sel[1],_yoff+_dialog.sel[2],7)
    end

    _yoff+=mapheight+4
    print(_dialog.sel.name,4+3,_yoff,13)

    _yoff+=5+3
    draweffects(_dialog.sel.effects,_yoff)

    _yoff+=16
    print('cost to cancel:',4+3,_yoff,13)
    for _k,_c in pairs(_dialog.sel.cancelcost) do
     printc(_c.text,72,_yoff)
     _yoff+=5+3
    end

    drawmenuopt(
     'cancel project',
     _dialog.r[1],
     _dialog.r[3],
     _dialog.r[4]-7,
     true)

   else
    print('(no projects)',38,_yoff+mapheight+4,13)
   end

  end,
 },

 placehq={
  ismandatory=true,
  r={4,16,123,126},
  draw=function(_dialog)
   local _yoff=3+_dialog.r[2]
   print('place project hq for',4+3,_yoff,13)
   _yoff+=1+5
   print(opportunites[dialogs.newproject.sel[1]].name,4+3,_yoff,13)

   _yoff+=3+5+1
   rect(mapx-1,_yoff-1,mapx+mapheight_2,mapheight+_yoff,0)
   sspr(0,0,mapheight_2,mapheight,mapx,_yoff)

   pset(mapx+_dialog.sel[1],_yoff-1,7)
   pset(mapx-1,_yoff+_dialog.sel[2],7)
   local _col=5
   if uits % 8 > 4 then
    _col=7
   end
   pset(mapx+_dialog.sel[1],_yoff+_dialog.sel[2],_col)

   _yoff+=mapheight+5
   local _tmpdialog={
    r=_dialog.r,
    selitems={{0,0,'start project'}}
   }
   _tmpdialog.sel=_tmpdialog.selitems[1]
   drawmenu(_tmpdialog)

  end,
 },
}

dialog=nil

function setdialog(name)
 dialog=dialogs[name]
 dialog.sel=dialog.selitems[1]
 dialog.q=quart
end

sel=nil

function gameupdate()
 uits+=1
 if uits > 32000 then
  uits=0
 end

 if dialog then
  if dialog.sel then
   if band(btnp(),0b1111) != 0 then
    dialog.sel=perfsel(dialog.sel,dialog.selitems)
   end
   if btnp(4) and dialog.sel.onp then
    dialog.sel.onp(dialog)
   end
  end
  if btnp(5) and not dialog.ismandatory then
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

 for _an in all(animating) do
  _an.animate(_an)
  _an.at-=1
  if _an.at <= 0 then
   del(animating,_an)
  end
 end

 local _nextquart=ceil(((ts+1)%tyear)/(tyear/4))

 if dialog and (not dialog.isplay) then
  -- note: never start a new quart if inside dialog.isplay=false/nil
  return
 end

 updatestars()

 ts+=1
 ts=ts%tyear

 if ts <= 1 then
  year+=1

  for _p in all(projects) do
   for _k,_e in pairs(_p.effects) do
    values[_k]=mid(0.1,_e.v+values[_k],0.9)
   end
  end

  if year%1 == 0 then
   local _b8=values.wealth+values.poverty+values.pollution+values.leftism+values.rightism
   local _mandates=function(_max, _value) return max(_max,flr(_value/_b8*33)) end

   values.man_wealth=_mandates(1,values.wealth)
   values.sup_wealth=flr(values.man_wealth*values.wealth)

   values.man_poverty=_mandates(1,values.poverty)
   values.sup_poverty=max(0,flr(values.man_poverty*(0.8-values.poverty)))

   values.man_pollution=_mandates(1,values.pollution)
   values.sup_pollution=max(0,flr(values.man_pollution*(0.8-values.pollution)))

   values.man_leftism=_mandates(2,values.leftism)
   values.sup_leftism=flr(values.man_leftism*values.leftism)

   values.man_rightism=_mandates(2,values.rightism)
   values.sup_rightism=flr(values.man_rightism*values.rightism)

   -- todo: open new-budget dialog

  end
 end
 quart=ceil((ts%tyear)/(tyear/4))

 local _event
 for _e in all(comingevents) do
  if _e.q == quart then
   del(comingevents,_e)
   if _e.t == 'ambassador' then
    local _a=_e.data
    local _cx,_cy,_m=0,0,0
    for _s in all(_a.ships) do
     _cx+=_s[1]
     _cy+=_s[2]
    end
    _cx=_cx/#_a.ships
    _cy=_cy/#_a.ships
    for _s in all(_a.ships) do
     local _sw=shipsprites[_s[3]][3]*2
     _m=max(_m,max(abs(_s[1]-_cx)+_sw,abs(_s[2]-_cy)+_sw))
    end
    _a[1]=_cx+36
    _a[2]=_cy+36
    _a[3]=_m
    _a[4]=function() setdialog('ambassador',_a) end
    add(armadas,_a)
    add(selitems,_a)

   elseif _e.t == 'project' then
    add(opportunites,_e.data)
   end

   break -- note: only one event each quart
  end
 end
 
end

function squareangle(_a)
 -- note: does not work below 0
 return flr(band(_a,0b0.1111111111111111)*4)/4
end

function gamedraw()
 cls()
 drawstarsplanet()

 for _an in all(animating) do
  for _s in all(_an.ships) do
   local _a=atan2(_an[1],-(_an[2]))
   drawship(_an[1],_an[2],_a,_s,_an.ships.col)
   -- todo: draw warp speed effect
  end
 end

 for _ar in all(armadas) do
  for _s in all(_ar.ships) do
   local _a=atan2(_ar[1]-64,-(_ar[2]-64))
   drawship(_ar[1],_ar[2],_a,_s,_ar.ships.col)
  end
 end

 if dialog and (not dialog.isplay) then
  print('y'..year..'q'..quart,2,1,5)
 else
  printc('^dy^6'..year..'^dq^6'..quart,2,1)
 end
 
 local _s='^b'..values.sup_wealth..' ^9'..values.sup_poverty..' ^4'..values.sup_pollution..' ^8'..values.sup_leftism..' ^c'..values.sup_rightism..' ^f'..values.favors
 printc(_s,127-(#_s-12)*4,1)
    
 circ(sel[1],sel[2],sel[3],7)

 if dialog then
  if not dialog.ismandatory then
   print('\x97',dialog.r[1],dialog.r[2]-6,13)
  end
  rectfill(dialog.r[1],dialog.r[2],dialog.r[3],dialog.r[4],1)

  if dialog.draw then
   dialog.draw(dialog)
  end
 end

 if dev then
  print('cpu: '..stat(2),0,0,11) -- note: cpu usage
 end
end

function gameinit()
 ts=0
 _update,_draw=gameupdate,gamedraw
 selitems={
  {left_ds-discsize_h,top_ds-discsize_h,discsize_h,curry(setdialog,'planet')},
 }
 sel=selitems[1]
end


function startupdate()
 ts+=1

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
 ts=0
 newplanet(seed)
 _update,_draw=startupdate,startdraw
end

_init=function()
 startinit()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddd0ddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddd7dd0dd7dddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd7ddd0ddd7ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd7dddd0dddd7dd000000000000000000000000000000000000000000000000000000000000000000000000000000fff00000000000000000000000000000000
ddd7ddd0ddd7ddd000000000000000000000000000000000000000000000000000000000000000000000000000000fffffff00ff00ff00f000f0000000000000
dddd7dd0dd7dddd000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffff0f0fff0f0fff0f000000
ddddddd0ddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000fff00fff0ff000f00ff000f0fff0fffff0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000ff00f000f000f000f000f00f0f00f
