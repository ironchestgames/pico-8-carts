pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

printh('debug started','debug',true)
function debug(s)
 printh(tostr(s),'debug',false)
end

x,y=10,10

function _update()
 if btn(0) then
  x-=1
 elseif btn(1) then
  x+=1
 end

 if btn(2) then
  y-=1
 elseif btn(3) then
  y+=1
 end
end

debug(0x7fff.ffff)

function _draw()
 cls(0)
 memcpy(0x6000,0x0000,8192)

 -- for _y=0,128 do
 --  for _x=0,128 do
 --   local _adr=0x6000+_x*0.5+_y*64
 --   local _v = peek(_adr)
 --   local _dx=x-_x
 --   local _dy=y-_y
 --   -- debug(_dx)
 --   if _dx > 0 or _dy > 0 then
 --    _v=0
 --   end
 --   poke(_adr,_v)
 --  end
 -- end

 poke(0x6000+x*0.5+y*64,0)

 pset(x,y,10)

 print(stat(0),0,0,7)
 print(stat(1),0,7,7)

end

__label__
2222222

__gfx__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333333dd333333333333333333333333333330003300033333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333330460064033333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333046640333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333ddd333333333333333333333333333304403333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333090903333333333333333333333333333333333b3333333333333333333333333333333333333
3333333333333333333333333333333333333333333033333333030333333333333333333333333333333333333b33b333333333333333333333333333333333
3333333333333333333333333333333333333333330303333333333333333333333333333333333333333333333b3b3333333333333333333333333333333333
3333333333333333333333333333333333333333330303333333333333333333333333333333333333333333333b3b3333333333333333333333333333333333
33333333333333333333333333333333333333333033033333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333003303333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333303503333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333303550333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333033500333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333033550333333333333333333333333333333333333333333333033333333333333333333333333333333333
33333333333333333333333333333333333333330333555033333333333333333333333333333333333333333330a03333333333333333003333333333333333
333333333333333333333333333333333333333300335500333333333333333333333333333333333333333333333a0333333333333330330333333333333333
3333333333333333333333333333333333333333303555033333333333333333333333333333333333333333330aa033333333333333003dd033333333333333
333333333333333333333333333333333333333303355550333333333333333333333333333333333333333330a3333333333333333303ddd033333333333333
3333333333333333333333333333333333333333000220003333333333333333333333333333333333333333330aa03333333333333333333333333333333333
333333333333333333333333333333333333333333022033333333333333333333333333333333333333333333333a0333333333333333333333333333333333
3333333333333333333b33333333333333333333333333333333333333333333333333333333333333333333330aa03333333333333333333333333333333333
33333333333333333333b33b33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333b3b333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333777777777777777777777777777777777773333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337777777777777777777777777777777777777333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337771117717711177777177771177117111777333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337777177177711177777177717171777717777333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337777177777717177777177717171117717777333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337777177777717177777177717177717717777333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333337771117777717177777111711771177717777333333333333000333333333333333333333
33333333333333333333333333333333333333333333333333333337777777777777777777777777777777777777333333333330bbb033333333333333333333
3333333333333333333333333333333333333333333333333333333377777777777777777777777777777777777333333333330bbbb303333333333333333333
3333333333333333333333333330333333333333333333333333333333377733333333333333333333333333333333333333330bbb3303333333333333333333
3333333333333333333333333303033333333333333333333333333333377333333333333333333333333333333333333333330bb33303333333333333333333
33333333333333333333333333033033333333333333333333333333333733333333333333333333333333333333333333333330b33033333333333333333333
33333333333333333333333330333503333333333333333333333333003333333333333333333333333333333333333333333333020333333333333333333333
33333333333333333333333333035033333333333333333333333330ff0333333333333333333333333333333333333333333333020333333333333333333333
33333333333333333333333330335033333333333333333333333330ff0333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333303355503333333333333333333333330880333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333330020033333333333333333333333330880333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333020333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333300333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333044033333333333333333333333333333333333333333333333338333333333333333333333333333333333
33333333333333333333333333333333333333333022033333333333333333333333333333333333333333333333339333333333333333333300033333333333
333333333333333333333333333333333333333333333333333333333333333333333333333300000003333333333333333333333333333330bbb03333333333
333333333333333333333333333333333333333333333333333333333333333333333333333099994d4033333333383333333333333333330bbbb30333333333
333333333333333333333333333333333333333333333333333333333333333333333333330999944d4403333333893333333003333333330bbb330333333333
333333333333333333333333333333333333333333333333333333333333333333333333309999444d44403333339a8333330440333333330bb3330333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333302420333302203333333330b3303333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333302033333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333302033333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333dd333333333333333333333333333333333333333333333333333333330003333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333330bbb0333333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333333330bbbb3033333333333333333333333333333333333333333333333333333333333
33333333ddd3333333333333333333333333333333333333333333333333330bbb33033333333333333333333333333333333333333333333333333333333333
333333333333333333333333333000333333333333333333333333333333330bb333033333333333333333333333333333333333333333333333333333333333
333333333333333333333333330bbb033333333333333b333333333333333330b330333333333333333333333333333333333333333333333333333333333333
33333333333333333333333330bbebb033333333333333b33b333333333333330503333333333333333333333333333333333333333333333333333333333333
33333333333333333333333330ebbb3033333333333333b3b3333333333333330503333333333333333333333333333333333333333333333333333333333333
33333333333333333333333330bbb83033333333333333b3b3333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333333333333330b3303333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333dd3333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333303333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333302003333333333333333333333333333333333333ddd3333333333333333333333
33333333333333333333333333333333333333333333333333333333333333002203333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333330223333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333033333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333000000033333333333333333333333333330303333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333330222222203333333333333333333333333330303333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333302ddddddd20333333333333333333333333303303333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333330ddddddddd0333333333333333333333333300330333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333330dddddddd0333333333333333333333333330350333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333300ddddd03333333333333333333333333330355033333333333333333333333333333333333333333
33333333333333333333300033333333333333333333333330000033333333333333333333333333303350033333333333333333333333333333333333333333
33333333333333333333088803333333333333333333333333333333333333333333333333333333303355033333333300333333333330333333333333333333
3333333333333333333330f000333333333333333333333333333333333333333333333333333333033355503333333033033333333303033333333333333333
3333333333333333333330f88803333333333333333333333333333333333333333333333333333300335500333333003dd03333333303033333333333333333
3333333333333333333330f0f03333333333333333333333333333333333333333333333333333333035550333333303ddd03333333033033333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333033555503333333333333333333003303333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333000220003333333333333333333303503333333333333333
33333333333333333333333333333333333333333333333330033333333333333333333333333333330220333333333333333333333303550333333333333333
33333333333333333333333333333333333333333333333303303333333333333333333333333333333333333333333333333333333033500333333333333333
33333333333333333333333333333333333333333333333303d30333333333333333333333333333333333333333333333333333333033550333333333333333
3333333333333333333333333333333333333333333333303ddd0333333333333333333333333333333333333333333333333333330333555033333333333333
3333333333333333333333333333333333333333333333303ddd3033333333333333333333333333333333333a33333333333333330033550033333333333333
333333333333333333333333333333333333333333333303dd33d033333333333333330333333333333333333a33333333333333333035550333333333333333
333333333333333333333333333333333333333333333303ddddd033333333333333303033333333333333333a33333333333333330335555033333333333333
33333333333333333333333333333333333333333333333333333333333333333333303303333333333333333333333333333333330002200033333333333333
33333333333333333333333333333333333333333333333333333333333333333333033350333333333333333a33333333333333333302203333333333333333
333333333333333333333b3333333333333333333333333333333333333333333333303503333333333333333333333333333333333333333333333333333333
3333333333333333333333b33b333333333333333333333333333333333333333333033503333333333333333333333333333333333333333333333333333333
3333333333333333333333b3b3333333333333333333333333333333333333333330335550333333333333333333333333333333333333333333333333333333
3333333333333333333333b3b3333333333333333333333333333333333333333333002003333333333333003300333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333302033333333333333040040333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333044440333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333014144033333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333b3333333333333333333333333333044444403333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b33b333333333333333333333333044444403333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b3b3333333333333333333333333044444403333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333b3b3333333333333333333333333040040403333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333