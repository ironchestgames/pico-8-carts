pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

n=8
counter=0
redcounter=0

function _update60()
	if counter > 0 then
		counter-=1
	end
	if redcounter > 0 then
		redcounter-=1
	end
	if btnp(4) then
		counter=n
		redcounter=30
	end
end

function _draw()
	cls()
	circfill(10,10,1,2)
	circfill(10,20,1.5,2)
	circfill(10,30,2,2)
	circfill(10,40,2.95,2)
	circfill(10,50,3,2)
	circfill(10,60,4,2)
	circfill(10,70,4.5,2)
	
	x=61
	y=64
	if redcounter > 0 and
				redcounter < 30 - n then
		y=65
	end
	if redcounter > 0 then
		spr(1,x,y)
	else
		spr(0,x,y)
	end
	
	if counter > n*0.5 then
		circfill(64,64,2,8)
	elseif counter > 0 and
								counter <= n*0.5 then
		circfill(64,64,3,7)
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
060f0000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06554400088888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00054400000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00505000008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000