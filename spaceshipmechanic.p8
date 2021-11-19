pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

-- note: custom font
poke(0x5600,unpack(split"4,4,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,6,3,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,2,2,4,0,0,0,0,1,2,2,1,0,0,0,0,5,2,5,0,0,0,0,0,0,2,7,2,0,0,0,0,0,0,2,1,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,1,0,0,0,0,4,2,2,1,0,0,0,0,7,5,5,7,0,0,0,0,3,2,2,7,0,0,0,0,7,4,1,7,0,0,0,0,7,6,4,7,0,0,0,0,5,5,7,4,0,0,0,0,7,1,4,7,0,0,0,0,7,1,5,7,0,0,0,0,7,4,4,4,0,0,0,0,7,7,5,7,0,0,0,0,7,5,4,7,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,7,0,0,0,0,0,0,0,0,0,0,0,0,7,4,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,2,2,6,0,0,0,0,1,2,2,4,0,0,0,0,3,2,2,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,0,0,0,7,5,7,5,0,0,0,0,3,7,5,7,0,0,0,0,7,1,1,7,0,0,0,0,3,5,5,7,0,0,0,0,7,1,3,7,0,0,0,0,7,1,3,1,0,0,0,0,7,1,5,7,0,0,0,0,5,5,7,5,0,0,0,0,7,2,2,7,0,0,0,0,7,4,4,3,0,0,0,0,5,3,5,5,0,0,0,0,1,1,1,7,0,0,0,0,7,7,5,5,0,0,0,0,3,5,5,5,0,0,0,0,7,5,5,7,0,0,0,0,7,5,7,1,0,0,0,0,2,5,7,6,0,0,0,0,7,5,3,5,0,0,0,0,7,3,4,7,0,0,0,0,7,2,2,2,0,0,0,0,5,5,5,7,0,0,0,0,5,5,7,2,0,0,0,0,5,5,7,7,0,0,0,0,5,2,5,5,0,0,0,0,5,7,4,7,0,0,0,0,7,6,1,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,7,2,5,0,0,0,0,0,0,0,0,0,0,0,0,4,7,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,1,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,7,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,2,5,0,0,0,0,0"))
poke(0x5f58,0x81) -- note: always print w custom font

btn2symbol={[0]='\x8b','\x91','\x94','\x83','\x8e','\x97'}
status2col={ok=11,problem=9,blocked=8,off=1}

function clone(_t)
 local t={}
 for k,v in pairs(_t) do
  t[k]=v
 end
 return t
end

function newrandombtn(_except)
 local _result={0,1,2,3,4,5}
 for _e in all(_except) do
  del(_result,_e)
 end
 return _result[flr(rnd(#_result))+1]
end

function drawbase(_obj)
 local _offx,_offy=_obj.x,_obj.y
 rectfill(_offx,_offy,_offx+_obj.w-1,_offy+_obj.h-1,13)

 local _col=6
 if _obj == curpanel then
  _col=7
 end
 for _i=1,#_obj.entrycode do
  local _b=_obj.entrycode[_i]
  print(btn2symbol[_b],_offx+1+(_i-1)*4,_offy+1,_col)
 end

 _col=status2col[_obj.status]
 if _obj.blink > 0 and _obj.blink % 8 >= 4 then
  _col=1
 end
 rectfill(_offx+_obj.w-4,_offy+1,_offx+_obj.w-2,_offy+3,_col)

 return _offx,_offy
end

funs={
 -- codeinput={
 --  input=function(_obj)
 --   local _nextb=_obj.code[_obj.pos]
 --   if _obj.pos < 6 and btnp(_nextb) then
 --    _obj.pos+=1
 --   end
 --  end,
 --  update=function(_obj)
 --   _obj.c-=1
 --   if _obj.status == 'ok' then
 --    if _obj.c == 0 then
 --     _obj.status='problem'
 --     _obj.pos=1
 --    end
 --   elseif _obj.status == 'problem' then
 --    if _obj.pos == 6 then
 --     _obj.status='ok'
 --     _obj.c=3000
 --     _obj.blink=30
 --    end
 --   end
 --  end,
 --  draw=function(_obj)
 --   local _offx,_offy=drawbase(_obj)
 --   rectfill(_offx+2,_offy+6,_offx+22,_offy+12,1)

 --   local _s=''
 --   for _c in all(_obj.code) do
 --    _s=_s..btn2symbol[_c]
 --   end
 --   print(_s,_offx+3,_offy+7,11)

 --   _s=''
 --   local _i=1
 --   while _i < _obj.pos do
 --    local _c=_obj.code[_i]
 --    _s=_s..btn2symbol[_c]
 --    _i+=1
 --   end
 --   local _col=3
 --   if _obj.blink > 0 and _obj.blink % 8 >= 4 then
 --    _col=11
 --   elseif _obj.status == 'ok' then
 --    _col=1
 --   end
 --   print(_s,_offx+3,_offy+7,_col)

 --   if _obj.pos < 6 then
 --    print('_',_offx+3+(_obj.pos-1)*4,_offy+8,11)
 --   end
 --  end,
 -- },

 powergen={
  init=function(_obj)
   _obj.b={}
  end,
  input=function(_obj)
  end,
  update=function(_obj)
   _obj.power=400
   local _cnodepow=_obj.power/#_obj.cnodes
   for _i=1,#_obj.cnodes do
    _obj.cnodepows[_i]=_cnodepow
   end
  end,
  draw=function(_obj)
   drawbase(_obj)
  end,
 },

 pulseshow={
  init=function(_obj)
   _obj.b=newrandombtn(_obj.entrycode)
  end,
  input=function(_obj)
   
  end,
  update=function(_obj)
   local _cnodepow=_obj.power/#_obj.cnodes
   for _i=1,#_obj.cnodes do
    _obj.cnodepows[_i]=_cnodepow
   end
   _obj.power-=1
  end,
  draw=function(_obj)
   local _offx,_offy=drawbase(_obj)

   print(_obj.power,_offx+2,_offy+7,11)
  end,
 },

 -- onoffbutton={
 --  init=function(_obj)
 --   _obj.b=newrandombtn(_obj.entrycode)
 --  end,
 --  input=function(_obj)
 --   if btnp(_obj.b) then
 --    -- if _obj.status == 'ok' then
 --    --  _obj.status='problem'
 --    -- elseif _obj.status == 'problem' then
 --    --  _obj.status='ok'
 --    -- end
 --   end
 --  end,
 --  update=function(_obj)
 --   -- if _obj.inflow < 1 then
 --   --  _obj.status='problem'
 --   -- elseif _obj.outflow < 1 then
 --   --  _obj.status='ok'
 --   -- end
 --  end,
 --  draw=function(_obj)
 --   local _offx,_offy=drawbase(_obj)

 --   print(btn2symbol[_obj.b],_offx+2,_offy+7,6)
 --   rectfill(_offx+6,_offy+6,_offx+10,_offy+10,1)

 --   local _col=1
 --   if _obj.status == 'ok' then
 --    _col=11
 --   end
 --   rectfill(_offx+7,_offy+7,_offx+9,_offy+9,_col)
 --  end,
 -- },

 -- channelbuttons={
 --  init=function(_obj)
 --   _obj.s={}
 --   _obj.b={}
 --   for _i=1,#_obj.inlinks do
 --    _obj.s[_i]=false
 --    local _except=clone(_obj.b)
 --    add(_except,_obj.entrycode[1])
 --    _obj.b[_i]=newrandombtn(_except)
 --   end
 --  end,
 --  input=function(_obj)
 --   for _i=1,#_obj.b do
 --    local _b=_obj.b[_i]
 --    if btnp(_b) and _obj.inlinks[_i].status == 'ok' then
 --     _obj.s[_i]=not _obj.s[_i]
 --    end
 --   end
 --  end,
 --  update=function(_obj)
 --   local _inlinksok=true
 --   for _i in all(_obj.inlinks) do
 --    if _i.status != 'ok' then
 --     _inlinksok=false
 --     for _i=1,#_obj.s do
 --      _obj.s[_i]=false
 --     end
 --     break
 --    end
 --   end
 --   local _sok=true
 --   for _s in all(_obj.s) do
 --    if not _s then
 --     _sok=false
 --    end
 --   end
 --   if _obj.status == 'problem' and _inlinksok and _sok then
 --    _obj.status='ok'
 --   end
 --  end,
 --  draw=function(_obj)
 --   local _offx,_offy=drawbase(_obj)

 --   _offx+=6
 --   _offy+=6
 --   for _i=1,#_obj.b do
 --    pset(_offx,_offy,8)
 --    if _obj.inlinks[_i].status == 'ok' then
 --     pset(_offx,_offy,11)
 --    end

 --    print(btn2symbol[_obj.b[_i]],_offx-4,_offy+3,6)
 --    rectfill(_offx,_offy+2,_offx+4,_offy+6,1)

 --    if _obj.s[_i] then
 --     rectfill(_offx+1,_offy+3,_offx+3,_offy+5,11)
 --    end

 --    _offx+=11
 --   end
 --  end,
 -- }
}


 -- {
 --  w=24,h=15,
 --  entrycode={2},
 --  fun='channelbuttons',
 -- }

 -- {
 --  w=25,h=15,
 --  entrycode={4},
 --  status='ok',
 --  c=10,
 --  fun='codeinput',
 --  code={0,1,2,3,5},
 --  pos=1,
 -- },

root={
 w=10,h=10,
 entrycode={2},
 fun='powergen',
 cnodes={{
   w=13,h=13,
   entrycode={5},
   fun='pulseshow',
   cnodes={},
  },
  {
   w=13,h=13,
   entrycode={5},
   fun='pulseshow',
   cnodes={{
    w=13,h=13,
    entrycode={1},
    fun='pulseshow',
    cnodes={{
     w=13,h=13,
     entrycode={3},
     fun='pulseshow',
     cnodes={},
    }},
   }},
  },
 },
}

function travtree(_n,_f)
 if _n then
  _f(_n)
  for _cnode in all(_n.cnodes) do
   travtree(_cnode,_f)
  end
 end
end

cotravtree=cocreate(function ()
 while true do
  local _stack={}
  add(_stack,root)

  while #_stack > 0 do
   local _n=_stack[#_stack]
   del(_stack,_n)

   for _i=1,#_n.cnodes do
    local _cnode=_n.cnodes[_i]
    _cnode.power+=max(_n.cnodepows[_i],0)
    add(_stack,_cnode)
   end

   yield()
  end
 end
end)

_init=function()

 local _x,_y,_maxy=1,1,0

 travtree(root,function(_p)
  local _funs=funs[_p.fun]
  for _k,_v in pairs(_funs) do
   _p[_k]=_v
  end
  _p.c=0
  _p.status='ok'
  _p.blink=0
  _p.power=0
  _p.cnodepows={}

  if _x+_p.w > 128 then
   _x,_y=0,_maxy
  end
  _p.x=_x
  _p.y=_y

  if _p.w+_p.y > _maxy then
   _maxy=_p.w+_p.y
  end

  _x+=_p.w+1
  end)

 travtree(root,function(_p)
  _p.init(_p)
  end)

 curpanel=nil
end


tick=0

_update=function()
 tick+=1
 
 -- if curpanel then
 --  local _count=0
 --  for _b in all(curpanel.entrycode) do
 --   if btnp(_b) then
 --    _count+=1
 --   end
 --  end
 --  if _count == #curpanel.entrycode then
 --   curpanel=nil
 --  end
 -- else
 --  travtree(root,function(_p)
 --   local _count=0
 --   for _b in all(_p.entrycode) do
 --    if btnp(_b) then
 --     _count+=1
 --    end
 --   end
 --   if _count == #_p.entrycode then
 --   -- if _p.status != 'blocked' and _count == #_p.entrycode then
 --    curpanel=_p
 --   end
 --   end)
 -- end

 -- if curpanel then
 --  curpanel.input(curpanel)
 -- end

 travtree(root,function(_p)
  _p.update(_p)
  _p.power=max(_p.power,0)
  debug('power '.._p.power)
  end)

 if tick % 30 == 0 then
  status=coresume(cotravtree)
  debug('status: '..tostr(status))
 end

 -- for _p in all(panels) do
 --  if _p.blink > 0 then
 --   _p.blink-=1
 --  end
 --  for _l in all(_p.inlinks) do
 --   _p.inflow+=_l.outflow
 --  end
 --  -- if _p.status == 'blocked' then
 --  --  _p.status='problem'
 --  -- end

 --  _p.update(_p)
 -- end
end

_draw=function()
 cls(1)

 travtree(root,function(_p)
  if _p == curpanel then
   rect(_p.x-1,_p.y-1,_p.x+_p.w,_p.y+_p.h,7)
  end
  _p.draw(_p)
  end)
 
 -- print'l \x8b  r \x91  u \x94  d \x83  o \x8e  x \x97'
end

