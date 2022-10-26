pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

enemies={
 {
  hp=3,
  pos=8,
 },
 {
  hp=5,
  pos=10,
 },
}

squad={
 {
  hp=4,
  pos=1,
  coverfinding=.2,
  range=3,
  hitrangefactor=.5,
 },
 {
  hp=4,
  pos=1,
  coverfinding=.2,
  range=3,
  hitrangefactor=.5,
 },
}

hitmsgs={
 'hit!',
 'a nice hit!',
 'shot is good!',
 'between the eyes',
}

missmsgs={
 'i missed!',
 'failed to connect',
 'shot missed',
 'it dodged!',
}

movetoopen={
 'moving into open space',
 'moving in the open',
 'i\'m easy target here',
 'i don\'t like this',
}

movetocover={
 'moving into cover',
 'got some cover',
 'got some good cover',
 'i\'m in cover',
}

options={}
curoption=1

turnlen=7
ts=0
curmember=1
isfirstturn=nil
isvictory=nil
message=nil
msgmember=nil

function domsg(_msgs,_curmember)
 message=_msgs[1+flr(rnd(#_msgs))]
 msgrmts=time()+1.5
 msgmember=_curmember
end

function _init()
 ts=time()
 
 isvictory=nil
 curmember=0
 curoption=1
 domsg({'let\'s bring it'},1)
 isfirstturn=true
 options={
  {typ='donothing'}
 }
end

function _update()
 
 if isvictory then
  return
 end

 if message and time() >= msgrmts then

  message=nil

  -- generate next options for next member  
  curoption=1

  curmember+=1
  if curmember > #squad then
   curmember=1
  end

  options={}
  _member=squad[curmember]
  
  -- check if in shooting range
  local _range=enemies[1].pos-_member.pos
  if _range <= _member.range then
   local _hitpercentfunc=function()
    local _r=enemies[1].pos-_member.pos
    return mid(0.05,_member.hitrangefactor^(_r*.4),0.96)
   end
   add(options,{
    typ='attack:',
    atktyp='deadly',
    hitpercent=_hitpercentfunc(),
    hitpercentfunc=_hitpercentfunc,
   })
  end

  -- check if cover is available
  local _dist=1
  if _range <= 1 then
   _dist=0
  end
  if rnd() <= _member.coverfinding then
   add(options,{
    typ='move to:',
    dest='cover',
    dist=_dist,
   })
  end
  add(options,{
   typ='move to:',
   dest='open space',
   dist=_dist,
  })

  if #options > 2 then
   for _o in all(options) do
    if _o.dest == 'open space' then
     del(options,_o)
     return
    end
   end
  end

 elseif isfirstturn or btnp(4) then
  isfirstturn=nil

  -- execute curoption
  local _exeop=options[curoption]
  local _member=squad[curmember]
  if _exeop.typ == 'attack:' then
   if rnd() <= _exeop.hitpercent and _exeop.atktyp == 'deadly' then
    enemies[1].hp-=1 -- todo: damage
    domsg(hitmsgs,curmember)
    
    if enemies[1].hp <= 0 then
     domsg({'enemy down!'},curmember)
     del(enemies,enemies[1])
     if #enemies == 0 then
      isvictory=true
      return
     end
    end
   else
    domsg(missmsgs,curmember)
   end
  elseif _exeop.typ == 'move to:' then
   _member.pos+=_exeop.dist
   _member.isincover=_exeop.dest == 'cover'

   if _member.isincover then
    domsg(movetocover,curmember)
   else
    domsg(movetoopen,curmember)
   end
  end
 end

 if btnp(3) then
  curoption+=1
 elseif btnp(2) then
  curoption-=1
 end
 curoption=mid(1,curoption,#options)

 if time()-ts >= turnlen then
  
  local _minpos=0
  for _m in all(squad) do
   if _m.pos > _minpos then
    _minpos=_m.pos
   end
  end

  for _e in all(enemies) do
   if _e.pos-1 >= _minpos then
    _e.pos-=1
   end
  end

  -- todo: sort enemies on pos

  -- update options
  local _range=enemies[1].pos-squad[curmember].pos
  for _o in all(options) do
   if _o.typ == 'attack:' then
    _o.hitpercent=_o.hitpercentfunc()
   end
  end

  ts=time()
  -- return
 end

end

function _draw()
 cls(0)

 for _i=1,#squad do
  rectfill(4,11+19*(_i-1),19,26+19*(_i-1),_i)
 end

 local _curmembery=11+19*(curmember-1)

 if message then
  print(message,38,11+19*(msgmember-1),13)
 else
  local _offy=-4
  for _i=1,#options do
   local _o=options[_i]
   local _col=1
   if _i == curoption then
    _col=12
   end
   print(_o.typ,53,_curmembery+_offy,_col)
   _offy+=7
   if _o.typ == 'attack:' then
    print(flr(_o.hitpercent*100)..'%, '.._o.atktyp,53,_curmembery+_offy,_col)
   elseif _o.typ == 'move to:' then
    print(_o.dest,53,_curmembery+_offy,_col)
   end
   _offy+=9
  end 
 end

 if isvictory then
  print('victory',64,64,8)
 end

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
