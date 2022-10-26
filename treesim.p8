pico-8 cartridge // http://www.pico-8.com
version 35
__lua__


-- circular mask

drawmybg=false
myx=64
myy=64

function beforedraw()
 myr=flr(32+32*sin(time()/8))
end

function afterdraw()
 --copy the sccreen to the spritesheet
 memcpy(0,0x6000,0x2000)
 
 --remap spritesheet to become the screen
 poke(0x5f55,0)

 --draw bunch of white circles
 circfill(myx,myy,myr,7)
 circfill(myx,myy,myr-2,0)
 circfill(myx,myy,myr-4,7)
 for i=0,7 do
  local ii=i/7
  local cx=myx-sin(time()/8+ii)*(64+32*sin(time()/4))
  local cy=myy-cos(time()/8+ii)*(64+32*sin(time()/4))
  circfill(cx,cy,16+16*cos(time()/2+ii*2),7) 
 end
 
 --video remapping back to normal
 poke(0x5f55,0x60)
 
 --set white to transparent
 palt(7,true)

 --shift colors darker
 pal({0,1,1,2,0,5,5,2,
      5,13,3,1,1,2,13})
       
 --draw the entire spritesheet to the screen
 sspr(0,0,128,128,0,0)
 
 --reset everything
 reload(0,0,0x2000)
 palt()
 pal()
end


function _update()
 if btn(➡️) then
  myx+=1
 end
 if btn(⬅️) then
  myx-=1
 end
 if btn(⬇️) then
  myy+=1
 end
 if btn(⬆️) then
  myy-=1
 end
end

function _draw()

 cls(1)

 --------------
 -- if drawmybg then
 --  cls(14)
 --  local myscrol=time()%1*16
 --  for ix=0,8 do
 --   for iy=0,8 do
 --    print("♥",ix*16-myscrol+(8*(iy%2)),iy*16+8,15)
 --   end
 --  end
 -- end

 beforedraw()

 circfill(64,64,30,13)
 circfill(100,100,30,8)
    
 afterdraw()
end


-- function fadeout()
--  dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

--  -- palette fade
--  for i=0,40 do
--   for j=1,15 do
--    local col=j
--    for k=1,((i+(j%5))/4) do
--     col=dpal[col]
--    end
--    pal(j,col,1)
--   end
--   flip()
--  end
  
-- end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
